# 🛡️ Atlas ModAnalyzer
> A tool that scans your Minecraft mods for suspicious patterns, cheat clients, unknown files, and JVM argument abuse.

---

## What does it do?

Atlas ModAnalyzer looks at every `.jar` file in your active Minecraft instance and assigns one of three labels:

| Label | Meaning |
|-------|---------|
| ✅ VERIFIED | Found in an official database = safe |
| ❓ UNKNOWN | Not found but no suspicious patterns detected |
| 🚨 SUSPICIOUS | Contains strings or signatures linked to cheat clients |

It also inspects your active **JVM arguments** for injected agents, unsafe flags, and runtime manipulation techniques.

---

## How to run?

> Coming soon — download from the [Releases](https://github.com/yourusername/atlas-modanalyzer/releases) page.

Start Minecraft **first**, then run Atlas ModAnalyzer. It automatically detects which instance you have open via the Java process command line (`--gameDir`). Just press **Enter** to confirm, or type a custom path instead.

---

## How does the scan work?

### Step 1 — SHA-1 verification

A SHA-1 hash is calculated for every `.jar`. That hash is checked against:

- **Modrinth** `api.modrinth.com/v2/version_file/{hash}` — largest database of legitimate mods
- **Megabase** `megabase.vercel.app/api/query?hash={hash}` — fallback database if Modrinth finds nothing

If the hash matches, the mod is marked **VERIFIED** and the scan stops there.

### Step 2 — Content analysis

If a mod isn't recognized, the JAR is opened as a zip and the following are checked:

- File names and paths inside the JAR
- Text inside `.json`, `.toml`, `.cfg`, `.properties` and `MANIFEST.MF`
- Bytecode of `.class` files (ASCII strings)
- Hidden URLs inside configs
- Suspicious reflection / runtime exec calls
- Obfuscation techniques (short paths like `a/b/c/`, single-char class names, Japanese/Chinese characters)

### Step 3 — JVM argument audit

Atlas reads your active JVM arguments and flags:

- `-javaagent:` entries pointing to unrecognized agents
- `-Xbootclasspath` overrides
- Unsafe reflection flags (`--add-opens`, `--add-exports` to unknown modules)
- Arguments commonly used by cheat injection loaders

### Step 4 — Download source

Windows automatically stores where you downloaded a file from (Zone.Identifier stream). The tool reads this and flags downloads from risky sources.

**Safe:** CurseForge, Modrinth  
**Risky:** Discord CDN, MediaFire, and known cheat client distribution sites

---

## What gets detected?

Over 100 patterns across multiple categories:

- **Combat cheats** — KillAura, AimAssist, AutoCrystal, Reach, TriggerBot, Velocity, ...
- **Movement cheats** — Flight, NoFall, Phase, Scaffold, Timer, Bhop, ...
- **PvP automation** — AutoTotem, AutoPot, AutoArmor, FakeLag, Blink, PopSwitch, ...
- **Visual cheats** — ESP, XRay, Wallhack, Freecam, FullBright, Tracers, ...
- **Known clients** — Wurst, Meteor, LiquidBounce, Sigma, Flux, Vape, Aristois, ...
- **Malware strings** — TokenGrabber, Backdoor, Stealer, webhook URLs, HWID checks
- **Obfuscation libs** — Allatori, ZKM, Stringer, jnativehook, imgui, chainlibs, ...
- **Suspicious mixins** — KeyboardMixin, LicenseCheckMixin, ClientPlayerInteractionManagerMixin
- **JVM abuse** — injected agents, bootclasspath overrides, loader flags

Including fullwidth unicode variants of all the above (Ａｕｔｏ Ｃｒｙｓｔａｌ, etc.)

---

## Requirements

- Windows
- Java 17 or higher
- Internet connection (for database lookups)

---

## Contact

Discord: `yourname`  
GitHub: [yourusername](https://github.com/yourusername)
