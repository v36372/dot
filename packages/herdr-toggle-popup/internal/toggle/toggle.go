// Package toggle implements the `toggle` subcommand: open-or-toggle logic, scope keying,
// and close-to-hide behavior backed by a tmux session. Uses Herdr placement=popup so the
// shell opens as a sized float rather than a full-screen overlay.
package toggle

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"github.com/maro114510/herdr-toggle-popup/internal/config"
	"github.com/maro114510/herdr-toggle-popup/internal/herdr"
	"github.com/maro114510/herdr-toggle-popup/internal/state"
)

const (
	pluginID = "local.toggle-popup"

	// ModeSwitch is the default mode: another entrypoint's popup is left untouched.
	ModeSwitch = "switch"
	// ModeForceClose closes every other entrypoint's popup under the same scope before opening.
	ModeForceClose = "force-close"
	// ModeForceOpen behaves like switch but is a distinct, explicit opt-in to stacking popups.
	ModeForceOpen = "force-open"

	scopeDirectory = "directory"
	scopeTab       = "tab"

	workspaceIDEnvVar = "HERDR_WORKSPACE_ID"

	msPerSecond = 1000
)

// Run implements the `toggle` subcommand: args is
// <entrypoint> [switch|force-close|force-open].
func Run(args []string, stdout, stderr io.Writer) int {
	_ = stdout

	if len(args) == 0 {
		_, _ = fmt.Fprintln(stderr, "usage: toggle-popup toggle <entrypoint> [switch|force-close|force-open]")
		return 1
	}
	entrypoint := args[0]

	mode := ModeSwitch
	if len(args) > 1 {
		mode = args[1]
	}

	workspaceID := os.Getenv(workspaceIDEnvVar)
	if workspaceID == "" {
		_, _ = fmt.Fprintf(stderr, "toggle: %s must be set\n", workspaceIDEnvVar)
		return 1
	}

	switch mode {
	case ModeSwitch, ModeForceClose, ModeForceOpen:
	default:
		_, _ = fmt.Fprintf(stderr, "toggle: invalid mode: %s (expected switch, force-close, or force-open)\n", mode)
		return 1
	}

	stateDir, err := state.StateDirFromEnv()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "toggle: %v\n", err)
		return 1
	}

	cfg := config.Load()
	keyPrefix, err := scopeKeyPrefix(cfg.Scope, workspaceID)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "toggle: %v\n", err)
		return 1
	}

	store := state.NewStore(stateDir)
	client := herdr.NewClient()
	ctx := context.Background()

	return runToggle(ctx, store, client, cfg, stderr, entrypoint, mode, keyPrefix, cfg.Scope, workspaceID)
}

func scopeKeyPrefix(scopeMode, workspaceID string) (string, error) {
	switch scopeMode {
	case scopeDirectory:
		cwd, err := focusedCwd()
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("directory:%s:", cwd), nil
	case scopeTab:
		tabID, err := focusedTabID()
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("tab:%s:%s:", workspaceID, tabID), nil
	default:
		return fmt.Sprintf("workspace:%s:", workspaceID), nil
	}
}

func focusedCwd() (string, error) {
	for _, candidate := range []string{
		herdr.ContextField("focused_pane_cwd"),
		os.Getenv("HERDR_ACTIVE_PANE_CWD"),
		os.Getenv("HERDR_PANE_CWD"),
	} {
		if candidate != "" {
			return candidate, nil
		}
	}
	if wd, err := os.Getwd(); err == nil && wd != "" {
		return wd, nil
	}
	return "", errors.New("could not determine the focused pane's cwd")
}

func focusedTabID() (string, error) {
	tabID := herdr.ContextField("tab_id")
	if tabID == "" {
		return "", errors.New("could not determine the focused tab's id")
	}
	return tabID, nil
}

func runToggle(
	ctx context.Context, store *state.Store, client *herdr.Client, cfg config.Config, stderr io.Writer,
	entrypoint, mode, keyPrefix, scopeMode, workspaceID string,
) int {
	key := keyPrefix + entrypoint
	var code int
	if err := store.WithLock(func() error {
		code = runToggleLocked(ctx, store, client, cfg, stderr, key, entrypoint, mode, keyPrefix, scopeMode, workspaceID)
		return nil
	}); err != nil {
		_, _ = fmt.Fprintf(stderr, "toggle: %v\n", err)
		return 1
	}
	return code
}

// runToggleLocked drives hide/show/open while the registry lock is held.
//
// Herdr popups are session singletons without pane IDs. Visibility is tracked only in our
// registry: visible entry => hide via popup.close; hidden/missing entry => open via
// plugin.pane.open with placement=popup.
func runToggleLocked(
	ctx context.Context, store *state.Store, client *herdr.Client, cfg config.Config, stderr io.Writer,
	key, entrypoint, mode, keyPrefix, scopeMode, workspaceID string,
) int {
	entry, ok, err := store.Get(key)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "toggle: %v\n", err)
		return 1
	}

	if ok && (entry.Hidden == nil || !*entry.Hidden) {
		return hidePopup(ctx, store, client, stderr, key)
	}

	if mode == ModeForceClose {
		closeOtherPopups(ctx, store, client, keyPrefix, key)
	}

	return openPopup(ctx, store, client, cfg, stderr, key, entrypoint, scopeMode, workspaceID)
}

func hidePopup(ctx context.Context, store *state.Store, client *herdr.Client, stderr io.Writer, key string) int {
	// Always mark hidden first. Modal popups can already be gone (Escape, process exit)
	// while our registry still says visible; treating close as best-effort keeps the next
	// ctrl+f on the open path instead of looping on failed closes.
	if err := store.SetHidden(key, true); err != nil {
		_, _ = fmt.Fprintf(stderr, "toggle: %v\n", err)
		return 1
	}
	if err := client.PopupClose(ctx); err != nil {
		_, _ = fmt.Fprintf(stderr, "toggle: popup close: %v\n", err)
		// Still success: registry is hidden so the next toggle will reopen.
	}
	return 0
}

func closeOtherPopups(ctx context.Context, store *state.Store, client *herdr.Client, keyPrefix, excludeKey string) {
	reg, err := store.Read()
	if err != nil {
		return
	}
	// Session-modal popups are a singleton: closing the current popup is enough.
	// Still clear sibling registry entries under the same scope prefix.
	for otherKey, entry := range reg.Popups {
		if otherKey == excludeKey || !strings.HasPrefix(otherKey, keyPrefix) {
			continue
		}
		if entry.Hidden == nil || !*entry.Hidden {
			_ = client.PopupClose(ctx)
		}
		_ = store.Delete(otherKey)
	}
}

func openPopup(
	ctx context.Context, store *state.Store, client *herdr.Client, cfg config.Config, stderr io.Writer,
	key, entrypoint, scopeMode, workspaceID string,
) int {
	cwd, err := focusedCwd()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "toggle: %v\n", err)
		return 1
	}

	width, height := cfg.SizeFor(entrypoint)
	tabID := herdr.ContextField("tab_id")
	if tabID == "" {
		tabID = os.Getenv("HERDR_TAB_ID")
	}

	// Popups do not reliably inherit HERDR_WORKSPACE_ID / context. Inject them so
	// popup-shell can resolve the tmux session key and stay alive.
	env := map[string]string{
		"HERDR_WORKSPACE_ID": workspaceID,
	}
	if tabID != "" {
		env["HERDR_TAB_ID"] = tabID
	}
	if cwd != "" {
		env["HERDR_ACTIVE_PANE_CWD"] = cwd
	}
	if ctxJSON := os.Getenv("HERDR_PLUGIN_CONTEXT_JSON"); ctxJSON != "" {
		env["HERDR_PLUGIN_CONTEXT_JSON"] = ctxJSON
	}

	if err := client.PluginPopupOpen(ctx, pluginID, entrypoint, cwd, width, height, env); err != nil {
		_, _ = fmt.Fprintf(stderr, "toggle: failed to open popup: %v\n", err)
		return 1
	}

	entry := state.Entry{
		// Popups have no pane id; keep a stable synthetic marker for registry dumps.
		PaneID:          "popup:" + entrypoint,
		PluginID:        pluginID,
		Entrypoint:      entrypoint,
		Scope:           scopeMode,
		WorkspaceID:     &workspaceID,
		TabID:           tabIDPointer(tabID),
		CreatedAtUnixMs: time.Now().Unix() * msPerSecond,
		Hidden:          nil,
	}
	if err := store.Set(key, entry); err != nil {
		_ = client.PopupClose(ctx)
		_, _ = fmt.Fprintf(stderr, "toggle: %v\n", err)
		return 1
	}
	return 0
}

func tabIDPointer(tabID string) *string {
	if tabID == "" {
		return nil
	}
	return &tabID
}
