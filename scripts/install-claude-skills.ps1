param(
    [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")),
    [string] $SharedSkillsRoot = (Join-Path $env:USERPROFILE ".agents\skills"),
    [string] $ClaudeSkillsRoot = (Join-Path $env:USERPROFILE ".claude\skills"),
    [switch] $DryRun,
    [switch] $Force
)

$ErrorActionPreference = "Stop"

function Get-ManagedSkills {
    param([string] $Root)

    $manifestPath = Join-Path $Root "skills.manifest.json"
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Missing manifest: $manifestPath"
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if (-not $manifest.skills) {
        throw "Manifest has no skills list: $manifestPath"
    }

    return @($manifest.skills | ForEach-Object { $_.name } | Where-Object { $_ })
}

function Get-LinkTarget {
    param([System.IO.FileSystemInfo] $Item)

    if ($null -eq $Item.Target) {
        return $null
    }

    if ($Item.Target -is [array]) {
        return $Item.Target[0]
    }

    return [string] $Item.Target
}

function New-BackupPath {
    param([string] $Path)

    $stamp = Get-Date -Format "yyyyMMddHHmmss"
    return "$Path.backup.$stamp"
}

function Ensure-Junction {
    param(
        [string] $Name,
        [string] $Source,
        [string] $Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Missing shared runtime skill for ${Name}: $Source. Run scripts\install-codex-skills.ps1 first."
    }

    if (-not (Test-Path -LiteralPath (Split-Path -Parent $Destination))) {
        if ($DryRun) {
            Write-Output "Would create Claude skills root $(Split-Path -Parent $Destination)"
        }
        else {
            New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null
        }
    }

    if (-not (Test-Path -LiteralPath $Destination)) {
        if ($DryRun) {
            Write-Output "Would link $Name -> $Source"
        }
        else {
            New-Item -ItemType Junction -Path $Destination -Target $Source | Out-Null
            Write-Output "Linked $Name -> $Source"
        }
        return
    }

    $item = Get-Item -LiteralPath $Destination
    $target = Get-LinkTarget $item

    if ($item.LinkType -eq "Junction" -and $target -eq $Source) {
        Write-Output "Already linked $Name -> $Source"
        return
    }

    if (-not $Force) {
        throw "Refusing to replace existing ${Destination}. Re-run with -Force after verifying it should be managed."
    }

    $backupPath = New-BackupPath $Destination
    if ($DryRun) {
        Write-Output "Would move existing $Destination to $backupPath"
        Write-Output "Would link $Name -> $Source"
        return
    }

    Move-Item -LiteralPath $Destination -Destination $backupPath
    New-Item -ItemType Junction -Path $Destination -Target $Source | Out-Null
    Write-Output "Backed up $Name to $backupPath"
    Write-Output "Linked $Name -> $Source"
}

$repoRootPath = (Resolve-Path $RepoRoot).Path

foreach ($skillName in Get-ManagedSkills $repoRootPath) {
    Ensure-Junction `
        -Name $skillName `
        -Source (Join-Path $SharedSkillsRoot $skillName) `
        -Destination (Join-Path $ClaudeSkillsRoot $skillName)
}
