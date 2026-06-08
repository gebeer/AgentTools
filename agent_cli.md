# AgentTools for ProcessWire

Tools for using AI coding agents to interact directly with a ProcessWire
installation through the ProcessWire API.

This project uses **RockMigrations** for repeatable migrations. Use AgentTools for
inspection, one-off queries, verification, and Engineer guidance. Use the
`processwire-rockmigrations` skill for site changes that need to transfer across
environments.

---

## Getting started

**Step 1:** Install the AgentTools module in your ProcessWire installation.

**Step 2:** Make sure `php` is in your PATH. To verify:
~~~~~
php -v
~~~~~

**Step 3:** Start an AI coding agent session in your ProcessWire root directory and say:
> *"Please read the `site/modules/AgentTools/AGENTS.md` file before we begin."*

**Step 4:** For repeatable site changes, ask the agent to load the
`processwire-rockmigrations` skill.

---

## CLI commands

All commands are run from the ProcessWire root directory (where `index.php` lives).

| Command | Purpose |
|---------|---------|
| `php index.php --at-cli` | Opens the agent CLI for interactive API access |
| `php index.php --at-eval 'CODE'` | Evaluate a PHP expression inline |
| `echo 'CODE' \| php index.php --at-stdin` | Evaluate multi-line PHP code from stdin |
| `php index.php --at-sitemap-generate` | Generate a JSON site map to `site/assets/at/site-map.json` |
| `php index.php --at-sitemap-generate-schema` | Generate a schema JSON to `site/assets/at/site-map-schema.json` |
| `php index.php --at-engineer "REQUEST"` | Ask the Engineer a question or request guidance |
| `php index.php --at-engineer-site-info pages\|schema\|modules [--refresh]` | Print generated site info JSON without calling an AI provider |
| `php index.php --at-engineer-api-docs-list` | List available ProcessWire API.md documentation without calling an AI provider |
| `php index.php --at-engineer-api-docs-get NAME` | Print a ProcessWire API.md documentation file without calling an AI provider |
| `php index.php --at-engineer-api-docs-search TERM` | Search ProcessWire API.md documentation without calling an AI provider |
| `php index.php --at-engineer-read-file PATH` | Read a local site file without calling an AI provider |
| `php index.php --at-cron` | Process one pending AgentTools background job; intended for system cron |

Native AgentTools migration commands (`--at-migrations-*` and
`--at-engineer-migrate`) remain available for compatibility, but they are not the
default migration workflow for this project.

### When to use `--at-eval` vs `--at-stdin`

`--at-eval` is convenient for simple expressions but is subject to shell escaping
rules — single quotes, double quotes, dollar signs, and backticks in the PHP code
can conflict with the shell. For anything beyond a simple one-liner, prefer
`--at-stdin` with a single-quoted heredoc, which passes PHP code verbatim:

~~~~~
cat <<'PHP' | php index.php --at-stdin
$items = $pages->find("template=blog-post, sort=-modified, limit=10");
foreach($items as $item) {
    $date = date('Y-m-d', $item->modified);
    echo "{$date} | {$item->title} | {$item->url}\n";
}
PHP
~~~~~

The single-quoted delimiter (`<<'PHP'`) prevents the shell from interpreting
`$variables`, so PHP variables pass through untouched.

`--at-stdin` also accepts normal PHP file contents with an opening `<?php` tag,
so generated PHP files can be piped directly.

---

## Site map and schema

Running `--at-sitemap-generate` writes a JSON file to `site/assets/at/site-map.json`
covering templates, fields, pages, and modules. Run this at the start of a session
on an unfamiliar site.

Run `--at-sitemap-generate-schema` when you need full field/template configuration
details, per-template field context overrides, or detailed template settings. This
is useful before creating RockMigrations changes that depend on existing config.

---

## Engineer helper commands

The Engineer can be called from the CLI when AgentTools has an AI provider
configured:

~~~~~
php index.php --at-engineer "How many published pages does this site have?"
~~~~~

In RockMigrations mode, use `--at-engineer` for questions, state inspection, and
guidance. Do not use `--at-engineer-migrate` unless the user explicitly asks for
native AgentTools migrations and the Engineer is configured for that workflow.

Several read-only helper commands are available without calling an AI provider:

| Command | Purpose |
|---------|---------|
| `php index.php --at-engineer-site-info pages [--refresh]` | Print `site/assets/at/site-map.json`; with `--refresh`, regenerate first |
| `php index.php --at-engineer-site-info schema [--refresh]` | Print `site/assets/at/site-map-schema.json`; with `--refresh`, regenerate first |
| `php index.php --at-engineer-site-info modules` | Print installed module class names as JSON |
| `php index.php --at-engineer-api-docs-list` | Print available API docs as JSON with `name`, `description`, and `file` |
| `php index.php --at-engineer-api-docs-get NAME` | Print the contents of an API.md file by name |
| `php index.php --at-engineer-api-docs-search TERM` | Search API docs and print JSON matches with `name`, `file`, `line`, and `snippet` |
| `php index.php --at-engineer-read-file PATH` | Print a file inside the ProcessWire root; paths outside the root are denied |

Use these local helper commands when an external coding agent needs structured
site context, ProcessWire API documentation, or a small local file without
spending provider tokens.

`--at-cron` is for queued background jobs from the admin Engineer, Page Engineer,
and Tasks screens. It should be run by system cron from the ProcessWire root. Do
not install or modify cron for the user unless they explicitly ask you to.

---

## agent_cli.php

### Purpose

Gives the agent direct access to the ProcessWire API so it can perform reads,
one-off checks, tests, and verification tasks.

### How it works

The agent may modify anything in `agent_cli.php` **after** the marker line:
~~~~~
/* ~~~ AGENT ~~~ */
~~~~~
After that marker, ProcessWire is fully booted and all API variables are
available. They are documented with PHPDoc at the top of the file.

When `--at-cli` starts, the first line of output indicates which file is active:
~~~~~
// agent_cli.php: /path/to/site/modules/AgentTools/agent_cli.php
~~~~~
Always edit the file indicated in that output. On servers where the modules
directory is not writable, the active file will be in `site/assets/at/` instead.

### Notes

- If something doesn't appear to be working correctly, report the error and ask
  before attempting to fix it.
- For quick one-off operations, prefer `--at-eval` or `--at-stdin` over editing
  `agent_cli.php`.
- Do not use `agent_cli.php` to make repeatable schema/config changes directly;
  write RockMigrations files instead.

---

## RockMigrations integration

For repeatable ProcessWire changes:

1. Inspect current state with AgentTools (`--at-eval`, `--at-stdin`, sitemap/schema).
2. Load and follow the `processwire-rockmigrations` skill.
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

Use RockMigrations for fields, templates, roles, permissions, module config, and
repeatable structural pages. Ask the user before treating content pages as seed
data.

---

## Native AgentTools migrations compatibility

AgentTools includes a native migration system that writes files to
`site/assets/at/migrations/` and applies them through `--at-migrations-*` commands
or **Setup > Agent Tools**.

This native system is kept for compatibility with AgentTools-native projects. It
is not the default migration workflow for this project. Use it only when the user
explicitly requests native AgentTools migrations.
