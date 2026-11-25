# Rex, the terminal multiplexer. macOS: the app (Sparkle appcast, not
# Homebrew).
# Linux: the server package (pkgs.superlogical.com) and a personal server
# that Rex for Mac reaches over ssh://<host>. Both: stowed config, terminfo,
# for terminal compatibility.
__define_component rex all optional "Rex"

REX_APP_PATH="/Applications/Rex Beta.app"
REX_APPCAST_URL="https://blob.superlogical.com/public/rex-app/preview/appcast.xml"
REX_TEAM_ID="AG92C3PT77"
REX_BUNDLED_CLI="${HOME}/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
# Linux: Rex's server package (apt/dnf/pacman repo or tarball, picked by the
# script). Re-running the script upgrades Rex and keeps the channel.
REX_LINUX_INSTALL_URL="https://pkgs.superlogical.com/rex/install.sh"
REX_LINUX_CHANNEL="preview"

component_rex_install() {
    if [[ "$DOT_OS" == "linux" ]]; then
        __install_rex_linux || return 1
        __export_rex_runtime_dir
        __setup_rex_server_linux
    else
        __update_rex_app || return 1
    fi
    local status=0
    __try "Rex config reload" __reload_rex_config || status=1
    __try "Rex terminfo setup" __setup_rex_terminfo || status=1
    return "$status"
}

component_rex_update() {
    local status=0
    if [[ "$DOT_OS" == "linux" ]]; then
        __try "Rex update" __update_rex_linux || status=1
        __export_rex_runtime_dir
        __try "Rex config reload" __reload_rex_config || status=1
        return "$status"
    fi
    __try "Rex update" __update_rex_app || status=1
    __try "Rex config reload" __reload_rex_config || status=1
    return "$status"
}

component_rex_check() {
    local rex_bin
    if [[ "$DOT_OS" == "linux" ]]; then
        __export_rex_runtime_dir
        __doctor_check --warn --hint "run: ${SCRIPT_NAME} init --only rex" "Rex is installed" __rex_linux_installed
        __doctor_check --warn --hint "run: rex server install" "Rex server is installed (rex.socket)" \
            systemctl --user is-enabled rex.socket
    else
        __doctor_check --warn --hint "run: ${SCRIPT_NAME} init --only rex" "Rex is installed" test -d "$REX_APP_PATH"
    fi
    __doctor_check --warn --hint "run: ${SCRIPT_NAME} stow" "Rex config is stowed" __path_is_stowed .config/rex/init.lua
    if rex_bin="$(__rex_cli)"; then
        __doctor_check --warn --hint "run: rex config check" "Rex config loads without errors" "$rex_bin" config check
    else
        __print_warning "rex CLI not found (launch Rex once on macOS, or run: ${SCRIPT_NAME} init --only rex)"
    fi
}

# True when the Rex server package is installed. Ubuntu also has an unrelated
# "rex" package, so only a rex that reports "rex 0.x" counts.
__rex_linux_installed() {
    __command_exists rex && rex version 2>/dev/null | grep -q '^rex 0\.'
}

# Print the rex CLI path: $REX_BIN_DIR inside Rex terminals, then PATH, then
# the copy bundled with the app's server.
__rex_cli() {
    if [[ -n "${REX_BIN_DIR:-}" && -x "${REX_BIN_DIR}/rex" ]]; then
        echo "${REX_BIN_DIR}/rex"
    elif [[ -x "$REX_BUNDLED_CLI" ]]; then
        echo "$REX_BUNDLED_CLI"
    elif __command_exists rex && rex version 2>/dev/null | grep -q '^rex 0\.'; then
        command -v rex
    else
        return 1
    fi
}

__rex_installed_build() {
    defaults read "${REX_APP_PATH}/Contents/Info" CFBundleVersion 2>/dev/null
}

# Print "<build> <dmg-url>" for the newest appcast entry.
__rex_latest_release() {
    local appcast
    appcast="$(__download_url "$REX_APPCAST_URL" -)" || return 1
    awk '
        /<sparkle:version>/ { gsub(/.*<sparkle:version>|<\/sparkle:version>.*/, ""); build = $0 }
        /<enclosure / && build != "" {
            match($0, /url="[^"]+"/)
            url = substr($0, RSTART + 5, RLENGTH - 6)
            if (best == "" || build + 0 > best + 0) { best = build; best_url = url }
            build = ""
        }
        END { if (best != "") print best, best_url }
    ' <<< "$appcast"
}

# Install Rex from a DMG after checking its Developer ID team. Only used when
# the app is not running; a running app updates through Sparkle instead.
__install_rex_dmg() {
    local url="$1"
    local work mount app
    work="$(mktemp -d)" || return 1
    mount="${work}/mount"

    __print_info "Downloading ${url##*/}..."
    if ! __download_url "$url" "${work}/rex.dmg"; then
        rm -rf "$work"
        return 1
    fi
    if ! hdiutil attach -nobrowse -readonly -quiet -mountpoint "$mount" "${work}/rex.dmg"; then
        rm -rf "$work"
        return 1
    fi

    app="$(find "$mount" -maxdepth 1 -name '*.app' -print -quit)"
    local status=1
    if [[ -z "$app" ]]; then
        __print_error "No app found in the Rex disk image"
    elif ! codesign --verify --deep --strict "$app" 2>/dev/null \
        || ! codesign -dv "$app" 2>&1 | grep -q "^TeamIdentifier=${REX_TEAM_ID}$"; then
        __print_error "Rex disk image failed signature verification; not installing"
    elif ditto "$app" "${REX_APP_PATH}.new" \
        && rm -rf "$REX_APP_PATH" \
        && mv "${REX_APP_PATH}.new" "$REX_APP_PATH"; then
        status=0
    fi

    hdiutil detach -quiet "$mount" || true
    rm -rf "$work" "${REX_APP_PATH}.new"
    return "$status"
}

# Install Rex if missing, or update it when the appcast has a newer build.
__update_rex_app() {
    local release latest url installed
    if ! release="$(__rex_latest_release)" || [[ -z "$release" ]]; then
        __print_warning "Could not read the Rex appcast; skipping Rex update"
        return 1
    fi
    read -r latest url <<< "$release"
    installed="$(__rex_installed_build || true)"

    if [[ -n "$installed" && "$installed" -ge "$latest" ]]; then
        __print_success "Rex is up to date (build ${installed})"
        return 0
    fi

    if [[ -n "$installed" ]] && pgrep -qf "${REX_APP_PATH}/Contents/MacOS/"; then
        # Replacing a running app bundle is unsafe; let Sparkle do it. The app
        # relaunches, and sessions survive because they live in the server.
        __print_info "Rex build ${latest} is available (installed: ${installed}); asking the app to install it..."
        local rex_bin
        if rex_bin="$(__rex_cli)" && "$rex_bin" "do" client.update.accept >/dev/null 2>&1; then
            __print_success "Rex is installing build ${latest} and will relaunch"
        else
            __print_warning "Rex could not start the update; use Rex > Install Update, or quit Rex and rerun '${SCRIPT_NAME} update'"
        fi
        return 0
    fi

    __print_info "Installing Rex build ${latest}..."
    if __install_rex_dmg "$url"; then
        __print_success "Rex build ${latest} installed"
    else
        __print_error "Failed to install Rex"
        return 1
    fi
}

# Validate the stowed config and, when a server is running, reload it.
__reload_rex_config() {
    local rex_bin
    if ! rex_bin="$(__rex_cli)"; then
        __print_warning "rex CLI not found (launch Rex once to install its server); skipping config reload"
        return 0
    fi
    if ! "$rex_bin" config check >/dev/null; then
        __print_error "Rex config has errors; run 'rex config check'"
        return 1
    fi
    if "$rex_bin" --autostart=false server status >/dev/null 2>&1; then
        "$rex_bin" --autostart=false config reload >/dev/null && __print_success "Rex config reloaded"
    else
        __print_success "Rex config is valid"
    fi
}


# Install Rex's xterm-rex terminfo entry (~/.terminfo) and its ssh guard
# (~/.config/rex/ssh_config + an Include in ~/.ssh/config, so remote hosts get
# xterm-256color). Both hold machine paths, so Rex writes them, not stow.
# "Ready:" is the verdict line of `rex terminfo status`. On Linux the package
# installs the ssh guard system-wide (/etc/ssh/ssh_config.d/50-rex.conf), so
# the per-user guard it reports "missing" is not needed there.
__setup_rex_terminfo() {
    local rex_cli
    rex_cli="$(__rex_cli)" || {
        __print_warning "rex CLI not found; skipping Rex terminfo setup"
        return 0
    }
    if "$rex_cli" terminfo status 2>/dev/null | grep -q '^Ready:'; then
        __print_success "Rex terminfo is set up"
    elif "$rex_cli" terminfo setup >/dev/null; then
        __print_success "Installed Rex terminfo (xterm-rex) and ssh guard"
    else
        __print_error "rex terminfo setup failed"
        return 1
    fi
}


# Install (or, with "update", upgrade) Rex's Linux server package.
__install_rex_linux() {
    local mode="${1:-install}"
    if [[ "$mode" != "update" ]] && __rex_linux_installed; then
        __print_success "Rex is installed ($(rex version | head -1))"
        return 0
    fi
    __print_info "Installing Rex from the ${REX_LINUX_CHANNEL} channel..."
    if __run_remote_installer "$REX_LINUX_INSTALL_URL" sh --channel "$REX_LINUX_CHANNEL"; then
        hash -r
        __print_success "Rex installed ($(rex version | head -1))"
    else
        __print_error "Failed to install Rex"
        return 1
    fi
}

# True when apt or pacman owns the rex binary; their upgrades then update Rex too.
__rex_package_managed() {
    local rex_bin
    rex_bin="$(command -v rex)" || return 1
    rex_bin="$(readlink -f "$rex_bin")"
    case "$DOT_PACKAGE_MANAGER" in
        apt) dpkg -S "$rex_bin" >/dev/null 2>&1 ;;
        pacman) pacman -Qo "$rex_bin" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

__update_rex_linux() {
    if __rex_package_managed; then
        __print_success "Rex is updated by ${DOT_PACKAGE_MANAGER} ($(rex version | head -1))"
        return 0
    fi
    __install_rex_linux update
}

# exe.dev SSH sessions may lack XDG_RUNTIME_DIR, which rex and systemctl --user need.
__export_rex_runtime_dir() {
    if [[ -z "${XDG_RUNTIME_DIR:-}" && -d "/run/user/$(id -u)" ]]; then
        XDG_RUNTIME_DIR="/run/user/$(id -u)"
        export XDG_RUNTIME_DIR
    fi
}

# Personal Rex server (systemd user units, socket-activated) running as this
# account; this is the server Rex for Mac finds over ssh://<host>.
__setup_rex_server_linux() {
    if ! __command_exists systemctl || [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
        __print_warning "No systemd user session; skipping Rex server (run 'rex server install' later)"
        return 0
    fi
    if systemctl --user is-enabled rex.socket >/dev/null 2>&1; then
        __print_success "Rex server is installed (rex.socket)"
    elif rex server install >/dev/null; then
        __print_success "Rex server installed; it starts at boot and on the first rex command"
    else
        __print_warning "rex server install failed; run it by hand to see why"
    fi
}
