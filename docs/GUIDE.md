# Guide — from a fresh Mac to daily use

The complete walkthrough for this setup: what it is, how to bring up a brand-new
Mac end to end, and how to live with it day to day. This is the deep version;
[`README.md`](../README.md) is the landing page, [`CONTEXT.md`](../CONTEXT.md)
defines the vocabulary, and [`docs/adr/`](./adr/) holds the *why* behind every
decision. This guide links to those rather than repeating them.

**Contents**

1. [Overview](#overview)
2. [Fresh-Mac walkthrough](#fresh-mac-walkthrough)
3. [Daily use](#daily-use)
4. [Architecture tour](#architecture-tour)
5. [AI agent config](#ai-agent-config)
6. [Troubleshooting](#troubleshooting)
7. [Manual-steps checklist](#manual-steps-checklist)

---

## Overview

The repo is the **single source of truth** for one Mac: dotfiles, installed
software, macOS preferences, and secrets *wiring* (never the secrets themselves).

**Source → `$HOME`.** [chezmoi](https://www.chezmoi.io) renders the versioned
**Source state** under [`home/`](../home/) into your home directory. You never
edit `~/.zshrc` directly — you edit the source and **Apply** (`chezmoi apply`) to
converge `$HOME` with the repo. See the *Source state*, *Apply*, and *Bootstrap*
terms in [`CONTEXT.md`](../CONTEXT.md); the choice of chezmoi is
[ADR-0001](./adr/0001-chezmoi-as-dotfile-manager.md).

**Managed vs Runtime.** Only a small, durable, non-secret set of files is
version-controlled (**Managed config**). Machine-generated state — credentials,
caches, session transcripts, history (**Runtime state**) — is never committed,
excluded via `.chezmoiignore`. This split matters most for the AI agent
dotfolders; see [ADR-0006](./adr/0006-agent-config-managed-vs-runtime.md) and the
*Managed config* / *Runtime state* terms in [`CONTEXT.md`](../CONTEXT.md).

**What is deliberately *not* automated** — because it can't be, or isn't worth
it: the Mac App Store sign-in, the 1Password login, the commit-signing key, loose
skill collections and MCP servers ([ADR-0006](./adr/0006-agent-config-managed-vs-runtime.md)).
All of it is collected in the [Manual-steps checklist](#manual-steps-checklist).

---

## Fresh-Mac walkthrough

Bootstrap runs in **two phases** because Apply needs a live 1Password session for
the secret-bearing templates, and a fresh Mac has none yet
([ADR-0002](./adr/0002-secrets-via-1password.md)). Work top to bottom.

### Before you start — prerequisites

| Prerequisite | Why | Check |
| --- | --- | --- |
| Signed into macOS with an admin account | Apply runs one `sudo` command (`nvram StartupMute`) | you can open **System Settings** |
| **Apple ID signed into the App Store app** | the Manifest installs Keynote, Numbers, Pages, WireGuard via `mas`; Apple allows **no** CLI sign-in | App Store → your name shows at the bottom of the sidebar |
| Access to your 1Password account | SSH auth + commit signing resolve from it at Apply time | you can log in on another device |
| Internet | Homebrew, casks, mas, git clone | — |

> **The App Store sign-in must happen before Phase 2.** `mas` cannot log in from
> the CLI, so if you skip it the four `mas` entries in the
> [Brewfile](../home/Brewfile) fail to install (the rest of the Manifest still
> installs). Open the **App Store** app and sign in now.

### Phase 1 — prerequisites + 1Password

```sh
curl -fsSL https://raw.githubusercontent.com/JimSeven/dotfiles/main/scripts/bootstrap.sh | bash
```

[`scripts/bootstrap.sh`](../scripts/bootstrap.sh) installs the Xcode Command Line
Tools (if the dialog appears, finish it and re-run), Homebrew, the 1Password
app + CLI, and Herd — then stops.

Now:

1. Open 1Password and **sign in**.
2. **Settings → Developer → enable "Use the SSH agent".** This is what makes SSH
   auth and commit signing work; `~/.ssh/config` already routes `Host *` through
   the agent socket and is intentionally *not* managed by chezmoi
   ([ADR-0002](./adr/0002-secrets-via-1password.md)).
3. **Open Herd once** and let it finish its setup. This installs its bundled PHP
   and `composer`, which phase 2's global-Composer provisioning step needs
   ([ADR-0003](./adr/0003-herd-owns-php-and-node.md)). Skip this and the Composer
   CLIs are simply skipped (the Apply still succeeds); open Herd and re-apply to
   get them.

### Phase 2 — install everything and apply

```sh
curl -fsSL https://raw.githubusercontent.com/JimSeven/dotfiles/main/scripts/bootstrap.sh | bash -s -- --continue
```

This installs chezmoi and runs `chezmoi init --apply JimSeven/dotfiles`, which:

- **Enables Touch ID for `sudo`** first
  ([`run_once_before_05-touch-id-sudo`](../home/run_once_before_05-touch-id-sudo.sh)) —
  writes `/etc/pam.d/sudo_local`, **prompting once for your password**; every
  later `sudo` this run (and after) can authenticate by touch
  ([ADR-0009](./adr/0009-minimal-deterministic-whole-machine-core.md)).
- **Installs the Manifest** — `brew bundle` over the [Brewfile](../home/Brewfile)
  (formulae, casks, `mas` apps, VS Code extensions), via the
  [`run_onchange_before_10-install-packages`](../home/run_onchange_before_10-install-packages.sh.tmpl)
  Provisioning script.
- **Links every dotfile** into `$HOME` (`dot_zshrc` → `~/.zshrc`, …).
- **Applies macOS defaults**
  ([`run_onchange_after_20-macos-defaults`](../home/run_onchange_after_20-macos-defaults.sh)) —
  Dock, keyboard, Finder, trackpad (`sudo nvram StartupMute`).
- **Rebuilds the Dock**
  ([`run_onchange_after_30-dock`](../home/run_onchange_after_30-dock.sh) via `dockutil`).
- **Installs global Composer CLIs**
  ([`run_onchange_after_40-composer-global`](../home/run_onchange_after_40-composer-global.sh)) —
  Forge CLI, `laravel new`, Statamic, Ray ([ADR-0009](./adr/0009-minimal-deterministic-whole-machine-core.md)).
- **Runs Verification**
  ([`run_after_90-verify.sh`](../home/run_after_90-verify.sh)) last — see
  [Troubleshooting](#troubleshooting) for reading its output.

### After first apply — finish the manual steps

1. **Replace the commit-signing key.** [`home/dot_gitconfig.tmpl`](../home/dot_gitconfig.tmpl)
   ships a **placeholder** `signingkey`. Replace it with *your* public SSH signing
   key (1Password → your SSH key → "public key"), then `chezmoi apply`. Until you
   do, commits are signed with a key that isn't yours.
2. **Enable the pre-commit secret gate** (once per clone), if you'll commit to
   this repo:
   ```sh
   git config core.hooksPath .githooks
   ```
   See [Secret gate](#the-secret-gate) below and
   [ADR-0006](./adr/0006-agent-config-managed-vs-runtime.md).
3. **Re-authenticate the AI agents** per machine (Claude Code, Codex, opencode) —
   their credentials are Runtime state and are never committed
   ([ADR-0006](./adr/0006-agent-config-managed-vs-runtime.md)).
4. Open **Ghostty** or restart your shell to pick up the new zsh config.

Some macOS defaults need a logout/restart to fully take effect.

---

## Daily use

You edit the **source**, then **Apply**. Never edit the rendered file in `$HOME`
directly — the next Apply would overwrite it.

```sh
chezmoi edit ~/.zshrc      # edit a managed file in the source, in $EDITOR
chezmoi apply              # converge $HOME with the source
chezmoi update             # git pull the source, then apply
chezmoi cd                 # jump into the source directory
chezmoi diff               # preview what an apply would change
```

### Adding / removing packages

The [Brewfile](../home/Brewfile) is the **Manifest** — the declarative list of
everything the machine should have. To **add** a package, add a `brew`/`cask`/
`mas`/`vscode` line; the next `chezmoi apply` re-runs `brew bundle` automatically
(the Provisioning script is keyed on the Brewfile's hash, so it only re-runs when
the Brewfile changes).

**Removal is manual, by design** (the *Manifest* term in
[`CONTEXT.md`](../CONTEXT.md)): deleting a line does **not** uninstall anything.
To see what's installed but no longer listed:

```sh
brew bundle cleanup --file="$(chezmoi source-path)/Brewfile"   # reports only
brew bundle cleanup --file="$(chezmoi source-path)/Brewfile" --force   # actually removes
```

Local dev services (Postgres, Redis, …) are deliberately **not** in the Manifest —
they run per-project in OrbStack containers
([ADR-0005](./adr/0005-dev-services-per-project-in-orbstack.md)).

### Editing shell config

`~/.zshrc` is thin; each concern lives in a numbered **Shell module** under
`~/.config/zsh` (`00-path`, `10-env`, … `50-herd`, `60-projects`), sourced in
prefix order ([ADR-0004](./adr/0004-modular-zsh-with-local-escape-hatch.md)). Add
a concern by adding/editing one small module — `chezmoi edit ~/.config/zsh/30-aliases.zsh`.

Machine-specific tweaks that should *not* be version-controlled go in
`~/.zshrc.local` (the **Machine-local override**), which chezmoi does not manage.
It also absorbs tool auto-injections (e.g. Herd writing into your shell config).

### Capturing macOS settings

macOS system preferences are applied by
[`run_onchange_after_20-macos-defaults`](../home/run_onchange_after_20-macos-defaults.sh)
(a curated list of `defaults write` calls) and the Dock by
[`run_onchange_after_30-dock`](../home/run_onchange_after_30-dock.sh). Both are
**best-effort**: a TCC-protected domain (Contacts, Calendar) or a not-yet-installed
app is skipped with a warning, never aborting the Apply.

To fold a setting you changed in **System Settings** into the repo, use the
discovery helper — it reads the *current* value for a curated vocabulary of keys
(mouse/trackpad speed, gestures, Dock, Finder, …) and prints ready-to-review
`defaults write` lines. It never writes anything itself:

```sh
bash scripts/capture-defaults.sh              # all captured settings
bash scripts/capture-defaults.sh | grep -i mouse   # just the mouse keys
```

For a setting whose `defaults` domain/key you *don't* know — anything not in the
curated list, e.g. most of **System Settings › Accessibility** — use discovery
mode. It snapshots the common UI domains, waits while you change one setting,
then prints exactly which key moved (and a ready `defaults write` line for it):

```sh
bash scripts/capture-defaults.sh --watch      # then toggle the setting, press Enter
```

Copy the line(s) into `home/run_onchange_after_20-macos-defaults.sh` (or the
emitted `dockutil --add` lines into `run_onchange_after_30-dock.sh`), then
`chezmoi apply`. This stays deliberately hand-curated rather than a full machine
snapshot ([ADR-0009](./adr/0009-minimal-deterministic-whole-machine-core.md)); to
widen coverage, add a `domain|key` pair to the list in the helper.

For the settings already managed in the provisioning script, the interactive
companion does the copy for you:

```sh
bash scripts/sync-defaults.sh            # reconcile machine ↔ repo, prompt per drift
bash scripts/sync-defaults.sh --dry-run  # just list what differs
```

It compares each managed value against the machine's current value, explains any
setting that drifted in plain language, and — on your confirmation — writes the
current value back into `run_onchange_after_20-macos-defaults.sh`. It edits the
repo source only; run `chezmoi apply` afterwards to apply.

### Shell secrets & global CLI tools

**Secrets are never exported into the shell.** A globally exported API token leaks
into every child process; it is a hazard, not a convenience. Resolve secrets
**on demand** instead ([ADR-0009](./adr/0009-minimal-deterministic-whole-machine-core.md),
extending [ADR-0002](./adr/0002-secrets-via-1password.md)):

```sh
op run --env-file=.env -- <cmd>   # inject 1Password refs for one command
# or, per project, an .envrc that direnv loads (direnv is already wired in)
```

**Reproducible CLI tools go in the [Brewfile](../home/Brewfile).** Homebrew is the
deterministic source. Two exceptions are ecosystem-only and not in brew:

- **Global Composer CLIs** are provisioned automatically on every apply
  ([`run_onchange_after_40-composer-global`](../home/run_onchange_after_40-composer-global.sh)) —
  add a package to that script's list and re-apply.
- **Global npm CLIs** are **not** automated: they live under Herd's NVM and break
  on a Node switch ([ADR-0003](./adr/0003-herd-owns-php-and-node.md)), so they are a
  manual step — see the [checklist](#manual-steps-checklist).

### The secret gate

The repo is public, so [gitleaks](https://github.com/gitleaks/gitleaks) guards it
at two points ([ADR-0006](./adr/0006-agent-config-managed-vs-runtime.md)): a
pre-commit hook on staged changes, and CI re-scanning the whole tree on every
push. Enable the local hook once per clone with
`git config core.hooksPath .githooks`. `gitleaks` ships in the Brewfile.

---

## Architecture tour

A map of the moving parts. Each links to the decision that owns its rationale —
follow the ADR for the *why*, [`CONTEXT.md`](../CONTEXT.md) for the exact term.

| Part | What it is | Decision |
| --- | --- | --- |
| **chezmoi** | Dotfile manager; renders `home/` → `$HOME` | [ADR-0001](./adr/0001-chezmoi-as-dotfile-manager.md) |
| **Bootstrap** | Two-phase fresh-Mac script | [ADR-0002](./adr/0002-secrets-via-1password.md) |
| **Secrets / 1Password** | SSH agent + commit signing + `op` templates; no secrets in repo | [ADR-0002](./adr/0002-secrets-via-1password.md) |
| **Manifest (Brewfile)** | Declarative package list; removal manual | [ADR-0001](./adr/0001-chezmoi-as-dotfile-manager.md) |
| **PHP & Node** | Laravel Herd owns both; no mise/asdf | [ADR-0003](./adr/0003-herd-owns-php-and-node.md) |
| **Shell modules** | Thin `~/.zshrc` + numbered modules + `.local` escape hatch | [ADR-0004](./adr/0004-modular-zsh-with-local-escape-hatch.md) |
| **Dev services** | Per-project OrbStack containers, not brew daemons | [ADR-0005](./adr/0005-dev-services-per-project-in-orbstack.md) |
| **Agent config** | Managed vs Runtime split; gitleaks gate | [ADR-0006](./adr/0006-agent-config-managed-vs-runtime.md) |
| **Agent Defaults + Bridges** | One canonical Defaults file, bridged per tool | [ADR-0007](./adr/0007-canonical-defaults-bridged-per-tool.md) |
| **Verification** | Post-apply `run_after` seam, on-machine only | [ADR-0008](./adr/0008-post-apply-verification-on-machine.md) |
| **Minimal core** | What the repo versions vs. leaves manual; whole-machine scope | [ADR-0009](./adr/0009-minimal-deterministic-whole-machine-core.md) |

Repository layout is in [`README.md`](../README.md#repository-layout).

---

## AI agent config

Three coding agents — Claude Code (`~/.claude`), Codex (`~/.codex`), opencode
(`~/.config/opencode`) — share **one canonical Defaults file**,
`~/.config/agents/defaults.md`: a lean, public-safe profile plus tool- and
domain-neutral working rules ([ADR-0007](./adr/0007-canonical-defaults-bridged-per-tool.md);
the *Defaults* / *Bridge* terms in [`CONTEXT.md`](../CONTEXT.md)).

Each tool **bridges** to that one file instead of holding a copy, so drift is
structurally impossible:

- **Claude** — an `@~/.config/agents/defaults.md` import line in `~/.claude/CLAUDE.md`.
- **Codex** — a symlink from its native `~/.codex/AGENTS.md`.
- **opencode** — an `instructions` entry in `~/.config/opencode/opencode.json`.

The post-apply [Verification](../home/run_after_90-verify.sh) asserts all three
bridges resolve to the Defaults on every Apply
([ADR-0008](./adr/0008-post-apply-verification-on-machine.md)).

**Deliberately out of scope** ([ADR-0006](./adr/0006-agent-config-managed-vs-runtime.md)):
loose skill collections (interactive installers — re-install per machine), MCP
servers (their wiring lives in mutable/runtime files; auth is always runtime), and
empty `agents/` / `commands/` dirs. Credentials are Runtime state — re-authenticate
each agent per machine.

### Inventory & provenance

Skills and MCP wiring aren't versioned — but *knowing what you have and where it
comes from* is the point ([ADR-0009](./adr/0009-minimal-deterministic-whole-machine-core.md)).
This map is the source of truth for re-establishing the agent setup; it lists
**origins**, not every individual skill (individual skills churn, origins don't):

| Origin | Re-establish | Automatic? |
| --- | --- | --- |
| Self-authored skills | clone your skills repo into `~/.claude/skills` | ❌ own repo (tracked separately) |
| Third-party skill sets (e.g. Matt Pocock, Obsidian) | each set's own installer (`npx …`) | ❌ manual |
| Plugin marketplace (`leadership-toolkit`) | gated in `settings.json` | ✅ on apply (work machines) |
| MCP connectors (Gmail, GCal, Drive, Slack, Notion, Sentry, Atlassian, …) | sign into claude.ai | ✅ follows the account |
| Local MCP servers (`attio`, `clockify`) | re-add by hand in `~/.claude.json` | ❌ manual |

---

## Troubleshooting

### Reading the Verification output

[`run_after_90-verify.sh`](../home/run_after_90-verify.sh) runs at the end of
every Apply and prints one line per invariant. All-`PASS` and it exits quietly;
any `FAIL` and it exits non-zero (loud) so a broken bridge can't rot silently
([ADR-0008](./adr/0008-post-apply-verification-on-machine.md)):

```
verify: agent Bridges resolve to the canonical Defaults (ADR-0007)
  PASS  Defaults file exists
  FAIL  Codex bridge -> Defaults
  ...
verify: one or more checks failed — fix before relying on this machine
```

| FAIL line | Likely cause | Fix |
| --- | --- | --- |
| `Defaults file exists` | `~/.config/agents/defaults.md` didn't render | re-run `chezmoi apply`; check the source under [`home/dot_config`](../home/dot_config/) |
| `Codex bridge -> Defaults` | `~/.codex/AGENTS.md` symlink missing/wrong | `chezmoi apply`; verify the symlink target is the Defaults path |
| `Claude bridge imports Defaults` | `@import` line missing from `~/.claude/CLAUDE.md` | `chezmoi apply`; confirm the import line is present |
| `opencode bridge -> Defaults` | `instructions` entry missing in `opencode.json` | `chezmoi apply` |
| `Herd integration path present` | Herd updated and moved its integration script | open Herd once, then re-run; see [ADR-0003](./adr/0003-herd-owns-php-and-node.md) |

The Herd check only runs when `/Applications/Herd.app` exists, so it never
false-positives on a non-Herd machine.

### Common fresh-Mac failure modes

| Symptom | Cause | Fix |
| --- | --- | --- |
| `mas` apps (iWork, WireGuard) not installed | not signed into the App Store app before Phase 2 | sign in, then `chezmoi apply` |
| Templates fail to render / `op` errors during Phase 2 | 1Password not signed in, or SSH agent not enabled | complete the Phase 1 1Password steps, re-run Phase 2 |
| Commits signed with the wrong key | `signingkey` placeholder not replaced | replace it in [`dot_gitconfig.tmpl`](../home/dot_gitconfig.tmpl), `chezmoi apply` |
| `brew bundle` can't find `brew` | Homebrew not on PATH in a fresh shell | re-run the bootstrap; open a new shell |
| A Dock app is missing | the app's cask/mas entry didn't install | fix the Manifest install, then re-run — the Dock script skips gracefully if `dockutil` is absent |
| Herd check fails after a Herd update | integration path moved | open Herd, re-run `chezmoi apply` |

When in doubt: `chezmoi diff` to see what an Apply *would* do, then `chezmoi apply`
again — it is idempotent.

---

## Manual-steps checklist

Everything that is **not** automated, in one place. Order matters where noted.

- [ ] **Sign into the App Store app** with your Apple ID — **before Phase 2**
      (`mas`: Keynote, Numbers, Pages, WireGuard; no CLI sign-in exists).
- [ ] **Phase 1** bootstrap, then in **1Password**: sign in **and** enable
      **Settings → Developer → Use the SSH agent**.
- [ ] **Open Herd once** (installed in Phase 1) so its bundled PHP + `composer`
      exist before Phase 2 — otherwise the global Composer CLIs are skipped.
- [ ] Provide your **password** at Phase 2's first `sudo` prompt (the Touch ID
      setup step); after that, `sudo` this run can authenticate by touch.
- [ ] **Replace the `signingkey` placeholder** in
      [`home/dot_gitconfig.tmpl`](../home/dot_gitconfig.tmpl) with your public SSH
      signing key from 1Password, then `chezmoi apply`.
- [ ] **Enable the pre-commit secret gate** if committing here:
      `git config core.hooksPath .githooks`.
- [ ] **Re-authenticate each AI agent** (Claude Code, Codex, opencode) —
      credentials are Runtime state, never committed.
- [ ] **Re-establish agent skills & MCP** per the
      [inventory & provenance map](#inventory--provenance): clone the self-authored
      skills repo, run any third-party set installers, re-add the local MCP servers
      (`attio`, `clockify`). Connectors and the plugin marketplace come back on
      their own.
- [ ] **Re-install global npm CLIs** by hand (fragile under Herd's NVM, not
      automated): `@playwright/cli`, `attio-cli`. (Composer CLIs are automated.)
- [ ] **Logout/restart** so the remaining macOS defaults take effect.
