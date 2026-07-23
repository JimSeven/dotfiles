# Laravel Herd owns PHP and Node versioning (no mise)

We do not use a dedicated version manager (mise/asdf/nvm-standalone). Laravel Herd
— already installed and in daily use — bundles PHP (7.4–8.5) and Node (via its own
NVM), so a second manager would only compete for PATH and confuse per-project
resolution.

mise was chosen during the grilling session, but diffing against the live machine
showed Herd already fills that role, so we reversed the decision.

Consequences:

- PHP comes from Herd. Node has two layers: a **brew `node`** as the machine-wide
  default (declared in the Brewfile — it was already pulled in transitively by
  `opencode`, now explicit so global tooling has a stable npm), and **Herd's NVM**
  for per-project Node versions. `corepack enable` (yarn/pnpm shims) runs against
  the brew Node via `run_onchange_after_50-corepack.sh`. The Brewfile installs the
  `herd` cask; the shell integration lives in `home/dot_config/zsh/50-herd.zsh`.
- Trade-off: version setup is tied to Herd rather than a portable, declarative
  manager. Acceptable for a single-Mac, Laravel-centric setup; revisit if the
  machine ever needs non-Herd PHP/Node.
