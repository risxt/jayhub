--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║        LUCKY EVENT HATCHER (LIGHTWEIGHT)                      ║
    ║        Only: Hatch + Auto Delete + Teleport to Lucky Event    ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  Based on: TapSimHub_v3.2_Test.lua                            ║
    ║  Purpose: Minimal script for Lucky Event farming              ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

if not game:IsLoaded() then game.Loaded:Wait() end

-- ============================================
-- SERVICES & CORE
-- ============================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Settings
_G.LuckySettings = {
    AutoHatch = false,
    AutoDelete = false,
    TargetEgg = nil, -- Will be discovered
    HatchDelay = 0.1,
    KeepGolden = true,
    KeepRainbow = true,
    SelectedRarities = {
        Common = true,
        Uncommon = true,
        Rare = false,
        Epic = false,
        Legendary = false,
        Mythic = false
    }
}

-- Lucky Event Location
local LuckyEventCFrame = CFrame.new(-177.407364, 214.149719, 234.651199, 0.0380607843, -7.83694603e-08, 0.999275446, -5.23740029e-09, 1, 7.86257743e-08, -0.999275446, -8.22616375e-09, 0.0380607843)

-- ============================================
-- [MODULE] NETWORK HELPER
-- ============================================
local Network = nil
pcall(function() Network = require(RS.Modules.Network) end)

local Replication = nil
pcall(function() Replication = require(RS.Game.Replication) end)

local PetStats = nil
pcall(function() PetStats = require(RS.Game.PetStats) end)

-- ============================================
-- [MODULE] EGG DISCOVERY
-- ============================================
local Eggs = {}
do
    local _discoveredEggs = {}
    local _hatchThread = nil
    local _isRunning = false
    local _hatchAmount = 1
    
    function Eggs.discover()
        _discoveredEggs = {}
        local Workspace = game:GetService("Workspace")
        
        -- Check Eggs folder
        for _, folderName in pairs({"Eggs", "RobuxEggs"}) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                for _, egg in pairs(folder:GetChildren()) do
                    if egg.Name ~= "Isl Folder" and not string.find(egg.Name, "Folder") then
                        if not table.find(_discoveredEggs, egg.Name) then
                            table.insert(_discoveredEggs, egg.Name)
                        end
                    end
                end
            end
        end
        
        table.sort(_discoveredEggs)
        print("[LUCKY] Discovered " .. #_discoveredEggs .. " eggs")
        return _discoveredEggs
    end
    
    function Eggs.getList()
        if #_discoveredEggs == 0 then Eggs.discover() end
        return _discoveredEggs
    end
    
    function Eggs.detectHatchAmount()
        if Replication and Replication.Data and Replication.Data.Gamepasses then
            local gp = Replication.Data.Gamepasses
            if gp["x8Egg"] == true then return 8
            elseif gp["x3Egg"] == true then return 3
            end
        end
        return 1
    end
    
    function Eggs.start()
        if _isRunning then return end
        _isRunning = true
        _hatchAmount = Eggs.detectHatchAmount()
        print("[LUCKY] Hatch amount: x" .. _hatchAmount)
        
        _hatchThread = task.spawn(function()
            while _isRunning and _G.LuckySettings.AutoHatch do
                local eggName = _G.LuckySettings.TargetEgg
                if eggName and Network then
                    pcall(function()
                        Network:InvokeServer("OpenEgg", eggName, _hatchAmount, {})
                    end)
                end
                task.wait(_G.LuckySettings.HatchDelay or 0.1)
            end
            _isRunning = false
        end)
    end
    
    function Eggs.stop()
        _isRunning = false
        if _hatchThread then
            pcall(function() task.cancel(_hatchThread) end)
            _hatchThread = nil
        end
    end
    
    function Eggs.toggle(enabled)
        _G.LuckySettings.AutoHatch = enabled
        if enabled then Eggs.start() else Eggs.stop() end
    end
end

-- ============================================
-- [MODULE] AUTO DELETE
-- ============================================
local AutoDelete = {}
do
    local _deleteThread = nil
    local _isRunning = false
    
    function AutoDelete.run()
        if not Replication or not Replication.Data or not Replication.Data.Pets then
            return 0
        end
        
        local deleted = 0
        for id, pet in pairs(Replication.Data.Pets) do
            if not _G.LuckySettings.AutoDelete then break end
            
            if not pet.Equipped and not pet.Locked then
                local rarity = "Common"
                if PetStats then
                    pcall(function() rarity = PetStats:GetRarity(pet.Name) end)
                end
                
                local shouldDelete = _G.LuckySettings.SelectedRarities[rarity]
                
                -- Keep special pets
                if pet.Tier == "Golden" and _G.LuckySettings.KeepGolden then shouldDelete = false end
                if pet.Tier == "Rainbow" and _G.LuckySettings.KeepRainbow then shouldDelete = false end
                if rarity == "Secret" or pet.Huge or pet.Exclusive then shouldDelete = false end
                
                if shouldDelete and Network then
                    pcall(function() Network:InvokeServer("DeletePet", id) end)
                    deleted = deleted + 1
                    task.wait(0.1)
                end
            end
        end
        return deleted
    end
    
    function AutoDelete.start()
        if _isRunning then return end
        _isRunning = true
        
        _deleteThread = task.spawn(function()
            while _isRunning and _G.LuckySettings.AutoDelete do
                AutoDelete.run()
                task.wait(1)
            end
            _isRunning = false
        end)
    end
    
    function AutoDelete.stop()
        _isRunning = false
        if _deleteThread then
            pcall(function() task.cancel(_deleteThread) end)
            _deleteThread = nil
        end
    end
    
    function AutoDelete.toggle(enabled)
        _G.LuckySettings.AutoDelete = enabled
        if enabled then AutoDelete.start() else AutoDelete.stop() end
    end
end

-- ============================================
-- [MODULE] TELEPORT
-- ============================================
local function teleportToLucky()
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = LuckyEventCFrame
        Fluent:Notify({Title="Teleported", Content="Lucky Event", Duration=2})
        return true
    end
    return false
end

-- ============================================
-- UI
-- ============================================
local Window = Fluent:CreateWindow({
    Title = "Lucky Event Hatcher",
    SubTitle = "Lightweight",
    TabWidth = 160,
    Size = UDim2.fromOffset(420, 380),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local MainTab = Window:AddTab({ Title = "Main", Icon = "egg" })
local DeleteTab = Window:AddTab({ Title = "Delete", Icon = "trash" })

-- Discover eggs first
task.wait(2)
local eggList = Eggs.getList()

-- Main Tab
MainTab:AddButton({
    Title = "Teleport to Lucky Event",
    Callback = teleportToLucky
})

MainTab:AddDropdown("EggSelect", {
    Title = "Target Egg",
    Values = eggList,
    Multi = false,
    Default = eggList[1] or "Basic"
}):OnChanged(function(v)
    _G.LuckySettings.TargetEgg = v
    Fluent:Notify({Title="Egg Selected", Content=v, Duration=2})
end)

MainTab:AddToggle("AutoHatch", {
    Title = "Auto Hatch",
    Default = false
}):OnChanged(function(v)
    Eggs.toggle(v)
    Fluent:Notify({Title="Auto Hatch", Content=v and "ON" or "OFF", Duration=2})
end)

MainTab:AddSlider("HatchDelay", {
    Title = "Hatch Delay",
    Min = 0.05,
    Max = 1,
    Default = 0.1,
    Rounding = 2
}):OnChanged(function(v)
    _G.LuckySettings.HatchDelay = v
end)

-- Delete Tab
DeleteTab:AddToggle("AutoDelete", {
    Title = "Auto Delete",
    Default = false
}):OnChanged(function(v)
    AutoDelete.toggle(v)
    Fluent:Notify({Title="Auto Delete", Content=v and "ON" or "OFF", Duration=2})
end)

DeleteTab:AddToggle("KeepGolden", {
    Title = "Keep Golden Pets",
    Default = true
}):OnChanged(function(v) _G.LuckySettings.KeepGolden = v end)

DeleteTab:AddToggle("KeepRainbow", {
    Title = "Keep Rainbow Pets",
    Default = true
}):OnChanged(function(v) _G.LuckySettings.KeepRainbow = v end)

DeleteTab:AddParagraph({Title = "Delete Rarities:", Content = "Select which rarities to auto-delete"})

for _, rarity in pairs({"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}) do
    local default = (rarity == "Common" or rarity == "Uncommon")
    DeleteTab:AddToggle("Delete"..rarity, {
        Title = rarity,
        Default = default
    }):OnChanged(function(v)
        _G.LuckySettings.SelectedRarities[rarity] = v
    end)
end

-- Set default egg
if eggList[1] then
    _G.LuckySettings.TargetEgg = eggList[1]
end

Fluent:Notify({Title="Lucky Event Hatcher", Content="Loaded! Select egg and start hatching.", Duration=5})

print("═══════════════════════════════════════")
print("  LUCKY EVENT HATCHER - LIGHTWEIGHT")
print("  • Auto Hatch (x1/x3/x8 detected)")
print("  • Auto Delete by Rarity")
print("  • TP to Lucky Event")
print("═══════════════════════════════════════")
