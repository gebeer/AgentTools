# AgentTools

AgentTools is a ProcessWire module that gives AI coding agents CLI access to the
ProcessWire API, site discovery helpers, and the browser/CLI Engineer.

This project uses **RockMigrations** as the migration workflow. For repeatable
site changes, load and follow the installed `processwire-rockmigrations` skill.
Use AgentTools to inspect current state and verify results.

## API variable

The module registers `$at` as a ProcessWire API variable (`wire('at')`).

## CLI commands

Run from the ProcessWire root directory (where `index.php` lives):

| Command | Purpose |
|---------|---------|
| `php index.php --at-eval 'CODE'` | Evaluate a PHP expression with full PW API access |
| `echo 'CODE' \| php index.php --at-stdin` | Evaluate multi-line PHP code from stdin |
| `php index.php --at-sitemap-generate` | Generate a JSON site map to `site/assets/at/site-map.json` |
| `php index.php --at-sitemap-generate-schema` | Generate a schema JSON to `site/assets/at/site-map-schema.json` |
| `php index.php --at-cli` | Open an interactive agent CLI session |
| `php index.php --at-engineer "REQUEST"` | Ask the Engineer a question or request guidance |
| `php index.php --at-engineer-site-info pages\|schema\|modules [--refresh]` | Print generated site info JSON without calling an AI provider |
| `php index.php --at-engineer-api-docs-list` | List available ProcessWire API.md documentation without calling an AI provider |
| `php index.php --at-engineer-api-docs-get NAME` | Print a ProcessWire API.md documentation file without calling an AI provider |
| `php index.php --at-engineer-api-docs-search TERM` | Search ProcessWire API.md documentation without calling an AI provider |
| `php index.php --at-engineer-read-file PATH` | Read a local site file without calling an AI provider |
| `php index.php --at-cron` | Process one pending AgentTools background job; intended for system cron |

## Getting oriented on a new site

If you are working on a site for the first time, run:
```
php index.php --at-sitemap-generate
```
Then read `site/assets/at/site-map.json` to get a complete picture of the site's
templates, fields, page tree, and installed modules before making any changes.

If you need full field/template configuration details (type-specific field settings,
per-template field context overrides, all template settings), also run:
```
php index.php --at-sitemap-generate-schema
```
Then read `site/assets/at/site-map-schema.json`. The file contains a `_readme` key
at the top level with instructions on how to interpret the schema — read it before
using the data. This schema is useful when planning RockMigrations changes that
depend on existing field or template configuration.

## RockMigrations workflow

For repeatable ProcessWire changes:

1. Load the `processwire-rockmigrations` skill.
2. Inspect current state with AgentTools CLI/schema output.
3. Create or update RockMigrations files:
   - `site/RockMigrations/{fields,templates,roles,permissions}/...`
   - `site/modules/Site/Site.migrate.php`
   - PageClass/MagicPage migrations when appropriate
4. Run RockMigrations, usually:
   ```bash
   ddev php site/modules/RockMigrations/migrate.php
   ```
5. Verify with AgentTools CLI or regenerated schema output.
6. Report the migration files changed and verification output.

Prefer RockMigrations for fields, templates, fieldgroups, roles, permissions,
module config, and structural pages. Ask the user before treating content pages
as migration/seed data.

## Background jobs

The admin Engineer, Page Engineer, and Tasks screens can queue long-running
requests as background jobs when system cron is configured. Cron should run
`php index.php --at-cron` from the ProcessWire root directory. Each run processes
one pending job and updates an AgentTools heartbeat file.

Agents may help create or review the cron command, but should not silently install
or modify a user's crontab without explicit permission. If background mode is
unavailable in the admin, check whether `php index.php --at-cron` runs
successfully from the ProcessWire root and report the result.

## Engineer (admin UI and CLI)

The ProcessAgentTools module provides a browser-based Engineer at **Setup > Agent Tools > Engineer**.
It connects to an AI provider (Anthropic, OpenAI, or any OpenAI-compatible endpoint) and gives it
tools for querying the site, reading files, site info, ProcessWire API docs, and persistent memory.
The Engineer supports multi-turn conversation history within a session and optional persistent memory.

When the Engineer migration workflow is set to RockMigrations, it should provide
guidance and current-state inspection, not create AgentTools native migration files.
Use the CLI coding agent plus `processwire-rockmigrations` skill for actual
RockMigrations file edits.

The Engineer is also available from the command line, which allows AI agents to spawn a
ProcessWire-specialist sub-agent without needing to understand ProcessWire themselves:

| Command | Purpose |
|---------|---------|
| `php index.php --at-engineer "REQUEST"` | Ask the Engineer a question or request guidance |
| `php index.php --at-engineer-site-info pages\|schema\|modules [--refresh]` | Print generated site info JSON without calling an AI provider |
| `php index.php --at-engineer-api-docs-list` | List available ProcessWire API.md documentation without calling an AI provider |
| `php index.php --at-engineer-api-docs-get NAME` | Print a ProcessWire API.md documentation file without calling an AI provider |
| `php index.php --at-engineer-api-docs-search TERM` | Search ProcessWire API.md documentation without calling an AI provider |
| `php index.php --at-engineer-read-file PATH` | Read a local site file without calling an AI provider |

Optional flags for `--at-engineer` (placed before the request string):

| Flag | Purpose |
|------|---------|
| `--model=N` | Use agent at index N (0 = primary) as configured in module settings |
| `--readonly` | Allow queries only; the Engineer cannot execute tools that make changes |
| `--verbose` | Write tool call names to stderr as they execute |

The Engineer responds in plain text (stdout). Errors are written to stderr.

**Example — querying site data:**
```
php index.php --at-engineer "How many published pages does this site have?"
```

## Further reading

- `agent_cli.md` — AgentTools CLI usage and RockMigrations integration notes
- `processwire-rockmigrations` skill — canonical migration workflow for this project

---

# DOX framework

- DOX is highly performant AGENTS.md hierarchy installed here
- Agent must follow DOX instructions across any edits

## Core Contract

- AGENTS.md files are binding work contracts for their subtrees
- Work products, source materials, instructions, records, assets, and durable docs must stay understandable from the nearest applicable AGENTS.md plus every parent AGENTS.md above it

## Read Before Editing

1. Read the root AGENTS.md
2. Identify every file or folder you expect to touch
3. Walk from the repository root to each target path
4. Read every AGENTS.md found along each route
5. If a parent AGENTS.md lists a child AGENTS.md whose scope contains the path, read that child and continue from there
6. Use the nearest AGENTS.md as the local contract and parent docs for repo-wide rules
7. If docs conflict, the closer doc controls local work details, but no child doc may weaken DOX

Do not rely on memory. Re-read the applicable DOX chain in the current session before editing.

## Update After Editing

Every meaningful change requires a DOX pass before the task is done.

Update the closest owning AGENTS.md when a change affects:

- purpose, scope, ownership, or responsibilities
- durable structure, contracts, workflows, or operating rules
- required inputs, outputs, permissions, constraints, side effects, or artifacts
- user preferences about behavior, communication, process, organization, or quality
- AGENTS.md creation, deletion, move, rename, or index contents

Update parent docs when parent-level structure, ownership, workflow, or child index changes. Update child docs when parent changes alter local rules. Remove stale or contradictory text immediately. Small edits that do not change behavior or contracts may leave docs unchanged, but the DOX pass still must happen.

## Hierarchy

- Root AGENTS.md is the DOX rail: project-wide instructions, global preferences, durable workflow rules, and the top-level Child DOX Index
- Child AGENTS.md files own domain-specific instructions and their own Child DOX Index
- Each parent explains what its direct children cover and what stays owned by the parent
- The closer a doc is to the work, the more specific and practical it must be

## Child Doc Shape

- Create a child AGENTS.md when a folder becomes a durable boundary with its own purpose, rules, responsibilities, workflow, materials, or quality standards
- Work Guidance must reflect the current standards of the project or user instructions; if there are no specific standards or instructions yet, leave it empty
- Verification must reflect an existing check; if no verification framework exists yet, leave it empty and update it when one exists

Default section order:
- Purpose
- Ownership
- Local Contracts
- Work Guidance
- Verification
- Child DOX Index

## Style

- Keep docs concise, current, and operational
- Document stable contracts, not diary entries
- Put broad rules in parent docs and concrete details in child docs
- Prefer direct bullets with explicit names
- Do not duplicate rules across many files unless each scope needs a local version
- Delete stale notes instead of explaining history
- Trim obvious statements, repeated rules, misplaced detail, and warnings for risks that no longer exist

## Closeout

1. Re-check changed paths against the DOX chain
2. Update nearest owning docs and any affected parents or children
3. Refresh every affected Child DOX Index
4. Remove stale or contradictory text
5. Run existing verification when relevant
6. Report any docs intentionally left unchanged and why

## User Preferences

When the user requests a durable behavior change, record it here or in the relevant child AGENTS.md

## Child DOX Index

- `installable-skills/AGENTS.md` — distributable skill packages AgentTools installs into a ProcessWire project root (incl. the `processwire-agenttools` skill bundle)
- `FieldtypePageEngineer/AGENTS.md` — the Page Engineer custom Fieldtype/Inputfield (per-page conversation field powering the admin Page Engineer)
- `tasks/AGENTS.md` — predefined Engineer review/automation task definitions surfaced in the admin Tasks screen and CLI
