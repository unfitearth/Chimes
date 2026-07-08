# Chimes

Sound notifications for coding agents on Windows. Plays a `.wav` when
**Claude Code** (or **Cursor**) finishes a task, asks you a question, or stops
because of an error / usage limit — so you can walk away while the agent works
and hear when it needs you.

No dependencies: plain PowerShell (built into Windows) and three wav files.

## Install

1. Download the ZIP (green **Code** button → *Download ZIP*) or `git clone`,
   and extract the folder somewhere **permanent** — the installer bakes the
   folder's path into your hooks, so don't move it afterwards (if you do,
   just run the installer again).
2. Double-click **`install.bat`**.
3. Restart any open Claude Code sessions (hooks are read at startup).

That's it. The installer:

- adds three hooks to `%USERPROFILE%\.claude\settings.json`
  (`Stop`, `StopFailure`, `Notification`);
- if Cursor is installed, adds a `stop` hook to `%USERPROFILE%\.cursor\hooks.json`
  (pass `-SkipCursor` to `install.ps1` to opt out);
- writes a timestamped backup next to each file before touching it, and never
  removes or reorders anything that isn't a Chimes hook. Safe to re-run.

To remove the hooks later, double-click **`uninstall.bat`**. Your wavs and
settings backups stay put.

<details>
<summary><b>Manual install</b> (if you'd rather edit the JSON yourself)</summary>

Merge this into `%USERPROFILE%\.claude\settings.json`, replacing
`C:/path/to/Chimes` with wherever you extracted the folder:

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/path/to/Chimes/play-sound.ps1\" complete", "async": true } ] }
    ],
    "StopFailure": [
      { "hooks": [ { "type": "command", "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/path/to/Chimes/play-sound.ps1\" tokens", "async": true } ] }
    ],
    "Notification": [
      { "hooks": [ { "type": "command", "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/path/to/Chimes/play-sound.ps1\" notify", "async": true } ] }
    ]
  }
}
```

For Cursor, merge this into `%USERPROFILE%\.cursor\hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "stop": [
      { "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:/path/to/Chimes/cursor-stop.ps1\"" }
    ]
  }
}
```

</details>

## The sounds

| File                | Plays when                                   |
|---------------------|----------------------------------------------|
| `work-complete.wav` | The agent finished its task                  |
| `question.wav`      | The agent has a question / is waiting on you |
| `power-down.wav`    | Usage/tokens exhausted, or the turn errored  |

The included sounds are royalty-free. Feel free to swap in any sounds you
like — just keep exactly these file names. Only `.wav` is supported (played
via `System.Media.SoundPlayer`). If you have mp3s, convert them first:
`ffmpeg -i sound.mp3 sound.wav`

## Mute switch

When the sounds get annoying, turn them off without touching any hooks —
double-click a `.bat` (they also make handy desktop/taskbar shortcuts, since
Windows opens `.ps1` files in an editor instead of running them):

| File                | Does                                                                                             |
|---------------------|--------------------------------------------------------------------------------------------------|
| `chimes-widget.bat` | Tray icon (green = on, red = muted) + a small always-on-top panel with an on/off switch and 30m / 1h / 2h mute buttons |
| `chimes-on.bat`     | Unmute                                                                                            |
| `chimes-off.bat`    | Mute until you turn it back on                                                                    |
| `chimes-timer.bat`  | Mute for a while — asks how long (default 30m); also takes it as an argument: `chimes-timer 2h`   |
| `chimes-status.bat` | Show whether sounds are on or muted                                                               |

Or from a terminal:

```powershell
powershell -File chimes.ps1 off       # mute until turned back on
powershell -File chimes.ps1 off 2h    # mute for 2 hours (also 45m, 1h30m)
powershell -File chimes.ps1 on        # unmute
powershell -File chimes.ps1 toggle    # flip
powershell -File chimes.ps1 status    # am I muted?
```

To get a plain `chimes off` command from any PowerShell terminal, add this to
your profile (`notepad $PROFILE`), with your own path:

```powershell
function chimes { & "C:\path\to\Chimes\chimes.ps1" @args }
```

The widget lives in the system tray: left-click the dot to open/hide the
panel, right-click for a quick mute menu. Closing the panel just hides it —
quit from the tray menu. To have it start with Windows, press `Win+R`, run
`shell:startup`, and drop a shortcut to `chimes-widget.bat` there.

How it works: `chimes.ps1 off` drops a `.muted` file next to the wavs;
`play-sound.ps1` checks for it before playing and exits silently if present.
A timed mute writes an expiry timestamp into the file, and sounds come back
on their own after it passes.

## Test it

```powershell
powershell -File play-sound.ps1 complete
powershell -File play-sound.ps1 question
powershell -File play-sound.ps1 tokens
```

## Notes per editor

- **Claude Code** — `Stop` → complete, `StopFailure` → power-down.
  `Notification` is routed by `play-sound.ps1`: if the message mentions a
  usage limit/quota it plays power-down, otherwise the question sound.
- **Cursor** — `cursor-stop.ps1` runs on the `stop` event: completed →
  complete, error → power-down, aborted → silence. Cursor has no "agent asked
  a question" hook; a question also ends the turn, so it plays the complete
  sound.
- **Antigravity** — no hook system. Either enable *Settings → Enable Sounds
  for Agent* (built-in, not customizable) or install the "Antigravity Task
  Sound" extension from Open VSX, which supports custom wavs.
