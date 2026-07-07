# Cursor "stop" hook: reads the hook JSON from stdin and plays a sound by status.
#   completed -> work-complete.wav
#   error     -> power-down.wav
#   aborted   -> silence (you cancelled it yourself)
$raw = [Console]::In.ReadToEnd()
$status = "completed"
try { $s = [string](ConvertFrom-Json $raw).status; if ($s) { $status = $s } } catch {}

$play = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "play-sound.ps1"
switch ($status) {
    "completed" { & $play complete }
    "error"     { & $play tokens }
    default     { }
}
exit 0
