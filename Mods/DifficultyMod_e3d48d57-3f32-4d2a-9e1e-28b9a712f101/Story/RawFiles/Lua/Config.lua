--[[
    DifficultyMod - Configuration
    Adjust the multipliers below as desired.
--]]

local Config = {
    -- Multiplier for combat XP gained from defeating enemies (0.5 = 50% XP)
    CombatXPMultiplier = 0.5,

    -- Multiplier for enemy Vitality / Max HP (1.5 = +50% HP)
    EnemyVitalityMultiplier = 1.5,

    -- Multiplier for enemy Physical Armour (1.5 = +50% Physical Armour)
    EnemyPhysicalArmourMultiplier = 1.5,

    -- Multiplier for enemy Magic Armour (1.5 = +50% Magic Armour)
    EnemyMagicArmourMultiplier = 1.5,

    -- Print adjustments to the Script Extender console
    DebugLogging = true
}

return Config
