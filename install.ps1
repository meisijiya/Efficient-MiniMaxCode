# Efficient-MiniMaxCode Installer (Windows PowerShell)
#
# Installs agents and skills from this repo into ~/.mavis/
# Only copies user-controlled files (agent.md, SKILL.md).
# Skips daemon-generated files (config.yaml, PERSONA.md, _meta.json, etc.)
#
# Usage:
#   .\install.ps1                    # Normal install
#   .\install.ps1 -ForceAll          # Also copy daemon-generated files (NOT recommended)
#   .\install.ps1 -DryRun            # Show what would be done, don't actually copy
#   .\install.ps1 -MavisDir "D:\path\.mavis"  # Custom Mavis directory

[CmdletBinding()]
param(
    [switch]$ForceAll,
    [switch]$DryRun,
    [string]$MavisDir
)

$ErrorActionPreference = "Stop"

# === Configuration ===
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path $ScriptDir

# Default Mavis directory
if (-not $MavisDir) {
    $MavisDir = Join-Path $env:USERPROFILE ".mavis"
}

# Files that are daemon-generated — skip by default
$SkipFiles = @("config.yaml", "PERSONA.md", ".builtin-prompt-layout-v2", "_meta.json")

# === Helpers ===
function Write-Step($msg) { Write-Host "`n===> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERR] $msg" -ForegroundColor Red }

# === Pre-flight checks ===
Write-Step "Pre-flight checks"

if (-not (Test-Path $MavisDir)) {
    Write-Err "Mavis directory not found: $MavisDir"
    Write-Host "    Hint: is Mavis Code installed? Try running 'mavis --version' to verify."
    exit 1
}
Write-Ok "Mavis directory: $MavisDir"

$agentsSrc = Join-Path $RepoRoot "agents"
$skillsSrc = Join-Path $RepoRoot "skills"
if (-not (Test-Path $agentsSrc)) {
    Write-Err "agents/ not found in repo: $agentsSrc"
    exit 1
}
if (-not (Test-Path $skillsSrc)) {
    Write-Err "skills/ not found in repo: $skillsSrc"
    exit 1
}
Write-Ok "Source directory: $RepoRoot"

# === Copy agents ===
Write-Step "Installing agents"

$agentCount = 0
$agentSkipped = 0
Get-ChildItem $agentsSrc -Directory | ForEach-Object {
    $name = $_.Name
    $dst = Join-Path $MavisDir "agents\$name"

    if (-not (Test-Path $dst)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }

    # Copy each file in the source, skipping daemon-generated ones
    Get-ChildItem $_.FullName -File | ForEach-Object {
        $f = $_.Name
        if (-not $ForceAll -and $SkipFiles -contains $f) {
            $agentSkipped++
            return
        }
        $srcPath = $_.FullName
        $dstPath = Join-Path $dst $f
        if ($DryRun) {
            Write-Host "  [DRY] would copy: agents/$name/$f"
        } else {
            Copy-Item $srcPath -Destination $dstPath -Force
        }
        $agentCount++
    }

    if (-not $DryRun) {
        Write-Ok "agent: $name"
    }
}

# === Copy skills ===
Write-Step "Installing skills"

$skillCount = 0
$skillSkipped = 0
Get-ChildItem $skillsSrc -Directory | ForEach-Object {
    $name = $_.Name
    $dst = Join-Path $MavisDir "skills\$name"

    if (-not (Test-Path $dst)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }

    Get-ChildItem $_.FullName -File | ForEach-Object {
        $f = $_.Name
        if (-not $ForceAll -and $SkipFiles -contains $f) {
            $skillSkipped++
            return
        }
        $srcPath = $_.FullName
        $dstPath = Join-Path $dst $f
        if ($DryRun) {
            Write-Host "  [DRY] would copy: skills/$name/$f"
        } else {
            Copy-Item $srcPath -Destination $dstPath -Force
        }
        $skillCount++
    }

    if (-not $DryRun) {
        Write-Ok "skill: $name"
    }
}

# === Trigger daemon re-registration ===
if (-not $DryRun) {
    Write-Step "Triggering daemon re-registration"
    $mavisCmd = Get-Command mavis -ErrorAction SilentlyContinue
    if ($mavisCmd) {
        mavis agent list 2>&1 | Out-Null
        Write-Ok "mavis agent list executed (daemon will re-scan ~/.mavis/agents/)"
    } else {
        Write-Warn "mavis CLI not found in PATH. Run 'mavis agent list' manually after install."
    }
}

# === Summary ===
Write-Step "Summary"
if ($DryRun) {
    Write-Host "  DRY RUN: nothing was copied"
} else {
    Write-Ok "Copied $agentCount agent files + $skillCount skill files"
    if ($agentSkipped + $skillSkipped -gt 0) {
        Write-Host "  Skipped $($agentSkipped + $skillSkipped) daemon-generated files (use -ForceAll to override)"
    }
}

Write-Host "`nNext step: run .\verify.ps1 to confirm installation.`n" -ForegroundColor Cyan
