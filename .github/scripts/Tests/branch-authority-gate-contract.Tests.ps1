#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }
<#
.SYNOPSIS
    Contract tests for Code-Conductor Branch Authority Gate wording.

.DESCRIPTION
    Locks the issue #205 branch-authority contract in:
      - .github/agents/Code-Conductor.agent.md

        The file must describe the same semantics for:
            - attached branch context is advisory only
            - live git is canonical before branch mutation
            - a Branch Authority Gate runs immediately before branch create, checkout, rename, and cleanup actions
            - mismatch handling is stop, reconcile, and document the verified branch before any branch-changing action continues
            - same-tip duplicates remain non-destructive

        These tests are intentionally RED for issue #205 until Code-Conductor carries the landed branch-authority wording.
#>

Describe 'branch authority gate contract' {

    BeforeAll {
        $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
        $script:CodeConductor = Join-Path $script:RepoRoot '.github\agents\Code-Conductor.agent.md'

        $script:ReadContent = {
            param([string]$Path)

            return Get-Content -Path $Path -Raw
        }

        $script:AdvisoryOnlyPattern = '(?is)(attached branch context|branch context|attached context).{0,220}(advisory only|advisory, not authoritative|hint only).{0,260}(live git|git).{0,200}(canonical|authoritative source)'
        $script:CanonicalBeforeMutationPattern = '(?is)(live git|git).{0,220}(canonical|authoritative source).{0,220}before branch mutation'
        $script:ImmediateGatePattern = '(?is)(Branch Authority Gate|branch authority check|branch-authority gate).{0,260}(immediately before|before each|immediately ahead of).{0,220}(create|creation).{0,120}(checkout).{0,120}(rename).{0,120}(cleanup)'
        $script:MismatchStopPattern = '(?is)(attached branch context|attached context|branch context).{0,240}(mismatch|differ|disagree).{0,260}(stop|stops|blocked).{0,200}(reconcile|reconciliation).{0,260}(document|record|emit).{0,220}(verified live branch|verified branch).{0,260}(before any branch-changing action continues|before any branch mutation resumes|before branch-changing action continues)'
        $script:NonDestructiveDuplicatePattern = '(?is)(same-tip duplicates|same-tip duplication|same commit duplicate branches|same-commit duplicate branches).{0,260}(non-destructive|preserve recoverability|remain blocked for rename/cleanup|blocked for rename/cleanup).{0,240}(no forced delete|no automatic cleanup|no auto-rename)?'
        $script:StartupOnlyWeakeningPattern = '(?is)(one-time|startup-only|only once at session start).{0,220}(branch authority|branch verification|branch check)'
    }

    It 'requires Code-Conductor to treat attached branch context as advisory only and live git as canonical' {
        $content = & $script:ReadContent -Path $script:CodeConductor

        $content | Should -Match $script:AdvisoryOnlyPattern -Because 'issue #205 requires attached branch context to remain advisory while live git is the canonical branch authority source'
        $content | Should -Match $script:CanonicalBeforeMutationPattern -Because 'issue #205 requires live git to be canonical before any branch mutation proceeds'
    }

    It 'requires the Branch Authority Gate to run immediately before create checkout rename and cleanup actions' {
        $content = & $script:ReadContent -Path $script:CodeConductor

        $content | Should -Match $script:ImmediateGatePattern -Because 'issue #205 requires a per-mutation Branch Authority Gate rather than a loose or implied check'
        $content | Should -Not -Match $script:StartupOnlyWeakeningPattern -Because 'issue #205 does not allow a startup-only branch verification substitute for the per-mutation gate'
    }

    It 'requires mismatch handling to stop reconcile and document the verified branch before branch-changing actions continue' {
        $content = & $script:ReadContent -Path $script:CodeConductor

        $content | Should -Match $script:MismatchStopPattern -Because 'issue #205 requires mismatch handling to fail safe and record the verified branch before any branch-changing action resumes'
    }

    It 'requires same-tip duplicates to remain non-destructive' {
        $content = & $script:ReadContent -Path $script:CodeConductor

        $content | Should -Match $script:NonDestructiveDuplicatePattern -Because 'issue #205 requires same-tip duplicate branches to preserve recoverability instead of permitting destructive rename or cleanup'
    }
}