# claude-settings installer (Windows / PowerShell 7+)
# Usage: pwsh ./install.ps1 [-Copy] [-DryRun]
#   -Copy     Force copy mode (default tries symlink, falls back to copy)
#   -DryRun   Show actions without executing
#
# Note: Symbolic links on Windows require either admin privileges or
#       Developer Mode enabled (Settings > Privacy > For developers).

param(
    [switch]$Copy,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoDir = $PSScriptRoot
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$BackupDir = Join-Path $ClaudeHome (".backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

function Log([string]$msg) { Write-Host "[install] $msg" }
function Run([scriptblock]$block) {
    if ($DryRun) { Write-Host "[dry-run] $($block.ToString().Trim())" }
    else { & $block }
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

# 3. mcp.json — render template (substitute ${VAR} from secrets.env if present, else copy as-is)
$SecretsFile = "$RepoDir/secrets/secrets.env"
$Template = "$RepoDir/claude/mcp.template.json"
if (Test-Path $Template) {
    Backup-IfNeeded "$ClaudeHome/mcp.json"
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
        $content = [regex]::Replace($content, '\$\{(\w+)\}', {
            param($m)
            if ($env_table.ContainsKey($m.Groups[1].Value)) { $env_table[$m.Groups[1].Value] }
            else { $m.Value }
        })
        if ($content -match '\$\{') {
            Log "WARNING: unresolved `${...} placeholders remain — check secrets/secrets.env"
        }
        Set-Content -Path "$ClaudeHome/mcp.json" -Value $content -NoNewline
        Log "rendered: $ClaudeHome/mcp.json"
    }
}

# 5. platform-specific (Windows extras, if any)
$PlatformInstaller = "$RepoDir/platform/windows/install.ps1"
if (Test-Path $PlatformInstaller) {
    Log "running platform installer: windows"
    Run { & $PlatformInstaller }
}

Log "done."
