# Improved mouse jiggler to prevent idle sleep and keep Teams online
# - Adds subtle micro-movements instead of random repositions
# - Simulates keyboard activity to keep Teams status online
# - Includes exit condition (press 'q' to quit)
# - Configurable timing and movement
# - Basic error handling

Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
Add-Type -AssemblyName System.Drawing -ErrorAction Stop

# Configuration
$idleThresholdSeconds = 60  # Time before checking for movement
$jigglePixels = 1              # Subtle movement distance (pixels)
$checkIntervalMs = 100         # Polling interval for key press (ms)
$activityIntervalMinutes = 1   # Interval for simulated keyboard activity (minutes)

# Function to jiggle cursor subtly
function Move-CursorSubtly {
    param([int]$pixels)
    try {
        $currentPos = [System.Windows.Forms.Cursor]::Position
        $newPos = New-Object System.Drawing.Point(($currentPos.X + $pixels), ($currentPos.Y + $pixels))
        [System.Windows.Forms.Cursor]::Position = $newPos
        Start-Sleep -Milliseconds 50  # Brief pause
        [System.Windows.Forms.Cursor]::Position = $currentPos  # Return to original
    } catch {
        Write-Warning "Failed to move cursor: $_"
    }
}

# Function to simulate keyboard activity for Teams
function Simulate-Activity {
    try {
        [System.Windows.Forms.SendKeys]::SendWait("{SCROLLLOCK}")
        Write-Host "Simulated keyboard activity at $(Get-Date -Format 'HH:mm:ss')"
    } catch {
        Write-Warning "Failed to simulate activity: $_"
    }
}

# Main loop
$lastPos = [System.Windows.Forms.Cursor]::Position
$lastActivityTime = Get-Date
Write-Host "Mouse jiggler and activity simulator started. Press 'q' to quit."

while ($true) {
    Start-Sleep -Seconds $idleThresholdSeconds

    $currentPos = [System.Windows.Forms.Cursor]::Position
    if ($currentPos -eq $lastPos) {
        # No movement detected - jiggle subtly
        Move-CursorSubtly -pixels $jigglePixels
        Write-Host "Jiggled cursor at $(Get-Date -Format 'HH:mm:ss')"
    }

    $lastPos = $currentPos

    # Simulate activity periodically to keep Teams online
    if ((Get-Date) - $lastActivityTime -gt [TimeSpan]::FromMinutes($activityIntervalMinutes)) {
        Simulate-Activity
        $lastActivityTime = Get-Date
    }

    # Check for quit key (non-blocking)
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq 'Q') {
            Write-Host "Exiting mouse jiggler."
            break
        }
    }
}