# AI agent config: version managed config, never runtime state

The home-directory dotfolders of AI agent tools (`~/.claude`, `~/.codex`, opencode)
interleave user-authored config with machine-generated runtime state and secrets. We
version only the **managed config** — `settings.json`, `CLAUDE.md`, `rules/`, `agents/`,
self-authored `skills/`, statusline, and the Identity — via a plain (never `exact_`)
chezmoi directory plus a strict `.chezmoiignore`. **Runtime state** (credentials, session
transcripts, history, caches, installed plugin payloads, SQLite logs) is never added.
Plugins and installed third-party skill collections are reproduced declaratively
(`extraKnownMarketplaces`/`enabledPlugins`, the installer skill) rather than vendored.

Consequences:

- `exact_` on an agent dotfolder is **forbidden** — it would delete every unmanaged
  runtime file on the next `chezmoi apply`, wiping credentials, transcripts and 100s of MB
  of plugins.
- Because the repo is **public**, `~/.claude/.credentials.json` and `~/.codex/auth.json`
  are never managed (re-authenticate per machine), and a **gitleaks pre-commit hook** guards
  every commit against a pasted secret in an otherwise-tracked file.
- `settings.json` is a chezmoi template so the private company marketplace
  (`skills-leadership`) is gated behind machine data and stays out of the public repo.
