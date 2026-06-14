---
name: sync-rm-fork
description: Use when reapplying the AgentTools RockMigrations fork's carried patches onto new upstream commits — the recurring upstream-sync / rebase cycle on feature/rockmigrations-agent-instructions. Triggers when `git fetch upstream` shows new commits, or the user asks to sync the fork, reapply patches, or check for drift after upstream changes.
---

# Sync RM fork

## Overview

This repo is a **rebasing tracking fork**: `main` mirrors `upstream/main`; the patch
branch `feature/rockmigrations-agent-instructions` carries a small set of commits that
make AgentTools defer migrations to **RockMigrations**. Each upstream release, the patches
are rebased forward. Much of the patch is **prose** — so the real risk on sync is not the
git conflict (visible) but **silent semantic drift**: upstream wording/code that merges
clean yet contradicts the overlay.

This skill drives the sync: deterministic git + guardrails, then a **diff-driven semantic
audit** (subagents) against the audit rubric in `references/FORK-INVARIANTS.md`. The audit
is **report-only** — propose fixes, get human approval, then apply.

> **Rubric location.** The rubric lives in this skill at `references/FORK-INVARIANTS.md`.
> Subagents are dispatched from the repo root and have no skill-directory context, so cite
> the full repo-root path to them: `.claude/skills/sync-rm-fork/references/FORK-INVARIANTS.md`.

## ⛔ Hard rule

**NEVER open a PR from the patch branch to `upstream`.** This is a permanent, deliberate
divergence, not a contribution. Ignore GitHub's "create a pull request" link after pushing.

## Phase 0 — Detect scope

```bash
.claude/skills/sync-rm-fork/scripts/detect-scope.sh
```

Read-only (only updates remote-tracking refs). It captures `OLD` **before** fetching —
structurally, so the "fetch before capture" footgun can't happen — computes `NEW`, and
prints `UPSTREAM_CHANGED: yes|no`, the `OLD..NEW` commits, the **changed overlay files**
(your Phase 3 audit scope), and heuristic §3 drift hints.

- `UPSTREAM_CHANGED: no` → routine sync has nothing to do; stop (or use full-state mode).
- `UPSTREAM_CHANGED: yes` → **record the printed `OLD` and `NEW` shas** — Phase 1 rebases
  onto `NEW`; Phase 3 diffs each file over `OLD..NEW`.

## Phase 1 — Sync main + backup + rebase

```bash
git checkout main && git merge --ff-only "$NEW" && git push origin main
git branch "backup/feature/rockmigrations-agent-instructions-before-sync-$(git log -1 --format=%cd --date=format:%Y%m%d-%H%M%S $NEW)" feature/rockmigrations-agent-instructions
git checkout feature/rockmigrations-agent-instructions
git rebase upstream/main          # rerere replays known resolutions; resolve any new conflicts
```

README conflicts should now be rare (whitespace churn was eliminated; see
`readme-whitespace-conflict-fixed` memory). If one appears, it's a **real content**
overlap — resolve on the merits, and never re-strip markdown trailing whitespace
(`.editorconfig` guards this; don't fight it).

## Phase 2 — Deterministic guardrails

```bash
.claude/skills/sync-rm-fork/scripts/guardrails.sh
```

The executable single source of truth for `references/FORK-INVARIANTS.md` §1 (php -l + the
invariant greps). **Non-zero exit = a hard regression in the rebase — fix before proceeding.**

## Phase 3 — Diff-driven semantic audit (subagents, report-only)

Your audit scope is the **changed overlay files** already listed in Phase 0's
`detect-scope.sh` report (it also flagged likely `references/FORK-INVARIANTS.md` §3 hits).
Still skim §3 yourself — an upstream change to tools, `eval_php`, the CLI dispatch, module
version/`$keys`, or migration docs forces a re-audit of the mapped surface even if our file
didn't conflict, and the §3 hints are heuristic, not exhaustive.

Per-file diff for each subagent: `git diff <OLD>..<NEW> -- <FILE>` (use the shas from Phase 0).

**Dispatch one subagent per affected file, in parallel.** Each gets this prompt:

> You are auditing one file of a downstream fork after an upstream sync. The fork's rules
> are in `.claude/skills/sync-rm-fork/references/FORK-INVARIANTS.md` (read it). Inputs: (a) upstream's change to `<FILE>`:
> `git diff <OLD>..<NEW> -- <FILE>`; (b) our current post-rebase `<FILE>`. Report only —
> do NOT edit. Find: (1) native-migration guidance reintroduced or surviving against the
> hard-scrub rule (§2); (2) our prose now contradicting changed upstream code/behavior;
> (3) genuine upstream improvements a conflict resolution dropped. Output findings as
> `{file, location, drift-type, evidence, suggested-fix}`; say "no findings" if clean.

## Phase 4 — Report → approve → apply → push

Aggregate findings into a short report. Present proposed edits for **human approval**
(report-only philosophy). On approval, apply, re-run `scripts/guardrails.sh`, then:

```bash
git push --force-with-lease origin feature/rockmigrations-agent-instructions
```

## Full-state audit mode (no upstream delta)

Phases 0–4 are **diff-driven** — they audit only `OLD..NEW`, so Phase 0 exits early when
upstream is unchanged. That is correct for routine syncs but **blind to pre-existing
fork debt** and to drift accumulated before the invariants tightened.

Run a **full-state audit** instead when: doing an initial/one-time debt sweep, after a
material change to `references/FORK-INVARIANTS.md`, or as a periodic deep check. Procedure:

- Skip Phase 0's early-exit. Audit the **entire current content** of every overlay-touched
  file (not a diff): `README.md`, `AGENTS.md`, `agent_cli.md`,
  `installable-skills/processwire-agenttools/{SKILL.md,migrations.md}`, plus
  `AgentToolsEngineer.php` for code invariants.
- Use the Phase 3 subagent prompt, but state the scope is **full-state** (whole file), and
  fan out one subagent per file in parallel (Opus).
- Still **report-only** → human-approved fixes → `scripts/guardrails.sh` → push.

## Common mistakes

- Fetching before capturing `OLD` → audit scope lost (`detect-scope.sh` captures `OLD`
  first; use it rather than hand-running the git dance).
- Treating a clean merge as "nothing to check" → silent drift is the whole point of Phase 3.
- Re-stripping markdown trailing whitespace during conflict resolution → reintroduces the
  recurring README conflict.
- Auto-applying audit fixes → this fork is a deliberate divergence; keep the human gate.
- Opening a PR to upstream → see Hard rule.
