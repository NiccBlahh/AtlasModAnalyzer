[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

Write-Host ""
Write-Host "   █████╗ ████████╗██╗      █████╗ ███████╗" -ForegroundColor Cyan
Write-Host "  ██╔══██╗╚══██╔══╝██║     ██╔══██╗██╔════╝" -ForegroundColor Cyan
Write-Host "  ███████║   ██║   ██║     ███████║███████╗" -ForegroundColor Cyan
Write-Host "  ██╔══██║   ██║   ██║     ██╔══██║╚════██║" -ForegroundColor Cyan
Write-Host "  ██║  ██║   ██║   ███████╗██║  ██║███████║" -ForegroundColor Cyan
Write-Host "  ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝" -ForegroundColor Cyan
Write-Host "            Atlas Mod Analyzer" -ForegroundColor White
Write-Host ""
Write-Host "  Made by Nicc and Tryserver , hit up imnicc.dll for any errors" -ForegroundColor DarkGray
Write-Host ""

$strcanDirectory = $null

$possibleDirs = [System.Collections.Generic.List[string]]::new()

# Modrinth
$modrinthDir = "$env:APPDATA\ModrinthApp\profiles"
if (Test-Path -LiteralPath $modrinthDir) {
    Get-ChildItem -Path $modrinthDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Join-Path $_.FullName "mods"
        if (Test-Path -LiteralPath $p) { $possibleDirs.Add($p) }
    }
}

# CurseForge
$cfDir = "$env:USERPROFILE\curseforge\minecraft\Instances"
if (Test-Path -LiteralPath $cfDir) {
    Get-ChildItem -Path $cfDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Join-Path $_.FullName "mods"
        if (Test-Path -LiteralPath $p) { $possibleDirs.Add($p) }
    }
}

# Feather Client
$featherDir = "$env:APPDATA\.feather\user-mods"
if (Test-Path -LiteralPath $featherDir) { $possibleDirs.Add($featherDir) }

# Lunar Client
$lunarDir = "$env:USERPROFILE\.lunarclient\offline"
if (Test-Path -LiteralPath $lunarDir) {
    Get-ChildItem -Path $lunarDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Join-Path $_.FullName "mods"
        if (Test-Path -LiteralPath $p) { $possibleDirs.Add($p) }
    }
}

# Badlion
$badlionDir = "$env:APPDATA\.badlion\mods"
if (Test-Path -LiteralPath $badlionDir) { $possibleDirs.Add($badlionDir) }

# NoRisk
$noriskDir = "$env:APPDATA\.norisk\mods"
if (Test-Path -LiteralPath $noriskDir) { $possibleDirs.Add($noriskDir) }

# Vanilla / MC Launcher
$vanillaDir = "$env:APPDATA\.minecraft\mods"
if (Test-Path -LiteralPath $vanillaDir) { $possibleDirs.Add($vanillaDir) }

if ($possibleDirs.Count -gt 0) {
    $mostRecent = $possibleDirs | ForEach-Object { Get-Item -LiteralPath $_ -ErrorAction SilentlyContinue } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $strcanDirectory = $mostRecent.FullName
}

Write-Host ""
Write-Host "  Auto-Detected: " -ForegroundColor DarkGray -NoNewline
if ($strcanDirectory) { Write-Host "$strcanDirectory" -ForegroundColor White }
else { Write-Host "None" -ForegroundColor DarkRed }

Write-Host ""
Write-Host "  Paste the path to your mods folder (or a .zip of it)," -ForegroundColor Gray
Write-Host "  or press Enter to use the auto-detected path above." -ForegroundColor Gray
$rawPath = Read-Host "  Path"

if ($rawPath -and $rawPath.Trim() -ne "") {
    $strcanDirectory = $rawPath.Trim('"', "'", ' ')
    if (-not (Test-Path -LiteralPath $strcanDirectory)) {
        Write-Host "  Invalid path. Exiting." -ForegroundColor Red
        exit 1
    }

    $itemInfo = Get-Item -LiteralPath $strcanDirectory
    if ($itemInfo -is [System.IO.FileInfo]) {
        if ($itemInfo.Extension -match "\.zip$") {
            Write-Host "  Extracting ZIP file for scanning..." -ForegroundColor DarkGray
            $tempDir = Join-Path $env:TEMP ("ModScan_" + [Guid]::NewGuid().ToString().Substring(0,8))
            Expand-Archive -LiteralPath $strcanDirectory -DestinationPath $tempDir -Force
            $strcanDirectory = $tempDir
        } else {
            Write-Host "  Please provide a folder path or a .zip file." -ForegroundColor Red
            exit 1
        }
    }
} elseif (-not $strcanDirectory) {
    Write-Host "  No path selected. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "  Scanning  " -ForegroundColor DarkGray -NoNewline
Write-Host "$strcanDirectory" -ForegroundColor White


Add-Type -AssemblyName System.IO.Compression.FileSystem

$threatSignatures = ([System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('QWltQXNzaXN0fHxBbmNob3JUd2Vha3N8fEF1dG9BbmNob3J8fEF1dG9DcnlzdGFsfHxBdXRvRG91YmxlSGFuZHx8SkRXUC5WaXJ0dWFsTWFjaGluZS5BbGxNb2R1bGVzfHxBdXRvSGl0Q3J5c3RhbHx8QXV0b1BvdHx8QXV0b1RvdGVtfHxBdXRvQXJtb3J8fEludmVudG9yeVRvdGVtfHxMZWdpdFRvdGVtfHxQaW5nU3Bvb2Z8fFNlbGZEZXN0cnVjdHx8U2hpZWxkQnJlYWtlcnx8VHJpZ2dlckJvdHx8QXhlU3BhbXx8V2ViTWFjcm98fEZhc3RQbGFjZXx8V2Fsc2t5T3B0aW1pemVyfHxXYWxrc3lPcHRpbWl6ZXJ8fHdhbHNreS5vcHRpbWl6ZXJ8fFdhbGtzeUNyeXN0YWxPcHRpbWl6ZXJNb2R8fERvbnV0fHxSZXBsYWNlIE1vZHx8U2hpZWxkRGlzYWJsZXJ8fFNpbGVudEFpbXx8VG90ZW0gSGl0fHxXdGFwfHxGYWtlTGFnfHxCbG9ja0VTUHx8ZGV2LmtyeXB0b258fGRldi9rcnlwdG9ufHxza2lkLmtyeXB0b258fHNraWQva3J5cHRvbnx8QW50aU1pc3NDbGlja3x8TGFnUmVhY2h8fFBvcFN3aXRjaHx8U3ByaW50UmVzZXR8fENoZXN0U3RlYWx8fEFudGlCb3R8fEVseXRyYVN3YXB8fEZhc3RYUHx8RmFzdEV4cHx8UmVmaWxsfHxBaXJBbmNob3J8fGpuYXRpdmVob29rfHxGYWtlSW52fHxIb3ZlclRvdGVtfHxBdXRvQ2xpY2tlcnx8QXV0b0ZpcmV3b3JrfHxQYWNrU3Bvb2Z8fEFudGlrbm9ja2JhY2t8fGNhdGxlYW58fEF1dGhCeXBhc3N8fEFzdGVyaWF8fFByZXN0aWdlfHxBdXRvRWF0fHxBdXRvTWluZXx8TWFjZVN3YXB8fE1hY3JvMTk4fHxTdHVuU2xhbXx8U2FmZUFuY2hvcnx8RG91YmxlQW5jaG9yfHxBdXRvVFBBfHxCYXNlRmluZGVyfHxYZW5vbnx8Z3lwc3l8fEF1dG9Qb3RSZWZpbGx8fEtleVBlYXJsfHxBdXRvTmV0aFBvdHx8QXV0b0R0YXB8fEF1dG9XZWJ8fEFuY2hvckFjdGlvbnx8b3JnLmNoYWlubGlicy5tb2R1bGUuaW1wbC5tb2R1bGVzLkNyeXN0YWwuWXx8b3JnLmNoYWlubGlicy5tb2R1bGUuaW1wbC5tb2R1bGVzLkNyeXN0YWwuYkZ8fG9yZy5jaGFpbmxpYnMubW9kdWxlLmltcGwubW9kdWxlcy5DcnlzdGFsLmJNfHxvcmcuY2hhaW5saWJzLm1vZHVsZS5pbXBsLm1vZHVsZXMuQ3J5c3RhbC5iWXx8b3JnLmNoYWlubGlicy5tb2R1bGUuaW1wbC5tb2R1bGVzLkNyeXN0YWwuYnF8fG9yZy5jaGFpbmxpYnMubW9kdWxlLmltcGwubW9kdWxlcy5DcnlzdGFsLmN2fHxvcmcuY2hhaW5saWJzLm1vZHVsZS5pbXBsLm1vZHVsZXMuQ3J5c3RhbC5vfHxvcmcuY2hhaW5saWJzLm1vZHVsZS5pbXBsLm1vZHVsZXMuQmxhdGFudC5JfHxvcmcuY2hhaW5saWJzLm1vZHVsZS5pbXBsLm1vZHVsZXMuQmxhdGFudC5iUnx8b3JnLmNoYWlubGlicy5tb2R1bGUuaW1wbC5tb2R1bGVzLkJsYXRhbnQuYnh8fG9yZy5jaGFpbmxpYnMubW9kdWxlLmltcGwubW9kdWxlcy5CbGF0YW50LmNqfHxvcmcuY2hhaW5saWJzLm1vZHVsZS5pbXBsLm1vZHVsZXMuQmxhdGFudC5ka3x8aW1ndWkuZ2wzfHxpbWd1aS5nbGZ3fHxCb3dBaW18fENyaXRpY2Fsc3x8RmFrZW5pY2t8fEZha2VJdGVtfHxpbnZzZWV8fEl0ZW1FeHBsb2l0fHxIZWxsaW9ufHxoZWxsaW9ufHxMaWNlbnNlQ2hlY2tNaXhpbnx8Q2xpZW50UGxheWVySW50ZXJhY3Rpb25NYW5hZ2VyQWNjZXNzb3J8fENsaWVudFBsYXllckVudGl0eU1peGltfHxkZXYuZ2FtYmxlY2xpZW50fHxvYmZ1c2NhdGVkQXV0aHx8cGhhbnRvbS1yZWZtYXAuanNvbnx8eHl6LmdyZWFqfHzjgZguY2xhc3N8fOOBtS5jbGFzc3x844G2LmNsYXNzfHzjgbcuY2xhc3N8fOOBny5jbGFzc3x844GtLmNsYXNzfHzjgZ0uY2xhc3N8fOOBqi5jbGFzc3x844GpLmNsYXNzfHzjgZAuY2xhc3N8fOOBmi5jbGFzc3x844GnLmNsYXNzfHzjgaQuY2xhc3N8fOOBuS5jbGFzc3x844GbLmNsYXNzfHzjgaguY2xhc3N8fOOBvy5jbGFzc3x844GzLmNsYXNzfHzjgZkuY2xhc3N8fOOBri5jbGFzcw=='))) -split '\|\|'
$knownMaliciousStrings = ([System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('Ti5hbWVUYWdzfHxtb29uQ2xpZW50fHx0cmlnZ2VyIGJvdHx8aXRjaCBDaGFuY2V8fC5sYWNlIGNoYW58fGltcGFjdGNsaWVudHx8TGF2YVdhbGt8fEZha2VMYXRlbmN5fHw/eXN0YWwgYm91bmNlIGFuaW1hdGlvbnx8cy50b3B8fFIuYW4/Pz98fD8ubGFjZSBEZWxheXx8QXV0b0FybW9yfHxqZHdwfHxMb25nUmVhY2h8fE1pbiBQZWFybHx8RC5lbGF5SC5vdGJhcj8ub3RlbSBTbG90P2l0Y2h8fD8/b3cgZWZmZWN0IHRvIGFsbCBlbnRpdGllc3x8Uy50b3AgT24gS2lsbHx8Z2V0cy4uLnx8RmFzdENsaW1ifHxBdXRvQWltfHxTLmFtZSBQbGF5ZXJ8fD8/Vy5oaWxlIFVzZVMudG8/Pz8/Uy53aXQ/P1Mud2l0Y2ggQ2hhbmNlUC5sP2NlPz9hbj8/ZSBEZWxheUUueHBsb2RlIFNsb3Q/P093bj8/b25lUi5hbmQgR2xvdyBNaW4/R2xvdyA/P3x8RmFzdEJyaWRnZXx8V2FsbEhhY2t8fEZhaWxlZCB0byBzd2l0Y2ggdG8gbWFjZSBhZnRlciBheGUhfHxBLmN0aXZhP0Fib3ZlfHxTd29yZEF4ZUJvdGh8fD8/T3dufHxob3IgTWFjfHxBLmN0J3x8Ui5hbnx8Q2hlY2sgSXRlbXN8fFN0YXkgT3BlbiBGb3J8fC8ubWNDbGllbnQtcmVuZGVyZXItY2F8fE5ld0NodW5rc3x8UkVGSUxMSU5HfHxIaWdoU3RlcHx8YWNlIGJsb2NrcyBmYXN0ZXInfHw/Lm90ZW0gU2xvdHx8TWFjZSBQcmlvcml0eXx8YXV0byBhcm1vcnx8cC5sYWNlSW50ZXI/YWx8fEJhY2tkb29yfHxBdXRvIE1hY2UnfHxTLndpdD8/fHxvcmcvY2hhaW5saWJzL21vZHVsZS9pbXBsL21vZHVsZXN8fEF1dG9BbmNob3J8fE0uaW4/fHxBLnV0byBDcnlzdGFsQS5jdGl2YXRlIEtleT8ubGFjZSBEZWxheT8/YW5jZUIucmVhayBDaGFuY2VTLnRvcCBPbiBLaWxsRi5ha2UgUHVuY2hDLmxpY2s/P0QuYW1hZ2UgVGlja0EubnRpPz8/fHxHeXBzeUNsaWVudHx8QS5udGl8fE1pbiBUb3RlbXN8fEZha2VMYWd8fGFycmF5T2ZTdHJpbmd8fG5ldC9jYWZmZWluZW1jL21vZHMvbGl0aGl1bS9mYWJyaWMvY29tcGF0L2NvcmUnfHxTYXZlZDogP3x8Qy5oYW5jZXx8Uy53aXRjaERlP3x8QXV0aEJ5cGFzc3x8TWF4IFNwZWVkfHxBdXRvV2VifHxBLnV0b3x8Ui5lcXVpcj98fEEuY3Rpdid8fEF1dG9Ub3RlbXx8P2FzdCBQP3x8Q2hlY2sgUGxheWVyc3x8ZCBDb25maWdzfHxFLnhwbG9kZSBTbG90fHxBdXRvUGVhcmx8fGF1dG8gYW5jaG9yfHxBbnRpIFdlYWtuZXNzJ3x8QS51dG8nfHxNLmFjcm8gS2V5fHx3dGYvbW9vbmxpZ2h0fHxpbWd1aS5iaW5kaW5nfHxHYW1lU3BlZWR8fFBhY2tldE1pbmV8fEF1dG9TcHJpbnR8fFMud2l0Y2ggPz98fEF1dG9tYXRpY2FsbHkgaGl0LWNyeXN0YWxzIGZvcid8fEUueHB8fEJlZFBsYWNlfHxjb20vYWxhbi9jbGllbnRzfHxUYXJnZXRTdHJhZmV8fGFuY2hvck1hY3JvfHxTLmhvdyBEaXN0YW5jZXx8b3cgZWZmZWN0IHRvfHxleGhpYml0aW9ufHxULnJpZ2dlcj98fEF1dG9Dcml0fHxWdWxjYW5CeXBhc3N8fEF1dG9XZWFwb258fG5ldC9taW5lY3JhZnQvaW5qZWN0aW9ufHw/YWxMVjI/dGl2YXRlIEtleUMubGljayBTaW11bGF0aW9uTi5vIENvdW50IEdsaT9QLj8/YXlCLnJlYWsgRGVsYXk/Pz9vZGV8fEJvd1NwYW18fD8gQXNzaXN0P2lzdHMgeW91ciBhaW0gdG93YXJkcz8/bGF5Pz8/ZSBDbGlja1Zpc2liaWxpdD9UYXI/dCBMb2NrP2l0Y2ggVGFyZ2V0IEtleT8/TWF4IFNwZWVkPz9pPz8gQm9uZVNtYXJ0V2VhcG9uIE9ubHl8fEFpckFuY2hvcnx8bHZzdHJuZ3x8YXN0ZXJpYSBjbGllbnR8fGRxcmtpcy54eXp8fEEudXRvIFN3aXRjaHx8TS5pbnx8U3R1blNsYW18fEZyZWV6ZVBsYXllcnx8Uy53fHxhc3RvbGZvfHxBbnRpS0J8fEcubG93c3Rvbnx8PyB0aHJvdWdoIHdhbGxzfHxQLj8/IERhbWFnZXx8Y2F0bGVhbiBjbGllbnR8fE11bHRpQXVyYXx8QkhvcHx8QS51dG8gRG91YmxlIEhhbmR8fG5vdm93YXJlfHxGYWtlUGluZ3x8Pz8/P3NwYXduIGFuY2hvcnM/Y3Rpb24gU3BlZWQgKG1zKT8/Pz8/Pz9vb3RoIFJvdGF0aT9uc1JvdGF0aW9uIFNwZWVkPz8/RWFzaW5nRWFzaW5nIFN0cmVuZ3RofHxDaGVzdFNtYXJ0fHxCaW5kaW5nQnJpZGdlJ3x8cG90aW9uY2hpbWUuY29uZmlnLmVmZmVjdHN8fEEudXRvQyd8fE1pbi4/aWdodHx8TS5pbiBUb3Q/fHxhbmNob3J0d2Vha3N8fGJ5dGVjb2RlLXZpZXdlcnx8U3dpdGNoIERlbGF5fHxkZW5zaXR5YnJlYWNofHxOYXRpdmVLZXlMaXN0ZW5lcnx8Qy5saWNrfHxBdXRvQnJpZGdlfHxSQ1RSTHx8SW5jbHVkZSBIZWFkfHxGYWtlIFB1bmNofHxuZXQvY2NibHVleHx8YXV0byBkb3VibGUgaGFuZHx8P2FrZVB1bmNofHxibHVlQ29sb3J8fEJyZWFrIERlbGF5fHx2YXBlLmdnfHxwb3Rpb25jaGltZS5jb25maWcuZW5hYmxlZHBvdGlvbmNoaW1lLmNvbmZpZy5lc2NhbGF0aW5ncG90aW9uY2hpbWUuY29uZmlnLmVmZmVjdHN8fFNoaWVsZERpc2FibGVyfHxNaW4gRmFsbCBTcGVlZHx8Qy5oZWNrIFN8fD8/dC5hZ2U/fHxwcmV2aWV3IHRvIHBsYWNlIGl0fHxhbmNob3IgbWFjcm98fEIuYWNrZyd8fFRhcmdldEhVRHx8ZHFya2lzfHxFYXNpbmcgU3RyZW5ndGh8fGF1dG9jcnlzdGFsfHxPcGVuIEZvbD98fENoZWNrIFNoaWVsZHx8P2VzcG9uc2VDb2RlfHxvb3RoIFJvdGF0aXx8Ty5ubHkgQXhlfHxXYXRjaGRvZ0J5cGFzc3x8Ty5ubHkgQ3JpdCBTd29yZHx8R1VJIFNldHRpbmdzfHxLQlJlZHVjZXx8bWV0ZW9yZGV2ZWxvcG1lbnR8fC5XRkggQ3J5c3R8fEF1dG9Eb3VibGVIYW5kfHxOLm9Cb3VuY2V8fE9wZW4gRm9sfHxDLmhlY2sgSXRlbXN8fG8ubmUgbmluZSBlaWdodCA/cm9NLmFjcm8gS2V5P2F0P29kZVAubGFjZT9lbGF5Qi5yZWFrP2VsYXlQLmxhY2UgY2hhbmNlQi5yZWFrIGNoYW5jZT8/Ri5ha2UgcHVuY2hQLmFydGljbGUgQ2hhbmNlfHx2aXJnaW4gY2xpZW50fHxjdGlvbiBTcGVlZCAobXMpfHxBdXRvIEludmVudG9yeSd8fEFjdGl2YXRlcyBBYm92ZSd8fFZlbG9jaXR5U3Bvb2Z8fD8uanNvbmRlP3x8YXhlIHNwYW18fD9hLm5ldC5VUkl8fFN3aXQ/bj98fF0lIGvDuDghXzRUfHxGLm9yY2U/fHxlYWsgZGVsYXl8fEMubGljaz8/fHxTYXZlZCBDb25maWdzPz8/Tm8gY29uZmlncyA/YXZlZE9wZW4gRm9sZGVyT3BlbiBGb2w/X1NhdmVTYXZlfHxWaXN1YWxzb24gPSBkaXNhYmxlICAgb2ZmID0gY29uZmlnPz98fG1hY2Vfc3dhcHx8QS51dG8gQ3J5c3RhbHx8Uy53aXRjaCBEP3x8SC5vdGJhcnx8P2F5ZXI6ID8/Pz9tKXx8Qi5yZWFjaCd8fGRvbnRCcmVha0NyeXN0YWx8fEFwcGx5aW5nIGhpZ2ggaW1wYXx8U2VhcmNoIG1vZHVsZXMuLi58fHJpdCBBeGV8fFMucHJpbnRLLmVwcyB5b3Ugc3ByaW50aW5nIGF0IGFsbCB0aW1lc3x8Qm93QWltYm90fHxBaW1Mb2NrfHxFcnJvciBsbz8/P3x8Uy50bz8/fHxQTEFDRV9PQkl8fEF1dG8gSnVtcCBSZXNldCd8fGF1dG8gdG90ZW18fD8ubGljayBTaW11bGF0aW9ufHxHLmxvdz8/b3cgZWZmZWN0IHRvIGFsbCBlbnRpdGllc0Mub2xvciBNb2RlQy51c3RvbSBSZWQ/P0MudXN0b20gQmx1ZT9ib3cgU3BlP1AubGF5ZXJ8fD9ja0d1aVM/P3x8PyBDcml0IEF4ZXx8ZmluZEtub2NrYmFja1N3b3JkfHxDaGVjayBMaW5lIG9mIFNpP3x8LnJldmVudHMgY2VydGFpbiBhY3Rpb25zfHxCLnJlYWsgQ2hhbmNlJ3x8P2hlYz8gQWltfHxKdW1wUmVzZXR8fD8gQXNzaXN0fHx4eXovZ3JlYWp8fFN0b3JhZ2VFU1B8fE5vU2xvd3x8Lm5lIG5pbmUgZWlnaHR8fHNhZmVhbmNob3J8fEV4dGVuZFJlYWNofHw/P29yIE1vdmV8fE5vIGF4ZSBmb3VuZCAtIHVzaXx8SGFzQW5jaG9yfHxydXNzPz8/fHxzIGFib3ZlIHBsYXllcnN8fHhlbm9uIGNsaWVudHx8QXV0b0Jvd3x8P2N0aW9uIFNwZWVkIChtcyl8fC5sYWNlfHxQb3BTd2l0Y2h8fEF1dG9SZXNwYXdufHxPbmx5IE9uIFBvcHx8P2VhP3x8Tm9Lbm9ja2JhY2t8fEEudXRvIEhpfHxDLmxpY2sgU2ltdT98fEl0ZW1FeHBsb2l0fHxQLmxhY2UgY2hhbmNlfHxTcGVlZEhhY2t8fD9fP8O/XHgxRHx8Ty5uIEdyb3VuZHx8UC5sfHxGb3JjZSBUb3RlbXx8QXNzaXN0cyB5b3VyIGFpbSB0b3dhcmRzIHRhcmdldHMgc21vb3RobHknfHxMaWNlbnNlQ2hlY2tNaXhpbnx8Ui5lbmRlcnMgY3VzdG9tIG5hbXx8UGxhY2UgQ2hhbmNlfHxMb290WWVldGVyfHw/ZW0gRmlyc3R8fFN3b3JkIFN3P3x8U3Rhc2hGaW5kZXJ8fE1hY2VTd2FwfHxBLnhlIERlbGF5IE0nfHxzZXRJdGVtVXNlQ29vbGRvd258fD9lIENsaWNrfHxjb20uc3VuLm1hbmFnZW1lP214cmVtb3RlfHxSLmVuZGVycyBjdXN0b20gbmFtP3MgYWJvdmUgcGxheWVyc3x8QmluZGluZ0FjY2Vzc29yJ3x8UC5sYWNlIENoYW5jZXx8SW50YXZlQnlwYXNzfHxpdGNoIFRhcmdldCBLZXl8fFIuYW5kIEdsfHxSLmFuZG9tIERlbGF5IE1heHx8TS5hY2UgUz8/fHxhY3RpdmF0ZU9uUmlnaHRDbGlja3x8YS5uZXQuVVJJfHxOLm8gQ291bnQgR2xpP3x8aW5kIEJ1cnN0fHxsYWNlIGRlbGF5fHxST1RBVElOR19ET1dOfHzvvKM/77yyPz8/Pz8/P++9ge+9ku+9jCA/fHxBdXRvdG90ZW0nfHwub3RlbSBTbG90fHxGLm9yY2V8fEdsb3dzdG9uZSBEZWxheXx8SW5zdGFudEJyZWFrfHxFeHBsb2RlIENoYW5jZXx8O8Kww4dwNMOCw5jDsWfCrCRxaDFceDE5XHgwN1fDu2M/P3x8P2REaXNhYmxlcnx8UGFja2V0Rmx5fHxSZXZlcnNlU2hlbGx8fFAuPz9heXx8VG90ZW0gU2xvdHx8QXV0b0NsaWNrZXJ8fExlZ2l0QXVyYXx8Py5qc29ufHxTdG9wIE9uIEtpbGx8fGEuY3RpdmF0ZU9uUmlnfHxBbnRpRmFsbHx8YXN0IFB8fEFudGlTdXJyb3VuZHx8RG9udXR8fEludk1vdmVieXBhc3N8fFRvdGVtU3dpdGNofHxzaGllbGRzaGllbGR8fEF1dG8gU3dpdGNoIEJhY2t8fE5vdCBXaGVuIEFmZmVjdHMgUGxheWVyfHxDYXRsZWFuQ2xpZW50fHxhdXRvZG91YmxlaGFuZHx8cHJlc3RpZ2UgY2xpZW50fHxObyBheGUgZm91bmQgLSB1c2luZyBtYWNlIG8/P3x8aW52c2VlfHxib3VuY2UgYW5pbWF0aW9ufHxQT1NUX0NZQ0xFX0RFTEFZfHxvbiA9IGRpc2FibGUgICBvZmYgPSBjb25maWc/P3x8SSdtIGdldHRpbmcgU1MnZWR8fFNlc3Npb25TdGVhbGVyfHxneXBzeSBjbGllbnR8fEQuYW1hZ2UgVGlja3x8cGluZyBzcG9vZnx8UGFja1Nwb29mfHxPbiBSTUJ8fD9vbm5lYz98fE1hdHJpeEJ5cGFzc3x8Ti5hbWVUYWdzUi5lbmRlcnMgY3VzdG9tIG5hbT9zIGFib3ZlIHBsYXllcnM/bD9TLmhvdyBEaXN0YW5jZT8/SD8/ZXR8fHByZXN0aWdlY2xpZW50LnZpcHx8cnVzc3x8P3BlZWR8fFNub3cgUGFydGljbGVzfHxPcGVuIEZvbGRlcnx8bExWMnx8Q3J5c3RhbEF1cmF8fD8/P2VhdHN8fG1lL3plcm9laWdodHNpeC9rYW1pfHxhdXRvIHBvdHx8QnV0dGVyZmx5Q2xpY2t8fEFBQ0J5cGFzc3x8QWltQXNzaXN0fHxPLm58fGd1aUtleXx8Pz9nZXRzLi4ufHw/LldGSCBDcnlzdD98fFJPVEFUSU5HX0JBQ0t8fFAubGFjZSBkZWxheXx8ZG9vbXNkYXljbGllbnR8fHBoYW50b20tcmVmbWFwLmpzb258fEF0dGFjayBEZWxheXx8aCBCYWNrfHxrb25hc3x8T2ZmaGFuZFRvdGVtfHxULnJpZ2dlcj9XLmhpbGUgP3NlTy5uIExlZnQgQ2xpPz8gSXRlbXM/b3JkIERlP1M/Pz8/IE0/Pz8/Qy4/P08ubmx5IENyaXQgU3dvcmQ/IENyaXQgQXhlUy53aW5nIEg/Vy5oaWxlIEFzY2VuZGluZz8ubGljayBTaW11bGF0aW9uPz9wYXNzQS5sbCA/P3RpZXNVLj8/P2llbGQgVGltZVMuYW1lIFBsYXllcnx8bWV0ZW9yZGV2ZWxvcG1lbnQubWV0ZW9yY2xpZW50fHxseSBBeGV8fD8gcHJldmlldyB0byBwbGFjZSBpdHx8RGlzY29yZFRva2VufHxlIENoYW5jZXx8V1RhcHx8SC5pZ2hsaWdoP3x8QW5jaG9yQWN0aW9ufHxBY3RpdmF0ZXMgQWJvdmV8fFRyYWlsRmluZGVyfHxCLnJlYWsgRGVsYXl8fEJSRUFLX0NSWVNUQUx8fHBvdGlvbmNoaW1lLmNvbmZpZy53YXJuaW5nX3dpbmRvd3x8XHgwN1fDu2NZbXx8TW9iRVNQfHw/LnJldmVudHMgY2VydGFpbiBhY3Rpb25zfHxObyBjb25maWdzfHw/IEdsb3cgTT98fEEudXRvIERvdWJ8fENoZXN0RVNQfHxTLnQ/IEtpbGx8fGh0dHA6Ly81MS4zOC4xMzQuMjAwOjMwMDAvYXBvL2xhdW5jaHx8UGFja2V0U25lYWt8fFoxXHgwM3I/P3x8UG9zaXRpb25TcG9vZnx8RE9VQkxFX0VTQ0FQRXx8YWN0aXZhdGVLZXknfHw/YWxMVjJ8fC5sYWNlIER8fGNvbS5zdW4ubWFuYWdlbWV8fFRvdGVtIEZpcnN0fHxyaXNlY2xpZW50LmNvbXx8YXR0YWNrUmVnaXN0ZXJlZFRoaXNDbGlja3x8Uy50P3x8Uy50b3x8c2tpZC9rcnlwdG9ufHxhdXRvdG90ZW18fGludGVudC5zdG9yZXx8TS5hY3JvfHxBLmltIEFzcyd8fD82TlokXHgxNlx4MDZceDFEcm4yW19ceDAzXHgxQ3t6fHxTaWxlbnRBaW18fFNlbGZEZXN0cnVjdHx8bmV0L2NhZmZlaW5lbWMvbW9kcy9saXRoaXVtL2ZhYnJpYy9oZWxwZXInfHxXQUlUX09CSXx8RC5hbWFnfHxdJSBrw7g4IV80VD8/w4vDn8K0fHxPbmx5IFdoZW4gRmFsbGluZ3x8UHJlZGljdCBEYW1hZ2V8fGN3IGNyeXN0YWx8fG9uQmxvY2tCcmVha2luZ3x8VmVydXNEaXNhYmxlcnx8aHR0cDovLzUxLjM4LjEzNC4yMDA6MzAwMC9hcGkvdmVyaWZ5fHxSYWluYm93IENvbG9yU25vdyBQYXJ0aWNsZXN8fEFjdGl2YXRlIEtleXx8bWV0ZW9yLWNsaWVudHx8Sy5lcHMgeW91IHNwcmludGluZyBhdCBhbGwgdGltZXN8fD80NXx8P2vDuDghXzRUXHgxMVx0Pz98fEFudGlXZWJ8fGF1dG9fd2VifHxKLnVtcCBSZXNldCBDaGFuY2V8fEF1dG9Td29yZHx8QXV0byBJbnZlbnRvcnkgVG90ZW18fEF1dG9NYWNlfHxCbGF0YW50J3x8w4xuXHgxQ0LCpTAjPz98fE5hbWVUYWdzSGFja3x8Qi5sYXRhbnQnfHxPbmx5IENoYXJnZXx8SGlkZUNsaWVudHx8U3RyaWN0IE9uZS1UaWNrfHxQcmVzdGlnZXx8SC5VRHx8QzJTZXJ2ZXJ8fGFjZSBjaGFuJ3x8Vy5oaWx8fGluZXJ0aWF8fGNrR3VpU3x8RXJyb3Igc2F2Pz98fHdlYiBtYWNyb3x8b25Jc0dsb3dpbmd8fGF1dG9oaXRjcnlzdGFsfHxMV0ZIIENyeXN0YWx8fD8/aG9yIE1hYz98fENoZWNrIExpbmUgb2YgU2lnaHR8fD9tIFBhdHRlcm58fFNlbGZUcmFwfHxTYWZlRmFsbHx8amF2YS5uZXQuSHR0cFVSTENvbm58fGUgQ2xpY2t8fEFudGkgV2Vha25lc3N8fEFwcERhdGEvUm9hbWluZy8ubWluZWNyYWZ0Ly5tY0NsaWVudC1yZW5kZXJlci1jYWNoZSd8fEEudXRvbWF0aWNhbGx5IGF4ZSBhbmQgbWFjZSBzaGllbGRlZCBwbGF5ZT98fD8ucmV2ZW50cyBjZXJ0YWluIGFjdGlvbnM/P3JldmVudCBBbmNob3J8fFMud2l0Y2h8fFcuaGl8fE9yZUVTUHx8P1A/RC5lbGF5P2ggRD98fHN0dW5fc2xhbXx8YmxvY2tCcmVha2luZ0Nvb2xkb3dufHxBc3Npc3R8fHBvdGlvbmNoaW1lLmNvbmZpZy52b2x1bWV8fE5vSnVtcERlbGF5fHxzcGVlZFBvdFNsb3R8fEMuaGVjayA/fHxjb20vbW9vbnN3b3J0aHx8amF2YS5uZXQuVVJJY3JlYXRldG9VUkw/b25uZWM/amF2YS5uZXQuSHR0cFVSTENvbm5lY3Rpb25zZXRzZXREb091dHB1dD8/Pz9yZWFtP2VzcG9uc2VDb2RlPz8/P3RyP2Rpc2Nvbm5lY3R8fD8/dHJhfHxEcm9wIEludGVydmFsfHxOb1NvdWxTYW5kfHxBY3Rpb24gU3BlZWQnfHxGbHlIYWNrfHxSYW5kb20gUGF0dGVybnx877yh77yO772V772U772PIO+8re+9ge+9g++9hSd8fENsaWNrQXVyYXx8YW5kJ3x8UmVtb3RlQWNjZXNzfHw/Ly5tY0NsaWVudC1yZW5kZXJlci1jYT98fEFuY2hvckZpbGx8fFAubD9jZXx8UC5sYWNlfHxCcmVha2luZyBzaGllbGQgd2l0aCBheGUuLi58fHJpc2UudG9kYXl8fD8/ci1jYT98fGxkZWQgcGx8fEEudXRvIFN3aXRjaCd8fFx4MDckw4QpX3x8Ty5ubHkgQ2hhfHxhaW1fYXNzaXN0fHw/cyBmYT8/fHxXLmhpbGUgQXNjZW5kaW5nfHxBdXRvbWF0aWNhbGx5IHN3aXRjaGVzIHRvIHN3b3JkIHdoZW4gaGl0dGluZyB3aXRoIHRvdGVtfHxceDFBesKuwql9T3x8aCBEZWx8fEIubGF0YW50IE1vZGUnfHxoZWFsUG90U2xvdHx8SXRlbUVTUHx8QXV0b0JlZHx8YXV0b2FuY2hvcnx8P2F5ZXI6ID98fFBsYWNlQXNzaXN0fHxWaXNpYmlsaXQ/fHxBbmNob3JQbGFjZXx8QWlyUGxhY2V8fFJFT0ZGSEFORF9UT1RFTXx8Yi5yZXx8Qm9hdEZseXx8P2U/ZXJ8fEV4cGxvZGUgU2xvdHx8RG9vbXNkYXlDbGllbnR8fEIucmVhayBDaGFuY2V8fEYuYWtlIFB1bmNofHxKTmF0aXZlSG9va3x8c2FmZV9hbmNob3J8fGFHJ3x8Pz8/RWFzaW5nfHxDLm9sb3IgTW9kZXx8S2V5UGVhcmx8fHNoaWVsZCB3aXRoIGF4ZS4uLnx8by5uZSBuaW5lIGVpZ2h0ID9yb3x8P2FzdCBQPz9zIGZhPz9ELmVsYXl8fGhvdmVyIHRvdGVtfHw/IEl0ZW1zfHxBcmdvbkNsaWVudHx8TS5vdmUgZnJlZWx5IHRofHxCLnJlYWsgY2hhbmNlfHxWYXBlTGl0ZXx8aC5vbGRDcnlzdGFsfHxObyBheGUgZm91bmQgLSB1c2luZyBtYWNlIG8/P0JyZWFraW5nIHNoaWVsZCB3aXRoIGF4ZS4uLkZhaWxlZCB0byBzd2l0Y2ggdG8gbWFjZSBhZnRlciBheGUhQXBwbHlpbmcgaGlnaCBpbXBhP2F0ZSF8fFMudGF5IE9wZW4gRm9yfHxzd2FwQmFja1RvT3JpZ2luYWxTbG90fHxzdG9wT25LaWxsfHxvcmQgRGV8fE8ubmx5fHw/XHgwN1fDu2NZbT98fEUueHA/ZWxheXx8YXRlIEtleXx8SW52TWFuYWdlcnx8Uy53aXRjaCBEfHxUcmlnZ2VyIEtleXx8V29yayBXaXQ/fHxhdXRvX3BvdF9yZWZpbGx8fG5vdmFjbGllbnR8fHN1c3BlbmQ9fHxicmVha0ludGVydmFsfHxBLnAnfHxQTEFDRV9DUllTVEFMfHxELmFtfHxNLmFjZSBTfHxBLmN0aXZhdGUga2V5fHxieXRlbWFufHxBLmxsID8/dGllc3x8TnVrZXJ8fD8/IENoYW5jZXx8Q3JpdEJ5cGFzc3x8cHJldmVudFN3b3JkQmxvY2tCcmVha2luZ3x8RmFpbGVkIHRvIHJlYWQgcG90aW9uY2hpbWUuanNvbiwgdXNpbmcgZGVmYXVsdHN8fGNvbS9jaGVhdGJyZWFrZXJ8fEFwcGx5aW5nIGhpZ2ggaW1wYT9hdGUhfHxJbnN0YW50RWx5dHJhfHxEb3VibGVBbmNob3J8fFRhcj90IExvY2t8fD9pdGNofHxBbHdheXNDcml0fHxBdXRvQnJlYWNofHxuZXQuY2NibHVleHx8U21vb3RoIFJvdGF0aW9uc3x8WGVub258fD9mbG93ZXJ8fEMuaGVjayBTPz8/fHxQYXJ0aWNsZSBDaGFuY2V8fD8/P29kZXx8cGluZ3Nwb29mfHxIb2xkaW5nIFdlYnx8SGVhZFNuYXB8fD9ib3cgU3BlP3x8Uy53aXRjaERlfHxWZXJ0aWNhbCBTcGVlZHx8R3JpbUJ5cGFzc3x8V2Fsc2t5T3B0aW1pemVyfHxBdXRvIFN3aXRjaCd8fEJ1cnJvd3x8UGxheWVyRVNQfHxyIGRlbGV0aW5nIXx8Q2hlY2s/YWNlfHxXZWFwb24gT25seXx8P2ggQmFja3x8PyByZXN1bHQocyl8fHJ1c2hlcmhhY2t8fFVzZSBFYXNpbmd8fEEudXRvIEhpPz98fEF1dG9Qb3R8fD8/IERlbGF5fHxDLnVzdG9tIFJlZHx8QS51dG8gU3dpdCd8fFAubGFjZT9lbGF5fHxMLm9vdCBZZWV0ZXJ8fD8/Li4uPz8hfHxkZWZhdWx0Lmpzb258fHJ1c3NpYW5UfHw/aCBEP3x8QS5udGk/Pz98fHNraWxsZWR8fGEuY3RpdmF0ZU9uUmlnaHRDbGljayd8fEcubG93c3Rvbj8/fHxQLmFydGljbGUgQ2hhfHxzZXRCbG9ja0JyZWFraW5nQ29vbGRvd258fExpbmUgb2Z8fE0uYWNlIFM/P1cuaW5kIEJ1cnN0Pz8/Ty5ubHkgQXhlP2ggQmFja1Mud2l0Y2ggRD98fGludm9rZU9uTW91c2VCdXR0b258fD9vb3RoIFJvdGF0aT9uc3x8eW91ciBhaW0gdG93YXJkc3x8Ri5hfHxWaXJnaW5DbGllbnR8fEEubnRpLVdlJ3x8UHJlZGljdCBDcnlzdGFsc3x8ZGV2LmtyeXB0b258fD9lbnRvcnkgVG90ZW1NLm9kZT8/Pz9BLnV0byBTd2l0Y2hGLm9yY2U/QT9TLnRheSBPcGVuIEZvcj8/b3IgTW92ZT8/P3x8YXRlIEtleSd8fDZOWiRceDE2XHgwNlx4MURyfHxDcml0IFN3b3x8UC5yZWRpY3QgQ3J5c3Q/P3x8Q3JpdGljYWxIaXR8fEF1dG8/Y2V8fEJsb2NrQ2FsY3VsYXRvcid8fEMudXN0b20gQmx1ZXx8Vy5oaWxlID9zZXx8UmVhY2hEaXNwbGF5fHxQb3Rpb24gRWZmZWN0IENvdW50ZG93biBDaGltZSBpbml0aWFsaXplZHx8dXNlci5uYW1lb3MubmFtZW9zLmFyY2hTSEEtMjU2fHxTLndpbmcgSD98fEVuaGFuY2VkIE1vZHVsZXN8fD8/aG9yIE1hYz8/P2V5Vy5oaWxlIFVzZVMudD8gS2lsbD9sYXRpb24/P1AubGFjZSBDaGFuY2VHLmxvd3N0b24/Pz8/IENoYW5jZUUueHA/ZWxheUUueHBsb2RlIENoYW5jZUU/U2w/Pz9PLm5seSBDaGE/Pz9uZG9tIEdsb3dzdG9uZVIuYW5kIEdsb3cgTWluP00/fHxkYW1hZ2V0aWNrfHxBbnRpQUZLfHxKRFdQLlZpcnR1YWxNYWNoaW5lLkFsbE1vZHVsZXN8fFNjYWZmb2xkV2Fsa3x8Z3lwc3l8fEJlZEJvbWJ8fEFzdGVyaWF8fEdyaW1EaXNhYmxlcnx8UmVxdWlyZSBDcnx8Y2hlYXQtcmVmbWFwLmpzb258fERvdWJsZUNsaWNrZXJ8fHRyaWdnZXJfYm90fHxCT05FTUVBTElOR3x8TS5vZHVsZXN8fEF1dG9DaXR5fHxTLnR8fEEubGwnfHxhdXRvYXJtb3J8fEUuU1B8fD8/LmhvbWVkZWZhdWx0Lmpzb258fGNsP2NrR3VpU2NhbGVydXNzPz8/cnVzc2lhblQ/ZW1lcmVkQ29sb3JyZWRDb2xvcmdyZWVuQ29sb3JibHVlQ29sb3I/bz8/YmdHcmVlbmJnR3JlZW58fGNsaWVudC1yZWZtYXAuanNvbnx8U2hpZWxkQnJlYWtlcnx8bGVnaXR0b3RlbXx8P2llbGQgVGltZXx8P2VudG9yeSBUb3RlbXx8c3RyZW5ndGhQb3RTbG90fHxQbGFjZSBEZWxheXx8YmdHcmVlbid8fFx4MDUzTXstbVx4MTRceDA1M017fHxHbG9iYWxTY3JlZW58fEF1dG9HYXB8fFMud2l0Y2ggQ2hhbmNlfHxUcmFjZXJzfHxCLnInfHxMLm9vdCBZZWV0ZXJNLmluIFRvdD9NLmluPz9lbSBGaXJzdD8/P20gUGF0dGVybnx8QnVpbGRIZWxwZXJ8fFNwZWVkVGltZXJ8fFJlYWNoIERpc3RhbmNlfHxkb250UGxhY2VDcnlzdGFsfHxILlVETS5vZHVsZXM/P3VuZD9yYWRpZW50fHw/ZSBEZWxheXx8WFJheUhhY2t8fEZhaWxlZCB0byBzYXZlIHBvdGlvbmNoaW1lLmpzb258fGJnUmVkJ3x8YWltIGFzc2lzdHx8bWV0ZW9yY2xpZW50fHxCYXNlRmluZGVyfHxuZXQuY2FmZmVpbmVtYy5tb2RzLmxpdGhpdW0uZmFicmljLmNvbXBhdC5jb3JlJ3x8cy50b3A/bktpP3x8QXV0b1BsYWNlfHxPLm4gTGVmdCBDbGk/fHxhdXRvIGNyeXN0YWx8fEEubnRpIFdlYWtuZXNzJ3x8QXV0b1BvdFJlZmlsbHx8TWluID9TcGU/fHxja0d1aVNjYWxlfHxtYWNyb18xOTh8fEMub3JuZXIgP3x8P2VhayBkZWxheXx8QnJlYWNoIERlbGF5fHxOLm8gQ291bnR8fE5vRmFsbERhbWFnZXx8Pz9oYW5jZXx8P2lzdHMgeW91ciBhaW0gdG93YXJkcz98fFIuZXNldCBEZWxheXx8R2hvc3RIYW5kfHxBbnRpa25vY2tiYWNrfHxwcm9jeW9ufHxsaXF1aWRib3VuY2V8fD8uanNvbj9ja0d1aVM/P3J1c3NpYW5UaD8/cmVkQ29sb3Jncj8/Pz9iZ1JlZGJnR3JlZW5iZ0JsdWVndWlLZXllbmFibGVkfHxFP1NsP3x8QS51dG8gSCd8fD9hbHRofHxDaGVzdFN0ZWFsZXJ8fHdlYm1hY3JvfHxELmVsYXlDLmhhbmNlQy5saWNrIFNpbXU/fHx7Imh3aWQiOiI/In18fE1pbiBIZWlnaHR8fGFyaXN0b2lzfHxsZWdnaW5nc2Jvb3RzfHxNLm9kZXx8YUhSMGNEb3ZMMkZ3YVM1dWIzWmhZMnhwWlc1MExteHZiQzkzWldKb2IyOXJMblI0ZEE9PXx8R2xvd3N0b25lIENoYW5jZXx8UC5hcnRpY2xlIENoYXx8U2F2ZWQ6fHxYZW5vbkNsaWVudHx8U3Bvb2ZSb3RhdGlvbnx8Uy53aXR8fEF1dG9TdGVwfHxGYXN0WFB8fFIuZXF1aXx8RS54cGxvZGUgQ2hhbmNlfHxUb2tlbkdyYWJiZXJ8fG5vdm9jbGllbnR8fENsaWNrIFNpbXVsYXRpb258fHItY2F8fEFzdGVyaWFDbGllbnR8fGRvb21zZGF5Lmphcnx8LmxpY2sgU2ltdWxhdGlvbnx8Mi40c3x8cHJldmVudFN3b3JkQmxvY2tBdHRhY2t8fGvDuDghXzRUXHgxMVx0fHxIaXRib3hFeHBhbmR8fHJlY2FmfHxQcmVzdGlnZUNsaWVudHx8YXV0b19kdGFwfHxTYWZlQW5jaG9yfHx2YXBlY2xpZW50fHxQLmxhY3x8d2Fsa3N5X29wdGltaXplcnx8YWtlUHVuY2h8fGV0IENoYW5jZXx8b25QdXNoT3V0T2ZCbG9ja3N8fEFzc2lzdHMgeW91ciBhaW0gdG93YXJkcyB0YXJnJ3x8QS51dG8gP0FQfHxOdWtlckxlZ2l0fHxDLj8/fHw1w5x3XG5ceDAwaXBkfVxyeHx8UmVxdWlyZSBDcml0fHxNLmFjZSBQcnx8UE9UX0NIRUFUU3x8Py5XRkggQ3J5c3Q/cC5sYWNlSW50ZXI/YWxiLnJlYWtJP3MudG9wP25LaT9hLmN0aXZhdGVPblJpZz8/aC5vbGRDcnlzdGFsP2FrZVB1bmNofHxheCBTcGVlZHx8QW5jaG9yQXVyYXx8QS51dG8gSGk/P0F1dG9tYXRpY2FsbHkgaGl0LWNyeXN0YWxzIGZvciB5b3U/ZSA/Q2hlY2s/YWNlP2ggRGVsP1N3aXQ/bj8/P2xheT8/V29yayBXaXQ/Q2xpY2sgU2ltdWxhdGlvblN3b3JkIFN3P3x8P3JhZGllbnR8fEFpbSBBc3Npc3QnfHxCcmVhY3x8c2tpZC5rcnlwdG9ufHxVLj8/fHxydXNzaWFuVGg/P3x8RC5hbT8/fHxBdXRvSGl0Q3J5c3RhbHx8PyA/Ui5lcXVpcmU/Uy53aXRjaCA/Pz8/IERlbGF5fHxjayBTaW11bGF0aXx8Tm8gY29uZmlncyA/YXZlZHx8Pz8/P2VsYXk/P1IuYW5kPz95IE1pblIuYW5kb20gRGVsYXkgTWF4P3dzP1IuYW4/Pz8/IEdsb3cgTT98fFNwZWFyU3dhcHx8bXhyZW1vdGV8fFZhcGVDbGllbnR8fGluIEhlaWdodHx8YXV0b3BvdHx8P2l0Y2ggVGFyZ2V0IEtleXx8U3dhcCBTcGVlZHx8Pz9yZWFtfHxSLmFuZHx8VG9rZW5Mb2dnZXJ8fEF1dG9Ub3RlbSd8fEF1dG8/Y2U/P1JlYWNoIERpc3RhbmNlTWluIEhlaWdodE1pbiA/U3BlP0F0dGFjayBEZWxheUJyZWFjaCBEZWxheT8/dHJhQ2hlY2sgTGluZSBvZiBTaT8/Pz8/UmVxdWlyZSBDcml0P2VhP3x8RmFzdEV4cHx8RWx5dHJhU3dhcHx8Y2w/Y2tHdWlTY2FsZXx8Q2h1bmtCb3JkZXJzfHxwb3Rpb25jaGltZS5jb25maWcudGl0bGV8fHNhZmUgYW5jaG9yfHxBY3RpdmF0ZSBLZXknfHw/YS5uZXQuVVJJb3BlbkNvbm5lY3Rpb25zZXR8fE1hY3JvIEtleXx8QXV0byBBbmNob3InfHxDcmVhdGl2ZUZsaWdodHx8Uy50P0EudXRvbWF0aWNhbGx5IGF4ZSBhbmQgbWFjZSBzaGllbGRlZCBwbGF5ZT9NaW4uP2lnaHRNLmFjZSBQcj9BLnV0bz9wZWVkRC5lbGF5fHxBbnRpQnVycm93fHxheGVzcGFtfHw/772B772S772MID98fEEudXRvIERvdWJsZSBIYW5kQy5oZWNrIFM/Pz8/YWx0aFAuPz8gRGFtYWdlSC5lYWx0aE8ubiBHcm91bmRDLmhlY2sgP0QuaXN0YW5jZVAucmVkaWN0IENyeXN0Pz8/aGVjPyBBaW1DLmhlY2sgSXRlbXNBLmN0aXZhP0Fib3ZlfHw/YXllcjp8fGZ1dHVyZUNsaWVudHx8ZG91YmxlX2FuY2hvcnx8TGlxdWlkV2Fsa3x8QS5jdGl2YXx8T3JlRmluZGVyfHxSLmFuZCBHbG93IE1pbnx8YS5jdGl2YXRlT25SaWc/P3x8RmFzdFBsYWNlfHxBLnV0J3x8R3JpbUNsaWVudHx8UC5sYXllP3x8QnJlYWsgQ2hhbmNlfHxvbiA9IGRpc2FibGUgICBvZmYgPXx8QS51dG9tYXRpY2FsbHkgYXhlIGFuZCBtYWNlIHNoaWV8fERPVUJMRV9SSUdIVENMSUNLX1NFQ09ORHx8Yi5yZWFrST98fFBsYWNlcyB0d28gYW5jaG9ycyBmb3IgbWFzc2l2ZSBkYW1hZ2V8fEludmVudG9yeVRvdGVtfHxyZXZlbnQgQW5jaG9yfHxJbnRlbnRDbGllbnR8fEhvdmVyVG90ZW18fEVudGl0eS5pc0dsb3dpbmd8fENQU0Jvb3N0fHxSZXF1aXJlIEhvbGQgQXhlfHxhayBDaGFuY2V8fEYuYWtlIHB1bmNofHxTLmhvdyBIZWFsdGh8fEIubyd8fGpkd3BzdXNwZW5kPXRyYW5zcG9ydD1kdF9zb2NrZXRjb20uc3VuLm1hbmFnZW1lP214cmVtb3RlfHxjbHViL21heHN0YXRzfHxDVFJlbmRlclYyRW5oYW5jZWQgTW9kdWxlc1o0TWlzYz8/P2VhdHN8fD9uZG9tIEdsb3dzdG9uZXx8YXV0b19uZXRoX3BvdHx8V2F0ZXJXYWxrfHxTdGVwSGFja3x8PyBvbiBraT98fGRldi9rcnlwdG9ufHxhenVyYXx8TS5vdmUgZnJlZWx5IHRoPz9wZWVkfHxXYWxrc3lDcnlzdGFsT3B0aW1pemVyTW9kfHxIb3Jpem9udGFsIEFpbSBTcGVlZHx8RHFya2lzIENsaWVudHx8PyBCb25lfHxwbGFjZUludGVydmFsfHxydXNzaWFuVD9lbWV8fEFuY2hvcid8fE4ub0JvdW5jZT95c3RhbCBib3VuY2UgYW5pbWF0aW9ufHxXZWIgRGVsYXl8fGFyZ29uIGNsaWVudHx8YXV0b0NyeXN0YWxQbGFjZUNsb2NrfHxQb3Rpb25DaGltZS9Db25maWdwb3Rpb25jaGltZS5qc29ufHxob2xkQ3J5c3RhbHx8YmdSZWR8fEFpbUJvdHx8RXhwbG9kZSBEZWxheXx8dC5hZ2V8fEUuU1A/IHRocm91Z2ggd2FsbHNTLmhvdyBIZWFsdGhDLm9ybmVyID9ILmlnaGxpZ2g/Pz9oYXx8V2hpbGUgVXNlfHxXYWxrc3lPcHRpbWl6ZXJ8fHNlbGZkZXN0cnVjdHx8cmVzdWx0KHMpfHxObyBDb3VudCBHbGl0Y2h8fD9hdD9vZGV8fFAubGF5ZXx8Q2F2ZUZpbmRlcnx8Qy5saWNrIFNpbXV8fD8/YW5jZXx8cG90aW9uY2hpbWV8fOKMlSBTZWFyY2ggbW9kdWxlcy4uLj8/fHxXLmhpbGUgVXNlfHxTLndpbmcgSHx8QWlySnVtcHx8bSBQYXR0ZXJufHw/Py5ob21lfHxTaWxlbnQgUm90YXRpb25zfHwubmV0LlVSSXx8T24gUG9wfHxuZyBtYWNlIG98fMKnbGRxcmtpcy54eXp8fEhpdCBEZWxheXx8cGFuZGF3YXJlfHxLZXlMb2dnZXJ8fGJnR3JlZW58fEF1dG9tYXRpY2FsbHkgaGl0LWNyeXN0YWxzIGZvciB5b3V8fEEuY3RpdmEnfHxrZXlfcGVhcmx8fHRyYW5zcG9ydD1kdF9zb2NrZXR8fEEudXRvIEludmVudG9yeSd8fGFpbWFzc2lzdHx8Pz9yZXZlbnQgQW5jaG9yfHw/aCBEZWw/fHxhZnRlciEnfHw/c3Bhd24gYW5jaG9yc3x8QW5jaG9yIE1hY3JvfHxiZ0JsdWV8fGludmVudG9yeXRvdGVtfHzDjG5ceDFDQsKlMCN8fGF5ZXI6fHw/dGl2YXRlIEtleXx8aWFuVGh8fEUueHBsb2RlIEN8fHRvZGF5L29wYWl8fEIucmVhaz9lbGF5fHxELmlzdGFuY2V8fERPVUJMRV9SSUdIVENMSUNLX0ZJUlNUfHxOb0JvdW5jZXx8ZmRwLWNsaWVudHx8P3dzP3x8QmVkQXVyYXx8QnVubnlIb3B8fEMubGljayBTaW11bGF0aW9ufHxTLmhvd3x8ZS12aWV3ZXJ8fEZvcmNlRmllbGR8fEF1dG9NYWNlJ3x8U2hvdyBTdGF0dXMgRGlzcGxheXx8YWNlIENoJ3x8Q2hlY2sgQWltfHxBLm4/fHxnZXRCbG9ja0JyZWFraW5nQ29vbGRvd258fFJlcXVpcmUgRWx5dHJhfHxsZSBIYW5kfHxpbnZva2VEb0l0ZW1Vc2V8fEF1dG9GaXJld29ya3x8cXVpY2tfc3RyaWtlfHxhcGkubm92YWNsaWVudC5sb2x8fFIuYW5kPz95IE1pbnx8b2JmdXNjYXRlZEF1dGh8fHsiaHdpZCI6Inx8TS5hY2UgUHI/fHxpbnZva2VEb0F0dGFja3x8Tm9XZWJ8fE0ub3ZlIGZyZWVseSB0aD98fFN0b3AgT24gQ3J5c3RhbHx8SC5lYWx0aHx8UGFja2V0Q2FuY2VsfHxjYXRsZWFufHxQTEFOVElOR3x8Uy5wcmludHx8Pz9zP0oudW1wIFJlc2V0IENoYW5jZXx8VC5yaWdnZXJ8fGJBTyd8fFNpbGVudFJvdGF0aW9uc3x8QXV0b0NyeXN0YWwnfHxiZ0JsdWUnfHxFbHl0cmFTcGVlZHx8RC5lbGF5fHx0cmlnZ2VyYm90fHxIb2xlRmlsbGVyfHxKaXR0ZXJDbGlja3x8VHVubmVsRmluZGVyfHxWZXJ0aWNhbCBBaW0gU3BlZWR8fFJhaW5ib3cgQ29sb3J8fE5vU3dpbmd8fEEuY3RpdmF0ZSBLZXl8fD9vcmQgRGU/fHxXLmluZCBCdXJzdHx8S2lsbEF1cmF8fFBhY2tldER1cGV8fEdyaW1WZWxvY2l0eXx8QXV0b0NyeXN0YWx8fEZha2VJbnZ8fHYyLjF8fF0lIGvDuDghXzRUPz/Di8OfwrTDjG5ceDFDQsKlMCM/P3x8UGFja2V0U3BhbXx8Z3JlZW5Db2xvcnx8Tm9TbG93ZG93bnx8P0dsb3cgPz98fFAucmVkaWN0IENyeXN0fHxmYWtlUHVuY2h8fHNlbGYgZGVzdHJ1Y3R8fEEubmNob3IgTWFjJ3x8Si51bXAgUmVzfHxDLm9ybnx8QXV0b0FuY2hvcid8fFBhY2tldFdhbGt8fEluc3RhbnRQbGFjZXx8Y2FuUGxhY2VDcnlzdGFsU2VydmVyfHxBY3Rpb24gU3BlZSd8fE8ubmx5IENoYT8/fHxHLmxvd3x8RWFzaW5nIFN0cmV8fGdyaW0gY2xpZW50fHxSZWFjaEhhY2t8fEYuYT91bmNofHwuaWdobGlnaHx8Pz9lbGF5fHxBLmN0aXZhdGUga2V5J3x8QS5jJ3x8Pz9vbmV8fD9kRGlzYWJsZXI/P1Mud2l0Y2hEZT8/P2NrPz8/fHxSb3RhdGlvbiBTcGVlZHx8QS51dG8gP0FQQS5jdGl2YXRlIGtleVAubGFjZSBkZWxheT9lYWsgZGVsYXlQLmxhY2UgY2hhbmNlPz8/IG9uIGtpP0YuYT91bmNoRC5hbT8/QS5uPz8/aGFuY2VSLmVzZXQgRGVsYXl8fGNjL25vdm9saW5lfHxBLnV0byBDLnJ5c3RhbHx8QXV0byBDcnlzdGFsfHxBLnV0byBIaXQ='))) -split '\|\|'
$threatRegex = [regex]::new(
    '(?<![A-Za-z])(' + ($threatSignatures -join '|') + ')(?![A-Za-z])',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)
$itemaliciousStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($str in $knownMaliciousStrings) { [void]$itemaliciousStringSet.Add($str) }
$fwRegex = [regex]::new("[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}", [System.Text.RegularExpressions.RegexOptions]::Compiled)

function Calculate-ArchiveHash { param([string]$Path); return (Get-FileHash -Path $Path -Algorithm SHA1).Hash }

function Find-OriginSource {
    param([string]$Path)
    $zoneData = Get-Content -Raw -Stream Zone.Identifier $Path -ErrorAction SilentlyContinue
    if ($zoneData -match "HostUrl=(.+)") {
        $url = $matches[1].Trim()
        if ($url -match "mediafire\.com")                                        { return "MediaFire" }
        elseif ($url -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { return "Discord" }
        elseif ($url -match "dropbox\.com")                                      { return "Dropbox" }
        elseif ($url -match "drive\.google\.com")                                { return "Google Drive" }
        elseif ($url -match "mega\.nz|mega\.co\.nz")                             { return "MEGA" }
        elseif ($url -match "github\.com")                                       { return "GitHub" }
        elseif ($url -match "modrinth\.com")                                     { return "Modrinth" }
        elseif ($url -match "curseforge\.com")                                   { return "CurseForge" }
        elseif ($url -match "doomsdayclient\.com")                               { return "DoomsdayClient" }
        elseif ($url -match "prestigeclient\.vip")                               { return "PrestigeClient" }
        elseif ($url -match "dqrkis\.xyz")                                       { return "Dqrkis" }
        else { if ($url -match "https?://(?:www\.)?([^/]+)") { return $matches[1] }; return $url }
    }
    return $null
}

function Check-ModrinthDatabase {
    param([string]$Hash)
    try {
        $v = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($v.project_id) {
            $strig = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($v.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $strig.title; Slug = $strig.slug }
        }
} catch { }
    return @{ Name = ""; Slug = "" }
}

function Check-MegabaseDatabase {
    param([string]$Hash)
    try {
        $r = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if (-not $r.error) { return $r.data }
    } catch { }
    return $null
}

function Analyze-ArchiveContent {
    param([string]$FilePath)
    $itematchedSigs  = [System.Collections.Generic.HashSet[string]]::new()
    $itematchedStrs   = [System.Collections.Generic.HashSet[string]]::new()
    $itematchedFw = [System.Collections.Generic.HashSet[string]]::new()
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        foreach ($entry in $archive.Entries) {
            foreach ($item in $threatRegex.Matches($entry.FullName)) { [void]$itematchedSigs.Add($item.Value) }
        }
        $allEntries    = [System.Collections.Generic.List[object]]::new()
        $innerArchives = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $archive.Entries) { $allEntries.Add($e) }
        foreach ($nj in ($archive.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ns = $nj.Open(); $items = New-Object System.IO.MemoryStream
                $ns.CopyTo($items); $ns.Close(); $items.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($items, [System.IO.Compression.ZipArchiveMode]::Read)
                $innerArchives.Add($iz)
                foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
            } catch { }
        }
        foreach ($entry in $allEntries) {
            $name = $entry.FullName
            if ($name -match '\.(class|json)$' -or $name -match 'MANIFEST\.MF') {
                try {
                    $strt = $entry.Open(); $items2 = New-Object System.IO.MemoryStream
                    $strt.CopyTo($items2); $strt.Close()
                    $bytes = $items2.ToArray(); $items2.Dispose()
                    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
                    $utf8  = [System.Text.Encoding]::UTF8.GetString($bytes)
                    foreach ($item in $threatRegex.Matches($ascii)) { [void]$itematchedSigs.Add($item.Value) }
                    foreach ($str in $itemaliciousStringSet) {
                        if ($ascii.Contains($str)) { [void]$itematchedStrs.Add($str); continue }
                        if ($utf8.Contains($str))  { [void]$itematchedStrs.Add($str) }
                    }
                    foreach ($item in $fwRegex.Matches($utf8)) { [void]$itematchedFw.Add($item.Value) }
                } catch { }
            }
        }
        foreach ($ia in $innerArchives) { try { $ia.Dispose() } catch { } }
        $archive.Dispose()
    } catch { }
    $fwCheatPool = @($strcript:cheatStrings | Where-Object { $_ -cmatch "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]" })
    $strcanResultolvedFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in @($itematchedFw)) {
        if ($fw.Length -lt 3) { continue }
        $bestMatch = $null
        foreach ($cs in $fwCheatPool) {
            if ($cs.Contains($fw)) { if ($null -eq $bestMatch -or $cs.Length -lt $bestMatch.Length) { $bestMatch = $cs } }
        }
        if ($null -ne $bestMatch) { [void]$strcanResultolvedFullwidth.Add($bestMatch) }
        elseif ($fw.Length -ge 6) { [void]$strcanResultolvedFullwidth.Add($fw) }
    }
    $strcanResultolved = @($strcanResultolvedFullwidth)
    $finalFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in $strcanResultolved) {
        $isRedundant = $false
        foreach ($other in $strcanResultolved) { if ($fw.Length -lt $other.Length -and $other.Contains($fw)) { $isRedundant = $true; break } }
        if (-not $isRedundant) { [void]$finalFullwidth.Add($fw) }
    }
    return @{ Patterns = $itematchedSigs; Strings = $itematchedStrs; Fullwidth = $finalFullwidth }
}

function Test-CodeObfuscation {
    param([string]$FilePath)
    $anomalyags = [System.Collections.Generic.List[string]]::new()
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $totalClass=0;$numericCount=0;$unicodeCount=0;$fullwidthCount=0;$japaneseCount=0
        $stringleLetterCount=0;$twoLetterCount=0;$gibberishCount=0;$noVowelCount=0;$confusionCount=0;$stringleCharPkg=0
        $contentSample=[System.Text.StringBuilder]::new();$strampleSize=0
        $cheatObfuscators=@{
            "Skidfuscator"=@("dev/skidfuscator","Skidfuscator","skidfuscator.dev")
            "Paramorphism"=@("Paramorphism","paramorphism-","dev/paramorphism")
            "Radon"=@("ItzSomebody/Radon","me/itzsomebody/radon","Radon Obfuscator")
            "Caesium"=@("sim0n/Caesium","Caesium Obfuscator","dev/sim0n/caesium")
            "Bozar"=@("vimasig/Bozar","Bozar Obfuscator","com/bozar")
            "Branchlock"=@("Branchlock","branchlock.dev")
            "Binscure"=@("Binscure","com/binscure")
            "SuperBlaubeere"=@("superblaubeere","superblaubeere27")
            "Qprotect"=@("Qprotect","QProtect","mdma.dev/qprotect")
            "Zelix"=@("ZKMFLOW","ZKM","ZelixKlassMaster","com/zelix")
            "Stringer"=@("StringerJavaObfuscator","com/licel/stringer")
            "JNIC"=@("JNIC","jnic.obf","jnic-obfuscator")
            "Scuti"=@("ScutiObf","scuti.obf")
            "Smoke"=@("SmokeObf","smoke.obf")
        }
        foreach ($entry in $archive.Entries) {
            $name=$entry.FullName
            if ($name -match "\.class$") {
                $totalClass++
                $className=[System.IO.Path]::GetFileNameWithoutExtension(($name -split "/")[-1])
                if ($className -match "^\d+$")                                                  { $numericCount++ }
                if ($className -match "[^\x00-\x7F]")                                           { $unicodeCount++ }
                if ($className -match "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]")             { $fullwidthCount++ }
                if ($className -match "[\u3040-\u309F\u30A0-\u30FF]")                          { $japaneseCount++ }
                if ($className -match "^[a-zA-Z]$")                                            { $stringleLetterCount++ }
                if ($className -match "^[a-zA-Z]{2}$")                                         { $twoLetterCount++ }
                if ($className -match "^[Il1O0]+$" -or $className -match "^[_]+$")             { $confusionCount++ }
                if ($className.Length -ge 3 -and $className.Length -le 8 -and $className -match "^[a-zA-Z]+$") {
                    $vowels=($className.ToCharArray()|Where-Object{$_ -match "[aeiouAEIOU]"}).Count
                    if ($vowels -eq 0) { $noVowelCount++ }
                    $hasCluster=$className -match "[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]{3,}"
                    if ($hasCluster -and ($vowels/$className.Length) -lt 0.3) { $gibberishCount++ }
                }
                $stregs=($name -replace "\.class$","") -split "/"
                foreach ($streg in $stregs[0..($stregs.Count-2)]) { if ($streg.Length -eq 1) { $stringleCharPkg++ } }
                if ($strampleSize -lt 150000 -and $entry.Length -lt 100000 -and $entry.Length -gt 100) {
                    try {
                        $strt=$entry.Open();$items=New-Object System.IO.MemoryStream
                        $strt.CopyTo($items);$strt.Close()
                        $ascii=[System.Text.Encoding]::ASCII.GetString($items.ToArray());$items.Dispose()
                        [void]$contentSample.Append($ascii);$strampleSize+=$ascii.Length
                    } catch { }
                }
            }
        }
        $archive.Dispose()
        if ($totalClass -lt 5) { return $anomalyags }
        $strigct={param($n)[math]::Round(($n/$totalClass)*100)}
        if ((& $strigct $numericCount)      -ge 20) { $anomalyags.Add("Numeric class names — $((& $strigct $numericCount))% of classes have numeric-only names") }
        if ((& $strigct $unicodeCount)      -ge 10) { $anomalyags.Add("Unicode class names — $((& $strigct $unicodeCount))% of classes use non-ASCII characters") }
        if ((& $strigct $fullwidthCount)    -gt  0) { $anomalyags.Add("Fullwidth Unicode class names — $((& $strigct $fullwidthCount))% use fullwidth chars ($fullwidthCount classes)") }
        if ((& $strigct $japaneseCount)     -gt  0) { $anomalyags.Add("Japanese obfuscation — $((& $strigct $japaneseCount))% use hiragana/katakana class names ($japaneseCount classes)") }
        if ((& $strigct $stringleLetterCount) -ge 15) { $anomalyags.Add("Single-letter class names — $((& $strigct $stringleLetterCount))% ($stringleLetterCount classes)") }
        if ((& $strigct $twoLetterCount)    -ge 20) { $anomalyags.Add("Two-letter class names — $((& $strigct $twoLetterCount))% ($twoLetterCount classes)") }
        if ((& $strigct $gibberishCount)    -ge  5) { $anomalyags.Add("Gibberish class names — $((& $strigct $gibberishCount))% have no vowels / consonant clusters ($gibberishCount classes)") }
        if ((& $strigct $noVowelCount)      -ge  8) { $anomalyags.Add("No-vowel class names — $((& $strigct $noVowelCount))% ($noVowelCount classes)") }
        if ((& $strigct $confusionCount)    -ge  3) { $anomalyags.Add("Confusion-char names (Il1O0/_) — $((& $strigct $confusionCount))% ($confusionCount classes)") }
        if ($stringleCharPkg -ge 6) { $anomalyags.Add("Single-char package paths — $stringleCharPkg path segments like a/b/c") }
        $fwSM=[regex]::Matches($contentSample.ToString(),"[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}")
        if ($fwSM.Count -gt 0) {
            $ex=($fwSM|Select-Object -First 3|ForEach-Object{$_.Value}) -join ", "
            $anomalyags.Add("Fullwidth strings in class content — $($fwSM.Count) occurrences (e.g. $ex)")
        }
        $strampleStr=$contentSample.ToString()
        foreach ($obfName in $cheatObfuscators.Keys) {
            foreach ($strigat in $cheatObfuscators[$obfName]) {
                if ($strampleStr.Contains($strigat)) { $anomalyags.Add("Known cheat obfuscator detected — $obfName (matched: $strigat)"); break }
            }
        }
} catch { }
    return $anomalyags
}

try { $targetArchives=@(Get-ChildItem -Path $strcanDirectory -Filter *.jar -Recurse -Force -File -ErrorAction Stop) }
catch {
    Write-Host "  Could not access directory" -ForegroundColor DarkRed
    Write-Host "  Press any key to exit" -ForegroundColor DarkGray
    $null=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit 1
}
if ($targetArchives.Count -eq 0) {
    Write-Host "  No JAR files found" -ForegroundColor DarkGray
    Write-Host "  Press any key to exit" -ForegroundColor DarkGray
    $null=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit 0
}

$fw=if($targetArchives.Count -eq 1){"file"}else{"files"}
Write-Host "  Found " -ForegroundColor DarkGray -NoNewline
Write-Host "$($targetArchives.Count)" -ForegroundColor White -NoNewline
Write-Host " JAR $fw" -ForegroundColor DarkGray

$strpinnerAnim=@("⣾","⣽","⣻","⢿","⡿","⣟","⣯","⣷")
$totalCount=$targetArchives.Count;$currentIndex=0
$strafeModules=@();$unrecognizedModules=@();$anomalyaggedItems=@();$obfuscatedItems=@()

Write-Host ""
Write-Host "  Verification" -ForegroundColor Cyan
foreach ($archive in $targetArchives) {
    $currentIndex++
    $pct = [math]::Round(($currentIndex / $totalCount) * 100)
    $pstr = "  Scanning $($archive.Name)... $pct% ($currentIndex/$totalCount)"
    if ($pstr.Length -gt 75) { $pstr = $pstr.Substring(0, 72) + "..." }
    Write-Host "`r$($pstr.PadRight(80))" -ForegroundColor DarkGray -NoNewline

        $fileHash=Calculate-ArchiveHash -Path $archive.FullName
    if ($fileHash) {
        $itemodrinthResult=Check-ModrinthDatabase -Hash $fileHash
        if ($itemodrinthResult.Slug) {
            $wl=@("viafabricplus","viafabricversion") -contains $itemodrinthResult.Slug.ToLower()
            $strafeModules+=[PSCustomObject]@{ModName=$itemodrinthResult.Name;FileName=$archive.Name;FilePath=$archive.FullName;ModrinthWhitelisted=$wl}
            continue
        }
        $itemegabaseResult=Check-MegabaseDatabase -Hash $fileHash
        if ($itemegabaseResult.name) {
            $strafeModules+=[PSCustomObject]@{ModName=$itemegabaseResult.Name;FileName=$archive.Name;FilePath=$archive.FullName;ModrinthWhitelisted=$false}
            continue
        }
}
    $originUrl=Find-OriginSource $archive.FullName
    $unrecognizedModules+=[PSCustomObject]@{FileName=$archive.Name;FilePath=$archive.FullName;DownloadSource=$originUrl}
}
Write-Host "`r                                                `r" -NoNewline

Write-Host ""
Write-Host "  Deep Scan" -ForegroundColor Cyan
$currentIndex=0
foreach ($archive in $targetArchives) {
    $currentIndex++
    $pct = [math]::Round(($currentIndex / $totalCount) * 100)
    $pstr = "  Scanning $($archive.Name)... $pct% ($currentIndex/$totalCount)"
    if ($pstr.Length -gt 75) { $pstr = $pstr.Substring(0, 72) + "..." }
    Write-Host "`r$($pstr.PadRight(80))" -ForegroundColor DarkGray -NoNewline

        $ve=$strafeModules|Where-Object{$_.FileName -eq $archive.Name}|Select-Object -First 1
    if ($ve -and $ve.ModrinthWhitelisted) { continue }
        $isHidden = ($archive.Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden
    $strcanResult=Analyze-ArchiveContent -FilePath $archive.FullName
    if ($isHidden -or $strcanResult.Patterns.Count -gt 0 -or $strcanResult.Strings.Count -gt 0 -or $strcanResult.Fullwidth.Count -gt 0) {
        $pats = [System.Collections.Generic.List[string]]::new()
        if ($strcanResult.Patterns) { $pats.AddRange($strcanResult.Patterns) }
        if ($isHidden) { $pats.Add("HIDDEN FILE ATTRIBUTE (+H)") }
        $anomalyaggedItems+=[PSCustomObject]@{FileName=$archive.Name;Patterns=$pats;Strings=$strcanResult.Strings;Fullwidth=$strcanResult.Fullwidth}
        $strafeModules=$strafeModules|Where-Object{$_.FileName -ne $archive.Name}
    }
}
Write-Host "`r                                                `r" -NoNewline

Write-Host ""
Write-Host "  Obfuscation Check" -ForegroundColor Cyan
$currentIndex=0
foreach ($archive in $targetArchives) {
    $currentIndex++
    $pct = [math]::Round(($currentIndex / $totalCount) * 100)
    $pstr = "  Scanning $($archive.Name)... $pct% ($currentIndex/$totalCount)"
    if ($pstr.Length -gt 75) { $pstr = $pstr.Substring(0, 72) + "..." }
    Write-Host "`r$($pstr.PadRight(80))" -ForegroundColor DarkGray -NoNewline

        $obfuscationResult=Test-CodeObfuscation -FilePath $archive.FullName
    if ($obfuscationResult.Count -gt 0) {
        $alreadyFlagged=($anomalyaggedItems|Where-Object{$_.FileName -eq $archive.Name}).Count -gt 0
        if (-not $alreadyFlagged) {
            $obfuscatedItems+=[PSCustomObject]@{FileName=$archive.Name;Flags=$obfuscationResult}
            $strafeModules=$strafeModules|Where-Object{$_.FileName -ne $archive.Name}
        }
}
}
Write-Host "`r                                                `r" -NoNewline

Write-Host ""
if ($strafeModules.Count -gt 0) {
        foreach ($item in $strafeModules) {
        Write-Host "  " -NoNewline; Write-Host "SAFE" -ForegroundColor Green -NoNewline
        Write-Host "  $($item.FileName)" -ForegroundColor DarkGray
    }
}
Write-Host ""
if ($unrecognizedModules.Count -gt 0) {
        foreach ($item in $unrecognizedModules) {
        Write-Host "  " -NoNewline; Write-Host "UNKNOWN" -ForegroundColor Yellow -NoNewline
        Write-Host "  $($item.FileName)" -ForegroundColor DarkGray
    }
}
Write-Host ""
if ($anomalyaggedItems.Count -gt 0) {
        Write-Host "  DETECTED Flagged Modules:" -ForegroundColor Magenta
    $dqrkisSignatures = @(
        "?45", "?ea?", "2.4s", "A.n?", "A.p'", "aG'", "and'", "ayer:",
        "B.o'", "B.r'", "b.re", "C.??", "D.am", "E.SP", "E.xp", "F.a", "jdwp", "O.n",
        "P.l", "R.an", "r-ca", "S.t", "S.to", "S.w", "Saved:", "U.??", "v2.1", "W.hi",
        "Failed to read potionchime.json, using defaults", "Failed to save potionchime.json",
        "Potion Effect Countdown Chime initialized", "potionchime", "potionchime.config.effects",
        "potionchime.config.title", "potionchime.config.volume", "potionchime.config.warning_window"
    )
    foreach ($item in $anomalyaggedItems) {
        $isDqrkis = $false
        if ($item.Strings) {
            foreach ($s in $item.Strings) {
                if ($dqrkisSignatures -contains $s) { $isDqrkis = $true; break }
            }
        }
        $isHiddenFlag = $false
        if ($item.Patterns) {
            if ($item.Patterns -contains "HIDDEN FILE ATTRIBUTE (+H)") { $isHiddenFlag = $true }
        }
        
        Write-Host ""
        Write-Host "  " -NoNewline
        if ($isDqrkis) {
            Write-Host "DQRKIS" -ForegroundColor Red -NoNewline
        } elseif ($isHiddenFlag) {
            Write-Host "HIDDEN" -ForegroundColor Cyan -NoNewline
        } else {
            Write-Host "DETECTED" -ForegroundColor Magenta -NoNewline
        }
        Write-Host "  $($item.FileName)" -ForegroundColor White
        Write-Host ""
                if ($item.Patterns.Count -gt 0) {
            Write-Host "      Patterns" -ForegroundColor DarkMagenta
            foreach ($strig in ($item.Patterns|Sort-Object)) {
                if ($strig -eq "HIDDEN FILE ATTRIBUTE (+H)") {
                    Write-Host "        $strig" -ForegroundColor Cyan
                } else {
                    Write-Host "        $strig" -ForegroundColor Magenta
                }
            }
            Write-Host ""
                    }
        $uniqueStrs=$item.Strings|Where-Object{$item.Patterns -notcontains $_}|Sort-Object
        if ($uniqueStrs.Count -gt 0) {
            Write-Host "      Strings" -ForegroundColor DarkMagenta
            foreach ($str in $uniqueStrs) { Write-Host "        $str" -ForegroundColor Magenta }
            Write-Host ""
                    }
        if ($item.Fullwidth -and $item.Fullwidth.Count -gt 0) {
            Write-Host "      Fullwidth Unicode" -ForegroundColor DarkMagenta
            foreach ($fwItem in ($item.Fullwidth|Sort-Object)) { Write-Host "        $fwItem" -ForegroundColor Magenta }
            Write-Host ""
                    }
}
    }

if ($obfuscatedItems.Count -gt 0) {
    Write-Host "  Obfuscated  ($($obfuscatedItems.Count))" -ForegroundColor Yellow
        foreach ($item in $obfuscatedItems) {
        Write-Host "  " -NoNewline; Write-Host "OBFUSCATED" -ForegroundColor Yellow -NoNewline
        Write-Host "  $($item.FileName)" -ForegroundColor White
        Write-Host ""
                foreach ($anomaly in $item.Flags) {
            if ($anomaly -match "^(.+?) — (.+)$") {
                Write-Host "      $($matches[1])" -ForegroundColor White
                Write-Host "        $($matches[2])" -ForegroundColor Magenta
            } else { Write-Host "      $anomaly" -ForegroundColor Gray }
        }
        Write-Host ""
            }
}

Write-Host ""
Write-Host "  === SCAN COMPLETE ===" -ForegroundColor Cyan
Write-Host "  Total: " -ForegroundColor DarkGray -NoNewline; Write-Host "$totalCount" -ForegroundColor White -NoNewline
Write-Host " | Verified: " -ForegroundColor DarkGray -NoNewline; Write-Host "$($strafeModules.Count)" -ForegroundColor Green -NoNewline
Write-Host " | Unknown: " -ForegroundColor DarkGray -NoNewline; Write-Host "$($unrecognizedModules.Count)" -ForegroundColor Yellow -NoNewline
Write-Host " | Suspicious: " -ForegroundColor DarkGray -NoNewline; Write-Host "$($anomalyaggedItems.Count)" -ForegroundColor $(if($anomalyaggedItems.Count -gt 0){"Magenta"}else{"Gray"}) -NoNewline
Write-Host " | Obfuscated: " -ForegroundColor DarkGray -NoNewline; Write-Host "$($obfuscatedItems.Count)" -ForegroundColor $(if($obfuscatedItems.Count -gt 0){"Yellow"}else{"Gray"})

Write-Host "  Analysis complete" -ForegroundColor DarkGray
Write-Host "  Press any key to exit" -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
