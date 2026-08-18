--[[
    DifficultyMod - BootstrapClient
    Initializes client-side difficulty scaling logic.
--]]

if Ext and Ext.Require then
    local ok, err = pcall(Ext.Require, "DifficultyScaler.lua")
    if not ok then
        pcall(Ext.Require, "DifficultyScaler")
    end
elseif require then
    pcall(require, "DifficultyScaler")
end
