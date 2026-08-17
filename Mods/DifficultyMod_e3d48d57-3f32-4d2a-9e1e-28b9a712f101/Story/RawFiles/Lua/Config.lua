--[[
    DifficultyMod - Configuration
    Adjust the multipliers below to change game balance.
--]]

local Config = {
    -- Combat Experience Multiplier
    -- 0.5 = 50% XP gained from enemy kills (reduces battle XP by half)
    -- 1.0 = Default vanilla XP
    CombatXPMultiplier = 0.5,

    -- Enemy Stat Multipliers (Applied only to non-party / hostile entities)
    -- 1.5 = +50% increase
    -- 2.0 = +100% (doubled)
    EnemyVitalityMultiplier = 1.5,       -- Enemy Max HP multiplier
    EnemyPhysicalArmourMultiplier = 1.5,  -- Enemy Physical Armour multiplier
    EnemyMagicArmourMultiplier = 1.5,    -- Enemy Magic Armour multiplier

    -- Debug mode (prints info to the Script Extender console / logs)
    DebugLogging = true
}

return Config
