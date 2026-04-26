<p align="center">
  <img src="whiteMonster.jpeg" alt="WhiteMonster" width="640" />
</p>

# WhiteMonster

WhiteMonster is a lightweight mouse jiggler for Windows. It prevents system idle timeouts, screensaver activation, and presence-app "away" status (Microsoft Teams, Slack, etc.) by performing subtle one-pixel cursor movements and a periodic keep-alive keystroke — useful for keeping yourself marked as available while you're heads-down on something off-screen.

## Features

- **Subtle 1-pixel jiggle** that returns the cursor to its origin so you don't notice it. Direction alternates each call to avoid drifting toward a screen edge on multi-monitor setups.
- **Idle-aware**: only jiggles when the cursor has been still during the idle window.
- **Active-user-aware keep-alive**: the keep-alive keystroke is skipped automatically when the cursor has moved during the interval, so it stays out of the way while you're actively typing.
- **F15 keep-alive by default**: F15 has no LED, no shell binding, and no Excel side-effect — strictly safer than ScrollLock. ScrollLock remains available via `-KeepAliveKey SCROLLLOCK` for environments that strip F-keys.
- **Responsive `q`-to-quit** with a graceful shutdown summary (runtime, jiggles, keep-alives sent, keep-alives skipped).
- **Resilient**: transient input-API failures are caught and logged rather than crashing the loop.
- **Console-host detection**: warns up front if running in a host where `q`-to-quit won't work (ISE, VSCode integrated terminal).

## Usage

### Run the PowerShell script (recommended)

```powershell
# Defaults: 60s idle threshold, 1px jiggle, 100ms tick, F15 keep-alive every 1 minute
.\MouseJiggler.ps1

# Custom: 30s idle threshold, F15 keep-alive every 4 minutes, verbose logging
.\MouseJiggler.ps1 -IdleThresholdSeconds 30 -ActivityIntervalMinutes 4 -Verbose

# Fall back to ScrollLock if F15 is filtered in your environment
.\MouseJiggler.ps1 -KeepAliveKey SCROLLLOCK
```

Press **`q`** in the same console window to quit.

If you get an execution-policy error, either unblock the file or run for the current process only:

```powershell
Unblock-File .\MouseJiggler.ps1
# or
powershell -ExecutionPolicy Bypass -File .\MouseJiggler.ps1
```

### Run the prebuilt executable

`WhiteMonster.exe` is a convenience build for users who can't run `.ps1` files. Fresh builds are produced by GitHub Actions on every tagged release and attached to the [Releases page](https://github.com/ctclostio/whiteMonster/releases). Because it's an unsigned binary that synthesizes input, Windows SmartScreen and some antivirus products may flag it — see the note below. Running the script directly is the most transparent option.

## Parameters

| Parameter | Default | Range | Meaning |
|---|---|---|---|
| `-IdleThresholdSeconds` | `60` | 5–3600 | Cursor stillness required before jiggling |
| `-JigglePixels` | `1` | 1–10 | Distance of the subtle move (pixels) |
| `-CheckIntervalMs` | `100` | 50–5000 | Loop tick / quit-key polling interval |
| `-ActivityIntervalMinutes` | `1` | 1–60 | How often the keep-alive fires when idle |
| `-KeepAliveKey` | `F15` | `F15`, `SCROLLLOCK` | Key used for the keep-alive synthesis |

Run `Get-Help .\MouseJiggler.ps1 -Detailed` for the full help block.

## Building the executable yourself

If you'd rather not trust a downloaded binary, you can produce one locally with [`ps2exe`](https://github.com/MScholtes/PS2EXE):

```powershell
Install-Module ps2exe -Scope CurrentUser
Invoke-PS2EXE .\MouseJiggler.ps1 .\WhiteMonster.exe
```

The release workflow at [`.github/workflows/release.yml`](.github/workflows/release.yml) does exactly this on a clean Windows runner — you can read it to verify the build is reproducible.

## Antivirus note

Mouse jigglers and any tool that calls `SendKeys` / sets `Cursor.Position` look a lot like input-injecting malware to AV heuristics. False positives on the prebuilt `.exe` are common. The script source is short — read it before running, and prefer the `.ps1` over the `.exe` if your environment is locked down.

## Requirements

- Windows
- PowerShell 5.1 or PowerShell 7+
- An interactive console session (the script reads keypresses via `[Console]::KeyAvailable`)

## License

MIT — see [LICENSE](LICENSE).
