# claude-settings installer (Windows / PowerShell 7+)
# Usage: pwsh ./install.ps1 [-Copy] [-DryRun] [-Verbose]
#   -Copy     Force copy mode (default tries symlink, falls back to copy)
#   -DryRun   Show actions without executing
#   -Verbose  Print extra detail (idempotent skips, resolved secrets count)
#
# Note: Symbolic links on Windows require either admin privileges or
#       Developer Mode enabled (Settings > Privacy > For developers).

param(
    [switch]$Copy,
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$RepoDir = $PSScriptRoot
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$BackupDir = Join-Path $ClaudeHome (".backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

function Log([string]$msg)   { Write-Host "[install] $msg" }
function Debug([string]$msg) { if ($Verbose) { Write-Host "[debug]   $msg" } }
function Run([scriptblock]$block) {
    if ($DryRun) { Write-Host "[dry-run] $($block.ToString().Trim())" }
    else { & $block }
}

function Already-Linked([string]$target, [string]$src) {
    if (-not (Test-Path -LiteralPath $target)) { return $false }
    $item = Get-Item -LiteralPath $target -Force
    if (-not $item.LinkType) { return $false }
    return ($item.Target -eq $src) -or ($item.Target -contains $src)
}

function Backup-IfNeeded([string]$target) {
    if (-not (Test-Path -LiteralPath $target)) { return }
    $item = Get-Item -LiteralPath $target -Force
    if ($item.LinkType) {
        Run { Remove-Item -LiteralPath $target -Force }
        return
    }
    Run { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
    Run { Move-Item -LiteralPath $target -Destination "$BackupDir/" -Force }
    Log "backed up: $target -> $BackupDir/"
}

function Link-OrCopy([string]$src, [string]$dest) {
    if (-not (Test-Path -LiteralPath $src)) { Log "skip (missing source): $src"; return }
    if (-not $Copy -and (Already-Linked $dest $src)) {
        Debug "already linked: $dest -> $src (skip)"
        return
    }
    Backup-IfNeeded $dest
    $useCopy = $Copy
    if (-not $useCopy) {
        try {
            Run { New-Item -ItemType SymbolicLink -Path $dest -Target $src -Force | Out-Null }
            Log "linked:  $dest -> $src"
            return
        } catch {
            Log "symlink failed (need admin or Developer Mode), falling back to copy"
            $useCopy = $true
        }
    }
    if ($useCopy) {
        Run { Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force }
        Log "copied:  $dest"
    }
}

# 1. ensure ~/.claude
if (-not (Test-Path $ClaudeHome)) { Run { New-Item -ItemType Directory -Path $ClaudeHome -Force | Out-Null } }

# 2. settings.json
Link-OrCopy "$RepoDir/claude/settings.json" "$ClaudeHome/settings.json"

# 2b. user-level CLAUDE.md — universal behavioral rules applied across all projects
Link-OrCopy "$RepoDir/claude/CLAUDE.md" "$ClaudeHome/CLAUDE.md"

# 3. mcp.json — render template (substitute ${VAR} from secrets.env if present, else copy as-is).
#    Idempotent: skip backup + rewrite when rendered content matches the existing file.
$SecretsFile = "$RepoDir/secrets/secrets.env"
$Template = "$RepoDir/claude/mcp.template.json"
if (Test-Path $Template) {
    if ($DryRun) {
        Log "would render: $ClaudeHome/mcp.json"
    } else {
        $env_table = @{}
        if (Test-Path $SecretsFile) {
            Get-Content $SecretsFile | ForEach-Object {
                if ($_ -match '^\s*([^#=\s][^=]*)=(.*)$') {
                    $env_table[$matches[1].Trim()] = $matches[2].Trim()
                }
            }
        }
        $content = Get-Content $Template -Raw
        $resolved = 0
        $content = [regex]::Replace($content, '\$\{(\w+)\}', {
            param($m)
            if ($env_table.ContainsKey($m.Groups[1].Value)) {
                $script:resolved++
                $env_table[$m.Groups[1].Value]
            } else { $m.Value }
        })
        Debug "resolved $resolved `${VAR} placeholder(s) from secrets.env"
        if ($content -match '\$\{') {
            Log "WARNING: unresolved `${...} placeholders remain — check secrets/secrets.env"
        }
        $existing = if (Test-Path -LiteralPath "$ClaudeHome/mcp.json") { Get-Content -LiteralPath "$ClaudeHome/mcp.json" -Raw } else { $null }
        if ($null -ne $existing -and $existing -eq $content) {
            Debug "mcp.json unchanged (skip)"
        } else {
            Backup-IfNeeded "$ClaudeHome/mcp.json"
            Set-Content -Path "$ClaudeHome/mcp.json" -Value $content -NoNewline
            Log "rendered: $ClaudeHome/mcp.json"
        }
    }
}

# 4. user-scope skills — symlink each subdirectory individually so we don't
#    clobber any other skills the user has under ~/.claude/skills/.
$SkillsRoot = "$RepoDir/skills"
if (Test-Path -LiteralPath $SkillsRoot) {
    $SkillsDest = Join-Path $ClaudeHome "skills"
    if (-not (Test-Path -LiteralPath $SkillsDest)) {
        Run { New-Item -ItemType Directory -Path $SkillsDest -Force | Out-Null }
    }
    Get-ChildItem -LiteralPath $SkillsRoot -Directory | ForEach-Object {
        Link-OrCopy $_.FullName (Join-Path $SkillsDest $_.Name)
    }
}

# 5. platform-specific (Windows extras, if any)
$PlatformInstaller = "$RepoDir/platform/windows/install.ps1"
if (Test-Path $PlatformInstaller) {
    Log "running platform installer: windows"
    Run { & $PlatformInstaller }
}

# 6. local-overrides hint
$LocalFile = Join-Path $ClaudeHome "settings.local.json"
if (-not (Test-Path -LiteralPath $LocalFile)) {
    Log "hint: no $LocalFile - see templates/settings.local.example.json for per-machine plugin overrides"
}

Log "done. backup dir created only if a non-symlink file was overwritten."
