--[[
    ████████╗ █████╗ ██████╗ ███████╗██╗███╗   ███╗
    ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║████╗ ████║
       ██║   ███████║██████╔╝███████╗██║██╔████╔██║
       ██║   ██╔══██║██╔═══╝ ╚════██║██║██║╚██╔╝██║
       ██║   ██║  ██║██║     ███████║██║██║ ╚═╝ ██║
       ╚═╝   ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝╚═╝     ╚═╝
    
    TapSim Hub v3.2 - Polished Edition
    NEW: SafeMode UI, Webhook Validation, FPS Counter, Config Save+
    Last Updated: 2026-02-05
    
    ═══════════════════════════════════════════════════════════════════
    NAVIGATION (Use Ctrl+F to search tags)
    ═══════════════════════════════════════════════════════════════════
    
    [SEC-CONFIG]     Global Settings & Anti-Duplicate
    [SEC-ANTIAFK]    Super Anti-AFK V2 & Auto Rejoin
    [MOD-REMOTES]    Remote Handler (Events/Functions)
    [MOD-FARM]       Auto Farm / Auto Tap
    [MOD-REBIRTH]    Auto Rebirth (Nabung Strategy)
    [MOD-EGGS]       Smart Hatch (x8/x3 Detect + Speedometer)
    [MOD-ISLANDS]    Island Discovery & Teleport
    [MOD-UPGRADES]   Stats Auto Upgrade
    [MOD-REWARDS]    Rank Rewards Claim
    [MOD-PETS]       Auto Equip Best
    [MOD-DELETE]     Auto Delete by Rarity
    [MOD-SMARTSAVE]  Data Cache for Island Buying
    [MOD-BESTISLE]   Auto Teleport to Best Island
    [MOD-CRAFT]      Auto Golden/Rainbow Craft
    [MOD-MERCHANT]   Dual Shop (Space + Gem)
    [MOD-WEBHOOK]    Discord Webhook Notifications
    [UI-MAIN]        Fluent UI Setup & Window
    [UI-TABS]        All Tab Definitions
    [SEC-CLEANUP]    Memory Cleanup & Unload
    
    ═══════════════════════════════════════════════════════════════════
    QUICK DEBUG:
    - Farm not working?     → Search [MOD-FARM]
    - Eggs not hatching?    → Search [MOD-EGGS]
    - UI not showing?       → Search [UI-MAIN]
    - Memory leak?          → Search [SEC-CLEANUP]
    ═══════════════════════════════════════════════════════════════════
]]

-- ============================================
-- [SEC-CONFIG] ANTI-DUPLICATE EXECUTION
-- ============================================
if _G.TapSimLoaded then
    warn("[CONFIG] Script already loaded! Destroying previous instance...")
    if _G.TapSimUI then pcall(function() _G.TapSimUI:Destroy() end) end
end
_G.TapSimLoaded = true

-- ============================================
-- [SEC-CONFIG] GLOBAL SETTINGS
-- ============================================
_G.Settings = _G.Settings or {}
_G.Settings.AutoFarm = false
_G.Settings.AutoRebirth = false
_G.Settings.AutoRankReward = false
_G.Settings.FarmDelay = 0.1  -- SAFE: 10 clicks/sec (human-like)
_G.Settings.NabungTime = 25
_G.Settings.AutoIsland = false
_G.Settings.AutoUpgrade = false
_G.Settings.AutoJump = false
_G.Settings.UpgradeDelay = 3
_G.Settings.AutoHatch = false
_G.Settings.TargetEgg = "Basic"
_G.Settings.HatchDelay = 0.5
_G.Settings.AutoEquip = false

_G.DeleteSettings = { Enabled = false, SelectedRarities = {}, KeepGolden = true, KeepRainbow = true, KeepHuge = true }
_G.SmartSave = { Enabled = false, Threshold = 0.9 }
_G.AutoGoBest = false
_G.WebhookSettings = { Enabled = false, Url = "", MinRarity = "Legendary" }
_G.SpaceSelectedItems = {}
_G.GemSelectedItems = {}

-- ============================================
-- [SEC-HELPERS] UTILITY FUNCTIONS
-- ============================================
-- Local reference untuk akses lebih pendek
local Settings = _G.Settings

-- Logging standar
local function log(mod, msg)
    print(string.format("[%s] %s", mod, msg))
end

local function logToggle(mod, state)
    log(mod, "Toggled: " .. (state and "ON" or "OFF"))
end

-- Safe call dengan traceback
local function safeCall(label, fn)
    local ok, res = xpcall(fn, function(err)
        return string.format("[ERROR][%s] %s\n%s", label, tostring(err), debug.traceback())
    end)
    if not ok then
        warn(res)
        return false, res
    end
    return true, res
end

-- Safe spawn dengan label
local function safeSpawn(label, fn)
    return task.spawn(function()
        safeCall(label, fn)
    end)
end

-- Loop interval helper
local function every(seconds, label, fn)
    task.spawn(function()
        while true do
            task.wait(seconds)
            safeCall(label, fn)
        end
    end)
end

-- ============================================
-- [SEC-ANTIAFK] SUPER ANTI-AFK V2
-- ============================================
log("ANTIAFK", "Loading Aggressive Anti-AFK...")
local VirtualUser = game:GetService("VirtualUser")
local Player = game:GetService("Players").LocalPlayer

Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
end)

-- Anti-AFK pulse setiap 60 detik
every(60, "AntiAFK.Pulse", function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ============================================
-- [SYS-AUTOWAKE] AUTO WAKE UP (HANDSHAKE)
-- ============================================
-- Simulasi klik fisik agar server merespon script
task.spawn(function()
    repeat task.wait() until Player.Character
    task.wait(1) -- Tunggu game loading sempurna
    
    print("[SYSTEM] Melakukan Klik Pancingan (Virtual Click)...")
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(500, 500))
    task.wait(0.1)
    VirtualUser:ClickButton1(Vector2.new(500, 500))
    print("[SYSTEM] Status Siap! Auto Click akan berjalan.")
end)

-- ============================================
-- [SEC-ANTIAFK] AUTO REJOIN (PS FRIENDLY)
-- ============================================
task.spawn(function()
    local Gui = game:GetService("CoreGui")
    local Teleport = game:GetService("TeleportService")
    Gui.ChildAdded:Connect(function(child)
        if child.Name == "RobloxPromptGui" then
            task.wait(5)
            Teleport:Teleport(game.PlaceId, Player)
        end
    end)
end)

-- ============================================
-- [MOD-REMOTES] REMOTE HANDLER (DYNAMIC DISCOVERY)
-- ============================================
-- IMPROVED: Dynamic remote discovery - no hardcoded indices!
local Remotes = {}
do
    local RS = game:GetService("ReplicatedStorage")
    local _remoteFolder, _eventsFolder, _functionsFolder = nil, nil, nil
    local _remoteCache = {} -- Cache untuk remote yang sudah ditemukan
    
    -- LEGACY: Backup index untuk fallback (jika dynamic gagal)
    Remotes.INDEX = { 
        FARM = 23, UNLOCK_ISLAND = 31, UPGRADE_JUMP = 34, 
        RANK_REWARD = 37, REBIRTH = 38, EGG_HATCH = 44, UPGRADE_STATS = 106 
    }
    
    -- Remote name mapping (nama yang diketahui dari game)
    Remotes.NAMES = {
        FARM = "Tap",
        UNLOCK_ISLAND = "UnlockIsland",
        UPGRADE_JUMP = "UpgradeJump",
        RANK_REWARD = "RankReward",
        REBIRTH = "Rebirth",
        EGG_HATCH = "OpenEgg",  -- Updated: was "HatchEgg", now "OpenEgg" (2026-02-06)
        UPGRADE_STATS = "UpgradeStats"
    }
    
    Remotes.UPGRADES = {
        "RebirthButtons", "FreeAutoClicker", "HatchSpeed", 
        "CriticalChance", "GoldenLuck", "AutoClickerSpeed", "ClickMultiplier"
    }
    
    function Remotes.getRemoteFolder()
        if _remoteFolder then return _remoteFolder end
        for _, child in pairs(RS:GetChildren()) do
            if child:IsA("Folder") and child:FindFirstChild("Events") and child:FindFirstChild("Functions") then
                _remoteFolder = child
                _eventsFolder = child:FindFirstChild("Events")
                _functionsFolder = child:FindFirstChild("Functions")
                log("REMOTES", "Found remote folder: " .. child.Name)
                return _remoteFolder
            end
        end
        warn("[REMOTES] Could not find remote folder!")
    end
    
    -- IMPROVED: Dynamic discovery by name
    function Remotes.findByName(targetName)
        -- Check cache first
        if _remoteCache[targetName] then
            return _remoteCache[targetName].remote, _remoteCache[targetName].type
        end
        
        Remotes.getRemoteFolder()
        
        -- Search in Events
        if _eventsFolder then
            for _, remote in pairs(_eventsFolder:GetChildren()) do
                if remote.Name == targetName or string.find(remote.Name:lower(), targetName:lower()) then
                    _remoteCache[targetName] = {remote = remote, type = "Event"}
                    log("REMOTES", "Found Event: " .. remote.Name)
                    return remote, "Event"
                end
            end
        end
        
        -- Search in Functions
        if _functionsFolder then
            for _, remote in pairs(_functionsFolder:GetChildren()) do
                if remote.Name == targetName or string.find(remote.Name:lower(), targetName:lower()) then
                    _remoteCache[targetName] = {remote = remote, type = "Function"}
                    log("REMOTES", "Found Function: " .. remote.Name)
                    return remote, "Function"
                end
            end
        end
        
        warn("[REMOTES] Remote not found: " .. targetName)
        return nil, nil
    end
    
    -- IMPROVED: Get remote with fallback to index
    function Remotes.getRemote(key)
        -- Try dynamic first
        local name = Remotes.NAMES[key]
        if name then
            local remote, remoteType = Remotes.findByName(name)
            if remote then return remote, remoteType end
        end
        
        -- Fallback to legacy index
        local index = Remotes.INDEX[key]
        if index then
            local remote = Remotes.getFunction(index) or Remotes.getEvent(index)
            if remote then
                warn("[REMOTES] Using fallback index for: " .. key)
                return remote, remote:IsA("RemoteFunction") and "Function" or "Event"
            end
        end
        
        return nil, nil
    end
    
    -- Legacy functions (untuk backward compatibility)
    function Remotes.getEvent(index)
        if not _eventsFolder then Remotes.getRemoteFolder() end
        if _eventsFolder then
            local c = _eventsFolder:GetChildren()
            if c[index] then return c[index] end
        end
        return nil
    end
    
    function Remotes.getFunction(index)
        if not _functionsFolder then Remotes.getRemoteFolder() end
        if _functionsFolder then
            local c = _functionsFolder:GetChildren()
            if c[index] then return c[index] end
        end
        return nil
    end
    
    -- Debug: List all remotes
    function Remotes.listAll()
        Remotes.getRemoteFolder()
        local list = {Events = {}, Functions = {}}
        if _eventsFolder then
            for i, r in ipairs(_eventsFolder:GetChildren()) do
                table.insert(list.Events, {index = i, name = r.Name})
            end
        end
        if _functionsFolder then
            for i, r in ipairs(_functionsFolder:GetChildren()) do
                table.insert(list.Functions, {index = i, name = r.Name})
            end
        end
        return list
    end
end

-- ============================================
-- [SEC-HELPERS] ERROR FEEDBACK (FLUENT NOTIFY)
-- ============================================
-- IMPROVED: Error feedback ke user via Fluent UI
local _FluentRef = nil -- Will be set after Fluent loads

local function notifyError(title, message)
    if _FluentRef then
        safeCall("Notify.Error", function()
            _FluentRef:Notify({
                Title = title,
                Content = message .. " (Buka F9 untuk detail)",
                Duration = 5
            })
        end)
    end
    warn("[" .. title .. "] " .. message)
end

local function notifySuccess(title, message)
    if _FluentRef then
        safeCall("Notify.Success", function()
            _FluentRef:Notify({
                Title = title,
                Content = message,
                Duration = 3
            })
        end)
    end
end

-- ============================================
-- [SEC-SAFEMODE] SAFE MODE CONFIG
-- ============================================
-- IMPROVED: Safe Mode untuk mengurangi risiko deteksi
_G.Settings.SafeMode = false
_G.Settings.SafeBurstAmount = 3      -- Burst lebih kecil
_G.Settings.SafeFarmDelay = 0.15     -- Delay lebih panjang

-- ============================================
-- [MOD-FARM] GOD MODE: BURST EDITION (SAFEMODE ENHANCED)
-- ============================================
-- IMPROVED: Added SafeMode with random delay for anti-detection
local Farm = {}
do
    -- Services
    local RS = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local VirtualUser = game:GetService("VirtualUser")
    
    -- Load Network Module Resmi
    local NetworkModule = require(RS.Modules.Network)
    
    -- Konfigurasi (Ubah angka ini untuk speed)
    getgenv().BurstAmount = 7
    
    -- IMPROVED: Random delay helper untuk anti-detection
    local function getRandomDelay()
        -- Returns random delay between -0.05 and +0.05
        return (math.random() - 0.5) * 0.1
    end
    
    -- IMPROVED: Get current burst amount based on SafeMode
    local function getCurrentBurstAmount()
        if Settings.SafeMode then
            return Settings.SafeBurstAmount or 3
        end
        return getgenv().BurstAmount or 7
    end
    
    function Farm.toggle(state)
        -- KUNCI UTAMA: Mengontrol Variable Global
        getgenv().AutoTap = state
        _G.Settings.AutoFarm = state
        logToggle("FARM", state)
        
        if state then
            local burstAmt = getCurrentBurstAmount()
            local mode = Settings.SafeMode and "SAFE MODE" or "BURST MODE"
            log("FARM", mode .. " AKTIF: " .. burstAmt .. " hits per frame")

            -- 1. Pancingan Awal (Sama persis)
            task.spawn(function()
                if Players.LocalPlayer.Character then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(500, 500))
                    task.wait(0.5)
                end
            end)

            -- 2. LOOP UTAMA (Enhanced with SafeMode)
            task.spawn(function()
                while getgenv().AutoTap do
                    -- Bungkus dalam pcall biar script gak mati kalau lag
                    local success, err = pcall(function()
                        local burstAmount = getCurrentBurstAmount()
                        for i = 1, burstAmount do
                            NetworkModule:FireServer("Tap", true, false, true)
                        end
                    end)
                    
                    if not success then
                        warn("[FARM] Server Lagging: " .. tostring(err))
                        notifyError("Farm Error", "Server lag detected")
                        task.wait(1)
                    end

                    -- IMPROVED: Delay with SafeMode and randomization
                    if Settings.SafeMode then
                        local delay = (Settings.SafeFarmDelay or 0.15) + getRandomDelay()
                        task.wait(math.max(0.05, delay))
                    else
                        RunService.Heartbeat:Wait()
                    end
                end
                log("FARM", "Auto Tap Stopped")
            end)
        else
            log("FARM", "Stopping...")
        end
    end
    
    function Farm.start()
        Farm.toggle(true)
    end
    
    function Farm.stop()
        Farm.toggle(false)
    end
    
    function Farm.isRunning()
        return getgenv().AutoTap or false
    end
    
    -- IMPROVED: Set SafeMode dinamis
    function Farm.setSafeMode(enabled)
        Settings.SafeMode = enabled
        logToggle("FARM.SafeMode", enabled)
        if enabled then
            notifySuccess("Safe Mode", "Farm berjalan dengan kecepatan aman")
        end
    end
end

-- ============================================
-- [MOD-REBIRTH] AUTO REBIRTH (NABUNG STRATEGY)
-- ============================================
local Rebirth = {}
do
    local _rebirthThread, _isRunning = nil, false
    function Rebirth.attemptRebirth()
        local rebirthRemote = Remotes.getFunction(Remotes.INDEX.REBIRTH)
        if not rebirthRemote then return false end
        for tier = 4, 1, -1 do
            local success, result = pcall(function() return rebirthRemote:InvokeServer(tier, nil) end)
            if success and result then return true, tier end
            task.wait(0.3)
        end
        return false
    end
    function Rebirth.start()
        if _isRunning then return end
        _isRunning = true
        _rebirthThread = task.spawn(function()
            while _isRunning and _G.Settings.AutoRebirth do
                for i = 1, (_G.Settings.NabungTime or 25) do if not _isRunning then break end task.wait(1) end
                if _isRunning then Rebirth.attemptRebirth() end
                task.wait(1)
            end
            _isRunning = false
        end)
    end
    function Rebirth.stop()
        _isRunning = false
        if _rebirthThread then
            task.cancel(_rebirthThread)
            _rebirthThread = nil
        end
        print("[REBIRTH] Stopped")
    end
    
    function Rebirth.toggle(enabled)
        _G.Settings.AutoRebirth = enabled
        logToggle("REBIRTH", enabled)
        if enabled then
            Rebirth.start()
        else
            Rebirth.stop()
        end
    end
    
    function Rebirth.forceRebirth()
        return Rebirth.attemptRebirth()
    end
end

-- ============================================
-- [MOD-EGGS] SMART HATCH (x8/x3 DETECT + SPEEDOMETER)
-- ============================================
print("[EGGS] Loading Smart Detect module...")
-- Eggs Speedometer Variables
local EggsHatchedPerSecond = 0
local EggsPerSecondDisplay = 0

local Eggs = {}
do
    local _eggThread, _isRunning = nil, false
    local _speedThread = nil
    local _discoveredEggs = {}
    local _currentHatchAmount = 1
    local _isCalibrated = false
    
    -- IMPROVED: Enhanced egg discovery with fallback
    function Eggs.discoverEggs()
        _discoveredEggs = {}
        local Workspace = game:GetService("Workspace")
        local foundFolders = false
        
        -- Primary method: Check known folders
        for _, folderName in pairs({"Eggs", "RobuxEggs"}) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                foundFolders = true
                for _, egg in pairs(folder:GetChildren()) do
                    if egg.Name ~= "Isl Folder" and not string.find(egg.Name, "Folder") then
                        if not table.find(_discoveredEggs, egg.Name) then
                            table.insert(_discoveredEggs, egg.Name)
                        end
                    end
                end
            end
        end
        
        -- IMPROVED: Fallback - scan workspace for models with "Egg" in name
        if not foundFolders or #_discoveredEggs == 0 then
            log("EGGS", "Standard folders not found, using fallback scan...")
            for _, child in pairs(Workspace:GetDescendants()) do
                if child:IsA("Model") and string.find(child.Name:lower(), "egg") then
                    if not table.find(_discoveredEggs, child.Name) then
                        table.insert(_discoveredEggs, child.Name)
                    end
                end
            end
        end
        
        -- Log discovery results
        if #_discoveredEggs > 0 then
            log("EGGS", "Discovered " .. #_discoveredEggs .. " eggs")
        else
            warn("[EGGS] No eggs found in workspace!")
            notifyError("Egg Discovery", "No eggs found")
        end
        
        table.sort(_discoveredEggs)
        return _discoveredEggs
    end
    
    function Eggs.getDiscoveredEggs() if #_discoveredEggs == 0 then Eggs.discoverEggs() end return _discoveredEggs end
    
    -- SMART DETECT: Read x8Egg/x3Egg from Gamepasses
    function Eggs.detectMaxHatch()
        local RS = game:GetService("ReplicatedStorage")
        local success, Replication = pcall(function() return require(RS.Game.Replication) end)
        if success and Replication then
            local attempts = 0
            while (not Replication.Data or not Replication.Data.Gamepasses) and attempts < 10 do task.wait(0.5) attempts = attempts + 1 end
            if Replication.Data and Replication.Data.Gamepasses then
                local gp = Replication.Data.Gamepasses
                if gp["x8Egg"] == true then print("[TapSim] Detect: x8 Hatch!") return 8
                elseif gp["x3Egg"] == true then print("[TapSim] Detect: x3 Hatch!") return 3
                else print("[TapSim] Detect: No pass (1x)") return 1 end
            end
        end
        return 1
    end
    
    function Eggs.start()
        if _isRunning then return end
        _isRunning = true
        _currentHatchAmount = Eggs.detectMaxHatch()
        
        -- Speedometer Monitor Thread
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
        
        -- Hatch Thread (Updated 2026-02-06: OpenEgg format)
        _eggThread = task.spawn(function()
            -- Use Network module instead of raw RemoteFunction
            local RS = game:GetService("ReplicatedStorage")
            local Network
            pcall(function() Network = require(RS.Modules.Network) end)
            
            if not Network then
                -- Fallback to old method
                local hatchRemote = Remotes.getFunction(Remotes.INDEX.EGG_HATCH)
                if not hatchRemote then _isRunning = false return end
                while _isRunning and _G.Settings.AutoHatch do
                    local eggName = _G.Settings.TargetEgg or "Basic"
                    local success = pcall(function() hatchRemote:InvokeServer(eggName, _currentHatchAmount, {}) end)
                    if success then EggsHatchedPerSecond = EggsHatchedPerSecond + _currentHatchAmount end
                    task.wait(_G.Settings.HatchDelay or 0.1)
                end
            else
                -- New method: Network:InvokeServer("OpenEgg", eggName, amount, autoDeleteTable)
                while _isRunning and _G.Settings.AutoHatch do
                    local eggName = _G.Settings.TargetEgg or "Basic"
                    local success = pcall(function()
                        Network:InvokeServer("OpenEgg", eggName, _currentHatchAmount, {})
                    end)
                    if success then
                        EggsHatchedPerSecond = EggsHatchedPerSecond + _currentHatchAmount
                    end
                    task.wait(_G.Settings.HatchDelay or 0.1)
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
    function Eggs.toggle(enabled) _G.Settings.AutoHatch = enabled if enabled then Eggs.start() else Eggs.stop() end end
    function Eggs.getSpeed() return EggsPerSecondDisplay end
    function Eggs.getHatchAmount() return _currentHatchAmount end
    function Eggs.isRunning() return _isRunning end
end

-- ============================================
-- [MOD-ISLANDS] ISLAND DISCOVERY & TELEPORT
-- ============================================
local Islands = {}
do
    local _islandThread, _isRunning = nil, false
    local _discoveredIslands = {}
    Islands.Locations = {
        ["Forest"] = CFrame.new(-235, 1225, 269), ["Winter"] = CFrame.new(-258, 2546, 354),
        ["Desert"] = CFrame.new(-95, 3510, 336), ["Jungle"] = CFrame.new(-304, 4421, 420),
        ["Heaven"] = CFrame.new(-397, 5847, 266), ["Dojo"] = CFrame.new(-402, 7626, 385),
        ["Volcano"] = CFrame.new(-281, 9192, 146), ["Candy"] = CFrame.new(-202, 10969, 399),
        ["Atlantis"] = CFrame.new(-432, 12950, 266), ["Space"] = CFrame.new(-278, 15334, 440),
        ["World 2"] = CFrame.new(1279, 651, -13267), ["Kryo"] = CFrame.new(1387, 1741, -13233),
        ["Magma"] = CFrame.new(1430, 3120, -12970), ["Celestial"] = CFrame.new(1260, 4164, -12939),
        ["Holographic"] = CFrame.new(1427, 5354, -12718), ["Lunar"] = CFrame.new(1472, 6855, -12914),
        ["Lucky Event"] = CFrame.new(-177.407364, 214.149719, 234.651199, 0.0380607843, -7.83694603e-08, 0.999275446, -5.23740029e-09, 1, 7.86257743e-08, -0.999275446, -8.22616375e-09, 0.0380607843)
    }
    function Islands.getLocationList() local n = {} for k,_ in pairs(Islands.Locations) do table.insert(n,k) end table.sort(n) return n end
    function Islands.discoverIslands()
        _discoveredIslands = {}
        local Zones = workspace:FindFirstChild("Zones")
        if not Zones then return _discoveredIslands end
        for _, fn in pairs({"Portals", "OldPortals"}) do
            local f = Zones:FindFirstChild(fn)
            if f then for _, p in pairs(f:GetChildren()) do if not table.find(_discoveredIslands, p.Name) then table.insert(_discoveredIslands, p.Name) end end end
        end
        return _discoveredIslands
    end
    function Islands.getDiscoveredIslands() if #_discoveredIslands == 0 then Islands.discoverIslands() end return _discoveredIslands end
    function Islands.unlockAll()
        local islands = Islands.getDiscoveredIslands()
        local unlockRemote = Remotes.getFunction(Remotes.INDEX.UNLOCK_ISLAND)
        if not unlockRemote then return end
        for _, name in pairs(islands) do pcall(function() unlockRemote:InvokeServer(name) end) task.wait(0.2) end
    end
    function Islands.start()
        if _isRunning then return end
        _isRunning = true
        Islands.discoverIslands()
        _islandThread = task.spawn(function()
            while _isRunning and _G.Settings.AutoIsland do Islands.unlockAll() for i=1,30 do if not _isRunning then break end task.wait(1) end end
            _isRunning = false
        end)
    end
    function Islands.stop() _isRunning = false if _islandThread then task.cancel(_islandThread) _islandThread = nil end end
    function Islands.toggle(enabled) _G.Settings.AutoIsland = enabled if enabled then Islands.start() else Islands.stop() end end
    function Islands.teleportTo(name)
        local Char = Player.Character
        if not Char or not Char:FindFirstChild("HumanoidRootPart") then return false end
        local HRP = Char.HumanoidRootPart
        local cf = Islands.Locations[name]
        if cf then
            HRP.Anchored = true
            HRP.CFrame = cf
            task.wait(0.5)
            HRP.Anchored = false
            return true
        end
        return false
    end
end

-- ============================================
-- [MOD-UPGRADES] STATS AUTO UPGRADE
-- ============================================
local Upgrades = {}
do
    local _upgradeThread, _isRunning = nil, false
    function Upgrades.upgradeAllStats()
        local remote = Remotes.getFunction(Remotes.INDEX.UPGRADE_STATS)
        if not remote then return end
        for _, stat in pairs(Remotes.UPGRADES) do pcall(function() remote:InvokeServer(stat, nil) end) task.wait(0.2) end
    end
    function Upgrades.upgradeJump()
        local remote = Remotes.getFunction(Remotes.INDEX.UPGRADE_JUMP)
        if remote then pcall(function() remote:InvokeServer("Main") end) end
    end
    function Upgrades.start()
        if _isRunning then return end
        _isRunning = true
        _upgradeThread = task.spawn(function()
            while _isRunning and (_G.Settings.AutoUpgrade or _G.Settings.AutoJump) do
                if _G.Settings.AutoUpgrade then Upgrades.upgradeAllStats() end
                if _G.Settings.AutoJump then Upgrades.upgradeJump() end
                for i=1,(_G.Settings.UpgradeDelay or 3) do if not _isRunning then break end task.wait(1) end
            end
            _isRunning = false
        end)
    end
    function Upgrades.stop() _isRunning = false if _upgradeThread then task.cancel(_upgradeThread) _upgradeThread = nil end end
    function Upgrades.toggleUpgrade(e) _G.Settings.AutoUpgrade = e if e or _G.Settings.AutoJump then if not _isRunning then Upgrades.start() end else Upgrades.stop() end end
    function Upgrades.toggleJump(e) _G.Settings.AutoJump = e if e or _G.Settings.AutoUpgrade then if not _isRunning then Upgrades.start() end else Upgrades.stop() end end
end

-- ============================================
-- [MOD-REWARDS] RANK REWARDS CLAIM
-- ============================================
local Rewards = {}
do
    function Rewards.claimRankReward()
        local remote = Remotes.getFunction(Remotes.INDEX.RANK_REWARD)
        if remote then
            safeCall("Rewards.Claim", function()
                remote:InvokeServer()
            end)
        end
    end
    
    function Rewards.startAutoReward()
        every(300, "Rewards.AutoLoop", function()
            if Settings.AutoRankReward then
                Rewards.claimRankReward()
            end
        end)
    end
    
    function Rewards.toggle(e)
        Settings.AutoRankReward = e
        logToggle("REWARDS", e)
        if e then
            Rewards.claimRankReward()
        end
    end
end
Rewards.startAutoReward()

-- ============================================
-- [MOD-PETS] AUTO EQUIP BEST
-- ============================================
local Pets = {}
do
    local _signal = nil
    
    function Pets.getSignal()
        if not _signal then
            local RS = game:GetService("ReplicatedStorage")
            local m = RS:FindFirstChild("Modules")
            if m and m:FindFirstChild("Signal") then
                _signal = require(m.Signal)
            end
        end
        return _signal
    end
    
    function Pets.equipBest()
        local sig = Pets.getSignal()
        if sig then
            safeCall("Pets.EquipBest", function()
                sig.Fire("EquipBest")
            end)
        end
    end
    
    function Pets.startAutoEquip()
        every(5, "Pets.AutoEquip", function()
            if Settings.AutoEquip then
                Pets.equipBest()
            end
        end)
    end
    
    function Pets.toggle(e)
        Settings.AutoEquip = e
        logToggle("PETS", e)
        if e then
            Pets.equipBest()
        end
    end
end
Pets.startAutoEquip()

-- ============================================
-- [MOD-DELETE] AUTO DELETE BY RARITY
-- ============================================
local AutoDelete = {}
do
    local _network, _replication, _petStats = nil, nil, nil
    AutoDelete.RarityList = {"None", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
    
    function AutoDelete.getModules()
        if not _network then
            local RS = game:GetService("ReplicatedStorage")
            local m = RS:FindFirstChild("Modules")
            local g = RS:FindFirstChild("Game")
            if m and m:FindFirstChild("Network") then
                _network = require(m.Network)
            end
            if g and g:FindFirstChild("Replication") then
                _replication = require(g.Replication)
            end
            if g and g:FindFirstChild("PetStats") then
                _petStats = require(g.PetStats)
            end
        end
        return _network, _replication, _petStats
    end
    
    function AutoDelete.runDelete()
        local net, rep, stats = AutoDelete.getModules()
        if not net or not rep or not rep.Data or not rep.Data.Pets then
            return 0
        end
        
        local deleted = 0
        for id, pet in pairs(rep.Data.Pets) do
            if not _G.DeleteSettings.Enabled then
                break
            end
            if not pet.Equipped and not pet.Locked then
                local rarity = "Common"
                if stats then
                    safeCall("AutoDelete.GetRarity", function()
                        rarity = stats:GetRarity(pet.Name)
                    end)
                end
                
                local shouldDelete = _G.DeleteSettings.SelectedRarities[rarity]
                if pet.Tier == "Golden" and _G.DeleteSettings.KeepGolden then
                    shouldDelete = false
                end
                if pet.Tier == "Rainbow" and _G.DeleteSettings.KeepRainbow then
                    shouldDelete = false
                end
                if rarity == "Secret" or pet.Huge or pet.Exclusive then
                    shouldDelete = false
                end
                
                if shouldDelete then
                    safeCall("AutoDelete.Delete", function()
                        net:InvokeServer("DeletePet", id)
                    end)
                    deleted = deleted + 1
                    task.wait(0.1)
                end
            end
        end
        return deleted
    end
    
    function AutoDelete.start()
        every(1, "AutoDelete.Loop", function()
            if _G.DeleteSettings.Enabled then
                AutoDelete.runDelete()
            end
        end)
    end
end
AutoDelete.start()

-- ============================================
-- [MOD-SMARTSAVE] DATA CACHE FOR ISLAND BUYING
-- ============================================
local SmartSave = {}
do
    local _replication, _islandUpgrades = nil, nil
    function SmartSave.getModules()
        if not _replication then
            local RS = game:GetService("ReplicatedStorage")
            local g = RS:FindFirstChild("Game")
            if g then
                if g:FindFirstChild("Replication") then _replication = require(g.Replication) end
                if g:FindFirstChild("IslandUpgrades") then _islandUpgrades = require(g.IslandUpgrades) end
            end
        end
        return _replication, _islandUpgrades
    end
    function SmartSave.isSafeToSpend()
        if not _G.SmartSave.Enabled then return true end
        local rep, islands = SmartSave.getModules()
        if not rep or not islands then return true end
        local clicks, price = 0, 0
        pcall(function() clicks = rep.Data.Clicks or 0 end)
        pcall(function() price = islands:GetPrice() end)
        if price > 0 and clicks >= (price * _G.SmartSave.Threshold) then return false end
        return true
    end
end

-- ============================================
-- [MOD-BESTISLE] AUTO TELEPORT TO BEST ISLAND
-- ============================================
local AutoBestIsland = {}
do
    local _thread, _replication = nil, nil
    local IslandOrder = {"Forest", "Winter", "Desert", "Jungle", "Heaven", "Dojo", "Volcano", "Candy", "Atlantis", "Space", "Kryo", "Magma", "Celestial", "Holographic", "Lunar"}
    function AutoBestIsland.getReplication()
        if not _replication then
            local RS = game:GetService("ReplicatedStorage")
            local g = RS:FindFirstChild("Game")
            if g and g:FindFirstChild("Replication") then _replication = require(g.Replication) end
        end
        return _replication
    end
    function AutoBestIsland.getBestIsland()
        local rep = AutoBestIsland.getReplication()
        if not rep or not rep.Data then return "Forest" end
        local portals = rep.Data.Portals or {}
        local best = "Forest"
        for _, name in ipairs(IslandOrder) do if portals[name] == true then best = name end end
        return best
    end
    function AutoBestIsland.teleportToBest()
        local best = AutoBestIsland.getBestIsland()
        local LP = game.Players.LocalPlayer
        local cf = Islands.Locations[best]
        if cf and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = cf
            return true
        end
        return false
    end
    function AutoBestIsland.start()
        if _thread then return end
        _thread = task.spawn(function() while true do if _G.AutoGoBest then pcall(AutoBestIsland.teleportToBest) end task.wait(10) end end)
    end
    function AutoBestIsland.toggle(e) _G.AutoGoBest = e if e then AutoBestIsland.teleportToBest() end end
end
AutoBestIsland.start()

-- ============================================
-- [MOD-CRAFT] AUTO GOLDEN/RAINBOW CRAFT
-- ============================================
local AutoCraft = {}
do
    local _goldenEnabled, _rainbowEnabled, _claimEnabled = false, false, true
    local _delay, _savedPos = 0.5, nil
    local RS = game:GetService("ReplicatedStorage")
    local LP = game.Players.LocalPlayer
    local Network, Replication
    pcall(function() Network = require(RS.Modules.Network) Replication = require(RS.Game.Replication) end)
    local _machineCache = {}
    local function TeleportTo(cf) if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then LP.Character.HumanoidRootPart.CFrame = cf end end
    local function FindMachinePart(name)
        if _machineCache[name] and _machineCache[name].Parent then return _machineCache[name] end
        local target = workspace:FindFirstChild(name, true) or workspace:FindFirstChild(name:gsub("Machine", " Machine"), true)
        if target then
            local result
            if target:IsA("Model") then result = target:FindFirstChild("Pad") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
            elseif target:IsA("BasePart") then result = target end
            if result then _machineCache[name] = result end
            return result
        end
    end
    function AutoCraft.clearCache() table.clear(_machineCache) end
    local function IsNearMachine()
        if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return false end
        local pos = LP.Character.HumanoidRootPart.Position
        local g, r = FindMachinePart("GoldenMachine"), FindMachinePart("RainbowMachine")
        if g and (pos - g.Position).Magnitude < 50 then return true end
        if r and (pos - r.Position).Magnitude < 50 then return true end
        return false
    end
    local function CheckAndClaim()
        if not _claimEnabled or not Replication or not Replication.Data then return end
        local cp = Replication.Data.CraftingPets
        if cp and cp.Rainbow then
            local now = workspace:GetServerTimeNow()
            for id, data in pairs(cp.Rainbow) do
                if data.EndTime and (data.EndTime - now) <= 0 then pcall(function() Network:InvokeServer("ClaimRainbow", id) end) end
            end
        end
    end
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
    local function CraftProcess()
        if not Replication or not Replication.Data or not Replication.Data.Pets then return end
        if not IsNearMachine() and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then _savedPos = LP.Character.HumanoidRootPart.CFrame end
        if _goldenEnabled and HasCraftableBatch("Normal") then
            local machine = FindMachinePart("GoldenMachine")
            if machine then
                if not IsNearMachine() then TeleportTo(machine.CFrame + Vector3.new(0, 3, 0)) task.wait(0.5) end
                while _goldenEnabled do
                    local groups, batch = {}, nil
                    for id, pet in pairs(Replication.Data.Pets) do
                        if not pet.Equipped and not pet.Locked and pet.Tier == "Normal" then
                            if not groups[pet.Name] then groups[pet.Name] = {} end
                            table.insert(groups[pet.Name], id)
                            if #groups[pet.Name] >= 5 then batch = {groups[pet.Name][1], groups[pet.Name][2], groups[pet.Name][3], groups[pet.Name][4], groups[pet.Name][5]} break end
                        end
                    end
                    if batch then Network:InvokeServer("CraftPets", batch) task.wait(_delay) else break end
                end
                if _savedPos then TeleportTo(_savedPos) end
                return
            end
        end
        if _rainbowEnabled then
            local usedSlots = 0
            if Replication.Data.CraftingPets and Replication.Data.CraftingPets.Rainbow then for _ in pairs(Replication.Data.CraftingPets.Rainbow) do usedSlots = usedSlots + 1 end end
            if usedSlots < 3 and HasCraftableBatch("Golden") then
                local machine = FindMachinePart("RainbowMachine")
                if machine then
                    if not IsNearMachine() then TeleportTo(machine.CFrame + Vector3.new(0, 3, 0)) task.wait(0.5) end
                    while _rainbowEnabled do
                        local currSlots = 0
                        if Replication.Data.CraftingPets and Replication.Data.CraftingPets.Rainbow then for _ in pairs(Replication.Data.CraftingPets.Rainbow) do currSlots = currSlots + 1 end end
                        if currSlots >= 3 then break end
                        local groups, batch = {}, nil
                        for id, pet in pairs(Replication.Data.Pets) do
                            if not pet.Equipped and not pet.Locked and pet.Tier == "Golden" then
                                if not groups[pet.Name] then groups[pet.Name] = {} end
                                table.insert(groups[pet.Name], id)
                                if #groups[pet.Name] >= 5 then batch = {groups[pet.Name][1], groups[pet.Name][2], groups[pet.Name][3], groups[pet.Name][4], groups[pet.Name][5]} break end
                            end
                        end
                        if batch then Network:InvokeServer("StartRainbow", batch) task.wait(_delay) else break end
                    end
                    if _savedPos then TeleportTo(_savedPos) end
                    return
                end
            end
        end
    end
    function AutoCraft.toggleGolden(val)
        _goldenEnabled = val
        if val then task.spawn(function() while _goldenEnabled do pcall(CheckAndClaim) pcall(CraftProcess) task.wait(3) end end) end
    end
    function AutoCraft.toggleRainbow(val)
        _rainbowEnabled = val
        if val then task.spawn(function() while _rainbowEnabled do pcall(CheckAndClaim) pcall(CraftProcess) task.wait(3) end end) end
    end
    function AutoCraft.toggleClaim(val) _claimEnabled = val end
    function AutoCraft.setDelay(val) _delay = val end
end

-- ============================================
-- [MOD-MERCHANT] DUAL SHOP (SPACE + GEM)
-- ============================================
local Merchant = {}
do
    local _spaceBuyEnabled, _gemBuyEnabled = false, false
    local _buyDelay = 0.1
    
    Merchant.SpaceItems = {"Space Luck I", "Space Tap I", "Space Rebirths I", "Totem of Luck", "Totem of Secret Luck", "Totem of Hatch Speed", "TeleportCrystal"}
    Merchant.GemItems = {"Luck Potion II", "Tap Potion II", "Rebirth Potion II", "Totem of Clicks", "Treat Bag", "TeleportCrystal"}
    
    local function GetMerchantRemote()
        local RS = game:GetService("ReplicatedStorage")
        for _, folder in pairs(RS:GetChildren()) do
            if folder:IsA("Folder") then
                local funcs = folder:FindFirstChild("Functions")
                if funcs then for _, remote in pairs(funcs:GetChildren()) do if remote:IsA("RemoteFunction") then return remote end end end
            end
        end
    end
    
    function Merchant.buy(merchantType, itemName)
        local remote = GetMerchantRemote()
        if remote then pcall(function() remote:InvokeServer(merchantType, itemName) end) return true end
        return false
    end
    
    function Merchant.setSpaceItems(itemTable)
        _G.SpaceSelectedItems = {}
        for item, selected in pairs(itemTable) do if selected then table.insert(_G.SpaceSelectedItems, item) end end
    end
    
    function Merchant.setGemItems(itemTable)
        _G.GemSelectedItems = {}
        for item, selected in pairs(itemTable) do if selected then table.insert(_G.GemSelectedItems, item) end end
    end
    
    function Merchant.toggleSpaceBuy(val)
        _spaceBuyEnabled = val
        if val then
            task.spawn(function()
                while _spaceBuyEnabled do
                    for _, item in ipairs(_G.SpaceSelectedItems or {}) do Merchant.buy("SpaceMerchant", item) task.wait(_buyDelay) end
                    task.wait(0.5)
                end
            end)
        end
    end
    
    function Merchant.toggleGemBuy(val)
        _gemBuyEnabled = val
        if val then
            task.spawn(function()
                while _gemBuyEnabled do
                    for _, item in ipairs(_G.GemSelectedItems or {}) do Merchant.buy("GemMerchant", item) task.wait(_buyDelay) end
                    task.wait(0.5)
                end
            end)
        end
    end
    
    function Merchant.setDelay(val) _buyDelay = val end
    function Merchant.getSpaceItems() return Merchant.SpaceItems end
    function Merchant.getGemItems() return Merchant.GemItems end
end

-- ============================================
-- [MOD-WEBHOOK] DISCORD NOTIFICATIONS
-- ============================================
local Webhook = {}
do
    local _scanning, _knownPets = false, {}
    local RarityRank = {["Common"]=1,["Uncommon"]=2,["Rare"]=3,["Epic"]=4,["Legendary"]=5,["Mythic"]=6,["Secret"]=99}
    local RS = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local Replication, PetStats
    pcall(function() Replication = require(RS.Game.Replication) PetStats = require(RS.Game.PetStats) end)
    
    function Webhook.init()
        if Replication and Replication.Data and Replication.Data.Pets then
            for id, _ in pairs(Replication.Data.Pets) do _knownPets[id] = true end
        end
    end
    
    local function sendToDiscord(petName, petRarity, petTier)
        if _G.WebhookSettings.Url == "" then return end
        local color = 16776960
        if petRarity == "Mythic" then color = 10038562 end
        if petRarity == "Secret" then color = 0 end
        local LP = game.Players.LocalPlayer
        local payload = {embeds = {{title = petRarity:upper() .. " HATCHED!", color = color, fields = {{name = "Player", value = LP.Name}, {name = "Pet", value = petName, inline = true}, {name = "Rarity", value = petRarity, inline = true}, {name = "Tier", value = petTier, inline = true}}, thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png"}, footer = {text = "TapSim Hub"}}}}
        pcall(function() request({Url = _G.WebhookSettings.Url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)}) end)
    end
    
    function Webhook.startLoop()
        if _scanning then return end
        _scanning = true
        task.spawn(function() task.wait(3) Webhook.init() end)
        task.spawn(function()
            while true do
                if _G.WebhookSettings.Enabled and Replication and Replication.Data and Replication.Data.Pets then
                    for id, petData in pairs(Replication.Data.Pets) do
                        if not _knownPets[id] then
                            _knownPets[id] = true
                            local rarity = "Common"
                            if PetStats and PetStats.GetRarity then pcall(function() rarity = PetStats:GetRarity(petData.Name) rarity = rarity:sub(1,1):upper() .. rarity:sub(2):lower() end) end
                            local myRank = RarityRank[rarity] or 1
                            local targetRank = RarityRank[_G.WebhookSettings.MinRarity] or 5
                            if myRank >= targetRank then sendToDiscord(petData.Name, rarity, petData.Tier or "Normal") end
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end
    function Webhook.toggle(val) _G.WebhookSettings.Enabled = val end
    
    -- IMPROVED V3.2: Webhook URL Validation
    function Webhook.setUrl(val)
        -- Validate Discord webhook URL
        local isValid = string.match(val, "^https://discord%.com/api/webhooks/") or 
                        string.match(val, "^https://discordapp%.com/api/webhooks/")
        if val == "" then
            _G.WebhookSettings.Url = ""
            return true
        elseif isValid then
            _G.WebhookSettings.Url = val
            log("WEBHOOK", "Valid URL set")
            return true
        else
            warn("[WEBHOOK] Invalid URL: " .. val)
            return false
        end
    end
    
    function Webhook.validateAndNotify(val, Fluent)
        if Webhook.setUrl(val) then
            if val ~= "" then
                Fluent:Notify({Title="Webhook", Content="URL Saved!", Duration=2})
            end
        else
            Fluent:Notify({Title="Error", Content="Invalid Webhook URL!\nMust start with https://discord.com/api/webhooks/", Duration=4})
        end
    end
    
    function Webhook.setRarity(val) _G.WebhookSettings.MinRarity = val end
end
Webhook.startLoop()

-- ============================================
-- [MOD-ELECTRIC] AUTO ELECTRIC WHEEL SPIN (GHOST EVENT)
-- ============================================
-- IMPROVED V3.2: Ghost event spin - remote masih aktif!
local ElectricSpin = {}
do
    local _isSpinning = false
    local _spinThread = nil
    local _spinDelay = 0.5 -- Delay antar spin (detik)
    local _totalSpins = 0
    local _lastReward = nil
    
    local RS = game:GetService("ReplicatedStorage")
    local Network
    pcall(function() Network = require(RS.Modules.Network) end)
    
    function ElectricSpin.spin()
        if not Network then
            warn("[ELECTRIC] Network module not found!")
            return nil
        end
        
        local success, result = pcall(function()
            return Network:InvokeServer("SpinWheel", "ElectricSpinWheel")
        end)
        
        if success and result then
            _totalSpins = _totalSpins + 1
            _lastReward = result[1] or "Unknown"
            log("ELECTRIC", "Spin #" .. _totalSpins .. " | Reward: " .. tostring(_lastReward))
            return result
        else
            return nil
        end
    end
    
    function ElectricSpin.start()
        if _isSpinning then return end
        _isSpinning = true
        _totalSpins = 0
        
        log("ELECTRIC", "Starting Auto Spin...")
        notifySuccess("Electric Wheel", "Auto Spin Started!")
        
        _spinThread = task.spawn(function()
            while _isSpinning do
                local result = ElectricSpin.spin()
                
                if not result then
                    -- Gagal spin, mungkin tiket habis
                    warn("[ELECTRIC] Spin failed. Tiket habis atau cooldown.")
                    task.wait(2) -- Tunggu lebih lama
                else
                    task.wait(_spinDelay)
                end
            end
            log("ELECTRIC", "Stopped. Total spins: " .. _totalSpins)
        end)
    end
    
    function ElectricSpin.stop()
        _isSpinning = false
        if _spinThread then
            pcall(function() task.cancel(_spinThread) end)
            _spinThread = nil
        end
        log("ELECTRIC", "Stopped")
    end
    
    function ElectricSpin.toggle(state)
        if state then
            ElectricSpin.start()
        else
            ElectricSpin.stop()
        end
    end
    
    function ElectricSpin.setDelay(delay)
        _spinDelay = math.max(0.1, delay) -- Minimum 0.1s
    end
    
    function ElectricSpin.getStats()
        return {
            isRunning = _isSpinning,
            totalSpins = _totalSpins,
            lastReward = _lastReward
        }
    end
end

-- ============================================
-- [MOD-LUCKYBLOCK] AUTO LUCKY BLOCK FARM
-- ============================================
-- Based on Gemini Technical Brief (2026-02-06)
local LuckyBlock = {}
do
    local _isRunning = false
    local _farmThread = nil
    local _totalCollected = 0
    local _teleportEnabled = true
    local _farmDelay = 0.25
    
    local Services = {
        Players = game:GetService("Players"),
        Workspace = game:GetService("Workspace"),
        RS = game:GetService("ReplicatedStorage")
    }
    local LocalPlayer = Services.Players.LocalPlayer
    
    -- Get network remote
    local function getRemote()
        local remote
        pcall(function()
            remote = require(Services.RS.Modules.Network)
        end)
        return remote
    end
    
    -- Collect falling blocks from sky
    function LuckyBlock.collectFalling()
        local Network = getRemote()
        if not Network then return 0 end
        
        local collected = 0
        for _, obj in pairs(Services.Workspace:GetChildren()) do
            -- Identify falling lucky blocks
            if obj:GetAttribute("Index") and obj:FindFirstChild("PrimaryPart") and not obj:GetAttribute("Opened") then
                local uid = obj.Name
                
                -- Teleport to block
                if _teleportEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        LocalPlayer.Character.HumanoidRootPart.CFrame = obj.PrimaryPart.CFrame + Vector3.new(0, 2, 0)
                    end)
                    task.wait(0.05)
                end
                
                -- Collect
                pcall(function()
                    Network:FireServer("LuckyBlockEvent", "Collect", uid)
                    collected = collected + 1
                end)
            end
        end
        return collected
    end
    
    -- Open placed blocks on map
    function LuckyBlock.openPlaced()
        local Network = getRemote()
        if not Network then return 0 end
        
        local folder = Services.Workspace:FindFirstChild("PlacedLuckyBlocks")
        if not folder then return 0 end
        
        local opened = 0
        for _, block in pairs(folder:GetChildren()) do
            local model = block:FindFirstChild("LuckyBlockModel")
            if model and model.PrimaryPart then
                local blockId = block:GetAttribute("BlockId") or block.Name
                
                if _teleportEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        LocalPlayer.Character.HumanoidRootPart.CFrame = model.PrimaryPart.CFrame
                    end)
                end
                
                pcall(function()
                    if Network.InvokeServer then
                        Network:InvokeServer("OpenWorldLuckyBlock", blockId)
                    else
                        Network:FireServer("OpenWorldLuckyBlock", blockId)
                    end
                    opened = opened + 1
                end)
            end
        end
        return opened
    end
    
    function LuckyBlock.start()
        if _isRunning then return end
        _isRunning = true
        log("LUCKYBLOCK", "Started auto-farm")
        
        _farmThread = task.spawn(function()
            while _isRunning do
                local c1 = LuckyBlock.collectFalling()
                local c2 = LuckyBlock.openPlaced()
                _totalCollected = _totalCollected + c1 + c2
                task.wait(_farmDelay)
            end
        end)
    end
    
    function LuckyBlock.stop()
        _isRunning = false
        if _farmThread then
            pcall(function() task.cancel(_farmThread) end)
            _farmThread = nil
        end
        log("LUCKYBLOCK", "Stopped. Total: " .. _totalCollected)
    end
    
    function LuckyBlock.toggle(state)
        if state then LuckyBlock.start() else LuckyBlock.stop() end
    end
    
    function LuckyBlock.setTeleport(enabled)
        _teleportEnabled = enabled
    end
    
    function LuckyBlock.setDelay(delay)
        _farmDelay = math.max(0.1, delay)
    end
    
    function LuckyBlock.getStats()
        return { isRunning = _isRunning, totalCollected = _totalCollected }
    end
    
    -- ========== ADVANCED FEATURES ==========
    
    -- Feature 4: Auto Craft Keys (Convert Pet to Key)
    -- @param rarity: "Legendary" or "Mythic"
    function LuckyBlock.craftKey(rarity)
        local Network = getRemote()
        if Network and Network.InvokeServer then
            local success, result = pcall(function()
                return Network:InvokeServer("CraftLuckyBlockKey", rarity or "Legendary", "Galaxy")
            end)
            if success and result then
                log("LUCKYBLOCK", "Crafted " .. (rarity or "Legendary") .. " key")
                return true
            end
        end
        return false
    end
    
    -- Feature 5: Auto Generator (Create Block from Essence)
    -- @param blockName: e.g. "Starry Lucky Block", "Rainbow Lucky Block"
    function LuckyBlock.generateBlock(blockName)
        local Network = getRemote()
        if Network and Network.InvokeServer then
            local success, result = pcall(function()
                return Network:InvokeServer("CreateLuckyBlock", blockName or "Starry Lucky Block")
            end)
            if success and result then
                log("LUCKYBLOCK", "Generated: " .. (blockName or "Starry Lucky Block"))
                return true
            end
        end
        return false
    end
    
    -- Feature 6: Get Player Lucky Block Data
    function LuckyBlock.getPlayerData()
        local Network = getRemote()
        if Network and Network.InvokeServer then
            local success, data = pcall(function()
                return Network:InvokeServer("GetLuckyBlockData", "Galaxy")
            end)
            if success and data then
                return {
                    Keys = data.Keys or 0,
                    SuperCharged = data.SuperCharged or 0,
                    Pity = data.Pity or 0
                }
            end
        end
        return { Keys = 0, SuperCharged = 0, Pity = 0 }
    end
    
    -- Feature 7: Auto Gacha (Open Galaxy Block)
    -- @param amount: 1, 3, or 10
    function LuckyBlock.openGalaxy(amount)
        local Network = getRemote()
        if Network and Network.InvokeServer then
            local success, result = pcall(function()
                return Network:InvokeServer("OpenLuckyBlock", amount or 1, "Galaxy")
            end)
            if success then
                log("LUCKYBLOCK", "Opened " .. (amount or 1) .. "x Galaxy block")
                return result
            end
        end
        return nil
    end
    
    -- Auto Craft Loop variables
    local _craftThread = nil
    local _craftRunning = false
    local _craftRarity = "Legendary"
    local _craftDelay = 1
    
    function LuckyBlock.startCrafting()
        if _craftRunning then return end
        _craftRunning = true
        log("LUCKYBLOCK", "Started auto-craft keys (" .. _craftRarity .. ")")
        
        _craftThread = task.spawn(function()
            while _craftRunning do
                LuckyBlock.craftKey(_craftRarity)
                task.wait(_craftDelay)
            end
        end)
    end
    
    function LuckyBlock.stopCrafting()
        _craftRunning = false
        if _craftThread then
            pcall(function() task.cancel(_craftThread) end)
            _craftThread = nil
        end
        log("LUCKYBLOCK", "Stopped auto-craft")
    end
    
    function LuckyBlock.toggleCrafting(state)
        if state then LuckyBlock.startCrafting() else LuckyBlock.stopCrafting() end
    end
    
    function LuckyBlock.setCraftRarity(rarity)
        _craftRarity = rarity or "Legendary"
    end
    
    -- Auto Generator Loop variables
    local _genThread = nil
    local _genRunning = false
    local _targetBlock = "Starry Lucky Block"
    local _genDelay = 5
    
    function LuckyBlock.startGenerator()
        if _genRunning then return end
        _genRunning = true
        log("LUCKYBLOCK", "Started auto-generator (" .. _targetBlock .. ")")
        
        _genThread = task.spawn(function()
            while _genRunning do
                LuckyBlock.generateBlock(_targetBlock)
                task.wait(_genDelay)
            end
        end)
    end
    
    function LuckyBlock.stopGenerator()
        _genRunning = false
        if _genThread then
            pcall(function() task.cancel(_genThread) end)
            _genThread = nil
        end
        log("LUCKYBLOCK", "Stopped auto-generator")
    end
    
    function LuckyBlock.toggleGenerator(state)
        if state then LuckyBlock.startGenerator() else LuckyBlock.stopGenerator() end
    end
    
    function LuckyBlock.setTargetBlock(blockName)
        _targetBlock = blockName or "Starry Lucky Block"
    end
    
    -- Auto Gacha Loop variables
    local _gachaThread = nil
    local _gachaRunning = false
    local _gachaAmount = 1
    local _gachaDelay = 0.5
    
    function LuckyBlock.startGacha()
        if _gachaRunning then return end
        _gachaRunning = true
        log("LUCKYBLOCK", "Started auto-gacha (" .. _gachaAmount .. "x)")
        
        _gachaThread = task.spawn(function()
            while _gachaRunning do
                LuckyBlock.openGalaxy(_gachaAmount)
                task.wait(_gachaDelay)
            end
        end)
    end
    
    function LuckyBlock.stopGacha()
        _gachaRunning = false
        if _gachaThread then
            pcall(function() task.cancel(_gachaThread) end)
            _gachaThread = nil
        end
        log("LUCKYBLOCK", "Stopped auto-gacha")
    end
    
    function LuckyBlock.toggleGacha(state)
        if state then LuckyBlock.startGacha() else LuckyBlock.stopGacha() end
    end
    
    function LuckyBlock.setGachaAmount(amount)
        _gachaAmount = amount or 1
    end
end

-- ============================================
-- [MOD-ENCHANT] AUTO GOD-ROLL ENCHANT (RNG BYPASS)
-- ============================================
-- IMPROVED V3.2: Brute-force enchant sampai dapat target
local Enchant = {}
do
    local _isEnchanting = false
    local _enchantThread = nil
    local _totalRolls = 0
    local _lastEnchant = nil
    local _targetPetUUID = nil
    
    local RS = game:GetService("ReplicatedStorage")
    local Network, Replication
    pcall(function() 
        Network = require(RS.Modules.Network) 
        Replication = require(RS.Game.Replication)
    end)
    
    -- Config
    _G.EnchantSettings = _G.EnchantSettings or {
        TargetPet = "",
        TargetEnchant = "Secret Hunter",
        Speed = 0.05,
        AutoStop = true
    }
    
    -- Available enchants (from game's EnchantData module)
    -- Sorted by rarity (rarest first)
    Enchant.ENCHANTS = {
        "Secret Hunter",    -- 0.1%  - +4% Secret Hatch Chance
        "Rainbow Hunter",   -- 0.15% - 1% Chance Rainbow Pets
        "Golden Hunter",    -- 0.35% - 2% Chance Golden Pets
        "Luck III",         -- 1%    - +20% Luck
        "Taps II",          -- 6%    - +10% Taps
        "Gems II",          -- 6%    - +10% Gems
        "Rebirths II",      -- 6%    - +10% Rebirths
        "Luck II",          -- 6%    - +10% Luck
        "Taps I",           -- 20%   - +5% Taps
        "Gems I",           -- 20%   - +5% Gems
        "Rebirths I",       -- 20%   - +5% Rebirths
        "Luck I"            -- 20%   - +5% Luck
    }
    
    -- Internal mapping: display string -> UUID
    local _petDisplayMap = {}
    
    -- Format power number (e.g., 118960000 -> "118.96M")
    local function formatPower(num)
        if not num or num == 0 then return "0" end
        if num >= 1e12 then return string.format("%.2fT", num / 1e12)
        elseif num >= 1e9 then return string.format("%.2fB", num / 1e9)
        elseif num >= 1e6 then return string.format("%.2fM", num / 1e6)
        elseif num >= 1e3 then return string.format("%.2fK", num / 1e3)
        else return tostring(math.floor(num)) end
    end
    
    -- Get pet UUID by display string (from dropdown)
    function Enchant.getPetUUID(displayString)
        if _petDisplayMap[displayString] then
            return _petDisplayMap[displayString].uuid, _petDisplayMap[displayString].data
        end
        return nil
    end
    
    -- Get all pets list with full details
    function Enchant.getAllPets()
        local pets = {}
        _petDisplayMap = {} -- Reset mapping
        
        if not Replication or not Replication.Data or not Replication.Data.Pets then 
            return pets 
        end
        
        -- Load PetStats module for accurate power calculation
        local RS = game:GetService("ReplicatedStorage")
        local PetStats
        pcall(function() PetStats = require(RS.Game.PetStats) end)
        
        local index = 0
        for uuid, data in pairs(Replication.Data.Pets) do
            index = index + 1
            -- Use correct field names from game data
            local petName = data.Nickname or data.Name or "Unknown"
            local cleanName = petName:gsub("<[^>]+>", "") -- Remove rich text
            local tier = data.Tier or "Normal"
            local level = data.Level or 1
            local equipped = data.Equipped or false
            
            -- Calculate ACTUAL power using game's own function
            local actualPower = 0
            if PetStats and PetStats.GetMulti then
                pcall(function()
                    actualPower = PetStats:GetMulti(data.Multi1, data.Tier, data.Level, data)
                end)
            end
            -- Fallback to Multi1 if PetStats fails
            if actualPower == 0 then
                actualPower = data.Multi1 or 0
            end
            
            -- Equipped status indicator
            local equippedStr = equipped and " *EQ" or ""
            
            -- Create display string with unique index
            -- Format: "[1] PetName (Tier) 701M [Lv.150] *EQ"
            local displayStr = string.format("[%d] %s (%s) %s [Lv.%d]%s", 
                index, cleanName, tier, formatPower(actualPower), level, equippedStr)
            
            -- Store mapping with UUID
            _petDisplayMap[displayStr] = {uuid = uuid, data = data, power = actualPower, index = index}
            table.insert(pets, displayStr)
        end
        
        -- Sort by power (highest first)
        table.sort(pets, function(a, b)
            local powerA = _petDisplayMap[a] and _petDisplayMap[a].power or 0
            local powerB = _petDisplayMap[b] and _petDisplayMap[b].power or 0
            return powerA > powerB
        end)
        
        return pets
    end
    
    -- Single enchant attempt
    function Enchant.roll(uuid)
        if not Network then return nil end
        
        local success, result = pcall(function()
            return Network:InvokeServer("EnchantPet", uuid)
        end)
        
        if success and result then
            _totalRolls = _totalRolls + 1
            _lastEnchant = result
            return result
        end
        return nil
    end
    
    -- Start brute-force
    function Enchant.start()
        if _isEnchanting then return end
        
        local petName = _G.EnchantSettings.TargetPet
        local targetEnchant = _G.EnchantSettings.TargetEnchant
        
        if petName == "" or not petName then
            notifyError("Enchant", "Pilih pet dulu!")
            return
        end
        
        local uuid, petData = Enchant.getPetUUID(petName)
        if not uuid then
            notifyError("Enchant", "Pet tidak ditemukan: " .. petName)
            return
        end
        
        _targetPetUUID = uuid
        _isEnchanting = true
        _totalRolls = 0
        
        log("ENCHANT", "Starting RNG Bypass for: " .. petName)
        log("ENCHANT", "Target: " .. targetEnchant)
        notifySuccess("Enchant", "Brute-force started!")
        
        _enchantThread = task.spawn(function()
            log("ENCHANT", "Loop started. Target: " .. targetEnchant)
            
            while _isEnchanting do
                -- Check crystals (try multiple paths)
                local crystals = 999999 -- Default high so we don't stop wrongly
                pcall(function()
                    local items = Replication.Data.Items
                    if items then
                        crystals = items.EnchantCrystal or items["Enchant Crystal"] or items.Crystal or 999999
                    end
                end)
                
                if crystals <= 0 then
                    warn("[ENCHANT] Crystal habis! Sisa: " .. crystals)
                    notifyError("Enchant", "Crystal habis setelah " .. _totalRolls .. " rolls")
                    _isEnchanting = false
                    break
                end
                
                -- Roll enchant
                local success, result = pcall(function()
                    return Network:InvokeServer("EnchantPet", _targetPetUUID)
                end)
                
                if success and result then
                    _totalRolls = _totalRolls + 1
                    _lastEnchant = result
                    
                    -- LOG SETIAP ROLL (untuk debug)
                    if _totalRolls % 10 == 0 then
                        log("ENCHANT", "Roll #" .. _totalRolls .. " = " .. tostring(result))
                    end
                    
                    -- Check if got target
                    if result == targetEnchant then
                        log("ENCHANT", "JACKPOT! Got: " .. result .. " after " .. _totalRolls .. " rolls")
                        notifySuccess("JACKPOT!", result .. " (" .. _totalRolls .. " rolls)")
                        
                        -- [FIX VISUAL DESYNC] Force update local data & UI
                        pcall(function()
                            local RS = game:GetService("ReplicatedStorage")
                            local Rep = require(RS.Game.Replication)
                            
                            -- 1. Update local pet data
                            if Rep.Data and Rep.Data.Pets and Rep.Data.Pets[_targetPetUUID] then
                                Rep.Data.Pets[_targetPetUUID].Enchant = result
                                log("ENCHANT", "Local data synced: " .. result)
                            end
                            
                            -- 2. Fire UI signal to refresh inventory
                            local Signal
                            pcall(function() Signal = require(RS.Modules.Signal) end)
                            if Signal and Signal.Fire then
                                Signal.Fire("UpdatePetData", _targetPetUUID, Rep.Data.Pets[_targetPetUUID])
                                Signal.Fire("InventoryChanged")
                            end
                        end)
                        -- [END FIX]
                        
                        if _G.EnchantSettings.AutoStop then
                            _isEnchanting = false
                            break
                        end
                    end
                    -- JANGAN BREAK/RETURN DI SINI - terus rolling kalau belum dapat
                else
                    -- Server error atau nil
                    warn("[ENCHANT] Server return nil/error. Retry in 0.5s...")
                    task.wait(0.5)
                end
                
                -- Delay antar roll
                task.wait(_G.EnchantSettings.Speed or 0.1)
            end
            
            log("ENCHANT", "Loop ended. Total rolls: " .. _totalRolls .. ", Last: " .. tostring(_lastEnchant))
        end)
    end
    
    function Enchant.stop()
        _isEnchanting = false
        if _enchantThread then
            pcall(function() task.cancel(_enchantThread) end)
            _enchantThread = nil
        end
        log("ENCHANT", "Stopped")
    end
    
    function Enchant.toggle(state)
        if state then
            Enchant.start()
        else
            Enchant.stop()
        end
    end
    
    function Enchant.setTargetPet(name)
        _G.EnchantSettings.TargetPet = name
    end
    
    function Enchant.setTargetEnchant(enchant)
        _G.EnchantSettings.TargetEnchant = enchant
    end
    
    function Enchant.setSpeed(speed)
        _G.EnchantSettings.Speed = math.max(0.01, speed)
    end
    
    function Enchant.getStats()
        return {
            isRunning = _isEnchanting,
            totalRolls = _totalRolls,
            lastEnchant = _lastEnchant,
            targetPet = _G.EnchantSettings.TargetPet
        }
    end
end

-- ============================================
-- [UI-MAIN] FLUENT UI SETUP & WINDOW
-- ============================================
print("[UI] Loading Fluent UI...")
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

Remotes.getRemoteFolder()

local Window = Fluent:CreateWindow({
    Title = "TapSim Hub v3.2",
    SubTitle = "Improved Edition",
    TabWidth = 130,
    Size = UDim2.fromOffset(550, 450),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})
_G.TapSimUI = Window

-- IMPROVED V3.2: Set Fluent reference for notifications
_FluentRef = Fluent

-- Mobile Toggle (Draggable)
if game:GetService("UserInputService").TouchEnabled then
    local UIS = game:GetService("UserInputService")
    local gui = Instance.new("ScreenGui", Player.PlayerGui)
    gui.Name = "TapSimToggle"
    gui.ResetOnSpawn = false
    local btn = Instance.new("TextButton", gui)
    btn.Size = UDim2.new(0,50,0,50)
    btn.Position = UDim2.new(0,10,0.5,-25)
    btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    btn.Text = "TS"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    -- Draggable Logic
    local dragging, dragInput, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    btn.MouseButton1Click:Connect(function() if Window then Window:Minimize() end end)
end

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "zap" }),
    Pets = Window:AddTab({ Title = "Pets", Icon = "egg" }),
    Islands = Window:AddTab({ Title = "Islands", Icon = "map" }),
    Upgrades = Window:AddTab({ Title = "Upgrades", Icon = "trending-up" }),
    Merchant = Window:AddTab({ Title = "Merchant", Icon = "shopping-cart" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "globe" }),
    Performance = Window:AddTab({ Title = "Performance", Icon = "gauge" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- [UI-TABS] ALL TAB DEFINITIONS
Tabs.Main:AddParagraph({ Title = "Auto Tap", Content = "Automatically taps coins really fast" })

Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Click",
    Default = false
}):OnChanged(function(value)
    Farm.toggle(value)
end)

-- FarmDelay fixed at fastest safe rate
_G.Settings.FarmDelay = 0.01

-- IMPROVED V3.2: Safe Mode Toggle
Tabs.Main:AddToggle("SafeModeFarm", {
    Title = "Safe Mode Farm",
    Description = "Slower but safer (anti-detection)",
    Default = false
}):OnChanged(function(value)
    Farm.setSafeMode(value)
    if value then
        Fluent:Notify({Title="Safe Mode", Content="Activated (Slower but Safer)", Duration=3})
    end
end)

task.wait(0.05) -- LAZY LOAD: Distribute render
Tabs.Main:AddParagraph({ Title = "Rebirths", Content = "" })
Tabs.Main:AddToggle("AutoRebirth", {Title = "Auto Rebirth", Default = false}):OnChanged(function(v) Rebirth.toggle(v) end)
Tabs.Main:AddSlider("NabungTime", {Title = "Cooldown", Default = 25, Min = 10, Max = 120, Rounding = 0, Callback = function(v) _G.Settings.NabungTime = v end})
Tabs.Main:AddParagraph({ Title = "Upgrades", Content = "" })
Tabs.Main:AddToggle("AutoUpgrade", {Title = "Auto Upgrade", Default = false}):OnChanged(function(v) Upgrades.toggleUpgrade(v) end)
Tabs.Main:AddParagraph({ Title = "Rank", Content = "" })
Tabs.Main:AddToggle("AutoRankReward", {Title = "Auto Claim Rank", Default = false}):OnChanged(function(v) Rewards.toggle(v) end)

-- IMPROVED V3.2: Electric Wheel (Ghost Event)
task.wait(0.05) -- LAZY LOAD: Distribute render
Tabs.Main:AddParagraph({ Title = "Electric Wheel", Content = "Hidden event - remote masih aktif" })
Tabs.Main:AddToggle("AutoElectricWheel", {
    Title = "Auto Spin Electric",
    Description = "Farm hadiah dari event tersembunyi",
    Default = false
}):OnChanged(function(v)
    ElectricSpin.toggle(v)
end)
Tabs.Main:AddSlider("ElectricSpinDelay", {
    Title = "Spin Delay",
    Description = "Jeda antar spin (detik)",
    Default = 0.5,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(v)
        ElectricSpin.setDelay(v)
    end
})

-- IMPROVED V3.2: Lucky Block Auto-Farm
task.wait(0.05) -- LAZY LOAD: Distribute render
Tabs.Main:AddParagraph({ Title = "Lucky Block", Content = "Auto-collect falling & placed blocks" })
Tabs.Main:AddToggle("AutoLuckyBlock", {
    Title = "Auto Farm Lucky Blocks",
    Description = "Teleport & collect all lucky blocks",
    Default = false
}):OnChanged(function(v)
    LuckyBlock.toggle(v)
end)
Tabs.Main:AddToggle("LuckyBlockTeleport", {
    Title = "Enable Teleport",
    Description = "Teleport to blocks (disable for stealth)",
    Default = true
}):OnChanged(function(v)
    LuckyBlock.setTeleport(v)
end)
Tabs.Main:AddSlider("LuckyBlockDelay", {
    Title = "Farm Delay",
    Description = "Jeda antar scan (detik)",
    Default = 0.25,
    Min = 0.1,
    Max = 2,
    Rounding = 2,
    Callback = function(v)
        LuckyBlock.setDelay(v)
    end
})

-- ADVANCED: Auto Craft Keys (convert pet to key)
Tabs.Main:AddParagraph({ Title = "Lucky Block Keys", Content = "Convert pets to Galaxy keys" })
Tabs.Main:AddToggle("AutoCraftKeys", {
    Title = "Auto Craft Keys",
    Description = "Otomatis convert pet ke key",
    Default = false
}):OnChanged(function(v)
    LuckyBlock.toggleCrafting(v)
end)
Tabs.Main:AddDropdown("CraftRarity", {
    Title = "Rarity to Sacrifice",
    Values = {"Legendary", "Mythic"},
    Default = "Legendary"
}):OnChanged(function(v)
    LuckyBlock.setCraftRarity(v)
end)

-- ADVANCED: Auto Generator (create block from essence)
Tabs.Main:AddParagraph({ Title = "Block Generator", Content = "Create blocks from essence" })
Tabs.Main:AddToggle("AutoGenerator", {
    Title = "Auto Generate Blocks",
    Description = "Otomatis bikin block dari essence",
    Default = false
}):OnChanged(function(v)
    LuckyBlock.toggleGenerator(v)
end)
Tabs.Main:AddDropdown("TargetBlock", {
    Title = "Block to Create",
    Values = {"Basic Lucky Block", "Starry Lucky Block", "Rainbow Lucky Block", "Galaxy Lucky Block"},
    Default = "Starry Lucky Block"
}):OnChanged(function(v)
    LuckyBlock.setTargetBlock(v)
end)

-- ADVANCED: Auto Gacha Galaxy
Tabs.Main:AddParagraph({ Title = "Galaxy Gacha", Content = "Auto open galaxy blocks" })
Tabs.Main:AddToggle("AutoGalaxyGacha", {
    Title = "Auto Galaxy Gacha",
    Description = "Spam open galaxy blocks",
    Default = false
}):OnChanged(function(v)
    LuckyBlock.toggleGacha(v)
end)
Tabs.Main:AddDropdown("GachaAmount", {
    Title = "Open Amount",
    Values = {"1x", "3x", "10x"},
    Default = "1x"
}):OnChanged(function(v)
    local amt = 1
    if v == "3x" then amt = 3 elseif v == "10x" then amt = 10 end
    LuckyBlock.setGachaAmount(amt)
end)

-- STATS MONITOR: Lucky Block Info
local LBStatsLabel = Tabs.Main:AddParagraph({ Title = "Keys: ? | Charge: ?/10", Content = "Stats monitor (updates every 3s)" })
task.spawn(function()
    while true do
        task.wait(3)
        local stats = LuckyBlock.getPlayerData()
        if stats then
            LBStatsLabel:SetTitle(string.format("Keys: %d | Charge: %d/10 | Pity: %d", 
                stats.Keys, stats.SuperCharged, stats.Pity))
        end
    end
end)

-- [FIX 3] PETS TAB (No manual HatchAmount dropdown)
task.wait(0.1) -- LAZY LOAD: Prevent freeze
local discoveredEggList = Eggs.discoverEggs()
-- Ensure key eggs for config compatibility
local fallbackEggs = {"Basic", "Space", "Starry", "Magma", "Lucky Event", "Galaxy", "Celestial", "Divine"}
for _, egg in ipairs(fallbackEggs) do
    if not table.find(discoveredEggList, egg) then
        table.insert(discoveredEggList, egg)
    end
end
table.sort(discoveredEggList)
Tabs.Pets:AddParagraph({ Title = "Hatching (Smart Detect)", Content = "Auto detects x8/x3 gamepass" })
local EggDropdown = Tabs.Pets:AddDropdown("TargetEgg", {Title = "Select Egg", Values = discoveredEggList, Default = 1})
EggDropdown:OnChanged(function(v) _G.Settings.TargetEgg = v end)

-- IMPROVED V3.2: Auto Rescan Eggs when Hatch enabled
Tabs.Pets:AddToggle("AutoHatch", {Title = "Auto Hatch", Default = false}):OnChanged(function(v)
    if v then
        -- Rescan eggs when enabling
        local eggs = Eggs.discoverEggs()
        EggDropdown:SetValues(eggs)
    end
    Eggs.toggle(v)
end)
_G.Settings.HatchDelay = 0.1

-- Speedometer Display
local SpeedLabel = Tabs.Pets:AddParagraph({ Title = "Speed: 0 Eggs/s", Content = "Hatch rate tracker" })
task.spawn(function()
    while true do
        task.wait(1)
        local speed = Eggs.getSpeed()
        local hatchAmt = Eggs.getHatchAmount and Eggs.getHatchAmount() or 1
        if Eggs.isRunning() then
            SpeedLabel:SetTitle("Speed: " .. speed .. " Eggs/s (" .. hatchAmt .. "x)")
        else
            SpeedLabel:SetTitle("Speed: 0 Eggs/s")
        end
    end
end)

-- IMPROVED V3.2: Auto Enchant (RNG Bypass)
Tabs.Pets:AddParagraph({ Title = "Enchant (RNG Bypass)", Content = "Brute-force enchant sampai dapat target" })

-- Pet dropdown (populate dari inventory) - SINGLE SELECT
local petList = Enchant.getAllPets()
if #petList == 0 then petList = {"No pets found"} end
local EnchantPetDropdown = Tabs.Pets:AddDropdown("EnchantPetSelect", {
    Title = "Select Pet",
    Values = petList,
    Multi = false, -- IMPORTANT: Single select only
    Default = nil
})
EnchantPetDropdown:OnChanged(function(v)
    Enchant.setTargetPet(v)
    Fluent:Notify({Title="Pet Selected", Content=v, Duration=2})
end)

-- Refresh pets button
Tabs.Pets:AddButton({
    Title = "Refresh Pet List",
    Callback = function()
        local pets = Enchant.getAllPets()
        if #pets > 0 then
            EnchantPetDropdown:SetValues(pets)
            Fluent:Notify({Title="Pets", Content="Found " .. #pets .. " pets", Duration=2})
        else
            Fluent:Notify({Title="Error", Content="No pets found", Duration=2})
        end
    end
})

-- Target enchant dropdown
Tabs.Pets:AddDropdown("EnchantTargetSelect", {
    Title = "Target Enchant",
    Values = Enchant.ENCHANTS,
    Default = "Secret Hunter"
}):OnChanged(function(v)
    Enchant.setTargetEnchant(v)
end)

-- Speed slider
Tabs.Pets:AddSlider("EnchantSpeed", {
    Title = "Roll Speed",
    Description = "Jeda antar roll (detik)",
    Default = 0.05,
    Min = 0.01,
    Max = 0.5,
    Rounding = 2,
    Callback = function(v)
        Enchant.setSpeed(v)
    end
})

-- Auto stop toggle
Tabs.Pets:AddToggle("EnchantAutoStop", {
    Title = "Stop When Found",
    Default = true
}):OnChanged(function(v)
    _G.EnchantSettings.AutoStop = v
end)

-- Main toggle
Tabs.Pets:AddToggle("AutoEnchant", {
    Title = "Start Enchant Bypass",
    Default = false
}):OnChanged(function(v)
    Enchant.toggle(v)
end)

Tabs.Pets:AddButton({Title = "Rescan Eggs", Callback = function() local eggs = Eggs.discoverEggs() EggDropdown:SetValues(eggs) Fluent:Notify({Title="Scan", Content=#eggs.." eggs", Duration=2}) end})
Tabs.Pets:AddParagraph({ Title = "Pets", Content = "" })
Tabs.Pets:AddToggle("AutoEquip", {Title = "Auto Equip Best", Default = false}):OnChanged(function(v) Pets.toggle(v) end)
Tabs.Pets:AddParagraph({ Title = "Auto Delete", Content = "" })
Tabs.Pets:AddToggle("AutoDelete", {Title = "Active", Default = false}):OnChanged(function(v) _G.DeleteSettings.Enabled = v end)
Tabs.Pets:AddDropdown("DeleteRarity", {Title = "Delete Rarities", Values = AutoDelete.RarityList, Multi = true, Default = {}}):OnChanged(function(v) _G.DeleteSettings.SelectedRarities = v end)
Tabs.Pets:AddToggle("KeepGolden", {Title = "Safe Golden", Default = true}):OnChanged(function(v) _G.DeleteSettings.KeepGolden = v end)
Tabs.Pets:AddToggle("KeepRainbow", {Title = "Safe Rainbow", Default = true}):OnChanged(function(v) _G.DeleteSettings.KeepRainbow = v end)
Tabs.Pets:AddParagraph({ Title = "Crafting", Content = "" })
Tabs.Pets:AddToggle("AutoGolden", {Title = "Auto Gold Craft", Default = false}):OnChanged(function(v) AutoCraft.toggleGolden(v) end)
Tabs.Pets:AddToggle("AutoRainbow", {Title = "Auto Rainbow Craft", Default = false}):OnChanged(function(v) AutoCraft.toggleRainbow(v) end)

-- ISLANDS TAB
task.wait(0.1) -- LAZY LOAD: Prevent freeze
Tabs.Islands:AddParagraph({ Title = "Islands", Content = "" })
Tabs.Islands:AddToggle("AutoIsland", {Title = "Auto Unlock", Default = false}):OnChanged(function(v) Islands.toggle(v) end)
Tabs.Islands:AddToggle("AutoBestIsland", {Title = "Auto Go Best", Default = false}):OnChanged(function(v) AutoBestIsland.toggle(v) end)
Tabs.Islands:AddToggle("SmartSave", {Title = "Smart Saving", Default = false}):OnChanged(function(v) _G.SmartSave.Enabled = v end)
Tabs.Islands:AddToggle("AutoBuyWorlds", {Title = "Auto Buy Worlds", Description = "Auto purchases World 2 portals", Default = false}):OnChanged(function(v)
    _G.Settings.AutoBuyWorlds = v
    if v then
        task.spawn(function()
            while _G.Settings.AutoBuyWorlds do
                pcall(function()
                    local buyRemote = Remotes.getFunction(Remotes.INDEX.UNLOCK_ISLAND)
                    if buyRemote then
                        for _, worldName in pairs({"World 2", "Kryo", "Magma", "Celestial", "Holographic", "Lunar"}) do
                            buyRemote:InvokeServer(worldName)
                            task.wait(0.5)
                        end
                    end
                end)
                task.wait(30)
            end
        end)
    end
end)
Tabs.Islands:AddParagraph({ Title = "Travel", Content = "" })
local islandList = Islands.getLocationList()
local selectedIsland = islandList[1] or "Spawn"
local IslandDropdown = Tabs.Islands:AddDropdown("TeleportIsland", {Title = "Destination", Values = islandList, Default = 1})
IslandDropdown:OnChanged(function(v) selectedIsland = v end)
Tabs.Islands:AddButton({Title = "Teleport", Callback = function() Islands.teleportTo(selectedIsland) end})

-- UPGRADES TAB
Tabs.Upgrades:AddToggle("AutoUpgrade", {Title = "Auto Upgrades", Default = false}):OnChanged(function(v) Upgrades.toggleUpgrade(v) end)
Tabs.Upgrades:AddToggle("AutoJump", {Title = "Auto Jump", Default = false}):OnChanged(function(v) Upgrades.toggleJump(v) end)
_G.Settings.UpgradeDelay = 1

-- [FIX 3] MERCHANT TAB (Dual Shop UI)
Tabs.Merchant:AddParagraph({ Title = "Space Merchant", Content = "" })
Tabs.Merchant:AddDropdown("SpaceMerchantItem", {Title = "Items", Values = Merchant.getSpaceItems(), Multi = true, Default = {}}):OnChanged(function(v) Merchant.setSpaceItems(v) end)
Tabs.Merchant:AddToggle("AutoBuySpaceMerchant", {Title = "Auto Buy Space", Default = false}):OnChanged(function(v) Merchant.toggleSpaceBuy(v) end)
Tabs.Merchant:AddParagraph({ Title = "Gem Merchant", Content = "" })
Tabs.Merchant:AddDropdown("GemMerchantItem", {Title = "Items", Values = Merchant.getGemItems(), Multi = true, Default = {}}):OnChanged(function(v) Merchant.setGemItems(v) end)
Tabs.Merchant:AddToggle("AutoBuyGemMerchant", {Title = "Auto Buy Gem", Default = false}):OnChanged(function(v) Merchant.toggleGemBuy(v) end)

-- WEBHOOK TAB
task.wait(0.1) -- LAZY LOAD: Prevent freeze
Tabs.Webhook:AddToggle("WebhookEnabled", {Title = "Enable", Default = false}):OnChanged(function(v) Webhook.toggle(v) end)

-- IMPROVED V3.2: Webhook URL with validation
Tabs.Webhook:AddInput("WebhookUrl", {
    Title = "URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric = false,
    Finished = true,
    Callback = function(v)
        Webhook.validateAndNotify(v, Fluent)
    end
})

Tabs.Webhook:AddDropdown("WebhookRarity", {Title = "Min Rarity", Values = {"Rare","Epic","Legendary","Mythic","Secret"}, Default = "Legendary"}):OnChanged(function(v) Webhook.setRarity(v) end)

-- PERFORMANCE TAB
task.wait(0.1) -- LAZY LOAD: Prevent freeze
local BlackGui = Instance.new("ScreenGui", Player.PlayerGui)
BlackGui.Name = "BlackScreenOverlay"
BlackGui.IgnoreGuiInset = true
BlackGui.Enabled = false
local BlackFrame = Instance.new("Frame", BlackGui)
BlackFrame.Size = UDim2.new(1,0,1,0)
BlackFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
BlackFrame.ZIndex = 9999
local StatusText = Instance.new("TextLabel", BlackFrame)
StatusText.Size = UDim2.new(1,0,1,0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "AFK MODE\n(3D Off - FPS 25)"
StatusText.TextColor3 = Color3.fromRGB(150,150,150)
StatusText.TextSize = 20
StatusText.Font = Enum.Font.GothamBold
Tabs.Performance:AddToggle("BlackScreenMode", {Title = "Black Screen (AFK)", Default = false}):OnChanged(function(v)
    BlackGui.Enabled = v
    game:GetService("RunService"):Set3dRenderingEnabled(not v)
    if v then setfpscap(25) else setfpscap(60) end
end)

-- IMPROVED V3.2: FPS Counter Real-Time
local FPSLabel = Tabs.Performance:AddParagraph({ Title = "FPS: Calculating...", Content = "Real-time frame rate" })
task.spawn(function()
    local RunService = game:GetService("RunService")
    local frameCount = 0
    local lastTick = tick()
    
    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
    end)
    
    while true do
        task.wait(1)
        local now = tick()
        local elapsed = now - lastTick
        local fps = math.floor(frameCount / elapsed)
        FPSLabel:SetTitle("FPS: " .. fps)
        frameCount = 0
        lastTick = now
    end
end)

Tabs.Performance:AddButton({Title = "Potato Graphics", Callback = function()
    local L = game:GetService("Lighting")
    L.GlobalShadows = false
    L.FogEnd = 9e9
    for _, v in pairs(L:GetChildren()) do if v:IsA("PostEffect") or v:IsA("Sky") or v:IsA("Atmosphere") then v:Destroy() end end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then v.Material = Enum.Material.SmoothPlastic v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") then v:Destroy() end
    end
    Fluent:Notify({Title="Potato", Content="Graphics lowered!", Duration=3})
end})
Tabs.Performance:AddButton({Title = "Clean RAM", Callback = function() pcall(collectgarbage, "collect") Fluent:Notify({Title="RAM", Content="Cleaned!", Duration=3}) end})

-- SETTINGS TAB
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("TapSimHub")
SaveManager:SetFolder("TapSimHub/configs")

-- IMPROVED V3.2: Expanded Config Save
-- Note: Custom OnSave/OnLoad removed - SaveManager doesn't support these hooks
-- Global settings are stored in _G tables and persist during session
-- SaveManager:SetIgnoreIndexes({}) -- All elements saved now

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- IMPROVED V3.2: Debug Button - List All Remotes
Tabs.Settings:AddButton({
    Title = "List All Remotes (Debug)",
    Description = "Print all remote names & indices to console (F9)",
    Callback = function()
        local list = Remotes.listAll()
        print("\n[DEBUG] === EVENTS ===")
        for _, r in ipairs(list.Events) do
            print(string.format("  [%d] %s", r.index, r.name))
        end
        print("\n[DEBUG] === FUNCTIONS ===")
        for _, r in ipairs(list.Functions) do
            print(string.format("  [%d] %s", r.index, r.name))
        end
        print("[DEBUG] === END ===")
        Fluent:Notify({Title="Debug", Content="Remote list printed to console (F9)", Duration=3})
    end
})

-- Rejoin Server v2.0 (VIP Support via Kick)
Tabs.Settings:AddButton({
    Title = "Rejoin Server (VIP Support)",
    Description = "Support Public & Private Server",
    Callback = function()
        local TS = game:GetService("TeleportService")
        local Plr = game:GetService("Players").LocalPlayer
        
        -- Cek apakah ini Private Server / VIP
        if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then
            
            -- LOGIKA UNTUK PRIVATE SERVER
            Fluent:Notify({
                Title = "VIP Server Detected",
                Content = "Melakukan Re-Login via Kick...",
                Duration = 3
            })
            
            -- Kick player supaya Executor melakukan Auto-Reconnect ke VIP
            Plr:Kick("Rejoining VIP Server...")
            
            task.wait(1)
            TS:Teleport(game.PlaceId, Plr)
            
        else
            -- LOGIKA UNTUK PUBLIC SERVER (JobId aman)
            Fluent:Notify({
                Title = "Public Server",
                Content = "Rejoining server...",
                Duration = 3
            })
            
            local success, err = pcall(function()
                TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, Plr)
            end)
            
            if not success then
                TS:Teleport(game.PlaceId, Plr)
            end
        end
    end
})

-- [SEC-CLEANUP] MEMORY CLEANUP & UNLOAD
local function CleanupAll()
    pcall(function() Farm.stop() end)
    pcall(function() Rebirth.stop() end)
    pcall(function() Eggs.stop() end)
    pcall(function() Islands.stop() end)
    pcall(function() Upgrades.stop() end)
    pcall(function() AutoCraft.clearCache() end)
    _G.TapSimLoaded = nil
    for i=1,5 do collectgarbage("collect") end
end
Window.OnUnload = CleanupAll

Window:SelectTab(1)
Fluent:Notify({Title="TapSim", Content="v3.2 Polished Edition Loaded!", Duration=3})
SaveManager:LoadAutoloadConfig()

-- [SAFETY] Sanity check: Prevent cached aggressive values from causing kicks
if _G.Settings.FarmDelay and _G.Settings.FarmDelay < 0.1 then
    _G.Settings.FarmDelay = 0.1
    warn("[SAFETY] Config had aggressive delay. Reset to 0.1s safe limit.")
end

-- [HOTKEY] Keyboard Shortcuts (Direct Toggle)
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- F1 = Toggle Auto Click
    if input.KeyCode == Enum.KeyCode.F1 then
        local newState = not _G.Settings.AutoFarm
        Farm.toggle(newState)
        Fluent:Notify({Title="Auto Click", Content=newState and "ON" or "OFF", Duration=1})
    end
    
    -- F2 = Toggle Auto Rebirth
    if input.KeyCode == Enum.KeyCode.F2 then
        local newState = not _G.Settings.AutoRebirth
        Rebirth.toggle(newState)
        Fluent:Notify({Title="Auto Rebirth", Content=newState and "ON" or "OFF", Duration=1})
    end
    
    -- F3 = Toggle Auto Hatch
    if input.KeyCode == Enum.KeyCode.F3 then
        local newState = not Eggs.isRunning()
        Eggs.toggle(newState)
        Fluent:Notify({Title="Auto Hatch", Content=newState and "ON" or "OFF", Duration=1})
    end
end)

print("[TapSim] ═══════════════════════════════════════════════")
print("[TapSim] TapSim Hub v3.2 - Polished Edition")
print("[TapSim] NEW: SafeMode UI, Webhook Validation, FPS Counter")
print("[TapSim] Use Ctrl+F: [MOD-FARM], [MOD-EGGS], [UI-MAIN]")
print("[TapSim] Press Left Ctrl to toggle UI")
print("[TapSim] HOTKEYS: F1=AutoClick, F2=AutoRebirth, F3=AutoHatch")
print("[TapSim] ═══════════════════════════════════════════════")
