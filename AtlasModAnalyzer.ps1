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

# Map the hex colors the tool used to reason about severity into
# ConsoleColor equivalents (plain terminals don't do arbitrary hex).
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

# Non-blocking check for the user pressing Q to abort a running scan.
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
    "ＡｕｔｏＤｏｕｂｌｅＨａｎｄ", "Ａｕｔｏ Ｄｏｕｂｌｅ Ｈａｎｄ",
    "AutoClicker",
    "ＡｕｔｏＣｌｉｃｋｅｒ",
    "Failed to switch to mace after axe!",
    "AutoMace", "MaceSwap", "SpearSwap",
    "ＡｕｔｏＭａｃｅ", "Ａｕｔｏ Ｍａｃｅ",
    "ＭａｃｅＳｗａｐ", "Ｍａｃｅ Ｓｗａｐ",
    "Ｓｐｅａｒ Ｓｗａｐ", "Ａｕｔｏｍａｔｉｃａｌｌｙ ａｘｅ ａｎｄ ｍａｃｅ ｓｈｉｅｌｄｅｄ ｐｌａｙｅｒｓ",
    "Ｓｔｕｎ Ｓｌａｍ", "StunSlam",
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
    "Ｆａｋｅ Ｐｕｎｃｈ",
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
    "Ａｎｔｉ Ｗｅｂ", "ＡｕｔｏＷｅｂ",
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
    "Ｆｒｅｅｃａｍ", "Ｍｏｖｅ ｆｒｅｅｌｙ ｔｈｒｏｕｇｈ ｗａｌｌｓ",
    "Ｎｏ Ｃｌｉｐ", "Ｆｒｅｅｚｅ Ｐｌａｙｅｒ",
    "LWFH Crystal", "JDWP.VirtualMachine.AllModules",
    "ＬＷＦＨ Ｃｒｙｓｔａｌ",
    "KeyPearl", "LootYeeter",
    "ＫｅｙＰｅａｒｌ", "Ｋｅｙ Ｐｅａｒｌ",
    "Ｌｏｏｔ Ｙｅｅｔｅｒ",
    "FastPlace",
    "Ｆａｓｔ Ｐｌａｃｅ", "Ｐｌａｃｅ ｂｌｏｃｋｓ ｆａｓｔｅｒ",
    "AutoBreach",
    "Ａｕｔｏ Ｂｒｅａｃｈ",
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
    "No Count Glitch", "Ｎｏ Ｃｏｕｎｔ Ｇｌｉｔｃｈ",
    "No Bounce", "NoBounce", "Ｎｏ Ｂｏｕｎｃｅ", "ＮｏＢｏｕｎｃｅ",
    "Ｒｅｍｏｖｅｓ ｔｈｅ ｃｒｙｓｔａｌ ｂｏｕｎｃｅ ａｎｉｍａｔｉｏｎ",
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
    "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ",
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
    "Require Elytra", "Ｒｅｑｕｉｒｅ Ｅｌｙｔｒａ",
    "Auto Switch Back", "Ａｕｔｏ Ｓｗｉｔｃｈ Ｂａｃｋ",
    "Check Line of Sight", "Ｃｈｅｃｋ Ｌｉｎｅ ｏｆ Ｓｉｇｈｔ",
    "Only When Falling", "Ｏｎｌｙ Ｗｈｅｎ Ｆａｌｌｉｎｇ",
    "Require Crit", "Ｒｅｑｕｉｒｅ Ｃｒｉｔ",
    "Show Status Display", "Ｓｈｏｗ Ｓｔａｔｕｓ Ｄｉｓｐｌａｙ",
    "Stop On Crystal", "Ｓｔｏｐ Ｏｎ Ｃｒｙｓｔａｌ",
    "Check Shield", "Ｃｈｅｃｋ Ｓｈｉｅｌｄ",
    "On Pop", "Ｏｎ Ｐｏｐ",
    "Predict Damage", "Ｐｒｅｄｉｃｔ Ｄａｍａｇｅ",
    "On Ground", "Ｏｎ Ｇｒｏｕｎｄ",
    "Check Players", "Ｃｈｅｃｋ Ｐｌａｙｅｒｓ",
    "Predict Crystals", "Ｐｒｅｄｉｃｔ Ｃｒｙｓｔａｌｓ",
    "Check Aim", "Ｃｈｅｃｋ Ａｉｍ",
    "Check Items", "Ｃｈｅｃｋ Ｉｔｅｍｓ",
    "Activates Above", "Ａｃｔｉｖａｔｅｓ Ａｂｏｖｅ",
    "Blatant", "Ｂｌａｔａｎｔ",
    "Force Totem", "Ｆｏｒｃｅ Ｔｏｔｅｍ",
    "Stay Open For", "Ｓｔａｙ Ｏｐｅｎ Ｆｏｒ",
    "Auto Inventory Totem", "Ａｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
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
    "Include Head", "Ｉｎｃｌｕｄｅ Ｈｅａｄ",
    "Web Delay", "Ｗｅｂ Ｄｅｌａｙ",
    "Holding Web", "Ｈｏｌｄｉｎｇ Ｗｅｂ",
    "Not When Affects Player", "Ｎｏｔ Ｗｈｅｎ Ａｆｆｅｃｔｓ Ｐｌａｙｅｒ",
    "Hit Delay", "Ｈｉｔ Ｄｅｌａｙ",
    "Ｓｗｉｔｃｈ Ｂａｃｋ",
    "Require Hold Axe", "Ｒｅｑｕｉｒｅ Ｈｏｌｄ Ａｘｅ",
    "Fake Punch", "Ｆａｋｅ Ｐｕｎｃｈ",
    "placeInterval", "breakInterval", "stopOnKill",
    "activateOnRightClick", "holdCrystal",
    "ｐｌａｃｅＩｎｔｅｒｖａｌ", "ｂｒｅａｋＩｎｔｅｒｖａｌ",
    "ｓｔｏｐＯｎＫｉｌｌ", "ａｃｔｉｖａｔｅＯｎＲｉｇｈｔＣｌｉｃｋ",
    "ｄａｍａｇｅｔｉｃｋ", "ｈｏｌｄＣｒｙｓｔａｌ",
    "ｆａｋｅＰｕｎｃｈ",
    "Ｒｅｆｉｌｌｓ ｙｏｕｒ ｈｏｔｂａｒ ｗｉｔｈ ｐｏｔｉｏｎｓ",
    "Ｋｅｐｓ ｙｏｕ ｓｐｒｉｎｔｉｎｇ ａｔ ａｌｌ ｔｉｍｅｓ",
    "Ｐｌａｃｅｓ ａｎｃｈｏｒ， ｃｈａｒｇｅｓ ｉｔ， ｐｒｏｔｅｃｔｓ ｙｏｕ， ａｎｄ ｅｘｐｌｏｄｅｓ",
    "Ａｕｔｏ ｓｗａｐ ｔｏ ｓｐｅａｒ ｏｎ ａｔｔａｃｋ",
    "Macro Key", "Ａｕｔｏ Ｐｏｔ", "Ｍａｃｒｏ Ｋｅｙ",
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

# --- SCANNER LOGIC ---
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

            # Unpacking nested jars (Fabric/Forge "jar-in-jar" bundling) means
            # opening and buffering each one in memory - real work, so it's
            # deep-scan only. Normal scan still catches these by their outer
            # META-INF/jars/*.jar entry name via the patternRegex check above.
            if ($DeepScan -and $entry.FullName -match "^META-INF/jars/.+\.jar$") {
                try {
                    $ns = $entry.Open(); $ms = New-Object System.IO.MemoryStream
                    $ns.CopyTo($ms); $ns.Close(); $ms.Position = 0
                    $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                    $innerArchives.Add($iz)
                    foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
                } catch { }
            }
        }

        foreach ($entry in $allEntries) {
            if ($global:stopScan) { return @{ Patterns = $foundPatterns; Strings = $foundStrings; Fullwidth = $foundFullwidth } }
            $name = $entry.FullName
            # Normal scan only pays the I/O cost for the manifest (small, cheap,
            # often reveals client/loader identity). Deep scan additionally
            # opens every .class/.json file and scans its raw bytes - that's
            # the expensive, thorough pass.
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
                # Reading and buffering class bytes for the obfuscator/reflection
                # fingerprinting below is the expensive part - deep scan only.
                if ($DeepScan -and $sampleSize -lt 150000 -and $entry.Length -lt 100000 -and $entry.Length -gt 100) {
                    try {
                        $st = $entry.Open(); $ms = New-Object System.IO.MemoryStream
                        $st.CopyTo($ms); $st.Close()
                        $ascii = [System.Text.Encoding]::ASCII.GetString($ms.ToArray()); $ms.Dispose()
                        [void]$contentSample.Append($ascii); $sampleSize += $ascii.Length
                    } catch { }
                }
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

function Invoke-JvmScan {
    $javaProcesses = Get-Process -Name javaw -ErrorAction SilentlyContinue
    if ($javaProcesses.Count -eq 0) {
        Append-Log "  [i] No javaw.exe processes found (Minecraft not running)" "#AAAAAA"
        return
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
        if ($global:stopScan) { return }
        try {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction Stop).CommandLine
            if (-not $cmdLine) { continue }
            Append-Log "  +- Process: PID $($proc.Id)" "#81C784"

            $detectedPatterns = @()
            foreach ($k in $fabricPatterns.Keys) {
                if ($cmdLine -match $fabricPatterns[$k]) {
                    $detectedPatterns += $k
                }
            }
            foreach ($cc in $cheatClients) {
                if ($cmdLine -match "(?i)\b$cc\b" -and $detectedPatterns -notcontains "CheatClient-$cc") { $detectedPatterns += "CheatClient-$cc" }
            }
            if ($cmdLine -match '(%3B|%26%26|%7C%7C|%7C|%60|%24|%3C|%3E)') { $detectedPatterns += "EncodedInjection" }

            if ($detectedPatterns.Count -gt 0) {
                Append-Log "  |  [!] JVM INJECTION DETECTED!" "#E53935" -Bold
                foreach ($d in $detectedPatterns) { Append-Log "  |    - $d" "#EF5350" }
            } else {
                Append-Log "  |  [v] No JVM injection patterns detected." "#81C784"
            }
        } catch {
            Append-Log "  |  [!] Could not retrieve cmdline. Run as Admin." "#FFB74D"
        }
    }
}

function Invoke-FullScan {
    param([string]$TargetPath, [switch]$DeepScan)

    $global:stopScan = $false
    $global:reportLines.Clear()

    Append-Log " ATLAS MOD ANALYZER SCAN STARTED" "#64B5F6" -Bold
    Append-Log " Target: $TargetPath" "#AAAAAA"
    Append-Log " Mode:   $(if ($DeepScan) { 'DEEP SCAN (full content + obfuscation analysis)' } else { 'NORMAL SCAN (names + manifest only)' })" "#AAAAAA"
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

    $flaggedCount = 0
    $obfCount = 0
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    for ($i = 0; $i -lt $total; $i++) {
        Test-StopRequested
        if ($global:stopScan) {
            Append-Log "`r`n[STOPPED] Scan cancelled by user." "#FFB74D" -Bold
            return
        }
        $jar = $jarFiles[$i]
        Write-Host ("  [{0}/{1}] {2}" -f ($i + 1), $total, $jar.Name) -ForegroundColor DarkGray

        $modRes = Invoke-ModScan -FilePath $jar.FullName -DeepScan:$DeepScan
        $obfRes = Invoke-ObfuscationScan -FilePath $jar.FullName -DeepScan:$DeepScan

        $isFlagged = ($modRes.Patterns.Count -gt 0 -or $modRes.Strings.Count -gt 0 -or $modRes.Fullwidth.Count -gt 0)
        $isObfuscated = ($obfRes.Count -gt 0)

        if ($isFlagged) {
            $flaggedCount++
            Append-Log " [FLAGGED] $($jar.Name)" "#E53935" -Bold
            foreach ($p in $modRes.Patterns) { Append-Log "    Pattern: $p" "#EF5350" }
            foreach ($s in $modRes.Strings) { Append-Log "    String: $s" "#FFB74D" }
            foreach ($f in $modRes.Fullwidth) { Append-Log "    Fullwidth: $f" "#9E9E9E" }
            Append-Log ""
        }

        if ($isObfuscated) {
            $obfCount++
            Append-Log " [OBFUSCATED] $($jar.Name)" "#FFF176" -Bold
            foreach ($o in $obfRes) { Append-Log "    Flag: $o" "#AAAAAA" }
            Append-Log ""
        }
    }

    Append-Log " JVM PROCESS SCAN" "#64B5F6" -Bold
    Invoke-JvmScan

    if ($global:stopScan) {
        Append-Log "`r`n[STOPPED] Scan cancelled by user." "#FFB74D" -Bold
        return
    }

    $stopwatch.Stop()
    Write-Host ""
    Append-Log " SCAN COMPLETE!" "#81C784" -Bold
    Append-Log " Total Scanned: $total" "#FFFFFF"
    Append-Log " Flagged Mods:  $flaggedCount" "#E53935"
    Append-Log " Obfuscated:    $obfCount" "#FFF176"
    Append-Log " Elapsed:       $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s" "#888888"
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
    Write-Host "  [1] Normal Scan  - fast, checks file names + manifest" -ForegroundColor Gray
    Write-Host "  [2] Deep Scan    - slower, opens every class, checks obfuscation + reflection" -ForegroundColor Gray
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
