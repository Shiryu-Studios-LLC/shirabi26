#compdef shirabe shirabe-backup shirabe-calendar shirabe-contacts shirabe-cookbook shirabe-docs shirabe-gallery shirabe-mail shirabe-mcp shirabe-memory shirabe-notes shirabe-personal shirabe-preset shirabe-research shirabe-sessions shirabe-signature shirabe-skills shirabe-tasks shirabe-theme shirabe-webhook
# Zsh tab-completion for the shirabe umbrella + sub-CLIs.
#
# Drop in any directory on $fpath, e.g.:
#     fpath=(/path/to/shirabe-ui/scripts/_completion $fpath)
#     autoload -U compinit; compinit
#
# Then `shirabe <tab>` completes subcommands; `shirabe mail <tab>`
# completes mail subcommands; `shirabe-mail <tab>` works the same.

_shirabe_scripts_dir() {
    local self="${(%):-%x}"
    while [[ -L "$self" ]]; do self="$(readlink "$self")"; done
    cd "${self:h}/.." && pwd
}

typeset -gA _shirabe_subs

_shirabe_refresh() {
    _shirabe_subs=()
    local dir="$(_shirabe_scripts_dir)"
    local py="$dir/../venv/bin/python"
    [[ -x "$py" ]] || py="$(command -v python3)"
    local f sub help_out commands
    for f in "$dir"/shirabe-*; do
        [[ -x "$f" ]] || continue
        case "$f" in
            *.bak|*.pyc|*.pre-*) continue ;;
        esac
        sub="${${f:t}#shirabe-}"
        help_out=$("$py" "$f" --help 2>/dev/null) || continue
        commands=$(echo "$help_out" | grep -oE '\{[a-z0-9_,-]+\}' | head -1 \
            | tr -d '{}' | tr ',' ' ')
        _shirabe_subs[$sub]="$commands"
    done
}

_shirabe() {
    [[ ${#_shirabe_subs} -eq 0 ]] && _shirabe_refresh

    local cmd="${words[1]}"

    if [[ "$cmd" == "shirabe" ]]; then
        if (( CURRENT == 2 )); then
            local -a subs=(${(k)_shirabe_subs} help)
            _describe 'subcommand' subs
            return
        fi
        local sub="${words[2]}"
        if [[ "$sub" == "help" ]] && (( CURRENT == 3 )); then
            local -a subs=(${(k)_shirabe_subs})
            _describe 'subcommand' subs
            return
        fi
        if (( CURRENT == 3 )); then
            local -a sc=(${(s/ /)_shirabe_subs[$sub]})
            _describe 'command' sc
            return
        fi
        return
    fi

    # shirabe-foo <tab>
    local sub="${cmd#shirabe-}"
    if (( CURRENT == 2 )); then
        local -a sc=(${(s/ /)_shirabe_subs[$sub]})
        _describe 'command' sc
        return
    fi
}

_shirabe "$@"
