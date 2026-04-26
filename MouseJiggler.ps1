# Improved mouse jiggler to prevent idle sleep and keep Teams online
# - Adds subtle micro-movements instead of random repositions
# - Simulates keyboard activity to keep Teams status online
# - Press 'q' at any time to quit (responsive within $checkIntervalMs)
# - Configurable timing and movement
# - Resilient to transient input-API failures

Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
Add-Type -AssemblyName System.Drawing -ErrorAction Stop

# Configuration
$idleThresholdSeconds   = 60   # Time of cursor stillness before jiggling
$jigglePixels           = 1    # Subtle movement distance (pixels)
$checkIntervalMs        = 100  # Polling interval for key press / loop tick (ms)
$activityIntervalMinutes = 1   # Interval for simulated keyboard activity (minutes)

function Move-CursorSubtly {
    param([int]$pixels)
    try {
        $currentPos = [System.Windows.Forms.Cursor]::Position
        $newPos = New-Object System.Drawing.Point(($currentPos.X + $pixels), ($currentPos.Y + $pixels))
        [System.Windows.Forms.Cursor]::Position = $newPos
        Start-Sleep -Milliseconds 50
        [System.Windows.Forms.Cursor]::Position = $currentPos
    } catch {
        Write-Warning "Failed to move cursor: $_"
    }
}

function Invoke-ActivitySimulation {
    try {
        # Double-tap ScrollLock so the toggle ends in the same state it started.
        [System.Windows.Forms.SendKeys]::SendWait("{SCROLLLOCK}{SCROLLLOCK}")
        Write-Host "Simulated keyboard activity at $(Get-Date -Format 'HH:mm:ss')"
    } catch {
        Write-Warning "Failed to simulate activity: $_"
    }
}

function Get-CursorPositionSafe {
    try {
        return [System.Windows.Forms.Cursor]::Position
    } catch {
        Write-Warning "Failed to read cursor position: $_"
        return $null
    }
}

# Main loop
$lastPos = Get-CursorPositionSafe
$lastIdleCheck = Get-Date
$lastActivityTime = Get-Date
Write-Host "Mouse jiggler and activity simulator started. Press 'q' to quit."

while ($true) {
    Start-Sleep -Milliseconds $checkIntervalMs

    # Quit check fires every tick, not every idle window
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq 'Q') {
            Write-Host "Exiting mouse jiggler."
            break
        }
    }

    $now = Get-Date

    # Idle / jiggle window
    if (($now - $lastIdleCheck).TotalSeconds -ge $idleThresholdSeconds) {
        $currentPos = Get-CursorPositionSafe
        if ($null -ne $currentPos -and $null -ne $lastPos -and $currentPos -eq $lastPos) {
            Move-CursorSubtly -pixels $jigglePixels
            Write-Host "Jiggled cursor at $(Get-Date -Format 'HH:mm:ss')"
        }
        $lastPos = $currentPos
        $lastIdleCheck = $now
    }

    # Periodic keep-alive activity
    if (($now - $lastActivityTime) -gt [TimeSpan]::FromMinutes($activityIntervalMinutes)) {
        Invoke-ActivitySimulation
        $lastActivityTime = Get-Date
    }
}
