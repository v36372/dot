package herdr

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"strings"
	"time"
)

const (
	binPathEnvVar         = "HERDR_BIN_PATH"
	socketPathEnvVar      = "HERDR_SOCKET_PATH"
	commandTimeoutEnvVar  = "HERDR_COMMAND_TIMEOUT"
	fallbackBin           = "herdr"
	defaultCommandTimeout = 5 * time.Second
)

// Client talks to Herdr over the socket API (for popup open/close) and the CLI
// (for anything that still needs a pane-shaped command).
type Client struct {
	bin            string
	socketPath     string
	commandTimeout time.Duration
}

// NewClient resolves the herdr binary and socket path from the plugin env.
func NewClient() *Client {
	bin := os.Getenv(binPathEnvVar)
	if bin == "" {
		bin = fallbackBin
	}
	return &Client{
		bin:            bin,
		socketPath:     os.Getenv(socketPathEnvVar),
		commandTimeout: commandTimeoutFromEnv(),
	}
}

func commandTimeoutFromEnv() time.Duration {
	raw := os.Getenv(commandTimeoutEnvVar)
	if raw == "" {
		return defaultCommandTimeout
	}
	timeout, err := time.ParseDuration(raw)
	if err != nil || timeout <= 0 {
		return defaultCommandTimeout
	}
	return timeout
}

func (c *Client) timeout() time.Duration {
	if c.commandTimeout <= 0 {
		return defaultCommandTimeout
	}
	return c.commandTimeout
}

// PluginPopupOpen opens a session-modal popup via plugin.pane.open with placement=popup.
// Herdr popups are session singletons: they have no pane id and return {type:"ok"}.
// env is merged into the popup process environment (needed because popups do not always
// inherit HERDR_WORKSPACE_ID / context the way overlay panes do).
func (c *Client) PluginPopupOpen(ctx context.Context, pluginID, entrypoint, cwd, width, height string, env map[string]string) error {
	params := map[string]any{
		"plugin_id":  pluginID,
		"entrypoint": entrypoint,
		"placement":  "popup",
		"focus":      true,
	}
	if cwd != "" {
		params["cwd"] = cwd
	}
	if width != "" {
		params["width"] = width
	}
	if height != "" {
		params["height"] = height
	}
	if len(env) > 0 {
		params["env"] = env
	}
	_, err := c.rpc(ctx, "plugin.pane.open", params)
	return err
}

// PopupClose closes the current session-modal popup. Returns nil when no popup is open.
func (c *Client) PopupClose(ctx context.Context) error {
	_, err := c.rpc(ctx, "popup.close", map[string]any{})
	if err != nil && isPopupNotOpen(err) {
		return nil
	}
	return err
}

// PopupIsOpen reports whether a session-modal popup is currently open.
// There is no dedicated query method, so this probes popup.close's error shape without
// closing: we use a best-effort open-state tracked by the plugin instead. Kept for tests.
func isPopupNotOpen(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return strings.Contains(msg, "popup_not_open") || strings.Contains(msg, "no popup is open")
}

type rpcResponse struct {
	ID     string          `json:"id"`
	Result json.RawMessage `json:"result"`
	Error  *struct {
		Code    string `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

func (c *Client) rpc(ctx context.Context, method string, params any) (json.RawMessage, error) {
	if c.socketPath == "" {
		return nil, fmt.Errorf("%s must be set", socketPathEnvVar)
	}

	timeout := c.timeout()
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	var d net.Dialer
	conn, err := d.DialContext(ctx, "unix", c.socketPath)
	if err != nil {
		return nil, fmt.Errorf("herdr socket dial: %w", err)
	}
	defer func() { _ = conn.Close() }()

	deadline, ok := ctx.Deadline()
	if ok {
		_ = conn.SetDeadline(deadline)
	}

	req := map[string]any{
		"id":     fmt.Sprintf("toggle-popup:%s:%d", method, time.Now().UnixNano()),
		"method": method,
		"params": params,
	}
	payload, err := json.Marshal(req)
	if err != nil {
		return nil, err
	}
	payload = append(payload, '\n')
	if _, err := conn.Write(payload); err != nil {
		return nil, fmt.Errorf("herdr socket write: %w", err)
	}

	dec := json.NewDecoder(conn)
	var resp rpcResponse
	if err := dec.Decode(&resp); err != nil {
		return nil, fmt.Errorf("herdr socket read: %w", err)
	}
	if resp.Error != nil {
		return nil, fmt.Errorf("%s: %s", resp.Error.Code, resp.Error.Message)
	}
	return resp.Result, nil
}

// run execs the herdr CLI. Kept for doctor / any residual CLI paths.
//
//nolint:gosec // c.bin is the plugin-configured herdr binary.
func (c *Client) run(ctx context.Context, args ...string) (stdout, stderr []byte, err error) {
	timeout := c.timeout()
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, c.bin, args...)
	var outBuf, errBuf strings.Builder
	cmd.Stdout = &outBuf
	cmd.Stderr = &errBuf
	err = cmd.Run()
	if ctx.Err() != nil {
		err = fmt.Errorf("%w after %s", ctx.Err(), timeout)
	}
	return []byte(outBuf.String()), []byte(errBuf.String()), err
}
