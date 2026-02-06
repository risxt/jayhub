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
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ============================================
-- [SEC-ANTIAFK] SUPER ANTI-AFK V2
-- ============================================
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    print("[ANTIAFK] Loading Aggressive Anti-AFK...")
    
    -- 1. Deteksi Idle (Saat Roblox mendeteksi diam 20 menit)
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
        print("[ANTIAFK] Idled Triggered - Resetting Timer")
    end)
    
    -- 2. Pulse Loop (Memaksa input setiap 60 detik sebagai cadangan)
    task.spawn(function()
        while true do
            task.wait(60)
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
    
    -- 3. Auto Rejoin (Jika terkena Kick/Disconnect)
    task.spawn(function()
        local Gui = game:GetService("CoreGui")
        local Teleport = game:GetService("TeleportService")
        Gui.ChildAdded:Connect(function(child)
            if child.Name == "RobloxPromptGui" then
                warn("[ANTIAFK] Disconnected! Rejoining in 5s...")
                task.wait(5)
                Teleport:Teleport(game.PlaceId, Player)
            end
        end)
    end)
end)

-- Settings
_G.LuckySettings = {
    AutoHatch = false,
    AutoDelete = false,
    AutoCraftKeys = false,
    AutoGacha = false,
    TargetEgg = nil,
    HatchDelay = 0.1,
    GachaAmount = 1,
    KeepGolden = true,
    KeepRainbow = true,
    CraftRarities = {
        Legendary = true,
        Mythic = false
    },
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
        
        -- Check all egg folders including Lucky Event
        for _, folderName in pairs({"Eggs", "RobuxEggs", "LuckyEggs", "EventEggs", "LuckyEventEggs"}) do
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
        
        -- Also check for eggs in Zones/LuckyEvent area
        local Zones = Workspace:FindFirstChild("Zones")
        if Zones then
            local LuckyZone = Zones:FindFirstChild("LuckyEvent") or Zones:FindFirstChild("Lucky Event")
            if LuckyZone then
                for _, child in pairs(LuckyZone:GetDescendants()) do
                    if child:IsA("Model") and string.find(child.Name:lower(), "egg") then
                        if not table.find(_discoveredEggs, child.Name) then
                            table.insert(_discoveredEggs, child.Name)
                        end
                    end
                end
            end
        end
        
        -- Hardcode Lucky Event eggs jika tidak ditemukan
        local luckyEggs = {"Lucky Egg", "Super Lucky Egg", "Mega Lucky Egg", "Ultra Lucky Egg", "Shamrock Egg", "Clover Egg", "Rainbow Egg"}
        for _, eggName in pairs(luckyEggs) do
            if not table.find(_discoveredEggs, eggName) then
                table.insert(_discoveredEggs, eggName)
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
-- [MODULE] AUTO CRAFT KEYS
-- ============================================
local CraftKeys = {}
do
    local _craftThread = nil
    local _isRunning = false
    local _craftDelay = 1
    
    function CraftKeys.craft(rarity)
        if Network then
            pcall(function()
                Network:InvokeServer("CraftLuckyBlockKey", rarity or "Legendary", "Galaxy")
            end)
        end
    end
    
    function CraftKeys.start()
        if _isRunning then return end
        _isRunning = true
        
        _craftThread = task.spawn(function()
            while _isRunning and _G.LuckySettings.AutoCraftKeys do
                local rarities = _G.LuckySettings.CraftRarities or {}
                for rarity, enabled in pairs(rarities) do
                    if enabled then
                        CraftKeys.craft(rarity)
                        task.wait(_craftDelay)
                    end
                end
                task.wait(0.5)
            end
            _isRunning = false
        end)
    end
    
    function CraftKeys.stop()
        _isRunning = false
        if _craftThread then
            pcall(function() task.cancel(_craftThread) end)
            _craftThread = nil
        end
    end
    
    function CraftKeys.toggle(enabled)
        _G.LuckySettings.AutoCraftKeys = enabled
        if enabled then CraftKeys.start() else CraftKeys.stop() end
    end
end

-- ============================================
-- [MODULE] GALAXY GACHA
-- ============================================
local GalaxyGacha = {}
do
    local _gachaThread = nil
    local _isRunning = false
    local _gachaDelay = 0.5
    
    function GalaxyGacha.open(amount)
        if Network then
            pcall(function()
                Network:InvokeServer("OpenLuckyBlock", amount or 1, "Galaxy")
            end)
        end
    end
    
    function GalaxyGacha.start()
        if _isRunning then return end
        _isRunning = true
        
        _gachaThread = task.spawn(function()
            while _isRunning and _G.LuckySettings.AutoGacha do
                local amount = _G.LuckySettings.GachaAmount or 1
                GalaxyGacha.open(amount)
                task.wait(_gachaDelay)
            end
            _isRunning = false
        end)
    end
    
    function GalaxyGacha.stop()
        _isRunning = false
        if _gachaThread then
            pcall(function() task.cancel(_gachaThread) end)
            _gachaThread = nil
        end
    end
    
    function GalaxyGacha.toggle(enabled)
        _G.LuckySettings.AutoGacha = enabled
        if enabled then GalaxyGacha.start() else GalaxyGacha.stop() end
    end
end

-- ============================================
-- [MODULE] TELEPORT
-- ============================================
local function teleportToLucky()
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = LuckyEventCFrame
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
    Size = UDim2.fromOffset(500, 420),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local MainTab = Window:AddTab({ Title = "Main", Icon = "egg" })
local GalaxyTab = Window:AddTab({ Title = "Galaxy", Icon = "star" })
local KeysTab = Window:AddTab({ Title = "Keys", Icon = "key" })
local DeleteTab = Window:AddTab({ Title = "Delete", Icon = "trash" })

-- Discover eggs first
task.wait(2)
local eggList = Eggs.getList()

-- ========== MAIN TAB ==========
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
end)

MainTab:AddToggle("AutoHatch", {
    Title = "Auto Hatch",
    Default = false
}):OnChanged(function(v)
    Eggs.toggle(v)
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

-- ========== GALAXY TAB ==========
GalaxyTab:AddToggle("AutoGacha", {
    Title = "Auto Galaxy Gacha",
    Default = false
}):OnChanged(function(v)
    GalaxyGacha.toggle(v)
end)

GalaxyTab:AddDropdown("GachaAmount", {
    Title = "Gacha Amount",
    Values = {"1", "3", "10"},
    Multi = false,
    Default = "1"
}):OnChanged(function(v)
    _G.LuckySettings.GachaAmount = tonumber(v) or 1
end)

-- ========== KEYS TAB ==========
KeysTab:AddToggle("AutoCraftKeys", {
    Title = "Auto Craft Keys",
    Default = false
}):OnChanged(function(v)
    CraftKeys.toggle(v)
end)

KeysTab:AddDropdown("CraftRarities", {
    Title = "Craft Key Rarities (Multi-Select)",
    Values = {"Legendary", "Mythic"},
    Multi = true,
    Default = {"Legendary"}
}):OnChanged(function(v)
    _G.LuckySettings.CraftRarities = v
end)

-- ========== DELETE TAB ==========
DeleteTab:AddToggle("AutoDelete", {
    Title = "Auto Delete",
    Default = false
}):OnChanged(function(v)
    AutoDelete.toggle(v)
end)

DeleteTab:AddToggle("KeepGolden", {
    Title = "Keep Golden Pets",
    Default = true
}):OnChanged(function(v) _G.LuckySettings.KeepGolden = v end)

DeleteTab:AddToggle("KeepRainbow", {
    Title = "Keep Rainbow Pets",
    Default = true
}):OnChanged(function(v) _G.LuckySettings.KeepRainbow = v end)

DeleteTab:AddDropdown("DeleteRarities", {
    Title = "Delete Rarities (Multi-Select)",
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"},
    Multi = true,
    Default = {"Common", "Uncommon"}
}):OnChanged(function(v)
    -- Convert table to settings format
    _G.LuckySettings.SelectedRarities = {
        Common = v["Common"] or false,
        Uncommon = v["Uncommon"] or false,
        Rare = v["Rare"] or false,
        Epic = v["Epic"] or false,
        Legendary = v["Legendary"] or false,
        Mythic = v["Mythic"] or false
    }
end)

-- Set default egg
if eggList[1] then
    _G.LuckySettings.TargetEgg = eggList[1]
end

-- ========== SETTINGS TAB ==========
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("LuckyEventHatcher")
SaveManager:SetFolder("LuckyEventHatcher/configs")

InterfaceManager:BuildInterfaceSection(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

-- Auto-load config if exists
SaveManager:LoadAutoloadConfig()

-- ============================================
-- MOBILE DRAG BUTTON
-- ============================================
local MobileButton = Instance.new("ScreenGui")
MobileButton.Name = "LuckyMobileBtn"
MobileButton.ResetOnSpawn = false
MobileButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MobileButton.Parent = game:GetService("CoreGui")

local DragButton = Instance.new("ImageButton")
DragButton.Name = "DragBtn"
DragButton.Size = UDim2.new(0, 50, 0, 50)
DragButton.Position = UDim2.new(0, 10, 0.5, -25)
DragButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
DragButton.BackgroundTransparency = 0.2
DragButton.Image = "rbxassetid://6031075938" -- Clover/Lucky icon
DragButton.ImageColor3 = Color3.fromRGB(0, 255, 100)
DragButton.BorderSizePixel = 0
DragButton.Parent = MobileButton

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0)
Corner.Parent = DragButton

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 200, 80)
Stroke.Thickness = 2
Stroke.Parent = DragButton

-- Draggable logic
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

DragButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = DragButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

DragButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        DragButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Toggle window on tap
local windowVisible = true
DragButton.MouseButton1Click:Connect(function()
    windowVisible = not windowVisible
    Window:Minimize()
end)

print("═══════════════════════════════════════")
print("  LUCKY EVENT HATCHER - LIGHTWEIGHT")
print("  • Auto Hatch (x1/x3/x8 detected)")
print("  • Auto Delete by Rarity")
print("  • Auto Craft Keys (Multi-Rarity)")
print("  • Auto Galaxy Gacha")
print("  • Save/Load Config")
print("  • Mobile Drag Button")
print("  • TP to Lucky Event")
print("═══════════════════════════════════════")
