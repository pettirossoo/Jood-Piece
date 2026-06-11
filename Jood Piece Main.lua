-- // AutoFarm SJW - PREMIUM MOBILE V19 (QOL UPDATED - INVENTORY REFRESH FIXED) //
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local VirtualUser   = game:GetService("VirtualUser")
local LocalPlayer   = Players.LocalPlayer
local HttpService   = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- ================================================
-- SECTION 1: VARIABLES
-- ================================================
local autofarmEnabled    = false
local selectedBoss       = "Sung Jinwoo"
local followMode         = "behind"
local followDistance     = 5
local attackRange        = 12
-- Boss Skills
local skillZ, skillX, skillC, skillV, skillF = false, false, false, false, false
-- Ocean Skills
local oceanSkillZ, oceanSkillX, oceanSkillC, oceanSkillV, oceanSkillF = false, false, false, false, false
-- Event Skills
local eventSkillZ, eventSkillX, eventSkillC, eventSkillV, eventSkillF = false, false, false, false, false

local step2Tool, step3Tool = nil, nil
local step2FEnabled, step2FActivated  = false, false
local stepsCompleted, isExecutingSteps, STEPS_IN_PROGRESS = false, false, false

local oceanMobsEnabled, oceanAutoEquipTool = false, nil
local mainFarmPaused                       = false
local eventIslandEnabled, eventAutoEquipTool = false, nil
local alreadyAtEventIsland  = false

local islandFarmEnabled      = false
local selectedIslandMob      = nil
local islandAutoEquipTool    = nil
local islandAutoEquip        = false
local islandSkillZ, islandSkillX, islandSkillC, islandSkillV, islandSkillF = false, false, false, false, false

-- Ocean-Hop Variables
local oceanHopEnabled              = false
local oceanHopMUITool              = nil
local oceanHopMUIAutoEquip         = false
local oceanHopMUISkillF            = false
local oceanHopPriorityEnabled      = false
local oceanHopPriorityMob          = nil
local oceanHopRegularEnabled       = false
local oceanHopRegularTool          = nil
local oceanHopRegularSkillZ, oceanHopRegularSkillX, oceanHopRegularSkillC, oceanHopRegularSkillV, oceanHopRegularSkillF = false, false, false, false, false
local oceanHopServerHopDelay       = 10

local selectedTitle            = nil
local guaranteeEnabled         = false
local selectedGuaranteeItems   = {}
local merchantEnabled          = false
local selectedMerchantItems    = {}
local inventoryEnabled         = false

local flyEnabled, flySpeed     = false, 60
local noclipEnabled            = false
local customWalkSpeed          = 16
local speedLoopEnabled         = false
local disableVFX               = false
local disableCamShake          = false
local fastModeEnabled          = false
local flyBV, flyBG, flyConn   = nil, nil, nil

local savedConfigs       = {}
local currentConfigName  = ""
local autoLoadConfigName = ""

local UI = {}

-- ================================================
-- SECTION 2: HELPER FUNCTIONS
-- ================================================
local function getConfigNames()
    local n = {}
    for k in pairs(savedConfigs) do table.insert(n,k) end
    return #n > 0 and n or {"No configs"}
end

local function getAutoLoadOpts()
    local o = {"None"}
    for k in pairs(savedConfigs) do table.insert(o,k) end
    return o
end

local function getAvailableBosses()
    local b = {}
    pcall(function()
        local g = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        if g and g:FindFirstChild("SUMMON") and g.SUMMON:FindFirstChild("Main") then
            for _,c in pairs(g.SUMMON.Main:GetChildren()) do
                if c:IsA("TextButton") and c.Name~="UIListLayout" and c.Name~="TEXT" then
                    table.insert(b, c.Name)
                end
            end
        end
    end)
    return #b>0 and b or {"Sung Jinwoo"}
end

local function getBackpackTools()
    local t = {}
    pcall(function()
        for _,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then table.insert(t, tool.Name) end
        end
        for _,tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then table.insert(t, tool.Name) end
        end
    end)
    return #t>0 and t or {"No tools"}
end

local function getTitles()
    local t = {}
    pcall(function()
        local g = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        if g and g:FindFirstChild("TITLE") and g.TITLE:FindFirstChild("Main") then
            for _,c in pairs(g.TITLE.Main:GetChildren()) do
                if (c:IsA("Frame") or c:IsA("TextButton"))
                and c.Name~="UIListLayout" and c.Name~="UIStroke"
                and c.Name~="LocalScript" and c.Name~="TEXT" then
                    table.insert(t, c.Name)
                end
            end
        end
    end)
    return #t>0 and t or {"No titles"}
end

local function getGuaranteeItems()
    local items = {}
    pcall(function()
        local g = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        if g and g:FindFirstChild("GUARANTEE") and g.GUARANTEE:FindFirstChild("Main") then
            for _,c in pairs(g.GUARANTEE.Main:GetChildren()) do
                if (c:IsA("Frame") or c:IsA("TextButton"))
                and c.Name~="UIListLayout" and c.Name~="TEXT" then
                    table.insert(items, c.Name)
                end
            end
        end
    end)
    return #items>0 and items or {"No items"}
end

local function getMerchantItems()
    local items = {}
    pcall(function()
        local g = LocalPlayer.PlayerGui:FindFirstChild("SettingGui")
        if g and g:FindFirstChild("MERCHANT") and g.MERCHANT:FindFirstChild("ScrollingFrame") then
            for _,c in pairs(g.MERCHANT.ScrollingFrame:GetChildren()) do
                if (c:IsA("Frame") or c:IsA("TextButton"))
                and c:FindFirstChild("BuyButton") and c:FindFirstChild("Stocks")
                and c.Name~="UIGridLayout" and c.Name~="UIPadding" then
                    table.insert(items, c.Name)
                end
            end
        end
    end)
    return #items>0 and items or {"No items"}
end

local function getIslandMobs()
    local mobs = {}
    pcall(function()
        if workspace:FindFirstChild("Mobs") then
            local mobsFolder = workspace.Mobs
            for _, islandFolder in pairs(mobsFolder:GetChildren()) do
                if islandFolder.Name == "Ocean" then continue end
                if islandFolder:IsA("Folder") then
                    for _, mob in pairs(islandFolder:GetChildren()) do
                        if mob:IsA("Model") then
                            table.insert(mobs, mob.Name)
                        end
                    end
                end
            end
        end
    end)
    local uniqueMobs = {}
    local seen = {}
    for _, mobName in pairs(mobs) do
        if not seen[mobName] then seen[mobName] = true; table.insert(uniqueMobs, mobName) end
    end
    return #uniqueMobs > 0 and uniqueMobs or {"No mobs"}
end

-- ================================================
-- SECTION 3: CONFIG SYSTEM
-- ================================================
local ConfigFolder = "SJW_Configs"
local ConfigFile   = ConfigFolder.."/configs.json"

local function saveConfigToFile()
    pcall(function()
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        writefile(ConfigFile, HttpService:JSONEncode({configs=savedConfigs, autoLoad=autoLoadConfigName}))
    end)
end

local function loadConfigFromFile()
    pcall(function()
        if isfile(ConfigFile) then
            local data = HttpService:JSONDecode(readfile(ConfigFile))
            savedConfigs = data.configs or {}
            autoLoadConfigName = data.autoLoad or ""
        end
    end)
end

local function getCurrentSettings()
    return {
        autofarmEnabled=autofarmEnabled, selectedBoss=selectedBoss, followMode=followMode, step2Tool=step2Tool, step2FEnabled=step2FEnabled,
        step3Tool=step3Tool, skillZ=skillZ, skillX=skillX, skillC=skillC, skillV=skillV, skillF=skillF,
        oceanMobsEnabled=oceanMobsEnabled, oceanAutoEquipTool=oceanAutoEquipTool, oceanSkillZ=oceanSkillZ, oceanSkillX=oceanSkillX, oceanSkillC=oceanSkillC, oceanSkillV=oceanSkillV, oceanSkillF=oceanSkillF,
        eventIslandEnabled=eventIslandEnabled, eventAutoEquipTool=eventAutoEquipTool, eventSkillZ=eventSkillZ, eventSkillX=eventSkillX, eventSkillC=eventSkillC, eventSkillV=eventSkillV, eventSkillF=eventSkillF,
        selectedTitle=selectedTitle, guaranteeEnabled=guaranteeEnabled, selectedGuaranteeItems=selectedGuaranteeItems, merchantEnabled=merchantEnabled, selectedMerchantItems=selectedMerchantItems,
        inventoryEnabled=inventoryEnabled, flySpeed=flySpeed, customWalkSpeed=customWalkSpeed, speedLoopEnabled=speedLoopEnabled, disableVFX=disableVFX,
        disableCamShake=disableCamShake, fastModeEnabled=fastModeEnabled, followDistance=followDistance, attackRange=attackRange, oceanHopEnabled=oceanHopEnabled,
        oceanHopMUITool=oceanHopMUITool, oceanHopMUIAutoEquip=oceanHopMUIAutoEquip or false, oceanHopMUISkillF=oceanHopMUISkillF or false, oceanHopPriorityEnabled=oceanHopPriorityEnabled or false,
        oceanHopPriorityMob=oceanHopPriorityMob, oceanHopRegularEnabled=oceanHopRegularEnabled or false, oceanHopRegularTool=oceanHopRegularTool,
        oceanHopRegularSkillZ=oceanHopRegularSkillZ or false, oceanHopRegularSkillX=oceanHopRegularSkillX or false, oceanHopRegularSkillC=oceanHopRegularSkillC or false,
        oceanHopRegularSkillV=oceanHopRegularSkillV or false, oceanHopRegularSkillF=oceanHopRegularSkillF or false,
        islandFarmEnabled=islandFarmEnabled or false, selectedIslandMob=selectedIslandMob, islandAutoEquipTool=islandAutoEquipTool, islandAutoEquip=islandAutoEquip or false,
        islandSkillZ=islandSkillZ or false, islandSkillX=islandSkillX or false, islandSkillC=islandSkillC or false, islandSkillV=islandSkillV or false, islandSkillF=islandSkillF or false
    }
end

local function applyVariables(s)
    if not s then return end
    autofarmEnabled=s.autofarmEnabled or false; selectedBoss=s.selectedBoss or "Sung Jinwoo"; followMode=s.followMode or "behind"
    followDistance=s.followDistance or 5; attackRange=s.attackRange or 12; step2Tool=s.step2Tool; step2FEnabled=s.step2FEnabled or false
    step3Tool=s.step3Tool; skillZ=s.skillZ or false; skillX=s.skillX or false; skillC=s.skillC or false; skillV=s.skillV or false; skillF=s.skillF or false
    oceanMobsEnabled=s.oceanMobsEnabled or false; oceanAutoEquipTool=s.oceanAutoEquipTool; oceanSkillZ=s.oceanSkillZ or false
    oceanSkillX=s.oceanSkillX or false; oceanSkillC=s.oceanSkillC or false; oceanSkillV=s.oceanSkillV or false; oceanSkillF=s.oceanSkillF or false
    eventIslandEnabled=s.eventIslandEnabled or false; eventAutoEquipTool=s.eventAutoEquipTool; eventSkillZ=s.eventSkillZ or false
    eventSkillX=s.eventSkillX or false; eventSkillC=s.eventSkillC or false; eventSkillV=s.eventSkillV or false; eventSkillF=s.eventSkillF or false
    selectedTitle=s.selectedTitle; guaranteeEnabled=s.guaranteeEnabled or false; selectedGuaranteeItems=s.selectedGuaranteeItems or {}
    merchantEnabled=s.merchantEnabled or false; selectedMerchantItems=s.selectedMerchantItems or {}
    inventoryEnabled=s.inventoryEnabled or false; flySpeed=s.flySpeed or 60; customWalkSpeed=s.customWalkSpeed or 16; speedLoopEnabled=s.speedLoopEnabled or false
    disableVFX=s.disableVFX or false; disableCamShake=s.disableCamShake or false; fastModeEnabled=s.fastModeEnabled or false
    oceanHopEnabled=s.oceanHopEnabled or false; oceanHopMUITool=s.oceanHopMUITool; oceanHopMUIAutoEquip=s.oceanHopMUIAutoEquip or false
    oceanHopMUISkillF=s.oceanHopMUISkillF or false; oceanHopPriorityEnabled=s.oceanHopPriorityEnabled or false; oceanHopPriorityMob=s.oceanHopPriorityMob
    oceanHopRegularEnabled=s.oceanHopRegularEnabled or false; oceanHopRegularTool=s.oceanHopRegularTool; oceanHopRegularSkillZ=s.oceanHopRegularSkillZ or false
    oceanHopRegularSkillX=s.oceanHopRegularSkillX or false; oceanHopRegularSkillC=s.oceanHopRegularSkillC or false; oceanHopRegularSkillV=s.oceanHopRegularSkillV or false
    oceanHopRegularSkillF=s.oceanHopRegularSkillF or false; islandFarmEnabled=s.islandFarmEnabled or false; selectedIslandMob=s.selectedIslandMob
    islandAutoEquipTool=s.islandAutoEquipTool; islandAutoEquip=s.islandAutoEquip or false; islandSkillZ=s.islandSkillZ or false
    islandSkillX=s.islandSkillX or false; islandSkillC=s.islandSkillC or false; islandSkillV=s.islandSkillV or false; islandSkillF=s.islandSkillF or false
    mainFarmPaused=false
end

loadConfigFromFile()

task.spawn(function()
    task.wait(2)
    if UI.ConfigDD then UI.ConfigDD:Refresh(getConfigNames(), true) end
    if UI.AutoLoadDD then UI.AutoLoadDD:Refresh(getAutoLoadOpts(), true) end
end)

if autoLoadConfigName ~= "" and savedConfigs[autoLoadConfigName] then
    applyVariables(savedConfigs[autoLoadConfigName])
end

-- ================================================
-- SECTION 4: RAYFIELD UI
-- ================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name="SJW Premium V19", LoadingTitle="Loading...", LoadingSubtitle="by SJW Team", ConfigurationSaving={Enabled=false}, Discord={Enabled=false}, KeySystem=false})

-- [TABS SETUP OMITTED FOR BREVITY, REST OF CODE REMAINS THE SAME]
-- (Section 5-14 skipped in display for clarity, assuming they are in your final script file)
-- ================================================
-- SECTION 15: UPDATE ALL UI FUNCTION
-- ================================================
function updateAllUI()
    -- [Existing updateAllUI logic]
end

-- ================================================
-- SECTION 16: LOOPS
-- ================================================

-- [Anti-Cheat/Misc Loops]

-- ================================================
-- SECTION 17: CORE FUNCTIONS
-- ================================================
local function robustClick(btn)
    if not btn then return end
    pcall(function()
        if firesignal then firesignal(btn.MouseButton1Click) elseif btn.MouseButton1Click then btn.MouseButton1Click:Fire() end
    end)
    task.spawn(function()
        for i=1,3 do
            task.wait(0.05)
            pcall(function()
                if firesignal then firesignal(btn.MouseButton1Click) elseif btn.MouseButton1Click then btn.MouseButton1Click:Fire() end
            end)
        end
    end)
end

-- [Helper Functions: equipTool, useSkills, etc...]

-- ================================================
-- SECTION 18: GAME LOOPS
-- ================================================

-- Inventory (IMPROVED AUTO-STORAGE & REFRESH)
task.spawn(function()
    local lastRefresh = tick()
    while true do
        task.wait(1)
        if inventoryEnabled and not STEPS_IN_PROGRESS then
            local mainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
            
            if mainGui and mainGui:FindFirstChild("INVENTORY") then
                local invGui = mainGui.INVENTORY
                local backpack = invGui:FindFirstChild("BackpackFrame")
                
                -- REFRESH LOGIC: Aggiornamento invisibile ogni 10 secondi
                if backpack and invGui.Visible == false and (tick() - lastRefresh > 4) then
                    local originalPos = invGui.Position
                    invGui.Position = UDim2.new(-5, 0, -5, 0)
                    invGui.Visible = true
                    task.wait(0.1)
                    invGui.Visible = false
                    invGui.Position = originalPos
                    lastRefresh = tick()
                end

                -- LOGICA CLICK
                pcall(function()
                    if backpack then
                        for _, f in pairs(backpack:GetChildren()) do
                            if f.Name == "UIGridLayout" or f.Name == "UIStroke" then continue end
                            local btn = f:FindFirstChild("Button")
                            if btn and btn:FindFirstChild("Amount") then
                                local n = tonumber(btn.Amount.Text:match("(%d+)"))
                                if n and n > 0 then
                                    for i = 1, math.min(n, 15) do
                                        task.spawn(function() robustClick(btn) end)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- [Rest of the loops remain the same as your provided script]
-- (Include your existing sections for Ocean, Event, Boss, etc.)