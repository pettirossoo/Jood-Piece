-- // AutoFarm SJW - PREMIUM MOBILE V19 (QOL UPDATED - NO STEP1/STEP4) //
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
-- Boss Skills (Default: OFF)
local skillZ             = false
local skillX             = false
local skillC             = false
local skillV             = false
local skillF             = false

-- Ocean Skills (Default: OFF)
local oceanSkillZ        = false
local oceanSkillX        = false
local oceanSkillC        = false
local oceanSkillV        = false
local oceanSkillF        = false

-- Event Skills (Default: OFF)
local eventSkillZ        = false
local eventSkillX        = false
local eventSkillC        = false
local eventSkillV        = false
local eventSkillF        = false

local step2Tool, step3Tool = nil, nil
local step2FEnabled, step2FActivated  = false, false
local stepsCompleted, isExecutingSteps, STEPS_IN_PROGRESS = false, false, false

local oceanMobsEnabled, oceanAutoEquipTool = false, nil
local mainFarmPaused                       = false
local eventIslandEnabled, eventAutoEquipTool = false, nil
local alreadyAtEventIsland  = false

-- ========== OCEAN-HOP VARIABLES ==========
local oceanHopEnabled              = false
-- MUI Section (Immortality)
local oceanHopMUITool              = nil
local oceanHopMUIAutoEquip         = false
local oceanHopMUISkillF            = false
-- Priority Mob Selection
local oceanHopPriorityEnabled      = false
local oceanHopPriorityMob          = nil
-- Regular Farm
local oceanHopRegularEnabled       = false
local oceanHopRegularTool          = nil
local oceanHopRegularSkillZ        = false
local oceanHopRegularSkillX        = false
local oceanHopRegularSkillC        = false
local oceanHopRegularSkillV        = false
local oceanHopRegularSkillF        = false
-- Fast Farm (Vergil) - REMOVED
local oceanHopServerHopDelay       = 4

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

-- ================================================
-- SECTION 3: CONFIG SYSTEM
-- ================================================
local ConfigFolder = "SJW_Configs"
local ConfigFile   = ConfigFolder.."/configs.json"

local function saveConfigToFile()
    pcall(function()
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        writefile(ConfigFile, HttpService:JSONEncode({
            configs  = savedConfigs,
            autoLoad = autoLoadConfigName
        }))
        print("✅ Config file saved to: "..ConfigFolder)
    end)
end

local function loadConfigFromFile()
    pcall(function()
        if isfile(ConfigFile) then
            local data = HttpService:JSONDecode(readfile(ConfigFile))
            savedConfigs       = data.configs  or {}
            autoLoadConfigName = data.autoLoad or ""
            print("✅ Config file loaded from: "..ConfigFile)
        end
    end)
end

local function getCurrentSettings()
    return {
        autofarmEnabled       = autofarmEnabled,
        selectedBoss          = selectedBoss,
        followMode            = followMode,
        step2Tool             = step2Tool,
        step2FEnabled         = step2FEnabled,
        step3Tool             = step3Tool,
        skillZ                = skillZ,
        skillX                = skillX,
        skillC                = skillC,
        skillV                = skillV,
        skillF                = skillF,
        oceanMobsEnabled      = oceanMobsEnabled,
        oceanAutoEquipTool    = oceanAutoEquipTool,
        oceanSkillZ           = oceanSkillZ,
        oceanSkillX           = oceanSkillX,
        oceanSkillC           = oceanSkillC,
        oceanSkillV           = oceanSkillV,
        oceanSkillF           = oceanSkillF,
        eventIslandEnabled    = eventIslandEnabled,
        eventAutoEquipTool    = eventAutoEquipTool,
        eventSkillZ           = eventSkillZ,
        eventSkillX           = eventSkillX,
        eventSkillC           = eventSkillC,
        eventSkillV           = eventSkillV,
        eventSkillF           = eventSkillF,
        selectedTitle         = selectedTitle,
        guaranteeEnabled      = guaranteeEnabled,
        selectedGuaranteeItems= selectedGuaranteeItems,
        merchantEnabled       = merchantEnabled,
        selectedMerchantItems = selectedMerchantItems,
        inventoryEnabled      = inventoryEnabled,
        flySpeed              = flySpeed,
        customWalkSpeed       = customWalkSpeed,
        speedLoopEnabled      = speedLoopEnabled,
        disableVFX            = disableVFX,
        disableCamShake       = disableCamShake,
        followDistance        = followDistance,
        attackRange           = attackRange,
        oceanHopEnabled       = oceanHopEnabled,
        oceanHopMUITool       = oceanHopMUITool,
        oceanHopMUIAutoEquip  = oceanHopMUIAutoEquip,
        oceanHopMUISkillF     = oceanHopMUISkillF,
        oceanHopPriorityEnabled = oceanHopPriorityEnabled,
        oceanHopPriorityMob   = oceanHopPriorityMob,
        oceanHopRegularEnabled = oceanHopRegularEnabled,
        oceanHopRegularTool   = oceanHopRegularTool,
        oceanHopRegularSkillZ = oceanHopRegularSkillZ,
        oceanHopRegularSkillX = oceanHopRegularSkillX,
        oceanHopRegularSkillC = oceanHopRegularSkillC,
        oceanHopRegularSkillV = oceanHopRegularSkillV,
        oceanHopRegularSkillF = oceanHopRegularSkillF,
    }
end

local function applyVariables(s)
    if not s then return end
    autofarmEnabled       = s.autofarmEnabled    or false
    selectedBoss          = s.selectedBoss       or "Sung Jinwoo"
    followMode            = s.followMode         or "behind"
    followDistance        = s.followDistance     or 5
    attackRange           = s.attackRange        or 12
    step2Tool             = s.step2Tool
    step2FEnabled         = s.step2FEnabled      or false
    step3Tool             = s.step3Tool
    skillZ                = s.skillZ ~= nil and s.skillZ or false
    skillX                = s.skillX ~= nil and s.skillX or false
    skillC                = s.skillC ~= nil and s.skillC or false
    skillV                = s.skillV ~= nil and s.skillV or false
    skillF                = s.skillF ~= nil and s.skillF or false
    oceanMobsEnabled      = s.oceanMobsEnabled   or false
    oceanAutoEquipTool    = s.oceanAutoEquipTool
    oceanSkillZ           = s.oceanSkillZ ~= nil and s.oceanSkillZ or false
    oceanSkillX           = s.oceanSkillX ~= nil and s.oceanSkillX or false
    oceanSkillC           = s.oceanSkillC ~= nil and s.oceanSkillC or false
    oceanSkillV           = s.oceanSkillV ~= nil and s.oceanSkillV or false
    oceanSkillF           = s.oceanSkillF ~= nil and s.oceanSkillF or false
    eventIslandEnabled    = s.eventIslandEnabled or false
    eventAutoEquipTool    = s.eventAutoEquipTool
    eventSkillZ           = s.eventSkillZ ~= nil and s.eventSkillZ or false
    eventSkillX           = s.eventSkillX ~= nil and s.eventSkillX or false
    eventSkillC           = s.eventSkillC ~= nil and s.eventSkillC or false
    eventSkillV           = s.eventSkillV ~= nil and s.eventSkillV or false
    eventSkillF           = s.eventSkillF ~= nil and s.eventSkillF or false
    selectedTitle         = s.selectedTitle
    guaranteeEnabled      = s.guaranteeEnabled   or false
    selectedGuaranteeItems= s.selectedGuaranteeItems or {}
    merchantEnabled       = s.merchantEnabled    or false
    selectedMerchantItems = s.selectedMerchantItems  or {}
    inventoryEnabled      = s.inventoryEnabled   or false
    flySpeed              = s.flySpeed           or 60
    customWalkSpeed       = s.customWalkSpeed    or 16
    speedLoopEnabled      = s.speedLoopEnabled   or false
    disableVFX            = s.disableVFX         or false
    disableCamShake       = s.disableCamShake    or false
    oceanHopEnabled       = s.oceanHopEnabled    or false
    oceanHopMUITool       = s.oceanHopMUITool
    oceanHopMUIAutoEquip  = s.oceanHopMUIAutoEquip or false
    oceanHopMUISkillF     = s.oceanHopMUISkillF or false
    oceanHopPriorityEnabled = s.oceanHopPriorityEnabled or false
    oceanHopPriorityMob   = s.oceanHopPriorityMob
    oceanHopRegularEnabled = s.oceanHopRegularEnabled or false
    oceanHopRegularTool   = s.oceanHopRegularTool
    oceanHopRegularSkillZ = s.oceanHopRegularSkillZ ~= nil and s.oceanHopRegularSkillZ or false
    oceanHopRegularSkillX = s.oceanHopRegularSkillX ~= nil and s.oceanHopRegularSkillX or false
    oceanHopRegularSkillC = s.oceanHopRegularSkillC ~= nil and s.oceanHopRegularSkillC or false
    oceanHopRegularSkillV = s.oceanHopRegularSkillV ~= nil and s.oceanHopRegularSkillV or false
    oceanHopRegularSkillF = s.oceanHopRegularSkillF ~= nil and s.oceanHopRegularSkillF or false
    mainFarmPaused        = false
    print("✅ Variables applied")
end

loadConfigFromFile()
-- Autoload moved after Rayfield creation

-- ================================================
-- SECTION 4: RAYFIELD
-- ================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name="SJW Premium V19", LoadingTitle="Loading...",
    LoadingSubtitle="by SJW Team",
    ConfigurationSaving={Enabled=false},
    Discord={Enabled=false}, KeySystem=false
})

-- ================================================
-- SECTION 5: TABS
-- ================================================
local ConfigTab = Window:CreateTab("💾 Config",    nil)
local BossTab   = Window:CreateTab("👹 Boss",      nil)
local OceanTab  = Window:CreateTab("🌊 Ocean",     nil)
local OceanHopTab = Window:CreateTab("🔄 Ocean-Hop", nil)
local EventTab  = Window:CreateTab("🎪 Event",     nil)
local TitleTab  = Window:CreateTab("👑 Title",     nil)
local GuarTab   = Window:CreateTab("🎁 Guarantee", nil)
local MerchTab  = Window:CreateTab("🛒 Merchant",  nil)
local InvTab    = Window:CreateTab("📦 Inventory", nil)
local MiscTab   = Window:CreateTab("⚙️ Misc",      nil)

-- ================================================
-- SECTION 6: CONFIG TAB
-- ================================================
ConfigTab:CreateSection("Save & Load")

ConfigTab:CreateInput({
    Name="Config Name", PlaceholderText="e.g. BossFarm1",
    RemoveTextAfterFocusLost=false,
    Callback=function(t) currentConfigName=t end,
})

ConfigTab:CreateButton({
    Name="💾 SAVE NEW",
    Callback=function()
        if currentConfigName=="" then
            Rayfield:Notify({Title="Error",Content="Enter a config name!",Duration=2})
            return
        end
        savedConfigs[currentConfigName] = getCurrentSettings()
        saveConfigToFile()
        task.wait(0.1)
        if UI.ConfigDD   then UI.ConfigDD:Refresh(getConfigNames(), true) end
        if UI.AutoLoadDD then UI.AutoLoadDD:Refresh(getAutoLoadOpts(), true) end
        Rayfield:Notify({Title="Saved ✅", Content=currentConfigName, Duration=2})
    end,
})

ConfigTab:CreateButton({
    Name="🔄 OVERWRITE SELECTED",
    Callback=function()
        if not savedConfigs[currentConfigName] then
            Rayfield:Notify({Title="Error",Content="Select a config to overwrite!",Duration=2})
            return
        end
        savedConfigs[currentConfigName] = getCurrentSettings()
        saveConfigToFile()
        Rayfield:Notify({Title="Overwritten ✅", Content=currentConfigName, Duration=2})
    end,
})

UI.ConfigDD = ConfigTab:CreateDropdown({
    Name="Select Config",
    Options=getConfigNames(), CurrentOption={},
    MultipleOptions=false,
    Callback=function(o)
        if o[1]~="No configs" then currentConfigName=o[1] end
    end,
})

ConfigTab:CreateButton({
    Name="🔄 LOAD",
    Callback=function()
        if not savedConfigs[currentConfigName] then
            Rayfield:Notify({Title="Error",Content="Select a config!",Duration=2})
            return
        end
        applyVariables(savedConfigs[currentConfigName])
        task.wait(0.5) -- Wait for variables to apply
        updateAllUI() -- Now update the UI
        Rayfield:Notify({Title="Loaded ✅", Content=currentConfigName, Duration=2})
    end,
})

UI.AutoLoadDD = ConfigTab:CreateDropdown({
    Name="Auto-Load on Start",
    Options=getAutoLoadOpts(),
    CurrentOption={autoLoadConfigName~="" and autoLoadConfigName or "None"},
    MultipleOptions=false,
    Callback=function(o)
        autoLoadConfigName = (o[1]=="None") and "" or o[1]
        saveConfigToFile()
        Rayfield:Notify({Title="Auto-Load Set",Content=o[1],Duration=2})
    end,
})

ConfigTab:CreateButton({
    Name="🗑️ DELETE",
    Callback=function()
        if not savedConfigs[currentConfigName] then
            Rayfield:Notify({Title="Error",Content="Select a config!",Duration=2})
            return
        end
        local n=currentConfigName
        savedConfigs[n]=nil
        if autoLoadConfigName==n then autoLoadConfigName="" end
        saveConfigToFile()
        task.wait(0.1)
        if UI.ConfigDD   then UI.ConfigDD:Refresh(getConfigNames(),true) end
        if UI.AutoLoadDD then UI.AutoLoadDD:Refresh(getAutoLoadOpts(),true) end
        Rayfield:Notify({Title="Deleted",Content=n,Duration=2})
        currentConfigName=""
    end,
})

ConfigTab:CreateSection("Info")
ConfigTab:CreateLabel("Config folder: "..ConfigFolder)
ConfigTab:CreateLabel("Files are JSON format")
ConfigTab:CreateLabel("Located in game directory")

-- ================================================
-- SECTION 7: BOSS TAB
-- ================================================
BossTab:CreateButton({Name="🔄 Refresh Boss", Callback=function()
    if UI.BossDD then UI.BossDD:Refresh(getAvailableBosses(), true) end
end})

UI.BossDD = BossTab:CreateDropdown({
    Name="Boss", Options=getAvailableBosses(),
    CurrentOption={selectedBoss},
    MultipleOptions=false,
    Callback=function(o) selectedBoss=o[1] end
})

UI.AutoFarmToggle = BossTab:CreateToggle({
    Name="Start Farm",
    CurrentValue=autofarmEnabled,
    Callback=function(v)
        autofarmEnabled=v
        if v then
            stepsCompleted=false; step2FActivated=false
            isExecutingSteps=false; STEPS_IN_PROGRESS=false
        end
    end
})

BossTab:CreateDropdown({
    Name="Position",
    Options={"Behind","Front","Above","Below"},
    CurrentOption={followMode:sub(1,1):upper()..followMode:sub(2)},
    MultipleOptions=false,
    Callback=function(o) followMode=o[1]:lower() end
})

BossTab:CreateSection("Steps (QOL: Accessory & Buso auto-equipped by game)")

BossTab:CreateButton({Name="🔄 Refresh Tools", Callback=function()
    local t=getBackpackTools()
    for _,dd in pairs({UI.Step2DD,UI.Step3DD,UI.OceanDD,UI.EventDD}) do
        if dd then dd:Refresh(t,true) end
    end
end})

UI.Step2DD = BossTab:CreateDropdown({
    Name="Step 2: MUI", Options=getBackpackTools(),
    CurrentOption=step2Tool and {step2Tool} or {},
    MultipleOptions=false,
    Callback=function(o) step2Tool=o[1] end
})

UI.Step2FToggle = BossTab:CreateToggle({
    Name="Use F (once)",
    CurrentValue=step2FEnabled,
    Callback=function(v) step2FEnabled=v end
})

UI.Step3DD = BossTab:CreateDropdown({
    Name="Step 3: Combat", Options=getBackpackTools(),
    CurrentOption=step3Tool and {step3Tool} or {},
    MultipleOptions=false,
    Callback=function(o) step3Tool=o[1] end
})

BossTab:CreateSection("Skills")
UI.SkillZ=BossTab:CreateToggle({Name="Z",CurrentValue=skillZ,Callback=function(v) skillZ=v end})
UI.SkillX=BossTab:CreateToggle({Name="X",CurrentValue=skillX,Callback=function(v) skillX=v end})
UI.SkillC=BossTab:CreateToggle({Name="C",CurrentValue=skillC,Callback=function(v) skillC=v end})
UI.SkillV=BossTab:CreateToggle({Name="V",CurrentValue=skillV,Callback=function(v) skillV=v end})
UI.SkillF=BossTab:CreateToggle({Name="F",CurrentValue=skillF,Callback=function(v) skillF=v end})

-- ================================================
-- SECTION 8: OCEAN / EVENT
-- ================================================
UI.OceanToggle=OceanTab:CreateToggle({
    Name="Farm Ocean", CurrentValue=oceanMobsEnabled,
    Callback=function(v) oceanMobsEnabled=v end
})
UI.OceanDD=OceanTab:CreateDropdown({
    Name="Tool", Options=getBackpackTools(),
    CurrentOption=oceanAutoEquipTool and {oceanAutoEquipTool} or {},
    MultipleOptions=false,
    Callback=function(o) oceanAutoEquipTool=o[1] end
})

OceanTab:CreateSection("Ocean Skills")
UI.OceanSkillZ=OceanTab:CreateToggle({Name="Z",CurrentValue=oceanSkillZ,Callback=function(v) oceanSkillZ=v end})
UI.OceanSkillX=OceanTab:CreateToggle({Name="X",CurrentValue=oceanSkillX,Callback=function(v) oceanSkillX=v end})
UI.OceanSkillC=OceanTab:CreateToggle({Name="C",CurrentValue=oceanSkillC,Callback=function(v) oceanSkillC=v end})
UI.OceanSkillV=OceanTab:CreateToggle({Name="V",CurrentValue=oceanSkillV,Callback=function(v) oceanSkillV=v end})
UI.OceanSkillF=OceanTab:CreateToggle({Name="F",CurrentValue=oceanSkillF,Callback=function(v) oceanSkillF=v end})

-- ================================================
-- OCEAN-HOP TAB
-- ================================================
OceanHopTab:CreateSection("🔄 Ocean-Hop Master Control")
UI.OceanHopToggle=OceanHopTab:CreateToggle({
    Name="🔄 Ocean-Hop Enabled", CurrentValue=oceanHopEnabled,
    Callback=function(v) oceanHopEnabled=v; if not v then oceanHopFastSkillActivated=false end end
})

OceanHopTab:CreateSection("Priority Mob Selection")
OceanHopTab:CreateButton({Name="🔄 Refresh Ocean Mobs",Callback=function()
    local oceanMobs = {}
    pcall(function()
        if workspace:FindFirstChild("Mobs") and workspace.Mobs:FindFirstChild("Ocean") then
            for _, mob in pairs(workspace.Mobs.Ocean:GetChildren()) do
                if mob:IsA("Model") then table.insert(oceanMobs, mob.Name) end
            end
        end
    end)
    if UI.OceanHopPriorityDD then UI.OceanHopPriorityDD:Refresh(oceanMobs, true) end
end})
UI.OceanHopPriorityToggle=OceanHopTab:CreateToggle({
    Name="Enable Priority Farm", CurrentValue=oceanHopPriorityEnabled,
    Callback=function(v) oceanHopPriorityEnabled=v end
})
UI.OceanHopPriorityDD=OceanHopTab:CreateDropdown({
    Name="Priority Mob", Options={},
    CurrentOption=oceanHopPriorityMob and {oceanHopPriorityMob} or {},
    MultipleOptions=false,
    Callback=function(o) oceanHopPriorityMob=o[1] end
})

OceanHopTab:CreateSection("🛡️ MUI Immortality (REQUIRED)")
UI.OceanHopMUIDD=OceanHopTab:CreateDropdown({
    Name="MUI Tool ⚠️ REQUIRED", Options=getBackpackTools(),
    CurrentOption=oceanHopMUITool and {oceanHopMUITool} or {},
    MultipleOptions=false,
    Callback=function(o) oceanHopMUITool=o[1] end
})
OceanHopTab:CreateButton({Name="🔄 Refresh Tools",Callback=function()
    if UI.OceanHopMUIDD then UI.OceanHopMUIDD:Refresh(getBackpackTools(),true) end
end})
UI.OceanHopMUIToggle=OceanHopTab:CreateToggle({
    Name="Auto Equip MUI", CurrentValue=oceanHopMUIAutoEquip,
    Callback=function(v) oceanHopMUIAutoEquip=v end
})
UI.OceanHopMUISkillF=OceanHopTab:CreateToggle({
    Name="Activate F (Immortality)", CurrentValue=oceanHopMUISkillF,
    Callback=function(v) oceanHopMUISkillF=v end
})

OceanHopTab:CreateSection("📍 Regular Farm (Choose ONE)")
UI.OceanHopRegularToggle=OceanHopTab:CreateToggle({
    Name="Regular Farm", CurrentValue=oceanHopRegularEnabled,
    Callback=function(v) oceanHopRegularEnabled=v end
})
UI.OceanHopRegularDD=OceanHopTab:CreateDropdown({
    Name="Tool", Options=getBackpackTools(),
    CurrentOption=oceanHopRegularTool and {oceanHopRegularTool} or {},
    MultipleOptions=false,
    Callback=function(o) oceanHopRegularTool=o[1] end
})
OceanHopTab:CreateButton({Name="🔄 Refresh Tools",Callback=function()
    if UI.OceanHopRegularDD then UI.OceanHopRegularDD:Refresh(getBackpackTools(),true) end
end})
UI.OceanHopRegularEquipToggle=OceanHopTab:CreateToggle({
    Name="Auto Equip Tool", CurrentValue=true,
    Callback=function(v) end
})

OceanHopTab:CreateSection("Regular Farm Skills")
UI.OceanHopRegularSkillZ=OceanHopTab:CreateToggle({Name="Z",CurrentValue=oceanHopRegularSkillZ,Callback=function(v) oceanHopRegularSkillZ=v end})
UI.OceanHopRegularSkillX=OceanHopTab:CreateToggle({Name="X",CurrentValue=oceanHopRegularSkillX,Callback=function(v) oceanHopRegularSkillX=v end})
UI.OceanHopRegularSkillC=OceanHopTab:CreateToggle({Name="C",CurrentValue=oceanHopRegularSkillC,Callback=function(v) oceanHopRegularSkillC=v end})
UI.OceanHopRegularSkillV=OceanHopTab:CreateToggle({Name="V",CurrentValue=oceanHopRegularSkillV,Callback=function(v) oceanHopRegularSkillV=v end})
UI.OceanHopRegularSkillF=OceanHopTab:CreateToggle({Name="F",CurrentValue=oceanHopRegularSkillF,Callback=function(v) oceanHopRegularSkillF=v end})

UI.EventToggle=EventTab:CreateToggle({
    Name="Farm Event", CurrentValue=eventIslandEnabled,
    Callback=function(v) eventIslandEnabled=v; if not v then alreadyAtEventIsland=false end end
})
UI.EventDD=EventTab:CreateDropdown({
    Name="Tool", Options=getBackpackTools(),
    CurrentOption=eventAutoEquipTool and {eventAutoEquipTool} or {},
    MultipleOptions=false,
    Callback=function(o) eventAutoEquipTool=o[1] end
})

EventTab:CreateSection("Event Skills")
UI.EventSkillZ=EventTab:CreateToggle({Name="Z",CurrentValue=eventSkillZ,Callback=function(v) eventSkillZ=v end})
UI.EventSkillX=EventTab:CreateToggle({Name="X",CurrentValue=eventSkillX,Callback=function(v) eventSkillX=v end})
UI.EventSkillC=EventTab:CreateToggle({Name="C",CurrentValue=eventSkillC,Callback=function(v) eventSkillC=v end})
UI.EventSkillV=EventTab:CreateToggle({Name="V",CurrentValue=eventSkillV,Callback=function(v) eventSkillV=v end})
UI.EventSkillF=EventTab:CreateToggle({Name="F",CurrentValue=eventSkillF,Callback=function(v) eventSkillF=v end})

-- ================================================
-- SECTION 9: TITLE
-- ================================================
TitleTab:CreateButton({Name="🔄 Refresh",Callback=function()
    if UI.TitleDD then UI.TitleDD:Refresh(getTitles(),true) end
end})

UI.TitleDD=TitleTab:CreateDropdown({
    Name="Title", Options=getTitles(),
    CurrentOption=selectedTitle and {selectedTitle} or {},
    MultipleOptions=false,
    Callback=function(o) selectedTitle=o[1] end
})

TitleTab:CreateButton({
    Name="⚡ EQUIP",
    Callback=function()
        if not selectedTitle then
            Rayfield:Notify({Title="Error",Content="Select a title!",Duration=2})
            return
        end
        task.spawn(function()
            pcall(function()
                local g=LocalPlayer.PlayerGui.MainGui
                local tf=g.TITLE.Main:FindFirstChild(selectedTitle)
                if tf then
                    local frame=tf:FindFirstChild("Frame")
                    if frame then
                        local eq=frame:FindFirstChild("Equip")
                        if eq and eq:IsA("TextButton") then
                            local lbl=eq:FindFirstChild("TextLabel")
                            if lbl and lbl.Text=="Equip" then
                                for i=1,15 do task.spawn(function()
                                    pcall(function()
                                        if firesignal then firesignal(eq.MouseButton1Click)
                                        else eq.MouseButton1Click:Fire() end
                                    end)
                                end) end
                                Rayfield:Notify({Title="Title ✅",Content=selectedTitle,Duration=2})
                            else
                                Rayfield:Notify({Title="Info",Content="Already equipped",Duration=2})
                            end
                        end
                    end
                end
            end)
        end)
    end
})

-- ================================================
-- SECTION 10: GUARANTEE
-- ================================================
UI.GuarToggle=GuarTab:CreateToggle({
    Name="Auto-Claim", CurrentValue=guaranteeEnabled,
    Callback=function(v) guaranteeEnabled=v end
})
GuarTab:CreateButton({Name="🔄 Refresh",Callback=function()
    if UI.GuarDD then UI.GuarDD:Refresh(getGuaranteeItems(),true) end
end})
UI.GuarDD=GuarTab:CreateDropdown({
    Name="Items", Options=getGuaranteeItems(),
    CurrentOption=selectedGuaranteeItems,
    MultipleOptions=true,
    Callback=function(o) selectedGuaranteeItems=o end
})

-- ================================================
-- SECTION 11: MERCHANT
-- ================================================
UI.MerchToggle=MerchTab:CreateToggle({
    Name="Auto-Buy", CurrentValue=merchantEnabled,
    Callback=function(v) merchantEnabled=v end
})
MerchTab:CreateButton({Name="🔄 Refresh",Callback=function()
    if UI.MerchDD then UI.MerchDD:Refresh(getMerchantItems(),true) end
end})
UI.MerchDD=MerchTab:CreateDropdown({
    Name="Items", Options=getMerchantItems(),
    CurrentOption=selectedMerchantItems,
    MultipleOptions=true,
    Callback=function(o) selectedMerchantItems=o end
})

-- ================================================
-- SECTION 12: INVENTORY
-- ================================================
UI.InvToggle=InvTab:CreateToggle({
    Name="Auto-Store (FAST)", CurrentValue=inventoryEnabled,
    Callback=function(v) inventoryEnabled=v end
})

-- ================================================
-- SECTION 13: MISC TAB
-- ================================================
MiscTab:CreateSection("✈️ Fly")

MiscTab:CreateToggle({
    Name="Fly", CurrentValue=false,
    Callback=function(v) flyEnabled=v; if v then startFly() else stopFly() end end,
})

UI.FlySpeedSlider=MiscTab:CreateSlider({
    Name="Fly Speed", Range={10,300}, Increment=5,
    CurrentValue=flySpeed,
    Callback=function(v) flySpeed=v end,
})

MiscTab:CreateSection("🏃 Speed")

UI.SpeedLoopToggle = MiscTab:CreateToggle({
    Name="Speed Loop Active",
    CurrentValue=speedLoopEnabled,
    Callback=function(v)
        speedLoopEnabled=v
        if not v then
            pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=16 end)
        end
    end,
})

UI.SpeedSlider=MiscTab:CreateSlider({
    Name="Walk Speed", Range={16,500}, Increment=1,
    CurrentValue=customWalkSpeed,
    Callback=function(v)
        customWalkSpeed=v
        if speedLoopEnabled then
            pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v end)
        end
    end,
})

MiscTab:CreateButton({Name="Reset Speed",Callback=function()
    customWalkSpeed=16
    if UI.SpeedSlider then UI.SpeedSlider:Set(16) end
    if UI.SpeedLoopToggle then UI.SpeedLoopToggle:Set(false) end
    speedLoopEnabled=false
    pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=16 end)
end})

MiscTab:CreateSection("👻 Noclip")
MiscTab:CreateToggle({
    Name="Noclip", CurrentValue=false,
    Callback=function(v) noclipEnabled=v end,
})

MiscTab:CreateSection("⚡ Graphics Settings")
UI.DisableVFXToggle = MiscTab:CreateToggle({
    Name="Disable VFX", CurrentValue=false,
    Callback=function(v)
        disableVFX = v
        print("🔍 [DEBUG] Disable VFX toggled, attempting click...")
        pcall(function()
            local settingGui = LocalPlayer.PlayerGui:FindFirstChild("SettingGui")
            print("🔍 [DEBUG] SettingGui found: "..tostring(settingGui ~= nil))
            
            if settingGui then
                local setting = settingGui:FindFirstChild("SETTING")
                print("🔍 [DEBUG] SETTING found: "..tostring(setting ~= nil))
                
                if setting then
                    local scrolling = setting:FindFirstChild("ScrollingFrame")
                    print("🔍 [DEBUG] ScrollingFrame found: "..tostring(scrolling ~= nil))
                    
                    if scrolling then
                        local vfx = scrolling:FindFirstChild("DisableVFX")
                        print("🔍 [DEBUG] DisableVFX found: "..tostring(vfx ~= nil))
                        
                        if vfx then
                            local imgBtn = vfx:FindFirstChild("ImageButton")
                            print("🔍 [DEBUG] ImageButton found: "..tostring(imgBtn ~= nil))
                            
                            if imgBtn then
                                print("✅ [DEBUG] Clicking ImageButton...")
                                if firesignal then firesignal(imgBtn.MouseButton1Click)
                                else imgBtn.MouseButton1Click:Fire() end
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end)
    end,
})

UI.DisableCamShakeToggle = MiscTab:CreateToggle({
    Name="Disable Cam Shake", CurrentValue=false,
    Callback=function(v)
        disableCamShake = v
        print("🔍 [DEBUG] Disable Cam Shake toggled, attempting click...")
        pcall(function()
            local settingGui = LocalPlayer.PlayerGui:FindFirstChild("SettingGui")
            print("🔍 [DEBUG] SettingGui found: "..tostring(settingGui ~= nil))
            
            if settingGui then
                local setting = settingGui:FindFirstChild("SETTING")
                print("🔍 [DEBUG] SETTING found: "..tostring(setting ~= nil))
                
                if setting then
                    local scrolling = setting:FindFirstChild("ScrollingFrame")
                    print("🔍 [DEBUG] ScrollingFrame found: "..tostring(scrolling ~= nil))
                    
                    if scrolling then
                        local camshake = scrolling:FindFirstChild("CamShake")
                        print("🔍 [DEBUG] CamShake found: "..tostring(camshake ~= nil))
                        
                        if camshake then
                            local imgBtn = camshake:FindFirstChild("ImageButton")
                            print("🔍 [DEBUG] ImageButton found: "..tostring(imgBtn ~= nil))
                            
                            if imgBtn then
                                print("✅ [DEBUG] Clicking ImageButton...")
                                if firesignal then firesignal(imgBtn.MouseButton1Click)
                                else imgBtn.MouseButton1Click:Fire() end
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end)
    end,
})

MiscTab:CreateSection("🔧 Extra")
MiscTab:CreateButton({Name="Rejoin",Callback=function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end})

-- ================================================
-- AUTO-LOAD CONFIG AT STARTUP
-- ================================================
task.wait(1.5)
if autoLoadConfigName ~= "" and savedConfigs[autoLoadConfigName] then
    applyVariables(savedConfigs[autoLoadConfigName])
    task.wait(0.5)
    updateAllUI()
    Rayfield:Notify({Title="Auto-Load ✅",Content="Config '"..autoLoadConfigName.."' loaded!",Duration=3})
end

-- ================================================
-- SECTION 14: FLY (COMPLETELY FIXED - ABSOLUTE DIRECTION)
-- ================================================
function startFly()
    stopFly()
    task.wait(0.1)
    local char=LocalPlayer.Character
    if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local bg = Instance.new("BodyGyro", hrp)
    bg.P = 9e4
    bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.cframe = hrp.CFrame
    flyBG = bg

    local bv = Instance.new("BodyVelocity", hrp)
    bv.velocity = Vector3.new(0,0.1,0)
    bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV = bv

    hum.PlatformStand = true

    local ctrl = {f = 0, b = 0, l = 0, r = 0}
    local lastctrl = {f = 0, b = 0, l = 0, r = 0}
    local maxspeed = 50
    local speed = 0

    local UserInputService = game:GetService("UserInputService")

    flyConn = RunService.Heartbeat:Connect(function()
        if not flyEnabled or not hrp or not hrp.Parent or not hum then return end
        if not flyBV or not flyBG then return end

        -- Get input from keyboard
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then ctrl.f = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then ctrl.b = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then ctrl.l = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then ctrl.r = 1 end

        -- Acceleration system
        if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
            speed = speed + 0.5 + (speed/maxspeed)
            if speed > maxspeed then
                speed = maxspeed
            end
        elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
            speed = speed - 1
            if speed < 0 then
                speed = 0
            end
        end

        -- Calculate velocity
        local cam = workspace.CurrentCamera
        if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
            flyBV.velocity = ((cam.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((cam.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - cam.CoordinateFrame.p))*speed
            lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
        elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
            flyBV.velocity = ((cam.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((cam.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - cam.CoordinateFrame.p))*speed
        else
            flyBV.velocity = Vector3.new(0,0,0)
        end

        -- Rotation
        flyBG.cframe = cam.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
    end)
end

function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV   then flyBV:Destroy();     flyBV=nil  end
    if flyBG   then flyBG:Destroy();     flyBG=nil  end
    pcall(function()
        local hum=LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand=false end
    end)
end

-- ================================================
-- SECTION 15: UPDATE ALL UI FUNCTION
-- ================================================
function updateAllUI()
    task.spawn(function()
        task.wait(0.2)
        
        if UI.AutoFarmToggle then UI.AutoFarmToggle:Set(autofarmEnabled) end
        if UI.OceanToggle then UI.OceanToggle:Set(oceanMobsEnabled) end
        if UI.EventToggle then UI.EventToggle:Set(eventIslandEnabled) end
        if UI.GuarToggle then UI.GuarToggle:Set(guaranteeEnabled) end
        if UI.MerchToggle then UI.MerchToggle:Set(merchantEnabled) end
        if UI.InvToggle then UI.InvToggle:Set(inventoryEnabled) end
        if UI.Step2FToggle then UI.Step2FToggle:Set(step2FEnabled) end
        if UI.SkillZ then UI.SkillZ:Set(skillZ) end
        if UI.SkillX then UI.SkillX:Set(skillX) end
        if UI.SkillC then UI.SkillC:Set(skillC) end
        if UI.SkillV then UI.SkillV:Set(skillV) end
        if UI.SkillF then UI.SkillF:Set(skillF) end
        
        if UI.OceanSkillZ then UI.OceanSkillZ:Set(oceanSkillZ) end
        if UI.OceanSkillX then UI.OceanSkillX:Set(oceanSkillX) end
        if UI.OceanSkillC then UI.OceanSkillC:Set(oceanSkillC) end
        if UI.OceanSkillV then UI.OceanSkillV:Set(oceanSkillV) end
        if UI.OceanSkillF then UI.OceanSkillF:Set(oceanSkillF) end
        
        if UI.EventSkillZ then UI.EventSkillZ:Set(eventSkillZ) end
        if UI.EventSkillX then UI.EventSkillX:Set(eventSkillX) end
        if UI.EventSkillC then UI.EventSkillC:Set(eventSkillC) end
        if UI.EventSkillV then UI.EventSkillV:Set(eventSkillV) end
        if UI.EventSkillF then UI.EventSkillF:Set(eventSkillF) end
        
        -- Ocean-Hop toggles
        if UI.OceanHopToggle then UI.OceanHopToggle:Set(oceanHopEnabled) end
        if UI.OceanHopPriorityToggle then UI.OceanHopPriorityToggle:Set(oceanHopPriorityEnabled) end
        if UI.OceanHopMUIToggle then UI.OceanHopMUIToggle:Set(oceanHopMUIAutoEquip) end
        if UI.OceanHopMUISkillF then UI.OceanHopMUISkillF:Set(oceanHopMUISkillF) end
        if UI.OceanHopRegularToggle then UI.OceanHopRegularToggle:Set(oceanHopRegularEnabled) end
        if UI.OceanHopRegularEquipToggle then UI.OceanHopRegularEquipToggle:Set(true) end
        if UI.OceanHopRegularSkillZ then UI.OceanHopRegularSkillZ:Set(oceanHopRegularSkillZ) end
        if UI.OceanHopRegularSkillX then UI.OceanHopRegularSkillX:Set(oceanHopRegularSkillX) end
        if UI.OceanHopRegularSkillC then UI.OceanHopRegularSkillC:Set(oceanHopRegularSkillC) end
        if UI.OceanHopRegularSkillV then UI.OceanHopRegularSkillV:Set(oceanHopRegularSkillV) end
        if UI.OceanHopRegularSkillF then UI.OceanHopRegularSkillF:Set(oceanHopRegularSkillF) end
        
        if UI.SpeedLoopToggle then UI.SpeedLoopToggle:Set(speedLoopEnabled) end
        if UI.DisableVFXToggle then UI.DisableVFXToggle:Set(disableVFX) end
        if UI.DisableCamShakeToggle then UI.DisableCamShakeToggle:Set(disableCamShake) end
        
        if UI.SpeedSlider then UI.SpeedSlider:Set(customWalkSpeed) end
        if UI.FlySpeedSlider then UI.FlySpeedSlider:Set(flySpeed) end
        
        task.wait(0.1)
        
        -- Set dropdown values (format: {value})
        if UI.BossDD and selectedBoss then UI.BossDD:Set({selectedBoss}) end
        if UI.Step2DD and step2Tool then UI.Step2DD:Set({step2Tool}) end
        if UI.Step3DD and step3Tool then UI.Step3DD:Set({step3Tool}) end
        if UI.OceanDD and oceanAutoEquipTool then UI.OceanDD:Set({oceanAutoEquipTool}) end
        if UI.EventDD and eventAutoEquipTool then UI.EventDD:Set({eventAutoEquipTool}) end
        if UI.TitleDD and selectedTitle then UI.TitleDD:Set({selectedTitle}) end
        if UI.GuarDD and #selectedGuaranteeItems > 0 then UI.GuarDD:Set(selectedGuaranteeItems) end
        if UI.MerchDD and #selectedMerchantItems > 0 then UI.MerchDD:Set(selectedMerchantItems) end
        
        -- Ocean-Hop dropdowns
        if UI.OceanHopMUIDD and oceanHopMUITool then UI.OceanHopMUIDD:Set({oceanHopMUITool}) end
        if UI.OceanHopPriorityDD and oceanHopPriorityMob then UI.OceanHopPriorityDD:Set({oceanHopPriorityMob}) end
        if UI.OceanHopRegularDD and oceanHopRegularTool then UI.OceanHopRegularDD:Set({oceanHopRegularTool}) end
        
        task.wait(0.1)
        
        -- Refresh dropdowns with latest data
        if UI.BossDD then UI.BossDD:Refresh(getAvailableBosses(), true) end
        if UI.Step2DD then UI.Step2DD:Refresh(getBackpackTools(), true) end
        if UI.Step3DD then UI.Step3DD:Refresh(getBackpackTools(), true) end
        if UI.OceanDD then UI.OceanDD:Refresh(getBackpackTools(), true) end
        if UI.EventDD then UI.EventDD:Refresh(getBackpackTools(), true) end
        if UI.TitleDD then UI.TitleDD:Refresh(getTitles(), true) end
        if UI.GuarDD then UI.GuarDD:Refresh(getGuaranteeItems(), true) end
        
        -- Ocean-Hop refresh
        if UI.OceanHopMUIDD then UI.OceanHopMUIDD:Refresh(getBackpackTools(), true) end
        if UI.OceanHopRegularDD then UI.OceanHopRegularDD:Refresh(getBackpackTools(), true) end
        if UI.MerchDD then UI.MerchDD:Refresh(getMerchantItems(), true) end
        
        print("✅ UI updated completely!")
    end)
end

-- ================================================
-- SECTION 16: LOOPS
-- ================================================

-- Noclip
RunService.Heartbeat:Connect(function()
    if not noclipEnabled then return end
    pcall(function()
        local char=LocalPlayer.Character
        if not char then return end
        for _,p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end)

-- Speed loop
RunService.Heartbeat:Connect(function()
    if not speedLoopEnabled then return end
    pcall(function()
        local char=LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            if char.Humanoid.WalkSpeed~=customWalkSpeed then
                char.Humanoid.WalkSpeed=customWalkSpeed
            end
        end
    end)
end)

-- Auto-delete SkillEffect
task.spawn(function()
    while true do
        task.wait(3)
        if autoDeleteSkillEffect then
            pcall(function()
                local se=workspace:FindFirstChild("SkillEffect")
                if se then se:Destroy() end
            end)
        end
    end
end)

-- ================================================
-- SECTION 17: CORE FUNCTIONS
-- ================================================
local function robustClick(btn)
    if not btn then return end
    -- Try direct click first
    pcall(function()
        if firesignal then firesignal(btn.MouseButton1Click)
        elseif btn.MouseButton1Click then btn.MouseButton1Click:Fire() end
    end)
    -- Retry with spawn if needed
    task.spawn(function()
        for i=1,3 do
            task.wait(0.05)
            pcall(function()
                if firesignal then firesignal(btn.MouseButton1Click)
                elseif btn.MouseButton1Click then btn.MouseButton1Click:Fire() end
            end)
        end
    end)
end

local function equipTool(name)
    if not name then return false end
    if LocalPlayer.Character:FindFirstChild(name) then return true end
    local tool=LocalPlayer.Backpack:FindFirstChild(name)
    if tool then
        pcall(function() LocalPlayer.Character.Humanoid:EquipTool(tool) end)
        task.wait(0.25)
        return true
    end
    return false
end

local function forceEquipTool(toolName)
    if not toolName then return end
    if LocalPlayer.Character:FindFirstChild(toolName) then return end
    task.spawn(function()
        for i=1,5 do
            if LocalPlayer.Character:FindFirstChild(toolName) then break end
            local tool=LocalPlayer.Backpack:FindFirstChild(toolName)
            if tool then pcall(function() LocalPlayer.Character.Humanoid:EquipTool(tool) end) end
            task.wait(0.1)
        end
    end)
end

local function useSkills()
    pcall(function()
        local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
        if ui and ui:FindFirstChild("Mobile Button") then
            if skillZ and ui["Mobile Button"]:FindFirstChild("Z") then robustClick(ui["Mobile Button"]["Z"]); task.wait(0.05) end
            if skillX and ui["Mobile Button"]:FindFirstChild("X") then robustClick(ui["Mobile Button"]["X"]); task.wait(0.05) end
            if skillC and ui["Mobile Button"]:FindFirstChild("C") then robustClick(ui["Mobile Button"]["C"]); task.wait(0.05) end
            if skillV and ui["Mobile Button"]:FindFirstChild("V") then robustClick(ui["Mobile Button"]["V"]); task.wait(0.05) end
            if skillF and ui["Mobile Button"]:FindFirstChild("F") then robustClick(ui["Mobile Button"]["F"]); task.wait(0.05) end
        end
    end)
end

local function useOceanSkills()
    pcall(function()
        local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
        if ui and ui:FindFirstChild("Mobile Button") then
            if oceanSkillZ and ui["Mobile Button"]:FindFirstChild("Z") then robustClick(ui["Mobile Button"]["Z"]); task.wait(0.05) end
            if oceanSkillX and ui["Mobile Button"]:FindFirstChild("X") then robustClick(ui["Mobile Button"]["X"]); task.wait(0.05) end
            if oceanSkillC and ui["Mobile Button"]:FindFirstChild("C") then robustClick(ui["Mobile Button"]["C"]); task.wait(0.05) end
            if oceanSkillV and ui["Mobile Button"]:FindFirstChild("V") then robustClick(ui["Mobile Button"]["V"]); task.wait(0.05) end
            if oceanSkillF and ui["Mobile Button"]:FindFirstChild("F") then robustClick(ui["Mobile Button"]["F"]); task.wait(0.05) end
        end
    end)
end

local function useEventSkills()
    pcall(function()
        local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
        if ui and ui:FindFirstChild("Mobile Button") then
            if eventSkillZ and ui["Mobile Button"]:FindFirstChild("Z") then robustClick(ui["Mobile Button"]["Z"]); task.wait(0.05) end
            if eventSkillX and ui["Mobile Button"]:FindFirstChild("X") then robustClick(ui["Mobile Button"]["X"]); task.wait(0.05) end
            if eventSkillC and ui["Mobile Button"]:FindFirstChild("C") then robustClick(ui["Mobile Button"]["C"]); task.wait(0.05) end
            if eventSkillV and ui["Mobile Button"]:FindFirstChild("V") then robustClick(ui["Mobile Button"]["V"]); task.wait(0.05) end
            if eventSkillF and ui["Mobile Button"]:FindFirstChild("F") then robustClick(ui["Mobile Button"]["F"]); task.wait(0.05) end
        end
    end)
end

local function useOceanHopRegularSkills()
    pcall(function()
        local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
        if ui and ui:FindFirstChild("Mobile Button") then
            if oceanHopRegularSkillZ and ui["Mobile Button"]:FindFirstChild("Z") then robustClick(ui["Mobile Button"]["Z"]); task.wait(0.05) end
            if oceanHopRegularSkillX and ui["Mobile Button"]:FindFirstChild("X") then robustClick(ui["Mobile Button"]["X"]); task.wait(0.05) end
            if oceanHopRegularSkillC and ui["Mobile Button"]:FindFirstChild("C") then robustClick(ui["Mobile Button"]["C"]); task.wait(0.05) end
            if oceanHopRegularSkillV and ui["Mobile Button"]:FindFirstChild("V") then robustClick(ui["Mobile Button"]["V"]); task.wait(0.05) end
            if oceanHopRegularSkillF and ui["Mobile Button"]:FindFirstChild("F") then robustClick(ui["Mobile Button"]["F"]); task.wait(0.05) end
        end
    end)
end

local function useSkillF()
    pcall(function()
        local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
        if ui and ui:FindFirstChild("Mobile Button") then
            local f=ui["Mobile Button"]:FindFirstChild("F")
            if f then ticketClick(f); task.wait(0.1) end
        end
    end)
end

local function useSkillZ()
    pcall(function()
        local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
        if ui and ui:FindFirstChild("Mobile Button") then
            local z=ui["Mobile Button"]:FindFirstChild("Z")
            if z then robustClick(z); task.wait(0.1) end
        end
    end)
end

local function useSkillX()
    pcall(function()
        local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
        if ui and ui:FindFirstChild("Mobile Button") then
            local x=ui["Mobile Button"]:FindFirstChild("X")
            if x then robustClick(x); task.wait(0.1) end
        end
    end)
end

local function useSkillC()
    pcall(function()
        local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
        if ui and ui:FindFirstChild("Mobile Button") then
            local c=ui["Mobile Button"]:FindFirstChild("C")
            if c then robustClick(c); task.wait(0.1) end
        end
    end)
end

local function useSkillV()
    pcall(function()
        local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
        if ui and ui:FindFirstChild("Mobile Button") then
            local v=ui["Mobile Button"]:FindFirstChild("V")
            if v then robustClick(v); task.wait(0.1) end
        end
    end)
end

local function serverHop()
    pcall(function()
        local Api = "https://games.roblox.com/v1/games/"
        local placeId = game.PlaceId
        local serverUrl = Api..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        local raw = game:HttpGet(serverUrl)
        local servers = HttpService:JSONDecode(raw)
        if servers and servers.data and #servers.data > 0 then
            local randomServer = servers.data[math.random(1, #servers.data)]
            if randomServer and randomServer.id ~= game.JobId then
                print("🌐 [SERVER-HOP] Joining random server: "..randomServer.id)
                TeleportService:TeleportToPlaceInstance(placeId, randomServer.id, LocalPlayer)
            end
        end
    end)
end

local function summonBoss()
    if not autofarmEnabled or mainFarmPaused or STEPS_IN_PROGRESS then return end
    pcall(function()
        -- Check if boss already exists
        local boss=workspace.Mobs.Ocean:FindFirstChild(selectedBoss)
        if boss then return end -- Boss exists, don't summon
        
        local g=LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        if g and g:FindFirstChild("SUMMON") and g.SUMMON:FindFirstChild("Main") then
            local btn=g.SUMMON.Main:FindFirstChild(selectedBoss)
            if btn then robustClick(btn) end
        end
    end)
end

local function executeBossFarmSteps()
    if isExecutingSteps or stepsCompleted or not autofarmEnabled then return end
    STEPS_IN_PROGRESS=true; mainFarmPaused=true
    isExecutingSteps=true
    print("🔧 Steps started")
    task.spawn(function()
        pcall(function()
            -- STEP 1 & 4 REMOVED - Auto-equipped by game QOL update
            
            if step2Tool then
                equipTool(step2Tool); task.wait(1)
                if step2FEnabled and not step2FActivated then
                    task.wait(0.3)
                    local ui=LocalPlayer.PlayerGui:FindFirstChild("SkillUI")
                    if ui and ui:FindFirstChild("Mobile Button") then
                        local f=ui["Mobile Button"]:FindFirstChild("F")
                        if f then robustClick(f); step2FActivated=true; task.wait(0.8) end
                    end
                end
            end
            if step3Tool then task.wait(0.3); equipTool(step3Tool); task.wait(0.5) end
            
            task.wait(0.5)
            stepsCompleted=true; isExecutingSteps=false
            STEPS_IN_PROGRESS=false; mainFarmPaused=false
            print("✅ Steps completed!")
            summonBoss()
        end)
    end)
end

-- ================================================
-- SECTION 18: GAME LOOPS
-- ================================================

-- Guarantee
task.spawn(function()
    while task.wait(1) do
        if guaranteeEnabled and #selectedGuaranteeItems>0 and not STEPS_IN_PROGRESS then
            pcall(function()
                local g=LocalPlayer.PlayerGui:FindFirstChild("MainGui")
                if not g or not g:FindFirstChild("GUARANTEE") then return end
                local main=g.GUARANTEE:FindFirstChild("Main")
                if not main then return end
                for _,itemName in pairs(selectedGuaranteeItems) do
                    local itemFrame=main:FindFirstChild(itemName)
                    if not itemFrame then continue end
                    local frame=itemFrame:FindFirstChild("Frame")
                    if not frame then continue end
                    local progress=frame:FindFirstChild("TextLabel1")
                    if not progress then continue end
                    local cur,max=progress.Text:match("(%d+)/(%d+)")
                    if not cur then continue end
                    cur,max=tonumber(cur),tonumber(max)
                    if cur<max then continue end
                    local buyBtn=frame:FindFirstChild("Buy")
                    if buyBtn and buyBtn:IsA("TextButton") then
                        robustClick(buyBtn); task.wait(0.8)
                    end
                end
            end)
        end
    end
end)

-- Merchant
task.spawn(function()
    while task.wait(1.2) do
        if merchantEnabled and not STEPS_IN_PROGRESS then
            pcall(function()
                local g=LocalPlayer.PlayerGui:FindFirstChild("SettingGui")
                if g and g:FindFirstChild("MERCHANT") and g.MERCHANT:FindFirstChild("ScrollingFrame") then
                    for _,itemName in pairs(selectedMerchantItems) do
                        local f=g.MERCHANT.ScrollingFrame:FindFirstChild(itemName)
                        if f and f:FindFirstChild("Stocks") and f:FindFirstChild("BuyButton") then
                            local s=f.Stocks.Text:match("(%d+)")
                            if s and tonumber(s)>0 then robustClick(f.BuyButton); task.wait(0.3) end
                        end
                    end
                end
            end)
        end
    end
end)

-- Inventory
task.spawn(function()
    while true do
        if inventoryEnabled and not STEPS_IN_PROGRESS then
            local found=false
            pcall(function()
                local g=LocalPlayer.PlayerGui:FindFirstChild("MainGui")
                if g and g:FindFirstChild("INVENTORY") and g.INVENTORY:FindFirstChild("BackpackFrame") then
                    for _,f in pairs(g.INVENTORY.BackpackFrame:GetChildren()) do
                        if f.Name=="UIGridLayout" or f.Name=="UIStroke" then continue end
                        local btn=f:FindFirstChild("Button")
                        if btn and btn:FindFirstChild("Amount") then
                            local n=tonumber(btn.Amount.Text:match("(%d+)"))
                            if n and n>0 then
                                found=true
                                for i=1,math.min(n,15) do
                                    task.spawn(function() robustClick(btn) end)
                                end
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end)
            task.wait(found and 0.1 or 2)
        else
            task.wait(1)
        end
    end
end)

-- Farm mob
local function farmMob(mob)
    if not mob or not mob:FindFirstChild("HumanoidRootPart") then return end
    local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        local t=mob.HumanoidRootPart
        local off=Vector3.new(0,0,0)
        if followMode=="behind" then off=t.CFrame.LookVector*-followDistance
        elseif followMode=="front" then off=t.CFrame.LookVector*followDistance
        elseif followMode=="above" then off=Vector3.new(0,followDistance,0)
        elseif followMode=="below" then off=Vector3.new(0,-followDistance,0) end
        hrp.CFrame=CFrame.new(t.Position+off, t.Position)
    end)
    useSkills()
end

local function farmOceanMob(mob)
    if not mob or not mob:FindFirstChild("HumanoidRootPart") then return end
    local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        local t=mob.HumanoidRootPart
        local off=Vector3.new(0,0,0)
        if followMode=="behind" then off=t.CFrame.LookVector*-followDistance
        elseif followMode=="front" then off=t.CFrame.LookVector*followDistance
        elseif followMode=="above" then off=Vector3.new(0,followDistance,0)
        elseif followMode=="below" then off=Vector3.new(0,-followDistance,0) end
        hrp.CFrame=CFrame.new(t.Position+off, t.Position)
    end)
    useOceanSkills()
end

local function farmOceanHopMob(mob, mode)
    if not mob or not mob:FindFirstChild("HumanoidRootPart") then return end
    local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        local t=mob.HumanoidRootPart
        hrp.CFrame=CFrame.new(t.Position+Vector3.new(0,3,2), t.Position)
    end)
    
    if mode == "regular" then
        if oceanHopRegularTool then forceEquipTool(oceanHopRegularTool) end
        useOceanHopRegularSkills()
    end
end

local function farmEventMob(mob)
    if not mob or not mob:FindFirstChild("HumanoidRootPart") then return end
    local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        local t=mob.HumanoidRootPart
        local off=Vector3.new(0,0,0)
        if followMode=="behind" then off=t.CFrame.LookVector*-followDistance
        elseif followMode=="front" then off=t.CFrame.LookVector*followDistance
        elseif followMode=="above" then off=Vector3.new(0,followDistance,0)
        elseif followMode=="below" then off=Vector3.new(0,-followDistance,0) end
        hrp.CFrame=CFrame.new(t.Position+off, t.Position)
    end)
    useEventSkills()
end

-- Ocean
task.spawn(function()
    while task.wait(0.3) do
        if STEPS_IN_PROGRESS then continue end
        if oceanMobsEnabled then
            local mobs={}
            pcall(function()
                if workspace:FindFirstChild("Mobs") and workspace.Mobs:FindFirstChild("Ocean") then
                    for _,mob in pairs(workspace.Mobs.Ocean:GetChildren()) do
                        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
                            local isBoss=false
                            for _,bn in pairs(getAvailableBosses()) do
                                if mob.Name==bn then isBoss=true; break end
                            end
                            if not isBoss then table.insert(mobs,mob) end
                        end
                    end
                end
            end)
            if #mobs>0 then
                mainFarmPaused=true; alreadyAtEventIsland=false
                if oceanAutoEquipTool then forceEquipTool(oceanAutoEquipTool) end
                for _,mob in pairs(mobs) do
                    while mob and mob.Parent and oceanMobsEnabled and not STEPS_IN_PROGRESS do
                        farmOceanMob(mob); task.wait(0.2)
                        if not workspace.Mobs.Ocean:FindFirstChild(mob.Name) then break end
                    end
                end
                mainFarmPaused=false
            end
        end
    end
end)

-- Ocean-Hop
task.spawn(function()
    while task.wait(0.3) do
        if not oceanHopEnabled or STEPS_IN_PROGRESS then continue end
        
        -- Regular Farm Mode
        if oceanHopRegularEnabled and not oceanHopFastEnabled then
            local mobs = {}
            pcall(function()
                if workspace:FindFirstChild("Mobs") and workspace.Mobs:FindFirstChild("Ocean") then
                    for _,mob in pairs(workspace.Mobs.Ocean:GetChildren()) do
                        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
                            table.insert(mobs, mob)
                        end
                    end
                end
            end)
            
            if #mobs > 0 then
                -- Equip MUI if needed
                if oceanHopMUIAutoEquip and oceanHopMUITool then
                    forceEquipTool(oceanHopMUITool)
                    if oceanHopMUISkillF then useSkillF() end
                    task.wait(1)
                end
                
                -- Farm with priority if enabled
                local targetMob = nil
                if oceanHopPriorityEnabled and oceanHopPriorityMob then
                    for _, m in pairs(mobs) do
                        if m.Name == oceanHopPriorityMob then
                            targetMob = m
                            break
                        end
                    end
                end
                
                -- Farm all mobs (or priority first)
                if targetMob then
                    while targetMob and targetMob.Parent and oceanHopRegularEnabled do
                        farmOceanHopMob(targetMob, "regular")
                        task.wait(0.2)
                        if not workspace.Mobs.Ocean:FindFirstChild(targetMob.Name) then break end
                    end
                end
                
                -- Farm remaining mobs
                for _, mob in pairs(mobs) do
                    if mob ~= targetMob then
                        while mob and mob.Parent and oceanHopRegularEnabled do
                            farmOceanHopMob(mob, "regular")
                            task.wait(0.2)
                            if not workspace.Mobs.Ocean:FindFirstChild(mob.Name) then break end
                        end
                    end
                end
            else
                -- Ocean is empty, server hop
                print("🔄 [OCEAN-HOP] Ocean empty, preparing server hop...")
                task.wait(oceanHopServerHopDelay)
                if oceanHopEnabled then
                    oceanHopFastSkillActivated = false
                    print("🌐 [OCEAN-HOP] Server hopping...")
                    serverHop()
                end
            end
        
        -- Fast Farm Mode (Vergil)
        end
    end
end)

-- Event
task.spawn(function()
    while task.wait(0.6) do
        if STEPS_IN_PROGRESS then continue end
        if eventIslandEnabled and not mainFarmPaused then
            if not alreadyAtEventIsland then
                pcall(function()
                    local island=workspace:FindFirstChild("Island")
                    if island and island:FindFirstChild("Event Island") then
                        local txt=island["Event Island"]:FindFirstChild("EventText")
                        if txt then
                            local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local pos=txt:IsA("Model") and txt:FindFirstChild("HumanoidRootPart") or txt
                                if pos then hrp.CFrame=pos.CFrame*CFrame.new(0,5,0); alreadyAtEventIsland=true end
                            end
                        end
                    end
                end)
                task.wait(1)
            end
            if eventAutoEquipTool then forceEquipTool(eventAutoEquipTool) end
            local mobs={}
            pcall(function()
                if workspace:FindFirstChild("Mobs") and workspace.Mobs:FindFirstChild("Event Island") then
                    for _,mob in pairs(workspace.Mobs["Event Island"]:GetChildren()) do
                        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
                            table.insert(mobs,mob)
                        end
                    end
                end
            end)
            for _,mob in pairs(mobs) do
                while mob and mob.Parent and eventIslandEnabled and not mainFarmPaused and not STEPS_IN_PROGRESS do
                    farmEventMob(mob); task.wait(0.2)
                    if not workspace.Mobs["Event Island"]:FindFirstChild(mob.Name) then break end
                end
            end
        end
    end
end)

-- Boss attack
task.spawn(function()
    while task.wait(0.2) do
        if STEPS_IN_PROGRESS then continue end
        if autofarmEnabled and stepsCompleted and not mainFarmPaused then
            pcall(function()
                local boss=workspace.Mobs.Ocean:FindFirstChild(selectedBoss)
                if boss and boss:FindFirstChild("HumanoidRootPart") then
                    local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist=(hrp.Position-boss.HumanoidRootPart.Position).Magnitude
                        if dist<attackRange then
                            if step3Tool then forceEquipTool(step3Tool) end
                            useSkills()
                        end
                    end
                else
                    summonBoss()
                end
            end)
        end
    end
end)

-- Boss anchor
task.spawn(function()
    while task.wait(0.1) do
        if STEPS_IN_PROGRESS or not autofarmEnabled or not stepsCompleted or mainFarmPaused then continue end
        pcall(function()
            local boss=workspace.Mobs.Ocean:FindFirstChild(selectedBoss)
            if boss and boss:FindFirstChild("HumanoidRootPart") then
                local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local t=boss.HumanoidRootPart
                    local off=Vector3.new(0,0,0)
                    if followMode=="behind" then off=t.CFrame.LookVector*-followDistance
                    elseif followMode=="front" then off=t.CFrame.LookVector*followDistance
                    elseif followMode=="above" then off=Vector3.new(0,followDistance,0)
                    elseif followMode=="below" then off=Vector3.new(0,-followDistance,0) end
                    hrp.CFrame=CFrame.new(t.Position+off, t.Position)
                end
            end
        end)
    end
end)

-- Steps manager
task.spawn(function()
    while task.wait(2) do
        if autofarmEnabled and not stepsCompleted and not isExecutingSteps and not STEPS_IN_PROGRESS then
            pcall(function()
                if not workspace.Mobs.Ocean:FindFirstChild(selectedBoss) then
                    executeBossFarmSteps(); task.wait(8)
                end
            end)
        end
    end
end)

-- Respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(4)
    stepsCompleted=false; step2FActivated=false
    isExecutingSteps=false; STEPS_IN_PROGRESS=false
    alreadyAtEventIsland=false
    
    -- Re-equip tools only if mobs actually exist
    if oceanMobsEnabled and oceanAutoEquipTool then
        pcall(function()
            local oceanFolder = workspace:FindFirstChild("Mobs") and workspace.Mobs:FindFirstChild("Ocean")
            if oceanFolder then
                for _,m in pairs(oceanFolder:GetChildren()) do
                    if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then
                        forceEquipTool(oceanAutoEquipTool)
                        break
                    end
                end
            end
        end)
    end
    if eventIslandEnabled and eventAutoEquipTool then
        pcall(function()
            local eventFolder = workspace:FindFirstChild("Mobs") and workspace.Mobs:FindFirstChild("Event Island")
            if eventFolder then
                for _,m in pairs(eventFolder:GetChildren()) do
                    if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then
                        forceEquipTool(eventAutoEquipTool)
                        break
                    end
                end
            end
        end)
    end
    
    if flyEnabled then task.wait(0.5); startFly() end
    if autofarmEnabled then task.wait(1); executeBossFarmSteps() end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Auto-load
if autoLoadConfigName~="" and savedConfigs[autoLoadConfigName] then
    task.spawn(function()
        task.wait(3)
        Rayfield:Notify({
            Title="Auto-Load ✅",
            Content="Config '"..autoLoadConfigName.."' loaded!",
            Duration=4,
        })
    end)
end

print("✅ SJW Premium V19 - QOL UPDATED (No Step 1/4)")
print("📁 Config folder: "..ConfigFolder)