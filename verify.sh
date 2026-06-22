#!/usr/bin/env bash
# Efficient-MiniMaxCode Verifier (macOS / Linux)
#
# Checks that all expected agents and skills are correctly installed.
# Usage: ./verify.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAVIS_DIR="${HOME}/.mavis"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mavis-dir) MAVIS_DIR="$2"; shift 2 ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# //; s/^#//'
            exit 0
            ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

step() { printf "\n\033[1;36m===> %s\033[0m\n" "$1"; }
ok()   { printf "  \033[1;32m[OK]\033[0m %s\n" "$1"; }
warn() { printf "  \033[1;33m[WARN]\033[0m %s\n" "$1"; }
err()  { printf "  \033[1;31m[ERR]\033[0m %s\n" "$1"; }

missing_agents=()
missing_skills=()
outdated_agents=()
outdated_skills=()

# === Verify agents ===
step "Verifying agents"
expected_agents=()
for d in "$REPO_ROOT/agents"/*/; do
    [[ -d "$d" ]] && expected_agents+=("$(basename "$d")")
done

for name in "${expected_agents[@]}"; do
    expected="$REPO_ROOT/agents/$name/agent.md"
    actual="$MAVIS_DIR/agents/$name/agent.md"
    if [[ ! -f "$actual" ]]; then
        err "missing: $MAVIS_DIR/agents/$name/agent.md"
        missing_agents+=("$name")
    elif ! cmp -s "$expected" "$actual"; then
        warn "outdated: $name (run install.sh to update)"
        outdated_agents+=("$name")
    else
        ok "$name"
    fi
done

# === Verify skills ===
step "Verifying skills"
expected_skills=()
for d in "$REPO_ROOT/skills"/*/; do
    [[ -d "$d" ]] && expected_skills+=("$(basename "$d")")
done

for name in "${expected_skills[@]}"; do
    expected="$REPO_ROOT/skills/$name/SKILL.md"
    actual="$MAVIS_DIR/skills/$name/SKILL.md"
    if [[ ! -f "$actual" ]]; then
        err "missing: $MAVIS_DIR/skills/$name/SKILL.md"
        missing_skills+=("$name")
    elif ! cmp -s "$expected" "$actual"; then
        warn "outdated: $name (run install.sh to update)"
        outdated_skills+=("$name")
    else
        ok "$name"
    fi
done

# === Check mavis CLI ===
step "Checking mavis CLI"
if command -v mavis &> /dev/null; then
    list=$(mavis agent list 2>&1 || true)
    actual_count=$(echo "$list" | grep -c '"name"' || true)
    if [[ $actual_count -ge ${#expected_agents[@]} ]]; then
        ok "mavis list shows $actual_count agents (expected ${#expected_agents[@]}+)"
    else
        warn "mavis list shows $actual_count agents (expected ${#expected_agents[@]}+)"
    fi
else
    warn "mavis CLI not in PATH. Skipping list check."
fi

# === Summary ===
step "Summary"
total=$((${#expected_agents[@]} + ${#expected_skills[@]}))
problems=$((${#missing_agents[@]} + ${#missing_skills[@]} + ${#outdated_agents[@]} + ${#outdated_skills[@]}))

if [[ $problems -eq 0 ]]; then
    printf "\n  \033[1;32mAll %d agents/skills are correctly installed!\033[0m\n" "$total"
    exit 0
else
    printf "\n  \033[1;33m%d issues found:\033[0m\n" "$problems"
    [[ ${#missing_agents[@]} -gt 0 ]]  && echo "    Missing agents: ${missing_agents[*]}"
    [[ ${#missing_skills[@]} -gt 0 ]]  && echo "    Missing skills: ${missing_skills[*]}"
    [[ ${#outdated_agents[@]} -gt 0 ]] && echo "    Outdated agents: ${outdated_agents[*]}"
    [[ ${#outdated_skills[@]} -gt 0 ]] && echo "    Outdated skills: ${outdated_skills[*]}"
    printf "\n  \033[1;36mRun install.sh to fix.\033[0m\n"
    exit 1
fi
