[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
 $OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

 $Banner = @"

▄████████     ███      ▄█          ▄████████    ▄████████        ▄▄▄▄███▄▄▄▄    ▄██████▄  ████████▄  
  ███    ███ ▀█████████▄ ███         ███    ███   ███    ███      ▄██▀▀▀███▀▀▀██▄ ███    ███ ███   ▀███ 
  ███    ███    ▀███▀▀██ ███         ███    ███   ███    █▀       ███   ███   ███ ███    ███ ███    ███ 
  ███    ███     ███   ▀ ███         ███    ███   ███             ███   ███   ███ ███    ███ ███    ███ 
▀███████████     ███     ███       ▀███████████ ▀███████████      ███   ███   ███ ███    ███ ███    ███ 
  ███    ███     ███     ███         ███    ███          ███      ███   ███   ███ ███    ███ ███    ███ 
  ███    ███     ███     ███▌    ▄   ███    ███    ▄█    ███      ███   ███   ███ ███    ███ ███   ▄███ 
  ███    █▀     ▄████▀   █████▄▄██   ███    █▀   ▄████████▀        ▀█   ███   █▀   ▀██████▀  ████████▀  
                         ▀                                                                              
             ▄████████ ███▄▄▄▄      ▄████████  ▄█       ▄██   ▄    ▄███████▄     ▄████████    ▄████████ 
            ███    ███ ███▀▀▀██▄   ███    ███ ███       ███   ██▄ ██▀     ▄██   ███    ███   ███    ███ 
            ███    ███ ███   ███   ███    ███ ███       ███▄▄▄███       ▄███▀   ███    █▀    ███    ███ 
            ███    ███ ███   ███   ███    ███ ███       ▀▀▀▀▀███  ▀█▀▄███▀▄▄  ▄███▄▄▄      ▄███▄▄▄▄██▀ 
              ▀███████████ ███   ███ ▀███████████ ███       ▄██   ███   ▄███▀   ▀ ▀▀███▀▀▀     ▀▀███▀▀▀▀   
            ███    ███ ███   ███   ███    ███ ███       ███   ███ ▄███▀         ███    █▄  ▀███████████ 
            ███    ███ ███   ███   ███    ███ ███▌    ▄ ███   ███ ███▄     ▄█   ███    ███   ███    ███ 
            ███    █▀   ▀█   █▀    ███    █▀  █████▄▄██  ▀█████▀   ▀████████▀   ██████████   ███    ███ 
                                              ▀                                              ███    ███ 

"@

Write-Host $Banner -ForegroundColor Magenta
Write-Host "Made with love by @imnicc.dll , love yall <3" -ForegroundColor Magenta
Write-Host ""
Write-Host ("━" * 76) -ForegroundColor DarkCyan
Write-Host

# Input Logic (Restored)
Write-Host "Enter path to the mods folder: " -NoNewline
Write-Host "(press Enter to use default)" -ForegroundColor DarkGray
 $modsPath = Read-Host "PATH"
Write-Host

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "Using default path: $modsPath" -ForegroundColor White
    Write-Host
} else {
    Write-Host "Using custom path: $modsPath" -ForegroundColor White
    Write-Host
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host
    Write-Host "  ╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ║ " -NoNewline -ForegroundColor Red
    Write-Host "✖  FATAL ERROR: INVALID PATH" -NoNewline -ForegroundColor White -BackgroundColor Red
    Write-Host (" " * (51 - "✖  FATAL ERROR: INVALID PATH".Length)) -NoNewline
    Write-Host " ║" -ForegroundColor Red
    Write-Host "  ╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "  ║  The directory does not exist or is inaccessible.          ║" -ForegroundColor Gray
    Write-Host "  ║  Location: " -NoNewline -ForegroundColor Gray
    Write-Host $modsPath.PadRight(44) -NoNewline -ForegroundColor DarkGray
    Write-Host " ║" -ForegroundColor Gray
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host
    # No pause, exit immediately
    exit 1
}

Write-Host "📁 Directory valid." -ForegroundColor Green
Write-Host

 $mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) { $mcProcess = Get-Process java -ErrorAction SilentlyContinue }
if ($mcProcess) {
    try {
        $elapsed = (Get-Date) - $mcProcess.StartTime
        $uptimeStr = "$($elapsed.Hours)h $($elapsed.Minutes)m $($elapsed.Seconds)s"
        Write-Host "Javaw Found , PID : $($mcProcess.Id) , Uptime : $uptimeStr" -ForegroundColor DarkCyan
    } catch { }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

 $suspiciousPatterns = @(
    "AimAssist","AnchorTweaks","AutoAnchor","AutoCrystal","AutoDoubleHand","JDWP.VirtualMachine.AllModules",
    "AutoHitCrystal","AutoPot","AutoTotem","AutoArmor","InventoryTotem",
    "LegitTotem","PingSpoof","SelfDestruct","ShieldBreaker","TriggerBot","AxeSpam","WebMacro",
    "FastPlace","WalskyOptimizer","WalksyOptimizer","walsky.optimizer",
    "WalksyCrystalOptimizerMod","Donut","Replace Mod","ShieldDisabler","SilentAim","Totem Hit",
    "Wtap","FakeLag","BlockESP","dev.krypton","dev/krypton","skid.krypton","skid/krypton","AntiMissClick",
    "LagReach","PopSwitch","SprintReset","ChestSteal","AntiBot","ElytraSwap","FastXP","FastExp","Refill",
    "AirAnchor","jnativehook","FakeInv","HoverTotem","AutoClicker","AutoFirework","PackSpoof",
    "Antiknockback","catlean","AuthBypass","Asteria","Prestige","AutoEat","AutoMine","MaceSwap",
    "Macro198","StunSlam","SafeAnchor","DoubleAnchor","AutoTPA","BaseFinder","Xenon","gypsy",
    "AutoPotRefill","KeyPearl","AutoNethPot","AutoDtap","TriggerBot","AutoWeb","AnchorAction",
    "org.chainlibs.module.impl.modules.Crystal.Y","org.chainlibs.module.impl.modules.Crystal.bF",
    "org.chainlibs.module.impl.modules.Crystal.bM","org.chainlibs.module.impl.modules.Crystal.bY",
    "org.chainlibs.module.impl.modules.Crystal.bq","org.chainlibs.module.impl.modules.Crystal.cv",
    "org.chainlibs.module.impl.modules.Crystal.o","org.chainlibs.module.impl.modules.Blatant.I",
    "org.chainlibs.module.impl.modules.Blatant.bR","org.chainlibs.module.impl.modules.Blatant.bx",
    "org.chainlibs.module.impl.modules.Blatant.cj","org.chainlibs.module.impl.modules.Blatant.dk",
    "imgui.gl3","imgui.glfw","BowAim","Criticals","Fakenick","FakeItem","invsee","ItemExploit",
    "Hellion","hellion","LicenseCheckMixin","ClientPlayerInteractionManagerAccessor",
    "ClientPlayerEntityMixim","dev.gambleclient","obfuscatedAuth","phantom-refmap.json","xyz.greaj",
    "じ.class","ふ.class","ぶ.class","ぷ.class","た.class","ね.class","そ.class","な.class",
    "ど.class","ぐ.class","ず.class","で.class","つ.class","べ.class","せ.class","と.class",
    "み.class","び.class","す.class","の.class"
)

 $cheatStrings = @(
    "AutoCrystal","autocrystal","auto crystal","cw crystal","JDWP.VirtualMachine.AllModules",
    "dontPlaceCrystal","dontBreakCrystal","AutoHitCrystal","autohitcrystal","canPlaceCrystalServer",
    "healPotSlot","ＡｕｔｏＣｒｙｓ","Ａｕｔｏ Ｃｒｙｓ","ＡｕｔｏＨｉｈｏｃ","ＡｕｔｏＨｉｈｏｃ",
    "AutoAnchor","autoanchor","auto anchor","DoubleAnchor","HasAnchor","anchortweaks","anchor macro",
    "safe anchor","safeanchor","SafeAnchor","AirAnchor","Ａｕｔｏ｡ｎｃｈ","Ａｕｔｏ Ａｎｃｈ",
    "ＤｏｕｂｌｅＡｎ","Ｄｏｕｂｌｅ Ａｎｃｈ","Ｓａｆｅｌ＋ｓ","Ｓａｆｅ",
    "AutoTotem","autototem","auto totem","InventoryTotem",
    "inventorytotem","HoverTotem","hover totem","legittotem","ＡｕｔｏＴｏｔｍ","Ａｕｔｏ Ｔｏｔｍ",
    "Ｈｏｖｅ▒ﾝ","Ｈｏｖｅ ▀█","Ｈｏｖｅ ▀█","Ｉｎｖｅｎｔｏｒｙ","Ｉｎｖｅｎ╔Ｓｗｏ▒",
    "AutoPot","autopot","auto pot","speedPotSlot","strengthPotSlot","AutoArmor","autoarmor","auto armor",
    "Ａｕｔｏ","Ａｕｔｏ","Ａｕｔｏ","Ｌｅｆｉｌ","AutoPotRefill",
    "Ａｕｏ","Ａｕｔ","Ａｕｔ","ｐｒｅｅｅｎｔ","Ａｕｔｏ Ａｒｍｏｒ",
    "Ｓｈｉｅｌ","Ｓｈｉｅ","Breaking shield with axe...","AutoDoubleHand","autodoublehand","auto double hand",
    "Ａｕｔｏ","Ａｕｔ","Ａｕｔ","Ａｕｔ","AutoClicker","Ａｕｔｏ｣ｌｉｃｋ",
    "Failed to switch to mace after axe!","AutoMace","MaceSwap","SpearSwap","Ａｕｔｏ","Ｍａｃｅ",
    "Ａｕｏ","Ｍａｃ","Ｍａｃｅ","Ｓｗａｐ","Ｍａｃ",
    "Ａｕｔｏｍａｔｉｃａｌｌｙ ａｘｅ ａｎｄ ｍａｃｅ ｓ",
    "Ｓｔｕｎ Ｓｌａｍ","StunSlam","Donut","JumpReset","axespam","axe spam",
    "findKnockbackSword","attackRegisteredThisClick","AimAssist","aimassist","aim assist",
    "triggerbot","trigger bot","Ａｉｍ","Ａｉ Ａｓｉｓ","Ｔｒｉｇｇ",
    "Silent Rotations","SilentRotations","Ｓｉｌｅ","Ｓｉｌ","FakeInv","swapBackToOriginalSlot",
    "FakeLag","pingspoof","ping spoof","Ｆａｋｅ","Ｆａｋｅ","fakePunch","Fake Punch","Ｆａｋ",
    "mace_swap","quick_strike","macro_198","stun_slam","safe_anchor","double_anchor","auto_pot_refill",
    "walksy_optimizer","key_pearl","aim_assist","auto_neth_pot","auto_dtap","trigger_bot","auto_web",
    "DOUBLE_ESCAPE","DOUBLE_RIGHTCLICK_FIRST","DOUBLE_RIGHTCLICK_SECOND","POST_CYCLE_DELAY",
    "PLACE_OBI","WAIT_OBI","PLACE_CRYSTAL","BREAK_CRYSTAL","ROTATING_DOWN","ROTATING_BACK",
    "REFILLING","PLANTING","BONEMEALING","AnchorAction","Places two anchors for massive damage",
    "REOFFHAND_TOTEM","webmacro","web macro","AntiWeb","AutoWeb","Ａｎｔﾉ Ｗｅ",
    "Ｐｌａｃｅｓ Ｗｅｂｓﾯｎ Ｅｎｅｍｉｅｓ","lvstrng","dqrkis","selfdestruct","self destruct",
    "WalksyCrystalOptimizerMod","WalksyOptimizer","WalskyOptimizer","Ｗａｌｋｓﾙ",
    "autoCrystalPlaceClock","AutoFirework","ElytraSwap","FastXP","FastExp","NoJumpDelay",
    "Ｅｌｙｔｒａ","Ｅｌｙｔｒａ","PackSpoof","Antiknockback","catlean",
    "AuthBypass","obfuscatedAuth","LicenseCheckMixin","BaseFinder","invsee","ItemExploit",
    "FreezePlayer","VirtualMachine","Ｆ▒ｅｅｃﾁ",
    "Ｎｏ Ｃﾌﾉｐ","Ｆｒｅﾚ",
    "ＬＷﾦｨＣｒｙｓｔ","LWFH Crystal","JDWP.VirtualMachine.AllModules",
    "ＬＷﾦＨ","Ｌｏｏ",
    "intent.store","IntentClient","rise.today","riseclient.com","meteor-client","meteorclient",
    "meteordevelopment.meteorclient","liquidbounce","fdp-client","net.ccbluex","novoware",
    "novoclient","aristois","impactclient","azura","pandaware","skilled","moonClient","astolfo",
    "futureClient","konas","rusherhack","inertia","exhibition","dev.krypton","dev/krypton",
    "skid.krypton","skid/krypton","VirginClient","virgin client","catlean","CatleanClient",
    "catlean client","ArgonClient","argon client","Asteria","AsteriaClient","asteria client",
    "Prestige","PrestigeClient","prestige client","prestigeclient.vip","gypsy","GypsyClient",
    "gypsy client","Xenon","XenonClient","xenon client","GrimClient","grim client",
    "phantom-refmap.json","dqrkis.xyz","Dqrkis Client"
)

 $patternRegex = [regex]::new(
    '(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

 $cheatStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $cheatStrings) { [void]$cheatStringSet.Add($s) }

function Get-FileSHA1 {
    param([string]$Path)
    return (Get-FileHash -Path $Path -Algorithm SHA1).Hash
}

function Get-DownloadSource {
    param([string]$Path)
    $zoneData = Get-Content -Raw -Stream Zone.Identifier $Path -ErrorAction SilentlyContinue
    if ($zoneData -match "HostUrl=(.+)") {
        $url = $matches[1].Trim()
        if ($url -match "mediafire\.com")                                         { return "MediaFire" }
        elseif ($url -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { return "Discord" }
        elseif ($url -match "dropbox\.com")                                       { return "Dropbox" }
        elseif ($url -match "drive\.google\.com")                                 { return "Google Drive" }
        elseif ($url -match "mega\.nz|mega\.co\.nz")                              { return "MEGA" }
        elseif ($url -match "github\.com")                                        { return "GitHub" }
        elseif ($url -match "modrinth\.com")                                      { return "Modrinth" }
        elseif ($url -match "curseforge\.com")                                    { return "CurseForge" }
        elseif ($url -match "doomsdayclient\.com")                                { return "DoomsdayClient" }
        elseif ($url -match "prestigeclient\.vip")                                { return "PrestigeClient" }
        elseif ($url -match "dqrkis\.xyz")                                        { return "Dqrkis" }
        else {
            if ($url -match "https?://(?:www\.)?([^/]+)") { return $matches[1] }
            return $url
        }
    }
    return $null
}

function Query-Modrinth {
    param([string]$Hash)
    try {
        $versionInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($versionInfo.project_id) {
            $projectInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($versionInfo.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $projectInfo.title; Slug = $projectInfo.slug }
        }
    } catch { }
    return @{ Name = ""; Slug = "" }
}

function Query-Megabase {
    param([string]$Hash)
    try {
        $result = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if (-not $result.error) { return $result.data }
    } catch { }
    return $null
}

 $fullwidthRegex = [regex]::new(
    "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}",
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

function Invoke-ModScan {
    param([string]$FilePath)
    $foundPatterns  = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings   = [System.Collections.Generic.HashSet[string]]::new()
    $foundFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        foreach ($entry in $archive.Entries) {
            foreach ($m in $patternRegex.Matches($entry.FullName)) { [void]$foundPatterns.Add($m.Value) }
        }
        $allEntries    = [System.Collections.Generic.List[object]]::new()
        $innerArchives = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $archive.Entries) { $allEntries.Add($e) }
        foreach ($nj in ($archive.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ns = $nj.Open(); $ms = New-Object System.IO.MemoryStream
                $ns.CopyTo($ms); $ns.Close(); $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $innerArchives.Add($iz)
                foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
            } catch { }
        }
        foreach ($entry in $allEntries) {
            $name = $entry.FullName
            if ($name -match '\.(class|json)$' -or $name -match 'MANIFEST\.MF') {
                try {
                    $st = $entry.Open(); $ms2 = New-Object System.IO.MemoryStream
                    $st.CopyTo($ms2); $st.Close()
                    $bytes = $ms2.ToArray(); $ms2.Dispose()
                    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
                    $utf8  = [System.Text.Encoding]::UTF8.GetString($bytes)
                    foreach ($m in $patternRegex.Matches($ascii)) { [void]$foundPatterns.Add($m.Value) }
                    foreach ($s in $cheatStringSet) {
                        if ($ascii.Contains($s)) { [void]$foundStrings.Add($s); continue }
                        if ($utf8.Contains($s))  { [void]$foundStrings.Add($s) }
                    }
                    foreach ($m in $fullwidthRegex.Matches($utf8)) { [void]$foundFullwidth.Add($m.Value) }
                } catch { }
            }
        }
        foreach ($ia in $innerArchives) { try { $ia.Dispose() } catch { } }
        $archive.Dispose()
    } catch { }

    $fwCheatPool = @($script:cheatStrings | Where-Object { $_ -cmatch "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]" })
    $resolvedFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in @($foundFullwidth)) {
        if ($fw.Length -lt 3) { continue }
        $bestMatch = $null
        foreach ($cs in $fwCheatPool) {
            if ($cs.Contains($fw)) {
                if ($null -eq $bestMatch -or $cs.Length -lt $bestMatch.Length) { $bestMatch = $cs }
            }
        }
        if ($null -ne $bestMatch) { [void]$resolvedFullwidth.Add($bestMatch) }
        elseif ($fw.Length -ge 6) { [void]$resolvedFullwidth.Add($fw) }
    }
    $resolved = @($resolvedFullwidth)
    $finalFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in $resolved) {
        $isRedundant = $false
        foreach ($other in $resolved) {
            if ($fw.Length -lt $other.Length -and $other.Contains($fw)) { $isRedundant = $true; break }
        }
        if (-not $isRedundant) { [void]$finalFullwidth.Add($fw) }
    }
    return @{ Patterns = $foundPatterns; Strings = $foundStrings; Fullwidth = $finalFullwidth }
}

function Invoke-ObfuscationScan {
    param([string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $totalClass=0; $numericCount=0; $unicodeCount=0; $fullwidthCount=0; $japaneseCount=0
        $singleLetterCount=0; $twoLetterCount=0; $gibberishCount=0; $noVowelCount=0
        $confusionCount=0; $singleCharPkg=0
        $contentSample = [System.Text.StringBuilder]::new(); $sampleSize = 0
        $cheatObfuscators = @{
            "Skidfuscator"   = @("dev/skidfuscator","Skidfuscator","skidfuscator.dev")
            "Paramorphism"   = @("Paramorphism","paramorphism-","dev/paramorphism")
            "Radon"          = @("ItzSomebody/Radon","me/itzsomebody/radon","Radon Obfuscator")
            "Caesium"        = @("sim0n/Caesium","Caesium Obfuscator","dev/sim0n/caesium")
            "Bozar"          = @("vimasig/Bozar","Bozar Obfuscator","com/bozar")
            "Branchlock"     = @("Branchlock","branchlock.dev")
            "Binscure"       = @("Binscure","com/binscure")
            "SuperBlaubeere" = @("superblaubeere","superblaubeere27")
            "Qprotect"       = @("Qprotect","QProtect","mdma.dev/qprotect")
            "Zelix"          = @("ZKMFLOW","ZKM","ZelixKlassMaster","com/zelix")
            "Stringer"       = @("StringerJavaObfuscator","com/licel/stringer")
            "JNIC"           = @("JNIC","jnic.obf","jnic-obfuscator")
            "Scuti"          = @("ScutiObf","scuti.obf")
            "Smoke"          = @("SmokeObf","smoke.obf")
        }
        foreach ($entry in $archive.Entries) {
            $name = $entry.FullName
            if ($name -match "\.class$") {
                $totalClass++
                $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split "/")[-1])
                if ($className -match "^\d+$")                                                       { $numericCount++ }
                if ($className -match "[^\x00-\x7F]")                                                { $unicodeCount++ }
                if ($className -match "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]")                  { $fullwidthCount++ }
                if ($className -match "[\u3040-\u309F\u30A0-\u30FF]")                               { $japaneseCount++ }
                if ($className -match "^[a-zA-Z]$")                                                  { $singleLetterCount++ }
                if ($className -match "^[a-zA-Z]{2}$")                                               { $twoLetterCount++ }
                if ($className -match "^[Il1O0]+$" -or $className -match "^[_]+$")                  { $confusionCount++ }
                if ($className.Length -ge 3 -and $className.Length -le 8 -and $className -match "^[a-zA-Z]+$") {
                    $vowels = ($className.ToCharArray() | Where-Object { $_ -match "[aeiouAEIOU]" }).Count
                    if ($vowels -eq 0) { $noVowelCount++ }
                    $hasCluster = $className -match "[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]{3,}"
                    if ($hasCluster -and ($vowels / $className.Length) -lt 0.3) { $gibberishCount++ }
                }
                $segs = ($name -replace "\.class$","") -split "/"
                foreach ($seg in $segs[0..($segs.Count-2)]) { if ($seg.Length -eq 1) { $singleCharPkg++ } }
                if ($sampleSize -lt 150000 -and $entry.Length -lt 100000 -and $entry.Length -gt 100) {
                    try {
                        $st = $entry.Open(); $ms = New-Object System.IO.MemoryStream
                        $st.CopyTo($ms); $st.Close()
                        $ascii = [System.Text.Encoding]::ASCII.GetString($ms.ToArray()); $ms.Dispose()
                        [void]$contentSample.Append($ascii); $sampleSize += $ascii.Length
                    } catch { }
                }
            }
        }
        $archive.Dispose()
        if ($totalClass -lt 5) { return $flags }
        $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }
        $numPct  = & $pct $numericCount;  $uniPct  = & $pct $unicodeCount;  $fwPct = & $pct $fullwidthCount
        $jpPct   = & $pct $japaneseCount; $s1Pct   = & $pct $singleLetterCount; $s2Pct = & $pct $twoLetterCount
        $gibPct  = & $pct $gibberishCount; $novPct = & $pct $noVowelCount; $confPct = & $pct $confusionCount
        if ($numPct  -ge 20) { $flags.Add("Numeric class names — $numPct% of classes have numeric-only names") }
        if ($uniPct  -ge 10) { $flags.Add("Unicode class names — $uniPct% of classes use non-ASCII characters") }
        if ($fwPct   -gt  0) { $flags.Add("Fullwidth Unicode class names — $fwPct% use fullwidth chars ($fullwidthCount classes)") }
        if ($jpPct   -gt  0) { $flags.Add("Japanese obfuscation — $jpPct% use hiragana/katakana names ($japaneseCount classes)") }
        if ($s1Pct   -ge 15) { $flags.Add("Single-letter class names — $s1Pct% ($singleLetterCount classes)") }
        if ($s2Pct   -ge 20) { $flags.Add("Two-letter class names — $s2Pct% ($twoLetterCount classes)") }
        if ($gibPct  -ge  5) { $flags.Add("Gibberish class names — $gibPct% have no vowels/consonant clusters ($gibberishCount classes)") }
        if ($novPct  -ge  8) { $flags.Add("No-vowel class names — $novPct% ($noVowelCount classes)") }
        if ($confPct -ge  3) { $flags.Add("Confusion-char names (Il1O0/_) — $confPct% ($confCount classes)") }
        if ($singleCharPkg -ge 6) { $flags.Add("Single-char package paths — $singleCharPkg path segments like a/b/c") }
        $fwStringMatches = [regex]::Matches($contentSample.ToString(), "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}")
        if ($fwStringMatches.Count -gt 0) {
            $examples = ($fwStringMatches | Select-Object -First 3 | ForEach-Object { $_.Value }) -join ", "
            $flags.Add("Fullwidth strings in class content — $($fwStringMatches.Count) occurrences (e.g. $examples)")
        }
        $sampleStr = $contentSample.ToString()
        foreach ($obfName in $cheatObfuscators.Keys) {
            foreach ($pat in $cheatObfuscators[$obfName]) {
                if ($sampleStr.Contains($pat)) { $flags.Add("Known cheat obfuscator detected — $obfName (matched: $pat)"); break }
            }
        }
    } catch { }
    return $flags
}

function Invoke-JvmScan {
    # Integrated JVM Argument Scanner Logic
    $sep = "━" * 76
    Write-Host $sep -ForegroundColor Yellow
    Write-Host "JVM ARGUMENTS INJECTION SCANNER" -ForegroundColor Yellow
    Write-Host $sep -ForegroundColor Yellow
    Write-Host ""

    $javaProcesses = Get-Process -Name javaw -ErrorAction SilentlyContinue
    if ($javaProcesses.Count -eq 0) {
        Write-Host "  [!] No javaw.exe processes found" -ForegroundColor Yellow
        Write-Host "  [i] Make sure Minecraft is running`n" -ForegroundColor Yellow
    } else {
        Write-Host "  [i] Scanning $($javaProcesses.Count) Java process(es)...`n" -ForegroundColor White
        $foundInjection = $false

        $fabricPatterns = @{
            "fabric.addMods"='-Dfabric\.addMods='; "fabric.loadMods"='-Dfabric\.loadMods='; "fabric.classPathGroups"='-Dfabric\.classPathGroups='; "fabric.gameJarPath"='-Dfabric\.gameJarPath='; "fabric.skipMcProvider"='-Dfabric\.skipMcProvider='; "fabric.development"='-Dfabric\.development='; "fabric.allowUnsupportedVersion"='-Dfabric\.allowUnsupportedVersion='; "fabric.remapClasspathFile"='-Dfabric\.remapClasspathFile='; "fabric.skipIntermediary"='-Dfabric\.skipIntermediary='; "fabric.configDir"='-Dfabric\.configDir='; "fabric.loader.config"='-Dfabric\.loader\.config='; "fabric.log.level"='-Dfabric\.log\.level='; "fabric.debug.dumpClasspath"='-Dfabric\.debug\.dumpClasspath='; "fabric.log.config"='-Dfabric\.log\.config='; "fabric.dli.config"='-Dfabric\.dli\.config='; "fabric.mixin.configs"='-Dfabric\.mixin\.configs='; "fabric.mixin.hotSwap"='-Dfabric\.mixin\.hotSwap='; "fabric.mixin.debug.export"='-Dfabric\.mixin\.debug\.export='; "fabric.mixin.debug.verbose"='-Dfabric\.mixin\.debug\.verbose='; "fabric.gameVersion"='-Dfabric\.gameVersion='; "fabric.forceVersion"='-Dfabric\.forceVersion='; "fabric.autoDetectVersion"='-Dfabric\.autoDetectVersion='; "fabric.launcher.name"='-Dfabric\.launcher\.name='; "fabric.launcher.brand"='-Dfabric\.launcher\.brand='; "fabric.mods.toml.path"='-Dfabric\.mods\.toml\.path='; "fabric.customModList"='-Dfabric\.customModList='; "fabric.resolve.modFiles"='-Dfabric\.resolve\.modFiles='; "fabric.skipDependencyResolution"='-Dfabric\.skipDependencyResolution='; "fabric.loader.entrypoints"='-Dfabric\.loader\.entrypoints='; "fabric.language.providers"='-Dfabric\.language\.providers=';
            "forge.addMods"='-Dforge\.addMods='; "forge.mods"='-Dforge\.mods='; "fml.coreMods.load"='-Dfml\.coreMods\.load='; "forge.coreMods.dir"='-Dforge\.coreMods\.dir='; "forge.modDir"='-Dforge\.modDir='; "forge.modsDirectories"='-Dforge\.modsDirectories='; "fml.customModList"='-Dfml\.customModList='; "forge.disableModScan"='-Dforge\.disableModScan='; "forge.modList"='-Dforge\.modList='; "forge.forceVersion"='-Dforge\.forceVersion='; "forge.disableUpdateCheck"='-Dforge\.disableUpdateCheck='; "forge.logging.mojang.level"='-Dforge\.logging\.mojang\.level='; "forge.mixin.hotSwap"='-Dforge\.mixin\.hotSwap='; "forge.resourcePack"='-Dforge\.resourcePack='; "forge.defaultResourcePack"='-Dforge\.defaultResourcePack='; "forge.texturePacks"='-Dforge\.texturePacks='; "forge.assetIndex"='-Dforge\.assetIndex='; "forge.assetsDir"='-Dforge\.assetsDir=';
            "javaSecurityManager"='-Djava\.security\.manager='; "javaSecurityPolicy"='-Djava\.security\.policy='; "bootClasspath"='-Xbootclasspath'; "systemClassLoader"='-Djava\.system\.class\.loader='; "javaClassPath"='-Djava\.class\.path='; "cp"='-cp\s+["''][^"'';]*\.jar';
            "cheatClientBrand"='-D(client|launcher)\.brand=(Wurst|Aristois|Impact|Kilo|Future|Lambda|Rusher|Konas|Phobos|Salhack|ForgeHax|Mathax|Meteor|Async|Seppuku|Xatz|Wolfram|Huzuni|Jigsaw|Zamorozka|Moon|Rage|Exhibition|Virtue|Novoline|Rekt|Skid|Ares|Abyss|Thunder|Tenacity|Rise|Flux|Gamesense|Intent|Remix|Sight|Vape|Shield|Ghost|Crispy|Inertia)';
            "optifine"='-Doptifine\.'; "shadersmod"='-Dshaders?\.'; "shaderPack"='-Dshader[sP]ack='; "cheatPattern"='-D(xray|fly|speed|killaura|reach|esp|wallhack|noclip|autoclick|aimbot|triggerbot|antiknockback|nofall|timer|step|fullbright|nightvision|cavefinder)\.'
        }
        $cheatClients = @('Wurst','Aristois','Impact','Kilo','Future','Lambda','Rusher','Konas','Phobos','Salhack','ForgeHax','Mathax','Meteor','Async','Seppuku','Xatz','Wolfram','Huzuni','Jigsaw','Zamorozka','Moon','Rage','Exhibition','Virtue','Novoline','Rekt','Skid','Ares','Abyss','Thunder','Tenacity','Rise','Flux','Gamesense|Intent|Remix|Sight|Vape','Shield','Ghost','Crispy','Inertia')

        foreach ($proc in $javaProcesses) {
            try {
                $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction Stop).CommandLine
                if (-not $cmdLine) { continue }
                Write-Host "  ┌─ Process: PID $($proc.Id) - $($proc.ProcessName)" -ForegroundColor Green
                if ($cmdLine -match '^"([^"]+)"') { $cmdLine = $cmdLine.Substring($matches[1].Length + 2).Trim() }

                $detectedPatterns = @(); $suspiciousArgs = @()
                foreach ($k in $fabricPatterns.Keys) {
                    if ($k -eq "addOpens" -or $k -eq "addExports") { continue }
                    if ($cmdLine -match $fabricPatterns[$k]) {
                        $detectedPatterns += $k
                        $suspiciousArgs += ($cmdLine -split '\s+' | Where-Object { $_ -match $fabricPatterns[$k] })
                    }
                }
                foreach ($cc in $cheatClients) {
                    if ($cmdLine -match "(?i)\b$cc\b" -and $detectedPatterns -notcontains "CheatClient-$cc") { $detectedPatterns += "CheatClient-$cc" }
                }
                if ($cmdLine -match '(%3B|%26%26|%7C%7C|%7C|%60|%24|%3C|%3E)') { $detectedPatterns += "EncodedInjection" }

                if ($detectedPatterns.Count -gt 0) {
                    $foundInjection = $true
                    Write-Host "  ├─ [✗] JVM INJECTION DETECTED`n" -ForegroundColor Red
                    Write-Host "  │  Detected JVM Arguments:" -ForegroundColor Yellow
                    $suspiciousArgs | Select-Object -Unique | ForEach-Object { Write-Host "  │    • $_" -ForegroundColor Magenta }
                    Write-Host "`n  │  Detected Pattern Categories:" -ForegroundColor Yellow
                    $grouped = @{}
                    foreach ($p in $detectedPatterns) {
                        $t = if ($p -match "^(fabric|forge|javaSecurity|bootClasspath|systemClassLoader|javaClassPath|cp|cheatClient|optifine|shadersmod|shaderPack|cheatPattern|EncodedInjection)") { $matches[1] } else { "other" }
                        if (-not $grouped[$t]) { $grouped[$t] = @() }
                        $grouped[$t] += $p
                    }
                    $typeMap = @{ fabric="Fabric Injection"; forge="Forge Injection"; javaSecurity="Security Bypass"; bootClasspath="Classpath Manipulation"; systemClassLoader="Class Loader"; javaClassPath="Class Path"; cp="Classpath (-cp)"; cheatClient="Cheat Client"; optifine="Optifine/Shaders"; shadersmod="Shader Mod"; shaderPack="Shader Pack"; cheatPattern="Cheat Pattern"; EncodedInjection="Encoded Injection"; other="Other" }
                    foreach ($t in $grouped.Keys | Sort-Object) {
                        Write-Host "  │    └─ $($typeMap[$t])" -ForegroundColor White
                        $grouped[$t] | ForEach-Object { Write-Host "  │        • $($_ -replace 'CheatClient-','')" -ForegroundColor Red }
                    }
                    Write-Host "`n  └─ ⚠ WARNING: Potential cheat client or mod injection detected!`n" -ForegroundColor Red
                } else {
                    Write-Host "  └─ [✓] No JVM injection patterns detected`n" -ForegroundColor Green
                }
            } catch {
                Write-Host "  └─ [!] Warning: Could not retrieve command line for PID $($proc.Id)" -ForegroundColor DarkYellow
                Write-Host "      [i] Run as Administrator for complete detection.`n" -ForegroundColor DarkYellow
            }
        }
        if (-not $foundInjection) { Write-Host "  [✓] CLEAN: No JVM argument injections detected in any Java process" -ForegroundColor Green }
    }
}

function Write-Rule { param([string]$Char="─",[int]$Width=76,[ConsoleColor]$Color="DarkGray"); Write-Host ($Char*$Width) -ForegroundColor $Color }

function Write-SectionHeader {
    param([string]$Title,[int]$Count,[ConsoleColor]$DotColor,[ConsoleColor]$CountColor)
    Write-Host ""; Write-Host "  " -NoNewline
    Write-Host "●" -ForegroundColor $DotColor -NoNewline
    Write-Host "  $Title  " -ForegroundColor White -NoNewline
    Write-Host "($Count)" -ForegroundColor $CountColor; Write-Host ""
}

function Write-SuspiciousCard {
    param($Mod)
    Write-Host ("  " + ("─"*70)) -ForegroundColor DarkRed
    Write-Host "  │ " -ForegroundColor DarkRed -NoNewline
    Write-Host " FLAGGED " -ForegroundColor White -BackgroundColor DarkRed -NoNewline
    Write-Host "  " -NoNewline; Write-Host $Mod.FileName -ForegroundColor Yellow
    Write-Host ("  │ " + ("─"*66)) -ForegroundColor DarkRed
    if ($Mod.Patterns.Count -gt 0) {
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  │  " -ForegroundColor DarkRed -NoNewline; Write-Host "PATTERNS" -ForegroundColor DarkGray
        foreach ($p in ($Mod.Patterns | Sort-Object)) { Write-Host "  │    " -ForegroundColor DarkRed -NoNewline; Write-Host $p -ForegroundColor Red }
    }
    $uniqueStrings = $Mod.Strings | Where-Object { $Mod.Patterns -notcontains $_ } | Sort-Object
    if ($uniqueStrings.Count -gt 0) {
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  │  " -ForegroundColor DarkRed -NoNewline; Write-Host "STRINGS" -ForegroundColor DarkGray
        foreach ($s in $uniqueStrings) { Write-Host "  │    " -ForegroundColor DarkRed -NoNewline; Write-Host $s -ForegroundColor DarkYellow }
    }
    if ($Mod.Fullwidth -and $Mod.Fullwidth.Count -gt 0) {
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  │  " -ForegroundColor DarkRed -NoNewline; Write-Host "FULLWIDTH UNICODE" -ForegroundColor DarkGray
        foreach ($fw in ($Mod.Fullwidth | Sort-Object)) { Write-Host "  │    " -ForegroundColor DarkRed -NoNewline; Write-Host "FULLWIDTH: $fw" -ForegroundColor Cyan }
    }
    Write-Host "  │" -ForegroundColor DarkRed; Write-Host ("  " + ("─"*70)) -ForegroundColor DarkRed; Write-Host ""
}

function Write-ObfuscationCard {
    param($Mod)
    Write-Host ("  " + ("─"*70)) -ForegroundColor DarkYellow
    Write-Host "  │ " -ForegroundColor DarkYellow -NoNewline
    Write-Host " OBFUSCATED " -ForegroundColor Black -BackgroundColor DarkYellow -NoNewline
    Write-Host "  " -NoNewline; Write-Host $Mod.FileName -ForegroundColor Yellow
    Write-Host ("  │ " + ("─"*66)) -ForegroundColor DarkYellow
    foreach ($flag in $Mod.Flags) {
        $ft=$flag; $fd=""
        if ($flag -match "^(.+?) — (.+)$") { $ft=$matches[1]; $fd=$matches[2] }
        Write-Host "  │" -ForegroundColor DarkYellow
        Write-Host "  │  " -ForegroundColor DarkYellow -NoNewline; Write-Host "⚑ " -ForegroundColor Yellow -NoNewline; Write-Host $ft -ForegroundColor White
        if ($fd) { Write-Host "  │    " -ForegroundColor DarkYellow -NoNewline; Write-Host $fd -ForegroundColor Gray }
    }
    Write-Host "  │" -ForegroundColor DarkYellow; Write-Host ("  " + ("─"*70)) -ForegroundColor DarkYellow; Write-Host ""
}

 $verifiedMods=@(); $unknownMods=@(); $suspiciousMods=@(); $obfuscatedMods=@()
 $modrinthWhitelistedSlugs = @("viafabricplus","viafabricversion")

try {
    $jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction Stop
} catch {
    Write-Host "❌ Error accessing directory: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit 1
}
if ($jarFiles.Count -eq 0) {
    Write-Host "⚠️  No JAR files found in: $modsPath" -ForegroundColor Yellow
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit 0
}

 $fileWord = if ($jarFiles.Count -eq 1) { "file" } else { "files" }
Write-Host "🔍 Found $($jarFiles.Count) JAR $fileWord to analyze" -ForegroundColor Green; Write-Host

 $spinnerFrames = @("⣾","⣽","⣻","⢿","⡿","⣟","⣯","⣷")
 $totalFiles    = $jarFiles.Count
 $idx           = 0

# Unified Scanning Loop
foreach ($jar in $jarFiles) {
    $idx++
    $spinner = $spinnerFrames[$idx % $spinnerFrames.Length]
    
    # Updated Scanning UI
    Write-Host "`r[$spinner] Scanning: $idx/$totalFiles - $($jar.Name)" -ForegroundColor Yellow -NoNewline

    $hash = Get-FileSHA1 -Path $jar.FullName
    $isVerified = $false; $modName = ""; $isWhitelisted = $false

    # --- 1. Hash Verification (Pass 1) ---
    if ($hash) {
        $modrinthData = Query-Modrinth -Hash $hash
        if ($modrinthData.Slug) {
            $isVerified = $true; $modName = $modrinthData.Name
            $isWhitelisted = ($modrinthWhitelistedSlugs -contains $modrinthData.Slug.ToLower())
        }
        else {
            $megabaseData = Query-Megabase -Hash $hash
            if ($megabaseData.name) { $isVerified = $true; $modName = $megabaseData.name }
        }
    }

    if ($isVerified) {
        $verifiedMods += [PSCustomObject]@{
            ModName=$modName; FileName=$jar.Name; FilePath=$jar.FullName
            ModrinthWhitelisted=$isWhitelisted
        }
    } else {
        $src = Get-DownloadSource $jar.FullName
        $unknownMods += [PSCustomObject]@{ FileName=$jar.Name; FilePath=$jar.FullName; DownloadSource=$src }
    }

    # --- 2. Deep Scanning (Pass 2) ---
    # Only deep scan if not verified OR not whitelisted
    if (-not $isVerified -or -not $isWhitelisted) {
        $result = Invoke-ModScan -FilePath $jar.FullName
        if ($result.Patterns.Count -gt 0 -or $result.Strings.Count -gt 0 -or $result.Fullwidth.Count -gt 0) {
            $suspiciousMods += [PSCustomObject]@{ FileName=$jar.Name; Patterns=$result.Patterns; Strings=$result.Strings; Fullwidth=$result.Fullwidth }
            # Remove from Verified/Unknown if flagged
            $verifiedMods = $verifiedMods | Where-Object { $_.FileName -ne $jar.Name }
            $unknownMods = $unknownMods | Where-Object { $_.FileName -ne $jar.Name }
        }
    }

    # --- 3. Obfuscation Scan (Pass 4 - Renumbered logically) ---
    if (-not $isVerified -or -not $isWhitelisted) {
        $obfFlags = Invoke-ObfuscationScan -FilePath $jar.FullName
        if ($obfFlags.Count -gt 0) {
            $alreadyFlagged = ($suspiciousMods | Where-Object { $_.FileName -eq $jar.Name }).Count -gt 0
            if (-not $alreadyFlagged) {
                $obfuscatedMods += [PSCustomObject]@{ FileName=$jar.Name; Flags=$obfFlags }
                $verifiedMods    = $verifiedMods | Where-Object { $_.FileName -ne $jar.Name }
            }
        }
    }
}
Write-Host "`r$(' '*100)`r" -NoNewline

# Call the Integrated JVM Scanner
Invoke-JvmScan

if ($verifiedMods.Count -gt 0) {
    Write-SectionHeader -Title "VERIFIED MODS" -Count $verifiedMods.Count -DotColor Green -CountColor Green
    Write-Rule "─" 76 DarkGray
    foreach ($mod in $verifiedMods) {
        Write-Host "  " -NoNewline
        Write-Host "$($mod.ModName)" -ForegroundColor White -NoNewline
        Write-Host " :: " -ForegroundColor Gray -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

if ($unknownMods.Count -gt 0) {
    Write-SectionHeader -Title "UNKNOWN MODS" -Count $unknownMods.Count -DotColor Yellow -CountColor Yellow
    Write-Rule "─" 76 DarkGray
    foreach ($mod in $unknownMods) {
        $name = $mod.FileName
        if ($name.Length -gt 50) { $name = $name.Substring(0,47) + "..." }
        $topLine    = "  ╔═ ? " + $name + " " + ("═"*(65-$name.Length)) + "╗"
        $sourceText = if ($mod.DownloadSource) { "Source: $($mod.DownloadSource)" } else { "Source: ?" }
        $bottomLine = "  ╚═ " + $sourceText + " " + ("═"*(67-$sourceText.Length)) + "╝"
        Write-Host $topLine    -ForegroundColor Yellow
        Write-Host $bottomLine -ForegroundColor Yellow
        Write-Host ""
    }
}

if ($suspiciousMods.Count -gt 0) {
    Write-SectionHeader -Title "SUSPICIOUS MODS" -Count $suspiciousMods.Count -DotColor Red -CountColor Red
    Write-Rule "─" 76 DarkGray; Write-Host ""
    foreach ($mod in $suspiciousMods) { Write-SuspiciousCard -Mod $mod }
}

if ($obfuscatedMods.Count -gt 0) {
    Write-SectionHeader -Title "OBFUSCATED MODS" -Count $obfuscatedMods.Count -DotColor DarkYellow -CountColor Yellow
    Write-Rule "─" 76 DarkGray; Write-Host ""
    foreach ($mod in $obfuscatedMods) { Write-ObfuscationCard -Mod $mod }
}

Write-Host "Scan complete." -ForegroundColor Green
Write-Host "Press any key to exit..." -ForegroundColor Gray
 $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
