# Homebrew stays manually upgraded, with a staleness nudge

The Manifest is installed by `brew bundle`, but keeping it **current** is a separate
concern: brew upgrades run **manually** via `brewup` (`brew update && brew upgrade &&
brew cleanup`), never on a background schedule. To stop "manual" from meaning
"forgotten", `brewup` records the time of each successful run and the shell prints a
one-line nudge at startup once that timestamp is older than `BREW_STALE_DAYS`
(default 14). This lives in the `45-brew` Shell module ([ADR-0004](./0004-modular-zsh-with-local-escape-hatch.md)).

A background auto-upgrade was considered and rejected. It contradicts the
minimal-deterministic principle ([ADR-0009](./0009-minimal-deterministic-whole-machine-core.md)):
an unattended `brew upgrade` picks its own moment to pull a breaking minor (PHP,
node, openssl) or restart a GUI cask, exactly the non-determinism the setup avoids
elsewhere. The `homebrew/autoupdate` launchd tap and a hand-rolled cron/launchd job
were the obvious mechanisms — both take the trigger away from the human, which is
the one thing worth keeping. A reminder keeps the *when* mine while removing the
*remembering*.

Design points worth not re-deriving:

- **Reminder, not scheduler.** The nudge only reads a timestamp file; it never
  shells out to `brew` (which is slow and hits the network), so it adds nothing
  measurable to shell startup.
- **`brewup` is a function, not an alias.** It has to write the stamp after a
  successful run. A leftover alias of the same name would shadow the function at
  parse time and the stamp would silently never update — so the alias was removed
  from `30-aliases.zsh`.
- **Stamp is state, not cache.** It lives under `${XDG_STATE_HOME:-~/.local/state}`.
  A missing stamp (fresh machine, or cleared state) surfaces the nudge rather than
  being read as "just upgraded" — the safe default is to remind.
- **Self-updating casks stay theirs.** `brew upgrade` skips casks with
  `auto_updates true` by design (Herd et al. update themselves); `--greedy` is a
  deliberate manual choice, never baked into `brewup`.

Consequences:

- Packages are never silently upgraded; every upgrade is a moment you chose.
- Until the first `brewup` on a machine the nudge reads "Upgrade-Alter unbekannt" —
  intended, and it clears on that first run.
- The threshold is tunable via `BREW_STALE_DAYS`, but only if exported before the
  module is sourced (e.g. in `10-env.zsh`); `~/.zshrc.local` loads too late to
  affect the startup nudge.
- The stamp is machine-local by construction, so it is not versioned and each
  machine tracks its own upgrade cadence.
