// Package popupshell implements the `popup-shell` subcommand. The Herdr popup is only a
// transient tmux client; the shell lives in a named tmux session so closing the Herdr popup
// removes UI chrome without killing the shell.
package popupshell

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/maro114510/herdr-toggle-popup/internal/config"
	"github.com/maro114510/herdr-toggle-popup/internal/herdr"
)

const (
	shellEnvVar       = "SHELL"
	defaultShell      = "fish"
	defaultShellAbs   = "/opt/homebrew/bin/fish"
	legacyShellAbs    = "/bin/zsh"
	defaultEntrypoint = "shell"
	shellBin          = "sh"
	tmuxBin           = "tmux"
	scopeGlobal       = "global"
	scopeDirectory    = "directory"
	scopeTab          = "tab"
	scopeWorkspace    = "workspace"
	workspaceIDEnvVar = "HERDR_WORKSPACE_ID"
	pluginRootEnvVar  = "HERDR_PLUGIN_ROOT"
	sessionPrefix     = "herdr-toggle-popup-"
	sessionHashBytes  = 16
	tmuxSocketName    = "herdr-toggle-popup"
	// Delay before enabling the in-popup C-l hide bind so the keystroke that opened
	// the float cannot race into the new client and immediately close it.
	hideBindDelay = 400 * time.Millisecond
)

// Attach script. Positional after sh -c:
// $1 session  $2 cwd  $3 shell  $4 tmux  $5 conf  $6 hide_cmd
//
// Intentionally no `set -e`: best-effort set-option failures must not abort attach.
const tmuxAttachScript = `
session="$1"
cwd="$2"
shell="$3"
tmux="$4"
conf="$5"
hide_cmd="$6"

if ! "$tmux" -L herdr-toggle-popup -f "$conf" has-session -t "$session" 2>/dev/null; then
  "$tmux" -L herdr-toggle-popup -f "$conf" new-session -d -s "$session" -c "$cwd" "$shell"
fi
"$tmux" -L herdr-toggle-popup -f "$conf" set-option -t "$session" status off 2>/dev/null || true
"$tmux" -L herdr-toggle-popup -f "$conf" set-option -s escape-time 0 2>/dev/null || true

# Install hide bind after a short delay so the opening ctrl+l cannot race-close us.
(
  sleep 0.4
  "$tmux" -L herdr-toggle-popup -f "$conf" bind-key -n C-l run-shell -b "$hide_cmd" 2>/dev/null || true
) >/dev/null 2>&1 &

exec "$tmux" -L herdr-toggle-popup -f "$conf" attach-session -t "$session"
`

type (
	lookPathFunc func(file string) (string, error)
	execFunc     func(argv0 string, argv, envv []string) error
)

// Run implements the `popup-shell` subcommand. It replaces the current process with a
// low-latency tmux attach. On success it never returns.
func Run(args []string, stdout, stderr io.Writer) int {
	_ = stdout
	return run(args, stderr, exec.LookPath, syscall.Exec)
}

func run(args []string, stderr io.Writer, lookPath lookPathFunc, execProcess execFunc) int {
	entrypoint := defaultEntrypoint
	if len(args) > 0 && args[0] != "" {
		entrypoint = args[0]
	}

	sessionKey, cwd, err := tmuxSessionKey(config.Load().Scope, entrypoint)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "popup-shell: %v\n", err)
		return 1
	}

	shPath, err := lookPath(shellBin)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "popup-shell: %v\n", err)
		return 1
	}

	tmuxPath, err := lookPath(tmuxBin)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "popup-shell: tmux is required but was not found on PATH: %v\n", err)
		return 1
	}

	shellPath := resolveShell(lookPath, config.Load().Shell)

	pluginRoot := os.Getenv(pluginRootEnvVar)
	if pluginRoot == "" {
		_, _ = fmt.Fprintf(stderr, "popup-shell: %s must be set\n", pluginRootEnvVar)
		return 1
	}
	hideBin := filepath.Clean(filepath.Join(pluginRoot, "bin", "toggle-popup"))

	confPath, err := writeTmuxConf()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "popup-shell: %v\n", err)
		return 1
	}

	hideCmd := buildHideCmd(hideBin, entrypoint)

	argv := []string{
		shellBin, "-c", tmuxAttachScript, "popup-shell",
		sessionName(sessionKey), cwd, shellPath, tmuxPath, confPath, hideCmd,
	}
	if err := execProcess(shPath, argv, os.Environ()); err != nil {
		_, _ = fmt.Fprintf(stderr, "popup-shell: %v\n", err)
		return 1
	}
	return 0
}

// resolveShell picks the interactive shell for the persistent tmux session.
// Order: plugin config shell, fish, $SHELL, zsh/sh.
// $SHELL is intentionally not first: on macOS it often stays /bin/zsh even when
// the user runs fish everywhere else (Herdr default_shell, Ghostty, etc.).
func resolveShell(lookPath lookPathFunc, configured string) string {
	candidates := []string{
		configured,
		defaultShell,
		defaultShellAbs,
		"/usr/local/bin/fish",
		"/usr/bin/fish",
		os.Getenv(shellEnvVar),
		legacyShellAbs,
		"/bin/sh",
	}
	for _, candidate := range candidates {
		if candidate == "" {
			continue
		}
		if path, err := lookPath(candidate); err == nil && path != "" {
			return path
		}
		// lookPath only finds PATH entries; also accept absolute paths that exist.
		if filepath.IsAbs(candidate) {
			if st, err := os.Stat(candidate); err == nil && !st.IsDir() {
				return candidate
			}
		}
	}
	return legacyShellAbs
}

func writeTmuxConf() (string, error) {
	stateDir := os.Getenv("HERDR_PLUGIN_STATE_DIR")
	if stateDir == "" {
		stateDir = os.TempDir()
	}
	if err := os.MkdirAll(stateDir, 0o750); err != nil {
		return "", err
	}

	body := strings.Join([]string{
		"set -g status off",
		"set -s escape-time 0",
		"set -g history-limit 10000",
		"set -g mouse off",
		"set -g set-titles off",
		"",
	}, "\n")

	path := filepath.Join(stateDir, "tmux.conf")
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		return "", err
	}
	return path, nil
}

func buildHideCmd(hideBin, entrypoint string) string {
	// env VAR='value' ... /path/toggle-popup hide 'shell'
	return strings.Join([]string{
		"env",
		"HERDR_SOCKET_PATH=" + shellQuote(os.Getenv("HERDR_SOCKET_PATH")),
		"HERDR_PLUGIN_STATE_DIR=" + shellQuote(os.Getenv("HERDR_PLUGIN_STATE_DIR")),
		"HERDR_PLUGIN_CONFIG_DIR=" + shellQuote(os.Getenv("HERDR_PLUGIN_CONFIG_DIR")),
		"HERDR_WORKSPACE_ID=" + shellQuote(os.Getenv("HERDR_WORKSPACE_ID")),
		shellQuote(hideBin),
		"hide",
		shellQuote(entrypoint),
	}, " ")
}

func shellQuote(s string) string {
	return `'` + strings.ReplaceAll(s, `'`, `'\''`) + `'`
}

func tmuxSessionKey(scopeMode, entrypoint string) (key, cwd string, err error) {
	cwd = resolveCwd()
	if cwd == "" {
		return "", "", errors.New("could not determine the focused pane's cwd")
	}

	switch scopeMode {
	case scopeGlobal, "":
		// One shell shared across every workspace/tab.
		return fmt.Sprintf("global:%s", entrypoint), cwd, nil
	case scopeDirectory:
		return fmt.Sprintf("directory:%s:%s", cwd, entrypoint), cwd, nil
	case scopeTab:
		workspaceID := resolveWorkspaceID()
		tabID := herdr.ContextField("tab_id")
		if tabID == "" {
			tabID = os.Getenv("HERDR_TAB_ID")
		}
		if tabID == "" {
			tabID = "default"
		}
		return fmt.Sprintf("tab:%s:%s:%s", workspaceID, tabID, entrypoint), cwd, nil
	case scopeWorkspace:
		return fmt.Sprintf("workspace:%s:%s", resolveWorkspaceID(), entrypoint), cwd, nil
	default:
		return fmt.Sprintf("global:%s", entrypoint), cwd, nil
	}
}

func resolveWorkspaceID() string {
	workspaceID := os.Getenv(workspaceIDEnvVar)
	if workspaceID == "" {
		workspaceID = herdr.ContextField("workspace_id")
	}
	if workspaceID == "" {
		workspaceID = "default"
	}
	return workspaceID
}

func resolveCwd() string {
	for _, candidate := range []string{
		herdr.ContextField("focused_pane_cwd"),
		os.Getenv("HERDR_ACTIVE_PANE_CWD"),
		os.Getenv("HERDR_PANE_CWD"),
	} {
		if candidate != "" {
			return candidate
		}
	}
	if wd, err := os.Getwd(); err == nil && wd != "" {
		return wd
	}
	return ""
}

func sessionName(key string) string {
	sum := sha256.Sum256([]byte(key))
	return sessionPrefix + hex.EncodeToString(sum[:sessionHashBytes])
}

// TmuxSocketName is the private tmux server name used by this plugin.
func TmuxSocketName() string { return tmuxSocketName }

// HideBindDelay is exposed for tests/docs.
func HideBindDelay() time.Duration { return hideBindDelay }
