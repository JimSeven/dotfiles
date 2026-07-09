# Laravel Herd owns PHP and Node versioning (no mise)

We do not use a dedicated version manager (mise/asdf/nvm-standalone). Laravel Herd
— already installed and in daily use — bundles PHP (7.4–8.5) and Node (via its own
NVM), so a second manager would only compete for PATH and confuse per-project
resolution.

mise was chosen during the grilling session, but diffing against the live machine
showed Herd already fills that role, so we reversed the decision.

Consequences:

- Node/npm come from Herd's NVM; PHP from Herd. The Brewfile installs the `herd`
  cask; the shell integration lives in `home/dot_config/zsh/50-herd.zsh`.
- Global npm tools are installed under Herd's node (see `home/npm-globals.txt`).
- Trade-off: version setup is tied to Herd rather than a portable, declarative
  manager. Acceptable for a single-Mac, Laravel-centric setup; revisit if the
  machine ever needs non-Herd PHP/Node.
