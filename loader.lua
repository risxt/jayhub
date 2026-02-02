--[[
    ████████╗ █████╗ ██████╗ ███████╗██╗███╗   ███╗
    ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║████╗ ████║
       ██║   ███████║██████╔╝███████╗██║██╔████╔██║
       ██║   ██╔══██║██╔═══╝ ╚════██║██║██║╚██╔╝██║
       ██║   ██║  ██║██║     ███████║██║██║ ╚═╝ ██║
       ╚═╝   ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝╚═╝     ╚═╝
    
    TapSim Hub v2.0 - Full Feature Edition
    Roblox Simulator Automation
    
    ═══════════════════════════════════════════════
    FEATURES:
    ═══════════════════════════════════════════════
    [MAIN]
    • Auto Farm - Super fast clicking
    • Smart Rebirth - Nabung strategy (highest tier first)
    • Auto Rank Reward - Claim every 5 minutes
    
    [ISLANDS]
    • Auto Island Unlock - Discover & unlock all
    • GPS Teleport - Hardcoded coordinates (16 locations)
    
    [UPGRADES]
    • Auto Upgrades - All stats upgrade loop
    • Auto Jump Upgrade - Separate jump boost
    
    [EGGS]
    • Auto Hatch - Select egg, amount, speed
    • Speedometer - Eggs/second display
    
    [SYSTEM]
    • Super Anti-AFK (VirtualUser)
    • Auto Rejoin (PS Friendly)
    • Config Save/Load
    ═══════════════════════════════════════════════
    
    Executor: Potassium (or any Luau executor)
    Minimize: RightCtrl
]]

-- ============================================
-- ANTI-DUPLICATE EXECUTION
-- ============================================
if _G.TapSimLoaded then
    warn("[TapSim] Script already loaded! Destroying previous instance...")
    if _G.TapSimUI then
        pcall(function() _G.TapSimUI:Destroy() end)
    end
end
_G.TapSimLoaded = true

-- ============================================
-- GLOBAL SETTINGS (All features config)
-- ============================================
_G.Settings = _G.Settings or {}

-- Main Features
_G.Settings.AutoFarm = false
_G.Settings.AutoRebirth = false
_G.Settings.AutoRankReward = false
_G.Settings.FarmDelay = 0.01
_G.Settings.NabungTime = 25

-- Islands
_G.Settings.AutoIsland = false

-- Upgrades
_G.Settings.AutoUpgrade = false
_G.Settings.AutoJump = false
_G.Settings.UpgradeDelay = 3

-- Eggs
_G.Settings.AutoHatch = false
_G.Settings.TargetEgg = "Basic"
_G.Settings.HatchAmount = 1
_G.Settings.HatchDelay = 0.5

-- Pets
_G.Settings.AutoEquip = false

-- Delete Settings (Multi-Select)
_G.DeleteSettings = {
    Enabled = false,
    SelectedRarities = {},
    KeepGolden = true,
    KeepRainbow = true,
    KeepHuge = true,
}

-- Smart Save Settings
_G.SmartSave = {
    Enabled = false,
    Threshold = 0.9
}

-- Auto Best Island
_G.AutoGoBest = false

-- Webhook Settings
_G.WebhookSettings = {
    Enabled = false,
    Url = "",
    MinRarity = "Legendary"
}

-- ============================================
-- SUPER ANTI-AFK V2 (AGGRESSIVE)
-- ============================================
print("[TapSim] Loading Aggressive Anti-AFK...")

local VirtualUser = game:GetService("VirtualUser")
local Player = game:GetService("Players").LocalPlayer

-- React to Idle detection
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
    print("[Anti-AFK] Prevented Sleep Mode")
end)

-- BRUTE FORCE: Loop every 60 seconds
task.spawn(function()
    while true do
        task.wait(60)
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ============================================
-- AUTO REJOIN (SAFE MODE - PS FRIENDLY)
-- ============================================
print("[TapSim] Loading Safe Auto-Rejoin (PS Friendly)...")

task.spawn(function()
    local Gui = game:GetService("CoreGui")
    local Teleport = game:GetService("TeleportService")
    local Plr = game:GetService("Players").LocalPlayer
    
    -- Only react to actual disconnect screens
    Gui.ChildAdded:Connect(function(child)
        if child.Name == "RobloxPromptGui" then
            print("[Auto-Rejoin] DISCONNECT DETECTED! Rejoining in 5s...")
            task.wait(5)
            -- Simple rejoin - works for both PS and public
            Teleport:Teleport(game.PlaceId, Plr)
        end
    end)
end)

print("[TapSim] Anti-AFK + Auto-Rejoin loaded - safe to AFK 24/7")


-- ============================================
-- CORE MODULES (Inline for single-file execution)
-- ============================================

-- [[ REMOTES MODULE ]]
local Remotes = {}
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local _remoteFolder, _eventsFolder, _functionsFolder = nil, nil, nil
    
    Remotes.INDEX = {
        FARM = 23,
        UNLOCK_ISLAND = 31,
        UPGRADE_JUMP = 34,
        RANK_REWARD = 37,
        REBIRTH = 38,
        EGG_HATCH = 44,
        UPGRADE_STATS = 106
    }
    
    Remotes.UPGRADES = {
        "RebirthButtons", "FreeAutoClicker", "HatchSpeed",
        "CriticalChance", "GoldenLuck", "AutoClickerSpeed", "ClickMultiplier"
    }
    
    function Remotes.getRemoteFolder()
        if _remoteFolder then return _remoteFolder end
        for _, child in pairs(ReplicatedStorage:GetChildren()) do
            if child:IsA("Folder") and child:FindFirstChild("Events") and child:FindFirstChild("Functions") then
                _remoteFolder = child
                _eventsFolder = child:FindFirstChild("Events")
                _functionsFolder = child:FindFirstChild("Functions")
                return _remoteFolder
            end
        end
        return nil
    end
    
    function Remotes.getEvent(index)
        if not _eventsFolder then Remotes.getRemoteFolder() end
        if _eventsFolder then
            local children = _eventsFolder:GetChildren()
            if children[index] then return children[index] end
        end
        return nil
    end
    
    function Remotes.getFunction(index)
        if not _functionsFolder then Remotes.getRemoteFolder() end
        if _functionsFolder then
            local children = _functionsFolder:GetChildren()
            if children[index] then return children[index] end
        end
        return nil
    end
end

-- [[ FARM MODULE ]]
local Farm = {}
do
    local _farmThread, _isRunning = nil, false
    
    function Farm.start()
        if _isRunning then return end
        _isRunning = true
        _farmThread = task.spawn(function()
            local farmRemote = Remotes.getEvent(Remotes.INDEX.FARM)
            if not farmRemote then
                warn("[TapSim] Farm remote not found!")
                _isRunning = false
                return
            end
            while _isRunning and _G.Settings.AutoFarm do
                pcall(function() farmRemote:FireServer(true, nil, false) end)
                task.wait(_G.Settings.FarmDelay or 0.01)
            end
            _isRunning = false
        end)
    end
    
    function Farm.stop()
        _isRunning = false
        if _farmThread then task.cancel(_farmThread) _farmThread = nil end
    end
    
    function Farm.toggle(enabled)
        _G.Settings.AutoFarm = enabled
        if enabled then Farm.start() else Farm.stop() end
    end
end

-- [[ REBIRTH MODULE ]]
local Rebirth = {}
do
    local _rebirthThread, _isRunning = nil, false
    
    function Rebirth.attemptRebirth()
        local rebirthRemote = Remotes.getFunction(Remotes.INDEX.REBIRTH)
        if not rebirthRemote then return false, nil end
        for tier = 4, 1, -1 do
            local success, result = pcall(function() return rebirthRemote:InvokeServer(tier, nil) end)
            if success and result then return true, tier end
            task.wait(0.3)
        end
        return false, nil
    end
    
    function Rebirth.start()
        if _isRunning then return end
        _isRunning = true
        _rebirthThread = task.spawn(function()
            while _isRunning and _G.Settings.AutoRebirth do
                local nabungTime = _G.Settings.NabungTime or 25
                for i = 1, nabungTime do
                    if not _isRunning or not _G.Settings.AutoRebirth then break end
                    task.wait(1)
                end
                if _isRunning and _G.Settings.AutoRebirth then
                    Rebirth.attemptRebirth()
                end
                task.wait(1)
            end
            _isRunning = false
        end)
    end
    
    function Rebirth.stop()
        _isRunning = false
        if _rebirthThread then task.cancel(_rebirthThread) _rebirthThread = nil end
    end
    
    function Rebirth.toggle(enabled)
        _G.Settings.AutoRebirth = enabled
        if enabled then Rebirth.start() else Rebirth.stop() end
    end
    
    function Rebirth.forceRebirth()
        return Rebirth.attemptRebirth()
    end
end

-- [[ ISLANDS MODULE ]]
local Islands = {}
do
    local _islandThread, _isRunning = nil, false
    local _discoveredIslands = {}
    
    -- HARDCODED COORDINATE DATABASE
    Islands.Locations = {
        ["Forest"]      = CFrame.new(-235, 1225, 269),
        ["Winter"]      = CFrame.new(-258, 2546, 354),
        ["Desert"]      = CFrame.new(-95, 3510, 336),
        ["Jungle"]      = CFrame.new(-304, 4421, 420),
        ["Heaven"]      = CFrame.new(-397, 5847, 266),
        ["Dojo"]        = CFrame.new(-402, 7626, 385),
        ["Volcano"]     = CFrame.new(-281, 9192, 146),
        ["Candy"]       = CFrame.new(-202, 10969, 399),
        ["Atlantis"]    = CFrame.new(-432, 12950, 266),
        ["Space"]       = CFrame.new(-278, 15334, 440),
        -- World 2 Areas
        ["World 2"]     = CFrame.new(1279, 651, -13267),
        ["Kryo"]        = CFrame.new(1387, 1741, -13233),
        ["Magma"]       = CFrame.new(1430, 3120, -12970),
        ["Celestial"]   = CFrame.new(1260, 4164, -12939),
        ["Holographic"] = CFrame.new(1427, 5354, -12718),
        ["Lunar"]       = CFrame.new(1472, 6855, -12914)
    }
    
    function Islands.getLocationList()
        local names = {}
        for name, _ in pairs(Islands.Locations) do
            table.insert(names, name)
        end
        table.sort(names)
        return names
    end
    function Islands.discoverIslands()
        _discoveredIslands = {}
        local Zones = game:GetService("Workspace"):FindFirstChild("Zones")
        if not Zones then return _discoveredIslands end
        
        for _, folderName in pairs({"Portals", "OldPortals"}) do
            local folder = Zones:FindFirstChild(folderName)
            if folder then
                for _, portal in pairs(folder:GetChildren()) do
                    local exists = false
                    for _, name in pairs(_discoveredIslands) do
                        if name == portal.Name then exists = true break end
                    end
                    if not exists then table.insert(_discoveredIslands, portal.Name) end
                end
            end
        end
        return _discoveredIslands
    end
    
    function Islands.getDiscoveredIslands()
        if #_discoveredIslands == 0 then Islands.discoverIslands() end
        return _discoveredIslands
    end
    
    function Islands.unlockAll()
        local islands = Islands.getDiscoveredIslands()
        local unlockRemote = Remotes.getFunction(Remotes.INDEX.UNLOCK_ISLAND)
        if not unlockRemote then return end
        for _, islandName in pairs(islands) do
            pcall(function() unlockRemote:InvokeServer(islandName) end)
            task.wait(0.2)
        end
    end
    
    function Islands.start()
        if _isRunning then return end
        _isRunning = true
        Islands.discoverIslands()
        _islandThread = task.spawn(function()
            while _isRunning and _G.Settings.AutoIsland do
                Islands.unlockAll()
                for i = 1, 30 do
                    if not _isRunning or not _G.Settings.AutoIsland then break end
                    task.wait(1)
                end
            end
            _isRunning = false
        end)
    end
    
    function Islands.stop()
        _isRunning = false
        if _islandThread then task.cancel(_islandThread) _islandThread = nil end
    end
    
    function Islands.toggle(enabled)
        _G.Settings.AutoIsland = enabled
        if enabled then Islands.start() else Islands.stop() end
    end
    
    function Islands.teleportTo(islandName)
        local Plr = game:GetService("Players").LocalPlayer
        local Char = Plr.Character
        if not Char or not Char:FindFirstChild("HumanoidRootPart") then 
            warn("[TapSim] Cannot teleport - no character")
            return false 
        end
        
        local HRP = Char.HumanoidRootPart
        local Coordinate = Islands.Locations[islandName]
        
        if Coordinate then
            print("[TapSim] Teleporting to: " .. islandName)
            HRP.Anchored = true
            HRP.CFrame = Coordinate
            task.wait(0.5)
            HRP.Anchored = false
            return true
        else
            warn("[TapSim] Coordinate not found: " .. islandName)
            return false
        end
    end
end

-- [[ UPGRADES MODULE ]]
local Upgrades = {}
do
    local _upgradeThread, _isRunning = nil, false
    
    function Upgrades.upgradeAllStats()
        local upgradeRemote = Remotes.getFunction(Remotes.INDEX.UPGRADE_STATS)
        if not upgradeRemote then return end
        for _, statName in pairs(Remotes.UPGRADES) do
            pcall(function() upgradeRemote:InvokeServer(statName, nil) end)
            task.wait(0.2)
        end
    end
    
    function Upgrades.upgradeJump()
        local jumpRemote = Remotes.getFunction(Remotes.INDEX.UPGRADE_JUMP)
        if jumpRemote then pcall(function() jumpRemote:InvokeServer("Main") end) end
    end
    
    function Upgrades.start()
        if _isRunning then return end
        _isRunning = true
        _upgradeThread = task.spawn(function()
            while _isRunning and (_G.Settings.AutoUpgrade or _G.Settings.AutoJump) do
                if _G.Settings.AutoUpgrade then Upgrades.upgradeAllStats() end
                if _G.Settings.AutoJump then Upgrades.upgradeJump() end
                local delay = _G.Settings.UpgradeDelay or 3
                for i = 1, delay do
                    if not _isRunning then break end
                    task.wait(1)
                end
            end
            _isRunning = false
        end)
    end
    
    function Upgrades.stop()
        _isRunning = false
        if _upgradeThread then task.cancel(_upgradeThread) _upgradeThread = nil end
    end
    
    function Upgrades.toggleUpgrade(enabled)
        _G.Settings.AutoUpgrade = enabled
        if enabled or _G.Settings.AutoJump then
            if not _isRunning then Upgrades.start() end
        else
            Upgrades.stop()
        end
    end
    
    function Upgrades.toggleJump(enabled)
        _G.Settings.AutoJump = enabled
        if enabled or _G.Settings.AutoUpgrade then
            if not _isRunning then Upgrades.start() end
        else
            Upgrades.stop()
        end
    end
end

-- [[ REWARDS MODULE ]]
local Rewards = {}
do
    local _rewardThread = nil
    
    function Rewards.claimRankReward()
        local rewardRemote = Remotes.getFunction(Remotes.INDEX.RANK_REWARD)
        if not rewardRemote then 
            warn("[TapSim] Rank reward remote not found!")
            return false 
        end
        
        local success = pcall(function()
            rewardRemote:InvokeServer()
        end)
        
        if success then
            print("[TapSim] Attempted to claim rank reward")
        end
        return success
    end
    
    function Rewards.startAutoReward()
        if _rewardThread then return end
        _rewardThread = task.spawn(function()
            while true do
                if _G.Settings.AutoRankReward then
                    Rewards.claimRankReward()
                end
                -- Check every 5 minutes (300 seconds) - rewards have long cooldowns
                task.wait(300)
            end
        end)
    end
    
    function Rewards.toggle(enabled)
        _G.Settings.AutoRankReward = enabled
        if enabled then
            -- Claim immediately when enabled
            Rewards.claimRankReward()
        end
    end
end

-- Start rewards loop in background
Rewards.startAutoReward()

-- [[ PETS MODULE (SIGNAL METHOD) ]]
local Pets = {}
do
    local _equipThread = nil
    local _signal = nil
    
    function Pets.getSignal()
        if not _signal then
            local RS = game:GetService("ReplicatedStorage")
            local modulesFolder = RS:FindFirstChild("Modules")
            if modulesFolder and modulesFolder:FindFirstChild("Signal") then
                _signal = require(modulesFolder.Signal)
            end
        end
        return _signal
    end
    
    function Pets.equipBest()
        local sig = Pets.getSignal()
        if not sig then 
            warn("[TapSim] Signal module not found!")
            return false 
        end
        
        local success = pcall(function()
            sig.Fire("EquipBest")
        end)
        
        if success then
            print("[TapSim] Equip Best: Signal fired")
            return true
        end
        return false
    end
    
    function Pets.startAutoEquip()
        if _equipThread then return end
        _equipThread = task.spawn(function()
            while true do
                if _G.Settings.AutoEquip then
                    Pets.equipBest()
                end
                task.wait(5)
            end
        end)
    end
    
    function Pets.toggle(enabled)
        _G.Settings.AutoEquip = enabled
        if enabled then
            Pets.equipBest()
        end
    end
end

-- Start auto equip loop
Pets.startAutoEquip()

-- [[ AUTO DELETE MODULE (DROPDOWN EDITION) ]]
local AutoDelete = {}
do
    local _deleteThread = nil
    local _network = nil
    local _replication = nil
    local _petStats = nil
    
    -- Rarity ranking (lower = more trash)
    local RarityRank = {
        ["None"] = 0,
        ["Common"] = 1,
        ["Uncommon"] = 2,
        ["Rare"] = 3,
        ["Epic"] = 4,
        ["Legendary"] = 5,
        ["Mythic"] = 6,
        ["Secret"] = 99
    }
    
    AutoDelete.RarityList = {"None", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
    
    function AutoDelete.getModules()
        if not _network then
            local RS = game:GetService("ReplicatedStorage")
            local modules = RS:FindFirstChild("Modules")
            local gameFolder = RS:FindFirstChild("Game")
            
            if modules and modules:FindFirstChild("Network") then
                _network = require(modules.Network)
            end
            if gameFolder and gameFolder:FindFirstChild("Replication") then
                _replication = require(gameFolder.Replication)
            end
            if gameFolder and gameFolder:FindFirstChild("PetStats") then
                _petStats = require(gameFolder.PetStats)
            end
        end
        return _network, _replication, _petStats
    end
    
    function AutoDelete.runDelete()
        local net, rep, stats = AutoDelete.getModules()
        if not net or not rep then return 0 end
        if not rep.Data or not rep.Data.Pets then return 0 end
        
        local deletedCount = 0
        
        for petId, petData in pairs(rep.Data.Pets) do
            if not _G.DeleteSettings.Enabled then break end
            
            if not petData.Equipped and not petData.Locked then
                local shouldDelete = false
                
                -- Get Rarity
                local rarity = "Common"
                if stats then
                    pcall(function()
                        rarity = stats:GetRarity(petData.Name)
                    end)
                end
                
                -- Multi-select logic: delete if rarity is in selected list
                if _G.DeleteSettings.SelectedRarities[rarity] then
                    shouldDelete = true
                end
                
                -- Safety filters (whitelist)
                if petData.Tier == "Golden" and _G.DeleteSettings.KeepGolden then shouldDelete = false end
                if petData.Tier == "Rainbow" and _G.DeleteSettings.KeepRainbow then shouldDelete = false end
                if rarity == "Secret" then shouldDelete = false end
                if petData.Huge or petData.Exclusive then shouldDelete = false end
                
                -- Execute delete
                if shouldDelete then
                    pcall(function()
                        net:InvokeServer("DeletePet", petId)
                    end)
                    deletedCount = deletedCount + 1
                    task.wait(0.1)
                end
            end
        end
        
        return deletedCount
    end
    
    function AutoDelete.start()
        if _deleteThread then return end
        _deleteThread = task.spawn(function()
            while true do
                if _G.DeleteSettings.Enabled then
                    pcall(AutoDelete.runDelete)
                end
                task.wait(1)
            end
        end)
    end
end

-- Start auto delete loop
AutoDelete.start()

-- [[ SMART SAVE MODULE ]]
local SmartSave = {}
do
    local _replication = nil
    local _islandUpgrades = nil
    
    function SmartSave.getModules()
        if not _replication then
            local RS = game:GetService("ReplicatedStorage")
            local gameFolder = RS:FindFirstChild("Game")
            
            if gameFolder then
                if gameFolder:FindFirstChild("Replication") then
                    _replication = require(gameFolder.Replication)
                end
                if gameFolder:FindFirstChild("IslandUpgrades") then
                    _islandUpgrades = require(gameFolder.IslandUpgrades)
                end
            end
        end
        return _replication, _islandUpgrades
    end
    
    function SmartSave.isSafeToSpend()
        if not _G.SmartSave.Enabled then return true end
        
        local rep, islands = SmartSave.getModules()
        if not rep or not islands then return true end
        
        local currentClicks = 0
        local nextIslandPrice = 0
        
        pcall(function()
            currentClicks = rep.Data.Clicks or 0
        end)
        
        pcall(function()
            nextIslandPrice = islands:GetPrice()
        end)
        
        if nextIslandPrice > 0 then
            local threshold = nextIslandPrice * _G.SmartSave.Threshold
            if currentClicks >= threshold then
                return false
            end
        end
        
        return true
    end
end

-- [[ AUTO BEST ISLAND MODULE ]]
local AutoBestIsland = {}
do
    local _thread = nil
    local _replication = nil
    
    -- Island order (lowest to highest) - matches Islands.Locations
    local IslandOrder = {
        "Forest", "Winter", "Desert", "Jungle", "Heaven",
        "Dojo", "Volcano", "Candy", "Atlantis", "Space",
        "Kryo", "Magma", "Celestial", "Holographic", "Lunar"
    }
    
    function AutoBestIsland.getReplication()
        if not _replication then
            local RS = game:GetService("ReplicatedStorage")
            local gameFolder = RS:FindFirstChild("Game")
            if gameFolder and gameFolder:FindFirstChild("Replication") then
                _replication = require(gameFolder.Replication)
            end
        end
        return _replication
    end
    
    function AutoBestIsland.getBestIsland()
        local rep = AutoBestIsland.getReplication()
        if not rep or not rep.Data then return "Forest" end
        
        -- Islands are stored in rep.Data.Portals (e.g., rep.Data.Portals.Jungle = true)
        local portals = rep.Data.Portals or {}
        local bestIsland = "Forest"
        
        for _, name in ipairs(IslandOrder) do
            if portals[name] == true then
                bestIsland = name
            end
        end
        
        return bestIsland
    end
    
    function AutoBestIsland.teleportToBest()
        local bestIsland = AutoBestIsland.getBestIsland()
        local LP = game.Players.LocalPlayer
        
        -- Use Islands.Locations coords
        local targetCFrame = Islands.Locations[bestIsland]
        if targetCFrame and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = targetCFrame
            print("[TapSim] Teleported to best island: " .. bestIsland)
            return true
        end
        return false
    end
    
    function AutoBestIsland.start()
        if _thread then return end
        _thread = task.spawn(function()
            while true do
                if _G.AutoGoBest then
                    pcall(AutoBestIsland.teleportToBest)
                end
                task.wait(10)
            end
        end)
    end
    
    function AutoBestIsland.toggle(enabled)
        _G.AutoGoBest = enabled
        if enabled then
            AutoBestIsland.teleportToBest()
        end
    end
end

-- Start auto best island loop
AutoBestIsland.start()

-- [[ AUTO CRAFT MODULE (FINAL STABLE - STRICT COUNT) ]]
local AutoCraft = {}
do
    local _goldenEnabled = false
    local _rainbowEnabled = false
    local _claimEnabled = true
    local _delay = 0.5
    local _savedFarmingPos = nil
    
    local RS = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    
    local Network, Replication
    pcall(function()
        Network = require(RS.Modules.Network)
        Replication = require(RS.Game.Replication)
    end)
    
    -- Teleport to CFrame
    local function TeleportTo(cframe)
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = cframe
        end
    end
    
    -- Find machine part
    local function FindMachinePart(machineName)
        local target = workspace:FindFirstChild(machineName, true) or workspace:FindFirstChild(machineName:gsub("Machine", " Machine"), true)
        if target then
            if target:IsA("Model") then
                return target:FindFirstChild("Pad") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
            elseif target:IsA("BasePart") then
                return target
            end
        end
        return nil
    end
    
    -- Check if near any machine
    local function IsNearMachine()
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return false end
        local myPos = LP.Character.HumanoidRootPart.Position
        local goldenM = FindMachinePart("GoldenMachine")
        local rainbowM = FindMachinePart("RainbowMachine")
        if goldenM and (myPos - goldenM.Position).Magnitude < 50 then return true end
        if rainbowM and (myPos - rainbowM.Position).Magnitude < 50 then return true end
        return false
    end
    
    -- Auto Claim Rainbow
    local function CheckAndClaim()
        if not _claimEnabled or not Replication or not Replication.Data then return end
        local craftingPets = Replication.Data.CraftingPets
        if craftingPets and craftingPets.Rainbow then
            local currentTime = workspace:GetServerTimeNow()
            for id, data in pairs(craftingPets.Rainbow) do
                if data.EndTime and (data.EndTime - currentTime) <= 0 then
                    pcall(function() Network:InvokeServer("ClaimRainbow", id) end)
                end
            end
        end
    end
    
    -- STRICT COUNT: Check if there's at least one group with 5+ pets
    local function HasCraftableBatch(tier)
        if not Replication or not Replication.Data or not Replication.Data.Pets then return false end
        local counts = {}
        for _, pet in pairs(Replication.Data.Pets) do
            if not pet.Equipped and not pet.Locked and pet.Tier == tier then
                counts[pet.Name] = (counts[pet.Name] or 0) + 1
                if counts[pet.Name] >= 5 then return true end
            end
        end
        return false
    end
    
    -- Craft Process
    local function CraftProcess()
        if not Replication or not Replication.Data or not Replication.Data.Pets then return end
        
        -- Smart Anchor: Save position only when FAR from machines
        if not IsNearMachine() and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            _savedFarmingPos = LP.Character.HumanoidRootPart.CFrame
        end
        
        -- GOLDEN: STRICT CHECK FIRST
        if _goldenEnabled and HasCraftableBatch("Normal") then
            local machine = FindMachinePart("GoldenMachine")
            if machine then
                -- Go to machine
                if not IsNearMachine() then
                    print("[AutoCraft] Found 5+ Normal -> Going to Golden Machine")
                    TeleportTo(machine.CFrame + Vector3.new(0, 3, 0))
                    task.wait(0.5)
                end
                
                -- Batch craft until empty
                while _goldenEnabled do
                    local groups = {}
                    local batch = nil
                    
                    for id, pet in pairs(Replication.Data.Pets) do
                        if not pet.Equipped and not pet.Locked and pet.Tier == "Normal" then
                            if not groups[pet.Name] then groups[pet.Name] = {} end
                            table.insert(groups[pet.Name], id)
                            if #groups[pet.Name] >= 5 then
                                batch = {groups[pet.Name][1], groups[pet.Name][2], groups[pet.Name][3], groups[pet.Name][4], groups[pet.Name][5]}
                                break
                            end
                        end
                    end
                    
                    if batch then
                        Network:InvokeServer("CraftPets", batch)
                        task.wait(_delay)
                    else
                        print("[AutoCraft] Golden done! Returning...")
                        break
                    end
                end
                
                if _savedFarmingPos then TeleportTo(_savedFarmingPos) end
                return
            end
        end
        
        -- RAINBOW: STRICT CHECK FIRST
        if _rainbowEnabled then
            local usedSlots = 0
            if Replication.Data.CraftingPets and Replication.Data.CraftingPets.Rainbow then
                for _ in pairs(Replication.Data.CraftingPets.Rainbow) do usedSlots = usedSlots + 1 end
            end
            
            if usedSlots < 3 and HasCraftableBatch("Golden") then
                local machine = FindMachinePart("RainbowMachine")
                if machine then
                    if not IsNearMachine() then
                        print("[AutoCraft] Found 5+ Golden -> Going to Rainbow Machine")
                        TeleportTo(machine.CFrame + Vector3.new(0, 3, 0))
                        task.wait(0.5)
                    end
                    
                    while _rainbowEnabled do
                        local currSlots = 0
                        if Replication.Data.CraftingPets and Replication.Data.CraftingPets.Rainbow then
                            for _ in pairs(Replication.Data.CraftingPets.Rainbow) do currSlots = currSlots + 1 end
                        end
                        if currSlots >= 3 then break end
                        
                        local groups = {}
                        local batch = nil
                        
                        for id, pet in pairs(Replication.Data.Pets) do
                            if not pet.Equipped and not pet.Locked and pet.Tier == "Golden" then
                                if not groups[pet.Name] then groups[pet.Name] = {} end
                                table.insert(groups[pet.Name], id)
                                if #groups[pet.Name] >= 5 then
                                    batch = {groups[pet.Name][1], groups[pet.Name][2], groups[pet.Name][3], groups[pet.Name][4], groups[pet.Name][5]}
                                    break
                                end
                            end
                        end
                        
                        if batch then
                            Network:InvokeServer("StartRainbow", batch)
                            task.wait(_delay)
                        else
                            print("[AutoCraft] Rainbow done! Returning...")
                            break
                        end
                    end
                    
                    if _savedFarmingPos then TeleportTo(_savedFarmingPos) end
                    return
                end
            end
        end
    end
    
    -- Toggle functions
    function AutoCraft.toggleGolden(val)
        _goldenEnabled = val
        if _goldenEnabled then
            print("[AutoCraft] Golden Started (Strict Mode)")
            task.spawn(function()
                while _goldenEnabled do
                    pcall(CheckAndClaim)
                    pcall(CraftProcess)
                    task.wait(3)
                end
            end)
        else
            print("[AutoCraft] Golden Stopped")
        end
    end
    
    function AutoCraft.toggleRainbow(val)
        _rainbowEnabled = val
        if _rainbowEnabled then
            print("[AutoCraft] Rainbow Started (Strict Mode)")
            task.spawn(function()
                while _rainbowEnabled do
                    pcall(CheckAndClaim)
                    pcall(CraftProcess)
                    task.wait(3)
                end
            end)
        else
            print("[AutoCraft] Rainbow Stopped")
        end
    end
    
    function AutoCraft.toggleClaim(val) _claimEnabled = val end
    function AutoCraft.setDelay(val) _delay = val end
end







-- [[ WEBHOOK MODULE (LITE VERSION - SIMPLE & STABLE) ]]
local Webhook = {}
do
    local _scanning = false
    local _knownPets = {}

    local RarityRank = {
        ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, 
        ["Epic"] = 4, ["Legendary"] = 5, ["Mythic"] = 6, ["Secret"] = 99
    }

    -- Load Modules
    local RS = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    
    local Replication, PetStats
    pcall(function()
        Replication = require(RS.Game.Replication)
        PetStats = require(RS.Game.PetStats)
    end)

    -- Init: Mark existing pets
    function Webhook.init()
        if Replication and Replication.Data and Replication.Data.Pets then
            for id, _ in pairs(Replication.Data.Pets) do
                _knownPets[id] = true
            end
        end
    end

    -- Send to Discord (Simple - Avatar Thumbnail)
    local function sendToDiscord(petName, petRarity, petTier)
        if _G.WebhookSettings.Url == "" then return end

        local embedColor = 16776960 -- Yellow
        if petRarity == "Mythic" then embedColor = 10038562 end
        if petRarity == "Secret" then embedColor = 0 end

        local LP = Players.LocalPlayer
        local payload = {
            embeds = {{
                title = petRarity:upper() .. " HATCHED!",
                color = embedColor,
                fields = {
                    { name = "Player", value = LP.Name, inline = false },
                    { name = "Pet Name", value = petName, inline = true },
                    { name = "Rarity", value = petRarity, inline = true },
                    { name = "Tier", value = petTier, inline = true }
                },
                thumbnail = { url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png" },
                footer = { text = "TapSim Hub" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }

        pcall(function()
            request({
                Url = _G.WebhookSettings.Url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
        
        print("[Webhook] Sent: " .. petName .. " (" .. petRarity .. ")")
    end

    -- Main Loop
    function Webhook.startLoop()
        if _scanning then return end
        _scanning = true
        
        task.spawn(function()
            task.wait(3)
            Webhook.init()
        end)

        task.spawn(function()
            while true do
                if _G.WebhookSettings.Enabled and Replication and Replication.Data and Replication.Data.Pets then
                    for id, petData in pairs(Replication.Data.Pets) do
                        if not _knownPets[id] then
                            _knownPets[id] = true
                            
                            local rarity = "Common"
                            if PetStats and PetStats.GetRarity then
                                local success, result = pcall(function()
                                    return PetStats:GetRarity(petData.Name)
                                end)
                                if success and result then
                                    rarity = result:sub(1,1):upper() .. result:sub(2):lower()
                                end
                            end
                            
                            local myRank = RarityRank[rarity] or 1
                            local targetRank = RarityRank[_G.WebhookSettings.MinRarity] or 5
                            
                            if myRank >= targetRank then
                                local tier = petData.Tier or "Normal"
                                sendToDiscord(petData.Name, rarity, tier)
                            end
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end
    
    -- Setters
    function Webhook.toggle(val) _G.WebhookSettings.Enabled = val end
    function Webhook.setUrl(val) _G.WebhookSettings.Url = val end
    function Webhook.setRarity(val) _G.WebhookSettings.MinRarity = val end
end

-- Start webhook
Webhook.startLoop()

-- [[ EGGS MODULE ]]
local Eggs = {}
local EggsHatchedPerSecond = 0 -- Speedometer counter
local EggsPerSecondDisplay = 0 -- For UI display
do
    local _eggThread, _isRunning = nil, false
    local _speedThread = nil
    local _discoveredEggs = {}
    
    function Eggs.discoverEggs()
        _discoveredEggs = {}
        local Workspace = game:GetService("Workspace")
        
        for _, folderName in pairs({"Eggs", "RobuxEggs"}) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                for _, egg in pairs(folder:GetChildren()) do
                    if egg.Name ~= "Isl Folder" and not string.find(egg.Name, "Folder") then
                        local exists = false
                        for _, name in pairs(_discoveredEggs) do
                            if name == egg.Name then exists = true break end
                        end
                        if not exists then table.insert(_discoveredEggs, egg.Name) end
                    end
                end
            end
        end
        
        table.sort(_discoveredEggs)
        return _discoveredEggs
    end
    
    function Eggs.getDiscoveredEggs()
        if #_discoveredEggs == 0 then Eggs.discoverEggs() end
        return _discoveredEggs
    end
    
    function Eggs.hatch(eggName, amount)
        local hatchRemote = Remotes.getFunction(Remotes.INDEX.EGG_HATCH)
        if not hatchRemote then return false end
        local success = pcall(function() hatchRemote:InvokeServer(eggName, amount, {}) end)
        return success
    end
    
    function Eggs.start()
        if _isRunning then return end
        _isRunning = true
        
        -- Speedometer Monitor Thread (prints every 1 second)
        _speedThread = task.spawn(function()
            while _isRunning do
                task.wait(1)
                if EggsHatchedPerSecond > 0 then
                    EggsPerSecondDisplay = EggsHatchedPerSecond
                    print("[SPEED]: " .. EggsHatchedPerSecond .. " Eggs/s (Est. " .. (EggsHatchedPerSecond * 60) .. " Eggs/min)")
                    EggsHatchedPerSecond = 0
                else
                    EggsPerSecondDisplay = 0
                end
            end
        end)
        
        -- Hatch Thread
        _eggThread = task.spawn(function()
            local hatchRemote = Remotes.getFunction(Remotes.INDEX.EGG_HATCH)
            if not hatchRemote then
                warn("[TapSim] Egg hatch remote not found!")
                _isRunning = false
                return
            end
            while _isRunning and _G.Settings.AutoHatch do
                local eggName = _G.Settings.TargetEgg or "Basic"
                local amount = _G.Settings.HatchAmount or 1
                
                -- Smart Save check
                if not SmartSave.isSafeToSpend() then
                    task.wait(1)
                else
                    -- Track successful hatches for speedometer
                    local success = pcall(function() 
                        hatchRemote:InvokeServer(eggName, amount, {}) 
                    end)
                    
                    if success then
                        EggsHatchedPerSecond = EggsHatchedPerSecond + amount
                    end
                    
                    task.wait(_G.Settings.HatchDelay or 0.5)
                end
            end
            _isRunning = false
        end)
    end
    
    function Eggs.stop()
        _isRunning = false
        EggsHatchedPerSecond = 0
        EggsPerSecondDisplay = 0
        if _eggThread then task.cancel(_eggThread) _eggThread = nil end
        if _speedThread then task.cancel(_speedThread) _speedThread = nil end
    end
    
    function Eggs.getSpeed()
        return EggsPerSecondDisplay
    end
    
    function Eggs.toggle(enabled)
        _G.Settings.AutoHatch = enabled
        if enabled then Eggs.start() else Eggs.stop() end
    end
end

-- ============================================
-- FLUENT UI SETUP
-- ============================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Validate remotes first
local folder = Remotes.getRemoteFolder()
if not folder then
    Fluent:Notify({
        Title = "TapSim Hub",
        Content = "⚠️ Remote folder not found! Script may not work.",
        Duration = 10
    })
end

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "TapSim Hub",
    SubTitle = "v2.0 | Full Feature Edition",
    TabWidth = 130,
    Size = UDim2.fromOffset(550, 450),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

_G.TapSimUI = Window

-- ============================================
-- MOBILE TOGGLE BUTTON (For Android)
-- ============================================
local function CreateMobileToggle()
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    
    -- Only create on mobile/touch devices
    if not UserInputService.TouchEnabled then return end
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create toggle button
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "TapSimToggle"
    toggleGui.ResetOnSpawn = false
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toggleGui.Parent = playerGui
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(0, 50, 0, 50)
    toggleBtn.Position = UDim2.new(0, 10, 0.5, -25)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    toggleBtn.Text = "TS"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextSize = 18
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = toggleGui
    
    -- Round corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = toggleBtn
    
    -- Make draggable
    local dragging, dragStart, startPos
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position
        end
    end)
    
    toggleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            toggleBtn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Toggle UI on click
    toggleBtn.MouseButton1Click:Connect(function()
        if Window then
            Window:Minimize()
        end
    end)
    
    print("[TapSim] Mobile toggle button created!")
end

-- Create mobile button
task.spawn(CreateMobileToggle)

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "zap" }),
    Pets = Window:AddTab({ Title = "Pets", Icon = "egg" }),
    Islands = Window:AddTab({ Title = "Islands", Icon = "map" }),
    Upgrades = Window:AddTab({ Title = "Upgrades", Icon = "trending-up" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "globe" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- ============================================
-- MAIN TAB
-- ============================================
Tabs.Main:AddParagraph({ Title = "Clicking", Content = "" })

Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Click",
    Default = false
}):OnChanged(function(value)
    Farm.toggle(value)
end)

Tabs.Main:AddSlider("FarmDelay", {
    Title = "Click Delay",
    Default = 0.01, Min = 0.001, Max = 0.1, Rounding = 3,
    Callback = function(v) _G.Settings.FarmDelay = v end
})

Tabs.Main:AddParagraph({ Title = "Rebirth", Content = "" })

Tabs.Main:AddToggle("AutoRebirth", {
    Title = "Auto Rebirth",
    Default = false
}):OnChanged(function(value)
    Rebirth.toggle(value)
end)

Tabs.Main:AddSlider("NabungTime", {
    Title = "Cooldown",
    Description = "Seconds before rebirth",
    Default = 25, Min = 10, Max = 120, Rounding = 0,
    Callback = function(v) _G.Settings.NabungTime = v end
})

Tabs.Main:AddButton({
    Title = "Force Rebirth",
    Callback = function()
        local success, tier = Rebirth.forceRebirth()
        Fluent:Notify({ Title = "Rebirth", Content = success and ("Tier " .. tier) or "Failed", Duration = 2 })
    end
})

Tabs.Main:AddParagraph({ Title = "Misc", Content = "" })

Tabs.Main:AddToggle("AutoRankReward", {
    Title = "Auto Claim Rewards",
    Default = false
}):OnChanged(function(value)
    Rewards.toggle(value)
end)

-- ============================================
-- PETS TAB
-- ============================================

-- Discover eggs on load
local discoveredEggList = Eggs.discoverEggs()
if #discoveredEggList == 0 then
    discoveredEggList = {"Basic", "Space", "Starry", "Magma"}
end

Tabs.Pets:AddParagraph({ Title = "Hatching", Content = "" })

local EggDropdown = Tabs.Pets:AddDropdown("TargetEgg", {
    Title = "Select Egg",
    Values = discoveredEggList,
    Default = 1
})
EggDropdown:OnChanged(function(value)
    _G.Settings.TargetEgg = value
end)

Tabs.Pets:AddDropdown("HatchAmount", {
    Title = "Hatch Mode",
    Values = {"1", "3", "8"},
    Default = 1
}):OnChanged(function(value)
    _G.Settings.HatchAmount = tonumber(value)
end)

Tabs.Pets:AddToggle("AutoHatch", {
    Title = "Auto Hatch",
    Default = false
}):OnChanged(function(value)
    Eggs.toggle(value)
end)

Tabs.Pets:AddSlider("HatchDelay", {
    Title = "Hatch Delay",
    Default = 0.5, Min = 0.1, Max = 2, Rounding = 1,
    Callback = function(v) _G.Settings.HatchDelay = v end
})

Tabs.Pets:AddButton({
    Title = "Rescan Eggs",
    Callback = function()
        local eggs = Eggs.discoverEggs()
        EggDropdown:SetValues(eggs)
        Fluent:Notify({ Title = "Scan", Content = #eggs .. " eggs found", Duration = 2 })
    end
})

-- Speedometer Display
local SpeedDisplay = Tabs.Pets:AddParagraph({ Title = "Speed", Content = "0 Eggs/s" })
task.spawn(function()
    while true do
        task.wait(1)
        local speed = Eggs.getSpeed()
        SpeedDisplay:SetDesc(speed > 0 and (speed .. " Eggs/s") or "0 Eggs/s")
    end
end)

Tabs.Pets:AddParagraph({ Title = "Management", Content = "" })

Tabs.Pets:AddToggle("AutoEquip", {
    Title = "Auto Equip",
    Default = false
}):OnChanged(function(value)
    Pets.toggle(value)
end)

Tabs.Pets:AddParagraph({ Title = "Auto Delete", Content = "" })

Tabs.Pets:AddToggle("AutoDelete", {
    Title = "Active",
    Default = false
}):OnChanged(function(value)
    _G.DeleteSettings.Enabled = value
end)

Tabs.Pets:AddDropdown("DeleteRarity", {
    Title = "Delete Below",
    Values = AutoDelete.RarityList,
    Multi = true,
    Default = {}
}):OnChanged(function(value)
    _G.DeleteSettings.SelectedRarities = value
end)

Tabs.Pets:AddToggle("KeepGolden", {
    Title = "Safe Golden",
    Default = true
}):OnChanged(function(value)
    _G.DeleteSettings.KeepGolden = value
end)

Tabs.Pets:AddToggle("KeepRainbow", {
    Title = "Safe Rainbow",
    Default = true
}):OnChanged(function(value)
    _G.DeleteSettings.KeepRainbow = value
end)

Tabs.Pets:AddParagraph({ Title = "Crafting", Content = "" })

Tabs.Pets:AddToggle("AutoGolden", {
    Title = "Auto Golden",
    Default = false
}):OnChanged(function(value)
    AutoCraft.toggleGolden(value)
end)

Tabs.Pets:AddToggle("AutoRainbow", {
    Title = "Auto Rainbow",
    Default = false
}):OnChanged(function(value)
    AutoCraft.toggleRainbow(value)
end)

-- ============================================
-- ISLANDS TAB
-- ============================================
Tabs.Islands:AddParagraph({ Title = "Automation", Content = "" })

Tabs.Islands:AddToggle("AutoIsland", {
    Title = "Auto Unlock",
    Default = false
}):OnChanged(function(value)
    Islands.toggle(value)
end)

Tabs.Islands:AddToggle("AutoBestIsland", {
    Title = "Auto Go Best",
    Default = false
}):OnChanged(function(value)
    AutoBestIsland.toggle(value)
end)

Tabs.Islands:AddToggle("SmartSave", {
    Title = "Smart Saving",
    Description = "Stop hatch at 90% island price",
    Default = false
}):OnChanged(function(value)
    _G.SmartSave.Enabled = value
end)

Tabs.Islands:AddParagraph({ Title = "Travel", Content = "" })

local islandList = Islands.getLocationList()
local selectedIsland = islandList[1] or "Spawn"

local IslandDropdown = Tabs.Islands:AddDropdown("TeleportIsland", {
    Title = "Destination",
    Values = islandList,
    Default = 1
})
IslandDropdown:OnChanged(function(value)
    selectedIsland = value
end)

Tabs.Islands:AddButton({
    Title = "Teleport",
    Callback = function()
        local success = Islands.teleportTo(selectedIsland)
        Fluent:Notify({ Title = "TP", Content = success and selectedIsland or "Failed", Duration = 2 })
    end
})

-- ============================================
-- UPGRADES TAB
-- ============================================
Tabs.Upgrades:AddParagraph({ Title = "Auto Buy", Content = "" })

Tabs.Upgrades:AddToggle("AutoUpgrade", {
    Title = "Auto Upgrades",
    Default = false
}):OnChanged(function(value)
    Upgrades.toggleUpgrade(value)
end)

Tabs.Upgrades:AddToggle("AutoJump", {
    Title = "Auto Jump",
    Default = false
}):OnChanged(function(value)
    Upgrades.toggleJump(value)
end)

Tabs.Upgrades:AddSlider("UpgradeDelay", {
    Title = "Interval",
    Default = 3, Min = 1, Max = 30, Rounding = 0,
    Callback = function(v) _G.Settings.UpgradeDelay = v end
})

-- ============================================
-- SETTINGS TAB
-- ============================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("TapSimHub")
SaveManager:SetFolder("TapSimHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Tabs.Settings:AddParagraph({ Title = "Credits", Content = "TapSim Hub v1.3" })

-- ============================================
-- WEBHOOK TAB
-- ============================================
Tabs.Webhook:AddParagraph({ Title = "Discord", Content = "" })

Tabs.Webhook:AddToggle("WebhookEnabled", {
    Title = "Enable",
    Default = false
}):OnChanged(function(value)
    _G.WebhookSettings.Enabled = value
end)

Tabs.Webhook:AddInput("WebhookUrl", {
    Title = "URL",
    Description = "Paste Discord webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric = false,
    Finished = true,
    Callback = function(value)
        _G.WebhookSettings.Url = value
    end
})

Tabs.Webhook:AddDropdown("WebhookRarity", {
    Title = "Min Rarity",
    Values = {"Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Default = "Legendary"
}):OnChanged(function(value)
    _G.WebhookSettings.MinRarity = value
end)

Tabs.Webhook:AddButton({
    Title = "Test Webhook",
    Callback = function()
        if _G.WebhookSettings.Url == "" then
            Fluent:Notify({ Title = "Webhook", Content = "URL is empty!", Duration = 2 })
            return
        end
        
        local HttpService = game:GetService("HttpService")
        local LP = game.Players.LocalPlayer
        local payload = {
            embeds = {{
                title = "TEST HATCHED!",
                color = 5763719,
                fields = {
                    { name = "Player", value = LP.Name, inline = false },
                    { name = "Pet Name", value = "Test Pet", inline = true },
                    { name = "Rarity", value = "Legendary", inline = true },
                    { name = "Tier", value = "Rainbow", inline = true }
                },
                thumbnail = { url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png" },
                footer = { text = "TapSim Hub" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        local success = pcall(function()
            request({
                Url = _G.WebhookSettings.Url,
                Method = "POST",
                Headers = { 
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
        
        if success then
            Fluent:Notify({ Title = "Webhook", Content = "Test sent!", Duration = 2 })
        else
            Fluent:Notify({ Title = "Webhook", Content = "Failed!", Duration = 2 })
        end
    end
})

-- ============================================
-- FINISH
-- ============================================
Window:SelectTab(1)

Fluent:Notify({
    Title = "TapSim",
    Content = "Loaded!",
    Duration = 3
})

SaveManager:LoadAutoloadConfig()

print("[TapSim] Hub loaded!")
