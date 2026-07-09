# Local dev services run per-project in OrbStack, not as global Homebrew daemons

Databases and search/cache services (PostgreSQL, Redis, MeiliSearch, …) are **not**
declared in the Brewfile. They run per project as containers in OrbStack
(`docker compose`), not as machine-wide `brew services` daemons.

The live machine had grown a global `postgresql@14`, `redis`, and `meilisearch`.
Diffing the Brewfile against it during a grilling session surfaced these as
accidental, machine-wide state: one pinned version shared by every project, always
running in the background, and invisible in the declarative manifest.

Consequences:

- The Brewfile stays free of long-running service daemons. Each project pins its own
  service versions in its own `docker-compose.yml`, matching production more closely.
- OrbStack (already the container runtime, replacing Docker Desktop) is the single
  place services live; nothing to `brew services start` on login.
- `mysql-client` stays in the Brewfile — it is a CLI, not a daemon, useful for
  connecting to containerised or remote databases.
- Trade-off: starting a project now means `docker compose up` rather than an
  always-on local Postgres. Acceptable, and the isolation is worth it. Revisit only
  if a service is genuinely needed system-wide outside any project.
