--[[
    DifficultyMod - BootstrapClient.lua
    Client-side entry point script invoked automatically by Norbyte's Script Extender.
--]]

-- Check if Script Extender global table and Ext.Require function exist in client context
if Ext and Ext.Require then
    -- Load ModInfo module to initialize version reporting
    Ext.Require("ModInfo.lua")
    -- Load main DifficultyScaler module
    Ext.Require("DifficultyScaler.lua")
-- Fallback check for standard Lua require function
elseif require then
    require("ModInfo")
    require("DifficultyScaler")
end
