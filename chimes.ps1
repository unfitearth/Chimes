# Mute switch for the agent notification sounds.
# Usage: chimes.ps1 <on|off|toggle|status> [duration]
#   off        -> mute until you turn sounds back on
#   off 45m    -> mute for 45 minutes (also accepts 2h, 1h30m, or plain minutes)
#   on         -> unmute
#   toggle     -> flip between on and muted
#   status     -> show current state (default)
param([string]$Command = "status", [string]$Duration = "")

$flag = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".muted"

function Parse-Minutes([string]$d) {
    if ($d -match '^\d+$') { return [int]$d }
    $mins = 0
    if ($d -match '(\d+)\s*h') { $mins += 60 * [int]$Matches[1] }
    if ($d -match '(\d+)\s*m') { $mins += [int]$Matches[1] }
    return $mins
}

function Get-Status {
    if (-not (Test-Path $flag)) { return "on" }
    $txt = ""
    try { $txt = [string](Get-Content $flag -ErrorAction Stop | Select-Object -First 1) } catch {}
    if ($txt) {
        try {
            $until = [datetime]::Parse($txt, [Globalization.CultureInfo]::InvariantCulture)
            if ((Get-Date) -lt $until) { return "muted until $($until.ToString('HH:mm'))" }
            Remove-Item $flag -Force   # timed mute expired
            return "on"
        } catch {}
    }
    return "muted"
}

switch ($Command) {
    "off" {
        if ($Duration) {
            $mins = Parse-Minutes $Duration
            if ($mins -le 0) { Write-Output "Couldn't parse duration '$Duration'. Try 45m, 2h, 1h30m, or plain minutes."; exit 1 }
            $until = (Get-Date).AddMinutes($mins)
            $until.ToString("o") | Set-Content $flag -Encoding ascii
            Write-Output "Chimes muted until $($until.ToString('HH:mm'))."
        } else {
            Set-Content $flag "" -Encoding ascii
            Write-Output "Chimes muted until you run 'chimes.ps1 on'."
        }
    }
    "on" {
        if (Test-Path $flag) { Remove-Item $flag -Force }
        Write-Output "Chimes on."
    }
    "toggle" {
        if ((Get-Status) -eq "on") { & $MyInvocation.MyCommand.Path off $Duration }
        else { & $MyInvocation.MyCommand.Path on }
    }
    default { Write-Output "Chimes: $(Get-Status)" }
}
exit 0
