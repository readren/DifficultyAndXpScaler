--[[
    DifficultyMod - BootstrapServer.lua
    Server-side entry point script invoked automatically by Norbyte's Script Extender.
--]]

-- Check if Script Extender global table and Ext.Require function exist in server context
if Ext and Ext.Require then
    -- Call library function Ext.Require(path: string) -> table
    -- Parameter: "DifficultyScaler.lua" (type: string) - script path to load into server Lua state
    local ok, _ = pcall(Ext.Require, "DifficultyScaler.lua")
    -- Check if file extension requirement failed, falling back to module name format
    if not ok then
        -- Call library function Ext.Require(path: string) -> table
        -- Parameter: "DifficultyScaler" (type: string) - module name without .lua extension
        pcall(Ext.Require, "DifficultyScaler")
    end
-- Fallback check for standard Lua require function
elseif require then
    -- Call standard library function require(modname: string) -> table
    -- Parameter: "DifficultyScaler" (type: string) - module name
    pcall(require, "DifficultyScaler")
end
