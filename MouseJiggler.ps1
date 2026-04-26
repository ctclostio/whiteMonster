<#
.SYNOPSIS
    Lightweight mouse jiggler that prevents idle timeouts and keeps presence-aware
    apps (Microsoft Teams, Slack, etc.) marked as available.

.DESCRIPTION
    WhiteMonster performs subtle one-pixel cursor jiggles when the cursor has been
    still for a configurable window, and periodically synthesizes a no-op keystroke
    (F15 by default) to reset the OS idle counter that presence apps read.

    The keep-alive is skipped automatically when the cursor has moved during the
    interval, so it stays out of the way while you're actively using the machine.

    Press 'q' in the console to quit (responsive within -CheckIntervalMs).

.PARAMETER IdleThresholdSeconds
    Cursor stillness required before a jiggle fires. Default 60.

.PARAMETER JigglePixels
    Distance of the subtle jiggle in pixels. Default 1.

.PARAMETER CheckIntervalMs
    Loop tick / quit-key polling interval in ms. Default 100.

.PARAMETER ActivityIntervalMinutes
    How often the keep-alive keystroke fires when the user is idle. Default 1.

.PARAMETER KeepAliveKey
    Key used for the keep-alive synthesis. F15 (default) has no LED, no shell
    binding, and no Excel side-effect. SCROLLLOCK is provided for environments
    that strip F-keys.

.EXAMPLE
    .\MouseJiggler.ps1

.EXAMPLE
    .\MouseJiggler.ps1 -IdleThresholdSeconds 30 -ActivityIntervalMinutes 4 -Verbose
#>
[CmdletBinding()]
param(
    [ValidateRange(5, 3600)]            [int]    $IdleThresholdSeconds    = 60,
    [ValidateRange(1, 10)]              [int]    $JigglePixels            = 1,
    [ValidateRange(50, 5000)]           [int]    $CheckIntervalMs         = 100,
    [ValidateRange(1, 60)]              [int]    $ActivityIntervalMinutes = 1,
    [ValidateSet('F15', 'SCROLLLOCK')]  [string] $KeepAliveKey            = 'F15'
)

Set-StrictMode -Version Latest

Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
Add-Type -AssemblyName System.Drawing -ErrorAction Stop

# Oscillating sign so successive jiggles stay centered around the origin
# instead of drifting toward a screen edge on multi-monitor setups.
$script:JiggleSign = 1

function Get-CursorPositionSafe {
    try {
        return [System.Windows.Forms.Cursor]::Position
    } catch {
        Write-Warning "Failed to read cursor position: $_"
        return $null
    }
}

function Move-CursorSubtly {
    param([int]$Pixels)
    try {
        $current = [System.Windows.Forms.Cursor]::Position
        $delta   = $Pixels * $script:JiggleSign
        $target  = [System.Drawing.Point]::new($current.X + $delta, $current.Y + $delta)
        [System.Windows.Forms.Cursor]::Position = $target
        Start-Sleep -Milliseconds 50
        [System.Windows.Forms.Cursor]::Position = $current
        $script:JiggleSign = -$script:JiggleSign
    } catch {
        Write-Warning "Failed to move cursor: $_"
    }
}

function Invoke-ActivitySimulation {
    param([string]$Key)
    # F15 is stateless — single tap is fine.
    # ScrollLock is stateful — double-tap so the toggle returns to its original state.
    $sequence = if ($Key -eq 'SCROLLLOCK') { "{$Key}{$Key}" } else { "{$Key}" }
    try {
        [System.Windows.Forms.SendKeys]::SendWait($sequence)
        Write-Verbose "Sent $sequence at $(Get-Date -Format 'HH:mm:ss')"
    } catch {
        Write-Warning "Failed to simulate activity: $_"
    }
}

# Console-host check — Quit-on-'q' relies on a real console
$isRealConsole = $Host.Name -eq 'ConsoleHost'
if (-not $isRealConsole) {
    Write-Warning "Quit-on-'q' requires a real console. Use Ctrl+C in $($Host.Name)."
}

# Hoist allocations out of the loop
$activityInterval = [TimeSpan]::FromMinutes($ActivityIntervalMinutes)
$idleThreshold    = [TimeSpan]::FromSeconds($IdleThresholdSeconds)

# State
$startTime                    = Get-Date
$lastIdleCheck                = $startTime
$lastActivityTime             = $startTime - $activityInterval  # fire keep-alive on first qualifying tick
$idleAnchorPos                = Get-CursorPositionSafe
$prevTickPos                  = $idleAnchorPos
$userActiveSinceLastIdleCheck = $false
$userActiveSinceLastKeepAlive = $false

# Stats
$jiggleCount   = 0
$activityCount = 0
$skippedCount  = 0

Write-Host "WhiteMonster started. Keep-alive key: {$KeepAliveKey}. Press 'q' to quit."

try {
    while ($true) {
        Start-Sleep -Milliseconds $CheckIntervalMs

        if ($isRealConsole -and [Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'Q') { break }
        }

        $now     = Get-Date
        $current = Get-CursorPositionSafe

        # Per-tick movement detection. Move-CursorSubtly is intra-tick and
        # restores position before the next tick starts, so its own moves
        # don't register here.
        if ($null -ne $current -and $null -ne $prevTickPos -and $current -ne $prevTickPos) {
            $userActiveSinceLastIdleCheck = $true
            $userActiveSinceLastKeepAlive = $true
        }

        # Idle / jiggle window
        if (($now - $lastIdleCheck) -ge $idleThreshold) {
            if (-not $userActiveSinceLastIdleCheck) {
                Move-CursorSubtly -Pixels $JigglePixels
                $jiggleCount++
                Write-Verbose "Jiggled at $(Get-Date -Format 'HH:mm:ss')"
            }
            $userActiveSinceLastIdleCheck = $false
            $lastIdleCheck                = $now
        }

        # Keep-alive (skipped when user is active)
        if (($now - $lastActivityTime) -ge $activityInterval) {
            if ($userActiveSinceLastKeepAlive) {
                $skippedCount++
                Write-Verbose "Skipped keep-alive — cursor activity observed"
            } else {
                Invoke-ActivitySimulation -Key $KeepAliveKey
                $activityCount++
            }
            $userActiveSinceLastKeepAlive = $false
            $lastActivityTime             = $now
        }

        $prevTickPos = Get-CursorPositionSafe
    }
} finally {
    $runtime = (Get-Date) - $startTime
    $summary = 'Stopped. Ran {0:hh\:mm\:ss}. Jiggles: {1}, keep-alives sent: {2}, skipped: {3}.'
    Write-Host ($summary -f $runtime, $jiggleCount, $activityCount, $skippedCount)
}
