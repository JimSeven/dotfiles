# VS Code settings as a global best-practice baseline

`settings.json` (in chezmoi at `home/Library/Application Support/Code/User/settings.json`) is a
single **global** baseline — no per-stack profiles (cf. Profiles-Strategie decision) and no
Settings-Sync categories (cf. Source-of-Truth decision). Stack-specific behaviour that cannot be
safely global lives in a committed `.vscode/settings.json` in the project repo instead.

The non-obvious choices, recorded so they are not "cleaned up" later by mistake:

- **No global `editor.defaultFormatter`.** A global default of Prettier plus `formatOnSave` makes
  VS Code attempt Prettier on PHP/Python/YAML, which have no Prettier parser — a silent no-op or
  error. Formatters are therefore bound **per language** (`[javascript]`, `[typescript]`,
  `[css]`, `[blade]`, …), and languages without a safe global formatter are left unbound.

- **`prettier.requireConfig: true`.** Prettier only formats where a Prettier config exists in the
  project. Prevents Prettier from silently reformatting files in repos that do not use it.

- **`[php]` deliberately unbound globally.** Pint (`open-southeners.laravel-pint`) is
  Laravel-specific; binding it globally would reformat non-Laravel PHP to Laravel style. Pint is
  bound per project in `.vscode/settings.json` — the global-vs-project boundary in practice.

- **`files.autoSave: "onFocusChange"`.** Saves at a natural checkpoint (file/window/terminal
  switch) rather than mid-keystroke (`afterDelay` moves the cursor while typing) or never (`off`
  leaves dirty buffers). Chosen to pair cleanly with `formatOnSave` + `source.fixAll.eslint`.

- **Performance excludes.** `files.watcherExclude`/`search.exclude` cover the heavy dirs VS Code
  does not exclude by default (`vendor/`, `storage/framework/`, `dist/`, `build/`); `node_modules`
  is already a built-in watcher exclude.

- **`git.branchProtection: ["main", "master"]`.** Prompts before committing directly to the
  protected branches — a safety default, not a hard block.

- **Telemetry off** (`telemetry.telemetryLevel: "off"`, `redhat.telemetry.enabled: false`) is a
  standing privacy default across the machine, not a per-tool afterthought.

- **AI assistants split by role, not stacked.** Claude Code and Codex are agentic/panel-only (no
  inline completions), so they do not compete for the inline slot; Copilot owns it exclusively for
  autocomplete. Copilot is **not** in the extension canon: since VS Code 1.130 `GitHub.copilot-chat`
  ships as a built-in that provides the inline completions itself, so the standalone `github.copilot`
  extension is obsolete (and un-installable via `brew bundle` — its pack drags in an older
  `copilot-chat` that cannot downgrade the built-in). It is configured, not installed:
  `github.copilot.enable` scopes it out of prose (`markdown`, `plaintext`) and the SCM commit box
  (`scminput`, since commits run through `vscode-conventional-commits`); a GitHub login activates the
  free tier. Codex keys (`chatgpt.openOnStartup`, `chatgpt.commentCodeLensEnabled`) are pinned to
  silence startup panel and per-comment CodeLens rather than left to drift on their defaults.

Consequences:

- The extension canon (see Brewfile) and this file are coupled: a per-language formatter binding
  assumes its formatter extension is in the canon (`shufo.vscode-blade-formatter` for `[blade]`).
  Dropping an extension means revisiting its binding here.
- Markdown/YAML are intentionally left without a global formatter binding; add one per project if
  a repo wants it, rather than forcing a house style everywhere.
- The file stays commented by section so a fresh machine reads the rationale inline; this ADR
  holds only the choices whose "why" does not fit a one-line comment.
- It is handled seed-once-then-ignore (ADR-0012): chezmoi seeds the baseline on a fresh
  machine, then a template-guarded `.chezmoiignore` hands the file off to VS Code's runtime
  writes so it never prompts. Consequence: once seeded the file is **unmanaged**, so
  `chezmoi apply --force '<path>'` does **not** re-apply it (it reports "not managed"). Roll
  baseline changes to an existing machine by hand-merging the changed keys into the live file,
  preserving any keys VS Code/extensions have written at runtime (e.g. `claudeCode.useTerminal`,
  `chat.viewSessions.orientation`) — diff source against the live file first, then apply only the
  delta. Alternatively delete the live file and re-`apply` to re-seed, but that discards those
  runtime keys.
