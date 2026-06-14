#!/usr/bin/env bash
# guardrails.sh — §1 deterministic code invariants for the RockMigrations overlay.
#
# This is the EXECUTABLE single source of truth for FORK-INVARIANTS.md §1. The rubric
# documents *what* holds and *why*; this script is *how* it's checked, so the documented
# tripwire and the run tripwire can never drift apart (they did once: a `grep -q` vs the
# `grep -qF` a literal `$` needs).
#
# Run from anywhere — it cd's to the repo root. Read-only.
#   exit 0 = all invariants hold
#   exit 1 = at least one hard regression — do NOT proceed with the sync
#   exit 2 = operational failure (not a git repo)
set -uo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "ERROR: not in a git repo" >&2; exit 2; }
cd "$root" || exit 2

fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "§1 code invariants (RockMigrations overlay):"

if php -l AgentToolsEngineer.php       >/dev/null 2>&1 \
&& php -l AgentTools.module.php         >/dev/null 2>&1 \
&& php -l AgentToolsEngineerConfig.php  >/dev/null 2>&1 \
&& php -l ProcessAgentTools.module.php  >/dev/null 2>&1; then
  ok "php -l (4 overlay files parse)"
else
  bad "php -l (4 overlay files parse)"
fi

grep -q "migrationWorkflowRockMigrations = 'rockmigrations'" AgentToolsEngineer.php \
  && ok "migrationWorkflowRockMigrations constant present" \
  || bad "migrationWorkflowRockMigrations constant present"

grep -q "function usesNativeMigrations" AgentToolsEngineer.php \
  && ok "usesNativeMigrations() helper present" \
  || bad "usesNativeMigrations() helper present"

# literal $ in the property name → fixed string, not regex
grep -qF '@property string $engineer_migration_workflow' AgentTools.module.php \
  && ok "engineer_migration_workflow @property registered" \
  || bad "engineer_migration_workflow @property registered"

# invariant 1.2: save_migration gated by usesNativeMigrations() in BOTH tool arrays
if [ "$(grep -cE 'usesNativeMigrations\(\)\) \{' AgentToolsEngineer.php)" -ge 2 ]; then
  ok "save_migration double-guard (Anthropic + OpenAI arrays)"
else
  bad "save_migration double-guard (Anthropic + OpenAI arrays)"
fi

# invariant 1.3: native migrate CLI neutralised in RM mode (literal $this → fixed string)
grep -qF 'migrate && !$this->usesNativeMigrations()' AgentToolsEngineer.php \
  && ok "native migrate CLI neutralisation guard" \
  || bad "native migrate CLI neutralisation guard"

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL — hard regression in the overlay; fix before proceeding."
  exit 1
fi
echo "RESULT: PASS — all §1 invariants hold."
