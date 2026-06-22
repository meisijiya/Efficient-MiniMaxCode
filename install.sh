#!/usr/bin/env bash
# Efficient-MiniMaxCode Installer (macOS / Linux)
#
# Installs agents and skills from this repo into ~/.mavis/
# Only copies user-controlled files (agent.md, SKILL.md).
# Skips daemon-generated files (config.yaml, PERSONA.md, _meta.json, etc.)
#
# Usage:
#   ./install.sh                    # Normal install
#   ./install.sh --force-all        # Also copy daemon-generated files (NOT recommended)
#   ./install.sh --dry-run          # Show what would be done, don't actually copy
#   ./install.sh --mavis-dir PATH   # Custom Mavis directory

set -euo pipefail

# === Configuration ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default Mavis directory
MAVIS_DIR="${HOME}/.mavis"

# Parse arguments
FORCE_ALL=false
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force-all) FORCE_ALL=true; shift ;;
        --dry-run)   DRY_RUN=true; shift ;;
        --mavis-dir) MAVIS_DIR="$2"; shift 2 ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# //; s/^#//'
            exit 0
            ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# Files that are daemon-generated — skip by default
SKIP_FILES=("config.yaml" "PERSONA.md" ".builtin-prompt-layout-v2" "_meta.json")

# === Helpers ===
step() { printf "\n\033[1;36m===> %s\033[0m\n" "$1"; }
ok()   { printf "  \033[1;32m[OK]\033[0m %s\n" "$1"; }
warn() { printf "  \033[1;33m[WARN]\033[0m %s\n" "$1"; }
err()  { printf "  \033[1;31m[ERR]\033[0m %s\n" "$1"; }

# === Pre-flight checks ===
step "Pre-flight checks"

if [[ ! -d "$MAVIS_DIR" ]]; then
    err "Mavis directory not found: $MAVIS_DIR"
    echo "    Hint: is Mavis Code installed? Try 'mavis --version'."
    exit 1
fi
ok "Mavis directory: $MAVIS_DIR"

AGENTS_SRC="$REPO_ROOT/agents"
SKILLS_SRC="$REPO_ROOT/skills"
if [[ ! -d "$AGENTS_SRC" ]]; then
    err "agents/ not found in repo: $AGENTS_SRC"
    exit 1
fi
if [[ ! -d "$SKILLS_SRC" ]]; then
    err "skills/ not found in repo: $SKILLS_SRC"
    exit 1
fi
ok "Source directory: $REPO_ROOT"

# === Copy function ===
should_skip() {
    local f="$1"
    if [[ "$FORCE_ALL" == "true" ]]; then
        return 1  # don't skip
    fi
    for skip in "${SKIP_FILES[@]}"; do
        if [[ "$f" == "$skip" ]]; then
            return 0  # skip
        fi
    done
    return 1
}

# === Copy agents ===
step "Installing agents"
agent_count=0
agent_skipped=0
for agent_dir in "$AGENTS_SRC"/*/; do
    name=$(basename "$agent_dir")
    dst="$MAVIS_DIR/agents/$name"
    mkdir -p "$dst"

    while IFS= read -r -d '' src_file; do
        f=$(basename "$src_file")
        if should_skip "$f"; then
            ((agent_skipped++))
            continue
        fi
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  [DRY] would copy: agents/$name/$f"
        else
            cp "$src_file" "$dst/$f"
        fi
        ((agent_count++))
    done < <(find "$agent_dir" -maxdepth 1 -type f -print0)

    if [[ "$DRY_RUN" != "true" ]]; then
        ok "agent: $name"
    fi
done

# === Copy skills ===
step "Installing skills"
skill_count=0
skill_skipped=0
for skill_dir in "$SKILLS_SRC"/*/; do
    name=$(basename "$skill_dir")
    dst="$MAVIS_DIR/skills/$name"
    mkdir -p "$dst"

    while IFS= read -r -d '' src_file; do
        f=$(basename "$src_file")
        if should_skip "$f"; then
            ((skill_skipped++))
            continue
        fi
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  [DRY] would copy: skills/$name/$f"
        else
            cp "$src_file" "$dst/$f"
        fi
        ((skill_count++))
    done < <(find "$skill_dir" -maxdepth 1 -type f -print0)

    if [[ "$DRY_RUN" != "true" ]]; then
        ok "skill: $name"
    fi
done

# === Trigger daemon re-registration ===
if [[ "$DRY_RUN" != "true" ]]; then
    step "Triggering daemon re-registration"
    if command -v mavis &> /dev/null; then
        mavis agent list &> /dev/null || true
        ok "mavis agent list executed (daemon will re-scan ~/.mavis/agents/)"
    else
        warn "mavis CLI not found in PATH. Run 'mavis agent list' manually after install."
    fi
fi

# === Summary ===
step "Summary"
if [[ "$DRY_RUN" == "true" ]]; then
    echo "  DRY RUN: nothing was copied"
else
    ok "Copied $agent_count agent files + $skill_count skill files"
    if [[ $((agent_skipped + skill_skipped)) -gt 0 ]]; then
        echo "  Skipped $((agent_skipped + skill_skipped)) daemon-generated files (use --force-all to override)"
    fi
fi

printf "\n\033[1;36mNext step: run ./verify.sh to confirm installation.\033[0m\n"
