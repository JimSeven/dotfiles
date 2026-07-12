# Post-apply verification runs on-machine (run_after), not in CI

`chezmoi apply` guarantees invariants it never checks — the three agent Bridges resolving to
the canonical Defaults (ADR-0007), and Herd's shell-integration path existing (ADR-0003) — so
a broken Bridge or a moved integration path fails silently until next use. A `run_after`
Provisioning script (`home/run_after_90-verify.sh`) asserts these at the end of every Apply
and exits non-zero (loud) on failure; it runs after files are written, so a hard exit signals
without rolling anything back.

Consequences:

- **No CI adapter.** The checks assert real symlinks and files in `$HOME`; a headless CI
  runner only does `chezmoi apply --dry-run` (which skips `run_` scripts) and has no real home
  to inspect. A CI check would be a hypothetical seam with no coverage, so it is left out —
  shellcheck still lints the script.
- **Scope is deliberately minimal.** Only invariants that otherwise fail *silently* are
  checked (the Bridges; the Herd path). Failures that surface on their own — an unsigned
  commit, a visibly incomplete Dock — are excluded; a check there would be interface without
  leverage.
- The Herd check is conditional on `/Applications/Herd.app` being present, so it never
  false-positives on a non-Herd machine.
