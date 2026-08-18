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
    if Ext and Ext.Utils and Ext.Utils.Print then
        Ext.Utils.Print(msg)
    elseif Ext and Ext.Print then
        Ext.Print(msg)
    else
        print(msg)
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
    PrintLog("[DifficultyMod] Applying in-memory difficulty scaling to Character stats...")

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

        PrintLog(string.format("[DifficultyMod] In-memory scaling applied to %d enemy templates (Vitality: x%.2f, PhysArmour: x%.2f, MagicArmour: x%.2f, CombatXP: x%.2f).",
            modifiedCount, Config.EnemyVitalityMultiplier, Config.EnemyPhysicalArmourMultiplier, Config.EnemyMagicArmourMultiplier, Config.CombatXPMultiplier or 1.0))
    else
        PrintLog("[DifficultyMod] Warning: Ext.Stats API not accessible.")
    end
end

--------------------------------------------------------------------------------
-- 4. Server-Side: Proportional Current Health & Armour Scaling on Save Load
--------------------------------------------------------------------------------
local function ScaleCharacterCurrentStats(guidOrChar)
    local char
    if type(guidOrChar) == "string" then
        if not Osi then return end
        if Osi.CharacterIsPlayer(guidOrChar) == 1 or Osi.CharacterIsPartyMember(guidOrChar) == 1 then
            return
        end
        if Osi.CharacterIsSummon(guidOrChar) == 1 then
            local master = Osi.CharacterGetOwnerCharacter(guidOrChar)
            if master and (Osi.CharacterIsPlayer(master) == 1 or Osi.CharacterIsPartyMember(master) == 1) then
                return
            end
        end
        char = (Ext.Entity and Ext.Entity.GetCharacter and Ext.Entity.GetCharacter(guidOrChar)) or (Ext.GetCharacter and Ext.GetCharacter(guidOrChar))
    else
        char = guidOrChar
    end

    if char and char.Stats and not char.Stats.IsDead then
        if char.IsPlayer or char.IsPartyMember then return end
        if char.OwnerHandle then
            local owner = (Ext.Entity and Ext.Entity.GetCharacter and Ext.Entity.GetCharacter(char.OwnerHandle)) or (Ext.GetCharacter and Ext.GetCharacter(char.OwnerHandle))
            if owner and (owner.IsPlayer or owner.IsPartyMember) then return end
        end

        local stats = char.Stats
        -- Scale Current Vitality to match the +50% expanded maximum
        if stats.CurrentVitality and stats.CurrentVitality > 0 and stats.MaxVitality and stats.MaxVitality > 0 then
            local scaledVit = math.floor(stats.CurrentVitality * Config.EnemyVitalityMultiplier)
            stats.CurrentVitality = math.min(stats.MaxVitality, scaledVit)
        end

        -- Scale Current Physical Armour to match the +50% expanded maximum
        if stats.CurrentArmor and stats.CurrentArmor > 0 and stats.MaxArmor and stats.MaxArmor > 0 then
            local scaledArmor = math.floor(stats.CurrentArmor * Config.EnemyPhysicalArmourMultiplier)
            stats.CurrentArmor = math.min(stats.MaxArmor, scaledArmor)
        end

        -- Scale Current Magic Armour to match the +50% expanded maximum
        if stats.CurrentMagicArmor and stats.CurrentMagicArmor > 0 and stats.MaxMagicArmor and stats.MaxMagicArmor > 0 then
            local scaledMagicArmor = math.floor(stats.CurrentMagicArmor * Config.EnemyMagicArmourMultiplier)
            stats.CurrentMagicArmor = math.min(stats.MaxMagicArmor, scaledMagicArmor)
        end
    end
end

local function ScaleAllLoadedMapEnemies()
    local getAllFn = (Ext.Entity and Ext.Entity.GetAllCharacters) or Ext.GetAllCharacters
    if not getAllFn then return end

    local allChars = getAllFn()
    if not allChars then return end

    local count = 0
    for _, char in ipairs(allChars) do
        if char and char.Stats and not char.Stats.IsDead then
            local isParty = (char.IsPlayer or char.IsPartyMember)
            if not isParty and char.MyGuid and Osi then
                isParty = (Osi.CharacterIsPlayer(char.MyGuid) == 1 or Osi.CharacterIsPartyMember(char.MyGuid) == 1)
            end

            if not isParty then
                ScaleCharacterCurrentStats(char)
                count = count + 1
            end
        end
    end

    if count > 0 then
        PrintLog(string.format("[DifficultyMod] Proportionally scaled current health & armour for %d NPCs on map.", count))
    end
end

--------------------------------------------------------------------------------
-- 5. Server-Side: Dynamic Combat Experience Award on Enemy Death
--------------------------------------------------------------------------------
local function RegisterCombatListeners()
    local registerOsiris = (Ext and Ext.Osiris and Ext.Osiris.RegisterListener) or (Ext and Ext.RegisterOsirisListener)

    if registerOsiris and Osi then
        -- Combat experience scaling
        registerOsiris("CharacterDied", 1, "after", function(charGuid)
            if not Config or not Config.CombatXPMultiplier or Config.CombatXPMultiplier <= 0 then
                return
            end
            if not charGuid or not Osi then return end

            -- Exclude player characters and party members
            if Osi.CharacterIsPlayer(charGuid) == 1 or Osi.CharacterIsPartyMember(charGuid) == 1 then
                return
            end

            -- Exclude player/companion summons
            if Osi.CharacterIsSummon(charGuid) == 1 then
                local master = Osi.CharacterGetOwnerCharacter(charGuid)
                if master and (Osi.CharacterIsPlayer(master) == 1 or Osi.CharacterIsPartyMember(master) == 1) then
                    return
                end
            end

            -- Determine enemy level
            local level = Osi.CharacterGetLevel(charGuid) or 1
            if level < 1 then level = 1 end

            -- Calculate base experience
            local expRequired = LevelExpTable[level] or (level * level * 2000)
            if Osi.DB_LevelExp then
                local ok, rows = pcall(Osi.DB_LevelExp.Get, Osi.DB_LevelExp, level, nil)
                if ok and rows and rows[1] and rows[1][2] then
                    expRequired = rows[1][2]
                end
            end

            local baseKillXP = expRequired / 20.0
            local scaledXP = math.max(1, math.floor(baseKillXP * Config.CombatXPMultiplier))

            -- Grant scaled experience to the party
            Osi.PartyAddExperience(scaledXP)

            PrintLog(string.format("[DifficultyMod] Awarded %d Combat XP (Level %d, Base: %d, Multiplier: %.2f) for defeating %s",
                scaledXP, level, math.floor(baseKillXP), Config.CombatXPMultiplier, tostring(charGuid)))
        end)

        -- Current stat scaling when character enters combat
        registerOsiris("CharacterEnteredCombat", 2, "after", function(charGuid, combatId)
            ScaleCharacterCurrentStats(charGuid)
        end)

        registerOsiris("ObjectEnteredCombat", 2, "after", function(objectGuid, combatId)
            if Osi.ObjectIsCharacter(objectGuid) == 1 then
                ScaleCharacterCurrentStats(objectGuid)
            end
        end)

        PrintLog("[DifficultyMod] Server combat listeners registered.")
    end
end

--------------------------------------------------------------------------------
-- 6. Register Event Listeners
--------------------------------------------------------------------------------
-- StatsLoaded subscription (in-memory template scaling)
if Ext and Ext.Events and Ext.Events.StatsLoaded then
    Ext.Events.StatsLoaded:Subscribe(ApplyDifficultyScaling)
elseif Ext and Ext.RegisterListener then
    Ext.RegisterListener("StatsLoaded", ApplyDifficultyScaling)
end

-- Session load subscription (proportionally scales current health of existing map characters)
if Ext and Ext.Events and Ext.Events.SessionLoaded then
    Ext.Events.SessionLoaded:Subscribe(function()
        ScaleAllLoadedMapEnemies()
    end)
elseif Ext and Ext.RegisterListener then
    Ext.RegisterListener("SessionLoaded", function()
        ScaleAllLoadedMapEnemies()
    end)
end

if Ext and Ext.Events and Ext.Events.GameStateChanged then
    Ext.Events.GameStateChanged:Subscribe(function(e)
        if e.ToState == "Running" then
            ScaleAllLoadedMapEnemies()
        end
    end)
end

-- Server combat registrations
RegisterCombatListeners()

return {
    ApplyDifficultyScaling = ApplyDifficultyScaling,
    Config = Config
}
