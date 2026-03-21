#Requires -Version 7.0
<#
.SYNOPSIS
    Shared helpers for parsing pipeline-metrics YAML blocks.
    Dot-sourced by aggregate-review-scores.ps1 and backfill-calibration.ps1.
#>

# ---------------------------------------------------------------------------
# Helper: extract a flat YAML field value from a text block
# ---------------------------------------------------------------------------
function Get-YamlField {
    param([string]$Block, [string]$FieldName)
    $m = [regex]::Match($Block, "(?m)^${FieldName}:\s*(.+)$")
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return $null
}

# ---------------------------------------------------------------------------
# Helper: parse the findings: array from a v2 metrics block
# ---------------------------------------------------------------------------
function Get-FindingsArray {
    param([string]$Block)

    $findings = [System.Collections.Generic.List[hashtable]]::new()

    # Locate start of findings: section
    if (-not [regex]::IsMatch($Block, '(?m)^findings:\s*$')) { Write-Output -NoEnumerate $findings; return }

    $blockLines = $Block -split "`n"
    $inFindings = $false
    $current = $null

    foreach ($line in $blockLines) {
        if (-not $inFindings) {
            if ($line -match '^findings:\s*$') {
                $inFindings = $true
            }
            continue
        }

        # New finding entry
        if ($line -match '^\s+-\s+([a-z_]+):\s*(.*)$') {
            if ($null -ne $current) { $findings.Add($current) }
            $current = @{}
            $current[$Matches[1].Trim()] = $Matches[2].Trim()
            continue
        }

        # Stop if we hit a top-level key
        if ($line -match '^[a-z_]+:\s') {
            if ($null -ne $current) { $findings.Add($current) }
            $current = $null
            break
        }

        # Field within current entry
        if ($null -ne $current -and $line -match '^\s{2,}([a-z_]+):\s*(.*)$') {
            $current[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }

    if ($null -ne $current) { $findings.Add($current) }
    Write-Output -NoEnumerate $findings
}
