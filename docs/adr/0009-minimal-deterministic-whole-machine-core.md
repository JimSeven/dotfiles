# Minimal, deterministic core — whole machine in scope

We version **only what is deterministic and text-based**, and we scope the repo to
the **whole machine**, not just `$HOME`. This generalises the minimal-core
principle that [ADR-0006](./0006-agent-config-managed-vs-runtime.md) established for
agent config — "a minimal core that never rots beats a comprehensive one that needs
constant tending" — to the entire setup, and names a boundary that was already
lived but never written down.

The architecture already behaves this way: services run per-project in OrbStack
rather than as global brew daemons ([ADR-0005](./0005-dev-services-per-project-in-orbstack.md)),
`~/.ssh/config` is deliberately unmanaged ([ADR-0002](./0002-secrets-via-1password.md)),
agent dotfolders are never `exact_` ([ADR-0006](./0006-agent-config-managed-vs-runtime.md)),
and Provisioning scripts already reach outside `$HOME` (`sudo nvram`, `defaults
write`, `dockutil`). Naming the principle lets every future addition be judged
against one rule rather than case-by-case taste.

**Rule of thumb for any candidate:** version it only if it is *text*,
*deterministic*, and *survives OS/runtime churn*. Otherwise document it as a manual
step — the documentation is the source of truth, not a rotting mechanism.

Consequences — what this admits and what it deliberately excludes:

- **In scope** (deterministic, text, whole-machine):
  - **Touch ID for `sudo`** via `/etc/pam.d/sudo_local` — a single line Apple
    preserves across OS updates. Added as a `run_once` Provisioning script.
  - **Global Composer CLIs** I always reinstall (`laravel/forge-cli`,
    `laravel/installer`, `statamic/cli`, `spatie/global-ray`) — stable and
    idempotent via `composer global require`, added as a `run_onchange`
    Provisioning script keyed on the package list.
- **Deliberately out of scope** (considered and rejected, so a future reader need
  not re-litigate):
  - **App preference plists** (`~/Library/Preferences/*.plist`) — binary,
    GUI-mutated, drift-prone. Text configs an app *does* expose (VS Code
    `settings.json`, Ghostty, Starship, Finicky) are managed; the opaque state is
    not.
  - **Login items / launchd autostart** — GUI-mutated; scripting via
    `sfltool`/`osascript` is flaky. Set by hand.
  - **Firewall / FileVault** — interactive or low-determinism (`socketfilterfw` is
    partly deprecated; FileVault needs recovery-key handling). The GUI is the
    honest interface.
  - **npm global packages** — structurally non-deterministic here: they live under
    Herd's NVM and are tied to a single Node version Herd switches
    ([ADR-0003](./0003-herd-owns-php-and-node.md)), so a provisioning script would
    version state that breaks underneath us. Listed as a manual step instead.
  - **Multi-machine profiles** — deferred, not on spec
    ([ADR-0001](./0001-chezmoi-as-dotfile-manager.md)); the `work` flag already
    covers the one real divergence.
- **Shell secrets stay runtime.** API tokens are never exported globally (a leak
  surface across every child process, not a reproducibility gain) and never
  versioned. The sanctioned pattern is on-demand: `op run --` or project-local
  `direnv` + `.envrc`. Extends [ADR-0002](./0002-secrets-via-1password.md).
- **Agent tooling keeps its version-management decision** ([ADR-0006](./0006-agent-config-managed-vs-runtime.md)):
  skills and MCP wiring are still not versioned. The only addition is an
  **inventory / provenance reference** in the docs — categories and how each is
  re-established — because the real gap was *knowing what is installed*, not
  reproducing it. Self-authored skills belong in their own repo (their backup gap
  is tracked separately).
