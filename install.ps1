#!/usr/bin/env pwsh
# Idempotent installer for ClaudeSkills.
# Re-run after `git pull` to pick up new skills and propagate config changes.

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "PowerShell 7+ required (settings.json merge uses ConvertFrom-Json -AsHashtable)."
    exit 1
}

$repoRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$skillsDir = Join-Path $claudeDir "skills"

if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }
if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null }

# 1. Symlink each skill folder into ~/.claude/skills/
$skillsSourceDir = Join-Path $repoRoot "skills"
if (Test-Path $skillsSourceDir) {
    Get-ChildItem $skillsSourceDir -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
        ForEach-Object {
            $target = Join-Path $skillsDir $_.Name
            $source = $_.FullName

            if (Test-Path $target) {
                $existing = Get-Item $target -Force
                $existingTarget = if ($existing.LinkType) { @($existing.Target)[0] } else { $null }
                $normalized = if ($existingTarget) { $existingTarget.TrimEnd('\').ToLower() } else { '' }
                if ($normalized -eq $source.TrimEnd('\').ToLower()) { return }
                Remove-Item $target -Force -Recurse
            }

            try   { New-Item -ItemType SymbolicLink -Path $target -Target $source -ErrorAction Stop | Out-Null }
            catch { New-Item -ItemType Junction     -Path $target -Target $source | Out-Null }
            Write-Host "linked skill: $($_.Name)"
        }
}

# 2. Merge home/CLAUDE.md into ~/.claude/CLAUDE.md (marker-bracketed)
$sharedClaude = Join-Path $repoRoot "home\CLAUDE.md"
$localClaude  = Join-Path $claudeDir "CLAUDE.md"
$beginMarker  = "<!-- BEGIN ClaudeSkills shared instructions -->"
$endMarker    = "<!-- END ClaudeSkills shared instructions -->"

if (Test-Path $sharedClaude) {
    $shared = (Get-Content $sharedClaude -Raw).TrimEnd()
    $block  = "$beginMarker`n$shared`n$endMarker"

    if (Test-Path $localClaude) {
        $local = Get-Content $localClaude -Raw
        if ($local -match [regex]::Escape($beginMarker)) {
            $pattern = "(?s)" + [regex]::Escape($beginMarker) + ".*?" + [regex]::Escape($endMarker)
            $updated = [regex]::Replace($local, $pattern, { param($m) $block })
        } else {
            $updated = $local.TrimEnd() + "`n`n" + $block + "`n"
        }
        Set-Content -Path $localClaude -Value $updated -NoNewline
    } else {
        Set-Content -Path $localClaude -Value ($block + "`n") -NoNewline
    }
    Write-Host "merged: ~/.claude/CLAUDE.md"
}

# 3. Deep-merge home/settings.json into ~/.claude/settings.json
#    Local wins on scalar conflict. Arrays union + dedupe. Nothing local is ever deleted.
$sharedSettings = Join-Path $repoRoot "home\settings.json"
$localSettings  = Join-Path $claudeDir "settings.json"

if (Test-Path $sharedSettings) {
    function Merge-Json {
        param($local, $shared)
        if ($null -eq $local)  { return $shared }
        if ($null -eq $shared) { return $local }
        if ($shared -is [hashtable] -and $local -is [hashtable]) {
            foreach ($key in $shared.Keys) {
                if ($local.ContainsKey($key)) {
                    $local[$key] = Merge-Json $local[$key] $shared[$key]
                } else {
                    $local[$key] = $shared[$key]
                }
            }
            return $local
        }
        if (($shared -is [System.Collections.IList]) -and ($local -is [System.Collections.IList])) {
            return @(($local + $shared) | Select-Object -Unique)
        }
        return $local
    }

    $sharedJson = Get-Content $sharedSettings -Raw | ConvertFrom-Json -AsHashtable
    if (Test-Path $localSettings) {
        $localJson = Get-Content $localSettings -Raw | ConvertFrom-Json -AsHashtable
    } else {
        $localJson = @{}
    }
    $merged = Merge-Json $localJson $sharedJson
    $merged | ConvertTo-Json -Depth 32 | Set-Content -Path $localSettings
    Write-Host "merged: ~/.claude/settings.json"
}

Write-Host "done. restart Claude Code to pick up new skills."
