--[[
    DifficultyMod - DifficultyScaler
    Applies in-memory difficulty scaling to character stats (Vitality, Armour, Magic Armour)
    and dynamic combat experience scaling without modifying static disk tables or mutating savegame states.
--]]

local Config
if Ext and Ext.Require then
    local ok, res = pcall(Ext.Require, "Config.lua")
    if ok and res then Config = res end
end
if not Config and require then
    local ok, res = pcall(require, "Config")
    if ok and res then Config = res end
end
if not Config then
    Config = {
        CombatXPMultiplier = 0.5,
        EnemyVitalityMultiplier = 1.5,
        EnemyPhysicalArmourMultiplier = 1.5,
        EnemyMagicArmourMultiplier = 1.5,
        DebugLogging = true
    }
end

local function PrintLog(msg)
    if not Config or not Config.DebugLogging then return end
    local formatted = string.format("[DifficultyMod] %s", msg)
    if Ext and Ext.Utils and Ext.Utils.Print then
        Ext.Utils.Print(formatted)
    elseif Ext and Ext.Print then
        Ext.Print(formatted)
    else
        print(formatted)
    end
end

--------------------------------------------------------------------------------
-- 1. Experience Requirements Table per Level (DOS2 Definitive Edition)
--------------------------------------------------------------------------------
local LevelExpTable = {
    [1]  = 2000,
    [2]  = 6000,
    [3]  = 12000,
    [4]  = 20000,
    [5]  = 30000,
    [6]  = 42000,
    [7]  = 56000,
    [8]  = 72000,
    [9]  = 100000,
    [10] = 139000,
    [11] = 189000,
    [12] = 252000,
    [13] = 330000,
    [14] = 425000,
    [15] = 539000,
    [16] = 674000,
    [17] = 833000,
    [18] = 1018000,
    [19] = 1232000,
    [20] = 1478000,
    [21] = 1759000,
    [22] = 2078000,
    [23] = 2439000,
    [24] = 2845000,
    [25] = 3300000
}

--------------------------------------------------------------------------------
-- 2. Helper: Identify Player & Hero Templates (to leave them untouched)
--------------------------------------------------------------------------------
local function IsPlayerOrHeroStat(name)
    if not name then return true end
    local lower = name:lower()

    if name == "_Hero" then
        return true
    end

    if string.find(lower, "hero") or string.find(lower, "player") or string.find(lower, "companion") or string.find(lower, "avatar") then
        return true
    end

    return false
end

--------------------------------------------------------------------------------
-- 3. Core: In-Memory Character Stat & XP Template Scaling (Inheritance-Aware)
--------------------------------------------------------------------------------
local function ApplyDifficultyScaling()
    local getStatEntriesFn = (Ext and Ext.Stats and Ext.Stats.GetStats) or (Ext and Ext.Stats and Ext.Stats.GetStatEntries) or (Ext and Ext.GetStatEntries)
    local getStatFn = (Ext and Ext.Stats and Ext.Stats.Get) or (Ext and Ext.GetStat)

    if getStatEntriesFn and getStatFn then
        local charEntries = getStatEntriesFn("Character")
        local modifiedCount = 0
        local shouldOverrideXP = (Config.CombatXPMultiplier ~= nil and Config.CombatXPMultiplier < 1.0)

        -- 1. Scale base template _Base (150 -> 225)
        local baseEntry = getStatFn("_Base")
        if baseEntry and baseEntry.Vitality and baseEntry.Vitality > 0 then
            baseEntry.Vitality = math.floor(baseEntry.Vitality * Config.EnemyVitalityMultiplier)
        end

        -- 2. Ensure player/hero template _Hero remains at exact vanilla base (100)
        local heroEntry = getStatFn("_Hero")
        if heroEntry then
            heroEntry.Vitality = 100
        end

        -- 3. Process all non-hero character entries
        for _, name in pairs(charEntries) do
            if name ~= "_Base" and not IsPlayerOrHeroStat(name) then
                local stat = getStatFn(name)
                if stat then
                    local parent = nil
                    if stat.Using and stat.Using ~= "" and stat.Using ~= name then
                        parent = getStatFn(stat.Using)
                    end

                    local modified = false

                    -- Vitality: Scale only explicit overrides that differ from parent
                    local parentVit = parent and parent.Vitality or nil
                    local baseVit = stat.Vitality
                    if baseVit and baseVit > 0 then
                        if parentVit and baseVit ~= parentVit then
                            stat.Vitality = math.floor(baseVit * Config.EnemyVitalityMultiplier)
                            modified = true
                        end
                    end

                    -- Physical Armour: Scale only explicit overrides
                    local parentArm = parent and parent.Armor or nil
                    local baseArm = stat.Armor
                    if baseArm and baseArm > 0 then
                        if not parentArm or baseArm ~= parentArm then
                            stat.Armor = math.floor(baseArm * Config.EnemyPhysicalArmourMultiplier)
                            modified = true
                        end
                    end

                    -- Magic Armour: Scale only explicit overrides
                    local parentMagicArm = parent and parent.MagicArmor or nil
                    local baseMagicArm = stat.MagicArmor
                    if baseMagicArm and baseMagicArm > 0 then
                        if not parentMagicArm or baseMagicArm ~= parentMagicArm then
                            stat.MagicArmor = math.floor(baseMagicArm * Config.EnemyMagicArmourMultiplier)
                            modified = true
                        end
                    end

                    -- Suppress engine kill XP if custom XP is active
                    if shouldOverrideXP then
                        stat.Gain = 0
                        modified = true
                    end

                    if modified then
                        modifiedCount = modifiedCount + 1
                    end
                end
            end
        end

        PrintLog(string.format("In-memory scaling applied to %d enemy templates (Vitality: x%.2f, PhysArmour: x%.2f, MagicArmour: x%.2f, CombatXP: x%.2f).",
            modifiedCount, Config.EnemyVitalityMultiplier, Config.EnemyPhysicalArmourMultiplier, Config.EnemyMagicArmourMultiplier, Config.CombatXPMultiplier or 1.0))
    else
        PrintLog("Warning: Ext.Stats API not accessible.")
    end
end

--------------------------------------------------------------------------------
-- 4. Server-Side: Proportional Current Health & Armour Scaling on Save Load
--------------------------------------------------------------------------------
local function ScaleCharacterCurrentStats(guidOrChar)
    local guid = nil
    local char = nil

    if type(guidOrChar) == "string" then
        guid = guidOrChar
        char = (Ext.Entity and Ext.Entity.GetCharacter and Ext.Entity.GetCharacter(guid)) or (Ext.GetCharacter and Ext.GetCharacter(guid))
    else
        char = guidOrChar
        if char and char.MyGuid then guid = char.MyGuid end
    end

    if not char or not char.Stats then return end

    -- Exclude dead characters
    if char.Dead or (char.Stats.CurrentVitality and char.Stats.CurrentVitality <= 0) then
        return
    end

    -- Exclude player and party characters
    if char.PlayerCustomData ~= nil then return end
    if char.Stats.Name and IsPlayerOrHeroStat(char.Stats.Name) then return end
    if Osi and guid then
        if Osi.CharacterIsPlayer(guid) == 1 or Osi.CharacterIsPartyMember(guid) == 1 then
            return
        end
    end

    local stats = char.Stats
    local maxVit = stats.MaxVitality or 0
    local curVit = stats.CurrentVitality or 0
    local maxArm = stats.MaxArmor or 0
    local curArm = stats.CurrentArmor or 0
    local maxMagicArm = stats.MaxMagicArmor or 0
    local curMagicArm = stats.CurrentMagicArmor or 0

    -- Scale Current Vitality proportionally up to MaxVitality
    if maxVit > 0 and curVit > 0 and curVit < maxVit then
        local scaledVit = math.min(maxVit, math.floor(curVit * Config.EnemyVitalityMultiplier))
        stats.CurrentVitality = scaledVit
        if Osi and guid and scaledVit >= maxVit and Osi.Proc_CharacterFullRestore then
            pcall(Osi.Proc_CharacterFullRestore, guid)
        end
    end

    -- Scale Current Physical Armour proportionally up to MaxArmor
    if maxArm > 0 and curArm > 0 and curArm < maxArm then
        local scaledArm = math.min(maxArm, math.floor(curArm * Config.EnemyPhysicalArmourMultiplier))
        stats.CurrentArmor = scaledArm
    end

    -- Scale Current Magic Armour proportionally up to MaxMagicArmor
    if maxMagicArm > 0 and curMagicArm > 0 and curMagicArm < maxMagicArm then
        local scaledMagicArm = math.min(maxMagicArm, math.floor(curMagicArm * Config.EnemyMagicArmourMultiplier))
        stats.CurrentMagicArmor = scaledMagicArm
    end
end

local function ScaleAllLoadedMapEnemies()
    local getGuidsFn = (Ext.Entity and Ext.Entity.GetAllCharacterGuids)
    if getGuidsFn then
        local ok, guids = pcall(getGuidsFn)
        if ok and guids then
            local count = 0
            for _, g in ipairs(guids) do
                local ok2 = pcall(ScaleCharacterCurrentStats, g)
                if ok2 then count = count + 1 end
            end
            PrintLog(string.format("Synchronized stats for %d characters on map.", count))
        end
    end
end

--------------------------------------------------------------------------------
-- 5. Server-Side: Event Handlers & Osiris Registrations
--------------------------------------------------------------------------------
local function RegisterServerEvents()
    local registerOsiris = (Ext and Ext.Osiris and Ext.Osiris.RegisterListener) or (Ext and Ext.RegisterOsirisListener)

    if registerOsiris and Osi then
        -- 1. Combat experience scaling on death
        registerOsiris("CharacterDied", 1, "after", function(charGuid)
            if not Config or not Config.CombatXPMultiplier or Config.CombatXPMultiplier <= 0 then
                return
            end
            if not charGuid or not Osi then return end

            if Osi.CharacterIsPlayer(charGuid) == 1 or Osi.CharacterIsPartyMember(charGuid) == 1 then
                return
            end

            if Osi.CharacterIsSummon(charGuid) == 1 then
                local master = Osi.CharacterGetOwnerCharacter(charGuid)
                if master and (Osi.CharacterIsPlayer(master) == 1 or Osi.CharacterIsPartyMember(master) == 1) then
                    return
                end
            end

            local level = Osi.CharacterGetLevel(charGuid) or 1
            if level < 1 then level = 1 end

            local expRequired = LevelExpTable[level] or (level * level * 2000)
            if Osi.DB_LevelExp then
                local ok, rows = pcall(Osi.DB_LevelExp.Get, Osi.DB_LevelExp, level, nil)
                if ok and rows and rows[1] and rows[1][2] then
                    expRequired = rows[1][2]
                end
            end

            local baseKillXP = expRequired / 20.0
            local scaledXP = math.max(1, math.floor(baseKillXP * Config.CombatXPMultiplier))

            Osi.PartyAddExperience(scaledXP)

            PrintLog(string.format("Awarded %d Combat XP (Level %d, Base: %d, Multiplier: %.2f) for defeating %s",
                scaledXP, level, math.floor(baseKillXP), Config.CombatXPMultiplier, tostring(charGuid)))
        end)

        -- 2. Savegame & Region startup hook
        registerOsiris("RegionStarted", 1, "after", function(region)
            ScaleAllLoadedMapEnemies()
        end)

        -- 3. Combat entry hook (for newly spawned/ambush enemies)
        registerOsiris("CharacterEnteredCombat", 2, "after", function(charGuid, combatId)
            pcall(ScaleCharacterCurrentStats, charGuid)
        end)

        PrintLog("Server events registered.")
    end
end

--------------------------------------------------------------------------------
-- 6. Register Engine Event Listeners
--------------------------------------------------------------------------------
-- StatsLoaded subscription (in-memory template scaling)
if Ext and Ext.Events and Ext.Events.StatsLoaded then
    Ext.Events.StatsLoaded:Subscribe(ApplyDifficultyScaling)
elseif Ext and Ext.RegisterListener then
    Ext.RegisterListener("StatsLoaded", ApplyDifficultyScaling)
end

-- Server Osiris event registration
RegisterServerEvents()

return {
    ApplyDifficultyScaling = ApplyDifficultyScaling,
    Config = Config
}
