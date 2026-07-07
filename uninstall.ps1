# Removes the Chimes hooks from Claude Code and Cursor settings. Only entries
# pointing at play-sound.ps1 / cursor-stop.ps1 are removed; everything else is
# left untouched. A timestamped backup is written before each file is modified.
# Usage: uninstall.ps1
$ErrorActionPreference = "Stop"

function Save-JsonFile([string]$path, $obj) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $path "$path.chimes-backup-$stamp"
    $json = ConvertTo-Json $obj -Depth 32
    [IO.File]::WriteAllText($path, $json, (New-Object Text.UTF8Encoding $false))
}

# --- Claude Code -------------------------------------------------------------

$settingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $changed = $false
    if ($settings.PSObject.Properties['hooks']) {
        foreach ($prop in @($settings.hooks.PSObject.Properties)) {
            $kept = @()
            foreach ($group in @($prop.Value)) {
                if ($group.PSObject.Properties['hooks']) {
                    $inner = @($group.hooks | Where-Object { $_.command -notmatch 'play-sound\.ps1' })
                    if ($inner.Count -ne @($group.hooks).Count) { $changed = $true }
                    if ($inner.Count -eq 0) { continue }
                    $group.hooks = $inner
                }
                $kept += $group
            }
            if ($kept.Count -eq 0) { $settings.hooks.PSObject.Properties.Remove($prop.Name) }
            else { $prop.Value = $kept }
        }
    }
    if ($changed) {
        Save-JsonFile $settingsPath $settings
        Write-Output "Claude Code: Chimes hooks removed from $settingsPath"
    } else {
        Write-Output "Claude Code: no Chimes hooks found, nothing to do."
    }
} else {
    Write-Output "Claude Code: no settings file found, nothing to do."
}

# --- Cursor ------------------------------------------------------------------

$hooksPath = Join-Path $env:USERPROFILE ".cursor\hooks.json"
if (Test-Path $hooksPath) {
    $cfg = Get-Content $hooksPath -Raw | ConvertFrom-Json
    $changed = $false
    if ($cfg.PSObject.Properties['hooks'] -and $cfg.hooks.PSObject.Properties['stop']) {
        $kept = @($cfg.hooks.stop | Where-Object { $_.command -notmatch 'cursor-stop\.ps1' })
        if ($kept.Count -ne @($cfg.hooks.stop).Count) {
            $changed = $true
            if ($kept.Count -eq 0) { $cfg.hooks.PSObject.Properties.Remove('stop') }
            else { $cfg.hooks.stop = $kept }
        }
    }
    if ($changed) {
        Save-JsonFile $hooksPath $cfg
        Write-Output "Cursor: Chimes hook removed from $hooksPath"
    } else {
        Write-Output "Cursor: no Chimes hooks found, nothing to do."
    }
} else {
    Write-Output "Cursor: no hooks file found, nothing to do."
}
