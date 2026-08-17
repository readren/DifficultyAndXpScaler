# DifficultyMod for Divinity: Original Sin 2 (Definitive Edition)

A lightweight balance mod powered by **Norbyte's Script Extender**.

## Features
1. **Battle XP Reduction**: Dynamically scales the combat XP gained from defeating enemies without affecting quest or exploration XP.
2. **Enemy Vitality (HP) Scaling**: Multiplies Max HP only for hostile/enemy combatants (leaves player party, companions, and player summons untouched).
3. **Enemy Physical & Magic Armour Scaling**: Multiplies Physical and Magic Armour only for enemies.

---

## Configuration

You can easily adjust the multipliers at any time by editing:
`Mods/DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101/Story/RawFiles/Lua/Config.lua`

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
```

---

## Installation & How to Play

### 1. Requirements
* Make sure you have **Norbyte's Script Extender** installed (e.g. via [Divinity Mod Manager](https://github.com/LaughingLeader-DOS2-Mods/DivinityModManager) or by dropping `DXGI.dll` into your `Divinity Original Sin 2/DefEd/bin` directory).

### 2. Installing the Mod
You can copy or create a directory symbolic link for the `Mods/DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101` folder to:

`%USERPROFILE%\Documents\Larian Studios\Divinity Original Sin 2 Definitive Edition\Mods\`
C:\Program Files (x86)\Steam\steamapps\common\Divinity Original Sin 2

#### Quick PowerShell Symlink Command:
Run this in PowerShell to link the folder directly so any edits here take effect instantly (works automatically with or without OneDrive backup enabled):
```powershell
New-Item -ItemType SymbolicLink -Path "C:\Program Files (x86)\Steam\steamapps\common\Divinity Original Sin 2\DefEd\Data\Mods\DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101" -Target "C:\projects\games\divinity\difficulty-mod\Mods\DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101"
```
#### Quick PowerShell Symlink Command:
Run this in PowerShell to link the folder directly so any edits here take effect instantly (works automatically with or without OneDrive backup enabled):
```powershell
$docs = [Environment]::GetFolderPath('MyDocuments')
New-Item -ItemType SymbolicLink -Path "$docs\Larian Studios\Divinity Original Sin 2 Definitive Edition\Mods\DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101" -Target "C:\projects\games\divinity\difficulty-mod\Mods\DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101"
```

### 3. Activating in Game
* Open **Divinity Mod Manager** (or the in-game Mods menu), activate **DifficultyMod**, and export/save load order.
