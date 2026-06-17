$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$codexScript = Join-Path $repoRoot "scripts\install-codex-skills.ps1"
$claudeScript = Join-Path $repoRoot "scripts\install-claude-skills.ps1"

function Assert-True {
    param(
        [bool] $Condition,
        [string] $Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-MatchText {
    param(
        [string] $Text,
        [string] $Pattern,
        [string] $Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-skills-shared-tests-" + [guid]::NewGuid().ToString("N"))
$sourceRoot = Join-Path $sandbox "repo"
$codexRoot = Join-Path $sandbox "agents-skills"
$claudeRoot = Join-Path $sandbox "claude-skills"

try {
    New-Item -ItemType Directory -Path (Join-Path $sourceRoot "skills\sample") -Force | Out-Null
    Set-Content -Path (Join-Path $sourceRoot "skills\sample\SKILL.md") -Value @(
        "---"
        "name: sample"
        "description: Test skill"
        "---"
        ""
        "Sample skill."
    )
    Set-Content -Path (Join-Path $sourceRoot "skills.manifest.json") -Value (@{
        skills = @(
            @{ name = "sample" }
        )
    } | ConvertTo-Json -Depth 4)

    $codexDryRun = & $codexScript -RepoRoot $sourceRoot -DestinationRoot $codexRoot -DryRun 2>&1 | Out-String
    Assert-MatchText $codexDryRun "Would link sample" "Codex dry run should report the managed skill junction."
    Assert-True (-not (Test-Path (Join-Path $codexRoot "sample"))) "Codex dry run should not create the destination skill."

    & $codexScript -RepoRoot $sourceRoot -DestinationRoot $codexRoot | Out-Null
    $codexEntry = Get-Item (Join-Path $codexRoot "sample")
    Assert-True ($codexEntry.LinkType -eq "Junction") "Codex install should create a junction."
    Assert-True ($codexEntry.Target -contains (Join-Path $sourceRoot "skills\sample")) "Codex junction should target the canonical skill."

    $claudeDryRun = & $claudeScript -RepoRoot $sourceRoot -SharedSkillsRoot $codexRoot -ClaudeSkillsRoot $claudeRoot -DryRun 2>&1 | Out-String
    Assert-MatchText $claudeDryRun "Would link sample" "Claude dry run should report the managed skill junction."
    Assert-True (-not (Test-Path (Join-Path $claudeRoot "sample"))) "Claude dry run should not create the junction."

    & $claudeScript -RepoRoot $sourceRoot -SharedSkillsRoot $codexRoot -ClaudeSkillsRoot $claudeRoot | Out-Null
    $claudeEntry = Get-Item (Join-Path $claudeRoot "sample")
    Assert-True ($claudeEntry.LinkType -eq "Junction") "Claude install should create a junction."
    Assert-True ($claudeEntry.Target -contains (Join-Path $codexRoot "sample")) "Claude junction should target the shared runtime skill."

    Write-Host "install-scripts.tests.ps1 passed"
}
finally {
    if (Test-Path $sandbox) {
        Remove-Item -LiteralPath $sandbox -Recurse -Force
    }
}
