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
                
                -- Track successful hatches for speedometer
                local success = pcall(function() 
                    hatchRemote:InvokeServer(eggName, amount, {}) 
                end)
                
                if success then
                    EggsHatchedPerSecond = EggsHatchedPerSecond + amount
                end
                
                task.wait(_G.Settings.HatchDelay or 0.5)
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

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "zap" }),
    Eggs = Window:AddTab({ Title = "Eggs", Icon = "egg" }),
    Islands = Window:AddTab({ Title = "Islands", Icon = "map" }),
    Upgrades = Window:AddTab({ Title = "Upgrades", Icon = "trending-up" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- ============================================
-- MAIN TAB (Farm, Rebirth, Rewards)
-- ============================================
Tabs.Main:AddParagraph({ Title = "Auto Farm", Content = "Super fast clicking" })

Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Description = "Enable automatic clicking (super fast)",
    Default = false
}):OnChanged(function(value)
    Farm.toggle(value)
    Fluent:Notify({ Title = "Auto Farm", Content = value and "Enabled" or "Disabled", Duration = 2 })
end)

Tabs.Main:AddSlider("FarmDelay", {
    Title = "Farm Speed",
    Description = "Lower = Faster (may cause lag)",
    Default = 0.01, Min = 0.001, Max = 0.1, Rounding = 3,
    Callback = function(v) _G.Settings.FarmDelay = v end
})

Tabs.Main:AddParagraph({ Title = "Smart Rebirth", Content = "Nabung strategy: wait then buy highest tier" })

Tabs.Main:AddToggle("AutoRebirth", {
    Title = "Auto Rebirth",
    Description = "Smart rebirth with nabung strategy",
    Default = false
}):OnChanged(function(value)
    Rebirth.toggle(value)
    Fluent:Notify({ Title = "Auto Rebirth", Content = value and "Enabled" or "Disabled", Duration = 2 })
end)

Tabs.Main:AddSlider("NabungTime", {
    Title = "Nabung Time",
    Description = "Seconds to wait before rebirth attempt",
    Default = 25, Min = 10, Max = 120, Rounding = 0,
    Callback = function(v) _G.Settings.NabungTime = v end
})

Tabs.Main:AddButton({
    Title = "Force Rebirth Now",
    Description = "Attempt rebirth immediately (Tier 4 → 1)",
    Callback = function()
        local success, tier = Rebirth.forceRebirth()
        Fluent:Notify({
            Title = "Force Rebirth",
            Content = success and ("Success! Tier " .. tostring(tier)) or "Failed - not enough money",
            Duration = 3
        })
    end
})

Tabs.Main:AddParagraph({ Title = "Rewards", Content = "Auto claim rank rewards every 5 minutes" })

Tabs.Main:AddToggle("AutoRankReward", {
    Title = "Auto Claim Rank Reward",
    Description = "Automatically claim rank rewards (every 5 min)",
    Default = false
}):OnChanged(function(value)
    Rewards.toggle(value)
    Fluent:Notify({ Title = "Auto Rank Reward", Content = value and "Enabled - claiming now!" or "Disabled", Duration = 2 })
end)

Tabs.Main:AddButton({
    Title = "Claim Rank Reward Now",
    Description = "Manually attempt to claim rank reward",
    Callback = function()
        local success = Rewards.claimRankReward()
        Fluent:Notify({
            Title = "Rank Reward",
            Content = success and "Attempted to claim!" or "Failed to claim",
            Duration = 2
        })
    end
})

-- ============================================
-- EGGS TAB (Hatching, Speed, Selection)
-- ============================================

-- Discover eggs on load
local discoveredEggList = Eggs.discoverEggs()
if #discoveredEggList == 0 then
    discoveredEggList = {"Basic", "Space", "Starry", "Magma"} -- Fallback
end

Tabs.Eggs:AddParagraph({ Title = "Auto Egg Hatch", Content = "Select egg and amount to auto hatch" })

Tabs.Eggs:AddToggle("AutoHatch", {
    Title = "Auto Hatch",
    Description = "Continuously hatch selected egg",
    Default = false
}):OnChanged(function(value)
    Eggs.toggle(value)
    Fluent:Notify({ Title = "Auto Hatch", Content = value and "Enabled" or "Disabled", Duration = 2 })
end)

local EggDropdown = Tabs.Eggs:AddDropdown("TargetEgg", {
    Title = "Target Egg",
    Description = "Select which egg to hatch",
    Values = discoveredEggList,
    Default = 1
})

EggDropdown:OnChanged(function(value)
    _G.Settings.TargetEgg = value
    Fluent:Notify({ Title = "Target Egg", Content = "Set to: " .. value, Duration = 2 })
end)

Tabs.Eggs:AddDropdown("HatchAmount", {
    Title = "Hatch Amount",
    Description = "How many eggs to hatch at once",
    Values = {"1", "3", "8"},
    Default = 1
}):OnChanged(function(value)
    _G.Settings.HatchAmount = tonumber(value)
end)

Tabs.Eggs:AddSlider("HatchDelay", {
    Title = "Hatch Speed",
    Description = "Delay between hatches (seconds)",
    Default = 0.5, Min = 0.1, Max = 2, Rounding = 1,
    Callback = function(v) _G.Settings.HatchDelay = v end
})

Tabs.Eggs:AddButton({
    Title = "Hatch Once",
    Description = "Hatch selected egg once",
    Callback = function()
        local eggName = _G.Settings.TargetEgg or "Basic"
        local amount = _G.Settings.HatchAmount or 1
        local success = Eggs.hatch(eggName, amount)
        Fluent:Notify({
            Title = "Hatch",
            Content = success and ("Hatched " .. tostring(amount) .. "x " .. eggName) or "Failed to hatch",
            Duration = 2
        })
    end
})

Tabs.Eggs:AddButton({
    Title = "Rescan Eggs",
    Description = "Re-discover available eggs",
    Callback = function()
        local eggs = Eggs.discoverEggs()
        EggDropdown:SetValues(eggs)
        Fluent:Notify({
            Title = "Egg Scan",
            Content = "Found " .. tostring(#eggs) .. " eggs",
            Duration = 3
        })
    end
})

-- Speedometer Display
local SpeedDisplay = Tabs.Eggs:AddParagraph({
    Title = "Speedometer",
    Content = "0 Eggs/s | Waiting..."
})

-- Update speedometer UI every second
task.spawn(function()
    while true do
        task.wait(1)
        local speed = Eggs.getSpeed()
        if speed > 0 then
            SpeedDisplay:SetDesc(speed .. " Eggs/s | Est. " .. (speed * 60) .. " Eggs/min")
        else
            if _G.Settings.AutoHatch then
                SpeedDisplay:SetDesc("0 Eggs/s | Hatching...")
            else
                SpeedDisplay:SetDesc("0 Eggs/s | Waiting...")
            end
        end
    end
end)

-- ============================================
-- ISLANDS TAB (Unlock, GPS Teleport)
-- ============================================
Tabs.Islands:AddParagraph({ Title = "Island Unlock", Content = "Auto-discover and unlock all islands" })

Tabs.Islands:AddToggle("AutoIsland", {
    Title = "Auto Unlock Islands",
    Description = "Periodically attempt to unlock all islands",
    Default = false
}):OnChanged(function(value)
    Islands.toggle(value)
    Fluent:Notify({ Title = "Auto Islands", Content = value and "Enabled" or "Disabled", Duration = 2 })
end)

Tabs.Islands:AddButton({
    Title = "Force Unlock All",
    Description = "Attempt to unlock all discovered islands now",
    Callback = function()
        local count = #Islands.getDiscoveredIslands()
        Islands.unlockAll()
        Fluent:Notify({ Title = "Island Unlock", Content = "Attempted " .. tostring(count) .. " islands", Duration = 3 })
    end
})

Tabs.Islands:AddButton({
    Title = "Rescan Islands",
    Description = "Re-discover island names from map",
    Callback = function()
        local islands = Islands.discoverIslands()
        Fluent:Notify({
            Title = "Island Scan",
            Content = "Found " .. tostring(#islands) .. " islands",
            SubContent = table.concat(islands, ", "),
            Duration = 5
        })
    end
})

-- Teleport Section (GPS Mode)
Tabs.Islands:AddParagraph({ Title = "GPS Teleport", Content = "Instant teleport to any island (16 locations)" })

-- Use coordinate database for dropdown
local islandList = Islands.getLocationList()

local IslandDropdown = Tabs.Islands:AddDropdown("TeleportIsland", {
    Title = "Select Island",
    Description = "Choose island to teleport to",
    Values = islandList,
    Default = 1
})

-- Track selected island
local selectedIsland = islandList[1] or "Spawn"
IslandDropdown:OnChanged(function(value)
    selectedIsland = value
end)

Tabs.Islands:AddButton({
    Title = "Teleport Now",
    Description = "Teleport to selected island",
    Callback = function()
        local success = Islands.teleportTo(selectedIsland)
        Fluent:Notify({
            Title = "Teleport",
            Content = success and ("Teleported to " .. selectedIsland) or ("Failed: " .. selectedIsland),
            Duration = 2
        })
    end
})

-- ============================================
-- UPGRADES TAB (Stats, Jump)
-- ============================================
Tabs.Upgrades:AddParagraph({ Title = "Auto Upgrades", Content = "Automatically purchase stat upgrades" })

Tabs.Upgrades:AddToggle("AutoUpgrade", {
    Title = "Auto Upgrades",
    Description = "Auto buy all stat upgrades",
    Default = false
}):OnChanged(function(value)
    Upgrades.toggleUpgrade(value)
    Fluent:Notify({ Title = "Auto Upgrades", Content = value and "Enabled" or "Disabled", Duration = 2 })
end)

Tabs.Upgrades:AddToggle("AutoJump", {
    Title = "Auto Jump Upgrade",
    Description = "Auto upgrade jump height",
    Default = false
}):OnChanged(function(value)
    Upgrades.toggleJump(value)
    Fluent:Notify({ Title = "Auto Jump", Content = value and "Enabled" or "Disabled", Duration = 2 })
end)

Tabs.Upgrades:AddSlider("UpgradeDelay", {
    Title = "Upgrade Interval",
    Description = "Seconds between upgrade attempts",
    Default = 3, Min = 1, Max = 30, Rounding = 0,
    Callback = function(v) _G.Settings.UpgradeDelay = v end
})

Tabs.Upgrades:AddParagraph({
    Title = "Upgrade List",
    Content = "RebirthButtons, FreeAutoClicker, HatchSpeed,\nCriticalChance, GoldenLuck, AutoClickerSpeed,\nClickMultiplier"
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

Tabs.Settings:AddParagraph({ Title = "Credits", Content = "TapSim Hub v1.1\nPowered by Fluent UI" })

-- ============================================
-- FINISH
-- ============================================
Window:SelectTab(1)

Fluent:Notify({
    Title = "TapSim Hub",
    Content = "Script loaded successfully!",
    SubContent = "Use RightCtrl to minimize",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()

print("[TapSim] Hub loaded successfully!")
