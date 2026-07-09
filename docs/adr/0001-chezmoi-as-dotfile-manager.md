# Use chezmoi as the dotfile manager

We manage dotfiles, machine provisioning, and secrets wiring with [chezmoi] rather than
the previous Make-based symlink approach.

The repo was a `Makefile` that symlinked files from `files/` into `$HOME` and imperatively
called `brew install`. This worked but offered no templating, no secrets story, and no
clean path to multiple machines. We evaluated modernizing Make, GNU Stow + Brewfile, and
nix-darwin + home-manager. chezmoi won: it is a purpose-built, widely-adopted dotfile
manager with first-class templating, a documented 1Password integration for secrets, and
idempotent `apply` — without the steep learning curve and full-rewrite cost of Nix.

Consequences:

- Source files follow chezmoi's naming (`dot_zshrc`, `*.tmpl`); the old `files/` layout and
  the `make link` symlink logic go away.
- Package install and macOS defaults become chezmoi `run_` provisioning scripts.
- Bootstrap becomes `chezmoi init --apply <repo>` behind a small prerequisites script.
- The setup targets a single Mac today but is structured so multiple machines/profiles can
  be added later via chezmoi templating without restructuring.

[chezmoi]: https://www.chezmoi.io
