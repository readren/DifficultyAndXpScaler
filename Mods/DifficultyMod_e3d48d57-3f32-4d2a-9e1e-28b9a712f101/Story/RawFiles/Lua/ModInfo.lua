--[[
    DifficultyMod - ModInfo.lua
    Provides runtime access to metadata, mod configuration, and version reporting.
--]]

-- Module GUID constant identifying this mod in Script Extender registries
local MOD_UUID = "e3d48d57-3f32-4d2a-9e1e-28b9a712f101"

--- Safely attempts to read a property from a C++ Extender userdata object without throwing errors.
-- @param obj userdata|table|nil: The C++ object or table to read from.
-- @param prop string: The property key name to query.
-- @return any: The property value if present and valid, nil otherwise.
local function SafeGetProperty(obj, prop)
    if not obj then return nil end
    local ok, val = pcall(function() return obj[prop] end)
    if ok and val ~= nil then
        return val
    end
    return nil
end

--- Unpacks a 32-bit Larian bit-packed version integer into a human-readable string.
-- Formula: Major << 28 | Minor << 24 | Revision << 16 | Build
-- @param v integer|string: Bit-packed 32-bit version integer or string from meta.lsx.
-- @return string|nil: Formatted version string (e.g. "1.0.1.0"), or nil if invalid.
local function FormatVersionNumber(v)
    if type(v) == "number" then
        local major    = (v >> 28) & 0x0F
        local minor    = (v >> 24) & 0x0F
        local revision = (v >> 16) & 0xFF
        local build    = v & 0xFFFF
        return string.format("%d.%d.%d.%d", major, minor, revision, build)
    elseif type(v) == "string" and v ~= "" then
        return v
    end
    return nil
end

--- Retrieves the active mod metadata table/userdata from Script Extender.
-- @return table|userdata|nil: Module info object if accessible.
local function GetModuleInfo()
    -- Check Ext.Mod.GetMod API
    if Ext.Mod and Ext.Mod.GetMod then
        local ok, info = pcall(Ext.Mod.GetMod, MOD_UUID)
        if ok and info then return info end
    end
    -- Fallback to Ext.GetModInfo API
    if Ext.GetModInfo then
        local ok, info = pcall(Ext.GetModInfo, MOD_UUID)
        if ok and info then return info end
    end
    return nil
end

--- Returns the human-readable version string dynamically read from engine metadata.
-- @return string|nil: The version string if successfully queried, nil otherwise.
local function GetVersion()
    local info = GetModuleInfo()
    if info then
        -- Check possible version properties on Extender Module struct safely
        local ver = SafeGetProperty(info, "ModVersion")
                 or SafeGetProperty(info, "Version")
                 or SafeGetProperty(info, "PublishVersion")
        if ver then
            local formatted = FormatVersionNumber(ver)
            if formatted then return formatted end
        end
        -- Check nested ModuleInfo property if present
        local subInfo = SafeGetProperty(info, "ModuleInfo")
        if subInfo then
            local subVer = SafeGetProperty(subInfo, "Version") or SafeGetProperty(subInfo, "ModVersion")
            if subVer then
                local formatted = FormatVersionNumber(subVer)
                if formatted then return formatted end
            end
        end
    end
    return nil
end

--- Logs the mod startup version banner to the Script Extender console and logs.
-- @return nil
local function LogStartupBanner()
    local version = GetVersion()
    local context = (Ext.IsServer and Ext.IsServer()) and "Server" or "Client"
    local msg
    if version then
        msg = string.format("[DifficultyMod] Difficulty and XP Scaler v%s loaded (%s context).", version, context)
    else
        msg = string.format("[DifficultyMod] Difficulty and XP Scaler loaded (%s context) [Version: Unable to query from engine].", context)
    end

    if Ext.Utils and Ext.Utils.Print then
        Ext.Utils.Print(msg)
    elseif Ext.Print then
        Ext.Print(msg)
    else
        print(msg)
    end
end

-- Automatically log startup banner upon module initialization
LogStartupBanner()

-- Return module interface
return {
    GetVersion       = GetVersion,
    GetModuleInfo    = GetModuleInfo,
    LogStartupBanner = LogStartupBanner,
    UUID             = MOD_UUID
}
