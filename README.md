# winter-tmux

The tmux half of winter's pane negotiation.

winter sets the pane option `@pane-is-winter` when it starts and clears it
when it exits. This plugin makes `C-w` pass through to editor panes (winter,
nvim, smart-splits) and enter a tmux key table everywhere else.

Requires tmux 3.1+.

## Install

TPM:

set -g @plugin 'Jlesster/winter-tmux'

Or by hand, near the end of `tmux.conf`:

run-shell ~/path/to/winter-tmux/winter.tmux

Delete any existing `bind -n C-w ...`. The root table holds one binding per
key, so whichever loads last wins.

## Options (set before the plugin loads)

| option                    | default     | meaning                                         |
|---------------------------|-------------|-------------------------------------------------|
| `@winter-prefix-key`      | `C-w`       | key that starts the window chord                |
| `@winter-table`           | `winter_win`| name of the key table                           |
| `@winter-wrap`            | `off`       | `on` wraps focus around at pane edges           |
| `@winter-editor-commands` | `nvim`      | comma list of process names that pass the key through |
| `@winter-resize`          | `off`       | `on` binds `M-h/j/k/l` to resize, passing through in editors |
| `@winter-resize-step`     | `1`         | cells per resize                                |

## Table keys

`h j k l` and `C-h C-j C-k C-l` move; `s` / `v` split; `c` / `q` close;
`o` closes the others; `w` / `W` cycle; `p` goes to the last pane.

## Check

tmux list-keys -T root | grep C-w
tmux list-keys -T winter_win
    tmux show -pv -t "$TMUX_PANE" @pane-is-winter   # run in the winter pane; prints 1
