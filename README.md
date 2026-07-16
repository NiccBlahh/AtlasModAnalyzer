# AtlasModAnalyzer

**Advanced forensic detection tool for Minecraft cheating clients, hidden mods, and obfuscated archives on Windows systems.**

AtlasModAnalyzer is a comprehensive PowerShell-based scanner that analyzes your Windows system for active Minecraft instances, locates installed mods, parses their contents for malicious cheat indicators using advanced pattern-matched signature analysis, and presents the findings in a compact, color-coded terminal display. Built for server administrators, screen sharers, esports integrity monitoring, and catching hidden ghost clients in competitive Minecraft environments.

Unlike simple file watchers or basic string searches, AtlasModAnalyzer performs deep content-level analysis — tearing open `.zip` and `.jar` archives, scanning for known cheat signatures (including highly specific client trackers), checking for hidden file attributes, and detecting Java obfuscation.

## Installation

**One-liner (run from CMD):**

```cmd
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NiccBlahh/AtlasModAnalyzer/refs/heads/main/AtlasModAnalyzer.ps1')"
```

---

## Table of Contents

- [Features](#features)
- [Scan Tags & Categories](#scan-tags--categories)
- [Usage](#usage)
- [Example Output](#example-output)
- [How It Works](#how-it-works)
- [Detection Methodology](#detection-methodology)
- [Technical Details](#technical-details)
- [Requirements](#requirements)
- [Notes](#notes)

---

## Features

- **Automated Environment Validation** — Instantly detects running Java processes (`javaw.exe`, `java.exe`) and queries WMI to locate the active `mods` directory based on launch arguments. 

- **Multi-Launcher Probing** — Automatically falls back to probing all known Minecraft installation path variants if a live process isn't found:
  - Modrinth (`%APPDATA%\ModrinthApp\profiles`)
  - CurseForge (`%USERPROFILE%\curseforge\minecraft\Instances`)
  - Feather Client (`%APPDATA%\.feather\user-mods`)
  - Lunar Client (`%USERPROFILE%\.lunarclient\offline`)
  - Badlion / NoRisk / Vanilla (`%APPDATA%\.minecraft\mods`)

- **Deep Signature Scanning** — Opens each `.jar` or `.zip` file and scans the raw bytecode and internal file structures against a massive, base64-encoded database of over 1,000 known cheat signatures, memory dumps, and malicious API calls.

- **Client-Specific Hijacking** — Contains dedicated detection modules for highly evasive ghost clients (such as **Dqrkis**). If specific core signatures are triggered, the scanner overrides standard detection and explicitly brands the mod.

- **Obfuscation Detection** — Uses structural analysis to detect if a `.jar` has been intentionally scrambled using known Java obfuscators to hide malicious payloads.

- **Hidden File Catching** — Actively hunts down files using the Windows `+h` (Hidden) attribute designed to bypass standard visual folder checks during a screen share.

- **Compact Terminal Output** — Color-coded display with ASCII art banner, structured output loops, and explicit spacing for readability without terminal bloat.

---

## Scan Tags & Categories

| Tag | Color | Meaning |
|-------|-------------------|---------------|
| **SAFE** | 🟢 Green | Verified, clean modifications recognized by the Modrinth/Megabase hash database. |
| **UNKNOWN** | 🟡 Yellow | Unrecognized files that did not trigger any malicious signatures but aren't explicitly verified. |
| **DETECTED** | 🟣 Magenta | The scanner found malicious strings, cheat patterns, or suspicious API calls inside the bytecode. |
| **DQRKIS** | 🔴 Red | Positively identified core signatures belonging specifically to the Dqrkis cheat client. |
| **HIDDEN** | 🔵 Cyan | The file has the Windows `+h` attribute applied to it, indicating an attempt to hide the file. |
| **OBFUSCATED** | 🟠 Orange | The code is heavily scrambled, which is highly suspicious for standard Forge/Fabric mods. |

---

## Usage

**Run locally from a downloaded file:**

1. Download `AtlasModAnalyzer.ps1` to any directory
2. Open a Command Prompt (`cmd.exe`) or PowerShell
3. Run:

```cmd
powershell -ExecutionPolicy Bypass -File "AtlasModAnalyzer.ps1"
```

No administrator privileges required. 

> **⚠️ Note:** AtlasModAnalyzer performs raw string and byte pattern matching. While highly accurate, always review the flagged patterns under the `DETECTED` tag to ensure a legitimate mod wasn't caught in the crossfire.

---

## Example Output

```
  Made by Nicc and Tryserver , hit up imnicc.dll for any errors

  Phase 1
  Environment Validation

  ●  javaw
  PID 23032
     Started   07/16/2026 23:17:28
     Uptime    0h 4m 19s

  Auto-Detected: C:\Users\Nic\AppData\Roaming\ModrinthApp\profiles\Yea Buddy\mods
  [1] Press Enter to scan detected path
  [2] Type or Paste a custom path
  Select option (1 or 2): 1
  
  Scanning [fabric-api-1.21.jar]... 100% (45/45)

  JVM Scanner
  JVM clean

  SAFE  fabric-api-1.21.jar
  SAFE  sodium-fabric-0.8.12+mc1.21.11.jar
  
  UNKNOWN  potionchime-1.0.0+1.21.11.jar

  DETECTED Flagged Modules:

  DQRKIS  fabric-language-kotlin-1.13.12+kotlin.2.4.0.jar
      Strings
        openConnection

  HIDDEN  ghostclient_hidden.jar
      Patterns
        HIDDEN FILE ATTRIBUTE (+H)

  === SCAN COMPLETE ===
  Total: 45 | Verified: 42 | Unknown: 1 | Suspicious: 2 | Obfuscated: 0 | JVM issues: 0
```

---

## How It Works

ModAnalyzer operates in 5 sequential phases:

### Phase 1: Environment Validation
Queries the Windows process list for active `java` or `javaw` instances. If found, it uses WMI (`Win32_Process`) to read the command-line launch arguments, extracting the exact `--gameDir` path to guarantee it scans the folder currently injected into memory.

### Phase 2: Hash Verification
Computes SHA hashes of the target archives and checks them against a local dictionary of verified Modrinth and Megabase signatures. Matches are immediately tagged as `SAFE`.

### Phase 3: Deep Scan
All unverified archives are unpacked in memory. The scanner rips through the internal files, running them against a massive, embedded database of malicious patterns, ESP strings, aura logic, and known cheat endpoints. 

### Phase 4: Obfuscation Check
Performs structural analysis on the bytecode to look for missing metadata, scrambled variable names, and common Java obfuscator signatures. 

### Phase 5: Reporting
Outputs the highly dense, color-coded forensic report, automatically parsing out false positives and highlighting critical findings (like `HIDDEN` attributes or `DQRKIS` payloads).

---

## Detection Methodology

ModAnalyzer uses a multi-layered approach to minimize false positives while maintaining high detection sensitivity:

| Layer | Method | False Positive Risk |
|-------|--------|---------------------|
| Verification | Pre-filters known safe mods via Hash DB | Very Low |
| Attribute Check | Specifically checks for Windows `+h` tags | Very Low |
| Database Filtering | Aggressively purges common Java strings | Low |
| Signature Match | Searches file text for cheat module names | Medium |
| Client Specific | Overrides generic tags for exact payload matches | Very Low |

---

## Technical Details

- **Language:** PowerShell 5.1 (Windows native, no additional runtimes required)
- **Signature DB:** Over 1,000 strings embedded natively via UTF-8 Base64 encoding.
- **Archive Extraction:** Uses native .NET `System.IO.Compression.ZipArchive` for speed.
- **Process:** `Get-WmiObject Win32_Process` for runtime argument extraction.
- **Encoding:** UTF8 with BOM for proper console rendering.
- **Script Size:** ~620 lines

---

## Requirements

- **Operating System:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 (included with Windows)
- **Permissions:** Standard user privileges (Administrator not required).
- **Dependencies:** None. All APIs used are part of the .NET Framework 4.x.

---

## Notes
- To prevent false positives, short common strings (like `delay`, `and`, `java`) have been permanently purged from the signature database.
- If you encounter a false flag, report it to `@imnicc.dll` on Discord to have the string blacklisted in the next build.
