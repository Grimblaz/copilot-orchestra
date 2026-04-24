#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

<#
.SYNOPSIS
    Contract tests for the scope-classification skip on full-upstream-complete resume paths.

.DESCRIPTION
    Locks the issue #413 fix: when smart resume detects all three full-upstream markers
    (experience-owner-complete, design-phase-complete, plan-issue), the Scope Classification
    Gate must be skipped and Code-Conductor must proceed directly to the D9 Checkpoint.

    The files that must describe this contract:
      - agents/Code-Conductor.agent.md
      - Documents/Design/hub-mode-ux.md

    These tests lock the landed issue #413 wording; update only when the contract semantics
    intentionally change.
#>

Describe 'scope classification resume skip contract' {

    BeforeAll {
        $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
        $script:ConductorPath = Join-Path $script:RepoRoot 'agents\Code-Conductor.agent.md'
        $script:HubModeUxPath = Join-Path $script:RepoRoot 'Documents\Design\hub-mode-ux.md'

        $script:ConductorContent = (Get-Content -Path $script:ConductorPath -Raw -ErrorAction Stop) -replace "`r`n?", "`n"
        $script:HubModeUxContent = (Get-Content -Path $script:HubModeUxPath -Raw -ErrorAction Stop) -replace "`r`n?", "`n"

        # Pattern: skip condition names all three full-upstream markers
        $script:SkipConditionPattern = '(?is)Skip scope classification when.{0,200}experience-owner-complete.{0,100}design-phase-complete.{0,100}plan-issue'

        # Pattern: skip condition explains that tier was established in prior session
        $script:PriorSessionTierPattern = '(?is)Skip scope classification when.{0,500}(tier|plan).{0,60}(established|determined).{0,60}prior session'

        # Pattern: skip condition directs Code-Conductor to the D9 Checkpoint
        $script:ProceedToD9Pattern = '(?is)Skip scope classification when.{0,500}(D9 Checkpoint|step 4.{0,30}D9)'

        # Pattern: multi-issue bundling applies the skip per-issue before classifying
        $script:BundleSkipPattern = '(?is)Per-issue scope classification.{0,100}(skip condition|Skip.{0,60}condition).{0,400}(experience-owner-complete|exempt from classification)'

        # Pattern: skip applies only when ALL bundled issues satisfy the full-completion condition
        $script:BundleAllConditionPattern = '(?is)(skip applies only when ALL bundled issues|ALL bundled issues satisfy the full-completion condition|all bundled issues.{0,60}full-completion condition)'
    }

    It 'requires Code-Conductor Scope Classification Gate to include a skip condition naming all three full-upstream markers' {
        $script:ConductorContent | Should -Match $script:SkipConditionPattern -Because 'issue #413 requires the Scope Classification Gate to skip when smart resume already has experience-owner-complete, design-phase-complete, and plan-issue markers'
    }

    It 'requires the skip condition to state that the tier was established in a prior session' {
        $script:ConductorContent | Should -Match $script:PriorSessionTierPattern -Because 'issue #413 requires the skip reason to explain that the tier was determined in the prior session, making classification redundant'
    }

    It 'requires the skip condition to direct Code-Conductor to proceed to the D9 Checkpoint' {
        $script:ConductorContent | Should -Match $script:ProceedToD9Pattern -Because 'issue #413 requires the skip path to proceed directly to the D9 Checkpoint instead of asking for scope classification'
    }

    It 'requires Multi-Issue Bundling to apply the skip condition per-issue before classification' {
        $script:ConductorContent | Should -Match $script:BundleSkipPattern -Because 'issue #413 requires the Multi-Issue Bundling section to check the skip condition per-issue before applying the Scope Classification Gate rubric'
    }

    It 'requires the skip condition to apply only when ALL bundled issues satisfy full-completion' {
        $script:ConductorContent | Should -Match $script:BundleAllConditionPattern -Because 'issue #413 requires the skip to be conservative for bundles: any issue missing a required marker still requires classification'
    }

    It 'requires the hub-mode design doc to document the D30 skip-on-resume decision' {
        $script:HubModeUxContent | Should -Match '(?is)D30.{0,60}Skip Scope Classification.{0,120}(Full-Upstream|full.upstream|full upstream)' -Because 'issue #413 requires the design doc to capture decision D30 for the scope-classification skip on full-upstream-complete resume paths'
    }

    It 'requires the hub-mode design doc D30 to name all three required markers' {
        $script:HubModeUxContent | Should -Match '(?is)D30.{0,600}experience-owner-complete.{0,200}design-phase-complete.{0,200}plan-issue' -Because 'issue #413 D30 must name all three full-upstream markers that trigger the skip condition'
    }
}
