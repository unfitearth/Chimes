# Plays a notification wav for coding-agent events.
# Usage: play-sound.ps1 <complete|question|tokens|notify>
#   complete -> work-complete.wav   (agent finished its task)
#   question -> question.wav        (agent is waiting for you)
#   tokens   -> power-down.wav      (usage limit / error)
#   notify   -> reads Claude Code Notification-hook JSON from stdin and routes
#               usage-limit messages to "tokens", everything else to "question"
param([string]$SoundEvent = "complete")

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($SoundEvent -eq "notify") {
    $raw = [Console]::In.ReadToEnd()
    $msg = ""
    try { $msg = [string](ConvertFrom-Json $raw).message } catch {}
    if ($msg -match 'limit|quota|out of tokens|credit') { $SoundEvent = "tokens" }
    else { $SoundEvent = "question" }
}

# Mute switch (managed by chimes.ps1): .muted present = silent.
# A timestamp inside the file means "muted until then"; past timestamps unmute.
$mute = Join-Path $dir ".muted"
if (Test-Path $mute) {
    $txt = ""
    try { $txt = [string](Get-Content $mute -ErrorAction Stop | Select-Object -First 1) } catch {}
    $expired = $false
    if ($txt) {
        try { $expired = (Get-Date) -ge [datetime]::Parse($txt, [Globalization.CultureInfo]::InvariantCulture) } catch {}
    }
    if (-not $expired) { exit 0 }
    try { Remove-Item $mute -Force } catch {}
}

$files = @{ complete = "work-complete.wav"; question = "question.wav"; tokens = "power-down.wav" }
if (-not $files.ContainsKey($SoundEvent)) { exit 0 }

$wav = Join-Path $dir $files[$SoundEvent]
if ($env:AGENT_SOUND_ECHO -eq "1") { Write-Output $wav }
if (Test-Path $wav) {
    try { (New-Object System.Media.SoundPlayer $wav).PlaySync() } catch {}
}
exit 0
