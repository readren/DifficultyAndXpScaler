--[[
    DifficultyMod - DifficultyScaler.lua
    Applies in-memory difficulty scaling to character stats (Vitality, Armour, Magic Armour)
    and dynamic combat experience scaling based on template Gain tiers without modifying static disk tables.
--]]

--------------------------------------------------------------------------------
-- Section 1: Environment Assertion & Script Extender API Adapters
--------------------------------------------------------------------------------

-- Assert that Norbyte's Script Extender is present; fail immediately if missing
if not Ext then
    -- Throw fatal error halting script initialization if Ext global table is missing
    error("[DifficultyMod] Critical: Norbyte's Script Extender (Ext) is required but not detected.")
end

--- Retrieves a character or object stat structure from the Script Extender stats engine by name.
-- @param name string: The template or stat identifier name (e.g. "_Base", "_Hero", "_Zombie").
-- @return table|userdata|nil: The stat object reference if found in memory, nil otherwise.
local function ExtGetStat(name)
    -- Return nil immediately if name is invalid or empty
    if not name or name == "" then return nil end
    -- Check if modern Ext.Stats.Get API is available (Extender v56+)
    if Ext.Stats and Ext.Stats.Get then
        -- Call library function Ext.Stats.Get(name: string) -> table|userdata
        -- Parameter: name (type: string) - stat template identifier
        return Ext.Stats.Get(name)
    -- Fallback to legacy Ext.GetStat API (Extender v50-v55)
    elseif Ext.GetStat then
        -- Call library function Ext.GetStat(name: string) -> table|userdata
        -- Parameter: name (type: string) - stat template identifier
        return Ext.GetStat(name)
    end
    -- Throw fatal error if no Extender stats retrieval function exists
    error("[DifficultyMod] Critical: Neither Ext.Stats.Get nor Ext.GetStat API is available.")
end

--- Retrieves an array of all character stat entry names defined in the engine.
-- @return table: Array of character stat template identifier strings.
local function ExtGetCharacterStatNames()
    -- Check if modern Ext.Stats.GetStats API is available (Extender v56+)
    if Ext.Stats and Ext.Stats.GetStats then
        -- Call library function Ext.Stats.GetStats(type: string) -> table
        -- Parameter: "Character" (type: string) - stat table category
        return Ext.Stats.GetStats("Character")
    -- Check if intermediate Ext.Stats.GetStatEntries API is available
    elseif Ext.Stats and Ext.Stats.GetStatEntries then
        -- Call library function Ext.Stats.GetStatEntries(type: string) -> table
        -- Parameter: "Character" (type: string) - stat table category
        return Ext.Stats.GetStatEntries("Character")
    -- Fallback to legacy Ext.GetStatEntries API
    elseif Ext.GetStatEntries then
        -- Call library function Ext.GetStatEntries(type: string) -> table
        -- Parameter: "Character" (type: string) - stat table category
        return Ext.GetStatEntries("Character")
    end
    -- Throw fatal error if no Extender stat listing function exists
    error("[DifficultyMod] Critical: Neither Ext.Stats.GetStats nor Ext.GetStatEntries API is available for Character stats.")
end

--- Retrieves an array of all skill stat entry names defined in the engine.
-- @return table: Array of skill stat template identifier strings.
local function ExtGetSkillStatNames()
    -- Check if modern Ext.Stats.GetStats API is available (Extender v56+)
    if Ext.Stats and Ext.Stats.GetStats then
        -- Call library function Ext.Stats.GetStats(type: string) -> table
        -- Parameter: "SkillData" (type: string) - stat table category
        return Ext.Stats.GetStats("SkillData")
    -- Check if intermediate Ext.Stats.GetStatEntries API is available
    elseif Ext.Stats and Ext.Stats.GetStatEntries then
        -- Call library function Ext.Stats.GetStatEntries(type: string) -> table
        -- Parameter: "SkillData" (type: string) - stat table category
        return Ext.Stats.GetStatEntries("SkillData")
    -- Fallback to legacy Ext.GetStatEntries API
    elseif Ext.GetStatEntries then
        -- Call library function Ext.GetStatEntries(type: string) -> table
        -- Parameter: "SkillData" (type: string) - stat table category
        return Ext.GetStatEntries("SkillData")
    end
    -- Throw fatal error if no Extender stat listing function exists for SkillData
    error("[DifficultyMod] Critical: Neither Ext.Stats.GetStats nor Ext.GetStatEntries API is available for SkillData.")
end

--- Retrieves a root template object from the engine by its GUID string.
-- @param guid string: The root template GUID string.
-- @return table|userdata|nil: The root template object if found, nil if GUID is empty.
local function ExtGetRootTemplate(guid)
    -- Return nil immediately if guid is invalid or empty
    if not guid or guid == "" then return nil end
    -- Check if modern Ext.Template.GetRootTemplate API is available
    if Ext.Template and Ext.Template.GetRootTemplate then
        return Ext.Template.GetRootTemplate(guid)
    -- Fallback to Ext.Template.GetTemplate API
    elseif Ext.Template and Ext.Template.GetTemplate then
        return Ext.Template.GetTemplate(guid)
    end
    -- Return nil if root template inspection subsystem is not supported in this extender build
    return nil
end

--- Retrieves a character entity object by its GUID string.
-- @param guid string: The character's world GUID string (e.g. "S_GLO_Character_...").
-- @return table|userdata|nil: The character entity object if found, nil otherwise.
local function ExtGetCharacter(guid)
    -- Return nil immediately if guid is invalid or empty
    if not guid or guid == "" then return nil end
    -- Check if modern Ext.Entity.GetCharacter API is available (Extender v56+)
    if Ext.Entity and Ext.Entity.GetCharacter then
        -- Call library function Ext.Entity.GetCharacter(guid: string) -> table|userdata
        -- Parameter: guid (type: string) - character entity GUID
        return Ext.Entity.GetCharacter(guid)
    -- Fallback to legacy Ext.GetCharacter API
    elseif Ext.GetCharacter then
        -- Call library function Ext.GetCharacter(guid: string) -> table|userdata
        -- Parameter: guid (type: string) - character entity GUID
        return Ext.GetCharacter(guid)
    end
    -- Throw fatal error if no character entity function exists
    error("[DifficultyMod] Critical: Neither Ext.Entity.GetCharacter nor Ext.GetCharacter API is available.")
end

--- Retrieves an array of all character entity GUID strings loaded on the current map level.
-- @return table: Array of character GUID strings.
local function ExtGetAllCharacterGuids()
    -- Check if Ext.Entity.GetAllCharacterGuids API is available
    if Ext.Entity and Ext.Entity.GetAllCharacterGuids then
        -- Call library function Ext.Entity.GetAllCharacterGuids() -> table of string GUIDs
        return Ext.Entity.GetAllCharacterGuids()
    end
    -- Throw fatal error if map entity querying function is missing
    error("[DifficultyMod] Critical: Ext.Entity.GetAllCharacterGuids API is available.")
end

--- Registers an Osiris event listener callback with the Script Extender.
-- @param eventName string: The Osiris event name (e.g. "CharacterDied", "RegionStarted").
-- @param arity integer: The number of parameters passed to the Osiris event.
-- @param eventType string: Execution timing relative to the engine ("before" or "after").
-- @param handler function: The Lua callback function to invoke upon event trigger.
-- @return nil
local function ExtRegisterOsiris(eventName, arity, eventType, handler)
    -- Check if modern Ext.Osiris.RegisterListener API is available
    if Ext.Osiris and Ext.Osiris.RegisterListener then
        -- Call library function Ext.Osiris.RegisterListener(name: string, arity: integer, type: string, handler: function) -> nil
        Ext.Osiris.RegisterListener(eventName, arity, eventType, handler)
    -- Fallback to legacy Ext.RegisterOsirisListener API
    elseif Ext.RegisterOsirisListener then
        -- Call library function Ext.RegisterOsirisListener(name: string, arity: integer, type: string, handler: function) -> nil
        Ext.RegisterOsirisListener(eventName, arity, eventType, handler)
    else
        -- Throw fatal error if Osiris listener registration function is missing
        error("[DifficultyMod] Critical: Ext.Osiris.RegisterListener API is missing.")
    end
end

--- Subscribes a callback function to the StatsLoaded engine event.
-- @param handler function: The Lua callback function to execute when stats are loaded into memory.
-- @return nil
local function ExtSubscribeStatsLoaded(handler)
    -- Check if modern Ext.Events.StatsLoaded event bus is available
    if Ext.Events and Ext.Events.StatsLoaded then
        -- Call library method Ext.Events.StatsLoaded:Subscribe(handler: function) -> nil
        Ext.Events.StatsLoaded:Subscribe(handler)
    -- Fallback to legacy Ext.RegisterListener API
    elseif Ext.RegisterListener then
        -- Call library function Ext.RegisterListener(event: string, handler: function) -> nil
        Ext.RegisterListener("StatsLoaded", handler)
    else
        -- Throw fatal error if StatsLoaded subscription mechanism is missing
        error("[DifficultyMod] Critical: Ext.Events.StatsLoaded subscription API is missing.")
    end
end

--- Checks whether a character instance is a registered Osiris summon.
-- @param guid string|nil: The character's world GUID string (e.g. "S_GLO_Character_...").
-- @return boolean: True if the character is confirmed as a summon by Osiris, false if guid is empty.
local function OsiIsSummon(guid)
    -- Return false immediately if GUID string is empty or nil
    if not guid or guid == "" then return false end
    -- Check if Osiris environment and query CharacterIsSummon are available
    if Osi and Osi.CharacterIsSummon then
        -- Call Osiris query Osi.CharacterIsSummon(guid: string) -> integer (1=true, 0=false)
        return Osi.CharacterIsSummon(guid) == 1
    end
    -- Throw fatal error if Osiris or CharacterIsSummon query API is unavailable
    error("[DifficultyMod] Critical: Osi.CharacterIsSummon query API is missing.")
end

--- Retrieves the owner/master character GUID of a summon instance.
-- @param guid string|nil: The summon character's world GUID string.
-- @return string|nil: The owner character GUID string if present and valid, nil if not a summon or guid is empty.
local function OsiGetOwnerCharacter(guid)
    -- Return nil immediately if GUID string is empty or nil
    if not guid or guid == "" then return nil end
    -- If entity is not a summon, do not invoke CharacterGetOwnerCharacter to avoid Osiris query failure
    if not OsiIsSummon(guid) then return nil end
    -- Check if Osiris environment and query CharacterGetOwnerCharacter are available
    if Osi and Osi.CharacterGetOwnerCharacter then
        -- Call Osiris query Osi.CharacterGetOwnerCharacter(guid: string) -> string (owner GUID)
        local owner = Osi.CharacterGetOwnerCharacter(guid)
        -- Validate that owner GUID is non-empty and does not match the null GUID constant
        if owner and owner ~= "" and owner ~= "NULL_00000000-0000-0000-0000-000000000000" then
            return owner
        end
        return nil
    end
    -- Throw fatal error if Osiris or CharacterGetOwnerCharacter query API is unavailable
    error("[DifficultyMod] Critical: Osi.CharacterGetOwnerCharacter query API is missing.")
end

--------------------------------------------------------------------------------
-- Section 2: Configuration Loading & Logging Utilities
--------------------------------------------------------------------------------

-- Storage variable for the loaded configuration table
local Config

-- Attempt to load Config.lua using Script Extender require mechanism
if Ext.Require then
    -- Call library function Ext.Require(path: string) -> table
    -- Parameter: "Config.lua" (type: string) - relative path to the configuration script
    local ok, res = pcall(Ext.Require, "Config.lua")
    -- Fail loudly if require raised an error or returned nil
    if not ok or not res then
        -- Throw fatal error with the exact underlying error message
        error(string.format("[DifficultyMod] Critical: Failed to load Config.lua via Ext.Require: %s", tostring(res)))
    end
    -- Assign loaded table to Config variable
    Config = res
-- Fallback attempt using standard Lua require function
elseif require then
    -- Call standard library function require(modname: string) -> table
    local ok, res = pcall(require, "Config")
    -- Fail loudly if standard require failed
    if not ok or not res then
        -- Throw fatal error with the exact error message
        error(string.format("[DifficultyMod] Critical: Failed to load Config.lua via require: %s", tostring(res)))
    end
    -- Assign loaded table to Config variable
    Config = res
else
    -- Throw fatal error if no module loading function is present in environment
    error("[DifficultyMod] Critical: No require function available to load Config.lua.")
end

-- Validate that Config is a table structure
if type(Config) ~= "table" then
    -- Throw fatal error if Config.lua did not return a table
    error("[DifficultyMod] Critical: Config.lua must return a configuration table.")
end

-- Precalculated module-level feature activation flags initialized once at startup
local ShouldScaleVitality       = (Config.EnemyVitalityMultiplier ~= nil and Config.EnemyVitalityMultiplier ~= 1.0 and Config.EnemyVitalityMultiplier > 0)
local ShouldScalePhysicalArmour = (Config.EnemyPhysicalArmourMultiplier ~= nil and Config.EnemyPhysicalArmourMultiplier ~= 1.0 and Config.EnemyPhysicalArmourMultiplier > 0)
local ShouldScaleMagicArmour    = (Config.EnemyMagicArmourMultiplier ~= nil and Config.EnemyMagicArmourMultiplier ~= 1.0 and Config.EnemyMagicArmourMultiplier > 0)
local ShouldOverrideCombatXP    = (Config.CombatXPMultiplier ~= nil and Config.CombatXPMultiplier ~= 1.0 and Config.CombatXPMultiplier > 0)
local ShouldSyncLiveStats       = (ShouldScaleVitality or ShouldScalePhysicalArmour or ShouldScaleMagicArmour)

--- Prints a formatted log message to the Script Extender debug console and log files.
-- @param msg string: The textual message content to output to the console.
-- @return nil
local function PrintLog(msg)
    -- Verify that Config is valid and DebugLogging is enabled before printing
    if not Config.DebugLogging then
        -- Exit early if debug logging is disabled in configuration
        return
    end
    -- Call string.format(formatstring: string, ...: any) -> string
    -- Parameters: "[DifficultyMod] %s" (type: string), msg (type: string)
    local formatted = string.format("[DifficultyMod] %s", msg)
    -- Check if Ext.Utils.Print library function is accessible
    if Ext.Utils and Ext.Utils.Print then
        -- Call library function Ext.Utils.Print(message: string) -> nil
        -- Parameter: formatted (type: string) - the formatted log message
        Ext.Utils.Print(formatted)
    -- Fallback to legacy Ext.Print library function if Ext.Utils is unavailable
    elseif Ext.Print then
        -- Call library function Ext.Print(message: string) -> nil
        -- Parameter: formatted (type: string) - the formatted log message
        Ext.Print(formatted)
    -- Final fallback to standard Lua print function
    else
        -- Call standard library function print(...: any) -> nil
        -- Parameter: formatted (type: string) - message to output
        print(formatted)
    end
end

--------------------------------------------------------------------------------
-- Section 3: Experience Requirements & Gain Tier Multiplier Constants
--------------------------------------------------------------------------------

-- Table mapping character level (1-25) to required experience in DOS2 Definitive Edition
local LevelExpTable = {
    [1]  = 2000,    -- Experience required to reach Level 2
    [2]  = 6000,    -- Experience required to reach Level 3
    [3]  = 12000,   -- Experience required to reach Level 4
    [4]  = 20000,   -- Experience required to reach Level 5
    [5]  = 30000,   -- Experience required to reach Level 6
    [6]  = 42000,   -- Experience required to reach Level 7
    [7]  = 56000,   -- Experience required to reach Level 8
    [8]  = 72000,   -- Experience required to reach Level 9
    [9]  = 100000,  -- Experience required to reach Level 10
    [10] = 139000,  -- Experience required to reach Level 11
    [11] = 189000,  -- Experience required to reach Level 12
    [12] = 252000,  -- Experience required to reach Level 13
    [13] = 330000,  -- Experience required to reach Level 14
    [14] = 425000,  -- Experience required to reach Level 15
    [15] = 539000,  -- Experience required to reach Level 16
    [16] = 674000,  -- Experience required to reach Level 17
    [17] = 833000,  -- Experience required to reach Level 18
    [18] = 1018000, -- Experience required to reach Level 19
    [19] = 1232000, -- Experience required to reach Level 20
    [20] = 1478000, -- Experience required to reach Level 21
    [21] = 1759000, -- Experience required to reach Level 22
    [22] = 2078000, -- Experience required to reach Level 23
    [23] = 2439000, -- Experience required to reach Level 24
    [24] = 2845000, -- Experience required to reach Level 25
    [25] = 3300000  -- Maximum baseline cap for calculation
}

-- Table mapping vanilla DOS2 Character.txt Gain tier enums, strings, and integer numbers to numerical multipliers
local GainTierMultipliers = {
    ["None"]       = 0.00, -- Non-combatants, civilians, ambient creatures (0% XP)
    ["0"]          = 0.00, -- String enum representation of None (0% XP)
    [0]            = 0.00, -- Integer enum representation of None (0% XP)
    ["ExtraSmall"] = 0.25, -- Minor critters, rats, rabbits, sheep (25% base XP)
    ["1"]          = 0.25, -- String enum representation of ExtraSmall (25% base XP)
    [1]            = 0.25, -- Integer enum representation of ExtraSmall (25% base XP)
    ["Small"]      = 0.50, -- Standard minions, adds, zombies, skeletons, wolves (50% base XP)
    ["2"]          = 0.50, -- String enum representation of Small (50% base XP)
    [2]            = 0.50, -- Integer enum representation of Small (50% base XP)
    ["Medium"]     = 1.00, -- Standard combatant baseline (_Base, human fighters, mages) (100% base XP)
    ["3"]          = 1.00, -- String enum representation of Medium (100% base XP)
    [3]            = 1.00, -- Integer enum representation of Medium (100% base XP)
    ["4"]          = 1.50, -- String enum representation of Veterans (150% base XP)
    [4]            = 1.50, -- Integer enum representation of Veterans (150% base XP)
    ["Large"]      = 2.00, -- Elite enemies, champions, mini-bosses, strong melee (200% base XP)
    ["5"]          = 2.00, -- String enum representation of Large (200% base XP)
    [5]            = 2.00, -- Integer enum representation of Large (200% base XP)
    ["6"]          = 3.00, -- String enum representation of Major mini-bosses (300% base XP)
    [6]            = 3.00, -- Integer enum representation of Major mini-bosses (300% base XP)
    ["ExtraLarge"] = 4.00, -- Major act bosses, act-end antagonists (400% base XP)
    ["7"]          = 4.00, -- String enum representation of ExtraLarge (400% base XP)
    [7]            = 4.00, -- Integer enum representation of ExtraLarge (400% base XP)
    ["8"]          = 5.00, -- String enum representation of Legendary bosses (500% base XP)
    [8]            = 5.00, -- Integer enum representation of Legendary bosses (500% base XP)
    ["9"]          = 6.00, -- String enum representation of Supreme bosses (600% base XP)
    [9]            = 6.00, -- Integer enum representation of Supreme bosses (600% base XP)
    ["10"]         = 8.00, -- Maximum cap tier (800% base XP)
    [10]           = 8.00
}

--------------------------------------------------------------------------------
-- Section 4: Template Identification & Dynamic Skill Introspection
--------------------------------------------------------------------------------

-- Global table storing dynamically discovered summon character template names from SkillData
SummonTemplates = {}

-- Global table storing pristine original stat properties for ALL character templates (heroes, summons, enemies)
OriginalStats = {}

--- Safely extracts the character stat entry name from a RootTemplate object across different template subclasses.
-- @param rootTpl userdata|table|nil: The root template object to inspect.
-- @return string|nil: The character stat entry name if present, nil otherwise.
local function SafeGetTemplateStat(rootTpl)
    if not rootTpl then return nil end
    local ok, stat = pcall(function()
        return rootTpl.Stats or rootTpl.StatsId or rootTpl.StatsEntryName
    end)
    if ok and stat and stat ~= "" then
        return stat
    end
    return nil
end

--- Checks whether a string matches standard GUID format (8-4-4-4-12 hex digits).
-- @param str string|nil: The string to inspect.
-- @return boolean: True if str is a GUID format, false otherwise.
local function IsGuidString(str)
    if type(str) ~= "string" then return false end
    return string.match(str, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

--- Dynamically inspects all SkillData entries to discover character templates used by summon skills.
-- @return nil
local function DiscoverSummonTemplates()
    SummonTemplates = {}
    -- Retrieve all SkillData entry names; fails loudly with fatal error if API is unavailable
    local skillEntries = ExtGetSkillStatNames()
    if not skillEntries or type(skillEntries) ~= "table" then
        error("[DifficultyMod] Critical: Failed to retrieve SkillData entries from stats engine.")
    end

    -- Iterate through each registered skill template to inspect summoning properties
    for _, skillName in pairs(skillEntries) do
        local skill = ExtGetStat(skillName)
        if skill then
            local tpl = skill.Template
            if tpl and tpl ~= "" then
                -- Check if Template refers to a RootTemplate GUID containing a character stat
                local rootTpl = ExtGetRootTemplate(tpl)
                local statName = SafeGetTemplateStat(rootTpl)
                if statName then
                    SummonTemplates[statName] = "skill template indirectly"
                -- Fallback: check if Template directly matches a Character stat template (skip if it is a GUID)
                elseif not IsGuidString(tpl) and ExtGetStat(tpl) then
                    SummonTemplates[tpl] = "skill template directly"
                end
            end

            -- Inspect SkillProperties for explicit SUMMON actions
            if skill.SkillProperties then
                for _, prop in pairs(skill.SkillProperties) do
                    if (prop.Action == "SUMMON" or prop.Action == "Summon") and prop.Arg1 and prop.Arg1 ~= "" then
                        local rootTpl = ExtGetRootTemplate(prop.Arg1)
                        local statName = SafeGetTemplateStat(rootTpl)
                        if statName then
                            SummonTemplates[statName] = "SkillProperties indirectly"
                        elseif not IsGuidString(prop.Arg1) and ExtGetStat(prop.Arg1) then
                            SummonTemplates[prop.Arg1] = "SkillProperties directly"
                        end
                    end
                end
            end
        end
    end

    -- Print discovered summon templates and their discovery source to console
    local count = 0
    for templateName, source in pairs(SummonTemplates) do
        count = count + 1
        PrintLog(string.format("Discovered summon template: %s (Source: %s)", tostring(templateName), tostring(source)))
    end
    PrintLog(string.format("Total summon templates discovered: %d", count))
end

--- Checks whether a stat entry name belongs to or inherits from the playable hero archetype _Hero.
-- @param name string|nil: The template stat identifier name from Character.txt.
-- @return boolean: True if the template is _Hero or inherits from _Hero (player/companion archetype), false otherwise.
local function IsPlayerOrHeroStat(name)
    -- Return true if name is nil or empty to protect undefined structures
    if not name or name == "" then return true end
    -- Check if name strictly matches the primary player archetype template _Hero
    if name == "_Hero" then
        -- Return true to protect base hero template from enemy stat scaling
        return true
    end

    -- Initialize current pointer to the starting stat template name
    local current = name
    -- Set to track visited template names and prevent infinite circular inheritance loops
    local visited = {}

    -- Traverse inheritance chain until _Hero is reached or inheritance ends
    while current and current ~= "" and not visited[current] do
        -- Check if current template name in chain is _Hero
        if current == "_Hero" then
            -- Return true indicating this template descends from _Hero
            return true
        end
        -- Mark current template as visited in cycle detection set
        visited[current] = true

        -- Call ExtGetStat(name: string) -> table|userdata|nil
        local stat = ExtGetStat(current)
        -- Break loop if stat object cannot be retrieved or has no parent
        if not stat or not stat.Using or stat.Using == "" or stat.Using == current then
            break
        end
        -- Step up the inheritance chain to the parent template name
        current = stat.Using
    end

    -- Return false indicating this template does not inherit from _Hero
    return false
end

--- Traverses template inheritance chains (Using) to find the original resolved Gain tier.
-- @param statName string: The name of the character stat template to inspect.
-- @return string: The resolved Gain tier string ("None", "ExtraSmall", "Small", "Medium", "Large", "ExtraLarge" or numeric enum string).
local function GetResolvedTemplateGain(statName)
    -- Initialize current pointer to the starting stat template name
    local current = statName
    -- Set to track visited template names and prevent infinite circular inheritance loops
    local visited = {}
    -- Loop through parent templates as long as current name is non-empty and unvisited
    while current and current ~= "" and not visited[current] do
        -- Mark current template name as visited in loop tracker
        visited[current] = true
        -- Call ExtGetStat(name: string) -> table|userdata|nil
        local stat = ExtGetStat(current)
        -- Break loop if stat object cannot be retrieved from engine
        if not stat then break end
        -- Check if stat defines an explicit non-empty Gain tier property (accepting 0, "0", "None", etc.)
        if stat.Gain ~= nil and stat.Gain ~= "" then
            -- Return the explicit Gain tier found on this template as a string
            return tostring(stat.Gain)
        end
        -- Check if template inherits from a parent template via Using property
        if stat.Using and stat.Using ~= "" and stat.Using ~= current then
            -- Step up the inheritance chain to the parent template name
            current = stat.Using
        else
            -- Terminate loop if root template is reached with no parent
            break
        end
    end
    -- Fall back to "None" (0 XP) if hierarchy terminates without declaring a combat Gain tier
    return "None"
end

--------------------------------------------------------------------------------
-- Section 5: In-Memory Character Stat & XP Template Scaling (StatsLoaded Hook)
--------------------------------------------------------------------------------

--- Iterates over all character templates in memory to apply stat scaling and cache Gain tiers.
-- @return nil
local function ApplyDifficultyScaling()
    -- Dynamically discover all summon templates registered in SkillData
    DiscoverSummonTemplates()

    -- If all feature flags are false, all multipliers are 1.0x (vanilla); exit immediately with zero overhead
    if not (ShouldSyncLiveStats or ShouldOverrideCombatXP) then
        PrintLog("All multipliers are 1.0x (vanilla). In-memory difficulty scaling skipped.")
        return
    end

    -- Call ExtGetCharacterStatNames() -> table of strings
    local charEntries = ExtGetCharacterStatNames()
    -- Counter tracking the number of modified character templates
    local modifiedCount = 0

    -- Reset global OriginalStats table
    OriginalStats = {}

    -- =========================================================================
    -- PASS 1: Read and capture pristine original data for ALL character templates
    -- =========================================================================

    for _, name in pairs(charEntries) do
        -- Call ExtGetStat(name: string) -> table|userdata|nil
        local stat = ExtGetStat(name)
        -- Verify stat structure exists for this template name
        if stat then
            -- Only resolve and cache Gain tier when custom XP override is active
            local resolvedGain = nil
            if ShouldOverrideCombatXP then
                -- Call GetResolvedTemplateGain(statName: string) -> string to traverse unmutated hierarchy
                resolvedGain = GetResolvedTemplateGain(name)
            end

            -- Snapshot pristine original properties before any in-memory mutation begins
            OriginalStats[name] = {
                Using = (stat.Using and stat.Using ~= "" and stat.Using ~= name) and stat.Using or nil,
                Vitality = stat.Vitality,
                Armor = stat.Armor,
                MagicArmor = stat.MagicArmor,
                Gain = resolvedGain
            }
        end
    end

    -- =========================================================================
    -- PASS 2: Apply in-memory stat scaling and suppress native engine kill XP
    -- =========================================================================

    -- Iterate over non-hero, non-summon, non-abstract character templates to scale stats and zero-out Gain
    for _, name in pairs(charEntries) do
        -- Exclude abstract archetype templates (starting with "_"), player/companion hero templates, and summon templates
        if string.sub(name, 1, 1) ~= "_" and not IsPlayerOrHeroStat(name) and not SummonTemplates[name] then
            -- Call ExtGetStat(name: string) -> table|userdata|nil
            local stat = ExtGetStat(name)
            local orig = OriginalStats[name]
            -- Verify stat structure and snapshot data exist for this template name
            if stat and orig then
                -- Boolean flag indicating if any property on this stat was modified
                local modified = false

                -- Vitality: Scale based directly on pristine snapshot value
                if ShouldScaleVitality and orig.Vitality and orig.Vitality > 0 then
                    -- Call math.floor(x: number) -> integer for scaled vitality
                    stat.Vitality = math.floor(orig.Vitality * Config.EnemyVitalityMultiplier)
                    modified = true
                end

                -- Physical Armour: Scale based directly on pristine snapshot value
                if ShouldScalePhysicalArmour and orig.Armor and orig.Armor > 0 then
                    -- Call math.floor(x: number) -> integer for scaled armour
                    stat.Armor = math.floor(orig.Armor * Config.EnemyPhysicalArmourMultiplier)
                    modified = true
                end

                -- Magic Armour: Scale based directly on pristine snapshot value
                if ShouldScaleMagicArmour and orig.MagicArmor and orig.MagicArmor > 0 then
                    -- Call math.floor(x: number) -> integer for scaled magic armour
                    stat.MagicArmor = math.floor(orig.MagicArmor * Config.EnemyMagicArmourMultiplier)
                    modified = true
                end

                -- Suppress engine native kill XP reward so custom multiplier can be awarded dynamically
                if ShouldOverrideCombatXP then
                    -- Set Gain to 0 to disable native unscaled kill XP calculation
                    stat.Gain = 0
                    modified = true
                end

                -- Increment count if any properties were updated
                if modified then
                    modifiedCount = modifiedCount + 1
                end
            end
        end
    end

    -- Call PrintLog(msg: string) to log summary of in-memory template adjustments
    PrintLog(string.format("In-memory scaling applied to %d enemy templates (Vitality: x%.2f, PhysArmour: x%.2f, MagicArmour: x%.2f, CombatXP: x%.2f).",
        modifiedCount, Config.EnemyVitalityMultiplier, Config.EnemyPhysicalArmourMultiplier, Config.EnemyMagicArmourMultiplier, Config.CombatXPMultiplier or 1.0))
end

--------------------------------------------------------------------------------
-- Section 6: Current Health & Armour Savegame Synchronization
--------------------------------------------------------------------------------

--- Proportionally scales a live character instance's current health and armour up to its new max.
-- @param guidOrChar string|userdata: The GUID string or character entity object to scale.
-- @return nil
local function ScaleCharacterCurrentStats(guidOrChar)
    -- If no stat multipliers are active, skip live character instance synchronization entirely
    if not ShouldSyncLiveStats then
        return
    end

    local guid = nil
    local char = nil

    -- Check if parameter passed is a GUID string
    if type(guidOrChar) == "string" then
        guid = guidOrChar
        -- Call ExtGetCharacter(guid: string) -> table|userdata|nil
        char = ExtGetCharacter(guid)
    -- Otherwise parameter is already a character entity object
    else
        char = guidOrChar
        -- Extract GUID from MyGuid property if present
        if char and char.MyGuid then guid = char.MyGuid end
    end

    -- Verify character entity and its stats component are valid
    if not char or not char.Stats then return end

    -- Exclude dead characters from stat synchronization
    if char.Dead or (char.Stats.CurrentVitality and char.Stats.CurrentVitality <= 0) then
        return
    end

    -- Exclude custom player characters
    if char.PlayerCustomData ~= nil then return end
    -- Exclude origin hero / player archetype templates
    if char.Stats.Name and IsPlayerOrHeroStat(char.Stats.Name) then return end

    -- Check Osiris player and party status
    if Osi and guid then
        -- Call library function Osi.CharacterIsPlayer(guid: string) -> integer (1=true, 0=false)
        -- Call library function Osi.CharacterIsPartyMember(guid: string) -> integer (1=true, 0=false)
        if Osi.CharacterIsPlayer(guid) == 1 or Osi.CharacterIsPartyMember(guid) == 1 then
            return
        end
    end

    -- Determine if entity is a summon and safely resolve master/owner
    local isSummon = false
    local master = nil

    if guid and OsiIsSummon(guid) then
        isSummon = true
        master = OsiGetOwnerCharacter(guid)
    elseif char.Stats.Name and SummonTemplates[char.Stats.Name] then
        isSummon = true
    end

    -- If entity is a summon owned by player or party, exclude from scaling (100% vanilla)
    if isSummon and master then
        if Osi and (Osi.CharacterIsPlayer(master) == 1 or Osi.CharacterIsPartyMember(master) == 1) then
            return
        end
    end

    -- Exclude player-owned entities via Extender entity handle
    if char.OwnerHandle and char.OwnerHandle ~= 0 and char.OwnerHandle ~= 0xFFFFFFFF then
        local owner = (Ext.Entity and Ext.Entity.GetCharacter and Ext.Entity.GetCharacter(char.OwnerHandle)) or (Ext.GetCharacter and Ext.GetCharacter(char.OwnerHandle))
        if owner and (owner.PlayerCustomData ~= nil or (Osi and (Osi.CharacterIsPlayer(owner.MyGuid) == 1 or Osi.CharacterIsPartyMember(owner.MyGuid) == 1))) then
            return
        end
    end

    -- Extract live stat values from character stats component
    local stats = char.Stats
    local maxVit = stats.MaxVitality or 0
    local curVit = stats.CurrentVitality or 0
    local maxArm = stats.MaxArmor or 0
    local curArm = stats.CurrentArmor or 0
    local maxMagicArm = stats.MaxMagicArmor or 0
    local curMagicArm = stats.CurrentMagicArmor or 0


    -- If this is an enemy summon, scale its live max and current stats
    if isSummon then
        if ShouldScaleVitality and maxVit > 0 and curVit > 0 then
            local scaledVit = math.min(maxVit, math.floor(curVit * Config.EnemyVitalityMultiplier))
            stats.CurrentVitality = scaledVit
        end
        if ShouldScalePhysicalArmour and maxArm > 0 and curArm > 0 then
            local scaledArm = math.min(maxArm, math.floor(curArm * Config.EnemyPhysicalArmourMultiplier))
            stats.CurrentArmor = scaledArm
        end
        if ShouldScaleMagicArmour and maxMagicArm > 0 and curMagicArm > 0 then
            local scaledMagicArm = math.min(maxMagicArm, math.floor(curMagicArm * Config.EnemyMagicArmourMultiplier))
            stats.CurrentMagicArmor = scaledMagicArm
        end
        return
    end

    -- For standard loaded enemies: scale Current Vitality proportionally up to MaxVitality
    if ShouldScaleVitality and maxVit > 0 and curVit > 0 and curVit < maxVit then
        -- Call math.min(x: number, y: number) -> number and math.floor(x: number) -> integer
        local scaledVit = math.min(maxVit, math.floor(curVit * Config.EnemyVitalityMultiplier))
        stats.CurrentVitality = scaledVit
        -- If vitality reached maximum and procedure exists, fully restore character state
        if Osi and guid and scaledVit >= maxVit and Osi.Proc_CharacterFullRestore then
            -- Call Osiris procedure Osi.Proc_CharacterFullRestore(guid: string) -> nil
            Osi.Proc_CharacterFullRestore(guid)
        end
    end

    -- Scale Current Physical Armour proportionally up to MaxArmor
    if ShouldScalePhysicalArmour and maxArm > 0 and curArm > 0 and curArm < maxArm then
        -- Call math.min(x: number, y: number) -> number and math.floor(x: number) -> integer
        local scaledArm = math.min(maxArm, math.floor(curArm * Config.EnemyPhysicalArmourMultiplier))
        stats.CurrentArmor = scaledArm
    end

    -- Scale Current Magic Armour proportionally up to MaxMagicArmor
    if ShouldScaleMagicArmour and maxMagicArm > 0 and curMagicArm > 0 and curMagicArm < maxMagicArm then
        -- Call math.min(x: number, y: number) -> number and math.floor(x: number) -> integer
        local scaledMagicArm = math.min(maxMagicArm, math.floor(curMagicArm * Config.EnemyMagicArmourMultiplier))
        stats.CurrentMagicArmor = scaledMagicArm
    end
end

--- Synchronizes stats for all loaded character instances on the active map level.
-- @return nil
local function ScaleAllLoadedMapEnemies()
    -- If no stat multipliers are active, skip map iteration entirely
    if not ShouldSyncLiveStats then
        return
    end

    -- Call ExtGetAllCharacterGuids() -> table of string GUIDs
    local guids = ExtGetAllCharacterGuids()
    if guids then
        local count = 0
        -- Iterate through all character GUIDs present in the current level
        for _, g in ipairs(guids) do
            -- Call ScaleCharacterCurrentStats(guidOrChar: string) -> nil
            ScaleCharacterCurrentStats(g)
            count = count + 1
        end
        -- Call PrintLog(msg: string) to log total synchronized character count
        PrintLog(string.format("Synchronized stats for %d characters on map.", count))
    end
end

--------------------------------------------------------------------------------
-- Section 7: Experience Distribution & Server Event Listeners
--------------------------------------------------------------------------------

--- Awards combat experience points to the host player party and any separate multiplayer parties.
-- @param amount integer: The quantity of experience points to award.
-- @return boolean: True if XP was successfully awarded to at least one player party, false otherwise.
local function AwardPartyCombatExperience(amount)
    -- Validate that XP amount is positive and Osiris table is accessible
    if not amount or amount <= 0 or not Osi then return false end

    -- Call Osiris function Osi.CharacterGetHostCharacter() -> string (host GUID)
    local host = Osi.CharacterGetHostCharacter()
    -- Set tracking all player GUIDs whose parties have been credited
    local awardedPlayers = {}
    -- Boolean tracking overall success of the award operation
    local success = false

    -- Verify host GUID is valid and not null
    if host and host ~= "" and host ~= "NULL_00000000-0000-0000-0000-000000000000" then
        -- Call Osiris function Osi.PartyAddActualExperience(character: string, xp: integer) -> nil
        -- Parameter 1: host (type: string) - recipient player character GUID
        -- Parameter 2: amount (type: integer) - raw experience amount
        Osi.PartyAddActualExperience(host, amount)
        awardedPlayers[host] = true
        success = true
    end

    -- Check if Osiris player database DB_IsPlayer is accessible for multiplayer handling
    if Osi.DB_IsPlayer then
        -- Call Osiris DB query Osi.DB_IsPlayer:Get(filter: nil) -> table of {guid}
        -- Parameter: nil (type: nil) - unfiltered query for all active players
        local players = Osi.DB_IsPlayer:Get(nil)
        if players then
            -- Iterate through each player record in DB_IsPlayer
            for _, p in ipairs(players) do
                local playerGuid = p[1]
                -- Check if player GUID is valid and party has not already received this XP
                if playerGuid and playerGuid ~= "" and not awardedPlayers[playerGuid] then
                    local inSameParty = false
                    -- Check if player is in the same party as host
                    if host and host ~= "" and Osi.CharacterIsInPartyWith(host, playerGuid) == 1 then
                        inSameParty = true
                    end
                    -- Check if player is in the same party as any other already-awarded player
                    for otherGuid, _ in pairs(awardedPlayers) do
                        -- Call Osiris query Osi.CharacterIsInPartyWith(char1: string, char2: string) -> integer (1=true, 0=false)
                        if Osi.CharacterIsInPartyWith(otherGuid, playerGuid) == 1 then
                            inSameParty = true
                            break
                        end
                    end

                    -- If player belongs to a distinct independent party, award XP to their party
                    if not inSameParty then
                        -- Call Osiris function Osi.PartyAddActualExperience(character: string, xp: integer) -> nil
                        Osi.PartyAddActualExperience(playerGuid, amount)
                        awardedPlayers[playerGuid] = true
                        success = true
                    end
                end
            end
        end
    end

    -- Fallback: if neither host nor DB_IsPlayer succeeded, try DB_PartyMembers database
    if not success and Osi.DB_PartyMembers then
        -- Call Osiris DB query Osi.DB_PartyMembers:Get(filter: nil) -> table of {guid}
        local members = Osi.DB_PartyMembers:Get(nil)
        if members and members[1] and members[1][1] then
            -- Call Osiris function Osi.PartyAddActualExperience(character: string, xp: integer) -> nil
            Osi.PartyAddActualExperience(members[1][1], amount)
            success = true
        end
    end

    -- Return overall success status
    return success
end

--- Registers server-side Osiris event listeners for character death, region start, and combat entry.
-- @return nil
local function RegisterServerEvents()
    -- Assert that Osiris is available in server context
    if not Osi then
        -- Throw fatal error if server environment lacks Osiris global table
        error("[DifficultyMod] Critical: Osiris global table (Osi) is not available in server context.")
    end

    -- 1. Register listener for CharacterDied Osiris event
    -- Call ExtRegisterOsiris(eventName: string, arity: integer, eventType: string, handler: function) -> nil
    -- Parameter 1: "CharacterDied" (type: string) - Osiris event name
    -- Parameter 2: 1 (type: integer) - number of event parameters (character GUID)
    -- Parameter 3: "after" (type: string) - execute handler after engine event processing
    -- Parameter 4: callback function receiving charGuid (type: string)
    ExtRegisterOsiris("CharacterDied", 1, "after", function(charGuid)
        -- Exit immediately if custom XP scaling is inactive (1.0 = native engine XP, <= 0 = disabled)
        if not ShouldOverrideCombatXP then
            return
        end
        -- Verify charGuid is valid
        if not charGuid or charGuid == "" then return end

        -- Exclude players and party members from awarding kill XP
        -- Call Osiris query Osi.CharacterIsPlayer(char: string) -> integer (1=true, 0=false)
        -- Call Osiris query Osi.CharacterIsPartyMember(char: string) -> integer (1=true, 0=false)
        if Osi.CharacterIsPlayer(charGuid) == 1 or Osi.CharacterIsPartyMember(charGuid) == 1 then
            return
        end

        -- Exclude summons from awarding kill XP (neither player nor enemy summons award kill XP)
        if OsiIsSummon(charGuid) then
            return
        end

        -- Retrieve character level using Osiris query
        -- Call Osiris query Osi.CharacterGetLevel(char: string) -> integer (character level)
        local level = Osi.CharacterGetLevel(charGuid) or 1
        if level < 1 then level = 1 end

        -- Query character template name from Extender entity component with multiple fallbacks
        local templateName = nil
        -- Call ExtGetCharacter(guid: string) -> table|userdata|nil
        local char = ExtGetCharacter(charGuid)
        if char then
            if char.Stats and char.Stats.Name and char.Stats.Name ~= "" then
                templateName = char.Stats.Name
            elseif char.StatsId and char.StatsId ~= "" then
                templateName = char.StatsId
            elseif char.RootTemplate and char.RootTemplate.Stats and char.RootTemplate.Stats ~= "" then
                templateName = char.RootTemplate.Stats
            end
        end

        -- Retrieve the cached original Gain tier from OriginalStats (defaulting to "None" if unresolvable)
        local orig = templateName and OriginalStats[templateName]
        local gainTier = (orig and orig.Gain) or "None"
        -- Look up the numerical multiplier from GainTierMultipliers table
        local tierMultiplier = GainTierMultipliers[gainTier]
        -- If not matched in dictionary, attempt numeric conversion with formula fallback
        if tierMultiplier == nil and tonumber(gainTier) then
            local n = tonumber(gainTier)
            if n <= 0 then tierMultiplier = 0.0
            elseif n == 1 then tierMultiplier = 0.25
            elseif n == 2 then tierMultiplier = 0.50
            elseif n == 3 then tierMultiplier = 1.00
            elseif n == 4 then tierMultiplier = 1.50
            elseif n == 5 then tierMultiplier = 2.00
            elseif n == 6 then tierMultiplier = 3.00
            elseif n == 7 then tierMultiplier = 4.00
            elseif n == 8 then tierMultiplier = 5.00
            elseif n == 9 then tierMultiplier = 6.00
            else tierMultiplier = n * 0.75 end
        end
        tierMultiplier = tierMultiplier or 0.00

        -- If template Gain tier resolves to 0.0 multiplier, no kill XP should be awarded
        if tierMultiplier <= 0 then
            PrintLog(string.format("Character %s resolved to 0x multiplier. Template: %s, Tier: %s",
                tostring(charGuid), tostring(templateName or "Unknown"), tostring(gainTier)))
            return
        end
        
        -- Calculate total experience required for this level from table
        local expRequired = LevelExpTable[level] or (level * level * 2000)
        -- Calculate base kill XP adjusted by the character's Gain tier multiplier (~20 kills per level at Medium)
        local baseKillXP = (expRequired / 20.0) * tierMultiplier
        -- Apply user configured CombatXPMultiplier and clamp minimum to 1 XP
        local scaledXP = math.max(1, math.floor(baseKillXP * Config.CombatXPMultiplier))

        -- Call AwardPartyCombatExperience(amount: integer) -> boolean to award XP to party
        local success = AwardPartyCombatExperience(scaledXP)

        -- Call PrintLog(msg: string) to log detailed XP reward to debug console
        PrintLog(string.format("Awarded %d Combat XP (Enemy: %s, Template: %s, Tier: %s, Level: %d, Base: %d, Multiplier: %.2f, Success: %s)",
            scaledXP, tostring(charGuid), tostring(templateName or "Unknown"), gainTier, level, math.floor(baseKillXP), Config.CombatXPMultiplier, tostring(success)))
    end)

    -- 2. Register listener for RegionStarted Osiris event (savegame load and map transitions)
    -- Call ExtRegisterOsiris(eventName: string, arity: integer, eventType: string, handler: function) -> nil
    ExtRegisterOsiris("RegionStarted", 1, "after", function(region)
        -- Call ScaleAllLoadedMapEnemies() -> nil to synchronize all loaded enemy stats
        ScaleAllLoadedMapEnemies()
    end)

    -- 3. Register listener for CharacterEnteredCombat Osiris event (newly spawned / ambush enemies)
    -- Call ExtRegisterOsiris(eventName: string, arity: integer, eventType: string, handler: function) -> nil
    ExtRegisterOsiris("CharacterEnteredCombat", 2, "after", function(charGuid, combatId)
        -- Call ScaleCharacterCurrentStats(guidOrChar: string) -> nil to scale newly entered combatant
        ScaleCharacterCurrentStats(charGuid)
    end)

    -- Call PrintLog(msg: string) to confirm server event registration
    PrintLog("Server events registered.")
end

--------------------------------------------------------------------------------
-- Section 8: Engine Event Listener Subscriptions & Module Export
--------------------------------------------------------------------------------

-- Call ExtSubscribeStatsLoaded(handler: function) to register in-memory template scaling hook
ExtSubscribeStatsLoaded(ApplyDifficultyScaling)

-- Check if current execution context is the server Lua state
if Ext.IsServer and Ext.IsServer() then
    -- Call RegisterServerEvents() -> nil to initialize all Osiris listeners
    RegisterServerEvents()
end

-- Return module interface table containing scaling function and configuration
return {
    ApplyDifficultyScaling = ApplyDifficultyScaling, -- Function applying in-memory stat scaling
    Config = Config                                  -- Active configuration table
}
