# Migration-related agent instructions

This branch redirects agent-facing migration guidance from AgentTools native
migrations to RockMigrations.

## Canonical rule

Use AgentTools for ProcessWire access, discovery, and verification. Use the
installed `processwire-rockmigrations` skill for repeatable site changes.

Do not create native AgentTools migrations under `site/assets/at/migrations/`
unless the user explicitly asks for native AgentTools migrations.

## Updated files

| File | Migration-related role after update |
|------|-------------------------------------|
| `AGENTS.md` | Main agent contract. Points migrations to `processwire-rockmigrations`; marks `--at-migrations-*` and `--at-engineer-migrate` as native/compatibility only. |
| `agent_cli.md` | CLI usage. AgentTools for inspection/verification; RockMigrations for repeatable changes; native migration commands compatibility only. |
| `README.md` | Project-level docs. Explains AgentTools + RockMigrations division of responsibility and Engineer workflow toggle. |
| `agents/skills/processwire-agenttools/SKILL.md` | Shipped AgentTools skill. Describes AgentTools as CLI/discovery companion; delegates migration work to RockMigrations. |
| `agents/skills/processwire-agenttools/migrations.md` | Replaced native migration tutorial with RockMigrations redirect and compatibility note. |
| `AgentToolsEngineer.php` | Adds `engineer_migration_workflow` config. In RockMigrations mode, prompt tells Engineer not to create native migrations and `save_migration` tool is hidden. |
| `ProcessAgentTools.module.php` | Native migration admin UI remains available for compatibility. |
| `ProcessAgentTools.js` | Native migration admin button/confirmation behavior remains unchanged. Edit only if UI selectors/buttons change. |
| `agents/skills/processwire-agenttools/scripts/pw-at.sh` | Wrapper still supports native migration commands for compatibility. |

## RockMigrations target paths

- `site/RockMigrations/{fields,templates,roles,permissions}/...`
- `site/modules/Site/Site.migrate.php`
- PageClass/MagicPage files when appropriate

## Verification search

After editing instructions, check for accidental native-default language:

```bash
grep -Rni "migration-first\|save_migration\|site/assets/at/migrations\|--at-engineer-migrate" \
  AGENTS.md agent_cli.md README.md agents/skills/processwire-agenttools AgentToolsEngineer.php
```

Expected: hits are compatibility notes, RockMigrations-mode code, or explicit native AgentTools references.
