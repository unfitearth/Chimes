# Wires the chime sounds into Claude Code (and Cursor, if installed) by adding
# hooks to your user-level settings files. Safe to re-run: existing Chimes hooks
# are replaced in place, everything else in the files is left untouched, and a
# timestamped backup is written next to each file before it is modified.
# Usage: install.ps1 [-SkipCursor]
param([switch]$SkipCursor)

$ErrorActionPreference = "Stop"

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dirFwd = $dir -replace '\\', '/'

function Read-JsonFile([string]$path, [string]$emptyFallback) {
    if (-not (Test-Path $path)) { return ConvertFrom-Json $emptyFallback }
    $raw = Get-Content $path -Raw
    if (-not $raw -or -not $raw.Trim()) { return ConvertFrom-Json $emptyFallback }
    try { return ConvertFrom-Json $raw }
    catch { throw "Could not parse $path as JSON - fix or remove it, then re-run the installer." }
}

function Save-JsonFile([string]$path, $obj) {
    if (Test-Path $path) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $path "$path.chimes-backup-$stamp"
    }
    $json = ConvertTo-Json $obj -Depth 32
    [IO.File]::WriteAllText($path, $json, (New-Object Text.UTF8Encoding $false))
}

# --- Claude Code -------------------------------------------------------------

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$settingsPath = Join-Path $claudeDir "settings.json"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Force $claudeDir | Out-Null }

$settings = Read-JsonFile $settingsPath '{}'
if (-not $settings.PSObject.Properties['hooks']) {
    $settings | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{})
}

$events = @(
    @{ Event = "Stop";         Arg = "complete" },  # agent finished its task
    @{ Event = "StopFailure";  Arg = "tokens" },    # turn errored / usage exhausted
    @{ Event = "Notification"; Arg = "notify" }     # question, or usage limit (routed by play-sound.ps1)
)

foreach ($e in $events) {
    $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$dirFwd/play-sound.ps1`" $($e.Arg)"
    $entry = [pscustomobject]@{
        hooks = @([pscustomobject]@{ type = "command"; command = $cmd; async = $true })
    }

    # Keep any unrelated hooks on this event; strip previous Chimes entries so
    # re-running (e.g. after moving the folder) never duplicates them.
    $kept = @()
    if ($settings.hooks.PSObject.Properties[$e.Event]) {
        foreach ($group in @($settings.hooks.($e.Event))) {
            if (-not $group.PSObject.Properties['hooks']) { $kept += $group; continue }
            $inner = @($group.hooks | Where-Object { $_.command -notmatch 'play-sound\.ps1' })
            if ($inner.Count -gt 0) { $group.hooks = $inner; $kept += $group }
        }
        $settings.hooks.PSObject.Properties.Remove($e.Event)
    }
    $settings.hooks | Add-Member -NotePropertyName $e.Event -NotePropertyValue (@($kept) + @($entry))
}

Save-JsonFile $settingsPath $settings
Write-Output "Claude Code: hooks added to $settingsPath"

# --- Cursor (optional) -------------------------------------------------------

$cursorDir = Join-Path $env:USERPROFILE ".cursor"
if ($SkipCursor) {
    Write-Output "Cursor: skipped (-SkipCursor)."
} elseif (-not (Test-Path $cursorDir)) {
    Write-Output "Cursor: not detected, skipped."
} else {
    $hooksPath = Join-Path $cursorDir "hooks.json"
    $cfg = Read-JsonFile $hooksPath '{"version":1,"hooks":{}}'
    if (-not $cfg.PSObject.Properties['version']) { $cfg | Add-Member -NotePropertyName version -NotePropertyValue 1 }
    if (-not $cfg.PSObject.Properties['hooks'])   { $cfg | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) }

    $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$dirFwd/cursor-stop.ps1`""
    $stop = @()
    if ($cfg.hooks.PSObject.Properties['stop']) {
        $stop = @($cfg.hooks.stop | Where-Object { $_.command -notmatch 'cursor-stop\.ps1' })
        $cfg.hooks.PSObject.Properties.Remove('stop')
    }
    $cfg.hooks | Add-Member -NotePropertyName stop -NotePropertyValue (@($stop) + @([pscustomobject]@{ command = $cmd }))

    Save-JsonFile $hooksPath $cfg
    Write-Output "Cursor: stop hook added to $hooksPath"
}

Write-Output ""
Write-Output "Done. Restart any open Claude Code sessions (hooks are read at startup)."
Write-Output "Test it:  powershell -File `"$dir\play-sound.ps1`" complete"
