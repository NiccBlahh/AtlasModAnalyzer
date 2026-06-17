[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Ensure required assemblies for GUI components are loaded
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Complete UI Structure (Embedding Your Requested Layout) ---
$htmlMarkup = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ModAnalyzer</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  background: #0e0c18;
  color: #c8c4f0;
  font-family: 'JetBrains Mono', monospace;
  font-size: 13px;
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  border-bottom: 1px solid rgba(127,119,221,0.15);
}
.header-left { display: flex; align-items: center; gap: 10px; }
.logo-box {
  width: 28px; height: 28px;
  background: rgba(127,119,221,0.15);
  border: 1px solid rgba(127,119,221,0.3);
  border-radius: 6px;
  display: flex; align-items: center; justify-content: center;
  font-size: 12px; font-weight: 600; color: #9d97e8;
}
.app-name { font-size: 13px; font-weight: 600; color: #c8c4f0; }
.app-ver  { font-size: 11px; color: rgba(168,164,220,0.4); margin-left: 2px; }
.header-right { display: flex; align-items: center; gap: 8px; }
.status-dot {
  width: 7px; height: 7px; border-radius: 50%;
  background: #444;
  transition: background 0.3s;
}
.status-dot.scanning { background: #7f77dd; animation: blink 1s infinite; }
.status-dot.done      { background: #5dcaa5; }
.status-dot.warn      { background: #e24b4a; }
@keyframes blink { 50% { opacity: 0.3; } }
.status-label { font-size: 11px; color: rgba(168,164,220,0.5); }

.main {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.controls {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 14px 20px;
  border-bottom: 1px solid rgba(127,119,221,0.1);
}
.path-input {
  flex: 1;
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(127,119,221,0.2);
  border-radius: 6px;
  color: #c8c4f0;
  font-family: inherit;
  font-size: 12px;
  padding: 8px 12px;
  outline: none;
  transition: border-color 0.2s;
}
.path-input:focus { border-color: rgba(127,119,221,0.5); }
.path-input::placeholder { color: rgba(168,164,220,0.3); }

.btn {
  background: #7f77dd;
  border: none;
  color: #fff;
  padding: 8px 16px;
  border-radius: 6px;
  font-family: inherit;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}
.btn:hover { background: #6b62cb; }
.btn:disabled { background: #333; color: #777; cursor: not-allowed; }

.terminal-container {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  background: #090711;
  margin: 0 20px 20px 20px;
  border-radius: 8px;
  border: 1px solid rgba(127,119,221,0.08);
}
.log-entry { margin-bottom: 4px; white-space: pre-wrap; line-height: 1.5; }
.log-ok { color: #5dcaa5; }
.log-warn { color: #ffb86c; }
.log-danger { color: #e24b4a; font-weight: 600; }
.log-info { color: #8be9fd; }
.log-muted { color: rgba(168,164,220,0.4); }
</style>
</head>
<body>

<div class="header">
  <div class="header-left">
    <div class="logo-box">M</div>
    <div>
      <span class="app-name">Mecz Mod Analyzer</span>
      <span class="app-ver">Lite UI</span>
    </div>
  </div>
  <div class="header-right">
    <div id="statusDot" class="status-dot"></div>
    <div id="statusLabel" class="status-label">Idle</div>
  </div>
</div>

<div class="main">
  <div class="controls">
    <input type="text" id="pathInput" class="path-input" placeholder="Searching for Minecraft directories...">
    <button id="scanBtn" class="btn" onclick="document.title='TRIGGER_SCAN|' + document.getElementById('pathInput').value">Scan Directory</button>
  </div>
  
  <div class="terminal-container" id="terminal">
    <div class="log-entry log-muted">Initializing analyzer engine components... Ready.</div>
  </div>
</div>

<script>
  var term = document.getElementById('terminal');
  var dot = document.getElementById('statusDot');
  var lbl = document.getElementById('statusLabel');
  var btn = document.getElementById('scanBtn');

  function setStatus(state, text) {
    dot.className = "status-dot " + state;
    lbl.innerText = text;
    if(state === 'scanning') { btn.disabled = true; } else { btn.disabled = false; }
  }
  function clearLog() { term.innerHTML = ''; }
  function log(text, styleClass) {
    var div = document.createElement('div');
    div.className = 'log-entry ' + (styleClass || '');
    div.innerText = text;
    term.appendChild(div);
    term.scrollTop = term.scrollHeight;
  }
  function setPath(p) { document.getElementById('pathInput').value = p; }
</script>

</body>
</html>
'@

# --- Scanning Heuristics ---
$SuspiciousPatternsList = @("AimAssist","AutoAnchor","AutoCrystal","AutoTotem","JumpReset","VelocitySpoof","GrimVelocity","KillAura","TriggerBot","CheatBreaker","WalksyOptimizer","WalksyCrystalOptimizerMod","coord[-_ ]?mod")

function Resolve-GamePath {
    $defaultPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    if (Test-Path $defaultPath) {
        $files = Get-ChildItem $defaultPath -Filter *.jar -ErrorAction SilentlyContinue
        if ($files.Count -gt 0) { return @{ Path = $defaultPath; Source = "Standard/Vanilla/Modrinth" } }
    }
    $featherBase = "$env:APPDATA\.feather\profiles"
    if (Test-Path $featherBase) {
        $latestProfile = Get-ChildItem $featherBase -Directory -ErrorAction SilentlyContinue | 
                         Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestProfile) {
            $featherMods = Join-Path $latestProfile.FullName "mods"
            if (Test-Path $featherMods) { return @{ Path = $featherMods; Source = "Feather Client" } }
        }
    }
    return @{ Path = $defaultPath; Source = "Default Context" }
}

function Get-FileSHA1 { param([string]$Path) return (Get-FileHash -Path $Path -Algorithm SHA1 -ErrorAction SilentlyContinue).Hash }

function Query-Modrinth {
    param([string]$Hash)
    try {
        $versionInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($versionInfo.project_id) {
            $projectInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($versionInfo.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $projectInfo.title; Slug = $projectInfo.slug }
        }
    } catch {}
    return @{ Name = ""; Slug = "" }
}

# --- Core Scan Execution Core ---
function Run-ScanOperation {
    param([System.Windows.Forms.WebBrowser]$browser, [string]$targetedPath)

    $InvokeUI = {
        param($func, $argsList)
        if ($browser.Document) { $browser.Document.InvokeScript($func, $argsList) | Out-Null }
    }

    if ([string]::IsNullOrWhiteSpace($targetedPath) -or -not (Test-Path $targetedPath -PathType Container)) {
        &$InvokeUI "setStatus" @("warn", "Directory Invalid")
        &$InvokeUI "log" @("Error: The directory path specified does not exist.", "log-danger")
        return
    }

    &$InvokeUI "setStatus" @("scanning", "Analyzing Content")
    &$InvokeUI "clearLog" $null
    &$InvokeUI "log" @("Scanning path: $targetedPath...", "log-info")

    try {
        $jarFiles = Get-ChildItem -Path $targetedPath -Filter *.jar -Force
    } catch {
        &$InvokeUI "log" @("Error scanning folder: $($_.Exception.Message)", "log-danger")
        &$InvokeUI "setStatus" @("warn", "Execution Error")
        return
    }

    if ($jarFiles.Count -eq 0) {
        &$InvokeUI "log" @("Scan finished: Zero (.jar) modification configurations found.", "log-warn")
        &$InvokeUI "setStatus" @("done", "Finished")
        return
    }

    &$InvokeUI "log" @("Found $($jarFiles.Count) file(s). Cross-referencing signatures...", "log-muted")

    $verifiedCount = 0
    $suspCount = 0
    $unknownCount = 0

    foreach ($jar in $jarFiles) {
        [System.Windows.Forms.Application]::DoEvents() 
        &$InvokeUI "log" @("Checking package entry: $($jar.Name)", "log-muted")
        
        $hash = Get-FileSHA1 -Path $jar.FullName
        if ($hash) {
            $modrinthData = Query-Modrinth -Hash $hash
            if ($modrinthData.Slug) {
                &$InvokeUI "log" @("[OK] Verified (Modrinth): $($modrinthData.Name)", "log-ok")
                $verifiedCount++
                continue
            }
        }
        
        $matchedArray = New-Object System.Collections.Generic.List[string]
        foreach ($pattern in $SuspiciousPatternsList) {
            if ($jar.Name -match $pattern) { $null = $matchedArray.Add($pattern) }
        }

        if ($matchedArray.Count -gt 0) {
            &$InvokeUI "log" @("[!] SUSPICIOUS: $($jar.Name) -> Matched: $($matchedArray -join ', ')", "log-danger")
            $suspCount++
        } else {
            &$InvokeUI "log" @("[?] UNKNOWN: $($jar.Name)", "log-warn")
            $unknownCount++
        }
    }

    &$InvokeUI "log" @("`n========================================`nSCAN COMPLETE SUMMARY`n========================================", "log-info")
    &$InvokeUI "log" @("Verified Secure Mods: $verifiedCount", "log-ok")
    &$InvokeUI "log" @("Flagged Suspicious Items: $suspCount", "log-danger")
    &$InvokeUI "log" @("Unknown/Custom Mods: $unknownCount", "log-warn")
    
    if ($suspCount -gt 0) {
        &$InvokeUI "setStatus" @("warn", "Flags Tripped")
    } else {
        &$InvokeUI "setStatus" @("done", "Scan Clean")
    }
}

# --- GUI Windows Forms Initialization ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Mecz Mod Analyzer"
$form.Width = 800
$form.Height = 600
$form.StartPosition = "CenterScreen"

$webBrowser = New-Object System.Windows.Forms.WebBrowser
$webBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill
$webBrowser.IsWebBrowserContextMenuEnabled = $false
$webBrowser.AllowWebBrowserDrop = $false
$webBrowser.ScriptErrorsSuppressed = $true

$form.Controls.Add($webBrowser)
$webBrowser.DocumentText = $htmlMarkup

# Safe Event Hook: Intercept Document title changes to drop native security constraints
$webBrowser.add_DocumentTitleChanged({
    if ($webBrowser.DocumentTitle -match "^TRIGGER_SCAN\|(.*)") {
        $scanPath = $matches[1]
        $webBrowser.Document.Title = "ModAnalyzer" # reset title
        Run-ScanOperation -browser $webBrowser -targetedPath $scanPath
    }
})

$form.Add_Shown({
    $detection = Resolve-GamePath
    $webBrowser.Document.InvokeScript("setPath", @($detection.Path)) | Out-Null
    $webBrowser.Document.InvokeScript("log", @("Auto-Detected Instance: $($detection.Source)", "log-info")) | Out-Null
})

[System.Windows.Forms.Application]::Run($form)
