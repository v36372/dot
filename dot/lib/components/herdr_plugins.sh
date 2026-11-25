# v36372's local Herdr plugins, built and linked from this repo.
__define_component herdr_plugins all optional "Local Herdr plugins"

component_herdr_plugins_check() {
  __doctor_check --warn "Float popup is linked" herdr_toggle_popup_linked
  __doctor_check --warn "Companion is linked" herdr_companion_linked
}

HERDR_TOGGLE_POPUP_DIR="$DOTFILES_DIR/packages/herdr-toggle-popup"
HERDR_TOGGLE_POPUP_BIN="$HERDR_TOGGLE_POPUP_DIR/bin/toggle-popup"
HERDR_TOGGLE_POPUP_CONFIG_SRC="$HERDR_TOGGLE_POPUP_DIR/config/config.toml"
HERDR_TOGGLE_POPUP_CONFIG_DIR="$HOME/.config/herdr/plugins/config/local.toggle-popup"
HERDR_TOGGLE_POPUP_CONFIG_DEST="$HERDR_TOGGLE_POPUP_CONFIG_DIR/config.toml"
HERDR_TOGGLE_POPUP_ID="local.toggle-popup"

HERDR_COMPANION_DIR="$DOTFILES_DIR/packages/herdr-companion"
HERDR_COMPANION_NM="$HERDR_COMPANION_DIR/node_modules/glimpseui"
HERDR_COMPANION_ID="local.companion"

herdr_toggle_popup_linked() {
  command -v herdr >/dev/null 2>&1 || return 1
  [[ "$(herdr plugin list 2>/dev/null)" == *"$HERDR_TOGGLE_POPUP_ID"* ]]
}

ensure_herdr_toggle_popup_bin() {
  local newer_source

  if [[ -x "$HERDR_TOGGLE_POPUP_BIN" ]]; then
    # Rebuild when any tracked source is newer than the binary.
    newer_source="$(find "$HERDR_TOGGLE_POPUP_DIR" \
      \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' -o -name 'herdr-plugin.toml' \) \
      -newer "$HERDR_TOGGLE_POPUP_BIN" -print -quit 2>/dev/null)"
    if [[ -z "$newer_source" ]]; then
      return 0
    fi
  fi

  if ! command -v go >/dev/null 2>&1; then
    echo "  skip  herdr-toggle-popup build (go not found)"
    return 1
  fi

  echo "  build herdr-toggle-popup"
  mkdir -p "$(dirname "$HERDR_TOGGLE_POPUP_BIN")"
  (
    cd "$HERDR_TOGGLE_POPUP_DIR" || exit 1
    go build -o bin/toggle-popup .
  )
}

seed_herdr_toggle_popup_config() {
  mkdir -p "$HERDR_TOGGLE_POPUP_CONFIG_DIR"
  if [[ -e "$HERDR_TOGGLE_POPUP_CONFIG_DEST" ]]; then
    echo "  keep  plugins/config/local.toggle-popup/config.toml"
    return 0
  fi
  if [[ ! -f "$HERDR_TOGGLE_POPUP_CONFIG_SRC" ]]; then
    echo "  miss  $HERDR_TOGGLE_POPUP_CONFIG_SRC" >&2
    return 1
  fi
  cp "$HERDR_TOGGLE_POPUP_CONFIG_SRC" "$HERDR_TOGGLE_POPUP_CONFIG_DEST"
  echo "  seed  plugins/config/local.toggle-popup/config.toml"
}

# Build binary, link local plugin, seed runtime config.
install_herdr_toggle_popup() {
  local ok=0

  echo "== herdr-toggle-popup =="

  if [[ ! -d "$HERDR_TOGGLE_POPUP_DIR" ]]; then
    echo "  miss  $HERDR_TOGGLE_POPUP_DIR"
    return 1
  fi

  if ! ensure_herdr_toggle_popup_bin; then
    if [[ ! -x "$HERDR_TOGGLE_POPUP_BIN" ]]; then
      echo "  fail  binary missing: $HERDR_TOGGLE_POPUP_BIN"
      return 1
    fi
  fi

  if ! command -v herdr >/dev/null 2>&1; then
    echo "  skip  herdr plugin link (herdr not found)"
    seed_herdr_toggle_popup_config || true
    return 1
  fi

  if herdr_toggle_popup_linked; then
    # Re-link keeps plugins.json in sync if the package path moved.
    echo "  link  $HERDR_TOGGLE_POPUP_ID (refresh)"
  else
    echo "  link  $HERDR_TOGGLE_POPUP_ID"
  fi
  if ! herdr plugin link "$HERDR_TOGGLE_POPUP_DIR" >/dev/null; then
    echo "  fail  herdr plugin link"
    return 1
  fi

  seed_herdr_toggle_popup_config || ok=1

  if herdr_toggle_popup_linked && [[ -x "$HERDR_TOGGLE_POPUP_BIN" ]]; then
    echo "  ok    ctrl+n -> $HERDR_TOGGLE_POPUP_ID.toggle-shell"
  else
    echo "  warn  plugin not fully installed"
    ok=1
  fi

  [[ "$ok" -eq 0 ]]
}

herdr_companion_linked() {
  command -v herdr >/dev/null 2>&1 || return 1
  [[ "$(herdr plugin list 2>/dev/null)" == *"$HERDR_COMPANION_ID"* ]]
}

ensure_herdr_companion_deps() {
  local newer_source

  if [[ -d "$HERDR_COMPANION_NM" ]]; then
    newer_source="$(find "$HERDR_COMPANION_DIR" \
      \( -name 'package.json' -o -name 'package-lock.json' -o -name 'herdr-plugin.toml' \) \
      -newer "$HERDR_COMPANION_NM" -print -quit 2>/dev/null)"
    if [[ -z "$newer_source" ]]; then
      return 0
    fi
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "  skip  herdr-companion install (npm not found)"
    return 1
  fi

  echo "  npm ci herdr-companion"
  (
    cd "$HERDR_COMPANION_DIR" || exit 1
    npm ci
  )
}

install_herdr_companion() {
  local ok=0

  echo "== herdr-companion =="

  if [[ ! -d "$HERDR_COMPANION_DIR" ]]; then
    echo "  miss  $HERDR_COMPANION_DIR"
    return 1
  fi

  if ! ensure_herdr_companion_deps; then
    if [[ ! -d "$HERDR_COMPANION_NM" ]]; then
      echo "  fail  node_modules missing: $HERDR_COMPANION_NM"
      return 1
    fi
  fi

  if ! command -v herdr >/dev/null 2>&1; then
    echo "  skip  herdr plugin link (herdr not found)"
    return 1
  fi

  if herdr_companion_linked; then
    echo "  link  $HERDR_COMPANION_ID (refresh)"
  else
    echo "  link  $HERDR_COMPANION_ID"
  fi
  if ! herdr plugin link "$HERDR_COMPANION_DIR" >/dev/null; then
    echo "  fail  herdr plugin link"
    return 1
  fi

  if herdr_companion_linked && [[ -d "$HERDR_COMPANION_NM" ]]; then
    echo "  ok    prefix+shift+c -> $HERDR_COMPANION_ID.toggle"
  else
    echo "  warn  plugin not fully installed"
    ok=1
  fi

  [[ "$ok" -eq 0 ]]
}

component_herdr_plugins_install() {
  local ok=0

  install_herdr_toggle_popup || ok=1
  install_herdr_companion || ok=1

  [[ "$ok" -eq 0 ]]
}
