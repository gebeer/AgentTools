# ProcessWire migrations with AgentTools

This project uses **RockMigrations** for repeatable ProcessWire changes.
AgentTools' native migration system remains available for compatibility, but is
not the default workflow for normal site changes. Load and follow the installed
`processwire-rockmigrations` skill instead.

## Default workflow

1. Use AgentTools CLI/schema output to inspect current state.
2. Load the `processwire-rockmigrations` skill.
3. Create or update RockMigrations files:
   - `site/RockMigrations/{fields,templates,roles,permissions}/...`
   - `site/modules/Site/Site.migrate.php`
   - PageClass/MagicPage migrations when appropriate
4. Run RockMigrations, usually:
   ```bash
   ddev php site/modules/RockMigrations/migrate.php
   ```
5. Verify with AgentTools CLI/schema output.
6. Report changed files and verification output.

## What belongs in RockMigrations

- Fields, templates, fieldgroups, roles, permissions
- Module installation/configuration when repeatable
- Structural or seed pages when the user confirms they should transfer across environments
- PageClass/MagicPage migrations and lifecycle hooks

## AgentTools native migrations

AgentTools also includes a native migration engine with `migrations-apply`,
`migrations-list`, `migrations-test`, and `engineer-migrate` commands. Those are
kept for compatibility with AgentTools-native projects.

Use native AgentTools migrations only when the user explicitly requests that
workflow. Do not mix native AgentTools migrations with RockMigrations for the same
site change.
