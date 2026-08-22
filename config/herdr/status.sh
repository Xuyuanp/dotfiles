#!/bin/sh
# Tab bar status helper for Herdr.
# Prints the active workspace name; used by ui.tab_bar_right in config.toml.
set -eu

workspace_id="${HERDR_ACTIVE_WORKSPACE_ID:-}"
[ -n "$workspace_id" ] || exit 0

herdr_bin="${HERDR_BIN_PATH:-herdr}"

"$herdr_bin" workspace list 2>/dev/null |
    jq -r --arg ws "$workspace_id" \
        '.result.workspaces[] | select(.workspace_id == $ws) | .label'