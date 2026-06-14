# ProcessWire migrations with AgentTools

This project uses **RockMigrations** for repeatable ProcessWire changes.
Load and follow the installed `processwire-rockmigrations` skill.

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
