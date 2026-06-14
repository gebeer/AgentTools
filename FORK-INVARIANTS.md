# Fork invariants — RockMigrations overlay

**Fork-only file.** Lives on `feature/rockmigrations-agent-instructions`, never on `main`.
This is the rubric for the post-upstream-sync audit: what this fork *guarantees* and
what must *never leak back in* when upstream wording or code changes underneath us.

The overlay's whole purpose: **AgentTools defers repeatable site changes to
RockMigrations (the `processwire-rockmigrations` skill) instead of its own native
migration system.** Native migrations remain available but only behind an opt-in toggle.

---

## How to use this doc

- **Deterministic guardrails** (the `grep`/`php -l` blocks below) are cheap tripwires —
  run them every sync; a failure is a hard regression.
- **Prose invariants** need an agent: read upstream's `OLD..NEW` diff over the doc files,
  then check our post-rebase prose against the "must hold" / "must never appear" rules.
- This file is **report-only** input. The audit proposes fixes; a human approves them.

---

## 1. Code invariants (deterministically checkable)

Exact symbols (cite these, don't paraphrase):

- Constants in `AgentToolsEngineer.php`:
  `migrationWorkflowRockMigrations = 'rockmigrations'`, `migrationWorkflowAgentTools = 'agenttools'`.
- Helpers: `getMigrationWorkflow()` (returns `rockmigrations` by default),
  `usesNativeMigrations()` (true **only** when the toggle is `agenttools`).
- Property `engineer_migration_workflow` registered in `AgentTools.module.php`
  (`@property` **and** the `$keys` array) and surfaced as a select in
  `AgentToolsEngineerConfig.php` (both options, default = RockMigrations).

Must hold:

1. **Default is RockMigrations.** With no/empty setting, `getMigrationWorkflow()` returns
   `rockmigrations` and `usesNativeMigrations()` is `false`.
2. **`save_migration` is withheld in RM mode** — its inclusion in *both* the Anthropic
   and OpenAI tool arrays is gated by `... && $this->usesNativeMigrations()`. The tool
   must never be offered when the workflow is `rockmigrations`.
3. **Native migrate CLI is neutralised in RM mode** — guarded by
   `if($migrate && !$this->usesNativeMigrations())`, which writes
   `ERROR: Native AgentTools migrations are disabled for this Engineer…` to STDERR and
   returns `false` before any native migration runs.
4. **System prompt branches on workflow.** RM branch tells the agent to inspect via
   `eval_php` / `site_info` / `read_file` / `api_docs` and delegate repeatable changes to
   the `processwire-rockmigrations` skill, and that it must **not** write RM/migration
   files itself in this mode. The `eval_php` tool description carries the
   inspection/verification-only note.
5. **`agenttools` mode preserves upstream's native behaviour verbatim** — the native
   branch (the `else`/`usesNativeMigrations()` path) is upstream's original text/logic,
   unchanged. The toggle is fully reversible.

Deterministic tripwire (all must pass):

```bash
php -l AgentToolsEngineer.php AgentTools.module.php AgentToolsEngineerConfig.php ProcessAgentTools.module.php
grep -q "migrationWorkflowRockMigrations = 'rockmigrations'" AgentToolsEngineer.php
grep -q "function usesNativeMigrations" AgentToolsEngineer.php
grep -q '@property string $engineer_migration_workflow' AgentTools.module.php
# save_migration must be guarded by usesNativeMigrations() in BOTH tool arrays:
test "$(grep -cE 'usesNativeMigrations\(\)\) \{' AgentToolsEngineer.php)" -ge 2
# native migrate CLI must be neutralised in RM mode (invariant 1.3):
grep -qF 'migrate && !$this->usesNativeMigrations()' AgentToolsEngineer.php
```

---

## 2. Prose invariants (agent-audited)

**Must hold** across `README.md`, `AGENTS.md`, `agent_cli.md`,
`installable-skills/processwire-agenttools/{SKILL.md,migrations.md}`,
`docs/migration-related.md`:

- **All** migration / repeatable-change guidance (fields, templates, content structure)
  routes **exclusively** to the **`processwire-rockmigrations` skill**. RockMigrations is
  presented as the only migration path.
- The agent's role in RM mode is stated: inspect/verify via `eval_php` & friends, delegate
  writes to RM; it does **not** author migration files itself in RM mode.

**Must NEVER appear** (hard scrub — these are the leak-back / drift signatures):

- **Any instructional coverage of native migration tooling** — no how-tos, examples,
  command lines, parameter docs, or "when to use" guidance for `save_migration`,
  `--at-engineer-migrate`, or native AgentTools migration files. The *only* permitted
  native reference is a single non-instructional sentence noting that an opt-in native
  mode exists in module config. Demoted-but-still-documented framings (e.g. "available
  for compatibility, do not use unless asked" shown alongside the actual command) are
  **violations**, not exceptions.
- Prose that contradicts the code: e.g. text praising/instructing a tool the overlay
  withholds, or describing native migrations as the default.
- Upstream-introduced passages (merged clean, no conflict) that reintroduce native
  migration guidance. **This is the silent-drift case — the audit's main job.**

> **Known pre-existing debt:** under the hard-scrub rule, `agent_cli.md` (it still shows
> `--at-engineer-migrate`) and any native how-to in `migrations.md` / `SKILL.md` currently
> *violate* these rules. The diff-driven audit only catches *new* upstream drift, so this
> backlog needs a one-time scrub pass separately.

---

## 3. Drift tripwires — upstream changes that force a re-check

When `git diff OLD..NEW upstream/main` touches any of these, re-audit the named surface:

| Upstream change | Re-check |
|---|---|
| Adds/renames/removes any agent **tool** (esp. migration-related) | tool arrays in `AgentToolsEngineer.php` + every doc that names tools + the RM skill |
| Changes **`eval_php`** behaviour or guards | RM-mode prompt + `eval_php` description (our overlay leans on it as the inspection tool) |
| Changes the **CLI action dispatch** around `--at-engineer-migrate` | RM-mode neutralisation guard (invariant 1.3) |
| Bumps module **version** / adds new `@property` or `$keys` entries | that our `engineer_migration_workflow` registration still merges and isn't shadowed |
| Adds/edits **migration documentation** or a new migration feature | reconcile with the RM overlay — the highest silent-drift risk |
| Edits the **system prompt** for the Engineer | that our workflow branch still wraps the right text and the native branch stays verbatim |

---

## 4. New, fork-only files (no upstream counterpart — conflict-free, but keep current)

- `docs/migration-related.md`, `docs/rockmigrations-agenttools-plan.md` — overlay intent/refs.
- `.agents/skills/processwire-rockmigrations` — committed symlink (machine-specific abs path).
- `.editorconfig` — preserves markdown trailing whitespace (kills the README rebase churn).
- `FORK-INVARIANTS.md` — this file.
