# Herdr desktop settings and mods are different on Linux and macOS.
__define_component herdr_app all optional "Herdr desktop configuration"

component_herdr_app_install() {
  local platform="$DOT_OS"
  [[ "$platform" == darwin ]] && platform=macos
  herdr_app_links "$platform"
}

component_herdr_app_check() {
  local platform="$DOT_OS" name
  [[ "$platform" == darwin ]] && platform=macos
  for name in keys.json settings.json; do
    __doctor_check --warn --hint "run: dot init --only herdr_app" "Herdr desktop $name is linked" \
      test "$(readlink "${HOME}/.config/herdr-app/$name" 2>/dev/null || true)" = "$DOTFILES_DIR/platforms/herdr-app/$platform/$name"
  done
}

herdr_app_links() {
  local platform="$1" name src dest link bak suffix
  for name in mods/herdr-prefix keys.json settings.json; do
    src="$DOTFILES_DIR/platforms/herdr-app/$platform/$name"
    dest="$HOME/.config/herdr-app/$name"
    if [[ "$name" != mods/herdr-prefix || "$platform" == linux ]]; then
      [[ -e "$src" ]] || { echo "missing source: $src" >&2; return 1; }
      mkdir -p "$(dirname "$dest")" || return 1
      if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        echo "  keep  .config/herdr-app/$name"
        continue
      fi
      if [[ -L "$dest" ]]; then
        link="$(readlink "$dest")"
        if [[ "$link" == "$HOME_DIR/.config/herdr-app/$name" || "$link" == "$DOTFILES_DIR/platforms/herdr-app/"*"/$name" ]]; then
          rm "$dest" || return 1
        fi
      fi
      if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ "$name" == mods/* ]]; then
          echo "refusing to overwrite existing mod: $dest" >&2
          return 1
        fi
        bak="$dest.bak.$(date +%s)"
        suffix=0
        while [[ -e "$bak" || -L "$bak" ]]; do
          ((suffix += 1))
          bak="$dest.bak.$(date +%s).$suffix"
        done
        echo "  backup $dest -> $bak"
        mv "$dest" "$bak" || return 1
      fi
      ln -s "$src" "$dest" || return 1
      echo "  link  .config/herdr-app/$name ($platform)"
    elif [[ -L "$dest" ]]; then
      link="$(readlink "$dest")"
      if [[ "$link" == "$HOME_DIR/.config/herdr-app/$name" || "$link" == "$DOTFILES_DIR/platforms/herdr-app/"*"/$name" ]]; then
        rm "$dest" || return 1
        echo "  unlink .config/herdr-app/$name"
      fi
    fi
  done
}
