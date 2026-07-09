$ErrorActionPreference = "SilentlyContinue"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Host.UI.RawUI.WindowTitle = "Atlas Mod Analyzer"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

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

function Show-Banner {
    Clear-Host
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "               Minecraft Mod / Cheat-Client Scanner" -ForegroundColor DarkCyan
    Write-Host ("=" * 66) -ForegroundColor DarkGray
    Write-Host ""
}

$global:stopScan    = $false
$global:reportLines = [System.Collections.Generic.List[string]]::new()

function Get-ConsoleColorForHex {
    param([string]$hex)
    switch ($hex) {
        "#64B5F6" { return "Cyan" }
        "#00FFFF" { return "Cyan" }
        "#AAAAAA" { return "DarkGray" }
        "#888888" { return "DarkGray" }
        "#9E9E9E" { return "Gray" }
        "#CCCCCC" { return "Gray" }
        "#E53935" { return "Red" }
        "#EF5350" { return "Red" }
        "#FFB74D" { return "Yellow" }
        "#FFF176" { return "Yellow" }
        "#81C784" { return "Green" }
        "#FFFFFF" { return "White" }
        default   { return "Gray" }
    }
}

function Append-Log {
    param([string]$text, [string]$color = "#CCCCCC", [switch]$Bold)
    if ($global:stopScan) { return }
    [void]$global:reportLines.Add($text)
    $cc = Get-ConsoleColorForHex $color
    Write-Host $text -ForegroundColor $cc
}

function Test-StopRequested {
    try {
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($key.Character -eq 'q' -or $key.Character -eq 'Q') {
                $global:stopScan = $true
            }
        }
    } catch { }
}

# ---------- PATTERN LISTS ----------
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
    "AutoPotRefill", "KeyPearl", "AutoNethPot", "AutoDtap",
    "AutoWeb", "AnchorAction",

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
    "ＡｕｔｏＣｒｙｓｔａｌ", "Ａｕｔｏ Ｃｒｙｓｔａｌ",
    "ＡｕｔｏＨｉｔＣｒｙｓｔａｌ",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor",
    "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "SafeAnchor", "AirAnchor",
    "ＡｕｔｏＡｎｃｈｏｒ", "Ａｕｔｏ Ａｎｃｈｏｒ",
    "ＤｏｕｂｌｅＡｎｃｈｏｒ", "Ｄｏｕｂｌｅ Ａｎｃｈｏｒ",
    "ＳａｆｅＡｎｃｈｏｒ", "Ｓａｆｅ Ａｎｃｈｏｒ",
    "Ａｎｃｈｏｒ Ｍａｃｒｏ", "anchorMacro",
    "AutoTotem", "autototem", "auto totem", "InventoryTotem",
    "inventorytotem", "HoverTotem", "hover totem", "legittotem",
    "ＡｕｔｏＴｏｔｅｍ", "Ａｕｔｏ Ｔｏｔｅｍ",
    "ＨｏｖｅｒＴｏｔｅｍ", "Ｈｏｖｅｒ Ｔｏｔｅｍ",
    "ＩｎｖｅｎｔｏｒｙＴｏｔｅｍ", "Ａｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
    "Ａｕｔｏ Ｔｏｔｅｍ Ｈｉｔ",
    "AutoPot", "autopot", "auto pot", "speedPotSlot", "strengthPotSlot",
    "AutoArmor", "autoarmor", "auto armor",
    "ＡｕｔｏＰｏｔ", "Ａｕｔｏ Ｐｏｔ",
    "Ａｕｔｏ Ｐｏｔ Ｒｅｆｉｌｌ", "AutoPotRefill",
    "ＡｕｔｏＡｒｍｏｒ", "Ａｕｔｏ Ａｒｍｏｒ",
    "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "ShieldDisabler", "ShieldBreaker",
    "ＳｈｉｅｌｄＤｉｓａｂｌｅｒ", "Ｓｈｉｅｌｄ Ｄｉｓａｂｌｅｒ",
    "Breaking shield with axe...",
    "AutoDoubleHand", "autodoublehand", "auto double hand",
    "ＡｕｔｏＤｏｗｂｌｅＨａｎｄ", "Ａｕｔｏ Ｄｏｗｂｌｅ Ｈａｎｄ",
    "AutoClicker",
    "ＡｕｔｏＣｌｉｃｋｅｒ",
    "Failed to switch to mace after axe!",
    "AutoMace", "MaceSwap", "SpearSwap",
    "ＡｕｔｏＭａｃｅ", "Ａｕｔｏ Ｍａｃｅ",
    "ＭａｃｅＳｗａｐ", "Ｍａｃｅ Ｓｗａｐ",
    "Ｓｐｅａｒ Ｓｗａｐ", "Ａｕｔｏｍａｔｉｃａｌｌｙ ａｘｅ ａｎｄ ｍａｃｅ ｓｈｉｅｌｄｅｄ ｐｌａｙｅｒｓ",
    "Ｓｔｗｎ Ｓｌａｍ", "StunSlam",
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
    "Ｆａｋｅ Ｐｗｎｃｈ",
    "𝐌𝐨𝐝𝐮𝐥𝐞𝐬",
    "𝐂𝐨𝐧𝐟𝐢𝐠𝐬",
    "𝐄𝐍𝐀𝐁𝐋𝐄𝐃",
    "𝐃𝐈𝐒𝐀𝐁𝐋𝐄𝐃",
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
    "Ａｎｔｉ Ｗｅｂ", "ＡｗｔｏＷｅｂ",
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
    "FreezePlayer","VirtualMachine",
    "Ｆｒｅｅｃａｍ", "Ｍｏｖｅ ｆｒｅｅｌｙ ｔｈｒｏｗｇｈ ｗａｌｌｓ",
    "Ｎｏ Ｃｌｉｐ", "Ｆｒｅｅｚｅ Ｐｌａｙｅｒ",
    "LWFH Crystal", "JDWP.VirtualMachine.AllModules",
    "ＬＷＦＨ Ｃｒｙｓｔａｌ",
    "KeyPearl", "LootYeeter",
    "ＫｅｙＰｅａｒｌ", "Ｋｅｙ Ｐｅａｒｌ",
    "Ｌｏｏｔ Ｙｅｅｔｅｒ",
    "FastPlace",
    "Ｆａｓｔ Ｐｌａｃｅ", "Ｐｌａｃｅ ｂｌｏｃｋｓ ｆａｓｔｅｒ",
    "AutoBreach",
    "Ａｗｔｏ Ｂｒｅａｃｈ",
    "setBlockBreakingCooldown", "getBlockBreakingCooldown", "blockBreakingCooldown",
    "onBlockBreaking", "setItemUseCooldown",
    "setSelectedSlot", "invokeDoAttack", "invokeDoItemUse", "invokeOnMouseButton",
    "onPushOutOfBlocks", "onIsGlowing",
    "Automatically switches to sword when hitting with totem",
    "arrayOfString", "POT_CHEATS",
    "Dqrkis Client", "Entity.isGlowing",
    "Activate Key", "Ａｃｔｉｖａｔｅ Ｋｅｙ",
    "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ",
    "On RMB", "Ｏｎ ＲＭＢ",
    "No Count Glitch", "Ｎｏ Ｃｏｗｎｔ Ｇｌｉｔｃｈ",
    "No Bounce", "NoBounce", "Ｎｏ Ｂｏｗｎｃｅ", "ＮｏＢｏｗｎｃｅ",
    "Ｒｅｍｏｖｅｓ ｔｈｅ ｃｒｙｓｔａｌ ｂｏｗｎｃｅ ａｎｉｍａｔｉｏｎ",
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
    "Auto Switch Back", "Ａｗｔｏ Ｓｗｉｔｃｈ Ｂａｃｋ",
    "Check Line of Sight", "Ｃｈｅｃｋ Ｌｉｎｅ ｏｆ Ｓｉｇｈｔ",
    "Only When Falling", "Ｏｎｌｙ Ｗｈｅｎ Ｆａｌｌｉｎｇ",
    "Require Crit", "Ｒｅｑｊｉｒｅ Ｃｒｉｔ",
    "Show Status Display", "Ｓｈｏｗ Ｓｔａｔｊｓ Ｄｉｓｐｌａｙ",
    "Stop On Crystal", "Ｓｔｏｐ Ｏｎ Ｃｒｙｓｔａｌ",
    "Check Shield", "Ｃｈｅｃｋ Ｓｈｉｅｌｄ",
    "On Pop", "Ｏｎ Ｐｏｐ",
    "Predict Damage", "Ｐｒｅｄｉｃｔ Ｄａｍａｇｅ",
    "On Ground", "Ｏｎ Ｇｒｏｗｎｄ",
    "Check Players", "Ｃｈｅｃｋ Ｐｌａｙｅｒｓ",
    "Predict Crystals", "Ｐｒｅｄｉｃｔ Ｃｒｙｓｔａｌｓ",
    "Check Aim", "Ｃｈｅｃｋ Ａｉｍ",
    "Check Items", "Ｃｈｅｃｋ Ｉｔｅｍｓ",
    "Activates Above", "Ａｃｔｉｖａｔｅｓ Ａｂｏｖｅ",
    "Blatant", "Ｂｌａｔａｎｔ",
    "Force Totem", "Ｆｏｒｃｅ Ｔｏｔｅｍ",
    "Stay Open For", "Ｓｔａｙ Ｏｐｅｎ Ｆｏｒ",
    "Auto Inventory Totem", "Ａｗｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
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
    "Ｒｅｆｉｌｌｓ ｙｏｗｒ ｈｏｔｂａｒ ｗｉｔｈ ｐｏｔｉｏｎｓ",
    "Ｋｅｐｓ ｙｏｗｒ ｓｐｒｉｎｔｉｎｇ ａｔ ａｌｌ ｔｉｍｅｓ",
    "Ｐｌａｃｅｓ ａｎｃｈｏｒ， ｃｈａｒｇｅｓ ｉｔ， ｐｒｏｔｅｃｔｓ ｙｏｗｒ， ａｎｄ ｅｘｐｌｏｄｅｓ",
    "Ａｗｔｏ ｓｗａｐ ｔｏ ｓｐｅａｒ ｏｎ ａｔｔａｃｋ",
    "Macro Key", "Ａｗｔｏ Ｐｏｔ", "Ｍａｃｒｏ Ｋｅｙ",
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
    "FakeNick", "PopSwitch",
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

    "activateKey", "checkPlace", "switchDelay", "switchChance",
    "placeDelay", "placeChance", "workWithTotem", "workWithCrystal",
    "clickSimulation", "swordSwapplayersOnly", "requireClick",
    "visibilityCheck", "targetLock", "switchTargetKey",
    "minSpeed", "maxSpeed", "randomize", "targetBone", "weaponOnly",
    "lockedTarget", "switchKeyWasPressed", "lastFrame", "smoothTargetPos",
    "S.afe hor", "Action Speed", "Switch Wait Time", "Totem Sl",
    "Rotation Sp", "Use Easing", "Easing S", "chestplate"
)

$suspiciousPatterns = @($suspiciousPatterns | Select-Object -Unique)
$cheatStrings       = @($cheatStrings       | Select-Object -Unique)

$fullwidthRegex = [regex]::new("[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}", [System.Text.RegularExpressions.RegexOptions]::Compiled)
$escapedPatterns = $suspiciousPatterns | ForEach-Object { [regex]::Escape($_) }
$patternRegex = [regex]::new('(?<![A-Za-z])(' + ($escapedPatterns -join '|') + ')(?![A-Za-z])', [System.Text.RegularExpressions.RegexOptions]::Compiled)

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

# --- CORE SCAN FUNCTIONS (enhanced with Meow scan logic) ---

function Invoke-ModScan {
    param([string]$FilePath, [switch]$DeepScan)
    $foundPatterns  = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings   = [System.Collections.Generic.HashSet[string]]::new()
    $foundFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    $archive = $null
    $innerArchives = [System.Collections.Generic.List[object]]::new()
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $allEntries = [System.Collections.Generic.List[object]]::new()

        foreach ($entry in $archive.Entries) {
            if ($global:stopScan) { return @{ Patterns = $foundPatterns; Strings = $foundStrings; Fullwidth = $foundFullwidth } }
            foreach ($m in $patternRegex.Matches($entry.FullName)) { [void]$foundPatterns.Add($m.Value) }
            $allEntries.Add($entry)
        }

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
            if ($global:stopScan) { return @{ Patterns = $foundPatterns; Strings = $foundStrings; Fullwidth = $foundFullwidth } }
            $name = $entry.FullName

            $shouldRead = ($name -match 'MANIFEST\.MF') -or ($DeepScan -and $name -match '\.(class|json)$')
            if ($shouldRead) {
                try {
                    $st = $entry.Open(); $ms2 = New-Object System.IO.MemoryStream
                    $st.CopyTo($ms2); $st.Close()
                    $bytes = $ms2.ToArray(); $ms2.Dispose()
                    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
                    $utf8  = [System.Text.Encoding]::UTF8.GetString($bytes)
                    foreach ($m in $patternRegex.Matches($ascii)) { [void]$foundPatterns.Add($m.Value) }
                    foreach ($s in $cheatStringSet) {
                        if ($ascii.Contains($s, [System.StringComparison]::Ordinal)) { [void]$foundStrings.Add($s); continue }
                        if ($utf8.Contains($s, [System.StringComparison]::Ordinal))  { [void]$foundStrings.Add($s) }
                    }
                    foreach ($m in $fullwidthRegex.Matches($utf8)) { [void]$foundFullwidth.Add($m.Value) }
                } catch { }
            }

            if ($DeepScan -and $name -match '\.(class|json)$') {
                try {
                    $st = $entry.Open(); $ms2 = New-Object System.IO.MemoryStream
                    $st.CopyTo($ms2); $st.Close()
                    $bytes = $ms2.ToArray(); $ms2.Dispose()

                    $contentTypes = @(
                        @{ Encoding = [System.Text.Encoding]::ASCII; Set = $foundPatterns; Func = { param($c,$p) foreach ($m in $patternRegex.Matches($c)) { [void]$p.Add($m.Value) } }},
                        @{ Encoding = [System.Text.Encoding]::ASCII; Set = $foundStrings; Func = { param($c,$p) foreach ($s in $cheatStringSet) { if ($c.Contains($s, [System.StringComparison]::Ordinal)) { [void]$p.Add($s) } }}},
                        @{ Encoding = [System.Text.Encoding]::UTF8; Set = $foundStrings; Func = { param($c,$p) foreach ($s in $cheatStringSet) { if ($c.Contains($s, [System.StringComparison]::Ordinal)) { [void]$p.Add($s) } }}},
                        @{ Encoding = [System.Text.Encoding]::UTF8; Set = $foundFullwidth; Func = { param($c,$p) foreach ($m in $fullwidthRegex.Matches($c)) { [void]$p.Add($m.Value) }}}
                    )
                } catch { }
            }
        }
    } catch {
        [void]$foundStrings.Add("[scan error: $($_.Exception.Message)]")
    } finally {
        foreach ($ia in $innerArchives) { try { $ia.Dispose() } catch { } }
        if ($archive) { try { $archive.Dispose() } catch { } }
    }

    $fwCheatPool = @($cheatStrings | Where-Object { $_ -cmatch "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]" })
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
    param([string]$FilePath, [switch]$DeepScan)
    $flags = [System.Collections.Generic.List[string]]::new()
    $archive = $null
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
            "Allatori"       = @("Allatori","allatori","com/allatori","allatori.obf")
            "DashO"          = @("DashO","dasho","com/dasho","preEmptive.DashO")
            "MinecraftSelfObf"= @("selfObf","selfobf","minecraft/Obfuscation","magic/Obfuscator")
            "NameObfuscation" = @("NameObfuscation","nameObfuscator","renameObf")
            "XenForgeObf"    = @("xenforgewrapper","XenForge","xenforge.obf")
            "SandboxObf"     = @("sandbox_obf","SandboxObfuscator")
            "Morphii"        = @("morphii","MorphiiObf","morph.obf")
            "JavaCrack"      = @("javamc.obf","MCrack","mcObfuscator")
        }

        foreach ($entry in $archive.Entries) {
            if ($global:stopScan) { return $flags }
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
            }
        }

        if ($totalClass -lt 5) { return $flags }

        $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }
        $numPct  = & $pct $numericCount;  $uniPct  = & $pct $unicodeCount;  $fwPct = & $pct $fullwidthCount
        $jpPct   = & $pct $japaneseCount; $s1Pct   = & $pct $singleLetterCount; $s2Pct = & $pct $twoLetterCount
        $gibPct  = & $pct $gibberishCount; $novPct = & $pct $noVowelCount; $confPct = & $pct $confusionCount
        if ($numPct  -ge 20) { $flags.Add("Numeric class names - $numPct% of classes have numeric-only names") }
        if ($uniPct  -ge 10) { $flags.Add("Unicode class names - $uniPct% of classes use non-ASCII characters") }
        if ($fwPct   -gt  0) { $flags.Add("Fullwidth Unicode class names - $fwPct% use fullwidth chars") }
        if ($jpPct   -gt  0) { $flags.Add("Japanese obfuscation - $jpPct% use hiragana/katakana names") }
        if ($s1Pct   -ge 15) { $flags.Add("Single-letter class names - $s1Pct%") }
        if ($s2Pct   -ge 20) { $flags.Add("Two-letter class names - $s2Pct%") }
        if ($gibPct  -ge 5) { $flags.Add("Gibberish class names - $gibPct% have no vowels/consonant clusters") }
        if ($novPct  -ge 8) { $flags.Add("No-vowel class names - $novPct%") }
        if ($confPct -ge 3) { $flags.Add("Confusion-char names (Il1O0/_) - $confPct%") }
        if ($singleCharPkg -ge 6) { $flags.Add("Single-char package paths - $singleCharPkg path segments like a/b/c") }

        if ($DeepScan) {
            foreach ($entry in $archive.Entries) {
                if ($global:stopScan) { return $flags }
                $name = $entry.FullName
                if ($name -match "\.class$" -and $sampleSize -lt 150000 -and $entry.Length -lt 100000 -and $entry.Length -gt 100) {
                    try {
                        $st = $entry.Open(); $ms = New-Object System.IO.MemoryStream
                        $st.CopyTo($ms); $st.Close()
                        $ascii = [System.Text.Encoding]::ASCII.GetString($ms.ToArray()); $ms.Dispose()
                        [void]$contentSample.Append($ascii); $sampleSize += $ascii.Length
                    } catch { }
                }
            }

            $sampleStr = $contentSample.ToString()
            $fwStringMatches = [regex]::Matches($sampleStr, "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}")
            if ($fwStringMatches.Count -gt 0) {
                $flags.Add("Fullwidth strings in class content - $($fwStringMatches.Count) occurrences")
            }

            foreach ($obfName in $cheatObfuscators.Keys) {
                foreach ($pat in $cheatObfuscators[$obfName]) {
                    if ($sampleStr.Contains($pat)) { $flags.Add("Known cheat obfuscator detected - $obfName (matched: $pat)"); break }
                }
            }

            $obfStringPatterns = @(
                @{Pattern='(?i)(?:string|str)_(?:obf|enc|crypt|hide|mangle)'; Label='String obfuscation methods'},
                @{Pattern='(?i)decrypt(?:String|Str|Key|Payload)'; Label='Decryption methods present'},
                @{Pattern='(?i)\.(?:obfuscate|deobfuscate|remap|rename)\(?\)'; Label='Obfuscation API calls'},
                @{Pattern='(?i)(?:class|method|field)_(?:mapping|remap|rename|transform)'; Label='Runtime mapping/remap methods'}
            )
            foreach ($obfPat in $obfStringPatterns) {
                if ($sampleStr -match $obfPat.Pattern) { $flags.Add("$($obfPat.Label) - matched: $($matches[0])") }
            }

            $reflectCount = [regex]::Matches($sampleStr, '(?i)(?:getDeclaredMethod|getDeclaredField|setAccessible|invoke\s*\(|forName\s*\()').Count
            if ($reflectCount -ge 50) { $flags.Add("Heavy reflection usage - $reflectCount reflection calls") }
        }

    } catch { } finally {
        if ($archive) { try { $archive.Dispose() } catch { } }
    }
    return $flags
}

function Invoke-BypassScan {
    param([string]$FilePath, [switch]$DeepScan)
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
            $flags.Add("Suspicious nested JAR - no version, unknown dependency: $sj")
        }

        if ($nestedJars.Count -eq 1 -and $outerClasses.Count -lt 3) {
            $njName = [System.IO.Path]::GetFileName(($nestedJars | Select-Object -First 1).FullName)
            $flags.Add("Hollow shell - only $($outerClasses.Count) own class(es), wraps: $njName")
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
            if ($global:stopScan) { break }
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

                if ($DeepScan) {
                    try {
                        $st = $entry.Open()
                        $ms2 = New-Object System.IO.MemoryStream
                        $st.CopyTo($ms2); $st.Close()
                        $rawBytes = $ms2.ToArray(); $ms2.Dispose()
                        $ct = [System.Text.Encoding]::ASCII.GetString($rawBytes)

                        if ($ct -match "java/lang/Runtime" -and $ct -match "getRuntime" -and $ct -match "exec") {
                            $runtimeExecFound = $true
                        }
                        if ($ct -match "openConnection" -and $ct -match "HttpURLConnection" -and $ct -match "FileOutputStream") {
                            $httpDownloadFound = $true
                        }
                        if ($ct -match "openConnection" -and $ct -match "setDoOutput" -and $ct -match "getOutputStream" -and $ct -match "getProperty") {
                            $httpExfilFound = $true
                        }
                    } catch { }
                }
            }
        }

        foreach ($iz in $innerZips) { try { $iz.Dispose() } catch { } }
        $zip.Dispose()

        $obfPct = if ($totalClassCount -ge 10) { [math]::Round(($obfuscatedCount   / $totalClassCount) * 100) } else { 0 }
        $numPct = if ($totalClassCount -ge 5)  { [math]::Round(($numericClassCount / $totalClassCount) * 100) } else { 0 }
        $uniPct = if ($totalClassCount -ge 5)  { [math]::Round(($unicodeClassCount / $totalClassCount) * 100) } else { 0 }

        if ($runtimeExecFound -and $obfPct -ge 25) {
            $flags.Add("Runtime.exec() in obfuscated code - can run arbitrary OS commands")
        }
        if ($httpDownloadFound) {
            $flags.Add("HTTP file download - fetches and writes files from a remote server at runtime")
        }
        if ($httpExfilFound) {
            $flags.Add("HTTP POST exfiltration - sends system data to an external server")
        }
        if ($totalClassCount -ge 10 -and $obfPct -ge 25) {
            $flags.Add("Heavy obfuscation - $obfPct% of classes use single-letter path segments (a/b/c style)")
        }
        if ($numPct -ge 20) {
            $flags.Add("Numeric class names - $numPct% of classes have numeric-only names (e.g. 1234.class)")
        }
        if ($uniPct -ge 10) {
            $flags.Add("Unicode class names - $uniPct% of classes use non-ASCII characters")
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
            $flags.Add("Fake mod identity - claims to be '$outerModId' but contains dangerous code")
        }

    } catch { }

    return $flags
}

function Invoke-JvmScan {
    $results = [System.Collections.Generic.List[string]]::new()

    $javaProcesses = Get-Process -Name javaw -ErrorAction SilentlyContinue
    if ($javaProcesses.Count -eq 0) { $javaProcesses = Get-Process -Name java -ErrorAction SilentlyContinue }
    if ($javaProcesses.Count -eq 0) {
        Append-Log "  [i] No javaw.exe/java.exe processes found (Minecraft not running)" "#AAAAAA"
        return $results
    }

    Append-Log "  [i] Scanning $($javaProcesses.Count) Java process(es)..." "#00FFFF"

    $fabricPatterns = @{
        "fabric.addMods"='-Dfabric\.addMods=';
        "fabric.loadMods"='-Dfabric\.loadMods=';
        "fabric.classPathGroups"='-Dfabric\.classPathGroups=';
        "fabric.gameJarPath"='-Dfabric\.gameJarPath=';
        "fabric.skipMcProvider"='-Dfabric\.skipMcProvider=';
        "fabric.development"='-Dfabric\.development=';
        "fabric.allowUnsupportedVersion"='-Dfabric\.allowUnsupportedVersion=';
        "fabric.remapClasspathFile"='-Dfabric\.remapClasspathFile=';
        "fabric.skipIntermediary"='-Dfabric\.skipIntermediary=';
        "fabric.configDir"='-Dfabric\.configDir=';
        "fabric.loader.config"='-Dfabric\.loader\.config=';
        "fabric.log.level"='-Dfabric\.log\.level=';
        "fabric.debug.dumpClasspath"='-Dfabric\.debug\.dumpClasspath=';
        "fabric.log.config"='-Dfabric\.log\.config=';
        "fabric.dli.config"='-Dfabric\.dli\.config=';
        "fabric.mixin.configs"='-Dfabric\.mixin\.configs=';
        "fabric.mixin.hotSwap"='-Dfabric\.mixin\.hotSwap=';
        "fabric.mixin.debug.export"='-Dfabric\.mixin\.debug\.export=';
        "fabric.mixin.debug.verbose"='-Dfabric\.mixin\.debug\.verbose=';
        "fabric.gameVersion"='-Dfabric\.gameVersion=';
        "fabric.forceVersion"='-Dfabric\.forceVersion=';
        "fabric.autoDetectVersion"='-Dfabric\.autoDetectVersion=';
        "fabric.launcher.name"='-Dfabric\.launcher\.name=';
        "fabric.launcher.brand"='-Dfabric\.launcher\.brand=';
        "fabric.mods.toml.path"='-Dfabric\.mods\.toml\.path=';
        "fabric.customModList"='-Dfabric\.customModList=';
        "fabric.resolve.modFiles"='-Dfabric\.resolve\.modFiles=';
        "fabric.skipDependencyResolution"='-Dfabric\.skipDependencyResolution=';
        "fabric.loader.entrypoints"='-Dfabric\.loader\.entrypoints=';
        "fabric.language.providers"='-Dfabric\.language\.providers=';
        "forge.addMods"='-Dforge\.addMods=';
        "forge.mods"='-Dforge\.mods=';
        "fml.coreMods.load"='-Dfml\.coreMods\.load=';
        "forge.coreMods.dir"='-Dforge\.coreMods\.dir=';
        "forge.modDir"='-Dforge\.modDir=';
        "forge.modsDirectories"='-Dforge\.modsDirectories=';
        "fml.customModList"='-Dfml\.customModList=';
        "forge.disableModScan"='-Dforge\.disableModScan=';
        "forge.modList"='-Dforge\.modList=';
        "forge.forceVersion"='-Dforge\.forceVersion=';
        "forge.disableUpdateCheck"='-Dforge\.disableUpdateCheck=';
        "forge.logging.mojang.level"='-Dforge\.logging\.mojang\.level=';
        "forge.mixin.hotSwap"='-Dforge\.mixin\.hotSwap=';
        "forge.resourcePack"='-Dforge\.resourcePack=';
        "forge.defaultResourcePack"='-Dforge\.defaultResourcePack=';
        "forge.texturePacks"='-Dforge\.texturePacks=';
        "forge.assetIndex"='-Dforge\.assetIndex=';
        "forge.assetsDir"='-Dforge\.assetsDir=';
        "javaSecurityManager"='-Djava\.security\.manager=';
        "javaSecurityPolicy"='-Djava\.security\.policy=';
        "bootClasspath"='-Xbootclasspath';
        "systemClassLoader"='-Djava\.system\.class\.loader=';
        "javaClassPath"='-Djava\.class\.path=';
        "cp"='-cp\s+["''][^"'';]*\.jar';
        "cheatClientBrand"='-D(client|launcher)\.brand=(Wurst|Aristois|Impact|Kilo|Future|Lambda|Rusher|Konas|Phobos|Salhack|ForgeHax|Mathax|Meteor|Async|Seppuku|Xatz|Wolfram|Huzuni|Jigsaw|Zamorozka|Moon|Rage|Exhibition|Virtue|Novoline|Rekt|Skid|Ares|Abyss|Thunder|Tenacity|Rise|Flux|Gamesense|Intent|Remix|Sight|Vape|Shield|Ghost|Crispy|Inertia)';
        "optifine"='-Doptifine\.';
        "shadersmod"='-Dshaders?\.';
        "shaderPack"='-Dshader[sP]ack=';
        "cheatPattern"='-D(xray|fly|speed|killaura|reach|esp|wallhack|noclip|autoclick|aimbot|triggerbot|antiknockback|nofall|timer|step|fullbright|nightvision|cavefinder)\.'
    }
    $cheatClients = @('Wurst','Aristois','Impact','Kilo','Future','Lambda','Rusher','Konas','Phobos','Salhack','ForgeHax','Mathax','Meteor','Async','Seppuku','Xatz','Wolfram','Huzuni','Jigsaw','Zamorozka','Moon','Rage','Exhibition','Virtue','Novoline','Rekt','Skid','Ares','Abyss','Thunder','Tenacity','Rise','Flux','Gamesense','Intent','Remix','Sight','Vape','Shield','Ghost','Crispy','Inertia')

    foreach ($proc in $javaProcesses) {
        if ($global:stopScan) { return $results }
        try {
            $pid = $proc.Id
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $pid" -ErrorAction Stop).CommandLine
            if (-not $cmdLine) { continue }
            Append-Log "  +- Process: PID $pid" "#81C784"

            $detectedPatterns = @()
            foreach ($k in $fabricPatterns.Keys) {
                if ($cmdLine -match $fabricPatterns[$k]) { $detectedPatterns += $k }
            }
            foreach ($cc in $cheatClients) {
                if ($cmdLine -match "(?i)\b$cc\b" -and $detectedPatterns -notcontains "CheatClient-$cc") { $detectedPatterns += "CheatClient-$cc" }
            }
            if ($cmdLine -match '(%3B|%26%26|%7C%7C|%7C|%60|%24|%3C|%3E)') { $detectedPatterns += "EncodedInjection" }

            # From Meow: javaagent detection and suspicious JVM flags
            $agentMatches = [regex]::Matches($cmdLine, '-javaagent:([^\s"]+)')
            foreach ($m in $agentMatches) {
                $agentPath = $m.Groups[1].Value.Trim('"').Trim("'")
                $agentName = [System.IO.Path]::GetFileName($agentPath)
                $legitAgents = @("jmxremote","yjp","jrebel","newrelic","jacoco","theseus")
                $isLegit = $false
                foreach ($la in $legitAgents) { if ($agentName -match $la) { $isLegit = $true; break } }
                if (-not $isLegit) {
                    $detectedPatterns += "JvmAgent-$agentName"
                    $results.Add("JVM Agent detected - -javaagent:$agentName (path: $agentPath)")
                }
            }

            $suspiciousFlags = @(
                "Xbootclasspath/p:","Xbootclasspath/a:","agentlib:jdwp","agentpath:"
            )
            foreach ($sf in $suspiciousFlags) {
                if ($cmdLine -match [regex]::Escape("-$sf")) {
                    $detectedPatterns += "SuspiciousFlag-$sf"
                }
            }

            if ($detectedPatterns.Count -gt 0) {
                Append-Log "  |  [!] JVM INJECTION DETECTED!" "#E53935" -Bold
                foreach ($d in $detectedPatterns) {
                    Append-Log "  |    - $d" "#EF5350"
                    [void]$results.Add($d)
                }
            } else {
                Append-Log "  |  [v] No JVM injection patterns detected." "#81C784"
            }
        } catch {
            Append-Log "  |  [!] Could not retrieve cmdline. Run as Admin." "#FFB74D"
        }
    }
    return $results
}

function Invoke-FullScan {
    param([string]$TargetPath, [switch]$DeepScan)

    $global:stopScan = $false
    $global:reportLines.Clear()

    Append-Log " ATLAS MOD ANALYZER SCAN STARTED" "#64B5F6" -Bold
    Append-Log " Target: $TargetPath" "#AAAAAA"
    Append-Log " Mode:   $(if ($DeepScan) { 'DEEP SCAN (full content + obfuscation + bypass analysis)' } else { 'NORMAL SCAN (names + manifest + hash verification)' })" "#AAAAAA"
    Write-Host ""

    if (-not (Test-Path $TargetPath -PathType Container)) {
        Append-Log "[!] Directory does not exist!" "#E53935" -Bold
        return
    }

    try { $jarFiles = Get-ChildItem -Path $TargetPath -Filter *.jar -ErrorAction Stop } catch {
        Append-Log "[!] Error accessing directory." "#E53935"
        return
    }

    if ($jarFiles.Count -eq 0) {
        Append-Log "[!] No JAR files found." "#FFB74D"
        return
    }

    $total = $jarFiles.Count
    Append-Log "Found $total JAR files to analyze. (press Q at any time to stop)`r`n" "#81C784"

    $verifiedMods   = [System.Collections.Generic.List[object]]::new()
    $flaggedMods    = [System.Collections.Generic.List[object]]::new()
    $bypassMods     = [System.Collections.Generic.List[object]]::new()
    $obfuscatedMods = [System.Collections.Generic.List[object]]::new()
    $unknownMods    = [System.Collections.Generic.List[object]]::new()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Pass 1: Hash verification (Modrinth + Megabase)
    Append-Log " Pass 1/4 - Hash verification (Modrinth/Megabase)..." "#64B5F6"
    for ($i = 0; $i -lt $total; $i++) {
        Test-StopRequested
        if ($global:stopScan) { break }
        $jar = $jarFiles[$i]
        Write-Host ("  [{0}/{1}] {2}" -f ($i + 1), $total, $jar.Name) -ForegroundColor DarkGray

        $hash = Get-FileSHA1 -Path $jar.FullName
        if ($hash) {
            $modrinthData = Query-Modrinth -Hash $hash
            if ($modrinthData.Slug) {
                $whitelisted = @("viafabricplus", "viafabricversion", "lithium", "sodium", "iris", "fabric-api", "modmenu")
                $isWhitelisted = $whitelisted -contains $modrinthData.Slug.ToLower()
                $verifiedMods.Add([PSCustomObject]@{
                    ModName = $modrinthData.Name; FileName = $jar.Name; FilePath = $jar.FullName; Whitelisted = $isWhitelisted
                })
                continue
            }
            $megabaseData = Query-Megabase -Hash $hash
            if ($megabaseData.name) {
                $verifiedMods.Add([PSCustomObject]@{
                    ModName = $megabaseData.name; FileName = $jar.Name; FilePath = $jar.FullName; Whitelisted = $false
                })
                continue
            }
        }

        $src = Get-DownloadSource -Path $jar.FullName
        $unknownMods.Add([PSCustomObject]@{ FileName = $jar.Name; FilePath = $jar.FullName; DownloadSource = $src })
    }
    Write-Host ""

    # Pass 2: Mod scan (cheat patterns + strings)
    Append-Log " Pass 2/4 - Pattern & String analysis..." "#64B5F6"
    for ($i = 0; $i -lt $total; $i++) {
        Test-StopRequested
        if ($global:stopScan) { break }
        $jar = $jarFiles[$i]
        Write-Host ("  [{0}/{1}] {2}" -f ($i + 1), $total, $jar.Name) -ForegroundColor DarkGray

        $verified = $verifiedMods | Where-Object { $_.FileName -eq $jar.Name -and $_.Whitelisted } | Select-Object -First 1
        if ($verified) { continue }

        $modRes = Invoke-ModScan -FilePath $jar.FullName -DeepScan:$DeepScan
        if ($modRes.Patterns.Count -gt 0 -or $modRes.Strings.Count -gt 0 -or $modRes.Fullwidth.Count -gt 0) {
            $flaggedMods.Add([PSCustomObject]@{
                FileName = $jar.Name; Patterns = $modRes.Patterns; Strings = $modRes.Strings; Fullwidth = $modRes.Fullwidth
            })
            $verifiedMods | Where-Object { $_.FileName -eq $jar.Name } | ForEach-Object { $verifiedMods.Remove($_) }
            $unknownMods | Where-Object { $_.FileName -eq $jar.Name } | ForEach-Object { $unknownMods.Remove($_) }
        }
    }
    Write-Host ""

    # Pass 3: Bypass/injection scan
    if ($DeepScan) {
        Append-Log " Pass 3/4 - Bypass & Injection analysis (deep scan only)..." "#64B5F6"
    } else {
        Append-Log " Pass 3/4 - Bypass & Injection analysis (name-level only)..." "#64B5F6"
    }
    for ($i = 0; $i -lt $total; $i++) {
        Test-StopRequested
        if ($global:stopScan) { break }
        $jar = $jarFiles[$i]
        Write-Host ("  [{0}/{1}] {2}" -f ($i + 1), $total, $jar.Name) -ForegroundColor DarkGray

        $verified = $verifiedMods | Where-Object { $_.FileName -eq $jar.Name -and $_.Whitelisted } | Select-Object -First 1
        if ($verified) { continue }

        $bypassRes = Invoke-BypassScan -FilePath $jar.FullName -DeepScan:$DeepScan
        if ($bypassRes.Count -gt 0) {
            $bypassMods.Add([PSCustomObject]@{ FileName = $jar.Name; Flags = $bypassRes })
            $verifiedMods | Where-Object { $_.FileName -eq $jar.Name } | ForEach-Object { $verifiedMods.Remove($_) }
            $unknownMods | Where-Object { $_.FileName -eq $jar.Name } | ForEach-Object { $unknownMods.Remove($_) }
            $flaggedMods | Where-Object { $_.FileName -eq $jar.Name } | ForEach-Object { $flaggedMods.Remove($_) }
        }
    }
    Write-Host ""

    # Pass 4: Obfuscation analysis
    Append-Log " Pass 4/4 - Obfuscation analysis..." "#64B5F6"
    for ($i = 0; $i -lt $total; $i++) {
        Test-StopRequested
        if ($global:stopScan) { break }
        $jar = $jarFiles[$i]
        Write-Host ("  [{0}/{1}] {2}" -f ($i + 1), $total, $jar.Name) -ForegroundColor DarkGray

        $verified = $verifiedMods | Where-Object { $_.FileName -eq $jar.Name -and $_.Whitelisted } | Select-Object -First 1
        if ($verified) { continue }

        $obfRes = Invoke-ObfuscationScan -FilePath $jar.FullName -DeepScan:$DeepScan
        if ($obfRes.Count -gt 0) {
            $alreadyFlagged = ($flaggedMods | Where-Object { $_.FileName -eq $jar.Name }).Count -gt 0 -or
                              ($bypassMods  | Where-Object { $_.FileName -eq $jar.Name }).Count -gt 0
            if (-not $alreadyFlagged) {
                $obfuscatedMods.Add([PSCustomObject]@{ FileName = $jar.Name; Flags = $obfRes })
                $verifiedMods | Where-Object { $_.FileName -eq $jar.Name } | ForEach-Object { $verifiedMods.Remove($_) }
                $unknownMods | Where-Object { $_.FileName -eq $jar.Name } | ForEach-Object { $unknownMods.Remove($_) }
            }
        }
        Test-StopRequested
        if ($global:stopScan) { break }
    }
    Write-Host ""

    # JVM process scan
    Append-Log " JVM PROCESS SCAN" "#64B5F6" -Bold
    $jvmFlags = Invoke-JvmScan

    $stopwatch.Stop()

    if ($global:stopScan) {
        Append-Log "`r`n[STOPPED] Scan cancelled by user." "#FFB74D" -Bold
        return
    }

    # Summary
    Write-Host ""
    Append-Log " SCAN COMPLETE!" "#81C784" -Bold
    Append-Log " Total:          $total" "#FFFFFF"
    Append-Log " Verified:       $($verifiedMods.Count)" "#81C784"
    Append-Log " Unknown:        $($unknownMods.Count)" "#FFB74D"
    Append-Log " Flagged:        $($flaggedMods.Count)" "#E53935"
    Append-Log " Bypass/Inject:  $($bypassMods.Count)" "#EF5350"
    Append-Log " Obfuscated:     $($obfuscatedMods.Count)" "#FFF176"
    Append-Log " JVM Issues:     $($jvmFlags.Count)" "#FFB74D"
    Append-Log " Elapsed:        $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s" "#888888"

    Write-Host ""
    Write-Host "  VERIFIED MODS" -ForegroundColor Green
    foreach ($vm in $verifiedMods) {
        Write-Host "    ✓ $($vm.ModName) → $($vm.FileName)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  UNKNOWN MODS" -ForegroundColor Yellow
    foreach ($um in $unknownMods) {
        $srcText = if ($um.DownloadSource) { " (source: $($um.DownloadSource))" } else { "" }
        Write-Host "    ? $($um.FileName)$srcText" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  FLAGGED MODS" -ForegroundColor Red
    foreach ($fm in $flaggedMods) {
        Append-Log " [FLAGGED] $($fm.FileName)" "#E53935" -Bold
        foreach ($p in $fm.Patterns) { Append-Log "    Pattern: $p" "#EF5350" }
        foreach ($s in $fm.Strings) { Append-Log "    String: $s" "#FFB74D" }
        foreach ($f in $fm.Fullwidth) { Append-Log "    Fullwidth: $f" "#9E9E9E" }
    }

    Write-Host ""
    Write-Host "  BYPASS / INJECTION DETECTED" -ForegroundColor Magenta
    foreach ($bm in $bypassMods) {
        Append-Log " [INJECTION] $($bm.FileName)" "#EF5350" -Bold
        foreach ($fl in $bm.Flags) { Append-Log "    $fl" "#FFB74D" }
    }

    Write-Host ""
    Write-Host "  OBFUSCATED MODS" -ForegroundColor Yellow
    foreach ($om in $obfuscatedMods) {
        Append-Log " [OBFUSCATED] $($om.FileName)" "#FFF176" -Bold
        foreach ($fl in $om.Flags) { Append-Log "    $fl" "#AAAAAA" }
    }
}

# --- MAIN LOOP ---
$defaultPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"

while ($true) {
    Show-Banner

    Write-Host "Target Path [$defaultPath]:" -ForegroundColor Gray
    Write-Host "> " -NoNewline -ForegroundColor DarkCyan
    $inputPath = Read-Host
    $targetPath = if ([string]::IsNullOrWhiteSpace($inputPath)) { $defaultPath } else { $inputPath }

    Write-Host ""
    Write-Host "Scan Mode:" -ForegroundColor Gray
    Write-Host "  [1] Normal Scan  - fast, hash verify + file names + manifest" -ForegroundColor Gray
    Write-Host "  [2] Deep Scan    - slower, opens every class, checks obfuscation, bypass, reflection" -ForegroundColor Gray
    Write-Host "> " -NoNewline -ForegroundColor DarkCyan
    $modeAns = Read-Host
    $useDeepScan = ($modeAns.Trim() -eq '2')

    Write-Host ""
    Invoke-FullScan -TargetPath $targetPath -DeepScan:$useDeepScan

    Write-Host ""
    Write-Host "Save report to file? (Y/N): " -NoNewline -ForegroundColor Gray
    $saveAns = Read-Host
    if ($saveAns -match '^(y|yes)$') {
        $defaultName = "AtlasScanReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        Write-Host "Save as [$defaultName]: " -NoNewline -ForegroundColor Gray
        $fileName = Read-Host
        if ([string]::IsNullOrWhiteSpace($fileName)) { $fileName = $defaultName }
        try {
            $global:reportLines | Out-File -FilePath $fileName -Encoding UTF8
            Write-Host "Report saved to $fileName" -ForegroundColor Green
        } catch {
            Write-Host "Failed to save report: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Scan another directory? (Y/N): " -NoNewline -ForegroundColor Gray
    $again = Read-Host
    if ($again -notmatch '^(y|yes)$') { break }
}

Write-Host ""
Write-Host "Exiting Atlas Mod Analyzer." -ForegroundColor DarkGray
