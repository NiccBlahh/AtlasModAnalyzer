# Required for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ---------------------------------------------------------
# CORE LOGIC (Preserved from original script)
# ---------------------------------------------------------

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
    "org.chainlibs.module.impl.modules.Crystal.Y", "org.chainlibs.module.impl.modules.Crystal.bF", "org.chainlibs.module.impl.modules.Crystal.bM",
    "org.chainlibs.module.impl.modules.Crystal.bY", "org.chainlibs.module.impl.modules.Crystal.bq", "org.chainlibs.module.impl.modules.Crystal.cv",
    "org.chainlibs.module.impl.modules.Crystal.o", "org.chainlibs.module.impl.modules.Blatant.I", "org.chainlibs.module.impl.modules.Blatant.bR",
    "org.chainlibs.module.impl.modules.Blatant.bx", "org.chainlibs.module.impl.modules.Blatant.cj", "org.chainlibs.module.impl.modules.Blatant.dk",
    "imgui.gl3", "imgui.glfw", "BowAim", "Criticals", "Fakenick", "FakeItem", "invsee", "ItemExploit", "Hellion", "hellion",
    "LicenseCheckMixin", "ClientPlayerInteractionManagerAccessor", "ClientPlayerEntityMixim", "dev.gambleclient", "obfuscatedAuth",
    "phantom-refmap.json", "xyz.greaj",
    "じ.class", "ふ.class", "ぶ.class", "ぷ.class", "た.class", "ね.class", "そ.class", "な.class", "ど.class", "ぐ.class",
    "ず.class", "で.class", "つ.class", "べ.class", "せ.class", "と.class", "み.class", "び.class", "す.class", "の.class"
)

 $cheatStrings = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "JDWP.VirtualMachine.AllModules", "dontPlaceCrystal", "dontBreakCrystal",
    "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer", "healPotSlot", "ＡｕｔｏＣｒｙｓｔａｌ", "Ａｕｔｏ Ｃｒｙｓｔａｌ", "ＡｕｔｏＨｉｔＣｒｙｓｔａｌ",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor", "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "SafeAnchor", "AirAnchor", "ＡｕｔｏＡｎｃｈｏｒ", "Ａｕｔｏ Ａｎｃｈｏｒ", "ＤｏｕｂｌｅＡｎｃｈｏｒ", "Ｄｏｕｂｌｅ Ａｎｃｈｏｒ", "ＳａｆｅＡｎｃｈｏｒ",
    "Ｓａｆｅ Ａｎｃｈｏｒ", "Ａｎｃｈｏｒ Ｍａｃｒｏ", "anchorMacro", "AutoTotem", "autototem", "auto totem", "InventoryTotem",
    "inventorytotem", "HoverTotem", "hover totem", "legittotem", "ＡｕｔｏＴｏｔｅｍ", "Ａｕｔｏ Ｔｏｔｅｍ", "ＨｏｖｅｒＴｏｔｅｍ",
    "Ｈｏｖｅｒ Ｔｏｔｅｍ", "ＩｎｖｅｎｔｏｒｙＴｏｔｅｍ", "Ａｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ", "Ａｕｔｏ Ｔｏｔｅｍ Ｈｉｔ",
    "AutoPot", "autopot", "auto pot", "speedPotSlot", "strengthPotSlot", "AutoArmor", "autoarmor", "auto armor",
    "ＡｕｔｏＰｏｔ", "Ａｕｔｏ Ｐｏｔ", "Ａｕｔｏ Ｐｏｔ Ｒｅｆｉｌｌ", "AutoPotRefill", "ＡｕｔｏＡｒｍｏｒ", "Ａｕｔｏ Ａｒｍｏｒ",
    "preventSwordBlockBreaking", "preventSwordBlockAttack", "ShieldDisabler", "ShieldBreaker", "ＳｈｉｅｌｄＤｉｓａｂｌｅｒ",
    "Ｓｈｉｅｌｄ Ｄｉｓａｂｌｅｒ", "Breaking shield with axe...", "AutoDoubleHand", "autodoublehand", "auto double hand",
    "ＡｕｔｏＤｏｕｂｌｅＨａｎｄ", "Ａｕｔｏ Ｄｏｕｂｌｅ Ｈａｎｄ", "AutoClicker", "ＡｕｔｏＣｌｉｃｋｅｒ", "Failed to switch to mace after axe!",
    "AutoMace", "MaceSwap", "SpearSwap", "ＡｕｔｏＭａｃｅ", "Ａｕｔｏ Ｍａｃｅ", "ＭａｃｅＳｗａｐ", "Ｍａｃｅ Ｓｗａｐ",
    "Ｓｐｅａｒ Ｓｗａｐ", "Ａｕｔｏｍａｔｉｃａｌｌｙ ａｘｅ ａｎｄ ｍａｃｅ ｓｈｉｅｌｄｅｄ ｐｌａｙｅｒｓ", "Ｓｔｕｎ Ｓｌａｍ", "StunSlam",
    "Donut", "JumpReset", "axespam", "axe spam", "findKnockbackSword", "attackRegisteredThisClick", "AimAssist", "aimassist",
    "aim assist", "triggerbot", "trigger bot", "ＡｉｍＡｓｓｉｓｔ", "Ａｉｍ Ａｓｓｉｓｔ", "ＴｒｉｇｇｅｒＢｏｔ", "Ｔｒｉｇｇｅｒ Ｂｏｔ",
    "Silent Rotations", "SilentRotations", "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ", "FakeInv", "swapBackToOriginalSlot", "FakeLag", "pingspoof",
    "ping spoof", "ＦａｋｅＬａｇ", "Ｆａｋｅ Ｌａｇ", "fakePunch", "Fake Punch", "Ｆａｋｅ Ｐｕｎｃｈ", "mace_swap", "quick_strike",
    "macro_198", "stun_slam", "safe_anchor", "double_anchor", "auto_pot_refill", "walksy_optimizer", "key_pearl", "aim_assist",
    "auto_neth_pot", "auto_dtap", "trigger_bot", "auto_web", "DOUBLE_ESCAPE", "DOUBLE_RIGHTCLICK_FIRST", "DOUBLE_RIGHTCLICK_SECOND",
    "POST_CYCLE_DELAY", "PLACE_OBI", "WAIT_OBI", "PLACE_CRYSTAL", "BREAK_CRYSTAL", "ROTATING_DOWN", "ROTATING_BACK",
    "REFILLING", "PLANTING", "BONEMEALING", "AnchorAction", "Places two anchors for massive damage", "REOFFHAND_TOTEM",
    "webmacro", "web macro", "AntiWeb", "AutoWeb", "Ａｎｔｉ Ｗｅｂ", "ＡｕｔｏＷｅｂ", "Ｐｌａｃｅｓ Ｗｅｂｓ Ｏｎ Ｅｎｅｍｉｅｓ",
    "lvstrng", "dqrkis", "selfdestruct", "self destruct", "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer",
    "Ｗａｌｋｓｙ Ｏｐｔｉｍｉｚｅｒ", "autoCrystalPlaceClock", "AutoFirework", "ElytraSwap", "FastXP", "FastExp", "NoJumpDelay",
    "ＥｌｙｔｒａＳｗａｐ", "Ｅｌｙｔｒａ Ｓｗａｐ", "PackSpoof", "Antiknockback", "catlean", "AuthBypass", "obfuscatedAuth",
    "LicenseCheckMixin", "BaseFinder", "invsee", "ItemExploit", "FreezePlayer","VirtualMachine", "Ｆｒｅｅｃａｍ",
    "Ｍｏｖｅ ｆｒｅｅｌｙ ｔｈｒｏｕｇｈ ｗａｌｌｓ", "Ｎｏ Ｃｌｉｐ", "Ｆｒｅｅｚｅ Ｐｌａｙｅｒ", "LWFH Crystal", "JDWP.VirtualMachine.AllModules",
    "ＬＷＦＨ Ｃｒｙｓｔａｌ", "KeyPearl", "LootYeeter", "ＫｅｙＰｅａｒｌ", "Ｋｅｙ Ｐｅａｒｌ", "Ｌｏｏｔ Ｙｅｅｔｅｒ", "FastPlace",
    "Ｆａｓｔ Ｐｌａｃｅ", "Ｐｌａｃｅ ｂｌｏｃｋｓ ｆａｓｔｅｒ", "AutoBreach", "Ａｕｔｏ Ｂｒｅａｃｈ", "setBlockBreakingCooldown",
    "getBlockBreakingCooldown", "blockBreakingCooldown", "onBlockBreaking", "setItemUseCooldown", "setSelectedSlot",
    "invokeDoAttack", "invokeDoItemUse", "invokeOnMouseButton", "onPushOutOfBlocks", "onIsGlowing",
    "Automatically switches to sword when hitting with totem", "arrayOfString", "POT_CHEATS", "Dqrkis Client", "Entity.isGlowing",
    "Activate Key", "Ａｃｔｉｖａｔｅ Ｋｅｙ", "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ", "On RMB", "Ｏｎ ＲＭＢ",
    "No Count Glitch", "Ｎｏ Ｃｏｕｎｔ Ｇｌｉｔｃｈ", "No Bounce", "NoBounce", "Ｎｏ Ｂｏｕｎｃｅ", "ＮｏＢｏｕｎｃｅ",
    "Ｒｅｍｏｖｅｓ ｔｈｅ ｃｒｙｓｔａｌ ｂｏｕｎｃｅ ａｎｉｍａｔｉｏｎ", "Place Delay", "Ｐｌａｃｅ Ｄｅｌａｙ", "Break Delay", "Ｂｒｅａｋ Ｄｅｌａｙ",
    "Ｆａｓｔ Ｍｏｄｅ", "Place Chance", "Ｐｌａｃｅ Ｃｈａｎｃｅ", "Break Chance", "Ｂｒｅａｋ Ｃｈａｎｃｅ", "Stop On Kill", "Ｓｔｏｐ Ｏｎ Ｋｉｌｌ",
    "Ｄａｍａｇｅ Ｔｉｃｋ", "damagetick", "Anti Weakness", "Ａｎｔｉ Ｗｅａｋｎｅｓｓ", "Particle Chance", "Ｐａｒｔｉｃｌｅ Ｃｈａｎｃｅ",
    "Trigger Key", "Ｔｒｉｇｇｅｒ Ｋｅｙ", "Switch Delay", "Ｓｗｉｔｃｈ Ｄｅｌａｙ", "Totem Slot", "Ｔｏｔｅｍ Ｓｌｏｔ", "Silent Rotations",
    "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ", "Smooth Rotations", "Ｓｍｏｏｔｈ Ｒｏｔａｔｉｏｎｓ", "Rotation Speed", "Ｒｏｔａｔｉｏｎ Ｓｐｅｅｄ",
    "Use Easing", "Ｕｓｅ Ｅａｓｉｎｇ", "Easing Strength", "Ｅａｓｉｎｇ Ｓｔｒｅｎｇｔｈ", "While Use", "Ｗｈｉｌｅ Ｕｓｅ",
    "Stop on Kill", "Ｓｔｏｐ ｏｎ Ｋｉｌｌ", "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ", "Glowstone Delay", "Ｇｌｏｗｓｔｏｎｅ Ｄｅｌａｙ",
    "Glowstone Chance", "Ｇｌｏｗｓｔｏｎｅ Ｃｈａｎｃｅ", "Explode Delay", "Ｅｘｐｌｏｄｅ Ｄｅｌａｙ", "Explode Chance", "Ｅｘｐｌｏｄｅ Ｃｈａｎｃｅ",
    "Explode Slot", "Ｅｘｐｌｏｄｅ Ｓｌｏｔ", "Only Charge", "Ｏｎｌｙ Ｃｈａｒｇｅ", "Anchor Macro", "Ａｎｃｈｏｒ Ｍａｃｒｏ",
    "Reach Distance", "Ｒｅａｃｈ Ｄｉｓｔａｎｃｅ", "Min Height", "Ｍｉｎ Ｈｅｉｇｈｔ", "Min Fall Speed", "Ｍｉｎ Ｆａｌｌ Ｓｐｅｅｄ",
    "Attack Delay", "Ａｔｔａｃｋ Ｄｅｌａｙ", "Breach Delay", "Ｂｒｅａｃｈ Ｄｅｌａｙ", "Require Elytra", "Ｒｅｑｕｉｒｅ Ｅｌｙｔｒａ",
    "Auto Switch Back", "Ａｕｔｏ Ｓｗｉｔｃｈ Ｂａｃｋ", "Check Line of Sight", "Ｃｈｅｃｋ Ｌｉｎｅ ｏｆ Ｓｉｇｈｔ",
    "Only When Falling", "Ｏｎｌｙ Ｗｈｅｎ Ｆａｌｌｉｎｇ", "Require Crit", "Ｒｅｑｕｉｒｅ Ｃｒｉｔ", "Show Status Display", "Ｓｈｏｗ Ｓｔａｔｕｓ Ｄｉｓｐｌａｙ",
    "Stop On Crystal", "Ｓｔｏｐ Ｏｎ Ｃｒｙｓｔａｌ", "Check Shield", "Ｃｈｅｃｋ Ｓｈｉｅｌｄ", "On Pop", "Ｏｎ Ｐｏｐ",
    "Predict Damage", "Ｐｒｅｄｉｃｔ Ｄａｍａｇｅ", "On Ground", "Ｏｎ Ｇｒｏｕｎｄ", "Check Players", "Ｃｈｅｃｋ Ｐｌａｙｅｒｓ",
    "Predict Crystals", "Ｐｒｅｄｉｃｔ Ｃｒｙｓｔａｌｓ", "Check Aim", "Ｃｈｅｃｋ Ａｉｍ", "Check Items", "Ｃｈｅｃｋ Ｉｔｅｍｓ",
    "Activates Above", "Ａｃｔｉｖａｔｅｓ Ａｂｏｖｅ", "Blatant", "Ｂｌａｔａｎｔ", "Force Totem", "Ｆｏｒｃｅ Ｔｏｔｅｍ",
    "Stay Open For", "Ｓｔａｙ Ｏｐｅｎ Ｆｏｒ", "Auto Inventory Totem", "Ａｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ", "Only On Pop", "Ｏｎｌｙ Ｏｎ Ｐｏｐ",
    "Vertical Speed", "Ｖｅｒｔｉｃａｌ Ｓｐｅｅｄ", "Hover Totem", "Ｈｏｖｅｒ Ｔｏｔｅｍ", "Swap Speed", "Ｓｗａｐ Ｓｐｅｅｄ",
    "Strict One-Tick", "Ｓｔｒｉｃｔ Ｏｎｅ－Ｔｉｃｋ", "Mace Priority", "Ｍａｃｅ Ｐｒｉｏｒｉｔｙ", "Min Totems", "Ｍｉｎ Ｔｏｔｅｍｓ",
    "Min Pearls", "Ｍｉｎ Ｐｅａｒｌｓ", "Totem First", "Ｔｏｔｅｍ Ｆｉｒｓｔ", "Drop Interval", "Ｄｒｏｐ Ｉｎｔｅｒｖａｌ",
    "Random Pattern", "Ｒａｎｄｏｍ Ｐａｔｔｅｒｎ", "Loot Yeeter", "Ｌｏｏｔ Ｙｅｅｔｅｒ", "Horizontal Aim Speed", "Ｈｏｒｉｚｏｎｔａｌ Ａｉｍ Ｓｐｅｅｄ",
    "Vertical Aim Speed", "Ｖｅｒｔｉｃａｌ Ａｉｍ Ｓｐｅｅｄ", "Include Head", "Ｉｎｃｌｕｄｅ Ｈｅａｄ", "Web Delay", "Ｗｅｂ Ｄｅｌａｙ",
    "Holding Web", "Ｈｏｌｄｉｎｇ Ｗｅｂ", "Not When Affects Player", "Ｎｏｔ Ｗｈｅｎ Ａｆｆｅｃｔｓ Ｐｌａｙｅｒ", "Hit Delay", "Ｈｉｔ Ｄｅｌａｙ",
    "Ｓｗｉｔｃｈ Ｂａｃｋ", "Require Hold Axe", "Ｒｅｑｕｉｒｅ Ｈｏｌｄ Ａｘｅ", "Fake Punch", "Ｆａｋｅ Ｐｕｎｃｈ",
    "placeInterval", "breakInterval", "stopOnKill", "activateOnRightClick", "holdCrystal",
    "ｐｌａｃｅＩｎｔｅｒｖａｌ", "ｂｒｅａｋＩｎｔｅｒｖａｌ", "ｓｔｏｐＯｎＫｉｌｌ", "ａｃｔｉｖａｔｅＯｎＲｉｇｈｔＣｌｉｃｋ",
    "ｄａｍａｇｅｔｉｃｋ", "ｈｏｌｄＣｒｙｓｔａｌ", "ｆａｋｅＰｕｎｃｈ", "Ｒｅｆｉｌｌｓ ｙｏｕｒ ｈｏｔｂａｒ ｗｉｔｈ ｐｏｔｉｏｎｓ",
    "Ｋｅｐｓ ｙｏｕ ｓｐｒｉｎｔｉｎｇ ａｔ ａｌｌ ｔｉｍｅｓ", "Ｐｌａｃｅｓ ａｎｃｈｏｒ， ｃｈａｒｇｅｓ ｉｔ， ｐｒｏｔｅｃｔｓ ｙｏｕ， ａｎｄ ｅｘｐｌｏｄｅｓ",
    "Ａｕｔｏ ｓｗａｐ ｔｏ ｓｐｅａｒ ｏｎ ａｔｔａｃｋ", "Macro Key", "Ａｕｔｏ Ｐｏｔ", "Ｍａｃｒｏ Ｋｅｙ",
    "KillAura", "ClickAura", "MultiAura", "ForceField", "LegitAura", "AimBot", "AutoAim", "SilentAim", "AimLock", "HeadSnap",
    "CrystalAura", "AnchorAura", "AnchorFill", "AnchorPlace", "BedAura", "AutoBed", "BedBomb", "BedPlace",
    "BowAimbot", "BowSpam", "AutoBow", "AutoCrit", "CritBypass", "AlwaysCrit", "CriticalHit",
    "ReachHack", "ExtendReach", "LongReach", "HitboxExpand", "AntiKB", "NoKnockback", "GrimVelocity", "GrimDisabler",
    "VelocitySpoof", "KBReduce", "OffhandTotem", "TotemSwitch", "AutoWeapon", "AutoSword", "AutoCity", "Burrow", "SelfTrap",
    "HoleFiller", "AntiSurround", "AntiBurrow", "WTap", "TargetStrafe", "AutoGap", "AutoPearl",
    "FlyHack", "CreativeFlight", "BoatFly", "PacketFly", "AirJump", "SpeedHack", "BHop", "BunnyHop",
    "AntiFall", "NoFallDamage", "SafeFall", "StepHack", "FastClimb", "AutoStep", "HighStep",
    "WaterWalk", "LiquidWalk", "LavaWalk", "NoSlow", "NoSlowdown", "NoWeb", "NoSoulSand", "WallHack",
    "ElytraSpeed", "InstantElytra", "ScaffoldWalk", "FastBridge", "BuildHelper", "AutoBridge",
    "Nuker", "NukerLegit", "InstantBreak", "GhostHand", "NoSwing", "PlaceAssist", "AirPlace", "AutoPlace", "InstantPlace",
    "PlayerESP", "MobESP", "ItemESP", "StorageESP", "ChestESP", "Tracers", "NameTagsHack",
    "XRayHack", "OreFinder", "CaveFinder", "OreESP", "NewChunks", "ChunkBorders", "TunnelFinder",
    "TargetHUD", "ReachDisplay", "DoubleClicker", "JitterClick", "ButterflyClick", "CPSBoost",
    "ChestStealer", "InvManager", "InvMovebypass", "AutoSprint", "AntiAFK", "AutoRespawn",
    "FakeNick", "PopSwitch", "FakeLatency", "FakePing", "SpoofRotation", "PositionSpoof",
    "GameSpeed", "SpeedTimer", "GrimBypass", "VulcanBypass", "MatrixBypass", "AACBypass",
    "VerusDisabler", "IntaveBypass", "WatchdogBypass", "PacketMine", "PacketWalk", "PacketSneak",
    "PacketCancel", "PacketDupe", "PacketSpam", "SelfDestruct", "HideClient", "SessionStealer",
    "TokenLogger", "TokenGrabber", "DiscordToken", "RemoteAccess", "ReverseShell", "C2Server", "Backdoor", "KeyLogger",
    "StashFinder", "TrailFinder", "imgui.binding", "JNativeHook", "GlobalScreen", "NativeKeyListener",
    "client-refmap.json", "cheat-refmap.json", "aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==",
    "meteordevelopment", "cc/novoline", "com/alan/clients", "club/maxstats", "wtf/moonlight",
    "me/zeroeightsix/kami", "net/ccbluex", "today/opai", "net/minecraft/injection", "org/chainlibs/module/impl/modules",
    "xyz/greaj", "com/cheatbreaker", "com/moonsworth", "doomsdayclient", "DoomsdayClient", "doomsday.jar",
    "novaclient", "api.novaclient.lol", "WalksyOptimizer", "LWFH Crystal", "vape.gg", "vapeclient",
    "VapeClient", "VapeLite", "intent.store", "IntentClient", "rise.today", "riseclient.com",
    "meteor-client", "meteorclient", "meteordevelopment.meteorclient", "liquidbounce", "fdp-client", "net.ccbluex",
    "novoware", "novoclient", "aristois", "impactclient", "azura", "pandaware", "skilled", "moonClient", "astolfo",
    "futureClient", "konas", "rusherhack", "inertia", "exhibition", "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton",
    "VirginClient", "virgin client", "catlean", "CatleanClient", "catlean client", "ArgonClient", "argon client",
    "Asteria", "AsteriaClient", "asteria client", "Prestige", "PrestigeClient", "prestige client", "prestigeclient.vip",
    "gypsy", "GypsyClient", "gypsy client", "Xenon", "XenonClient", "xenon client", "GrimClient", "grim client",
    "phantom-refmap.json", "dqrkis.xyz", "Dqrkis Client"
)

 $patternRegex = [regex]::new(
    '(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

 $cheatStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $cheatStrings) { [void]$cheatStringSet.Add($s) }

 $fullwidthRegex = [regex]::new(
    "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}",
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

# Helper Functions
function Get-FileSHA1 { param([string]$Path); return (Get-FileHash -Path $Path -Algorithm SHA1).Hash }

function Get-DownloadSource {
    param([string]$Path)
    $zoneData = Get-Content -Raw -Stream Zone.Identifier $Path -ErrorAction SilentlyContinue
    if ($zoneData -match "HostUrl=(.+)") {
        $url = $matches[1].Trim()
        if ($url -match "mediafire\.com") { return "MediaFire" }
        elseif ($url -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { return "Discord" }
        elseif ($url -match "dropbox\.com") { return "Dropbox" }
        elseif ($url -match "drive\.google\.com") { return "Google Drive" }
        elseif ($url -match "mega\.nz|mega\.co\.nz") { return "MEGA" }
        elseif ($url -match "github\.com") { return "GitHub" }
        elseif ($url -match "modrinth\.com") { return "Modrinth" }
        elseif ($url -match "curseforge\.com") { return "CurseForge" }
        elseif ($url -match "doomsdayclient\.com") { return "DoomsdayClient" }
        elseif ($url -match "prestigeclient\.vip") { return "PrestigeClient" }
        elseif ($url -match "dqrkis\.xyz") { return "Dqrkis" }
        else { if ($url -match "https?://(?:www\.)?([^/]+)") { return $matches[1] } else { return $url } }
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

function Invoke-ModScan {
    param([string]$FilePath)
    $foundPatterns = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings  = [System.Collections.Generic.HashSet[string]]::new()
    $foundFullwidth= [System.Collections.Generic.HashSet[string]]::new()
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        foreach ($entry in $archive.Entries) { foreach ($m in $patternRegex.Matches($entry.FullName)) { [void]$foundPatterns.Add($m.Value) } }
        $allEntries = [System.Collections.Generic.List[object]]::new(); $innerArchives = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $archive.Entries) { $allEntries.Add($e) }
        foreach ($nj in ($archive.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ns = $nj.Open(); $ms = New-Object System.IO.MemoryStream; $ns.CopyTo($ms); $ns.Close(); $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $innerArchives.Add($iz); foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
            } catch { }
        }
        foreach ($entry in $allEntries) {
            $name = $entry.FullName
            if ($name -match '\.(class|json)$' -or $name -match 'MANIFEST\.MF') {
                try {
                    $st = $entry.Open(); $ms2 = New-Object System.IO.MemoryStream; $st.CopyTo($ms2); $st.Close()
                    $bytes = $ms2.ToArray(); $ms2.Dispose()
                    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes); $utf8 = [System.Text.Encoding]::UTF8.GetString($bytes)
                    foreach ($m in $patternRegex.Matches($ascii)) { [void]$foundPatterns.Add($m.Value) }
                    foreach ($s in $cheatStringSet) { if ($ascii.Contains($s)) { [void]$foundStrings.Add($s); continue } if ($utf8.Contains($s)) { [void]$foundStrings.Add($s) } }
                    foreach ($m in $fullwidthRegex.Matches($utf8)) { [void]$foundFullwidth.Add($m.Value) }
                } catch { }
            }
        }
        foreach ($ia in $innerArchives) { try { $ia.Dispose() } catch { } }; $archive.Dispose()
    } catch { }
    # Fullwidth resolution
    $fwCheatPool = @($script:cheatStrings | Where-Object { $_ -cmatch "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]" })
    $resolvedFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in @($foundFullwidth)) {
        if ($fw.Length -lt 3) { continue }; $bestMatch = $null
        foreach ($cs in $fwCheatPool) {
            if ($cs.Contains($fw)) { if ($null -eq $bestMatch -or $cs.Length -lt $bestMatch.Length) { $bestMatch = $cs } }
        }
        if ($null -ne $bestMatch) { [void]$resolvedFullwidth.Add($bestMatch) } elseif ($fw.Length -ge 6) { [void]$resolvedFullwidth.Add($fw) }
    }
    $resolved = @($resolvedFullwidth)
    $finalFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in $resolved) {
        $isRedundant = $false
        foreach ($other in $resolved) { if ($fw.Length -lt $other.Length -and $other.Contains($fw)) { $isRedundant = $true; break } }
        if (-not $isRedundant) { [void]$finalFullwidth.Add($fw) }
    }
    return @{ Patterns = $foundPatterns; Strings = $foundStrings; Fullwidth = $finalFullwidth }
}

function Invoke-ObfuscationScan {
    param([string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $totalClass = 0; $numericCount = 0; $unicodeCount = 0; $fullwidthCount = 0; $japaneseCount = 0
        $singleLetterCount = 0; $twoLetterCount = 0; $gibberishCount = 0; $noVowelCount = 0
        $confusionCount = 0; $singleCharPkg = 0
        $cheatObfuscators = @{
            "Skidfuscator" = @("dev/skidfuscator", "Skidfuscator", "skidfuscator.dev"); "Paramorphism" = @("Paramorphism", "paramorphism-", "dev/paramorphism")
            "Radon" = @("ItzSomebody/Radon", "me/itzsomebody/radon", "Radon Obfuscator"); "Caesium" = @("sim0n/Caesium", "Caesium Obfuscator", "dev/sim0n/caesium")
            "Bozar" = @("vimasig/Bozar", "Bozar Obfuscator", "com/bozar"); "Branchlock" = @("Branchlock", "branchlock.dev")
            "Binscure" = @("Binscure", "com/binscure"); "SuperBlaubeere" = @("superblaubeere", "superblaubeere27")
            "Qprotect" = @("Qprotect", "QProtect", "mdma.dev/qprotect"); "Zelix" = @("ZKMFLOW", "ZKM", "ZelixKlassMaster", "com/zelix")
            "Stringer" = @("StringerJavaObfuscator", "com/licel/stringer"); "JNIC" = @("JNIC", "jnic.obf", "jnic-obfuscator")
            "Scuti" = @("ScutiObf", "scuti.obf"); "Smoke" = @("SmokeObf", "smoke.obf")
        }
        foreach ($entry in $archive.Entries) {
            $name = $entry.FullName
            if ($name -match "\.class$") {
                $totalClass++
                $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split "/")[-1])
                if ($className -match "^\d+$") { $numericCount++ }
                if ($className -match "[^\x00-\x7F]") { $unicodeCount++ }
                if ($className -match "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]") { $fullwidthCount++ }
                if ($className -match "[\u3040-\u309F\u30A0-\u30FF]") { $japaneseCount++ }
                if ($className -match "^[a-zA-Z]$") { $singleLetterCount++ }
                if ($className -match "^[a-zA-Z]{2}$") { $twoLetterCount++ }
                if ($className -match "^[Il1O0]+$" -or $className -match "^[_]+$") { $confusionCount++ }
                if ($className.Length -ge 3 -and $className.Length -le 8 -and $className -match "^[a-zA-Z]+$") {
                    $vowels = ($className.ToCharArray() | Where-Object { $_ -match "[aeiouAEIOU]" }).Count
                    if ($vowels -eq 0) { $noVowelCount++ }
                    $hasCluster = $className -match "[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]{3,}"
                    if ($hasCluster -and ($vowels / $className.Length) -lt 0.3) { $gibberishCount++ }
                }
                $segs = ($name -replace "\.class$", "") -split "/"
                foreach ($seg in $segs[0..($segs.Count - 2)]) { if ($seg.Length -eq 1) { $singleCharPkg++ } }
                if ($entry.Length -lt 100000 -and $entry.Length -gt 100) {
                    try {
                        $st = $entry.Open(); $ms = New-Object System.IO.MemoryStream; $st.CopyTo($ms); $st.Close()
                        $ascii = [System.Text.Encoding]::ASCII.GetString($ms.ToArray()); $ms.Dispose()
                        foreach ($obfName in $cheatObfuscators.Keys) {
                            foreach ($pat in $cheatObfuscators[$obfName]) { if ($ascii.Contains($pat)) { $flags.Add("Known cheat obfuscator detected — $obfName"); break } }
                        }
                    } catch { }
                }
            }
        }
        $archive.Dispose()
        if ($totalClass -lt 5) { return $flags }
        $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }
        $numPct = & $pct $numericCount; $uniPct = & $pct $unicodeCount; $fwPct = & $pct $fullwidthCount
        $jpPct = & $pct $japaneseCount; $s1Pct = & $pct $singleLetterCount; $s2Pct = & $pct $twoLetterCount
        $gibPct = & $pct $gibberishCount; $novPct = & $pct $noVowelCount; $confPct = & $pct $confusionCount
        if ($numPct -ge 20) { $flags.Add("Numeric class names — $numPct%") }
        if ($uniPct -ge 10) { $flags.Add("Unicode class names — $uniPct%") }
        if ($fwPct -gt 0) { $flags.Add("Fullwidth Unicode class names — $fwPct%") }
        if ($jpPct -gt 0) { $flags.Add("Japanese obfuscation — $jpPct%") }
        if ($s1Pct -ge 15) { $flags.Add("Single-letter class names — $s1Pct%") }
        if ($s2Pct -ge 20) { $flags.Add("Two-letter class names — $s2Pct%") }
        if ($gibPct -ge 5) { $flags.Add("Gibberish class names — $gibPct%") }
        if ($novPct -ge 8) { $flags.Add("No-vowel class names — $novPct%") }
        if ($confPct -ge 3) { $flags.Add("Confusion-char names (Il1O0/_) — $confPct%") }
        if ($singleCharPkg -ge 6) { $flags.Add("Single-char package paths — $singleCharPkg path segments") }
    } catch { }
    return $flags
}

function Invoke-BypassScan {
    param([string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()
    $mavenPrefixes = @("com_","org_","net_","io_","dev_","gs_","xyz_","app_","me_","tv_","uk_","be_","fr_","de_")
    function Test-SuspiciousJarName { param([string]$JarName); $base = [System.IO.Path]::GetFileNameWithoutExtension($JarName); if ($base -match '\d') { return $false }; foreach ($pfx in $mavenPrefixes) { if ($base.ToLower().StartsWith($pfx)) { return $false } }; if ($base.Length -gt 20) { return $false }; return $true }
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $nestedJars = @($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })
        $suspiciousNestedJars = @()
        foreach ($nj in $nestedJars) { $njBase = [System.IO.Path]::GetFileName($nj.FullName); if (Test-SuspiciousJarName -JarName $njBase) { $suspiciousNestedJars += $njBase } }
        foreach ($sj in $suspiciousNestedJars) { $flags.Add("Suspicious nested JAR: $sj") }
        $runtimeExecFound = $false; $httpDownloadFound = $false; $httpExfilFound = $false; $obfuscatedCount = 0; $totalClassCount = 0
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName
            if ($name -match "\.class$") {
                $totalClassCount++; $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split "/")[-1])
                $segs = ($name -replace "\.class$","") -split "/"; $consecutiveSingle = 0; $maxConsecutive = 0
                foreach ($seg in $segs) { if ($seg.Length -eq 1) { $consecutiveSingle++; if ($consecutiveSingle -gt $maxConsecutive) { $maxConsecutive = $consecutiveSingle } } else { $consecutiveSingle = 0 } }
                if ($maxConsecutive -ge 3) { $obfuscatedCount++ }
                try {
                    $st = $entry.Open(); $ms2 = New-Object System.IO.MemoryStream; $st.CopyTo($ms2); $st.Close(); $rawBytes = $ms2.ToArray(); $ms2.Dispose(); $ct = [System.Text.Encoding]::ASCII.GetString($rawBytes)
                    if ($ct -match "java/lang/Runtime" -and $ct -match "getRuntime" -and $ct -match "exec") { $runtimeExecFound = $true }
                    if ($ct -match "openConnection" -and $ct -match "HttpURLConnection" -and $ct -match "FileOutputStream") { $httpDownloadFound = $true }
                    if ($ct -match "openConnection" -and $ct -match "setDoOutput" -and $ct -match "getOutputStream" -and $ct -match "getProperty") { $httpExfilFound = $true }
                } catch { }
            }
        }
        $zip.Dispose()
        $obfPct = if ($totalClassCount -ge 10) { [math]::Round(($obfuscatedCount / $totalClassCount) * 100) } else { 0 }
        if ($runtimeExecFound -and $obfPct -ge 25) { $flags.Add("Runtime.exec() in obfuscated code") }
        if ($httpDownloadFound) { $flags.Add("HTTP file download capability") }
        if ($httpExfilFound) { $flags.Add("HTTP POST exfiltration capability") }
        if ($totalClassCount -ge 10 -and $obfPct -ge 25) { $flags.Add("Heavy obfuscation — $obfPct% single-letter paths") }
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
        $wmi = Get-WmiObject Win32_Process -Filter "ProcessId = $javaPid" -ErrorAction Stop
        $cmdLine = $wmi.CommandLine
        if ($cmdLine) {
            $agentMatches = [regex]::Matches($cmdLine, '-javaagent:([^\s"]+)')
            foreach ($m in $agentMatches) {
                $agentPath = $m.Groups[1].Value.Trim('"').Trim("'"); $agentName = [System.IO.Path]::GetFileName($agentPath)
                $legitAgents = @("jmxremote","yjp","jrebel","newrelic","jacoco","theseus"); $isLegit = $false
                foreach ($la in $legitAgents) { if ($agentName -match $la) { $isLegit = $true; break } }
                if (-not $isLegit) { $results.Add("JVM Agent: $agentName") }
            }
            $suspiciousFlags = @(
                @{ Flag = "-Xbootclasspath/p:"; Desc = "Prepends to bootstrap classpath" },
                @{ Flag = "-Xbootclasspath/a:"; Desc = "Appends to bootstrap classpath" },
                @{ Flag = "-agentlib:jdwp"; Desc = "JDWP debug agent enabled" },
                @{ Flag = "-agentpath:"; Desc = "Native agent loaded" }
            )
            foreach ($sf in $suspiciousFlags) { if ($cmdLine -match [regex]::Escape($sf.Flag)) { $results.Add("Suspicious JVM flag: $($sf.Flag)") } }
        }
    } catch { }
    return $results
}

# ---------------------------------------------------------
# GUI FORM
# ---------------------------------------------------------

 $mainForm = New-Object System.Windows.Forms.Form
 $mainForm.Text = "Minecraft Mod Scanner (by MeowTonynoh)"
 $mainForm.Size = New-Object System.Drawing.Size(1000, 700)
 $mainForm.StartPosition = "CenterScreen"
 $mainForm.MinimumSize = New-Object System.Drawing.Size(800, 600)

# Layout: Top Panel (Controls), Bottom Panel (Tabs)
 $topPanel = New-Object System.Windows.Forms.Panel
 $topPanel.Height = 80
 $topPanel.Dock = "Top"
 $mainForm.Controls.Add($topPanel)

# Path Input
 $lblPath = New-Object System.Windows.Forms.Label
 $lblPath.Text = "Mods Folder:"
 $lblPath.Location = New-Object System.Drawing.Point(10, 15)
 $lblPath.AutoSize = $true
 $topPanel.Controls.Add($lblPath)

 $txtPath = New-Object System.Windows.Forms.TextBox
 $txtPath.Location = New-Object System.Drawing.Point(100, 12)
 $txtPath.Size = New-Object System.Drawing.Size(500, 25)
 $txtPath.Text = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
 $topPanel.Controls.Add($txtPath)

 $btnBrowse = New-Object System.Windows.Forms.Button
 $btnBrowse.Location = New-Object System.Drawing.Point(610, 10)
 $btnBrowse.Size = New-Object System.Drawing.Size(80, 30)
 $btnBrowse.Text = "Browse..."
 $topPanel.Controls.Add($btnBrowse)

# Scan Button
 $btnScan = New-Object System.Windows.Forms.Button
 $btnScan.Location = New-Object System.Drawing.Point(700, 10)
 $btnScan.Size = New-Object System.Drawing.Size(100, 30)
 $btnScan.Text = "Scan Mods"
 $btnScan.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
 $btnScan.ForeColor = [System.Drawing.Color]::White
 $btnScan.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
 $topPanel.Controls.Add($btnScan)

# JVM Check Button
 $btnJvm = New-Object System.Windows.Forms.Button
 $btnJvm.Location = New-Object System.Drawing.Point(810, 10)
 $btnJvm.Size = New-Object System.Drawing.Size(120, 30)
 $btnJvm.Text = "Check JVM"
 $topPanel.Controls.Add($btnJvm)

# Progress Bar
 $progressBar = New-Object System.Windows.Forms.ProgressBar
 $progressBar.Location = New-Object System.Drawing.Point(10, 50)
 $progressBar.Size = New-Object System.Drawing.Size(960, 20)
 $progressBar.Style = "Continuous"
 $topPanel.Controls.Add($progressBar)

 $lblStatus = New-Object System.Windows.Forms.Label
 $lblStatus.Text = "Ready"
 $lblStatus.Location = New-Object System.Drawing.Point(10, 75)
 $lblStatus.AutoSize = $true
 $lblStatus.ForeColor = [System.Drawing.Color]::Gray
 $topPanel.Controls.Add($lblStatus)

# TabControl
 $tabControl = New-Object System.Windows.Forms.TabControl
 $tabControl.Dock = "Fill"
 $tabControl.Appearance = "FlatButtons"
 $mainForm.Controls.Add($tabControl)

# Define Tabs
function Create-ListViewTab($Name, $Color) {
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = $Name
    $tab.BackColor = $Color
    
    $lv = New-Object System.Windows.Forms.ListView
    $lv.Dock = "Fill"
    $lv.View = "Details"
    $lv.FullRowSelect = $true
    $lv.GridLines = $true
    $lv.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    $lv.Columns.Add("File Name", 300) | Out-Null
    $lv.Columns.Add("Status/Reason", 400) | Out-Null
    $lv.Columns.Add("Size (MB)", 80) | Out-Null
    
    $tab.Controls.Add($lv)
    $tabControl.TabPages.Add($tab)
    return $lv
}

 $lvSuspicious = Create-ListViewTab "Suspicious" ([System.Drawing.Color]::FromArgb(255, 240, 240))
 $lvInjection  = Create-ListViewTab "Injection/Obfuscated" ([System.Drawing.Color]::FromArgb(255, 245, 240))
 $lvVerified   = Create-ListViewTab "Verified" ([System.Drawing.Color]::FromArgb(240, 255, 240))
 $lvUnknown    = Create-ListViewTab "Unknown" ([System.Drawing.Color]::FromArgb(245, 245, 245))

# ---------------------------------------------------------
# EVENT HANDLERS
# ---------------------------------------------------------

 $btnBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $txtPath.Text = $folderBrowser.SelectedPath
    }
})

 $btnJvm.Add_Click({
    $jvmResults = Invoke-JvmScan
    if ($jvmResults.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No suspicious JVM agents or flags detected.", "JVM Scan Result", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        $msg = "Suspicious JVM Activity Detected:`n`n" + ($jvmResults -join "`n")
        [System.Windows.Forms.MessageBox]::Show($msg, "JVM WARNING", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})

# Function to show details on double click
function Show-ModDetails {
    param($ListView)
    if ($ListView.SelectedItems.Count -eq 0) { return }
    $item = $ListView.SelectedItems[0]
    $data = $item.Tag
    
    $detailsForm = New-Object System.Windows.Forms.Form
    $detailsForm.Text = "Details: " + $item.Text
    $detailsForm.Size = New-Object System.Drawing.Size(600, 500)
    $detailsForm.StartPosition = "CenterScreen"
    
    $txtDetails = New-Object System.Windows.Forms.TextBox
    $txtDetails.Multiline = $true
    $txtDetails.ScrollBars = "Vertical"
    $txtDetails.Dock = "Fill"
    $txtDetails.Font = New-Object System.Drawing.Font("Consolas", 10)
    $txtDetails.ReadOnly = $true
    
    $content = ""
    
    if ($data -is [System.Collections.Specialized.OrderedDictionary]) {
        # Raw dump for injection/obfuscation
        $content = "Flags Detected:`n`n"
        foreach ($k in $data.Keys) { $content += "[$k]`n" }
    } elseif ($data.PSObject.Properties.Match('Patterns').Count -gt 0) {
        # Suspicious
        if ($data.Patterns.Count -gt 0) { $content += "=== PATTERNS ===`n" + ($data.Patterns -join "`n") + "`n`n" }
        if ($data.Strings.Count -gt 0) { $content += "=== STRINGS ===`n" + ($data.Strings -join "`n") + "`n`n" }
        if ($data.Fullwidth.Count -gt 0) { $content += "=== FULLWIDTH UNICODE ===`n" + ($data.Fullwidth -join "`n") + "`n`n" }
    }
    
    $txtDetails.Text = $content
    $detailsForm.Controls.Add($txtDetails)
    $detailsForm.ShowDialog()
}

 $lvSuspicious.Add_DoubleClick({ Show-ModDetails -ListView $lvSuspicious })
 $lvInjection.Add_DoubleClick({ Show-ModDetails -ListView $lvInjection })

 $btnScan.Add_Click({
    $path = $txtPath.Text
    if (-not (Test-Path $path -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("Invalid Path!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Clear Lists
    $lvSuspicious.Items.Clear()
    $lvInjection.Items.Clear()
    $lvVerified.Items.Clear()
    $lvUnknown.Items.Clear()
    
    try {
        $jarFiles = Get-ChildItem -Path $path -Filter *.jar -ErrorAction Stop
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error accessing directory: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    $totalFiles = $jarFiles.Count
    $progressBar.Maximum = $totalFiles
    $progressBar.Value = 0
    $btnScan.Enabled = $false
    
    # Lists to hold results
    $verifiedMods = @()
    $unknownMods = @()
    $suspiciousMods = @{}
    $bypassMods = @{}
    $obfuscatedMods = @{}
    
    # Pass 1: Hash Verification
    $lblStatus.Text = "Pass 1: Verifying Hashes (Modrinth/Megabase)..."
    $idx = 0
    foreach ($jar in $jarFiles) {
        $idx++
        $progressBar.Value = $idx
        $lblStatus.Text = "Verifying ($idx/$totalFiles): $($jar.Name)"
        $mainForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
        
        $hash = Get-FileSHA1 -Path $jar.FullName
        if ($hash) {
            $modrinthData = Query-Modrinth -Hash $hash
            $modrinthWhitelisted = @("viafabricplus", "viafabricversion") -contains $modrinthData.Slug.ToLower()
            if ($modrinthData.Slug) {
                $verifiedMods += [PSCustomObject]@{ Name = $modrinthData.Name; File = $jar; Source = "Modrinth"; Whitelisted = $modrinthWhitelisted }
                continue
            }
            $megabaseData = Query-Megabase -Hash $hash
            if ($megabaseData.name) {
                $verifiedMods += [PSCustomObject]@{ Name = $megabaseData.Name; File = $jar; Source = "Megabase"; Whitelisted = $false }
                continue
            }
        }
        $src = Get-DownloadSource $jar.FullName
        $unknownMods += [PSCustomObject]@{ File = $jar; Source = if($src) {$src} else {"Local/Unknown"} }
    }
    
    # Pass 2 & 3: Deep Scans
    $lblStatus.Text = "Pass 2 & 3: Deep Scanning..."
    $idx = 0
    foreach ($jar in $jarFiles) {
        $idx++
        $progressBar.Value = $idx
        $lblStatus.Text = "Scanning ($idx/$totalFiles): $($jar.Name)"
        $mainForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
        
        # Check if whitelisted verified
        $vMod = $verifiedMods | Where-Object { $_.File.Name -eq $jar.Name } | Select-Object -First 1
        if ($vMod -and $vMod.Whitelisted -eq $true) { continue }
        
        # Mod Scan
        $result = Invoke-ModScan -FilePath $jar.FullName
        if ($result.Patterns.Count -gt 0 -or $result.Strings.Count -gt 0 -or $result.Fullwidth.Count -gt 0) {
            $suspiciousMods[$jar.FullName] = [PSCustomObject]@{
                FileName = $jar.Name
                FilePath = $jar.FullName
                Patterns = $result.Patterns
                Strings = $result.Strings
                Fullwidth = $result.Fullwidth
            }
            # Remove from verified if present
            $verifiedMods = $verifiedMods | Where-Object { $_.File.Name -ne $jar.Name }
            continue
        }
        
        # Bypass/Injection Scan
        $bypassFlags = Invoke-BypassScan -FilePath $jar.FullName
        if ($bypassFlags.Count -gt 0) {
            $bypassMods[$jar.FullName] = [PSCustomObject]@{
                FileName = $jar.Name
                FilePath = $jar.FullName
                Flags = $bypassFlags
                Type = "Injection"
            }
            $verifiedMods = $verifiedMods | Where-Object { $_.File.Name -ne $jar.Name }
            continue
        }
        
        # Obfuscation Scan
        $obfFlags = Invoke-ObfuscationScan -FilePath $jar.FullName
        if ($obfFlags.Count -gt 0) {
            $obfuscatedMods[$jar.FullName] = [PSCustomObject]@{
                FileName = $jar.Name
                FilePath = $jar.FullName
                Flags = $obfFlags
                Type = "Obfuscated"
            }
            # Keep in verified? No, usually suspicious, let's move to risk tab.
            $verifiedMods = $verifiedMods | Where-Object { $_.File.Name -ne $jar.Name }
        }
    }
    
    # Populate Lists
    $lblStatus.Text = "Finalizing Results..."
    
    # 1. Suspicious
    foreach ($key in $suspiciousMods.Keys) {
        $mod = $suspiciousMods[$key]
        $item = New-Object System.Windows.Forms.ListViewItem($mod.FileName)
        $reason = "Suspicious Patterns/Strings"
        $item.SubItems.Add($reason) | Out-Null
        $item.SubItems.Add("{0:N2}" -f ((Get-Item $mod.FilePath).Length / 1MB)) | Out-Null
        $item.ForeColor = [System.Drawing.Color]::DarkRed
        $item.Tag = $mod
        $lvSuspicious.Items.Add($item) | Out-Null
    }
    
    # 2. Injection/Obfuscated
    $allRisk = @{} + $bypassMods + $obfuscatedMods
    foreach ($key in $allRisk.Keys) {
        $mod = $allRisk[$key]
        $item = New-Object System.Windows.Forms.ListViewItem($mod.FileName)
        $reason = "$($mod.Type): " + ($mod.Flags -join ", ")
        # Truncate reason for view
        if ($reason.Length -gt 60) { $reason = $reason.Substring(0, 60) + "..." }
        $item.SubItems.Add($reason) | Out-Null
        $item.SubItems.Add("{0:N2}" -f ((Get-Item $mod.FilePath).Length / 1MB)) | Out-Null
        if ($mod.Type -eq "Injection") { $item.ForeColor = [System.Drawing.Color]::DarkMagenta } else { $item.ForeColor = [System.Drawing.Color]::DarkGoldenrod }
        $item.Tag = $mod.Flags # Pass flags directly
        $lvInjection.Items.Add($item) | Out-Null
    }
    
    # 3. Verified
    foreach ($mod in $verifiedMods) {
        $item = New-Object System.Windows.Forms.ListViewItem($mod.File.Name)
        $item.SubItems.Add("Verified via $($mod.Source)") | Out-Null
        $item.SubItems.Add("{0:N2}" -f ($mod.File.Length / 1MB)) | Out-Null
        $item.ForeColor = [System.Drawing.Color]::DarkGreen
        $lvVerified.Items.Add($item) | Out-Null
    }
    
    # 4. Unknown
    foreach ($mod in $unknownMods) {
        # Check if it ended up in suspicious lists
        if ($suspiciousMods.ContainsKey($mod.File.FullName) -or $allRisk.ContainsKey($mod.File.FullName)) { continue }
        
        $item = New-Object System.Windows.Forms.ListViewItem($mod.File.Name)
        $item.SubItems.Add("Unverified Source: $($mod.Source)") | Out-Null
        $item.SubItems.Add("{0:N2}" -f ($mod.File.Length / 1MB)) | Out-Null
        $item.ForeColor = [System.Drawing.Color]::Gray
        $lvUnknown.Items.Add($item) | Out-Null
    }
    
    $lblStatus.Text = "Scan Complete. Found $($suspiciousMods.Count) suspicious, $($allRisk.Count) risky code."
    $progressBar.Value = 0
    $btnScan.Enabled = $true
    
    # Auto-switch to suspicious if any found
    if ($suspiciousMods.Count -gt 0) { $tabControl.SelectedTab = $tabControl.TabPages[0] }
})

# Run Application
 $mainForm.ShowDialog()
