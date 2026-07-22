// Package hide implements the `hide` subcommand used from inside the popup (tmux C-o).
// Herdr modal popups swallow all keybindings, so the only way to close from inside is a
// binding that runs in the popup process and calls popup.close over the socket.
package hide

import (
	"context"
	"fmt"
	"io"

	"github.com/maro114510/herdr-toggle-popup/internal/herdr"
	"github.com/maro114510/herdr-toggle-popup/internal/state"
)

// Run closes the session-modal popup and marks every visible registry entry hidden so the
// next external toggle opens rather than trying to close again.
func Run(args []string, stdout, stderr io.Writer) int {
	_ = args
	_ = stdout

	stateDir, err := state.StateDirFromEnv()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "hide: %v\n", err)
		return 1
	}

	store := state.NewStore(stateDir)
	client := herdr.NewClient()
	ctx := context.Background()

	// Close first so the UI goes away immediately; registry update is best-effort after.
	if err := client.PopupClose(ctx); err != nil {
		_, _ = fmt.Fprintf(stderr, "hide: %v\n", err)
		return 1
	}

	if err := store.WithLock(func() error {
		reg, err := store.Read()
		if err != nil {
			return err
		}
		for key, entry := range reg.Popups {
			if entry.Hidden != nil && *entry.Hidden {
				continue
			}
			if err := store.SetHidden(key, true); err != nil {
				return err
			}
		}
		return nil
	}); err != nil {
		_, _ = fmt.Fprintf(stderr, "hide: %v\n", err)
		// Popup is already closed; non-zero would only confuse tmux run-shell.
		return 0
	}
	return 0
}
