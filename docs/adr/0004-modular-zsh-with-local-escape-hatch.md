# Modular zsh config with a machine-local escape hatch

`~/.zshrc` is a thin entry point that sources numbered modules from `~/.config/zsh`
(`00-path`, `10-env`, `20-tools`, `30-aliases`, `40-functions`, `50-herd`,
`60-projects`) and finally `~/.zshrc.local`.

The old `~/.zshrc` had grown to ~190 lines of oh-my-zsh boilerplate, dead tool hooks
(Fig, Kiro) and duplicated exports. Splitting by concern keeps each file small and
makes load order explicit through the numeric prefix.

Tools such as Laravel Herd auto-inject lines into `~/.zshrc`. Because chezmoi owns
that file, such injections are transient: chezmoi restores the thin version on the
next apply, and the real integration lives in a managed module (`50-herd.zsh`).
That restore is done by a `modify_dot_zshrc` script that strips the injections
*silently* on every apply (ADR-0012), rather than a plain file that prompted each
time Herd re-injected. Genuinely machine-specific config that should not be
version-controlled goes in `~/.zshrc.local`, which chezmoi does not manage.

Consequences:

- Adding a shell concern means adding/editing one small module, not growing a
  monolith.
- `~/.zshrc.local` is the sanctioned place for secrets-free, machine-only tweaks and
  for absorbing tool auto-injections without fighting chezmoi.
