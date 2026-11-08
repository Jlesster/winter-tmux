#!/usr/bin/env bash
# winter-tmux: the tmux half of winter's pane negotiation.
#
# winter sets the pane option @pane-is-winter on start and clears it on exit.
# This plugin binds C-w in the root table so that:
#   - in an editor pane (winter, or nvim / smart-splits) C-w passes through
#   - anywhere else C-w enters a key table that moves/splits tmux panes
#
# Needs tmux >= 3.1 (pane-scoped user options). Safe to re-source.

set -u

# get <@option> <default>: global user option with a fallback
get() {
    local v
    v=$(tmux show-option -gqv "$1" 2>/dev/null)
    printf '%s' "${v:-$2}"
}

prefix_key=$(get @winter-prefix-key C-w)
table=$(get @winter-table winter_win)
wrap=$(get @winter-wrap off)
editor_cmds=$(get @winter-editor-commands nvim)   # comma separated
resize=$(get @winter-resize off)
resize_step=$(get @winter-resize-step 1)

# ---- "is the pane running an editor?" -------------------------------------
# winter's flag, smart-splits' flag, then each process name in the list.
# #{||:a,b} takes exactly two operands, so fold the list into nested pairs.
is_editor='#{||:#{@pane-is-winter},#{@pane-is-vim}}'
IFS=',' read -ra cmds <<<"$editor_cmds"
for c in "${cmds[@]}"; do
    [ -n "$c" ] || continue
    is_editor="#{||:${is_editor},#{==:#{pane_current_command},${c}}}"
done

# ---- root binding ---------------------------------------------------------
tmux bind-key -n "$prefix_key" if-shell -F "$is_editor" \
    "send-keys $prefix_key" \
    "switch-client -T $table"

# ---- the key table --------------------------------------------------------
# move <key> <select-pane flag> <edge format>
move() {
    if [ "$wrap" = on ]; then
        tmux bind-key -T "$table" "$1" select-pane "$2"
    else
        # at the edge: do nothing (empty then-branch), otherwise move
        tmux bind-key -T "$table" "$1" if-shell -F "#{$3}" '' "select-pane $2"
    fi
}

move h -L pane_at_left
move j -D pane_at_bottom
move k -U pane_at_top
move l -R pane_at_right
# winter maps <C-w><C-h> etc. as well, so the table does too
move C-h -L pane_at_left
move C-j -D pane_at_bottom
move C-k -U pane_at_top
move C-l -R pane_at_right

tmux bind-key -T "$table" s split-window -v -c '#{pane_current_path}'
tmux bind-key -T "$table" v split-window -h -c '#{pane_current_path}'
tmux bind-key -T "$table" c kill-pane
tmux bind-key -T "$table" q kill-pane
tmux bind-key -T "$table" o kill-pane -a
tmux bind-key -T "$table" w select-pane -t ':.+'
tmux bind-key -T "$table" W select-pane -t ':.-'
tmux bind-key -T "$table" p last-pane

# ---- optional: resize keys that reach the editor --------------------------
if [ "$resize" = on ]; then
    rz() {  # <key> <resize-pane flag>
        tmux bind-key -n "$1" if-shell -F "$is_editor" \
            "send-keys $1" \
            "resize-pane $2 $resize_step"
    }
    rz M-h -L
    rz M-j -D
    rz M-k -U
    rz M-l -R
fi
