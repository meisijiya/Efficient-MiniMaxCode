# Efficient-MiniMaxCode Verifier (Windows PowerShell)
#
# Checks that all expected agents and skills are correctly installed.
# Reports what's missing or mismatched.
#
# Usage:
#   .\verify.ps1
#   .\verify.ps1 -MavisDir "D:\path\.mavis"

[CmdletBinding()]
param(
    [string]$MavisDir
)

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")

if (-not $MavisDir) {
    $MavisDir = Join-Path $env:USERPROFILE ".mavis"
}

function Write-Step($msg) { Write-Host "`n===> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERR] $msg" -ForegroundColor Red }

$missingAgents = @()
$missingSkills = @()
$outdatedAgents = @()
$outdatedSkills = @()

# === Verify agents ===
Write-Step "Verifying agents (13 expected)"

$expectedAgents = Get-ChildItem (Join-Path $RepoRoot "agents") -Directory | ForEach-Object { $_.Name }
foreach ($name in $expectedAgents) {
    $expected = Join-Path $RepoRoot "agents\$name\agent.md"
    $actual = Join-Path $MavisDir "agents\$name\agent.md"
    if (-not (Test-Path $actual)) {
        Write-Err "missing: $MavisDir\agents\$name\agent.md"
        $missingAgents += $name
    } else {
        # Compare content
        $expHash = (Get-FileHash $expected -Algorithm SHA256).Hash
        $actHash = (Get-FileHash $actual -Algorithm SHA256).Hash
        if ($expHash -ne $actHash) {
            Write-Warn "outdated: $name (run install.ps1 to update)"
            $outdatedAgents += $name
        } else {
            Write-Ok "$name"
        }
    }
}

# === Verify skills ===
Write-Step "Verifying skills (23 expected)"

$expectedSkills = Get-ChildItem (Join-Path $RepoRoot "skills") -Directory | ForEach-Object { $_.Name }
foreach ($name in $expectedSkills) {
    $expected = Join-Path $RepoRoot "skills\$name\SKILL.md"
    $actual = Join-Path $MavisDir "skills\$name\SKILL.md"
    if (-not (Test-Path $actual)) {
        Write-Err "missing: $MavisDir\skills\$name\SKILL.md"
        $missingSkills += $name
    } else {
        $expHash = (Get-FileHash $expected -Algorithm SHA256).Hash
        $actHash = (Get-FileHash $actual -Algorithm SHA256).Hash
        if ($expHash -ne $actHash) {
            Write-Warn "outdated: $name (run install.ps1 to update)"
            $outdatedSkills += $name
        } else {
            Write-Ok "$name"
        }
    }
}

# === Check mavis agent list ===
Write-Step "Checking mavis CLI"
$mavisCmd = Get-Command mavis -ErrorAction SilentlyContinue
if ($mavisCmd) {
    $list = mavis agent list 2>&1 | Out-String
    $expectedAgentCount = $expectedAgents.Count
    $actualAgentCount = ($list | Select-String '"name"' -SimpleMatch).Count
    if ($actualAgentCount -ge $expectedAgentCount) {
        Write-Ok "mavis list shows $actualAgentCount agents (expected $expectedAgentCount+)"
    } else {
        Write-Warn "mavis list shows $actualAgentCount agents (expected $expectedAgentCount+)"
    }
} else {
    Write-Warn "mavis CLI not in PATH. Skipping list check."
}

# === Summary ===
Write-Step "Summary"
$total = ($expectedAgents.Count + $expectedSkills.Count)
$problems = ($missingAgents.Count + $missingSkills.Count + $outdatedAgents.Count + $outdatedSkills.Count)

if ($problems -eq 0) {
    Write-Host ""
    Write-Host "  All $total agents/skills are correctly installed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "  $problems issues found:" -ForegroundColor Yellow
    if ($missingAgents.Count -gt 0)     { Write-Host "    Missing agents: $($missingAgents -join ', ')" }
    if ($missingSkills.Count -gt 0)     { Write-Host "    Missing skills: $($missingSkills -join ', ')" }
    if ($outdatedAgents.Count -gt 0)    { Write-Host "    Outdated agents: $($outdatedAgents -join ', ')" }
    if ($outdatedSkills.Count -gt 0)    { Write-Host "    Outdated skills: $($outdatedSkills -join ', ')" }
    Write-Host ""
    Write-Host "  Run install.ps1 to fix." -ForegroundColor Cyan
    exit 1
}
