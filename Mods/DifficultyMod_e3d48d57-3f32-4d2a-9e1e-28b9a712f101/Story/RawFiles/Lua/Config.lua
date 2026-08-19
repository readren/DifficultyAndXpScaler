--[[
    DifficultyMod - Config.lua
    User-configurable gameplay multipliers and debugging flags.
--]]

-- Table storing runtime configuration parameters for difficulty and experience scaling
local Config = {
    -- Multiplier applied to combat kill experience (type: number, e.g. 0.5 = 50% XP, 1.0 = 100% vanilla)
    CombatXPMultiplier = 0.5,

    -- Multiplier applied to enemy Max Vitality / Health (type: number, e.g. 1.5 = +50% Max HP)
    EnemyVitalityMultiplier = 1.5,

    -- Multiplier applied to enemy Physical Armour (type: number, e.g. 1.5 = +50% Physical Armour)
    EnemyPhysicalArmourMultiplier = 1.5,

    -- Multiplier applied to enemy Magic Armour (type: number, e.g. 1.5 = +50% Magic Armour)
    EnemyMagicArmourMultiplier = 1.5,

    -- Boolean flag enabling formatted debug print messages in the Script Extender console (type: boolean)
    DebugLogging = true
}

-- Return the configuration table to require callers
return Config
