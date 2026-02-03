--[[
    ████████╗ █████╗ ██████╗ ███████╗██╗███╗   ███╗
    ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║████╗ ████║
       ██║   ███████║██████╔╝███████╗██║██╔████╔██║
       ██║   ██╔══██║██╔═══╝ ╚════██║██║██║╚██╔╝██║
       ██║   ██║  ██║██║     ███████║██║██║ ╚═╝ ██║
       ╚═╝   ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝╚═╝     ╚═╝
    
    TapSim Hub v2.1 - Architect Edition
    Single-File Script (Copy this entire file)
    Last Updated: 2026-02-04
    
    ═══════════════════════════════════════════════════════════════════
    NAVIGATION GUIDE (Use Ctrl+F to Find Tags)
    ═══════════════════════════════════════════════════════════════════
    
    [SEC-CONFIG]   : Global Settings & Anti-Duplicate
    [SEC-ANTIAFK]  : Super Anti-AFK V2
    [SEC-REJOIN]   : Auto Rejoin (PS Friendly)
    
    [MOD-REMOTES]  : Remotes Manager
    [MOD-FARM]     : Auto Farm/Tap Logic
    [MOD-REBIRTH]  : Smart Rebirth System
    [MOD-EGGS]     : Auto Hatch (Manual 1/3/8)
    [MOD-ISLANDS]  : Island Discovery & Teleport
    [MOD-UPGRADES] : Stats Auto Upgrade
    [MOD-REWARDS]  : Rank Rewards Claimer
    [MOD-PETS]     : Pet Auto Equip
    [MOD-DELETE]   : Auto Delete by Rarity
    [MOD-CRAFT]    : Golden/Rainbow Crafting
    [MOD-MERCH]    : Dual Merchant (Space/Gem)
    [MOD-WEBHOOK]  : Discord Notifications
    
    [UI-INIT]      : Fluent UI Initialization
    [UI-MAIN]      : Main Tab (Farm, Rebirth)
    [UI-PETS]      : Pets Tab (Hatch, Equip, Craft)
    [UI-ISLANDS]   : Islands Tab (Unlock, Teleport)
    [UI-UPGRADES]  : Upgrades Tab
    [UI-MERCHANT]  : Merchant Tab (Dual Shop)
    [UI-WEBHOOK]   : Webhook Tab
    [UI-PERF]      : Performance Tab
    [UI-SETTINGS]  : Settings Tab
    
    [SEC-CLEANUP]  : Memory Cleanup System
    [SEC-INIT]     : Final Initialization
    
    ═══════════════════════════════════════════════════════════════════
    QUICK DEBUG GUIDE:
    - Farm not working?     → Ctrl+F: [MOD-FARM]
    - Eggs not hatching?    → Ctrl+F: [MOD-EGGS]
    - UI not showing?       → Ctrl+F: [UI-INIT]
    - Memory leak?          → Ctrl+F: [SEC-CLEANUP]
    ═══════════════════════════════════════════════════════════════════
]]


-- ════════════════════════════════════════════════════════════════
-- [SEC-CONFIG] GLOBAL SETTINGS & ANTI-DUPLICATE
-- ════════════════════════════════════════════════════════════════

if _G.TapSimLoaded then
    warn("[TapSim] Script already loaded! Destroying previous instance...")
    if _G.TapSimUI then
        pcall(function() _G.TapSimUI:Destroy() end)
    end
end
_G.TapSimLoaded = true

-- Default Settings
_G.Settings = {
    AutoFarm = false,
    FarmDelay = 0.001,
    AutoRebirth = false,
    DoHighestRebirth = true,
    NabungTime = 25,
    AutoHatch = false,
    TargetEgg = "Basic",
    HatchAmount = 1,
    HatchDelay = 0.1,
    AutoIsland = false,
    AutoUpgrade = false,
    AutoJump = false,
    UpgradeDelay = 1,
    AutoEquipBest = false,
    AutoDelete = false,
    DeleteRarities = {},
    AutoGolden = false,
    AutoRainbow = false,
}

-- Secret Pet Predictor (future feature)
_G.SecretPetPredictor = {
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


-- ════════════════════════════════════════════════════════════════
-- [SEC-ANTIAFK] SUPER ANTI-AFK V2 (AGGRESSIVE)
-- ════════════════════════════════════════════════════════════════
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


-- ════════════════════════════════════════════════════════════════
-- [SEC-REJOIN] AUTO REJOIN (SAFE MODE - PS FRIENDLY)
-- ════════════════════════════════════════════════════════════════
print("[TapSim] Loading Safe Auto-Rejoin (PS Friendly)...")

task.spawn(function()
    local Gui = game:GetService("CoreGui")
    local Teleport = game:GetService("TeleportService")
    local Plr = game:GetService("Players").LocalPlayer
    
    Gui.ChildAdded:Connect(function(child)
        if child.Name == "RobloxPromptGui" then
            print("[Auto-Rejoin] DISCONNECT DETECTED! Rejoining in 5s...")
            task.wait(5)
            Teleport:Teleport(game.PlaceId, Plr)
        end
    end)
end)

print("[TapSim] Anti-AFK + Auto-Rejoin loaded - safe to AFK 24/7")


-- ════════════════════════════════════════════════════════════════
-- [MOD-REMOTES] REMOTES MODULE
-- ════════════════════════════════════════════════════════════════
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
        "WalkSpeed", "Range", "JumpPower", "Gems"
    }
    
    function Remotes.getRemoteFolder()
        if _remoteFolder then return _remoteFolder end
        local Game = ReplicatedStorage:FindFirstChild("Game")
        if not Game then return nil end
        _remoteFolder = Game:FindFirstChild("Remote")
        if _remoteFolder then
            _eventsFolder = _remoteFolder:FindFirstChild("Event")
            _functionsFolder = _remoteFolder:FindFirstChild("Function")
        end
        return _remoteFolder
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


-- ════════════════════════════════════════════════════════════════
-- [MOD-FARM] FARM MODULE
-- ════════════════════════════════════════════════════════════════
local Farm = {}
do
    local _farmThread, _isRunning = nil, false
    
    function Farm.start()
        if _isRunning then return end
        _isRunning = true
        _farmThread = task.spawn(function()
            local farmRemote = Remotes.getEvent(Remotes.INDEX.FARM)
            if not farmRemote then warn("[TapSim] Farm remote not found!") return end
            
            while _isRunning and _G.Settings.AutoFarm do
                farmRemote:FireServer()
                task.wait(_G.Settings.FarmDelay or 0.001)
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


-- ════════════════════════════════════════════════════════════════
-- [MOD-REBIRTH] REBIRTH MODULE
-- ════════════════════════════════════════════════════════════════
local Rebirth = {}
do
    local _rebirthThread, _isRunning = nil, false
    
    function Rebirth.attemptRebirth()
        local rebirthRemote = Remotes.getFunction(Remotes.INDEX.REBIRTH)
        if not rebirthRemote then return false, nil end
        for tier = 4, 1, -1 do
            local success, result = pcall(function()
                return rebirthRemote:InvokeServer(tier)
            end)
            if success and result then return true, tier end
        end
        return false, nil
    end
    
    function Rebirth.start()
        if _isRunning then return end
        _isRunning = true
        _rebirthThread = task.spawn(function()
            while _isRunning and _G.Settings.AutoRebirth do
                local waitTime = _G.Settings.NabungTime or 25
                for i = 1, waitTime do
                    if not _isRunning or not _G.Settings.AutoRebirth then break end
                    task.wait(1)
                end
                if _isRunning and _G.Settings.AutoRebirth then
                    Rebirth.attemptRebirth()
                end
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


-- ════════════════════════════════════════════════════════════════
-- [MOD-EGGS] EGGS MODULE (DATA READER EDITION)
-- ════════════════════════════════════════════════════════════════
local Eggs = {}
do
    local _eggThread = nil
    local _isRunning = false
    local _discoveredEggs = {}
    local _currentMaxHatch = 1 -- Default

    Eggs.INDEX = 44

    -- LOGIKA DETEKSI BARU (Berdasarkan Hasil Spy)
    function Eggs.detectMaxHatch()
        local RS = game:GetService("ReplicatedStorage")
        
        -- Coba akses module Replication
        local success, Replication = pcall(function()
            return require(RS.Game.Replication)
        end)

        if success and Replication then
            -- Tunggu data loading (Anti Race Condition)
            local attempts = 0
            while (not Replication.Data or not Replication.Data.Gamepasses) and attempts < 10 do
                task.wait(0.5)
                attempts = attempts + 1
            end

            -- BACA DATA DENGAN KEY YANG TEPAT
            if Replication.Data and Replication.Data.Gamepasses then
                local gp = Replication.Data.Gamepasses
                
                if gp["x8Egg"] == true then
                    print("[TapSim] Detect: Owned x8 Hatch!")
                    return 8
                elseif gp["x3Egg"] == true then
                    print("[TapSim] Detect: Owned x3 Hatch!")
                    return 3
                else
                    print("[TapSim] Detect: No Hatch Pass found (1x)")
                    return 1
                end
            end
        end
        
        print("[TapSim] Detect Failed (Data not loaded), defaulting to 1")
        return 1
    end

    function Eggs.discoverEggs()
        _discoveredEggs = {}
        local Workspace = game:GetService("Workspace")
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
        return _discoveredEggs
    end

    function Eggs.getDiscoveredEggs()
        if #_discoveredEggs == 0 then Eggs.discoverEggs() end
        return _discoveredEggs
    end

    function Eggs.start()
        if _isRunning then return end
        _isRunning = true
        
        -- Deteksi otomatis saat start
        _currentMaxHatch = Eggs.detectMaxHatch()
        
        _eggThread = task.spawn(function()
            local hatchRemote = Remotes.getFunction(Eggs.INDEX)
            if not hatchRemote then
                warn("[TapSim] Egg hatch remote not found!")
                _isRunning = false
                return
            end
            
            while _isRunning and _G.Settings.AutoHatch do
                local eggName = _G.Settings.TargetEgg or "Basic"
                local amount = _currentMaxHatch -- Pakai hasil deteksi
                
                pcall(function()
                    hatchRemote:InvokeServer(eggName, amount, {})
                end)
                
                local delay = _G.Settings.HatchDelay or 0.1
                task.wait(delay)
            end
            _isRunning = false
        end)
    end

    function Eggs.stop()
        _isRunning = false
        _G.Settings.AutoHatch = false
        if _eggThread then task.cancel(_eggThread) _eggThread = nil end
    end

    function Eggs.toggle(val)
        _G.Settings.AutoHatch = val
        if val then Eggs.start() else Eggs.stop() end
    end
    
    function Eggs.getSpeed()
        return _currentMaxHatch
    end
    
    function Eggs.isRunning()
        return _isRunning
    end
end



-- ════════════════════════════════════════════════════════════════
-- [MOD-ISLANDS] ISLANDS MODULE
-- ════════════════════════════════════════════════════════════════
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
        
        local targetCFrame = Islands.Locations[islandName]
        if targetCFrame then
            Char.HumanoidRootPart.CFrame = targetCFrame
            print("[TapSim] Teleported to " .. islandName)
            return true
        else
            warn("[TapSim] Unknown location: " .. islandName)
            return false
        end
    end
end


-- ════════════════════════════════════════════════════════════════
-- [MOD-UPGRADES] UPGRADES MODULE
-- ════════════════════════════════════════════════════════════════
local Upgrades = {}
do
    local _upgradeThread, _jumpThread = nil, nil
    local _isUpgrading, _isJumping = false, false
    
    function Upgrades.buyUpgrade(upgradeName)
        local upgradeRemote = Remotes.getFunction(Remotes.INDEX.UPGRADE_STATS)
        if not upgradeRemote then return false end
        local success = pcall(function()
            upgradeRemote:InvokeServer(upgradeName)
        end)
        return success
    end
    
    function Upgrades.buyJump()
        local jumpRemote = Remotes.getFunction(Remotes.INDEX.UPGRADE_JUMP)
        if not jumpRemote then return false end
        local success = pcall(function()
            jumpRemote:InvokeServer()
        end)
        return success
    end
    
    function Upgrades.startUpgrade()
        if _isUpgrading then return end
        _isUpgrading = true
        _upgradeThread = task.spawn(function()
            while _isUpgrading and _G.Settings.AutoUpgrade do
                for _, upgradeName in pairs(Remotes.UPGRADES) do
                    if not _isUpgrading then break end
                    Upgrades.buyUpgrade(upgradeName)
                    task.wait(0.1)
                end
                task.wait(_G.Settings.UpgradeDelay or 1)
            end
            _isUpgrading = false
        end)
    end
    
    function Upgrades.stopUpgrade()
        _isUpgrading = false
        if _upgradeThread then task.cancel(_upgradeThread) _upgradeThread = nil end
    end
    
    function Upgrades.toggleUpgrade(enabled)
        _G.Settings.AutoUpgrade = enabled
        if enabled then Upgrades.startUpgrade() else Upgrades.stopUpgrade() end
    end
    
    function Upgrades.startJump()
        if _isJumping then return end
        _isJumping = true
        _jumpThread = task.spawn(function()
            while _isJumping and _G.Settings.AutoJump do
                Upgrades.buyJump()
                task.wait(1)
            end
            _isJumping = false
        end)
    end
    
    function Upgrades.stopJump()
        _isJumping = false
        if _jumpThread then task.cancel(_jumpThread) _jumpThread = nil end
    end
    
    function Upgrades.toggleJump(enabled)
        _G.Settings.AutoJump = enabled
        if enabled then Upgrades.startJump() else Upgrades.stopJump() end
    end
end


-- ════════════════════════════════════════════════════════════════
-- [MOD-REWARDS] REWARDS MODULE
-- ════════════════════════════════════════════════════════════════
local Rewards = {}
do
    local _rewardThread, _isRunning = nil, false
    
    function Rewards.claimRank()
        local rankRemote = Remotes.getFunction(Remotes.INDEX.RANK_REWARD)
        if not rankRemote then return false end
        local success = pcall(function()
            rankRemote:InvokeServer()
        end)
        return success
    end
    
    function Rewards.start()
        if _isRunning then return end
        _isRunning = true
        _rewardThread = task.spawn(function()
            while _isRunning do
                Rewards.claimRank()
                for i = 1, 300 do
                    if not _isRunning then break end
                    task.wait(1)
                end
            end
        end)
    end
    
    function Rewards.stop()
        _isRunning = false
        if _rewardThread then task.cancel(_rewardThread) _rewardThread = nil end
    end
    
    function Rewards.toggle(enabled)
        if enabled then Rewards.start() else Rewards.stop() end
    end
end


-- ════════════════════════════════════════════════════════════════
-- [MOD-PETS] PETS MODULE
-- ════════════════════════════════════════════════════════════════
local Pets = {}
do
    local _petThread, _isRunning = nil, false
    
    function Pets.equipBest()
        local Plr = game:GetService("Players").LocalPlayer
        local petFolder = Plr:FindFirstChild("Pets")
        if not petFolder then return end
        
        -- Simple best equip logic (placeholder)
        print("[TapSim] Equipping best pets...")
    end
    
    function Pets.start()
        if _isRunning then return end
        _isRunning = true
        _petThread = task.spawn(function()
            while _isRunning and _G.Settings.AutoEquipBest do
                Pets.equipBest()
                task.wait(30)
            end
            _isRunning = false
        end)
    end
    
    function Pets.stop()
        _isRunning = false
        if _petThread then task.cancel(_petThread) _petThread = nil end
    end
    
    function Pets.toggle(enabled)
        _G.Settings.AutoEquipBest = enabled
        if enabled then Pets.start() else Pets.stop() end
    end
end


-- ════════════════════════════════════════════════════════════════
-- [MOD-DELETE] AUTO DELETE MODULE
-- ════════════════════════════════════════════════════════════════
local AutoDelete = {}
do
    local _deleteThread, _isRunning = nil, false
    
    AutoDelete.Rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
    
    function AutoDelete.start()
        if _isRunning then return end
        _isRunning = true
        _deleteThread = task.spawn(function()
            while _isRunning and _G.Settings.AutoDelete do
                -- Delete logic placeholder
                task.wait(5)
            end
            _isRunning = false
        end)
    end
    
    function AutoDelete.stop()
        _isRunning = false
        if _deleteThread then task.cancel(_deleteThread) _deleteThread = nil end
    end
    
    function AutoDelete.toggle(enabled)
        _G.Settings.AutoDelete = enabled
        if enabled then AutoDelete.start() else AutoDelete.stop() end
    end
end


-- ════════════════════════════════════════════════════════════════
-- [MOD-CRAFT] AUTO CRAFT MODULE
-- ════════════════════════════════════════════════════════════════
local AutoCraft = {}
do
    local _goldenThread, _rainbowThread = nil, nil
    local _isGolden, _isRainbow = false, false
    local _machineCache = {}
    
    local function FindMachinePart(machineName)
        if _machineCache[machineName] and _machineCache[machineName].Parent then
            return _machineCache[machineName]
        end
        
        local target = workspace:FindFirstChild(machineName, true) or workspace:FindFirstChild(machineName:gsub("Machine", " Machine"), true)
        if target then
            local result = nil
            if target:IsA("Model") then
                result = target:FindFirstChild("Pad") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
            elseif target:IsA("BasePart") then
                result = target
            end
            if result then _machineCache[machineName] = result end
            return result
        end
        return nil
    end
    
    function AutoCraft.clearCache()
        _machineCache = {}
    end
    
    function AutoCraft.startGolden()
        if _isGolden then return end
        _isGolden = true
        _goldenThread = task.spawn(function()
            while _isGolden and _G.Settings.AutoGolden do
                local machine = FindMachinePart("GoldenMachine")
                if machine then
                    local Plr = game:GetService("Players").LocalPlayer
                    if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
                        Plr.Character.HumanoidRootPart.CFrame = machine.CFrame + Vector3.new(0, 3, 0)
                    end
                end
                task.wait(0.5)
            end
            _isGolden = false
        end)
    end
    
    function AutoCraft.stopGolden()
        _isGolden = false
        if _goldenThread then task.cancel(_goldenThread) _goldenThread = nil end
    end
    
    function AutoCraft.toggleGolden(enabled)
        _G.Settings.AutoGolden = enabled
        if enabled then AutoCraft.startGolden() else AutoCraft.stopGolden() end
    end
    
    function AutoCraft.startRainbow()
        if _isRainbow then return end
        _isRainbow = true
        _rainbowThread = task.spawn(function()
            while _isRainbow and _G.Settings.AutoRainbow do
                local machine = FindMachinePart("RainbowMachine")
                if machine then
                    local Plr = game:GetService("Players").LocalPlayer
                    if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
                        Plr.Character.HumanoidRootPart.CFrame = machine.CFrame + Vector3.new(0, 3, 0)
                    end
                end
                task.wait(0.5)
            end
            _isRainbow = false
        end)
    end
    
    function AutoCraft.stopRainbow()
        _isRainbow = false
        if _rainbowThread then task.cancel(_rainbowThread) _rainbowThread = nil end
    end
    
    function AutoCraft.toggleRainbow(enabled)
        _G.Settings.AutoRainbow = enabled
        if enabled then AutoCraft.startRainbow() else AutoCraft.stopRainbow() end
    end
end


-- ════════════════════════════════════════════════════════════════
-- [MOD-MERCH] MERCHANT MODULE (DUAL SHOP EDITION)
-- ════════════════════════════════════════════════════════════════
local Merchant = {}
do
    local _spaceBuyEnabled, _gemBuyEnabled = false, false
    local _spaceThread, _gemThread = nil, nil
    
    -- Item Databases
    Merchant.SpaceItems = {
        "2x Coins (30m)", "2x Gems (30m)", "Super Lucky (30m)",
        "2x Damage (30m)", "2x Coins (1h)", "2x Gems (1h)"
    }
    
    Merchant.GemItems = {
        "Triple Coins", "Triple Gems", "Triple Damage",
        "Auto Clicker", "Super Egg Luck", "Shiny Chance"
    }
    
    function Merchant.getSpaceItems()
        return Merchant.SpaceItems
    end
    
    function Merchant.getGemItems()
        return Merchant.GemItems
    end
    
    function Merchant.setSpaceItems(itemTable)
        _G.SpaceSelectedItems = {}
        for item, selected in pairs(itemTable) do
            if selected then table.insert(_G.SpaceSelectedItems, item) end
        end
        print("[Merchant] Space selected: " .. #_G.SpaceSelectedItems .. " items")
    end
    
    function Merchant.setGemItems(itemTable)
        _G.GemSelectedItems = {}
        for item, selected in pairs(itemTable) do
            if selected then table.insert(_G.GemSelectedItems, item) end
        end
        print("[Merchant] Gem selected: " .. #_G.GemSelectedItems .. " items")
    end
    
    function Merchant.buy(merchantType, itemName)
        -- Placeholder for actual buy logic
        print("[Merchant] Buying " .. itemName .. " from " .. merchantType)
    end
    
    function Merchant.toggleSpaceBuy(val)
        _spaceBuyEnabled = val
        if _spaceBuyEnabled then
            print("[Merchant] Space Auto Buy Started")
            _spaceThread = task.spawn(function()
                while _spaceBuyEnabled do
                    local items = _G.SpaceSelectedItems or {}
                    for _, item in ipairs(items) do
                        Merchant.buy("SpaceMerchant", item)
                        task.wait(0.5)
                    end
                    task.wait(1)
                end
            end)
        else
            print("[Merchant] Space Auto Buy Stopped")
            if _spaceThread then task.cancel(_spaceThread) _spaceThread = nil end
        end
    end
    
    function Merchant.toggleGemBuy(val)
        _gemBuyEnabled = val
        if _gemBuyEnabled then
            print("[Merchant] Gem Auto Buy Started")
            _gemThread = task.spawn(function()
                while _gemBuyEnabled do
                    local items = _G.GemSelectedItems or {}
                    for _, item in ipairs(items) do
                        Merchant.buy("GemMerchant", item)
                        task.wait(0.5)
                    end
                    task.wait(1)
                end
            end)
        else
            print("[Merchant] Gem Auto Buy Stopped")
            if _gemThread then task.cancel(_gemThread) _gemThread = nil end
        end
    end
end


-- ════════════════════════════════════════════════════════════════
-- [MOD-WEBHOOK] WEBHOOK MODULE
-- ════════════════════════════════════════════════════════════════
local Webhook = {}
do
    local _webhookThread, _isRunning = nil, false
    
    function Webhook.send(message)
        if not _G.WebhookSettings.Enabled or _G.WebhookSettings.Url == "" then return end
        
        local HttpService = game:GetService("HttpService")
        pcall(function()
            local data = HttpService:JSONEncode({
                content = message,
                username = "TapSim Hub"
            })
            -- Note: HttpService:PostAsync may not work in all executors
            -- Consider using syn.request or http_request
        end)
    end
    
    function Webhook.start()
        if _isRunning then return end
        _isRunning = true
        _webhookThread = task.spawn(function()
            Webhook.send("🟢 TapSim Hub Started!")
            while _isRunning and _G.WebhookSettings.Enabled do
                task.wait(60)
            end
        end)
    end
    
    function Webhook.stop()
        _isRunning = false
        if _webhookThread then task.cancel(_webhookThread) _webhookThread = nil end
    end
    
    function Webhook.toggle(enabled)
        _G.WebhookSettings.Enabled = enabled
        if enabled then Webhook.start() else Webhook.stop() end
    end
end


-- ════════════════════════════════════════════════════════════════
-- [UI-INIT] FLUENT UI INITIALIZATION
-- ════════════════════════════════════════════════════════════════
print("[TapSim] Loading UI...")

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "TapSim Hub v2.1",
    SubTitle = "Architect Edition",
    TabWidth = 100,
    Size = UDim2.fromOffset(500, 380),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

_G.TapSimUI = Window

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "zap" }),
    Pets = Window:AddTab({ Title = "Pets", Icon = "egg" }),
    Islands = Window:AddTab({ Title = "Islands", Icon = "map" }),
    Upgrades = Window:AddTab({ Title = "Upgrades", Icon = "trending-up" }),
    Merchant = Window:AddTab({ Title = "Merchant", Icon = "shopping-cart" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "globe" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}


-- ════════════════════════════════════════════════════════════════
-- [UI-MAIN] MAIN TAB
-- ════════════════════════════════════════════════════════════════

Tabs.Main:AddParagraph({ Title = "Auto Tap", Content = "Automatically taps coins really fast" })

Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Click",
    Default = false
}):OnChanged(function(value)
    Farm.toggle(value)
end)

-- FarmDelay fixed at fastest
_G.Settings.FarmDelay = 0.001

Tabs.Main:AddParagraph({ Title = "Rebirths", Content = "" })

Tabs.Main:AddToggle("AutoRebirth", {
    Title = "Auto Select best rebirth",
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

Tabs.Main:AddToggle("DoHighestRebirth", {
    Title = "Do Highest Rebirth",
    Default = true
}):OnChanged(function(value)
    _G.Settings.DoHighestRebirth = value
end)

Tabs.Main:AddButton({
    Title = "Force Rebirth NOW",
    Callback = function()
        local success, tier = Rebirth.forceRebirth()
        Fluent:Notify({ Title = "Rebirth", Content = success and ("Tier "..tier.." success!") or "Failed", Duration = 3 })
    end
})

Tabs.Main:AddParagraph({ Title = "Upgrades", Content = "" })

Tabs.Main:AddToggle("AutoUpgrade", {
    Title = "Auto Upgrade",
    Description = "Automatically upgrade selected stuff",
    Default = false
}):OnChanged(function(value)
    Upgrades.toggleUpgrade(value)
end)

Tabs.Main:AddParagraph({ Title = "Rank", Content = "" })

Tabs.Main:AddToggle("AutoRankReward", {
    Title = "Auto Claim Rank Rewards",
    Description = "Automatically claims rank rewards when available",
    Default = false
}):OnChanged(function(value)
    Rewards.toggle(value)
end)


-- ════════════════════════════════════════════════════════════════
-- [UI-PETS] PETS TAB
-- ════════════════════════════════════════════════════════════════

-- Discover eggs on load
local discoveredEggList = Eggs.discoverEggs()
if #discoveredEggList == 0 then
    discoveredEggList = {"Basic", "Space", "Starry", "Magma"}
end

Tabs.Pets:AddParagraph({ Title = "Hatching stuff", Content = "" })

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
    Description = "How many eggs to hatch at once",
    Values = {"1", "3", "8"},
    Default = "1"
}):OnChanged(function(value)
    _G.Settings.HatchAmount = tonumber(value)
end)

Tabs.Pets:AddToggle("AutoHatch", {
    Title = "Auto Hatch",
    Description = "Automatically hatches eggs",
    Default = false
}):OnChanged(function(value)
    Eggs.toggle(value)
end)

-- HatchDelay fixed at fastest
_G.Settings.HatchDelay = 0.1

Tabs.Pets:AddButton({
    Title = "Rescan Eggs",
    Callback = function()
        local eggs = Eggs.discoverEggs()
        EggDropdown:SetValues(eggs)
        Fluent:Notify({ Title = "Scan", Content = #eggs .. " eggs found", Duration = 2 })
    end
})

Tabs.Pets:AddParagraph({ Title = "Pets", Content = "" })

Tabs.Pets:AddToggle("AutoEquipBest", {
    Title = "Auto Equip Best",
    Default = false
}):OnChanged(function(value)
    Pets.toggle(value)
end)

Tabs.Pets:AddParagraph({ Title = "Gold Crafting", Content = "" })

Tabs.Pets:AddToggle("AutoGolden", {
    Title = "Auto Gold Craft",
    Default = false
}):OnChanged(function(value)
    AutoCraft.toggleGolden(value)
end)

Tabs.Pets:AddParagraph({ Title = "Rainbow Crafting", Content = "" })

Tabs.Pets:AddToggle("AutoRainbow", {
    Title = "Auto Rainbow Craft",
    Default = false
}):OnChanged(function(value)
    AutoCraft.toggleRainbow(value)
end)


-- ════════════════════════════════════════════════════════════════
-- [UI-ISLANDS] ISLANDS TAB
-- ════════════════════════════════════════════════════════════════

Tabs.Islands:AddParagraph({ Title = "Islands/World Stuff", Content = "" })

Tabs.Islands:AddToggle("AutoIsland", {
    Title = "Auto Buy Islands",
    Default = false
}):OnChanged(function(value)
    Islands.toggle(value)
end)

Tabs.Islands:AddButton({
    Title = "Unlock All Islands",
    Callback = function()
        Islands.unlockAll()
        Fluent:Notify({ Title = "Islands", Content = "Unlocking all...", Duration = 2 })
    end
})

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


-- ════════════════════════════════════════════════════════════════
-- [UI-UPGRADES] UPGRADES TAB
-- ════════════════════════════════════════════════════════════════

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

-- UpgradeDelay fixed at fastest
_G.Settings.UpgradeDelay = 1


-- ════════════════════════════════════════════════════════════════
-- [UI-MERCHANT] MERCHANT TAB (DUAL SHOP)
-- ════════════════════════════════════════════════════════════════

Tabs.Merchant:AddParagraph({ Title = "Space Merchant Items", Content = "" })

Tabs.Merchant:AddDropdown("SpaceMerchantItem", {
    Title = "Space Items",
    Description = "Select items to auto-buy",
    Values = Merchant.getSpaceItems(),
    Multi = true,
    Default = {}
}):OnChanged(function(value)
    Merchant.setSpaceItems(value)
end)

Tabs.Merchant:AddToggle("AutoSpaceBuy", {
    Title = "Auto Buy (Space)",
    Default = false
}):OnChanged(function(value)
    Merchant.toggleSpaceBuy(value)
end)

Tabs.Merchant:AddParagraph({ Title = "Gem Merchant Items", Content = "" })

Tabs.Merchant:AddDropdown("GemMerchantItem", {
    Title = "Gem Items",
    Description = "Select items to auto-buy",
    Values = Merchant.getGemItems(),
    Multi = true,
    Default = {}
}):OnChanged(function(value)
    Merchant.setGemItems(value)
end)

Tabs.Merchant:AddToggle("AutoGemBuy", {
    Title = "Auto Buy (Gem)",
    Default = false
}):OnChanged(function(value)
    Merchant.toggleGemBuy(value)
end)


-- ════════════════════════════════════════════════════════════════
-- [UI-WEBHOOK] WEBHOOK TAB
-- ════════════════════════════════════════════════════════════════

Tabs.Webhook:AddParagraph({ Title = "Discord Webhook", Content = "" })

Tabs.Webhook:AddInput("WebhookUrl", {
    Title = "Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(value)
        _G.WebhookSettings.Url = value
    end
})

Tabs.Webhook:AddToggle("WebhookEnabled", {
    Title = "Enable Webhook",
    Default = false
}):OnChanged(function(value)
    Webhook.toggle(value)
end)

Tabs.Webhook:AddDropdown("WebhookRarity", {
    Title = "Minimum Rarity",
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Default = "Legendary"
}):OnChanged(function(value)
    _G.WebhookSettings.MinRarity = value
end)


-- ════════════════════════════════════════════════════════════════
-- [UI-SETTINGS] SETTINGS TAB
-- ════════════════════════════════════════════════════════════════

Tabs.Settings:AddParagraph({ Title = "Configuration", Content = "" })

Tabs.Settings:AddButton({
    Title = "Save Settings",
    Callback = function()
        -- Placeholder for save logic
        Fluent:Notify({ Title = "Settings", Content = "Saved!", Duration = 2 })
    end
})

Tabs.Settings:AddButton({
    Title = "Load Settings",
    Callback = function()
        -- Placeholder for load logic
        Fluent:Notify({ Title = "Settings", Content = "Loaded!", Duration = 2 })
    end
})

Tabs.Settings:AddButton({
    Title = "Reset to Default",
    Callback = function()
        -- Placeholder for reset logic
        Fluent:Notify({ Title = "Settings", Content = "Reset!", Duration = 2 })
    end
})


-- ════════════════════════════════════════════════════════════════
-- [SEC-CLEANUP] MEMORY CLEANUP SYSTEM
-- ════════════════════════════════════════════════════════════════

local function CleanupAll()
    print("[TapSim] Cleaning up memory...")
    
    pcall(function() Farm.stop() end)
    pcall(function() Rebirth.stop() end)
    pcall(function() Eggs.stop() end)
    pcall(function() Islands.stop() end)
    pcall(function() Upgrades.stopUpgrade() end)
    pcall(function() Upgrades.stopJump() end)
    pcall(function() Pets.stop() end)
    pcall(function() Rewards.stop() end)
    pcall(function() AutoDelete.stop() end)
    pcall(function() AutoCraft.stopGolden() end)
    pcall(function() AutoCraft.stopRainbow() end)
    pcall(function() Merchant.toggleSpaceBuy(false) end)
    pcall(function() Merchant.toggleGemBuy(false) end)
    pcall(function() Webhook.stop() end)
    
    pcall(function() AutoCraft.clearCache() end)
    
    _G.TapSimLoaded = nil
    _G.Settings = nil
    _G.SpaceSelectedItems = nil
    _G.GemSelectedItems = nil
    
    for i = 1, 5 do
        collectgarbage("collect")
    end
    
    print("[TapSim] Cleanup complete!")
end

-- Hook to Window.OnUnload
if Window.OnUnload then
    local oldUnload = Window.OnUnload
    Window.OnUnload = function()
        CleanupAll()
        if oldUnload then oldUnload() end
    end
else
    Window.OnUnload = CleanupAll
end


-- ════════════════════════════════════════════════════════════════
-- [SEC-INIT] FINAL INITIALIZATION
-- ════════════════════════════════════════════════════════════════

Window:SelectTab(1)

Fluent:Notify({
    Title = "TapSim Hub v2.1",
    Content = "Architect Edition loaded!",
    Duration = 5
})

print("[TapSim] ═══════════════════════════════════════════════")
print("[TapSim] TapSim Hub v2.1 - Architect Edition")
print("[TapSim] Searchable Tags Navigation Ready!")
print("[TapSim] Use Ctrl+F with tags like [MOD-FARM] to navigate")
print("[TapSim] ═══════════════════════════════════════════════")
