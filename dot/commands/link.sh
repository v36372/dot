# dot link / dot unlink: a user-local `dot` symlink for shells that do not put
# dot/bin on PATH (Fish does, in conf.d/paths.fish).

cmd_link_usage() {
    cat << EOF
USAGE:
    ${SCRIPT_NAME} link

Symlink ${DOT_ROOT}/bin/dot into ~/.local/bin without replacing other commands.
EOF
}

cmd_unlink_usage() {
    cat << EOF
USAGE:
    ${SCRIPT_NAME} unlink

Remove the dot symlink that '${SCRIPT_NAME} link' created.
EOF
}

cmd_link() {
    __require_no_args link "$@" || return 1
    __print_header "Creating symlink for dot command"

    local target_dir="${HOME}/.local/bin" link_path="${HOME}/.local/bin/dot"
    mkdir -p "$target_dir" || return 1
    if [[ -e "$link_path" || -L "$link_path" ]]; then
        if [[ "$(readlink "$link_path" 2>/dev/null || true)" == "${DOT_ROOT}/bin/dot" ]]; then
            __print_success "Already linked: ${link_path}"
            return 0
        fi
        __print_error "Refusing to replace ${link_path}: it belongs to another command"
        return 1
    fi
    if ln -s "${DOT_ROOT}/bin/dot" "$link_path"; then
        __print_success "Created symlink at ${link_path}"
        __print_info "Make sure ${target_dir} is in your PATH"
    else
        __print_error "Failed to create symlink at ${link_path}"
        return 1
    fi
}

cmd_unlink() {
    __require_no_args unlink "$@" || return 1
    __print_header "Removing dot symlink"

    local link_path="${HOME}/.local/bin/dot"
    if [[ "$(readlink "$link_path" 2>/dev/null || true)" == "${DOT_ROOT}/bin/dot" ]]; then
        rm "$link_path" || return 1
        __print_success "Removed symlink at ${link_path}"
    else
        __print_warning "No symlink owned by this repo at ${link_path}"
    fi
}
