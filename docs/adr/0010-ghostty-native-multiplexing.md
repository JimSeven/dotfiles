# Ghostty native multiplexing — no tmux

The terminal is organised **inside Ghostty** — native splits, tabs and a global
quick terminal — with **one window per project/task** and splits for the roles that
project needs (agent · shell · server). We deliberately **do not** run a terminal
multiplexer (tmux/zellij) underneath.

The daily reality this optimises for is AI-assisted development: several projects
open at once, each running a coding agent (Claude Code, Codex, opencode) alongside a
shell and a dev server. The failure mode is *disorientation* — a flat pile of tabs
where nothing signals what belongs together — not a lack of session persistence.
Ghostty's own splits, per-window grouping, dimmed inactive splits and shell-driven
tab titles solve the disorientation directly; a multiplexer solves a problem
(detach/reattach, survive-disconnect) we don't currently have.

**Why not tmux (yet):** its one superpower Ghostty lacks is background sessions that
survive a closed terminal or a dropped SSH connection. Our work is almost entirely
**local**, so that superpower buys little, while the cost is real: a second keybind
layer to learn, and it masks Ghostty features we rely on (GPU scrollback, clickable
links, prompt marks that power `jump_to_prompt`). Adding it now would be versioning
complexity against a need we don't have — the same "minimal core that never rots"
test from [ADR-0009](./0009-minimal-deterministic-whole-machine-core.md).

**Revisit trigger:** if remote/SSH work becomes routine, or sessions genuinely need
to outlive a terminal restart, reopen this decision — tmux (or Ghostty's own future
session features) earns its keep then, not before.

The config itself is text, deterministic and survives runtime churn, so it stays
versioned per [ADR-0009](./0009-minimal-deterministic-whole-machine-core.md); it is
one of the text tool-configs [ADR-0007](./0007-canonical-defaults-bridged-per-tool.md)
keeps in the repo rather than as opaque GUI state.

Consequences — what this admits and what it deliberately excludes:

- **Splits/tabs stay on Ghostty defaults.** `⌘D`/`⌘⇧D` split, `⌘[`/`⌘]` and
  `⌘⌥←↑↓→` move focus, `⌘⌃←↑↓→` resize, `⌘⇧↵` zooms a split, `⌘1`…`⌘8` jump to a
  tab. We add **only** non-default binds, so there is less to maintain and nothing
  to relearn after a Ghostty update. The cheat-sheet lives in
  [`docs/GUIDE.md`](../GUIDE.md#terminal-workflow).
- **Two custom keybinds only:** a global quick terminal (`⌘\``) for throwaway
  commands that must not disturb a project layout, and prompt jumping (`⌘↑`/`⌘↓`)
  to navigate long agent output by command boundary.
- **Config tuned for agent output:** 50 MB scrollback per pane, and
  `notify-on-command-finish = unfocused` so a background agent/build pings a real
  macOS notification when it finishes and you've already looked away.
- **Dimmed inactive splits** (`unfocused-split-opacity`) make the focused pane
  obvious — the direct antidote to "which pane am I in?".
- **Paste protection stays on** (default). Copying an LLM- or web-suggested command
  is a live risk vector; the guard against auto-executing a pasted command with a
  hidden newline is worth one extra keypress.
- **Deliberately out of scope:** tmux/zellij, and any multi-machine terminal
  profile. Not on spec, and the quit-time `window-save-state` already restores the
  project windows on next launch.
