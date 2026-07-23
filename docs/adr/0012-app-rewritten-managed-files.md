# Handling app-rewritten managed files without apply-time prompts

Six managed files are rewritten at runtime by the apps that own them, so every
`chezmoi apply` prompted "X has changed since chezmoi last wrote it":
`.gitconfig` (gh), `~/.gitignore`, `.codex/config.toml` (Codex trust), `.zshrc`
(Herd), VS Code `settings.json`, `.claude/settings.json` (Claude Code).

There is no single fix — the right technique depends on whether the app's writes
are deterministic, redundant, or genuine machine-local state worth preserving:

- **Fold deterministic writes into the source.** `gh auth setup-git` writes a
  fixed `[credential]` block, so it is baked verbatim into `dot_gitconfig.tmpl`
  and source == target. `~/.gitignore`'s one extra rule was pulled in with
  `chezmoi re-add`. (ADR-0002)

- **Seed once, then ignore (JSONC we can't safely merge).** VS Code
  `settings.json` is JSONC (comments + trailing commas) that no CLI JSON tool can
  merge without destroying the comments. A template-guarded `.chezmoiignore`
  entry seeds the curated baseline on a fresh machine, then ignores the file once
  present. Baseline changes ship deliberately via `chezmoi apply --force`. (ADR-0011)

- **modify_ script that strips redundant writes.** Herd re-injects
  `HERD_PHP_*_INI_SCAN_DIR` into `.zshrc`, but `50-herd.zsh` already exports them
  portably, so `modify_dot_zshrc` always emits the thin baseline and discards the
  injections. (ADR-0004)

- **modify_ script that preserves genuine runtime state.** Codex project-trust
  entries and Claude Code's own toggles are real machine-local state with no other
  source. `modify_private_config.toml` re-appends the `[projects."…"]` blocks;
  `modify_settings.json.tmpl` jq-deep-merges the target under the baseline
  (baseline wins, runtime keys kept, formatting/key order normalised). Neither is
  ever committed. (ADR-0006)

The property exploited by the last two: **`modify_` scripts never trigger the
"changed since chezmoi last wrote it" prompt** — by contract they read the current
target on stdin, so an idempotent script silences the prompt permanently, where a
plain file would prompt on every external rewrite.

Consequences:

- Three `modify_` scripts run on every apply. They must stay idempotent —
  `chezmoi cat <target>` must byte-match a settled target — or drift returns.
  Verified at authoring time with a `diff <(chezmoi cat …) <target>` check.
- The VS Code baseline no longer auto-syncs to existing machines; roll changes
  out with a targeted `chezmoi apply --force '~/Library/.../settings.json'`.
- `.claude/settings.json` keeps whatever `permissions.allow` the target carries
  (runtime, never versioned); prune it in Claude if unwanted.
- `modify_` prefix order is `modify_private_…`, not `private_modify_…` (chezmoi
  parses the type prefix before permission attributes for these scripts).
