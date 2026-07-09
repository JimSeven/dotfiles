# Secrets, SSH, and Git signing via 1Password

All secrets are sourced from 1Password at Apply time; none are stored in the repo, even
encrypted. The 1Password SSH agent provides SSH authentication, Git commit signing uses an
SSH key held in 1Password, and chezmoi templates pull any remaining tokens via the `op` CLI.

We already use 1Password + its CLI, so this avoids introducing a second secrets mechanism
(age/GPG-encrypted files) and keeps a single vault as the source of truth. The alternative —
encrypted files committed to the repo — was rejected as more moving parts for a personal
setup.

Consequences:

- `op` (1Password CLI) becomes a hard dependency of Apply. Templates that reference secrets
  fail to render until the user is signed in to 1Password.
- Because a fresh Mac has no 1Password session yet, **Bootstrap is two-phase**: phase 1
  installs everything including 1Password and pauses; the user signs in; phase 2 applies the
  secret-bearing templates.
- `dot_gitconfig.tmpl` carries the signing configuration; SSH config points at the 1Password
  agent socket.
