--[[
    DifficultyMod - Config.lua
    User-configurable gameplay multipliers and debugging flags.
--]]

-- Table storing runtime configuration parameters for difficulty and experience scaling
local Config = {
    -- Multiplier applied to combat kill experience (type: number, e.g. 0.5 = 50% XP, 1.0 = 100% vanilla)
    CombatXPMultiplier = 0.5,
    -- Multiplier applied to enemy characters templates' vitality (type: number, e.g. 1.5 = +50% template stat)
    -- Note: In DOS2 Definitive Edition, the engine scales in-game vitality non-linearly (vitality ~ templateVitality^1.404):
    -- * 0.50  ~ 38% Vitality ( -62% in-game vitality)
    -- * 0.61  ~ 50% Vitality ( -50% in-game vitality)
    -- * 1.00   100% Vitality (Vanilla, unmodified)  
    -- * 1.10  ~114% Vitality ( +14% in-game vitality) 
    -- * 1.335 ~150% Vitality ( +50% in-game vitality)
    -- * 1.50  ~175% Vitality ( +77% in-game vitality)
    -- * 1.638 ~200% Vitality (+100% in-game vitality)
    -- * 2.00  ~265% Vitality (+165% in-game vitality)
    -- * I recomend setting the three stats multipliers equally to be in synch with how the game scales them with level.
    EnemyVitalityMultiplier = 1.34,

    -- Multiplier applied to enemy Physical Armour (type: number, e.g. 1.5 = +50% Physical Armour)
    -- Armour scales linearly with template changes (1.5 -> +50% in-game Physical Armour).
    EnemyPhysicalArmourMultiplier = 1.34,

    -- Multiplier applied to enemy Magic Armour (type: number, e.g. 1.5 = +50% Magic Armour)
    -- Armour scales linearly with template changes (1.5 -> +50% in-game Magic Armour).
    EnemyMagicArmourMultiplier = 1.34,

    -- Boolean flag enabling formatted debug print messages in the Script Extender console (type: boolean)
    DebugLogging = true
}

-- Return the configuration table to require callers
return Config
