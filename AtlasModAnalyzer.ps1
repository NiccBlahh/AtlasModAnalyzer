[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

# ==============================================================================
# SECTION 1: UI & INITIALIZATION
# ==============================================================================

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

# ==============================================================================
# SECTION 2: SIGNATURES & PATTERNS
# ==============================================================================

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
    "と.class", "み.class", "び.class", "す.class", "の.class",
    "activateKey", "checkPlace", "switchDelay", "switchChance", "placeDelay", "placeChance",
    "workWithTotem", "workWithCrystal", "clickSimulation", "swordSwap", "playersOnly",
    "requireClick", "visibilityCheck", "targetLock", "switchTargetKey",
    "minSpeed", "maxSpeed", "randomize", "targetBone", "weaponOnly",
    "lockedTarget", "switchKeyWasPressed", "lastFrame", "smoothTargetPos",
    "BufferState", "CalculateRange", "JoinerWriter", "keyBind", "NotifyResolver",
    "QueryZone", "RenderController", "StringDecoder", "TokenExtractor",
    "VerificationGuard", "YieldKeeper", "cfr",
    "guiKey", "redColor", "net.caffeinemc.mods.lithium"
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
    "No Count Glitch", "Ｎｏ ｃｏｊｎｔ Ｇｌｉｔｃｈ",
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
    "lockedTarget", "switchKeyWasPressed", "lastFrame", "smoothTargetPos",
    "BufferState", "CalculateRange", "JoinerWriter", "keyBind", "NotifyResolver",
    "QueryZone", "RenderController", "StringDecoder", "TokenExtractor",
    "VerificationGuard", "YieldKeeper", "cfr", "default.json",
    "guiKey", "redColor", "net/caffeinemc/mods/lithium/fabric/compat/core"
)

$patternRegex = [regex]::new(
    ('(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])'),
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

$cheatStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $cheatStrings) { [void]$cheatStringSet.Add($s) }

$fullwidthRegex = [regex]::new(
    "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}",
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

# ==============================================================================
# SECTION 3: UTILITIES & PARSERS
# ==============================================================================

# Parse JVM constant pool from class files to perfectly extract strings.
function Get-JavaClassStrings {
    param([byte[]]$Bytes)

    $strings = [System.Collections.Generic.List[string]]::new()
    if ($Bytes.Length -lt 10) { return $strings }

    # Check Magic 0xCAFEBABE
    if ($Bytes[0] -ne 0xCA -or $Bytes[1] -ne 0xFE -or $Bytes[2] -ne 0xBA -or $Bytes[3] -ne 0xBE) {
        # Fallback to UTF-8 regex matching if not a class file
        $utf8Str = [System.Text.Encoding]::UTF8.GetString($Bytes)
        $matches = [System.Text.RegularExpressions.Regex]::Matches($utf8Str, '[\x20-\x7E\uFF00-\uFFEF]{4,}')
        foreach ($m in $matches) { [void]$strings.Add($m.Value) }
        return $strings
    }

    try {
        $stream = [System.IO.MemoryStream]::new($Bytes)
        $reader = [System.IO.BinaryReader]::new($stream)

        # Skip magic (4), minor_version (2), major_version (2)
        $null = $reader.ReadBytes(8)

        # Read Constant Pool count
        $cpCountBytes = $reader.ReadBytes(2)
        [Array]::Reverse($cpCountBytes)
        $cpCount = [System.BitConverter]::ToUInt16($cpCountBytes, 0)

        $i = 1
        while ($i -lt $cpCount) {
            $tag = $reader.ReadByte()
            switch ($tag) {
                1 { # CONSTANT_Utf8
                    $lenBytes = $reader.ReadBytes(2)
                    [Array]::Reverse($lenBytes)
                    $len = [System.BitConverter]::ToUInt16($lenBytes, 0)
                    $strBytes = $reader.ReadBytes($len)
                    $str = [System.Text.Encoding]::UTF8.GetString($strBytes)
                    [void]$strings.Add($str)
                    $i++
                }
                3 { $null = $reader.ReadBytes(4); $i++ }
                4 { $null = $reader.ReadBytes(4); $i++ }
                5 { $null = $reader.ReadBytes(8); $i += 2 }
                6 { $null = $reader.ReadBytes(8); $i += 2 }
                7 { $null = $reader.ReadBytes(2); $i++ }
                8 { $null = $reader.ReadBytes(2); $i++ }
                16 { $null = $reader.ReadBytes(2); $i++ }
                19 { $null = $reader.ReadBytes(2); $i++ }
                20 { $null = $reader.ReadBytes(2); $i++ }
                9 { $null = $reader.ReadBytes(4); $i++ }
                10 { $null = $reader.ReadBytes(4); $i++ }
                11 { $null = $reader.ReadBytes(4); $i++ }
                12 { $null = $reader.ReadBytes(4); $i++ }
                17 { $null = $reader.ReadBytes(4); $i++ }
                18 { $null = $reader.ReadBytes(4); $i++ }
                15 { $null = $reader.ReadBytes(3); $i++ }
                default {
                    # Stop parsing on unknown tags and fallback
                    throw "Unknown CP tag: $tag"
                }
            }
        }
        $reader.Close()
        $stream.Close()
    } catch {
        # Fallback to UTF-8 regex strings extraction
        $strings.Clear()
        $utf8Str = [System.Text.Encoding]::UTF8.GetString($Bytes)
        $matches = [System.Text.RegularExpressions.Regex]::Matches($utf8Str, '[\x20-\x7E\uFF00-\uFFEF]{4,}')
        foreach ($m in $matches) { [void]$strings.Add($m.Value) }
    }
    return $strings
}

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

# ==============================================================================
# SECTION 4: SCANNING ENGINES
# ==============================================================================

function Invoke-ModScan {
    param([string]$FilePath)

    $foundPatterns  = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings   = [System.Collections.Generic.HashSet[string]]::new()
    $foundFullwidth = [System.Collections.Generic.HashSet[string]]::new()

    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)

        # Collect nested JAR entries and other entries
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
            foreach ($m in $patternRegex.Matches($name)) { [void]$foundPatterns.Add($m.Value) }

            if ($name -match '\.(class|json)$' -or $name -match 'MANIFEST\.MF') {
                try {
                    $st = $entry.Open()
                    $ms2 = New-Object System.IO.MemoryStream
                    $st.CopyTo($ms2); $st.Close()
                    $bytes = $ms2.ToArray(); $ms2.Dispose()

                    # Robust extraction of exact strings using Java Constant Pool parser
                    $extractedStrings = Get-JavaClassStrings -Bytes $bytes

                    foreach ($str in $extractedStrings) {
                        # Scan strings for suspicious patterns
                        foreach ($m in $patternRegex.Matches($str)) { [void]$foundPatterns.Add($m.Value) }

                        # Match with cheat strings (case-insensitive)
                        foreach ($s in $cheatStringSet) {
                            if ($str.IndexOf($s, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                                [void]$foundStrings.Add($s)
                            }
                        }

                        # Match fullwidth characters
                        foreach ($m in $fullwidthRegex.Matches($str)) {
                            [void]$foundFullwidth.Add($m.Value)
                        }
                    }
                } catch { }
            }
        }

        foreach ($ia in $innerArchives) { try { $ia.Dispose() } catch { } }
        $archive.Dispose()
    } catch { }

    # Resolve fullwidth representation of cheat strings
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

        if ($numPct   -ge 20) { [void]$flags.Add("Numeric class names — $numPct% of classes have numeric-only names") }
        if ($uniPct   -ge 10) { [void]$flags.Add("Unicode class names — $uniPct% of classes use non-ASCII characters") }
        if ($fwPct    -gt  0) { [void]$flags.Add("Fullwidth Unicode class names — $fwPct% use ａｂｃ/ＡＢＣ/０１２ chars ($fullwidthCount classes)") }
        if ($jpPct    -gt  0) { [void]$flags.Add("Japanese obfuscation — $jpPct% use hiragana/katakana class names ($japaneseCount classes)") }
        if ($s1Pct    -ge 15) { [void]$flags.Add("Single-letter class names — $s1Pct% ($singleLetterCount classes)") }
        if ($s2Pct    -ge 20) { [void]$flags.Add("Two-letter class names — $s2Pct% ($twoLetterCount classes)") }
        if ($gibPct   -ge  5) { [void]$flags.Add("Gibberish class names — $gibPct% have no vowels / consonant clusters ($gibberishCount classes)") }
        if ($novPct   -ge  8) { [void]$flags.Add("No-vowel class names — $novPct% ($noVowelCount classes)") }
        if ($confPct  -ge  3) { [void]$flags.Add("Confusion-char names (Il1O0/_) — $confPct% ($confusionCount classes)") }
        if ($singleCharPkg -ge 6) { [void]$flags.Add("Single-char package paths — $singleCharPkg path segments like a/b/c") }

        $fwStringMatches = [regex]::Matches($contentSample.ToString(), "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}")
        if ($fwStringMatches.Count -gt 0) {
            $examples = ($fwStringMatches | Select-Object -First 3 | ForEach-Object { $_.Value }) -join ", "
            [void]$flags.Add("Fullwidth strings in class content — $($fwStringMatches.Count) occurrences (e.g. $examples)")
        }

        $sampleStr = $contentSample.ToString()
        foreach ($obfName in $cheatObfuscators.Keys) {
            foreach ($pat in $cheatObfuscators[$obfName]) {
                if ($sampleStr.Contains($pat)) {
                    [void]$flags.Add("Known cheat obfuscator detected — $obfName (matched: $pat)")
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
            [void]$flags.Add("Suspicious nested JAR — no version, unknown dependency: $sj")
        }

        if ($nestedJars.Count -eq 1 -and $outerClasses.Count -lt 3) {
            $njName = [System.IO.Path]::GetFileName(($nestedJars | Select-Object -First 1).FullName)
            [void]$flags.Add("Hollow shell — only $($outerClasses.Count) own class(es), wraps: $njName")
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
            [void]$flags.Add("Runtime.exec() in obfuscated code — can run arbitrary OS commands")
        }
        if ($httpDownloadFound) {
            [void]$flags.Add("HTTP file download — fetches and writes files from a remote server at runtime")
        }
        if ($httpExfilFound) {
            [void]$flags.Add("HTTP POST exfiltration — sends system data to an external server")
        }
        if ($totalClassCount -ge 10 -and $obfPct -ge 25) {
            [void]$flags.Add("Heavy obfuscation — $obfPct% of classes use single-letter path segments (a/b/c style)")
        }
        if ($numPct -ge 20) {
            [void]$flags.Add("Numeric class names — $numPct% of classes have numeric-only names (e.g. 1234.class)")
        }
        if ($uniPct -ge 10) {
            [void]$flags.Add("Unicode class names — $uniPct% of classes use non-ASCII characters")
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
            [void]$flags.Add("Fake mod identity — claims to be '$outerModId' but contains dangerous code")
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
        $cmdLine = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $javaPid" -ErrorAction SilentlyContinue).CommandLine
        if (-not $cmdLine) {
            $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $javaPid" -ErrorAction SilentlyContinue).CommandLine
        }

        if ($cmdLine) {
            $agentMatches = [regex]::Matches($cmdLine, '-javaagent:([^\s"]+)')
            foreach ($m in $agentMatches) {
                $agentPath = $m.Groups[1].Value.Trim('"').Trim("'")
                $agentName = [System.IO.Path]::GetFileName($agentPath)
                $legitAgents = @("jmxremote","yjp","jrebel","newrelic","jacoco","theseus")
                $isLegit = $false
                foreach ($la in $legitAgents) { if ($agentName -match $la) { $isLegit = $true; break } }
                if (-not $isLegit) {
                    [void]$results.Add("JVM Agent — -javaagent:$agentName (path: $agentPath)")
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
                    [void]$results.Add("Suspicious JVM flag — $($sf.Flag) ($($sf.Desc))")
                }
            }
        }
    } catch { }

    return $results
}

# ==============================================================================
# SECTION 5: MAIN EXECUTION ENTRY POINT
# ==============================================================================

$verifiedMods   = @()
$unverifiedMods = @()
$suspiciousMods = @()
$bypassMods     = @()
$obfuscatedMods = @()

try { $jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction Stop } catch {
    Write-Host "Error finding JAR files: $_" -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

if ($jarFiles.Count -eq 0) {
    Write-Host "No JAR files found in the mods directory." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host "  Found $($jarFiles.Count) jar(s)" -ForegroundColor Green
Write-Host ""

$i = 0
$total = $jarFiles.Count
$spinner = "/-\|"

# Phase 1: Hash Lookup & Verifications
Write-Host "  [1/5] Hashing & lookup..." -ForegroundColor DarkGray
foreach ($jf in $jarFiles) {
    $i++
    Write-Host "`r  $($spinner[$i % 4]) $i/$total $($jf.Name)" -NoNewline
    $h = Get-FileSHA1 -Path $jf.FullName
    if ($h) {
        $md = Query-Modrinth -Hash $h
        if ($md.Slug) {
            $verifiedMods += [PSCustomObject]@{ N = $md.Name; F = $jf.Name; W = @("viafabricplus","viafabricversion") -contains $md.Slug.ToLower() }
            continue
        }
        $mg = Query-Megabase -Hash $h
        if ($mg.name) {
            $verifiedMods += [PSCustomObject]@{ N = $mg.name; F = $jf.Name; W = $false }
            continue
        }
    }
    $unverifiedMods += [PSCustomObject]@{ F = $jf.Name; S = Get-DownloadSource $jf.FullName }
}
Write-Host "`r" + (" " * 80) + "`r" -NoNewline

# Phase 2: String & Pattern Scan
$i = 0
Write-Host "  [2/5] Scanning file signatures & strings..." -ForegroundColor DarkGray
foreach ($jf in $jarFiles) {
    $i++
    Write-Host "`r  $($spinner[$i % 4]) $i/$total $($jf.Name)" -NoNewline
    if (($verifiedMods | Where-Object { $_.F -eq $jf.Name }).Count) { continue }
    $r = Invoke-ModScan -FilePath $jf.FullName
    if ($r.Patterns.Count -gt 0 -or $r.Strings.Count -gt 0 -or $r.Fullwidth.Count -gt 0) {
        $suspiciousMods += [PSCustomObject]@{ F = $jf.Name; P = $r.Patterns; Str = $r.Strings; Fw = $r.Fullwidth }
        $verifiedMods = $verifiedMods | Where-Object { $_.F -ne $jf.Name }
    }
}
Write-Host "`r" + (" " * 80) + "`r" -NoNewline

# Phase 3: Bypass & Sandbox Breach Scan
$i = 0
Write-Host "  [3/5] Checking sandbox/bypass vectors..." -ForegroundColor DarkGray
foreach ($jf in $jarFiles) {
    $i++
    Write-Host "`r  $($spinner[$i % 4]) $i/$total $($jf.Name)" -NoNewline
    if (($verifiedMods | Where-Object { $_.F -eq $jf.Name }).Count) { continue }
    $bf = Invoke-BypassScan -FilePath $jf.FullName
    if ($bf.Count) {
        $bypassMods += [PSCustomObject]@{ F = $jf.Name; Fl = $bf }
        $verifiedMods = $verifiedMods | Where-Object { $_.F -ne $jf.Name }
        $unverifiedMods = $unverifiedMods | Where-Object { $_.F -ne $jf.Name }
    }
}
Write-Host "`r" + (" " * 80) + "`r" -NoNewline

# Phase 4: Obfuscation Fingerprinting
$i = 0
Write-Host "  [4/5] Analyzing obfuscation footprint..." -ForegroundColor DarkGray
foreach ($jf in $jarFiles) {
    $i++
    Write-Host "`r  $($spinner[$i % 4]) $i/$total $($jf.Name)" -NoNewline
    if (($verifiedMods | Where-Object { $_.F -eq $jf.Name }).Count) { continue }
    $of = Invoke-ObfuscationScan -FilePath $jf.FullName
    if ($of.Count) {
        $isFlagged = ($suspiciousMods | Where-Object { $_.F -eq $jf.Name }).Count -gt 0 -or ($bypassMods | Where-Object { $_.F -eq $jf.Name }).Count -gt 0
        if (-not $isFlagged) {
            $obfuscatedMods += [PSCustomObject]@{ F = $jf.Name; Fl = $of }
            $verifiedMods = $verifiedMods | Where-Object { $_.F -ne $jf.Name }
        }
    }
}
Write-Host "`r" + (" " * 80) + "`r" -NoNewline

# Phase 5: Active JVM Diagnostics
Write-Host "  [5/5] Performing active JVM diagnostic..." -ForegroundColor DarkGray
$jvmIssues = Invoke-JvmScan
$statusMsg = if ($jvmIssues.Count -gt 0) { "$($jvmIssues.Count) issue(s) found" } else { "clean" }
Write-Host "  -> JVM State: $statusMsg" -ForegroundColor DarkGray
Write-Host ""

# ==============================================================================
# SECTION 6: DISPLAY RESULTS
# ==============================================================================

Write-Host ("=" * 50) -ForegroundColor DarkGray
Write-Host "                     RESULTS" -ForegroundColor White
Write-Host ("=" * 50) -ForegroundColor DarkGray

# Build lookup state map
$lookupMap = @{}
$verifiedMods   | ForEach-Object { $lookupMap[$_.F] = "OK" }
$unverifiedMods | ForEach-Object { $lookupMap[$_.F] = "?" }
$suspiciousMods | ForEach-Object { $lookupMap[$_.F] = "!" }
$bypassMods     | ForEach-Object { $lookupMap[$_.F] = "#" }
$obfuscatedMods | ForEach-Object { $lookupMap[$_.F] = "%" }

# Print status block per JAR
foreach ($jf in $jarFiles) {
    $n = $jf.Name
    $color = "DarkGray"
    
    switch ($lookupMap[$n]) {
        "OK" { $color = "Green" }
        "?"  { $color = "Yellow" }
        "!"  { $color = "Red" }
        "#"  { $color = "Magenta" }
        "%"  { $color = "DarkYellow" }
    }

    Write-Host ("  [{0}] {1}" -f $lookupMap[$n], $n) -ForegroundColor $color
    
    if ($lookupMap[$n] -eq "OK") {
        $res = $verifiedMods | Where-Object { $_.F -eq $n }
        if ($res) { Write-Host ("       Known clean: $($res[0].N)") -ForegroundColor DarkGray }
    }
    if ($lookupMap[$n] -eq "?")  {
        $res = $unverifiedMods | Where-Object { $_.F -eq $n }
        if ($res -and $res[0].S) { Write-Host ("       Source: $($res[0].S)") -ForegroundColor DarkGray }
    }
    if ($lookupMap[$n] -eq "!")  {
        $res = $suspiciousMods | Where-Object { $_.F -eq $n }
        if ($res) {
            $pats = $res[0].P
            $res[0].P   | ForEach-Object { Write-Host ("       Pattern match: $_") -ForegroundColor Red }
            $res[0].Str | Where-Object { $pats -notcontains $_ } | ForEach-Object { Write-Host ("       Cheat String: $_") -ForegroundColor DarkYellow }
            $res[0].Fw  | ForEach-Object { Write-Host ("       Fullwidth: $_") -ForegroundColor Cyan }
        }
    }
    if ($lookupMap[$n] -eq "#")  {
        $res = $bypassMods | Where-Object { $_.F -eq $n }
        if ($res) { $res[0].Fl | ForEach-Object { Write-Host ("       $_") -ForegroundColor White } }
    }
    if ($lookupMap[$n] -eq "%")  {
        $res = $obfuscatedMods | Where-Object { $_.F -eq $n }
        if ($res) { $res[0].Fl | ForEach-Object { Write-Host ("       $_") -ForegroundColor Gray } }
    }
}

if ($jvmIssues.Count -gt 0) {
    Write-Host ""
    Write-Host "  [Active JVM Diagnostics]" -ForegroundColor Yellow
    $jvmIssues | ForEach-Object { Write-Host ("       $_") -ForegroundColor Yellow }
}

Write-Host ""
Write-Host ("=" * 50) -ForegroundColor DarkGray
Write-Host "  Total Files: $total | OK:$($verifiedMods.Count) | Unverified(?):$($unverifiedMods.Count) | Flagged(!):$($suspiciousMods.Count) | Sandbox Bypass(#):$($bypassMods.Count) | Obfuscated(%):$($obfuscatedMods.Count)" -ForegroundColor Gray
Write-Host "  Press any key to complete..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
