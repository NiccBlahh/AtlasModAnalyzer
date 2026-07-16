
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int cButtons, int dwExtraInfo);
}
"@

$VK_F8 = 0x77
$VK_ESCAPE = 0x1B

$MOUSEEVENTF_LEFTDOWN = 0x02
$MOUSEEVENTF_LEFTUP = 0x04

$clicking = $false
$clickIntervalMs = 100 # Adjust this value to change click speed (in milliseconds)

Write-Host "AutoClicker ready!" -ForegroundColor Cyan
Write-Host "Press F8 to toggle ON/OFF."
Write-Host "Press ESC to exit."
Write-Host "---------------------------"

while ($true) {
    # Check if F8 is pressed
    $f8State = [Win32]::GetAsyncKeyState($VK_F8)
    
    # Check if ESC is pressed
    $escState = [Win32]::GetAsyncKeyState($VK_ESCAPE)

    if (($f8State -band 0x8000) -eq 0x8000) {
        $clicking = -not $clicking
        if ($clicking) {
            Write-Host "Autoclicker ON" -ForegroundColor Green
        } else {
            Write-Host "Autoclicker OFF" -ForegroundColor Red
        }
        # Sleep briefly to debounce the key press so it doesn't toggle multiple times rapidly
        Start-Sleep -Milliseconds 300 
    }

    if (($escState -band 0x8000) -eq 0x8000) {
        Write-Host "Exiting Autoclicker..." -ForegroundColor Yellow
        break
    }

    if ($clicking) {
        # Perform the click
        [Win32]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
        [Win32]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
        
        # Delay between clicks
        Start-Sleep -Milliseconds $clickIntervalMs
    } else {
        # Reduce CPU usage when idle
        Start-Sleep -Milliseconds 50 
    }
}
