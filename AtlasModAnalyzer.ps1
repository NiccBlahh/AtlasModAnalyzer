[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

$banner = @"
▄▄▄     ▄▄▄█████▓ ██▓    ▄▄▄        ██████     ███▄ ▄███▓ ▒█████  ▓█████▄
▒████▄   ▓  ██▒ ▓▒▓██▒   ▒████▄    ▒██    ▒    ▓██▒▀█▀ ██▒▒██▒  ██▒▒██▀ ██▌
▒██  ▀█▄ ▒ ▓██░ ▒░▒██░   ▒██  ▀█▄  ░ ▓██▄      ▓██    ▓██░▒██░  ██▒░██   █▌
░██▄▄▄▄██░ ▓██▓ ░ ▒██░   ░██▄▄▄▄██   ▒   ██▒   ▒██    ▒██ ▒██   ██░░▓█▄   ▌
 ▓█   ▓██▒ ▒██▒ ░ ░██████▒▓█   ▓██▒▒██████▒▒   ▒██▒   ░██▒░ ████▓▒░░▒████▓
 ▒▒   ▓▒█░ ▒ ░░   ░ ▒░▓  ░▒▒   ▓▒█░▒ ▒▓▒ ▒ ░   ░ ▒░   ░  ░░ ▒░▒░▒░  ▒▒▓  ▒
  ▒   ▒▒ ░   ░    ░ ░ ▒  ░ ▒   ▒▒ ░░ ░▒  ░ ░   ░  ░      ░  ░ ▒ ▒░  ░ ▒  ▒
  ░   ▒    ░        ░ ░    ░   ▒   ░  ░  ░     ░      ░   ░ ░ ░ ▒   ░ ░  ░
      ░  ░            ░  ░     ░  ░      ░            ░       ░ ░     ░
                                                                    ░
                ▄▄▄       ███▄    █  ▄▄▄       ██▓   ▓██   ██▓▒███████▒▓█████  ██▀███
               ▒████▄     ██ ▀█   █ ▒████▄    ▓██▒    ▒██  ██▒▒ ▒ ▒ ▄▀░▓█   ▀ ▓██ ▒ ██▒
               ▒██  ▀█▄  ▓██  ▀█ ██▒▒██  ▀█▄  ▒██░     ▒██ ██░░ ▒ ▄▀▒░ ▒███   ▓██ ░▄█ ▒
               ░██▄▄▄▄██ ▓██▒  ▐▌██▒░██▄▄▄▄██ ▒██░     ░ ▐██▓░  ▄▀▒   ░▒▓█  ▄ ▒██▀▀█▄
                ▓█   ▓██▒▒██░   ▓██░ ▓█   ▓██▒░██████▒ ░ ██▒▓░▒███████▒░▒████▒░██▓ ▒██▒
                ▒▒   ▓▒█░░ ▒░   ▒ ▒  ▒▒   ▓▒█░░ ▒░▓  ░  ██▒▒▒ ░▒▒ ▓░▒░▒░░ ▒░ ░░ ▒▓ ░▒▓░
                 ▒   ▒▒ ░░ ░░   ░ ▒░  ▒   ▒▒ ░░ ░ ▒  ░▓██ ░▒░ ░░▒ ▒ ░ ▒ ░ ░  ░  ░▒ ░ ▒░
                 ░   ▒      ░   ░ ░   ░   ▒     ░ ░   ▒ ▒ ░░  ░ ░ ░ ░ ░   ░     ░░   ░
                     ░  ░         ░       ░  ░    ░  ░░ ░       ░ ░       ░  ░   ░
                                                      ░ ░     ░
"@

Write-Host $banner -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor DarkGray
Write-Host "  Mod Analysis Tool" -ForegroundColor DarkCyan
Write-Host ("=" * 60) -ForegroundColor DarkGray
Write-Host ""

$modsPath = Read-Host "  Path to mods folder (Enter for default)"
if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host (" " * 3) -NoNewline; Write-Host "Using: $modsPath" -ForegroundColor White
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host (" " * 2) + "!" -ForegroundColor Red -NoNewline; Write-Host " Invalid path: $modsPath"
    Write-Host (" " * 3) + "Press any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host (" " * 3) + "Target: $modsPath" -ForegroundColor Green
Write-Host ""

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) { $mcProcess = Get-Process java -ErrorAction SilentlyContinue }
if ($mcProcess) {
    try {
        $startTime = $mcProcess.StartTime
        $uptime = (Get-Date) - $startTime
        Write-Host (" " * 3) + "Minecraft PID $($mcProcess.Id) — $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor DarkCyan
    } catch { }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$suspiciousPatterns = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand", "JDWP.VirtualMachine.AllModules",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "LegitTotem", "PingSpoof", "SelfDestruct",
    "ShieldBreaker", "TriggerBot", "AxeSpam", "WebMacro",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag",
    "BlockESP", "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton",  "AntiMissClick",
    "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "FastXP", "FastExp", "Refill",  "AirAnchor",
    "jnativehook", "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework",
    "PackSpoof", "Antiknockback", "catlean", 
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap",  "Macro198", "StunSlam", "SafeAnchor", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy",
    "AutoPotRefill", "WalksyOptimizer", "KeyPearl", "AimAssist", "AutoNethPot", "AutoDtap",
    "TriggerBot", "AutoWeb", "AnchorAction",
    
    "org.chainlibs.module.impl.modules.Crystal.Y",
    "org.chainlibs.module.impl.modules.Crystal.bF",
    "org.chainlibs.module.impl.modules.Crystal.bM",
    "org.chainlibs.module.impl.modules.Crystal.bY",
    "org.chainlibs.module.impl.modules.Crystal.bq",
    "org.chainlibs.module.impl.modules.Crystal.cv",
    "org.chainlibs.module.impl.modules.Crystal.o",
    "org.chainlibs.module.impl.modules.Blatant.I",
    "org.chainlibs.module.impl.modules.Blatant.bR",
    "org.chainlibs.module.impl.modules.Blatant.bx",
    "org.chainlibs.module.impl.modules.Blatant.cj",
    "org.chainlibs.module.impl.modules.Blatant.dk",
    "imgui.gl3", "imgui.glfw",
    "BowAim", "Criticals", "Fakenick", "FakeItem",
    "invsee", "ItemExploit", "Hellion", "hellion",
    "LicenseCheckMixin", "ClientPlayerInteractionManagerAccessor",
    "ClientPlayerEntityMixim", "dev.gambleclient", "obfuscatedAuth",
    "phantom-refmap.json", "xyz.greaj",
    "じ.class", "ふ.class", "ぶ.class", "ぷ.class", "た.class",
    "ね.class", "そ.class", "な.class", "ど.class", "ぐ.class",
    "ず.class", "で.class", "つ.class", "べ.class", "せ.class",
    "と.class", "み.class", "び.class", "す.class", "の.class"
)

$cheatStrings = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "JDWP.VirtualMachine.AllModules",
    "dontPlaceCrystal", "dontBreakCrystal",
    "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer", "healPotSlot",
    "ＡｗｔｏＣｒｙｓｔａｌ", "Ａｗｔｏ Ｃｒｙｓｔａｌ",
    "ＡｗｔｏＨｉｔＣｒｙｓｔａｌ",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor",
     "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "SafeAnchor", "AirAnchor",
    "ＡｗｔｏＡｎｃｈｏｒ", "Ａｗｔｏ Ａｎｃｈｏｒ",
    "ＤｏｗｂｌｅＡｎｃｈｏｒ", "Ｄｏｗｂｌｅ Ａｎｃｈｏｒ",
    "ＳａｆｅＡｎｃｈｏｒ", "Ｓａｆｅ Ａｎｃｈｏｒ",
    "Ａｎｃｈｏｒ Ｍａｃｒｏ", "anchorMacro",
    "AutoTotem", "autototem", "auto totem", "InventoryTotem",
    "inventorytotem", "HoverTotem", "hover totem", "legittotem",
    "ＡｗｔｏＴｏｔｅｍ", "Ａｗｔｏ Ｔｏｔｅｍ",
    "ＨｏｖｅｒＴｏｔｅｍ", "Ｈｏｖｅｒ Ｔｏｔｅｍ",
    "ＩｎｖｅｎｔｏｒｙＴｏｔｅｍ", "Ａｗｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
    "Ａｗｔｏ Ｔｏｔｅｍ Ｈｉｔ",
    "AutoPot", "autopot", "auto pot", "speedPotSlot", "strengthPotSlot",
    "AutoArmor", "autoarmor", "auto armor",
    "ＡｗｔｏＰｏｔ", "Ａｗｔｏ Ｐｏｔ",
    "Ａｗｔｏ Ｐｏｔ Ｒｅｆｉｌｌ", "AutoPotRefill",
    "ＡｗｔｏＡｒｍｏｒ", "Ａｗｔｏ Ａｒｍｏｒ",
    "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "ShieldDisabler", "ShieldBreaker",
    "ＳｈｉｅｌｄＤｉｓａｂｌｅｒ", "Ｓｈｉｅｌｄ Ｄｉｓａｂｌｅｒ",
    "Breaking shield with axe...",
    "AutoDoubleHand", "autodoublehand", "auto double hand",
    "ＡｗｔｏＤｏｊｂｌｅＨａｎｄ", "Ａｗｔｏ Ｄｏｊｂｌｅ Ｈａｎｄ",
    "AutoClicker",
    "ＡｗｔｏＣｌｉｃｋｅｒ",
    "Failed to switch to mace after axe!",
    "AutoMace", "MaceSwap", "SpearSwap",
    "ＡｗｔｏＭａｃｅ", "Ａｗｔｏ Ｍａｃｅ",
    "ＭａｃｅＳｗａｐ", "Ｍａｃｅ Ｓｗａｐ",
    "Ｓｐｅａｒ Ｓｗａｐ", "Ａｗｔｏｍａｔｉｃａｌｌｙ ａｘｅ ａｎｄ ｍａｃｅ ｓｈｉｅｌｄｅｄ ｐｌａｙｅｒｓ",
    "Ｓｔｊｎ Ｓｌａｍ", "StunSlam",
    "Donut", "JumpReset", "axespam", "axe spam",
    
    "findKnockbackSword", "attackRegisteredThisClick",
    "AimAssist", "aimassist", "aim assist",
    "triggerbot", "trigger bot",
    "ＡｉｍＡｓｓｉｓｔ", "Ａｉｍ Ａｓｓｉｓｔ",
    "ＴｒｉｇｇｅｒＢｏｔ", "Ｔｒｉｇｇｅｒ Ｂｏｔ",
    "Silent Rotations", "SilentRotations",
    "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ",
    "FakeInv", "swapBackToOriginalSlot",
    "FakeLag", "pingspoof", "ping spoof",
    "ＦａｋｅＬａｇ", "Ｆａｋｅ Ｌａｇ",
    "fakePunch", "Fake Punch",
    "Ｆａｋｅ Ｐｊｎｃｈ",
    "mace_swap", "quick_strike", "macro_198", "stun_slam",
    "safe_anchor", "double_anchor", "auto_pot_refill",
    "walksy_optimizer", "key_pearl", "aim_assist",
    "auto_neth_pot", "auto_dtap", "trigger_bot", "auto_web",
    "DOUBLE_ESCAPE", "DOUBLE_RIGHTCLICK_FIRST", "DOUBLE_RIGHTCLICK_SECOND",
    "POST_CYCLE_DELAY", "PLACE_OBI", "WAIT_OBI", "PLACE_CRYSTAL", "BREAK_CRYSTAL",
    "ROTATING_DOWN", "ROTATING_BACK", "REFILLING", "PLANTING", "BONEMEALING",
    "AnchorAction", "Places two anchors for massive damage",
    "REOFFHAND_TOTEM",
    "webmacro", "web macro",
    "AntiWeb", "AutoWeb",
    "Ａｎｔｉ Ｗｅｂ", "ＡｊｔｏＷｅｂ",
    "Ｐｌａｃｅｓ Ｗｅｂｓ Ｏｎ Ｅｎｅｍｉｅｓ",
    "lvstrng", "dqrkis", "selfdestruct", "self destruct",
    "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer",
    "Ｗａｌｋｓｙ Ｏｐｔｉｍｉｚｅｒ",
    "autoCrystalPlaceClock",
    "AutoFirework", "ElytraSwap", "FastXP", "FastExp", "NoJumpDelay",
    "ＥｌｙｔｒａＳｗａｐ", "Ｅｌｙｔｒａ Ｓｗａｐ",
    "PackSpoof", "Antiknockback", "catlean",
    "AuthBypass", "obfuscatedAuth", "LicenseCheckMixin",
    "BaseFinder", "invsee", "ItemExploit",
    "FreezePlayer",
    "Ｆｒｅｅｃａｍ", "Ｍｏｖｅ ｆｒｅｅｌｙ ｔｈｒｏｊｇｈ ｗａｌｌｓ",
    "Ｎｏ Ｃｌｉｐ", "Ｆｒｅｅｚｅ Ｐｌａｙｅｒ",
    "LWFH Crystal", "JDWP.VirtualMachine.AllModules",
    "ＬＷＦＨ Ｃｒｙｓｔａｌ",
    "KeyPearl", "LootYeeter",
    "ＫｅｙＰｅａｒｌ", "Ｋｅｙ Ｐｅａｒｌ",
    "Ｌｏｏｔ Ｙｅｅｔｅｒ",
    "FastPlace",
    "Ｆａｓｔ Ｐｌａｃｅ", "Ｐｌａｃｅ ｂｌｏｃｋｓ ｆａｓｔｅｒ",
    "AutoBreach",
    "Ａｊｔｏ Ｂｒｅａｃｈ",
    "setBlockBreakingCooldown", "getBlockBreakingCooldown", "blockBreakingCooldown",
    "onBlockBreaking", "setItemUseCooldown",
    "invokeDoAttack", "invokeDoItemUse", "invokeOnMouseButton",
    "onPushOutOfBlocks", "onIsGlowing",
    "Automatically switches to sword when hitting with totem",
    "arrayOfString", "POT_CHEATS",
    "Dqrkis Client", "Entity.isGlowing",
    "Activate Key", "Ａｃｔｉｖａｔｅ Ｋｅｙ",
    "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｊｌａｔｉｏｎ",
    "On RMB", "Ｏｎ ＲＭＢ",
    "No Count Glitch", "Ｎｏ Ｃｏｊｎｔ Ｇｌｉｔｃｈ",
    "No Bounce", "NoBounce", "Ｎｏ Ｂｏｊｎｃｅ", "ＮｏＢｏｊｎｃｅ",
    "Ｒｅｍｏｖｅｓ ｔｈｅ ｃｒｙｓｔａｌ ｂｏｊｎｃｅ ａｎｉｍａｔｉｏｎ",
    "Place Delay", "Ｐｌａｃｅ Ｄｅｌａｙ",
    "Break Delay", "Ｂｒｅａｋ Ｄｅｌａｙ",
     "Ｆａｓｔ Ｍｏｄｅ",
    "Place Chance", "Ｐｌａｃｅ Ｃｈａｎｃｅ",
    "Break Chance", "Ｂｒｅａｋ Ｃｈａｎｃｅ",
    "Stop On Kill", "Ｓｔｏｐ Ｏｎ Ｋｉｌｌ",
    "Ｄａｍａｇｅ Ｔｉｃｋ", "damagetick",
    "Anti Weakness", "Ａｎｔｉ Ｗｅａｋｎｅｓｓ",
    "Particle Chance", "Ｐａｒｔｉｃｌｅ Ｃｈａｎｃｅ",
    "Trigger Key", "Ｔｒｉｇｇｅｒ Ｋｅｙ",
    "Switch Delay", "Ｓｗｉｔｃｈ Ｄｅｌａｙ",
    "Totem Slot", "Ｔｏｔｅｍ Ｓｌｏｔ",
    "Silent Rotations", "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ",
    "Smooth Rotations", "Ｓｍｏｏｔｈ Ｒｏｔａｔｉｏｎｓ",
    "Rotation Speed", "Ｒｏｔａｔｉｏｎ Ｓｐｅｅｄ",
    "Use Easing", "Ｕｓｅ Ｅａｓｉｎｇ",
    "Easing Strength", "Ｅａｓｉｎｇ Ｓｔｒｅｎｇｔｈ",
    "While Use", "Ｗｈｉｌｅ Ｕｓｅ",
    "Stop on Kill", "Ｓｔｏｐ ｏｎ Ｋｉｌｌ",
    "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｊｌａｔｉｏｎ",
    "Glowstone Delay", "Ｇｌｏｗｓｔｏｎｅ Ｄｅｌａｙ",
    "Glowstone Chance", "Ｇｌｏｗｓｔｏｎｅ Ｃｈａｎｃｅ",
    "Explode Delay", "Ｅｘｐｌｏｄｅ Ｄｅｌａｙ",
    "Explode Chance", "Ｅｘｐｌｏｄｅ Ｃｈａｎｃｅ",
    "Explode Slot", "Ｅｘｐｌｏｄｅ Ｓｌｏｔ",
    "Only Charge", "Ｏｎｌｙ Ｃｈａｒｇｅ",
    "Anchor Macro", "Ａｎｃｈｏｒ Ｍａｃｒｏ",
    "Reach Distance", "Ｒｅａｃｈ Ｄｉｓｔａｎｃｅ",
    "Min Height", "Ｍｉｎ Ｈｅｉｇｈｔ",
    "Min Fall Speed", "Ｍｉｎ Ｆａｌｌ Ｓｐｅｅｄ",
    "Attack Delay", "Ａｔｔａｃｋ Ｄｅｌａｙ",
    "Breach Delay", "Ｂｒｅａｃｈ Ｄｅｌａｙ",
    "Require Elytra", "Ｒｅｑｊｉｒｅ Ｅｌｙｔｒａ",
    "Auto Switch Back", "Ａｊｔｏ Ｓｗｉｔｃｈ Ｂａｃｋ",
    "Check Line of Sight", "Ｃｈｅｃｋ Ｌｉｎｅ ｏｆ Ｓｉｇｈｔ",
    "Only When Falling", "Ｏｎｌｙ Ｗｈｅｎ Ｆａｌｌｉｎｇ",
    "Require Crit", "Ｒｅｑｊｉｒｅ Ｃｒｉｔ",
    "Show Status Display", "Ｓｈｏｗ Ｓｔａｔｊｓ Ｄｉｓｐｌａｙ",
    "Stop On Crystal", "Ｓｔｏｐ Ｏｎ Ｃｒｙｓｔａｌ",
    "Check Shield", "Ｃｈｅｃｋ Ｓｈｉｅｌｄ",
    "On Pop", "Ｏｎ Ｐｏｐ",
    "Predict Damage", "Ｐｒｅｄｉｃｔ Ｄａｍａｇｅ",
    "On Ground", "Ｏｎ Ｇｒｏｊｎｄ",
    "Check Players", "Ｃｈｅｃｋ Ｐｌａｙｅｒｓ",
    "Predict Crystals", "Ｐｒｅｄｉｃｔ Ｃｒｙｓｔａｌｓ",
    "Check Aim", "Ｃｈｅｃｋ Ａｉｍ",
    "Check Items", "Ｃｈｅｃｋ Ｉｔｅｍｓ",
    "Activates Above", "Ａｃｔｉｖａｔｅｓ Ａｂｏｖｅ",
    "Blatant", "Ｂｌａｔａｎｔ",
    "Force Totem", "Ｆｏｒｃｅ Ｔｏｔｅｍ",
    "Stay Open For", "Ｓｔａｙ Ｏｐｅｎ Ｆｏｒ",
    "Auto Inventory Totem", "Ａｊｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
    "Only On Pop", "Ｏｎｌｙ Ｏｎ Ｐｏｐ",
    "Vertical Speed", "Ｖｅｒｔｉｃａｌ Ｓｐｅｅｄ",
    "Hover Totem", "Ｈｏｖｅｒ Ｔｏｔｅｍ",
    "Swap Speed", "Ｓｗａｐ Ｓｐｅｅｄ",
    "Strict One-Tick", "Ｓｔｒｉｃｔ Ｏｎｅ－Ｔｉｃｋ",
    "Mace Priority", "Ｍａｃｅ Ｐｒｉｏｒｉｔｙ",
    "Min Totems", "Ｍｉｎ Ｔｏｔｅｍｓ",
    "Min Pearls", "Ｍｉｎ Ｐｅａｒｌｓ",
    "Totem First", "Ｔｏｔｅｍ Ｆｉｒｓｔ",
    "Drop Interval", "Ｄｒｏｐ Ｉｎｔｅｒｖａｌ",
    "Random Pattern", "Ｒａｎｄｏｍ Ｐａｔｔｅｒｎ",
    "Loot Yeeter", "Ｌｏｏｔ Ｙｅｅｔｅｒ",
    "Horizontal Aim Speed", "Ｈｏｒｉｚｏｎｔａｌ Ａｉｍ Ｓｐｅｅｄ",
    "Vertical Aim Speed", "Ｖｅｒｔｉｃａｌ Ａｉｍ Ｓｐｅｅｄ",
    "Include Head", "Ｉｎｃｌｊｄｅ Ｈｅａｄ",
    "Web Delay", "Ｗｅｂ Ｄｅｌａｙ",
    "Holding Web", "Ｈｏｌｄｉｎｇ Ｗｅｂ",
    "Not When Affects Player", "Ｎｏｔ Ｗｈｅｎ Ａｆｆｅｃｔｓ Ｐｌａｙｅｒ",
    "Hit Delay", "Ｈｉｔ Ｄｅｌａｙ",
    "Ｓｗｉｔｃｈ Ｂａｃｋ",
    "Require Hold Axe", "Ｒｅｑｊｉｒｅ Ｈｏｌｄ Ａｘｅ",
    "Fake Punch", "Ｆａｋｅ Ｐｊｎｃｈ",
    "placeInterval", "breakInterval", "stopOnKill",
    "activateOnRightClick", "holdCrystal",
    "ｐｌａｃｅＩｎｔｅｒｖａｌ", "ｂｒｅａｋＩｎｔｅｒｖａｌ",
    "ｓｔｏｐＯｎＫｉｌｌ", "ａｃｔｉｖａｔｅＯｎＲｉｇｈｔＣｌｉｃｋ",
    "ｄａｍａｇｅｔｉｃｋ", "ｈｏｌｄＣｒｙｓｔａｌ",
    "ｆａｋｅＰｊｎｃｈ",
    "Ｒｅｆｉｌｌｓ ｙｏｊｒ ｈｏｔｂａｒ ｗｉｔｈ ｐｏｔｉｏｎｓ",
    "Ｋｅｐｓ ｙｏｊｒ ｓｐｒｉｎｔｉｎｇ ａｔ ａｌｌ ｔｉｍｅｓ",
    "Ｐｌａｃｅｓ ａｎｃｈｏｒ， ｃｈａｒｇｅｓ ｉｔ， ｐｒｏｔｅｃｔｓ ｙｏｊｒ， ａｎｄ ｅｘｐｌｏｄｅｓ",
    "Ａｊｔｏ ｓｗａｐ ｔｏ ｓｐｅａｒ ｏｎ ａｔｔａｃｋ",
    "Macro Key", "Ａｊｔｏ Ｐｏｔ", "Ｍａｃｒｏ Ｋｅｙ",
    "KillAura", "ClickAura", "MultiAura", "ForceField", "LegitAura",
    "AimBot", "AutoAim", "SilentAim", "AimLock", "HeadSnap",
    "CrystalAura",
    "AnchorAura", "AnchorFill", "AnchorPlace",
    "BedAura", "AutoBed", "BedBomb", "BedPlace",
    "BowAimbot", "BowSpam", "AutoBow",
    "AutoCrit", "CritBypass", "AlwaysCrit", "CriticalHit",
    "ReachHack", "ExtendReach", "LongReach", "HitboxExpand",
    "AntiKB", "NoKnockback", "GrimVelocity", "GrimDisabler", "VelocitySpoof", "KBReduce",
    "OffhandTotem", "TotemSwitch",
    "AutoWeapon", "AutoSword", "AutoCity", "Burrow", "SelfTrap",
    "HoleFiller", "AntiSurround", "AntiBurrow",
    "WTap", "TargetStrafe", "AutoGap", "AutoPearl",
    "FlyHack", "CreativeFlight", "BoatFly", "PacketFly", "AirJump",
    "SpeedHack", "BHop", "BunnyHop",
    "AntiFall", "NoFallDamage", "SafeFall",
    "StepHack", "FastClimb", "AutoStep", "HighStep",
    "WaterWalk", "LiquidWalk", "LavaWalk",
    "NoSlow", "NoSlowdown", "NoWeb", "NoSoulSand",
    "WallHack",
    "ElytraSpeed", "InstantElytra",
    "ScaffoldWalk", "FastBridge", "BuildHelper", "AutoBridge",
    "Nuker", "NukerLegit", "InstantBreak",
    "GhostHand", "NoSwing",
    "PlaceAssist", "AirPlace", "AutoPlace", "InstantPlace",
    "PlayerESP", "MobESP", "ItemESP", "StorageESP", "ChestESP",
    "Tracers", "NameTagsHack",
    "XRayHack", "OreFinder", "CaveFinder", "OreESP",
    "NewChunks", "ChunkBorders", "TunnelFinder",
    "TargetHUD", "ReachDisplay",
    "DoubleClicker", "JitterClick", "ButterflyClick", "CPSBoost",
    "ChestStealer", "InvManager", "InvMovebypass",
    "AutoSprint", "AntiAFK", "AutoRespawn",
    "PopSwitch",
    "FakeLatency", "FakePing", "SpoofRotation", "PositionSpoof",
    "GameSpeed", "SpeedTimer",
     "GrimBypass", "VulcanBypass", "MatrixBypass",
    "AACBypass", "VerusDisabler", "IntaveBypass", "WatchdogBypass",
    "PacketMine", "PacketWalk", "PacketSneak", "PacketCancel", "PacketDupe", "PacketSpam",
    "SelfDestruct", "HideClient",
    "SessionStealer", "TokenLogger", "TokenGrabber", "DiscordToken",
    "RemoteAccess", "ReverseShell", "C2Server", "Backdoor", "KeyLogger",
    "StashFinder", "TrailFinder",
    "imgui.binding",
    "JNativeHook", "GlobalScreen", "NativeKeyListener",
    "client-refmap.json", "cheat-refmap.json",
    "aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==",
    "meteordevelopment", "cc/novoline",
    "com/alan/clients", "club/maxstats", "wtf/moonlight",
    "me/zeroeightsix/kami", "net/ccbluex", "today/opai",
    "net/minecraft/injection", "org/chainlibs/module/impl/modules",
    "xyz/greaj", "com/cheatbreaker", "com/moonsworth",
    "doomsdayclient", "DoomsdayClient", "doomsday.jar",
    "novaclient", "api.novaclient.lol",
    "WalksyOptimizer", "LWFH Crystal",
    "vape.gg", "vapeclient", "VapeClient", "VapeLite",
    "intent.store", "IntentClient",
    "rise.today", "riseclient.com",
    "meteor-client", "meteorclient", "meteordevelopment.meteorclient",
    "liquidbounce", "fdp-client", "net.ccbluex",
    "novoware", "novoclient",
    "aristois", "impactclient", "azura",
    "pandaware", "skilled", "moonClient", "astolfo",
    "futureClient", "konas", "rusherhack", "inertia", "exhibition",
    "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton",
     "VirginClient", "virgin client",
    "catlean", "CatleanClient", "catlean client",
     "ArgonClient", "argon client",
    "Asteria", "AsteriaClient", "asteria client",
    "Prestige", "PrestigeClient", "prestige client", "prestigeclient.vip",
    "gypsy", "GypsyClient", "gypsy client",
    "Xenon", "XenonClient", "xenon client",
     "GrimClient", "grim client",
     "phantom-refmap.json",
      "dqrkis.xyz", "Dqrkis Client",
    "activateKey", "checkPlace", "switchDelay", "switchChance", "placeDelay", "placeChance",
    "workWithTotem", "workWithCrystal", "clickSimulation", "swordSwap", "playersOnly",
    "requireClick", "visibilityCheck", "targetLock", "switchTargetKey",
    "minSpeed", "maxSpeed", "randomize", "targetBone", "weaponOnly",
    "lockedTarget", "switchKeyWasPressed", "lastFrame", "smoothTargetPos"
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
        if ($url -match "mediafire\.com")                                        { return "MediaFire" }
        elseif ($url -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { return "Discord" }
        elseif ($url -match "dropbox\.com")                                      { return "Dropbox" }
        elseif ($url -match "drive\.google\.com")                                { return "Google Drive" }
        elseif ($url -match "mega\.nz|mega\.co\.nz")                             { return "MEGA" }
        elseif ($url -match "github\.com")                                       { return "GitHub" }
        elseif ($url -match "modrinth\.com")                                     { return "Modrinth" }
        elseif ($url -match "curseforge\.com")                                   { return "CurseForge" }
        elseif ($url -match "anydesk\.com")                                      { return "AnyDesk" }
        elseif ($url -match "doomsdayclient\.com")                               { return "DoomsdayClient" }
        elseif ($url -match "prestigeclient\.vip")                               { return "PrestigeClient" }
        elseif ($url -match "198macros\.com")                                    { return "198Macros" }
        elseif ($url -match "dqrkis\.xyz")                                       { return "Dqrkis" }
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
            foreach ($m in $patternRegex.Matches($entry.FullName)) {
                [void]$foundPatterns.Add($m.Value)
            }
        }

        $allEntries    = [System.Collections.Generic.List[object]]::new()
        $innerArchives = [System.Collections.Generic.List[object]]::new()

        foreach ($e in $archive.Entries) { $allEntries.Add($e) }

        foreach ($nj in ($archive.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ns = $nj.Open()
                $ms = New-Object System.IO.MemoryStream
                $ns.CopyTo($ms); $ns.Close()
                $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $innerArchives.Add($iz)
                foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
            } catch { }
        }

        foreach ($entry in $allEntries) {
            $name = $entry.FullName

            if ($name -match '\.(class|json)$' -or $name -match 'MANIFEST\.MF') {
                try {
                    $st = $entry.Open()
                    $ms2 = New-Object System.IO.MemoryStream
                    $st.CopyTo($ms2); $st.Close()
                    $bytes = $ms2.ToArray(); $ms2.Dispose()

                    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
                    $utf8  = [System.Text.Encoding]::UTF8.GetString($bytes)

                    foreach ($m in $patternRegex.Matches($ascii)) { [void]$foundPatterns.Add($m.Value) }

                    foreach ($s in $cheatStringSet) {
                        if ($ascii.Contains($s)) { [void]$foundStrings.Add($s); continue }
                        if ($utf8.Contains($s))  { [void]$foundStrings.Add($s) }
                    }

                    foreach ($m in $fullwidthRegex.Matches($utf8)) {
                        [void]$foundFullwidth.Add($m.Value)
                    }
                } catch { }
            }
        }

        foreach ($ia in $innerArchives) { try { $ia.Dispose() } catch { } }
        $archive.Dispose()
    } catch { }

    $fwCheatPool = @($script:cheatStrings | Where-Object {
        $_ -cmatch "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]"
    })
    $resolvedFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in @($foundFullwidth)) {
        if ($fw.Length -lt 3) { continue }
        $bestMatch = $null
        foreach ($cs in $fwCheatPool) {
            if ($cs.Contains($fw)) {
                if ($null -eq $bestMatch -or $cs.Length -lt $bestMatch.Length) {
                    $bestMatch = $cs
                }
            }
        }
        if ($null -ne $bestMatch) {
            [void]$resolvedFullwidth.Add($bestMatch)
        } elseif ($fw.Length -ge 6) {
            [void]$resolvedFullwidth.Add($fw)
        }
    }
    $resolved = @($resolvedFullwidth)
    $finalFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in $resolved) {
        $isRedundant = $false
        foreach ($other in $resolved) {
            if ($fw.Length -lt $other.Length -and $other.Contains($fw)) {
                $isRedundant = $true; break
            }
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

        $totalClass    = 0
        $numericCount  = 0
        $unicodeCount  = 0
        $fullwidthCount= 0
        $japaneseCount = 0
        $singleLetterCount = 0
        $twoLetterCount    = 0
        $gibberishCount    = 0
        $noVowelCount      = 0
        $confusionCount    = 0
        $singleCharPkg     = 0
        $contentSample     = [System.Text.StringBuilder]::new()
        $sampleSize        = 0

        $cheatObfuscators = @{
            "Skidfuscator"   = @("dev/skidfuscator", "Skidfuscator", "skidfuscator.dev")
            "Paramorphism"   = @("Paramorphism", "paramorphism-", "dev/paramorphism")
            "Radon"          = @("ItzSomebody/Radon", "me/itzsomebody/radon", "Radon Obfuscator")
            "Caesium"        = @("sim0n/Caesium", "Caesium Obfuscator", "dev/sim0n/caesium")
            "Bozar"          = @("vimasig/Bozar", "Bozar Obfuscator", "com/bozar")
            "Branchlock"     = @("Branchlock", "branchlock.dev")
            "Binscure"       = @("Binscure", "com/binscure")
            "SuperBlaubeere" = @("superblaubeere", "superblaubeere27")
            "Qprotect"       = @("Qprotect", "QProtect", "mdma.dev/qprotect")
            "Zelix"          = @("ZKMFLOW", "ZKM", "ZelixKlassMaster", "com/zelix")
            "Stringer"       = @("StringerJavaObfuscator", "com/licel/stringer")
            "JNIC"           = @("JNIC", "jnic.obf", "jnic-obfuscator")
            "Scuti"          = @("ScutiObf", "scuti.obf")
            "Smoke"          = @("SmokeObf", "smoke.obf")
        }

        foreach ($entry in $archive.Entries) {
            $name = $entry.FullName

            if ($name -match "\.class$") {
                $totalClass++
                $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split "/")[-1])

                if ($className -match "^\d+$")                          { $numericCount++ }
                if ($className -match "[^\x00-\x7F]")                   { $unicodeCount++ }
                if ($className -match "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]") { $fullwidthCount++ }
                if ($className -match "[\u3040-\u309F\u30A0-\u30FF]")  { $japaneseCount++ }
                if ($className -match "^[a-zA-Z]$")                     { $singleLetterCount++ }
                if ($className -match "^[a-zA-Z]{2}$")                  { $twoLetterCount++ }
                if ($className -match "^[Il1O0]+$" -or $className -match "^[_]+$") { $confusionCount++ }

                if ($className.Length -ge 3 -and $className.Length -le 8 -and $className -match "^[a-zA-Z]+$") {
                    $vowels = ($className.ToCharArray() | Where-Object { $_ -match "[aeiouAEIOU]" }).Count
                    if ($vowels -eq 0) { $noVowelCount++ }
                    $hasCluster = $className -match "[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]{3,}"
                    if ($hasCluster -and ($vowels / $className.Length) -lt 0.3) { $gibberishCount++ }
                }

                $segs = ($name -replace "\.class$", "") -split "/"
                foreach ($seg in $segs[0..($segs.Count - 2)]) {
                    if ($seg.Length -eq 1) { $singleCharPkg++ }
                }

                if ($sampleSize -lt 150000 -and $entry.Length -lt 100000 -and $entry.Length -gt 100) {
                    try {
                        $st = $entry.Open()
                        $ms = New-Object System.IO.MemoryStream
                        $st.CopyTo($ms); $st.Close()
                        $ascii = [System.Text.Encoding]::ASCII.GetString($ms.ToArray())
                        $ms.Dispose()
                        [void]$contentSample.Append($ascii)
                        $sampleSize += $ascii.Length
                    } catch { }
                }
            }
        }

        $archive.Dispose()

        if ($totalClass -lt 5) { return $flags }

        $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }

        $numPct   = & $pct $numericCount
        $uniPct   = & $pct $unicodeCount
        $fwPct    = & $pct $fullwidthCount
        $jpPct    = & $pct $japaneseCount
        $s1Pct    = & $pct $singleLetterCount
        $s2Pct    = & $pct $twoLetterCount
        $gibPct   = & $pct $gibberishCount
        $novPct   = & $pct $noVowelCount
        $confPct  = & $pct $confusionCount

        if ($numPct   -ge 20) { $flags.Add("Numeric class names — $numPct% of classes have numeric-only names") }
        if ($uniPct   -ge 10) { $flags.Add("Unicode class names — $uniPct% of classes use non-ASCII characters") }
        if ($fwPct    -gt  0) { $flags.Add("Fullwidth Unicode class names — $fwPct% use ａｂｃ/ＡＢＣ/０１２ chars ($fullwidthCount classes)") }
        if ($jpPct    -gt  0) { $flags.Add("Japanese obfuscation — $jpPct% use hiragana/katakana class names ($japaneseCount classes)") }
        if ($s1Pct    -ge 15) { $flags.Add("Single-letter class names — $s1Pct% ($singleLetterCount classes)") }
        if ($s2Pct    -ge 20) { $flags.Add("Two-letter class names — $s2Pct% ($twoLetterCount classes)") }
        if ($gibPct   -ge  5) { $flags.Add("Gibberish class names — $gibPct% have no vowels / consonant clusters ($gibberishCount classes)") }
        if ($novPct   -ge  8) { $flags.Add("No-vowel class names — $novPct% ($noVowelCount classes)") }
        if ($confPct  -ge  3) { $flags.Add("Confusion-char names (Il1O0/_) — $confPct% ($confusionCount classes)") }
        if ($singleCharPkg -ge 6) { $flags.Add("Single-char package paths — $singleCharPkg path segments like a/b/c") }

        $fwStringMatches = [regex]::Matches($contentSample.ToString(), "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}")
        if ($fwStringMatches.Count -gt 0) {
            $examples = ($fwStringMatches | Select-Object -First 3 | ForEach-Object { $_.Value }) -join ", "
            $flags.Add("Fullwidth strings in class content — $($fwStringMatches.Count) occurrences (e.g. $examples)")
        }

        $sampleStr = $contentSample.ToString()
        foreach ($obfName in $cheatObfuscators.Keys) {
            foreach ($pat in $cheatObfuscators[$obfName]) {
                if ($sampleStr.Contains($pat)) {
                    $flags.Add("Known cheat obfuscator detected — $obfName (matched: $pat)")
                    break
                }
            }
        }

    } catch { }

    return $flags
}

function Invoke-BypassScan {
    param([string]$FilePath)

    $flags = [System.Collections.Generic.List[string]]::new()

    $mavenPrefixes = @(
        "com_","org_","net_","io_","dev_","gs_","xyz_",
        "app_","me_","tv_","uk_","be_","fr_","de_"
    )

    function Test-SuspiciousJarName {
        param([string]$JarName)
        $base = [System.IO.Path]::GetFileNameWithoutExtension($JarName)
        if ($base -match '\d')                                          { return $false }
        foreach ($pfx in $mavenPrefixes) {
            if ($base.ToLower().StartsWith($pfx))                       { return $false }
        }
        if ($base.Length -gt 20)                                        { return $false }
        return $true
    }

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)

        $nestedJars   = @($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })
        $outerClasses = @($zip.Entries | Where-Object { $_.FullName -match "\.class$" })

        $suspiciousNestedJars = @()
        foreach ($nj in $nestedJars) {
            $njBase = [System.IO.Path]::GetFileName($nj.FullName)
            if (Test-SuspiciousJarName -JarName $njBase) {
                $suspiciousNestedJars += $njBase
            }
        }
        foreach ($sj in $suspiciousNestedJars) {
            $flags.Add("Suspicious nested JAR — no version, unknown dependency: $sj")
        }

        if ($nestedJars.Count -eq 1 -and $outerClasses.Count -lt 3) {
            $njName = [System.IO.Path]::GetFileName(($nestedJars | Select-Object -First 1).FullName)
            $flags.Add("Hollow shell — only $($outerClasses.Count) own class(es), wraps: $njName")
        }

        $outerModId = ""
        $fmje = $zip.Entries | Where-Object { $_.FullName -eq "fabric.mod.json" } | Select-Object -First 1
        if ($fmje) {
            try {
                $s = $fmje.Open()
                $r = New-Object System.IO.StreamReader($s)
                $t = $r.ReadToEnd(); $r.Close(); $s.Close()
                if ($t -match '"id"\s*:\s*"([^"]+)"') { $outerModId = $matches[1] }
            } catch { }
        }

        $allEntries    = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $zip.Entries) { $allEntries.Add($e) }

        $innerZips = [System.Collections.Generic.List[object]]::new()
        foreach ($nj in $nestedJars) {
            try {
                $ns = $nj.Open()
                $ms = New-Object System.IO.MemoryStream
                $ns.CopyTo($ms); $ns.Close()
                $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $innerZips.Add($iz)
                foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
            } catch { }
        }

        $runtimeExecFound  = $false
        $httpDownloadFound = $false
        $httpExfilFound    = $false
        $obfuscatedCount   = 0
        $numericClassCount = 0
        $unicodeClassCount = 0
        $totalClassCount   = 0

        foreach ($entry in $allEntries) {
            $name = $entry.FullName

            if ($name -match "\.class$") {
                $totalClassCount++
                $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split "/")[-1])

                if ($className -match "^\d+$") { $numericClassCount++ }
                if ($className -match "[^\x00-\x7F]") { $unicodeClassCount++ }

                $segs = ($name -replace "\.class$","") -split "/"
                $consecutiveSingle = 0
                $maxConsecutive    = 0
                foreach ($seg in $segs) {
                    if ($seg.Length -eq 1) {
                        $consecutiveSingle++
                        if ($consecutiveSingle -gt $maxConsecutive) { $maxConsecutive = $consecutiveSingle }
                    } else {
                        $consecutiveSingle = 0
                    }
                }
                if ($maxConsecutive -ge 3) { $obfuscatedCount++ }

                try {
                    $st = $entry.Open()
                    $ms2 = New-Object System.IO.MemoryStream
                    $st.CopyTo($ms2)
                    $st.Close()
                    $rawBytes = $ms2.ToArray()
                    $ms2.Dispose()
                    $ct = [System.Text.Encoding]::ASCII.GetString($rawBytes)

                    if ($ct -match "java/lang/Runtime" -and
                        $ct -match "getRuntime" -and
                        $ct -match "exec") {
                        $runtimeExecFound = $true
                    }

                    if ($ct -match "openConnection" -and
                        $ct -match "HttpURLConnection" -and
                        $ct -match "FileOutputStream") {
                        $httpDownloadFound = $true
                    }

                    if ($ct -match "openConnection" -and
                        $ct -match "setDoOutput" -and
                        $ct -match "getOutputStream" -and
                        $ct -match "getProperty") {
                        $httpExfilFound = $true
                    }

                } catch { }
            }
        }

        foreach ($iz in $innerZips) { try { $iz.Dispose() } catch { } }
        $zip.Dispose()

        $obfPct = if ($totalClassCount -ge 10) { [math]::Round(($obfuscatedCount   / $totalClassCount) * 100) } else { 0 }
        $numPct = if ($totalClassCount -ge 5)  { [math]::Round(($numericClassCount / $totalClassCount) * 100) } else { 0 }
        $uniPct = if ($totalClassCount -ge 5)  { [math]::Round(($unicodeClassCount / $totalClassCount) * 100) } else { 0 }

        if ($runtimeExecFound -and $obfPct -ge 25) {
            $flags.Add("Runtime.exec() in obfuscated code — can run arbitrary OS commands")
        }
        if ($httpDownloadFound) {
            $flags.Add("HTTP file download — fetches and writes files from a remote server at runtime")
        }
        if ($httpExfilFound) {
            $flags.Add("HTTP POST exfiltration — sends system data to an external server")
        }
        if ($totalClassCount -ge 10 -and $obfPct -ge 25) {
            $flags.Add("Heavy obfuscation — $obfPct% of classes use single-letter path segments (a/b/c style)")
        }
        if ($numPct -ge 20) {
            $flags.Add("Numeric class names — $numPct% of classes have numeric-only names (e.g. 1234.class)")
        }
        if ($uniPct -ge 10) {
            $flags.Add("Unicode class names — $uniPct% of classes use non-ASCII characters")
        }

        $knownLegitModIds = @(
            "vmp-fabric","vmp","lithium","sodium","iris","fabric-api",
            "modmenu","ferrite-core","lazydfu","starlight","entityculling",
            "memoryleakfix","krypton","c2me-fabric","smoothboot-fabric",
            "immediatelyfast","noisium","threadtweak"
        )
        $dangerCount = ($flags | Where-Object {
            $_ -match "Runtime\.exec|HTTP file download|HTTP POST|Heavy obfuscation|Suspicious nested JAR"
        }).Count
        if ($outerModId -and ($knownLegitModIds -contains $outerModId) -and $dangerCount -gt 0) {
            $flags.Add("Fake mod identity — claims to be '$outerModId' but contains dangerous code")
        }

    } catch { }

    return $flags
}

function Invoke-JvmScan {
    $results = [System.Collections.Generic.List[string]]::new()

    $javaProc = Get-Process javaw -ErrorAction SilentlyContinue
    if (-not $javaProc) { $javaProc = Get-Process java -ErrorAction SilentlyContinue }
    if (-not $javaProc) { return $results }

    $javaPid = ($javaProc | Select-Object -First 1).Id

    try {
        $wmi     = Get-WmiObject Win32_Process -Filter "ProcessId = $javaPid" -ErrorAction Stop
        $cmdLine = $wmi.CommandLine

        if ($cmdLine) {
            $agentMatches = [regex]::Matches($cmdLine, '-javaagent:([^\s"]+)')
            foreach ($m in $agentMatches) {
                $agentPath = $m.Groups[1].Value.Trim('"').Trim("'")
                $agentName = [System.IO.Path]::GetFileName($agentPath)
                $legitAgents = @("jmxremote","yjp","jrebel","newrelic","jacoco","theseus")
                $isLegit = $false
                foreach ($la in $legitAgents) { if ($agentName -match $la) { $isLegit = $true; break } }
                if (-not $isLegit) {
                    $results.Add("JVM Agent — -javaagent:$agentName (path: $agentPath)")
                }
            }

            $suspiciousFlags = @(
                @{ Flag = "-Xbootclasspath/p:"; Desc = "prepends to bootstrap classpath, overrides core Java classes" },
                @{ Flag = "-Xbootclasspath/a:"; Desc = "appends to bootstrap classpath, injects below classloader" },
                @{ Flag = "-agentlib:jdwp";     Desc = "JDWP debug agent, remote debugging enabled" },
                @{ Flag = "-agentpath:";         Desc = "native agent loaded, bypasses Java sandbox" }
            )
            foreach ($sf in $suspiciousFlags) {
                if ($cmdLine -match [regex]::Escape($sf.Flag)) {
                    $results.Add("Suspicious JVM flag — $($sf.Flag) ($($sf.Desc))")
                }
            }
        }
    } catch { }

    return $results
}

$v = @(); $u = @(); $s = @(); $b = @(); $o = @()

try { $jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction Stop } catch {
    Write-Host "err: $_"; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit 1
}
if ($jarFiles.Count -eq 0) { Write-Host "no jars found"; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit 0 }

Write-Host "  $($jarFiles.Count) jar(s)" -ForegroundColor Green
Write-Host ""

$i=0; $t=$jarFiles.Count; $sp="/-\|"

# 1 hash
Write-Host "  1/5 hashing" -ForegroundColor DarkGray
foreach ($jf in $jarFiles) {
    $i++; Write-Host "`r  $($sp[$i%4]) $i/$t $($jf.Name)" -NoNewline
    $h = Get-FileSHA1 -Path $jf.FullName
    if ($h) {
        $md = Query-Modrinth -Hash $h
        if ($md.Slug) { $v += [PSCustomObject]@{ N=$md.Name; F=$jf.Name; W=@("viafabricplus","viafabricversion") -contains $md.Slug.ToLower() }; continue }
        $mg = Query-Megabase -Hash $h
        if ($mg.name) { $v += [PSCustomObject]@{ N=$mg.name; F=$jf.Name; W=$false }; continue }
    }
    $u += [PSCustomObject]@{ F=$jf.Name; S=Get-DownloadSource $jf.FullName }
}; Write-Host "`r"+" "*80+"`r" -NoNewline

# 2 patterns
$i=0; Write-Host "  2/5 patterns" -ForegroundColor DarkGray
foreach ($jf in $jarFiles) {
    $i++; Write-Host "`r  $($sp[$i%4]) $i/$t $($jf.Name)" -NoNewline
    if (($v|?{$_.F -eq $jf.Name -and $_.W}).Count) { continue }
    $r = Invoke-ModScan -FilePath $jf.FullName
    if ($r.Patterns.Count -gt 0 -or $r.Strings.Count -gt 0 -or $r.Fullwidth.Count -gt 0) {
        $s += [PSCustomObject]@{ F=$jf.Name; P=$r.Patterns; Str=$r.Strings; Fw=$r.Fullwidth }
        $v = $v|?{$_.F -ne $jf.Name}
    }
}; Write-Host "`r"+" "*80+"`r" -NoNewline

# 3 bypass
$i=0; Write-Host "  3/5 bypass" -ForegroundColor DarkGray
foreach ($jf in $jarFiles) {
    $i++; Write-Host "`r  $($sp[$i%4]) $i/$t $($jf.Name)" -NoNewline
    if (($v|?{$_.F -eq $jf.Name -and $_.W}).Count) { continue }
    $bf = Invoke-BypassScan -FilePath $jf.FullName
    if ($bf.Count) { $b += [PSCustomObject]@{ F=$jf.Name; Fl=$bf }; $v=$v|?{$_.F -ne $jf.Name}; $u=$u|?{$_.F -ne $jf.Name} }
}; Write-Host "`r"+" "*80+"`r" -NoNewline

# 4 obf
$i=0; Write-Host "  4/5 obfuscation" -ForegroundColor DarkGray
foreach ($jf in $jarFiles) {
    $i++; Write-Host "`r  $($sp[$i%4]) $i/$t $($jf.Name)" -NoNewline
    $of = Invoke-ObfuscationScan -FilePath $jf.FullName
    if ($of.Count) {
        $af = ($s|?{$_.F -eq $jf.Name}).Count -gt 0 -or ($b|?{$_.F -eq $jf.Name}).Count -gt 0
        if (-not $af) { $o += [PSCustomObject]@{ F=$jf.Name; Fl=$of }; $v=$v|?{$_.F -ne $jf.Name} }
    }
}; Write-Host "`r"+" "*80+"`r" -NoNewline

# 5 jvm
Write-Host "  5/5 jvm" -ForegroundColor DarkGray
$j = Invoke-JvmScan
Write-Host ("  -> " + $(if ($j.Count -gt 0) { "$($j.Count) issue(s)" } else { "clean" })) -ForegroundColor DarkGray

# results
Write-Host ""

if ($v) { $v|%{ Write-Host "  [$($_.N)]" -ForegroundColor Green -NoNewline; Write-Host " $($_.F)" -ForegroundColor DarkGray } }
if ($u) { $u|%{ $x=if($_.S){" ($($_.S))"}else{""}; Write-Host "  [?]$($_.F)$x" -ForegroundColor Yellow } }
if ($s) { $s|%{ Write-Host "  [!] $($_.F)" -ForegroundColor Red; $ps=$_.P; $_.P|%{ Write-Host "    p:$_" -ForegroundColor Red }; $_.Str|?{$ps -notcontains $_}|%{ Write-Host "    s:$_" -ForegroundColor DarkYellow }; $_.Fw|%{ Write-Host "    fw:$_" -ForegroundColor Cyan } } }
if ($b) { $b|%{ Write-Host "  [#] $($_.F)" -ForegroundColor Magenta; $_.Fl|%{ Write-Host "    $_" -ForegroundColor White } } }
if ($o) { $o|%{ Write-Host "  [%] $($_.F)" -ForegroundColor DarkYellow; $_.Fl|%{ Write-Host "    $_" -ForegroundColor Gray } } }
if ($j) { $j|%{ Write-Host "  [JVM] $_" -ForegroundColor Yellow } }

Write-Host ""; Write-Host "-"*40 -ForegroundColor DarkGray
Write-Host "  S:$t OK:$($v.Count) ?:$($u.Count) !:$($s.Count) #:$($b.Count) %:$($o.Count) JVM:$($j.Count)" -ForegroundColor Gray
Write-Host "  any key" -ForegroundColor DarkGray; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
