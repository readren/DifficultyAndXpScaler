--[[
    DifficultyMod - BootstrapClient.lua
    Client-side entry point script invoked automatically by Norbyte's Script Extender.
--]]

-- Check if Script Extender global table and Ext.Require function exist in client context
if Ext and Ext.Require then
    -- Call library function Ext.Require(path: string) -> table
    -- Parameter: "DifficultyScaler.lua" (type: string) - script path to load into client Lua state
    local ok, _ = Ext.Require("DifficultyScaler.lua")
    -- Check if file extension requirement failed, falling back to module name format
    if not ok then
        -- Call library function Ext.Require(path: string) -> table
        -- Parameter: "DifficultyScaler" (type: string) - module name without .lua extension
        Ext.Require("DifficultyScaler")
    end
-- Fallback check for standard Lua require function
elseif require then
    -- Call standard library function require(modname: string) -> table
    -- Parameter: "DifficultyScaler" (type: string) - module name
    require("DifficultyScaler")
end
