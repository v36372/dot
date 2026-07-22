// Package ontabfocused implements the `on-tab-focused` subcommand.
// When focus leaves a popup's recorded tab, hide the session-modal popup via popup.close
// without killing the underlying tmux shell session.
package ontabfocused

import (
	"context"
	"fmt"
	"io"
	"os"

	"github.com/maro114510/herdr-toggle-popup/internal/herdr"
	"github.com/maro114510/herdr-toggle-popup/internal/state"
)

const tabIDEnvVar = "HERDR_TAB_ID"

// Run implements the `on-tab-focused` subcommand.
func Run(_ []string, stdout, stderr io.Writer) int {
	_ = stdout

	tabID := os.Getenv(tabIDEnvVar)
	if tabID == "" {
		return 0
	}

	stateDir, err := state.StateDirFromEnv()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "on-tab-focused: %v\n", err)
		return 1
	}

	store := state.NewStore(stateDir)
	client := herdr.NewClient()
	ctx := context.Background()

	if err := store.WithLock(func() error {
		return hideEntriesOutsideFocusedTab(ctx, store, client, stderr, tabID)
	}); err != nil {
		_, _ = fmt.Fprintf(stderr, "on-tab-focused: %v\n", err)
		return 1
	}
	return 0
}

func hideEntriesOutsideFocusedTab(
	ctx context.Context, store *state.Store, client *herdr.Client, stderr io.Writer, focusedTabID string,
) error {
	reg, err := store.Read()
	if err != nil {
		return err
	}
	needClose := false
	for key, entry := range reg.Popups {
		if entry.Hidden != nil && *entry.Hidden {
			continue
		}
		if entry.TabID == nil || *entry.TabID == "" || *entry.TabID == focusedTabID {
			continue
		}
		if err := store.SetHidden(key, true); err != nil {
			_, _ = fmt.Fprintf(stderr, "on-tab-focused: %v\n", err)
			continue
		}
		needClose = true
	}
	if needClose {
		if err := client.PopupClose(ctx); err != nil {
			_, _ = fmt.Fprintf(stderr, "on-tab-focused: could not hide popup: %v\n", err)
		}
	}
	return nil
}
