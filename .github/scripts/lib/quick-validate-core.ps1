#Requires -Version 7.0
<#
.SYNOPSIS
    Library for quick-validate logic. Dot-source this file and call Invoke-QuickValidate.
#>

function Test-QVLegacyReference {
    param(
        [Parameter(Mandatory)]
        [string]$RootPath,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Pattern,
        [string[]]$ExtraExcludeNames = @()
    )

    $githubPath = Join-Path $RootPath '.github'
    if (-not (Test-Path $githubPath)) {
        return [PSCustomObject]@{ Name = $Name; Passed = $true; Detail = '' }
    }

    $excludePattern = 'copilot-instructions|architecture-rules'
    if ($ExtraExcludeNames.Count -gt 0) {
        $excludePattern += '|' + (($ExtraExcludeNames | ForEach-Object { [regex]::Escape($_) }) -join '|')
    }

    $mdFiles = Get-ChildItem -Path $githubPath -Recurse -Filter '*.md' |
        Where-Object { $_.Name -notmatch $excludePattern }

    $hits = $mdFiles | Select-String -Pattern $Pattern -SimpleMatch
    if ($hits.Count -eq 0) {
        return [PSCustomObject]@{ Name = $Name; Passed = $true; Detail = '' }
    }

    $fileList = ($hits | ForEach-Object { $_.RelativePath($githubPath) ?? $_.Path }) -join ', '
    return [PSCustomObject]@{ Name = $Name; Passed = $false; Detail = "$($hits.Count) reference(s) found: $fileList" }
}

function Test-QVSkillFrontmatter {
    param(
        [Parameter(Mandatory)]
        [string]$RootPath,
        [Parameter(Mandatory)]
        [string]$CheckName,
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    $skillsPath = Join-Path -Path $RootPath -ChildPath '.github' -AdditionalChildPath 'skills'
    if (-not (Test-Path $skillsPath)) {
        return [PSCustomObject]@{ Name = $CheckName; Passed = $true; Detail = '' }
    }

    $skillFiles = Get-ChildItem -Path $skillsPath -Directory |
        ForEach-Object { Join-Path -Path $_.FullName -ChildPath 'SKILL.md' } |
        Where-Object { Test-Path $_ }

    if ($skillFiles.Count -eq 0) {
        return [PSCustomObject]@{ Name = $CheckName; Passed = $true; Detail = '' }
    }

    $failing = @()
    foreach ($file in $skillFiles) {
        $match = Select-String -Path $file -Pattern $Pattern
        if (-not $match) {
            $failing += [System.IO.Path]::GetFileName(
                [System.IO.Path]::GetDirectoryName($file)
            ) + '/SKILL.md'
        }
    }

    if ($failing.Count -eq 0) {
        return [PSCustomObject]@{ Name = $CheckName; Passed = $true; Detail = '' }
    }

    return [PSCustomObject]@{
        Name   = $CheckName
        Passed = $false
        Detail = "$($failing.Count) SKILL.md file(s) missing pattern: $($failing -join ', ')"
    }
}

function Test-QVGuidanceComplexity {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    $resolvedScript = (Resolve-Path $ScriptPath).Path
    $output = & $resolvedScript
    $json = $output | ConvertFrom-Json

    if ($json.agents_over_ceiling.Count -eq 0) {
        return [PSCustomObject]@{ Name = 'GuidanceComplexity'; Passed = $true; Detail = '' }
    }

    $names = ($json.agents_over_ceiling | ForEach-Object { $_.name }) -join ', '
    return [PSCustomObject]@{
        Name   = 'GuidanceComplexity'
        Passed = $false
        Detail = "$($json.agents_over_ceiling.Count) agent(s) over ceiling: $names"
    }
}

function Test-QVPSScriptAnalyzer {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptsPath,
        [Parameter(Mandatory)]
        [string]$SettingsPath
    )

    $installed = Get-Module -Name PSScriptAnalyzer -ListAvailable
    if (-not $installed) {
        return [PSCustomObject]@{ Name = 'PSScriptAnalyzer'; Passed = 'SKIP'; Detail = 'PSScriptAnalyzer not installed — skipping' }
    }

    $resolvedScripts = (Resolve-Path $ScriptsPath).Path
    $analyzerParams = @{ Path = $resolvedScripts; Recurse = $true }
    if (Test-Path $SettingsPath) {
        $analyzerParams['Settings'] = (Resolve-Path $SettingsPath).Path
    }

    $issues = @(Invoke-ScriptAnalyzer @analyzerParams)
    if ($issues.Count -eq 0) {
        return [PSCustomObject]@{ Name = 'PSScriptAnalyzer'; Passed = $true; Detail = '' }
    }

    return [PSCustomObject]@{
        Name   = 'PSScriptAnalyzer'
        Passed = $false
        Detail = "$($issues.Count) issue(s) found"
    }
}

function Invoke-QuickValidate {
    [CmdletBinding()]
    param(
        [string]$RootPath,
        [string]$GuidanceComplexityScriptPath,
        [string]$PSScriptAnalyzerSettingsPath,
        [string]$ScriptsPath
    )

    if (-not $RootPath) {
        $RootPath = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    }
    if (-not $GuidanceComplexityScriptPath) {
        $GuidanceComplexityScriptPath = Join-Path -Path $RootPath -ChildPath '.github' -AdditionalChildPath 'scripts', 'measure-guidance-complexity.ps1'
    }
    if (-not $PSScriptAnalyzerSettingsPath) {
        $PSScriptAnalyzerSettingsPath = Join-Path -Path $RootPath -ChildPath '.github' -AdditionalChildPath 'config', 'PSScriptAnalyzerSettings.psd1'
    }
    if (-not $ScriptsPath) {
        $ScriptsPath = Join-Path -Path $RootPath -ChildPath '.github' -AdditionalChildPath 'scripts'
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 1. Plan-Architect
    $results.Add((Test-QVLegacyReference -RootPath $RootPath -Name 'Plan-Architect' -Pattern 'Plan-Architect'))
    # 2. Janitor
    $results.Add((Test-QVLegacyReference -RootPath $RootPath -Name 'Janitor' -Pattern 'Janitor'))
    # 3. Issue-Designer
    $results.Add((Test-QVLegacyReference -RootPath $RootPath -Name 'Issue-Designer' -Pattern 'Issue-Designer'))
    # 4. workflow-template (also exclude setup.prompt)
    $results.Add((Test-QVLegacyReference -RootPath $RootPath -Name 'workflow-template' -Pattern 'workflow-template' -ExtraExcludeNames @('setup.prompt')))
    # 5. SKILL-UseWhen
    $results.Add((Test-QVSkillFrontmatter -RootPath $RootPath -CheckName 'SKILL-UseWhen' -Pattern '^description:.*Use (when|before)'))
    # 6. SKILL-DoNotUseFor
    $results.Add((Test-QVSkillFrontmatter -RootPath $RootPath -CheckName 'SKILL-DoNotUseFor' -Pattern '^description:.*DO NOT USE FOR:'))
    # 7. SKILL-Gotchas
    $results.Add((Test-QVSkillFrontmatter -RootPath $RootPath -CheckName 'SKILL-Gotchas' -Pattern '^## Gotchas'))
    # 8. GuidanceComplexity
    $results.Add((Test-QVGuidanceComplexity -ScriptPath $GuidanceComplexityScriptPath))
    # 9. PSScriptAnalyzer
    $results.Add((Test-QVPSScriptAnalyzer -ScriptsPath $ScriptsPath -SettingsPath $PSScriptAnalyzerSettingsPath))

    $passCount = @($results | Where-Object { $_.Passed -eq $true }).Count
    $failCount = @($results | Where-Object { $_.Passed -eq $false }).Count
    $totalCount = $results.Count

    foreach ($r in $results) {
        if ($r.Passed -eq $true) {
            Write-Host "[PASS] $($r.Name)"
        }
        elseif ($r.Passed -eq 'SKIP') {
            Write-Host "[SKIP] $($r.Name) — $($r.Detail)"
        }
        else {
            Write-Host "[FAIL] $($r.Name) — $($r.Detail)"
        }
    }

    Write-Host "Quick-validate: $passCount/$totalCount checks passed"

    $exitCode = if ($failCount -gt 0) { 1 } else { 0 }

    return [PSCustomObject]@{
        Results    = $results.ToArray()
        PassCount  = [int]$passCount
        FailCount  = [int]$failCount
        TotalCount = [int]$totalCount
        ExitCode   = $exitCode
    }
}
