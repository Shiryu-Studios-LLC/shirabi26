#!/usr/bin/env bash
# Tab-completion for the `shirabe` umbrella + every `shirabe-*` CLI.
#
# Source from your shell rc:
#     source /path/to/shirabe-ui/scripts/_completion/shirabe.bash
#
# Or wire it once per machine:
#     sudo install -m 644 shirabe.bash /etc/bash_completion.d/shirabe
#
# What it does:
#   - On the first word after `shirabe`, complete with the list of
#     subcommands (`mail`, `calendar`, ...).
#   - On subsequent words, complete with the subcommand's first-token
#     subcommands (`list`, `show`, ...) which we cache by parsing the
#     tool's own --help output. Updates lazily; refresh by running
#     `_shirabe_refresh_cache`.
#   - Same completion works for the individual `shirabe-foo` scripts.

_shirabe_scripts_dir() {
    # Resolve the scripts/ dir from the script that sources us. We assume
    # the user sourced the file directly out of scripts/_completion/.
    local self="${BASH_SOURCE[0]}"
    while [ -L "$self" ]; do self=$(readlink "$self"); done
    cd "$(dirname "$self")/.." && pwd
}

declare -A _SHIRABE_SUBS_CACHE=()

_shirabe_refresh_cache() {
    local dir="$(_shirabe_scripts_dir)"
    _SHIRABE_SUBS_CACHE=()
    # Prefer the project venv's Python so deps (bcrypt, sqlalchemy, ...)
    # resolve. Falls back to system `python3` for container installs.
    local py="$dir/../venv/bin/python"
    [ -x "$py" ] || py="$(command -v python3)"
    local f
    for f in "$dir"/shirabe-*; do
        [ -x "$f" ] || continue
        case "$f" in *.bak|*.pyc|*.pre-*) continue ;; esac
        local name="$(basename "$f")"
        local sub="${name#shirabe-}"
        local help_out
        help_out=$("$py" "$f" --help 2>/dev/null) || continue
        local commands
        commands=$(echo "$help_out" | grep -oE '\{[a-z0-9_,-]+\}' | head -1 \
            | tr -d '{}' | tr ',' ' ')
        _SHIRABE_SUBS_CACHE[$sub]="$commands"
    done
}

_shirabe_complete() {
    [ ${#_SHIRABE_SUBS_CACHE[@]} -eq 0 ] && _shirabe_refresh_cache

    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmd="${COMP_WORDS[0]}"

    # `shirabe <tab>` → list every subcommand
    if [ "$cmd" = "shirabe" ]; then
        if [ "$COMP_CWORD" -eq 1 ]; then
            local subs="${!_SHIRABE_SUBS_CACHE[@]} help"
            COMPREPLY=($(compgen -W "$subs" -- "$cur"))
            return 0
        fi
        # `shirabe foo <tab>` — complete with foo's own subcommands
        local sub="${COMP_WORDS[1]}"
        # `shirabe help <tab>` lists every subcommand
        if [ "$sub" = "help" ] && [ "$COMP_CWORD" -eq 2 ]; then
            COMPREPLY=($(compgen -W "${!_SHIRABE_SUBS_CACHE[*]}" -- "$cur"))
            return 0
        fi
        if [ "$COMP_CWORD" -eq 2 ]; then
            COMPREPLY=($(compgen -W "${_SHIRABE_SUBS_CACHE[$sub]}" -- "$cur"))
            return 0
        fi
        return 0
    fi

    # Direct `shirabe-foo <tab>` (no umbrella)
    local sub="${cmd#shirabe-}"
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "${_SHIRABE_SUBS_CACHE[$sub]}" -- "$cur"))
        return 0
    fi
}

# Register the completion for every shirabe-* script + the umbrella.
complete -F _shirabe_complete shirabe
for f in "$(_shirabe_scripts_dir)"/shirabe-*; do
    [ -x "$f" ] || continue
    case "$f" in *.bak|*.pyc|*.pre-*) continue ;; esac
    complete -F _shirabe_complete "$(basename "$f")"
done
