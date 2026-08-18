# DifficultyMod for Divinity: Original Sin 2 (Definitive Edition)

A lightweight, purely script-driven balance mod powered by **Norbyte's Script Extender**.

---

## Key Design Principles

1. **Zero Large Tables**: Does not overwrite or modify huge base game tables (e.g. `Character.txt`). All adjustments are performed dynamically in memory via Extender hooks (`StatsLoaded`).
2. **Safe for Mid-Campaign Saves**: Full plug-and-play support for existing savegames created without the mod activated.
3. **Clean Uninstallation**: Removing the mod immediately restores 100% vanilla behavior with zero residual data or missing status warnings.

---

## Features

* **Battle XP Scaling**: Dynamically adjusts combat XP gained from defeating enemies without affecting quest or exploration rewards.
* **Enemy Vitality (HP) Scaling**: Dynamically scales Max Vitality for all enemy and monster archetypes while preserving player characters and companions (`_Hero`).
* **Enemy Physical & Magic Armour Scaling**: Dynamically scales Physical Armour and Magic Armour for enemy archetypes.

---

## Configuration

Multipliers can be adjusted at any time in:
[`Mods/DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101/Story/RawFiles/Lua/Config.lua`](file:///c:/projects/games/divinity/difficulty-mod/Mods/DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101/Story/RawFiles/Lua/Config.lua)

```lua
local Config = {
    -- Combat XP multiplier (0.5 = 50% XP gained from kills)
    CombatXPMultiplier = 0.5,

    -- Enemy stat multipliers (1.5 = +50% increase)
    EnemyVitalityMultiplier = 1.5,
    EnemyPhysicalArmourMultiplier = 1.5,
    EnemyMagicArmourMultiplier = 1.5,

    -- Print adjustments to the Script Extender console
    DebugLogging = true
}

return Config
```

---

## Installation & Deployment

### 1. Requirements
* [Norbyte's Script Extender](https://github.com/Norbyte/ositools) installed in your `Divinity Original Sin 2/DefEd/bin` directory (or installed via Divinity Mod Manager).

### 2. Building & Deploying the `.pak`
Run the included build script in PowerShell:
```powershell
.\build_pak.ps1
```
This automatically compiles `DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101.pak` and deploys it to your active DOS2 Mods folder.

### 3. Validating the Project
Run the validator script to verify XML metadata, JSON configs, and Lua AST syntax:
```bash
python validate.py
```

### 4. Activating in Game
* Open **Divinity Mod Manager** (or the in-game Mods menu), activate **DifficultyMod**, and save/export the load order.
