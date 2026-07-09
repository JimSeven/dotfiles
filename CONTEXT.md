# macOS Setup

A personal, reproducible macOS provisioning system: one command turns a fresh Mac
into a fully configured machine. The repository is the single source of truth for
dotfiles, installed software, macOS system preferences, and secrets wiring.

## Language

**Bootstrap**:
The single-command process that takes a fresh macOS install and produces a fully
configured machine (prerequisites → chezmoi → apply). Runs in two phases because of
the 1Password login step.
_Avoid_: Setup script, installer.

**Apply**:
Running chezmoi to converge `$HOME` with the source state in this repo. The verb for
"make my machine match the repo."
_Avoid_: Sync, install dotfiles, deploy.

**Source state**:
The version-controlled representation of dotfiles and directories that chezmoi renders
into `$HOME`. Lives in this repo, not in `$HOME`.
_Avoid_: Templates folder, config dir.

**Manifest**:
The `Brewfile` — the declarative list of every Homebrew formula, cask, and Mac App Store
app the machine should have. Treated as the source of truth; cleanup of unlisted packages
is manual, never automatic.
_Avoid_: Package list, dependencies file.

**Provisioning script**:
A chezmoi `run_` hook that performs imperative setup that isn't a file (installing the
Manifest via `brew bundle`, applying macOS defaults, configuring the Dock).
_Avoid_: Hook, post-install script.

**Secret**:
A value that must never appear in the repo in plaintext (SSH keys, signing keys, tokens).
Resolved at Apply time from 1Password via the `op` CLI inside a chezmoi template.
_Avoid_: Credential, password, env var.
