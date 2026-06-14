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
audit** (subagents) against `FORK-INVARIANTS.md`. The audit is **report-only** — propose
fixes, get human approval, then apply.

## ⛔ Hard rule

**NEVER open a PR from the patch branch to `upstream`.** This is a permanent, deliberate
divergence, not a contribution. Ignore GitHub's "create a pull request" link after pushing.

## Phase 0 — Detect (capture OLD *before* fetch)

```bash
OLD=$(git rev-parse upstream/main)      # last synced upstream — MUST capture before fetch
git fetch upstream
NEW=$(git rev-parse upstream/main)
[ "$OLD" = "$NEW" ] && echo "no upstream change — stop" && exit 0
```

`OLD..NEW` is the exact upstream surface to audit. Losing it (fetching before capturing)
means re-auditing everything blindly — don't.

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

Run the tripwire block from `FORK-INVARIANTS.md` §1 (php -l + the invariant greps). Any
failure is a hard regression in the rebase — fix before proceeding.

## Phase 3 — Diff-driven semantic audit (subagents, report-only)

List the files upstream changed in `OLD..NEW` that the overlay also touches:

```bash
git diff --name-only "$OLD".."$NEW" -- README.md AGENTS.md agent_cli.md \
  installable-skills/processwire-agenttools/SKILL.md \
  installable-skills/processwire-agenttools/migrations.md AgentToolsEngineer.php
```

Also consult `FORK-INVARIANTS.md` §3 (drift tripwires) — an upstream change to tools,
`eval_php`, the CLI dispatch, module version/`$keys`, or migration docs forces a re-audit
of the mapped surface even if our file didn't conflict.

**Dispatch one subagent per affected file, in parallel.** Each gets this prompt:

> You are auditing one file of a downstream fork after an upstream sync. The fork's rules
> are in `FORK-INVARIANTS.md` (read it). Inputs: (a) upstream's change to `<FILE>`:
> `git diff <OLD>..<NEW> -- <FILE>`; (b) our current post-rebase `<FILE>`. Report only —
> do NOT edit. Find: (1) native-migration guidance reintroduced or surviving against the
> hard-scrub rule (§2); (2) our prose now contradicting changed upstream code/behavior;
> (3) genuine upstream improvements a conflict resolution dropped. Output findings as
> `{file, location, drift-type, evidence, suggested-fix}`; say "no findings" if clean.

## Phase 4 — Report → approve → apply → push

Aggregate findings into a short report. Present proposed edits for **human approval**
(report-only philosophy). On approval, apply, re-run Phase 2 guardrails, then:

```bash
git push --force-with-lease origin feature/rockmigrations-agent-instructions
```

## Common mistakes

- Fetching before capturing `OLD` → audit scope lost.
- Treating a clean merge as "nothing to check" → silent drift is the whole point of Phase 3.
- Re-stripping markdown trailing whitespace during conflict resolution → reintroduces the
  recurring README conflict.
- Auto-applying audit fixes → this fork is a deliberate divergence; keep the human gate.
- Opening a PR to upstream → see Hard rule.
