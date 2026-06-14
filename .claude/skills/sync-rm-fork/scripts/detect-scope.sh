#!/usr/bin/env bash
# detect-scope.sh — Phase 0 of the RM-fork sync: capture the upstream delta and the
# exact audit scope in one shot, so the agent gathers everything it needs from one call.
#
# Read-only: the only thing it changes is remote-tracking refs (`git fetch upstream`).
# It does NOT touch the working tree, rebase, or push — those stay agent/human-gated.
# It structurally enforces the footgun the prose only warned about: capture OLD *before*
# the fetch.
#
# Run from anywhere — it cd's to the repo root.
#   exit 0 = report produced (read "UPSTREAM_CHANGED:" to decide whether to proceed)
#   exit 2 = operational failure (no repo / no `upstream` remote / fetch failed)
set -uo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "ERROR: not in a git repo" >&2; exit 2; }
cd "$root" || exit 2
git remote get-url upstream >/dev/null 2>&1 || { echo "ERROR: no 'upstream' remote configured" >&2; exit 2; }

# Overlay surface: the prose docs the audit covers + the one PHP file it cross-checks.
OVERLAY_FILES=(
  README.md
  AGENTS.md
  agent_cli.md
  installable-skills/processwire-agenttools/SKILL.md
  installable-skills/processwire-agenttools/migrations.md
  AgentToolsEngineer.php
)

OLD=$(git rev-parse upstream/main 2>/dev/null) \
  || { echo "ERROR: upstream/main not found — run 'git fetch upstream' once first" >&2; exit 2; }
git fetch --quiet upstream || { echo "ERROR: 'git fetch upstream' failed" >&2; exit 2; }
NEW=$(git rev-parse upstream/main)

echo "=== RM-fork sync scope ==="
echo "OLD (last synced upstream/main): $OLD"
echo "NEW (current  upstream/main):    $NEW"

if [ "$OLD" = "$NEW" ]; then
  echo "UPSTREAM_CHANGED: no"
  echo "→ Nothing to do for a routine sync. (For a deliberate deep check, use full-state audit mode.)"
  exit 0
fi
echo "UPSTREAM_CHANGED: yes"
echo "→ Record OLD and NEW above — Phase 1 rebases onto NEW; Phase 3 diffs each file over OLD..NEW."

echo
echo "--- upstream commits OLD..NEW ---"
git log --oneline --no-decorate "$OLD".."$NEW"

echo
echo "--- changed overlay files (Phase 3 audit scope) ---"
scope=$(git diff --name-only "$OLD".."$NEW" -- "${OVERLAY_FILES[@]}")
if [ -n "$scope" ]; then
  printf '%s\n' "$scope"
else
  echo "(none changed — but a clean merge can still drift; check the §3 hints below)"
fi

echo
echo "--- §3 drift-tripwire hints (HEURISTIC — confirm against FORK-INVARIANTS.md §3) ---"
hit=0
note() { printf '  • %s\n' "$1"; hit=1; }
changed=$(git diff --name-only "$OLD".."$NEW")

if printf '%s\n' "$changed" | grep -Fxq "AgentToolsEngineer.php"; then
  eng=$(git diff "$OLD".."$NEW" -- AgentToolsEngineer.php)
  printf '%s' "$eng" | grep -Fq "eval_php" \
    && note "eval_php changed → re-check RM-mode prompt + eval_php description (§3 row 2)"
  printf '%s' "$eng" | grep -Fq "usesNativeMigrations" \
    && note "migration-gating code changed → re-check invariants 1.2/1.3 guards (§3 rows 1,3)"
  printf '%s' "$eng" | grep -Eiq "system.?prompt" \
    && note "system-prompt code changed → re-check workflow branch wrapping + native branch verbatim (§3 row 6)"
fi
if printf '%s\n' "$changed" | grep -Fxq "AgentTools.module.php"; then
  git diff "$OLD".."$NEW" -- AgentTools.module.php | grep -Eq "version|@property|keys" \
    && note "module registration surface changed → re-check engineer_migration_workflow isn't shadowed (§3 row 4)"
fi
printf '%s\n' "$changed" | grep -Eiq "migration" \
  && note "migration-named paths changed upstream → reconcile any migration docs with the RM overlay (§3 row 5)"

[ "$hit" -eq 0 ] && echo "  (no heuristic hits — still skim §3 to be sure)"

echo
echo "NEXT: scripts/guardrails.sh (Phase 2) → one Phase 3 subagent per changed overlay file."
