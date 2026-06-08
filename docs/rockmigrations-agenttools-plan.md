# Plan: Use AgentTools with RockMigrations

Branch: `feature/rockmigrations-agent-instructions`

## Implemented scope

Steps 1 and 2 are implemented on this branch:

1. Agent-facing docs and shipped skill now delegate repeatable migration work to
   `processwire-rockmigrations`.
2. `AgentToolsEngineer.php` now has an **Engineer migration workflow** config
   toggle:
   - `rockmigrations` (default) — Engineer can inspect and advise, but does not
     expose `save_migration` and `--at-engineer-migrate` returns a clear error.
   - `agenttools` — preserves native AgentTools migration behavior.

## Desired contract

- AgentTools = live ProcessWire access layer:
  - `eval`, `stdin`, `cli`
  - sitemap/schema generation
  - Engineer for read/inspection and guided assistance
- RockMigrations = repeatable site changes:
  - fields, templates, roles, permissions
  - module config
  - seed/structural pages when appropriate
  - PageClass/MagicPage lifecycle migrations
- Agents must not create AgentTools native migration files for normal site changes.
- AgentTools native migrations remain available for compatibility.

## Practical workflow

1. Agent starts in ProcessWire root.
2. Agent reads `AGENTS.md`.
3. For discovery, agent uses AgentTools:
   - `pw-at.sh sitemap-generate`
   - `pw-at.sh sitemap-generate-schema`
   - `pw-at.sh eval` / `stdin`
4. For repeatable changes, agent loads `processwire-rockmigrations` skill.
5. Agent edits RockMigrations files:
   - `site/RockMigrations/{fields,templates,roles,permissions}/...`
   - `site/modules/Site/Site.migrate.php`
   - MagicPage/PageClass migrations where appropriate
6. Agent runs RockMigrations:
   - `ddev php site/modules/RockMigrations/migrate.php`
7. Agent verifies with AgentTools CLI/schema output.

## Remaining optional follow-up

Add a dedicated Engineer tool such as `save_rockmigration_file` if the admin
Engineer itself should create RockMigrations files. Keep it path-restricted to
safe locations instead of reusing `save_migration`.
