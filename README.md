# dotfiles

![CI](https://github.com/JimSeven/dotfiles/actions/workflows/ci.yml/badge.svg)

A personal, reproducible macOS setup. One command turns a fresh Mac into a fully
configured machine — dotfiles, apps, system preferences and secrets wiring, all
from a single source of truth.

Managed with [chezmoi](https://www.chezmoi.io). See
[`docs/adr/`](./docs/adr/) for the architectural decisions and
[`CONTEXT.md`](./CONTEXT.md) for the project's vocabulary.

## Quick start (fresh Mac)

Two phases, because commit signing and SSH go through 1Password (see
[ADR-0002](./docs/adr/0002-secrets-via-1password.md)).

**Phase 1 — prerequisites + 1Password:**

```sh
curl -fsSL https://raw.githubusercontent.com/JimSeven/dotfiles/main/scripts/bootstrap.sh | bash
```

Then open 1Password, sign in, and enable the SSH agent
(**Settings → Developer → Use the SSH agent**).

**Phase 2 — install everything and apply:**

```sh
curl -fsSL https://raw.githubusercontent.com/JimSeven/dotfiles/main/scripts/bootstrap.sh | bash -s -- --continue
```

This installs chezmoi and runs `chezmoi init --apply JimSeven/dotfiles`, which
installs all packages from the [Brewfile](./home/Brewfile), links every dotfile,
and applies the macOS defaults and Dock layout.

> **App Store apps:** the Brewfile installs a few apps via `mas` (iWork, WireGuard).
> Apple no longer permits CLI sign-in, so open the App Store app and sign in with
> your Apple ID **before** phase 2 — otherwise those `mas` entries are skipped.

> **After first apply:** replace the `signingkey` placeholder in
> [`home/dot_gitconfig.tmpl`](./home/dot_gitconfig.tmpl) with your public SSH
> signing key from 1Password, then `chezmoi apply`.

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
`chezmoi apply` re-runs `brew bundle` automatically. To see what's installed but
no longer listed:

```sh
brew bundle cleanup --file="$(chezmoi source-path)/Brewfile"   # reports only; removal is manual
```

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
push. Enable the local hook once per clone:

```sh
git config core.hooksPath .githooks
```

`gitleaks` ships in the [Brewfile](./home/Brewfile); if it's missing the hook
tells you to `brew install gitleaks`.

## License

[MIT](./LICENSE) © Steffen Rüther
