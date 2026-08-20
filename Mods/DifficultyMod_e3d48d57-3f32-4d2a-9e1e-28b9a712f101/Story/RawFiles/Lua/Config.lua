--[[
    DifficultyMod - Config.lua
    User-configurable gameplay multipliers and debugging flags.
--]]

-- Table storing runtime configuration parameters for difficulty and experience scaling
local Config = {
    -- Multiplier applied to combat kill experience (type: number, e.g. 0.5 = 50% XP, 1.0 = 100% vanilla)
    CombatXPMultiplier = 0.5,

    -- Multiplier applied to enemy Character.txt template Vitality (type: number, e.g. 1.5 = +50% template stat)
    -- Note: In DOS2 Definitive Edition, the engine scales in-game Max HP non-linearly (HP ~ Vitality^1.40):
    --   * 1.00 = 100% (Vanilla Max HP)
    --   * 1.10 = ~114% Max HP
    --   * 1.34 = ~150% Max HP (use 1.34 if you want an exact +50% in-game Max HP)
    --   * 1.50 = ~175% Max HP (default: scales template parameters equally with Armour)
    --   * 1.64 = ~200% Max HP (use 1.64 if you want an exact +100% in-game Max HP)
    --   * 2.00 = ~267% Max HP
    EnemyVitalityMultiplier = 1.5,

    -- Multiplier applied to enemy Physical Armour (type: number, e.g. 1.5 = +50% Physical Armour)
    -- Armour scales linearly with template changes (1.5 = +50% in-game Physical Armour).
    EnemyPhysicalArmourMultiplier = 1.5,

    -- Multiplier applied to enemy Magic Armour (type: number, e.g. 1.5 = +50% Magic Armour)
    -- Armour scales linearly with template changes (1.5 = +50% in-game Magic Armour).
    EnemyMagicArmourMultiplier = 1.5,

    -- Boolean flag enabling formatted debug print messages in the Script Extender console (type: boolean)
    DebugLogging = true
}

-- Return the configuration table to require callers
return Config
