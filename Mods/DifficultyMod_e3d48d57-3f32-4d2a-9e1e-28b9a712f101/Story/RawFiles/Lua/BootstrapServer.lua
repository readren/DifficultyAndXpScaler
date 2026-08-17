--[[
    DifficultyMod - BootstrapServer
    Handles dynamic enemy Vitality, Physical Armour, Magic Armour scaling,
    and scales combat XP reward.
--]]

local Config = Ext.Require("Config.lua")

Ext.Print("[DifficultyMod] Initializing server-side logic...")

-- Helper: Determine if a character belongs to the player's party or is a player-owned summon
local function IsPlayerOrAlly(char)
    if not char then return false end

    -- Check direct player / party flags
    if char.IsPlayer or char.IsPartyMember then
        return true
    end

    -- Check GUID with Osiris if available
    if char.MyGuid and Osi and Osi.CharacterIsPartyMember and Osi.CharacterIsPartyMember(char.MyGuid) == 1 then
        return true
    end

    -- Check if character is a summon owned by a player or party member
    if char.OwnerHandle then
        local owner = Ext.Entity.GetCharacter(char.OwnerHandle)
        if owner and (owner.IsPlayer or owner.IsPartyMember) then
            return true
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- 1. Apply Combat Experience Scaling
--------------------------------------------------------------------------------
local function ApplyExperienceScaling()
    if Ext.ExtraData then
        local baseCombatXP = Ext.ExtraData.CombatExperienceModifier or 1.0
        Ext.ExtraData.CombatExperienceModifier = baseCombatXP * Config.CombatXPMultiplier
        if Config.DebugLogging then
            Ext.Print(string.format("[DifficultyMod] CombatExperienceModifier set to: %.2f (Multiplier: %.2f)", 
                Ext.ExtraData.CombatExperienceModifier, Config.CombatXPMultiplier))
        end
    end
end

Ext.Events.SessionLoaded:Subscribe(function()
    ApplyExperienceScaling()
    if Config.DebugLogging then
        Ext.Print(string.format("[DifficultyMod] Session loaded. Multipliers -> Vitality: %.2fx, PhysArmour: %.2fx, MagicArmour: %.2fx, CombatXP: %.2fx",
            Config.EnemyVitalityMultiplier,
            Config.EnemyPhysicalArmourMultiplier,
            Config.EnemyMagicArmourMultiplier,
            Config.CombatXPMultiplier))
    end
end)

--------------------------------------------------------------------------------
-- 2. Hook Character Stat Calculations (Vitality, Phys Armour, Magic Armour)
--------------------------------------------------------------------------------

-- Hook via Ext.Events.ComputeCharacterStat (Extender v56+)
if Ext.Events and Ext.Events.ComputeCharacterStat then
    Ext.Events.ComputeCharacterStat:Hook(function(e)
        local char = e.Character
        if not char or IsPlayerOrAlly(char) then
            return
        end

        local stat = e.Stat
        if stat == "Vitality" or stat == "MaxVitality" then
            e.Value = math.floor(e.Value * Config.EnemyVitalityMultiplier)
        elseif stat == "PhysicalArmor" or stat == "MaxArmor" or stat == "Armor" then
            e.Value = math.floor(e.Value * Config.EnemyPhysicalArmourMultiplier)
        elseif stat == "MagicArmor" or stat == "MaxMagicArmor" then
            e.Value = math.floor(e.Value * Config.EnemyMagicArmourMultiplier)
        end
    end)
end

-- Fallback / Direct hook via Ext.Stats.Math
elseif Ext.Stats and Ext.Stats.Math then
    local oldCalcVit = Ext.Stats.Math.CalculateVitality
    if oldCalcVit then
        Ext.Stats.Math.CalculateVitality = function(character, ...)
            local base = oldCalcVit(character, ...)
            if not IsPlayerOrAlly(character) then
                return math.floor(base * Config.EnemyVitalityMultiplier)
            end
            return base
        end
    end

    local oldCalcArmor = Ext.Stats.Math.CalculateArmor
    if oldCalcArmor then
        Ext.Stats.Math.CalculateArmor = function(character, ...)
            local base = oldCalcArmor(character, ...)
            if not IsPlayerOrAlly(character) then
                return math.floor(base * Config.EnemyPhysicalArmourMultiplier)
            end
            return base
        end
    end

    local oldCalcMagicArmor = Ext.Stats.Math.CalculateMagicArmor
    if oldCalcMagicArmor then
        Ext.Stats.Math.CalculateMagicArmor = function(character, ...)
            local base = oldCalcMagicArmor(character, ...)
            if not IsPlayerOrAlly(character) then
                return math.floor(base * Config.EnemyMagicArmourMultiplier)
            end
            return base
        end
    end
end

Ext.Print("[DifficultyMod] Server logic loaded successfully.")
