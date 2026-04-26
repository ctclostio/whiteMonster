<p align="center">
  <img src="whiteMonster.jpeg" alt="WhiteMonster" width="640" />
</p>

# WhiteMonster

WhiteMonster is a lightweight mouse jiggler for Windows. It prevents system idle timeouts, screensaver activation, and sleep mode by performing subtle one-pixel cursor movements and a periodic keep-alive keystroke — useful for keeping Microsoft Teams (or any presence-aware app) marked as available while you're heads-down on something off-screen.

## Features

- **Subtle 1-pixel jiggle** that returns the cursor to its origin so you don't notice it.
- **Idle-aware**: only jiggles when the cursor has been still during the idle window, so it stays out of your way while you're actually using the machine.
- **Keep-alive keystroke** every minute via a double-tap of ScrollLock — the toggle returns to its original state so your ScrollLock LED is never left flipped.
- **Responsive `q`-to-quit** — the script polls for input every 100 ms instead of blocking on a long sleep.
- **Resilient**: transient input-API failures are caught and logged rather than crashing the loop.

## Usage

### Run the PowerShell script (recommended)

```powershell
# From an interactive PowerShell prompt
.\MouseJiggler.ps1
```

Press **`q`** in the same console window to quit.

If you get an execution-policy error, either unblock the file or run for the current process only:

```powershell
Unblock-File .\MouseJiggler.ps1
# or
powershell -ExecutionPolicy Bypass -File .\MouseJiggler.ps1
```

### Run the prebuilt executable

`WhiteMonster.exe` is a convenience build for users who can't run `.ps1` files. Because it's an unsigned binary that synthesizes input, Windows SmartScreen and some antivirus products may flag it — see the note below. Running the script directly is the most transparent option.

## Configuration

Edit the variables at the top of `MouseJiggler.ps1`:

| Variable | Default | Meaning |
|---|---|---|
| `$idleThresholdSeconds` | `60` | Cursor stillness required before jiggling |
| `$jigglePixels` | `1` | Distance of the subtle move (pixels) |
| `$checkIntervalMs` | `100` | Loop tick / quit-key polling interval |
| `$activityIntervalMinutes` | `1` | How often the keep-alive keystroke fires |

## Building the executable yourself

If you'd rather not trust a committed binary, you can produce one locally with [`ps2exe`](https://github.com/MScholtes/PS2EXE):

```powershell
Install-Module ps2exe -Scope CurrentUser
Invoke-PS2EXE .\MouseJiggler.ps1 .\WhiteMonster.exe
```

## Antivirus note

Mouse jigglers and any tool that calls `SendKeys` / sets `Cursor.Position` look a lot like input-injecting malware to AV heuristics. False positives on the prebuilt `.exe` are common. The script source is short — read it before running, and prefer the `.ps1` over the `.exe` if your environment is locked down.

## Requirements

- Windows
- PowerShell 5.1 or PowerShell 7+
- An interactive console session (the script reads keypresses via `[Console]::KeyAvailable`)

## License

MIT — see [LICENSE](LICENSE).
