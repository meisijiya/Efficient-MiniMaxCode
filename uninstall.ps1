# Efficient-MiniMaxCode Uninstaller (Windows PowerShell)
#
# Removes agent.md and SKILL.md files installed by this repo.
# Moves them to a backup directory for safety.
# Leaves daemon-generated files (config.yaml, PERSONA.md, _meta.json) untouched.
#
# Usage:
#   .\uninstall.ps1                # Interactive (asks for confirmation)
#   .\uninstall.ps1 -Force         # No confirmation
#   .\uninstall.ps1 -DryRun        # Show what would be done

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun,
    [string]$MavisDir
)

$ErrorActionPreference = "Stop"

# === Configuration ===
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path $ScriptDir

if (-not $MavisDir) {
    $MavisDir = Join-Path $env:USERPROFILE ".mavis"
}

# === Helpers ===
function Write-Step($msg) { Write-Host "`n===> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERR] $msg" -ForegroundColor Red }

# === Identify what we installed ===
Write-Step "Identifying installed files"

# Read all agent names and skill names from the repo
$agentNames = Get-ChildItem (Join-Path $RepoRoot "agents") -Directory | ForEach-Object { $_.Name }
$skillNames = Get-ChildItem (Join-Path $RepoRoot "skills") -Directory | ForEach-Object { $_.Name }

if (-not $agentNames -and -not $skillNames) {
    Write-Err "Could not find any agents/skills in repo: $RepoRoot"
    exit 1
}

Write-Host "  Found $($agentNames.Count) agents and $($skillNames.Count) skills in repo"

# === Confirm ===
if (-not $Force -and -not $DryRun) {
    Write-Host ""
    Write-Host "This will MOVE the following files to a backup directory:" -ForegroundColor Yellow
    foreach ($a in $agentNames) { Write-Host "  - $MavisDir\agents\$a\agent.md" }
    foreach ($s in $skillNames) { Write-Host "  - $MavisDir\skills\$s\SKILL.md" }
    Write-Host ""
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled."
        exit 0
    }
}

# === Create backup directory ===
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $MavisDir ".efficient-backup-$timestamp"
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Ok "Backup directory: $backupDir"
}

# === Move agents ===
Write-Step "Removing agents"
foreach ($name in $agentNames) {
    $src = Join-Path $MavisDir "agents\$name\agent.md"
    if (Test-Path $src) {
        $dstDir = Join-Path $backupDir "agents\$name"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            Move-Item $src -Destination (Join-Path $dstDir "agent.md") -Force
        }
        Write-Ok "moved: agents/$name/agent.md"
    } else {
        Write-Warn "not found: agents/$name/agent.md (skip)"
    }
}

# === Move skills ===
Write-Step "Removing skills"
foreach ($name in $skillNames) {
    $src = Join-Path $MavisDir "skills\$name\SKILL.md"
    if (Test-Path $src) {
        $dstDir = Join-Path $backupDir "skills\$name"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            Move-Item $src -Destination (Join-Path $dstDir "SKILL.md") -Force
        }
        Write-Ok "moved: skills/$name/SKILL.md"
    } else {
        Write-Warn "not found: skills/$name/SKILL.md (skip)"
    }
}

# === Summary ===
Write-Step "Summary"
if ($DryRun) {
    Write-Host "  DRY RUN: nothing was moved"
} else {
    Write-Ok "Uninstall complete. Backup at: $backupDir"
    Write-Host ""
    Write-Host "To restore, copy files back from the backup." -ForegroundColor Cyan
    Write-Host "Example:" -ForegroundColor Cyan
    Write-Host "  Copy-Item -Recurse '$backupDir\agents\*' '$MavisDir\agents\'" -ForegroundColor Cyan
}
