# dotfiles

![CI](https://github.com/JimSeven/dotfiles/actions/workflows/ci.yml/badge.svg)

A personal, reproducible macOS setup. One command turns a fresh Mac into a fully
configured machine — dotfiles, apps, system preferences and secrets wiring, all
from a single source of truth.

Managed with [chezmoi](https://www.chezmoi.io). The full walkthrough — fresh Mac
to daily use — is in **[`docs/GUIDE.md`](./docs/GUIDE.md)**;
[`docs/adr/`](./docs/adr/) holds the architectural decisions and
[`CONTEXT.md`](./CONTEXT.md) the project's vocabulary.

## Quick start (fresh Mac)

Two phases, because commit signing and SSH go through 1Password (see
[ADR-0002](./docs/adr/0002-secrets-via-1password.md)). **Sign into the App Store
app before phase 2** — the Brewfile installs `mas` apps (iWork, WireGuard) that
have no CLI sign-in.

```sh
# Phase 1 — prerequisites + 1Password:
curl -fsSL https://raw.githubusercontent.com/JimSeven/dotfiles/main/scripts/bootstrap.sh | bash
# …then in 1Password: sign in + Settings → Developer → enable the SSH agent…

# Phase 2 — install everything and apply:
curl -fsSL https://raw.githubusercontent.com/JimSeven/dotfiles/main/scripts/bootstrap.sh | bash -s -- --continue
```

Phase 2 installs chezmoi and runs `chezmoi init --apply JimSeven/dotfiles`
(Brewfile, dotfiles, macOS defaults, Dock, verify). For the checkable
prerequisites, the post-apply steps (including the `signingkey` replacement), and
the full **manual-steps checklist**, follow
**[`docs/GUIDE.md`](./docs/GUIDE.md)**.

## What's inside

| Area            | Choice                                                        |
| --------------- | ------------------------------------------------------------- |
| Dotfile manager | chezmoi                                                       |
| Shell           | zsh + [antidote](https://getantidote.github.io/) + [Starship](https://starship.rs) |
| Terminal        | [Ghostty](https://ghostty.org)                                |
| PHP & Node      | [Laravel Herd](https://herd.laravel.com) (bundled PHP + NVM)  |
| Packages        | Homebrew via `brew bundle` ([Brewfile](./home/Brewfile))      |
| Secrets / SSH   | 1Password (SSH agent + commit signing)                        |
| Editor          | VS Code (extensions in the Brewfile)                          |
| Git GUI         | Fork · **Containers** OrbStack · **Launcher** Raycast         |

## Daily use

```sh
chezmoi edit ~/.zshrc      # edit a managed file in the source
chezmoi apply              # apply pending changes to $HOME
chezmoi update             # pull latest from git and apply
chezmoi cd                 # jump to the source directory
```

Add a package by editing [`home/Brewfile`](./home/Brewfile); the next
`chezmoi apply` re-runs `brew bundle` automatically. Removal is manual by design.
See [`docs/GUIDE.md`](./docs/GUIDE.md#daily-use) for adding/removing packages,
editing shell modules, and `chezmoi update`.

## Repository layout

```
.
├── home/                     # chezmoi source (applied to $HOME via .chezmoiroot)
│   ├── dot_*                 # dotfiles (dot_zshrc → ~/.zshrc, …)
│   ├── dot_config/           # ~/.config (starship, ghostty, zsh modules)
│   ├── Brewfile              # package manifest
│   └── run_onchange_*        # provisioning: brew bundle, macOS defaults, Dock
├── scripts/bootstrap.sh      # fresh-machine bootstrap
├── .githooks/pre-commit      # gitleaks secret gate (see below)
├── docs/adr/                 # architectural decisions
├── CONTEXT.md                # domain glossary
└── .github/workflows/ci.yml  # lint (shellcheck, Brewfile, chezmoi dry-run, gitleaks)
```

## Secret gate

The repo is public, so [gitleaks](https://github.com/gitleaks/gitleaks) guards
it at two points (see [ADR-0006](./docs/adr/0006-agent-config-managed-vs-runtime.md)):
a pre-commit hook scans staged changes, and CI re-scans the whole tree on every
push. Enable the local hook once per clone with
`git config core.hooksPath .githooks` — details in
[`docs/GUIDE.md`](./docs/GUIDE.md#the-secret-gate).

## License

[MIT](./LICENSE) © Steffen Rüther
