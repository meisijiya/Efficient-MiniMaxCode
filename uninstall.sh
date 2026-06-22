#!/usr/bin/env bash
# Efficient-MiniMaxCode Uninstaller (macOS / Linux)
#
# Removes agent.md and SKILL.md files installed by this repo.
# Moves them to a backup directory for safety.
# Leaves daemon-generated files (config.yaml, PERSONA.md, _meta.json) untouched.
#
# Usage:
#   ./uninstall.sh                # Interactive
#   ./uninstall.sh --force        # No confirmation
#   ./uninstall.sh --dry-run      # Show what would be done

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAVIS_DIR="${HOME}/.mavis"

FORCE=false
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)   FORCE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
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

# === Identify installed files ===
step "Identifying installed files"

agent_names=()
skill_names=()
for d in "$REPO_ROOT/agents"/*/; do
    [[ -d "$d" ]] && agent_names+=("$(basename "$d")")
done
for d in "$REPO_ROOT/skills"/*/; do
    [[ -d "$d" ]] && skill_names+=("$(basename "$d")")
done

if [[ ${#agent_names[@]} -eq 0 && ${#skill_names[@]} -eq 0 ]]; then
    err "No agents/skills in repo: $REPO_ROOT"
    exit 1
fi

ok "Found ${#agent_names[@]} agents and ${#skill_names[@]} skills in repo"

# === Confirm ===
if [[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]]; then
    printf "\n\033[1;33mThis will MOVE the following files to a backup directory:\033[0m\n"
    for a in "${agent_names[@]}"; do echo "  - $MAVIS_DIR/agents/$a/agent.md"; done
    for s in "${skill_names[@]}"; do echo "  - $MAVIS_DIR/skills/$s/SKILL.md"; done
    printf "\n"
    read -rp "Continue? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# === Create backup ===
timestamp=$(date +"%Y%m%d-%H%M%S")
backup_dir="$MAVIS_DIR/.efficient-backup-$timestamp"
if [[ "$DRY_RUN" != "true" ]]; then
    mkdir -p "$backup_dir"
    ok "Backup directory: $backup_dir"
fi

# === Move agents ===
step "Removing agents"
for name in "${agent_names[@]}"; do
    src="$MAVIS_DIR/agents/$name/agent.md"
    if [[ -f "$src" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  [DRY] would move: agents/$name/agent.md"
        else
            mkdir -p "$backup_dir/agents/$name"
            mv "$src" "$backup_dir/agents/$name/agent.md"
        fi
        ok "moved: agents/$name/agent.md"
    else
        warn "not found: agents/$name/agent.md (skip)"
    fi
done

# === Move skills ===
step "Removing skills"
for name in "${skill_names[@]}"; do
    src="$MAVIS_DIR/skills/$name/SKILL.md"
    if [[ -f "$src" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  [DRY] would move: skills/$name/SKILL.md"
        else
            mkdir -p "$backup_dir/skills/$name"
            mv "$src" "$backup_dir/skills/$name/SKILL.md"
        fi
        ok "moved: skills/$name/SKILL.md"
    else
        warn "not found: skills/$name/SKILL.md (skip)"
    fi
done

# === Summary ===
step "Summary"
if [[ "$DRY_RUN" == "true" ]]; then
    echo "  DRY RUN: nothing was moved"
else
    ok "Uninstall complete. Backup at: $backup_dir"
    printf "\n\033[1;36mTo restore, copy files back from the backup.\033[0m\n"
    printf "\033[1;36mExample: cp -r %q/. %q\033[0m\n" "$backup_dir" "$MAVIS_DIR"
fi
