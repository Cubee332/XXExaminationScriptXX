--!nolint
-- ============================================
-- Examination v16.4.9 调整了一些设置
-- 此脚本使用AI生成
-- 因使用混淆加密会导致手机用户无法正常使用所以没有使用混淆加密
-- 请不要拿去缝合 此脚本永久免费
-- 若随意缝合和偷源码自称是自制的该脚本会进行删库处理并停止对外更新( AI写的史山代码你也要？？？？)
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")
local BadgeService = game:GetService("BadgeService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local infStaminaEnabled = false
local espEnabled = false
local headHitboxEnabled = false
local autoInteractEnabled = false
local forceResetEnabled = false
local slideEnabled = false
local slideSteerEnabled = false
local nvgEnabled = false
local elephantImmuneEnabled = false
local radarBoostEnabled = false
local recoilEnabled = false
local muzzleEnabled = false
local magicBulletEnabled = false
local forceHeadshotEnabled = false
local chatForceEnabled = false
local autoQTEEnabled = false
local shotgunNoPumpEnabled = false
local shieldFixEnabled = false
local shieldVMEnabled = false
local noCDEnabled = false
local noCDActiveUntil = 0
local pierceShieldEnabled = true
local pierceHelmetEnabled = true
local pierceTeammateEnabled = true
local pierceCorpseEnabled = true
local headSize = 4
local slideDistanceMult = 2
local shieldVMAlpha = 0.9
local slideSteerMode = "camera"

local AI_CONTAINERS = {"Characters", "Reactor1", "Reactor2", "Reactor3", "Reactor4"}

local SHOTGUN_PUMP_IDS = {
    ["115903749552317"] = true,
    ["80315455447277"]  = true,
    ["89272072134105"]  = true,
    ["96917301511774"]  = true,
    ["135326741887023"] = true,
    ["116710355675938"] = true,
}
local SHOTGUN_SPEED_MULT = 1000

local cleanupFns = {}
local _playerChars = {}
local function _bindPlayerChar(p)
    local function add(c) if c then _playerChars[c] = true end end
    local function rem(c) if c then _playerChars[c] = nil end end
    if p.Character then add(p.Character) end
    p.CharacterAdded:Connect(add)
    p.CharacterRemoving:Connect(rem)
end
for _, p in ipairs(Players:GetPlayers()) do _bindPlayerChar(p) end
Players.PlayerAdded:Connect(_bindPlayerChar)

local function safeCleanup()
    if _G._ExamStaminaBackup then
        local char0 = lp.Character
        if char0 then
            local handler0 = char0:FindFirstChild("ClientHandler")
            local sm0 = handler0 and handler0:FindFirstChild("State")
            if sm0 then
                local ok0, s0 = pcall(function() return require(sm0) end)
                if ok0 and type(s0) == "table" and s0.stamina then
                    local b = _G._ExamStaminaBackup
                    if b.current ~= nil then s0.stamina.current = b.current end
                    if b.fullRegen ~= nil then s0.stamina.fullRegen = b.fullRegen end
                    if b.regenDelay ~= nil then s0.stamina.regenDelay = b.regenDelay end
                    if b.max ~= nil then s0.stamina.max = b.max end
                    if b.maxStamina ~= nil then s0.stamina.maxStamina = b.maxStamina end
                    if b.maximum ~= nil then s0.stamina.maximum = b.maximum end
                end
            end
        end
        _G._ExamStaminaBackup = nil
    end
    if _G.ExaminationUI and _G.ExaminationUI.Parent then
        pcall(function() _G.ExaminationUI:Destroy() end)
    end
    _G.ExaminationUI = nil
    for _, k in ipairs({"_NR6UI","_MB2UI","_FH2UI","_MZ8UI","_MZ9UI","_MZ10UI","_MZ11UI","MBT2_UI","MBT2_FovCircle","MB_TargetLock","SPRadar_UI","ExamAutoQTE","ExamQTEProbe","ExamQTEUIProbe","ExamNetHook","ExamQTEDecomp","ExamHelmetTest","ExamR8Probe","ExamR8Decomp","ExamR8Capture","ExamR8v11","ExamR8v12","ExamR8v13","ExamR8v14","ExamR8v15","ExamShotgunTest","ExamMuzzle","ExamCanShoot","NewShotgunTest","SlideSteer"}) do
        if _G[k] and _G[k].Parent then pcall(function() _G[k]:Destroy() end) end
        _G[k] = nil
    end
    for _, k in ipairs({"_NR6ScanLoop","_NR6ObsLoop","_MB2FovGui","_MZ8HBC","_MZ9HBC","_MZ10HBC","_MZ11HBC","_MZ11WatchConn"}) do
        if _G[k] then
            pcall(function()
                if _G[k].Disconnect then _G[k]:Disconnect()
                elseif _G[k].Destroy then _G[k]:Destroy() end
            end)
            _G[k] = nil
        end
    end
    if _G.__ExamChatForceCleanup then pcall(_G.__ExamChatForceCleanup); _G.__ExamChatForceCleanup = nil end
    if _G.__ExamChatForceGui and _G.__ExamChatForceGui.Parent then
        pcall(function() _G.__ExamChatForceGui:Destroy() end)
        _G.__ExamChatForceGui = nil
    end
    if _G._MZ11Disabled then
        for p, orig in pairs(_G._MZ11Disabled) do
            if p and p.Parent then pcall(function() p.CanCollide = orig end) end
        end
        _G._MZ11Disabled = nil
    end
    if _G._NR6SpringModule and _G._NR6OrigNew then
        local mod = _G._NR6SpringModule
        local ok, spring = pcall(function() return mod.spring end)
        if ok and spring then
            local mt = getmetatable(spring)
            if mt then pcall(function() setmetatable(spring, nil) end) end
            pcall(function() rawset(spring, "new", _G._NR6OrigNew) end)
            if mt then pcall(function() setmetatable(spring, mt) end) end
        end
        _G._NR6SpringModule = nil; _G._NR6OrigNew = nil
    end
    if _G._NR6Patched then
        for obj, orig in pairs(_G._NR6Patched) do
            pcall(function() rawset(obj, "Accelerate", orig) end)
        end
        _G._NR6Patched = nil
    end
    if _G._MB2Net and _G._MB2OrigInvoke then pcall(function() _G._MB2Net.InvokeServer = _G._MB2OrigInvoke end) end
    if _G._MB2Net and _G._MB2OrigFire then pcall(function() _G._MB2Net.FireServer = _G._MB2OrigFire end) end
    if _G._MB2Raycast and _G._MB2OrigRaycastNew then pcall(function() rawset(_G._MB2Raycast, "new", _G._MB2OrigRaycastNew) end) end
    _G._MB2Net = nil; _G._MB2OrigInvoke = nil; _G._MB2OrigFire = nil
    _G._MB2Raycast = nil; _G._MB2OrigRaycastNew = nil
    if _G._FH2Net and _G._FH2OrigInvoke then pcall(function() _G._FH2Net.InvokeServer = _G._FH2OrigInvoke end) end
    _G._FH2Net = nil; _G._FH2OrigInvoke = nil
    if _G._shieldFixOrigBadge and hookfunction then
        pcall(function() hookfunction(BadgeService.UserHasBadgeAsync, _G._shieldFixOrigBadge) end)
        _G._shieldFixOrigBadge = nil
    end
    if _G._shieldFixTargetTrySlide and _G._shieldFixOrigTrySlide and hookfunction then
        pcall(function() hookfunction(_G._shieldFixTargetTrySlide, _G._shieldFixOrigTrySlide) end)
        _G._shieldFixTargetTrySlide = nil
        _G._shieldFixOrigTrySlide = nil
    end
    for _, name in ipairs({"ShieldTransTestUI", "ShieldVMTestUI", "NumberKeyBlockerTest", "SlideSteerModeTest", "SlideCDProbeUI", "SlideNoCDTestUI", "SlideChainTraceUI", "SlideCDv3UI", "SlideCDv31UI", "v63DumpUI", "SlideNoCDv2UI", "SlideNoCDv21UI", "SlideNoCDv3UI", "SlideNoCDv31UI", "SlideAllUI", "SlideResetTestUI"}) do
        if _G[name] and _G[name].Parent then
            pcall(function() _G[name]:Destroy() end)
            _G[name] = nil
        end
    end
    local function destroyFov()
        local parents = {}
        if gethui then local ok, h = pcall(gethui); if ok and h then table.insert(parents, h) end end
        table.insert(parents, CoreGui)
        local pg = lp:FindFirstChild("PlayerGui")
        if pg then table.insert(parents, pg) end
        for _, p in ipairs(parents) do
            if p then
                for _, n in ipairs({"ForceHS_FOVCircle","MB2_FOVCircle","MBT2_FovCircle"}) do
                    local fc = p:FindFirstChild(n)
                    if fc then pcall(function() fc:Destroy() end) end
                end
            end
        end
    end
    destroyFov()
    for _, name in ipairs({"C4Test","C4Test2","C4Test3","C4Test4","C4Test5","C4Test6","BTRC4Test","BTRC4Test2","BTRFinder","FireUltra","FireSimple","FireMod","AmmoDetect2","ConfigDump","FullFire","FullFire2","AmmoV2","AmmoV3","AmmoHook","AmmoMini","AmmoMod","DoorOpener","DoorOpener2","DoorOpener3","PromptScanner","StoryDoor","StoryDoor2","StoryV3","StoryV4","StoryV5","NoSignalImmune","NoSignalV2","NoSignalV3","RadarImmune","ExamTestMenu","RD5","RD4","RD3","RD2","RL","ForceHeadshotUI","BulletAimHackUI"}) do
        if _G[name] and _G[name].Parent then pcall(function() _G[name]:Destroy() end) end
        _G[name] = nil
    end
    destroyFov()
    local function cleanESP(obj)
        if not obj then return end
        local kill = {}
        for _, c in ipairs(obj:GetChildren()) do
            local n = c.Name
            local isESP = (c:IsA("Highlight") and (n == "AI_Highlight" or n == "_ExamESP_HL"))
                or (c:IsA("BillboardGui") and (n == "AI_HealthUI" or n == "_ExamESP_HB"))
                or (n == "Exam_MB_LockBB")
            if isESP then table.insert(kill, c) end
        end
        for _, c in ipairs(kill) do pcall(function() c:Destroy() end) end
    end
    local map = Workspace:FindFirstChild("Map")
    if map then
        local btr = map:FindFirstChild("BTR-82 (BOSS)")
        if btr then cleanESP(btr) end
    end
    cleanESP(Workspace:FindFirstChild("BTRDrone"))
    for _, folderName in ipairs(AI_CONTAINERS) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, c in ipairs(folder:GetChildren()) do cleanESP(c) end
        end
    end
    do
        local pg = lp:FindFirstChild("PlayerGui")
        local mm = pg and pg:FindFirstChild("Minimap")
        local mc = mm and mm:FindFirstChild("MinimapContainer")
        local core = mc and mc:FindFirstChild("Core")
        local hl = core and core:FindFirstChild("Highlights")
        if hl then
            for _, c in ipairs(hl:GetChildren()) do
                if c.Name == "SPRadar_Enemy" then
                    pcall(function() c:Destroy() end)
                end
            end
        end
    end
    local char = lp.Character
    if char and _G._InfNVG_AddedCloaker then
        local c = char:FindFirstChild("IsCloaker")
        if c then c:Destroy() end
    end
    for _, k in ipairs({"_InfNVG_TextSignalConn","_InfNVG_BarSignalConn","_InfNVG_Loop"}) do
        if _G[k] then pcall(function() _G[k]:Disconnect() end); _G[k] = nil end
    end
    _G._InfNVG_AddedCloaker = nil
    _G._InfNVG_OrigPercentText = nil
    _G._InfNVG_OrigBarSize = nil
    if _G._ElephantImmune_Loop then
        pcall(function() _G._ElephantImmune_Loop:Disconnect() end)
        _G._ElephantImmune_Loop = nil
    end
    if _G._ElephantImmune_DisabledScripts then
        for s, orig in pairs(_G._ElephantImmune_DisabledScripts) do
            if s and s.Parent then pcall(function() s.Disabled = orig end) end
        end
        _G._ElephantImmune_DisabledScripts = nil
    end
    if _G._KillPartBackup then
        for p, orig in pairs(_G._KillPartBackup) do
            if p and p.Parent then
                pcall(function()
                    p.Size = orig.Size
                    p.CFrame = orig.CFrame
                    p.CanTouch = orig.CanTouch
                    p.CanCollide = orig.CanCollide
                end)
            end
        end
        _G._KillPartBackup = nil
    end
    if _G._RadarBoost_Conns then
        for _, c in ipairs(_G._RadarBoost_Conns) do pcall(function() c:Disconnect() end) end
    end
    _G._RadarBoost_Conns = {}
    _G._RadarBoost_ZoneBackup = {}
    _G._RadarBoost_ScriptBackup = {}
    local pg0 = lp:FindFirstChild("PlayerGui")
    local mm0 = pg0 and pg0:FindFirstChild("Minimap")
    local mc0 = mm0 and mm0:FindFirstChild("MinimapContainer")
    local core0 = mc0 and mc0:FindFirstChild("Core")
    local hl0 = core0 and core0:FindFirstChild("Highlights")
    if hl0 then
        for _, ch in ipairs(hl0:GetChildren()) do
            if ch:GetAttribute("RDPoint") == true then pcall(function() ch:Destroy() end) end
        end
    end
    if mc0 then
        local oldLbl = mc0:FindFirstChild("SignalBoosterLabel")
        if oldLbl then pcall(function() oldLbl:Destroy() end) end
    end
end
pcall(safeCleanup)

local function detectLayout()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "mobile"
    end
    return "desktop"
end
local currentLayout = detectLayout()
local currentTab = "base"

local LAYOUT = {
    mobile = {
        W = 320, H = 570,
        TitleH = 34, TabY = 36, PageTop = 66,
        items = {
            cdLabel          = { p = UDim2.new(0, 15, 0, 4),   s = UDim2.new(1, -30, 0, 20) },
            stamina          = { p = UDim2.new(0, 15, 0, 28),  s = UDim2.new(0, 140, 0, 28) },
            nameBtn          = { p = UDim2.new(0, 15, 0, 62),  s = UDim2.new(0, 140, 0, 28) },
            headHitbox       = { p = UDim2.new(0, 15, 0, 96),  s = UDim2.new(0, 140, 0, 28) },
            forceReset       = { p = UDim2.new(0, 15, 0, 130), s = UDim2.new(0, 140, 0, 28) },
            nvg              = { p = UDim2.new(0, 15, 0, 164), s = UDim2.new(0, 140, 0, 28) },
            muzzle           = { p = UDim2.new(0, 15, 0, 198), s = UDim2.new(0, 140, 0, 28) },
            chatForce        = { p = UDim2.new(0, 15, 0, 232), s = UDim2.new(0, 140, 0, 28) },
            shieldSlide      = { p = UDim2.new(0, 15, 0, 266), s = UDim2.new(0, 140, 0, 28) },
            shieldVM         = { p = UDim2.new(0, 15, 0, 300), s = UDim2.new(0, 140, 0, 28) },
            noCD             = { p = UDim2.new(0, 15, 0, 334), s = UDim2.new(0, 140, 0, 28) },
            esp              = { p = UDim2.new(0, 165, 0, 28), s = UDim2.new(0, 140, 0, 28) },
            hpBtn            = { p = UDim2.new(0, 165, 0, 62), s = UDim2.new(0, 140, 0, 28) },
            autoInteract     = { p = UDim2.new(0, 165, 0, 96), s = UDim2.new(0, 140, 0, 28) },
            slide            = { p = UDim2.new(0, 165, 0, 130),s = UDim2.new(0, 140, 0, 28) },
            slideSteer       = { p = UDim2.new(0, 165, 0, 164),s = UDim2.new(0, 140, 0, 28) },
            slideSteerMode   = { p = UDim2.new(0, 165, 0, 198),s = UDim2.new(0, 140, 0, 28) },
            elephantImmune   = { p = UDim2.new(0, 165, 0, 232),s = UDim2.new(0, 140, 0, 28) },
            recoil           = { p = UDim2.new(0, 165, 0, 266),s = UDim2.new(0, 140, 0, 28) },
            forceHeadshot    = { p = UDim2.new(0, 165, 0, 300),s = UDim2.new(0, 140, 0, 28) },
            autoQTE          = { p = UDim2.new(0, 165, 0, 334),s = UDim2.new(0, 140, 0, 28) },
            shotgunNoPump    = { p = UDim2.new(0, 165, 0, 368),s = UDim2.new(0, 140, 0, 28) },
            layoutSwitch     = { p = UDim2.new(0, 15, 0, 406), s = UDim2.new(1, -30, 0, 28) },
            headSizeLabel    = { p = UDim2.new(0, 15, 0, 442), s = UDim2.new(0, 50, 0, 22) },
            headSizeInput    = { p = UDim2.new(0, 70, 0, 442), s = UDim2.new(0, 55, 0, 22) },
            slideDistLabel   = { p = UDim2.new(0, 140, 0, 442),s = UDim2.new(0, 90, 0, 22) },
            slideDistInput   = { p = UDim2.new(0, 235, 0, 442),s = UDim2.new(0, 70, 0, 22) },
            shieldAlphaLabel = { p = UDim2.new(0, 15, 0, 470), s = UDim2.new(0, 90, 0, 22) },
            shieldAlphaInput = { p = UDim2.new(0, 110, 0, 470),s = UDim2.new(0, 60, 0, 22) },
        },
    },
    desktop = {
        W = 320, H = 910,
        TitleH = 30, TabY = 33, PageTop = 63,
        items = {
            cdLabel          = { p = UDim2.new(0, 15, 0, 5),   s = UDim2.new(1, -30, 0, 22) },
            stamina          = { p = UDim2.new(0, 15, 0, 34),  s = UDim2.new(1, -30, 0, 30) },
            esp              = { p = UDim2.new(0, 15, 0, 70),  s = UDim2.new(1, -30, 0, 30) },
            nameBtn          = { p = UDim2.new(0, 15, 0, 106), s = UDim2.new(0, 140, 0, 28) },
            hpBtn            = { p = UDim2.new(0, 165, 0, 106),s = UDim2.new(0, 140, 0, 28) },
            headHitbox       = { p = UDim2.new(0, 15, 0, 142), s = UDim2.new(1, -30, 0, 30) },
            autoInteract     = { p = UDim2.new(0, 15, 0, 178), s = UDim2.new(1, -30, 0, 30) },
            forceReset       = { p = UDim2.new(0, 15, 0, 214), s = UDim2.new(1, -30, 0, 30) },
            slide            = { p = UDim2.new(0, 15, 0, 250), s = UDim2.new(1, -30, 0, 30) },
            slideSteer       = { p = UDim2.new(0, 15, 0, 286), s = UDim2.new(1, -30, 0, 30) },
            slideSteerMode   = { p = UDim2.new(0, 15, 0, 322), s = UDim2.new(1, -30, 0, 30) },
            nvg              = { p = UDim2.new(0, 15, 0, 358), s = UDim2.new(1, -30, 0, 30) },
            elephantImmune   = { p = UDim2.new(0, 15, 0, 394), s = UDim2.new(1, -30, 0, 30) },
            muzzle           = { p = UDim2.new(0, 15, 0, 430), s = UDim2.new(1, -30, 0, 30) },
            recoil           = { p = UDim2.new(0, 15, 0, 466), s = UDim2.new(1, -30, 0, 30) },
            chatForce        = { p = UDim2.new(0, 15, 0, 502), s = UDim2.new(1, -30, 0, 30) },
            forceHeadshot    = { p = UDim2.new(0, 15, 0, 538), s = UDim2.new(1, -30, 0, 30) },
            autoQTE          = { p = UDim2.new(0, 15, 0, 574), s = UDim2.new(1, -30, 0, 30) },
            shotgunNoPump    = { p = UDim2.new(0, 15, 0, 610), s = UDim2.new(1, -30, 0, 30) },
            shieldSlide      = { p = UDim2.new(0, 15, 0, 646), s = UDim2.new(1, -30, 0, 30) },
            shieldVM         = { p = UDim2.new(0, 15, 0, 682), s = UDim2.new(1, -30, 0, 30) },
            noCD             = { p = UDim2.new(0, 15, 0, 718), s = UDim2.new(1, -30, 0, 30) },
            layoutSwitch     = { p = UDim2.new(0, 15, 0, 754), s = UDim2.new(1, -30, 0, 28) },
            headSizeLabel    = { p = UDim2.new(0, 15, 0, 788), s = UDim2.new(0, 50, 0, 22) },
            headSizeInput    = { p = UDim2.new(0, 65, 0, 788), s = UDim2.new(0, 55, 0, 22) },
            slideDistLabel   = { p = UDim2.new(0, 130, 0, 788),s = UDim2.new(0, 90, 0, 22) },
            slideDistInput   = { p = UDim2.new(0, 225, 0, 788),s = UDim2.new(0, 75, 0, 22) },
            shieldAlphaLabel = { p = UDim2.new(0, 15, 0, 816), s = UDim2.new(0, 90, 0, 22) },
            shieldAlphaInput = { p = UDim2.new(0, 110, 0, 816),s = UDim2.new(0, 60, 0, 22) },
        },
    },
}

local TAB_HEIGHTS = {
    mobile = {
        base  = 570,
        magic = 450,
        radar = 320,
    },
    desktop = {
        base  = 910,
        magic = 450,
        radar = 320,
    },
}

local uiParent = CoreGui
if gethui then
    local ok, h = pcall(gethui)
    if ok and h then uiParent = h end
end

local function getTabHeight()
    local th = TAB_HEIGHTS[currentLayout]
    if th then return th[currentTab] or th.base end
    return 570
end

local gui = Instance.new("ScreenGui")
gui.Name = "ExaminationUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 101
gui.Parent = uiParent
_G.ExaminationUI = gui

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, LAYOUT[currentLayout].W, 0, getTabHeight())
main.Position = UDim2.new(0.5, -LAYOUT[currentLayout].W/2, 0.5, -getTabHeight()/2)
main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
main.Active = false
main.Draggable = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, LAYOUT[currentLayout].TitleH)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.Active = false
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Examination v16.4.9"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left

local function bindTap(btn, fn)
    local startPos = nil
    btn.InputBegan:Connect(function(input)
        local ut = input.UserInputType
        if ut == Enum.UserInputType.Touch or ut == Enum.UserInputType.MouseButton1 then
            startPos = input.Position
        end
    end)
    btn.InputEnded:Connect(function(input)
        if not startPos then return end
        local ut = input.UserInputType
        if ut == Enum.UserInputType.Touch or ut == Enum.UserInputType.MouseButton1 then
            local d = (input.Position - startPos).Magnitude
            startPos = nil
            if d < 12 then fn() end
        end
    end)
end

local collapseBtn = Instance.new("TextButton", titleBar)
collapseBtn.Size = UDim2.new(0, 30, 0, 24)
collapseBtn.Position = UDim2.new(1, -62, 0, 5)
collapseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
collapseBtn.Text = "▲"
collapseBtn.TextColor3 = Color3.new(1, 1, 1)
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 13
collapseBtn.Active = true
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0, 5)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Active = true
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1, -30, 0, 26)
tabBar.Position = UDim2.new(0, 15, 0, LAYOUT[currentLayout].TabY)
tabBar.BackgroundTransparency = 1

local TAB_W = 1/3
local function mkTabBtn(name, text, xScale)
    local b = Instance.new("TextButton", tabBar)
    b.Name = name
    b.Size = UDim2.new(TAB_W, -2, 1, 0)
    b.Position = UDim2.new(xScale, 2, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Active = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    return b
end
local btnTabBase = mkTabBtn("BtnBase", "基础", 0)
local btnTabMagic = mkTabBtn("BtnMagic", "魔法子弹", TAB_W)
local btnTabRadar = mkTabBtn("BtnRadar", "雷达", TAB_W * 2)

local basePage = Instance.new("Frame", main)
basePage.Size = UDim2.new(1, 0, 1, -LAYOUT[currentLayout].PageTop)
basePage.Position = UDim2.new(0, 0, 0, LAYOUT[currentLayout].PageTop)
basePage.BackgroundTransparency = 1
basePage.Visible = true

local magicPage = Instance.new("Frame", main)
magicPage.Size = UDim2.new(1, 0, 1, -LAYOUT[currentLayout].PageTop)
magicPage.Position = UDim2.new(0, 0, 0, LAYOUT[currentLayout].PageTop)
magicPage.BackgroundTransparency = 1
magicPage.Visible = false

local radarPage = Instance.new("Frame", main)
radarPage.Size = UDim2.new(1, 0, 1, -LAYOUT[currentLayout].PageTop)
radarPage.Position = UDim2.new(0, 0, 0, LAYOUT[currentLayout].PageTop)
radarPage.BackgroundTransparency = 1
radarPage.Visible = false

local C_TAB_ON = Color3.fromRGB(0, 120, 60)
local C_TAB_OFF = Color3.fromRGB(70, 70, 70)
local function switchTab(which)
    currentTab = which
    basePage.Visible = (which == "base")
    magicPage.Visible = (which == "magic")
    radarPage.Visible = (which == "radar")
    local L = LAYOUT[currentLayout]
    local h = getTabHeight()
    main.Size = UDim2.new(0, L.W, 0, h)
    basePage.Size = UDim2.new(1, 0, 1, -L.PageTop)
    magicPage.Size = UDim2.new(1, 0, 1, -L.PageTop)
    radarPage.Size = UDim2.new(1, 0, 1, -L.PageTop)
    btnTabBase.BackgroundColor3 = (which == "base") and C_TAB_ON or C_TAB_OFF
    btnTabMagic.BackgroundColor3 = (which == "magic") and C_TAB_ON or C_TAB_OFF
    btnTabRadar.BackgroundColor3 = (which == "radar") and C_TAB_ON or C_TAB_OFF
end
bindTap(btnTabBase, function() switchTab("base") end)
bindTap(btnTabMagic, function() switchTab("magic") end)
bindTap(btnTabRadar, function() switchTab("radar") end)
switchTab("base")

local regControls = {}
local function reg(g, key)
    regControls[g] = key
    local info = LAYOUT[currentLayout].items[key]
    if info then
        g.Position = info.p
        g.Size = info.s
    end
    return g
end

do
    local dragging, ds, sp = false, nil, nil
    local function pointInFrame(pos, f)
        local ap = f.AbsolutePosition
        local asz = f.AbsoluteSize
        return pos.X >= ap.X and pos.X <= ap.X + asz.X and pos.Y >= ap.Y and pos.Y <= ap.Y + asz.Y
    end
    local function pointInAnyControl(pos)
        for _, d in ipairs(main:GetDescendants()) do
            if (d:IsA("GuiButton") or d:IsA("TextBox")) and d.Visible then
                if pointInFrame(pos, d) then return true end
            end
        end
        return false
    end
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local ut = input.UserInputType
        if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.Touch then return end
        if not gui.Parent then return end
        if not pointInFrame(input.Position, main) then return end
        if pointInAnyControl(input.Position) then return end
        dragging = true
        ds = input.Position
        sp = main.Position
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local ut = input.UserInputType
        if ut ~= Enum.UserInputType.MouseMovement and ut ~= Enum.UserInputType.Touch then return end
        local d = input.Position - ds
        main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end)
    UserInputService.InputEnded:Connect(function(input)
        local ut = input.UserInputType
        if ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

_G._ExamFH = _G._ExamFH or {}
_G._ExamFH.forceOffFn = nil
_G._ExamMB = _G._ExamMB or {}
_G._ExamMB.magicOffFn = nil

local cdLabel = Instance.new("TextLabel", basePage)
cdLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
cdLabel.Text = "滑铲冷却显示关闭"
cdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
cdLabel.Font = Enum.Font.GothamBold
cdLabel.TextSize = 11
cdLabel.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", cdLabel).CornerRadius = UDim.new(0, 4)
reg(cdLabel, "cdLabel")

local function mkCreateToggle(parent)
    return function(text, posSpec, default, callback, sizeSpec)
        local btn = Instance.new("TextButton", parent)
        if type(posSpec) == "string" then
            reg(btn, posSpec)
        else
            btn.Position = posSpec
            btn.Size = sizeSpec or UDim2.new(1, -30, 0, 30)
        end
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Active = true
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        local state = default
        local lastFire = 0
        local function setState(nv)
            if state == nv then return end
            state = nv
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
            callback(state)
        end
        local function fire()
            local now = tick()
            if now - lastFire < 0.3 then return end
            lastFire = now
            setState(not state)
        end
        bindTap(btn, fire)
        return btn, setState
    end
end
local toggleBase = mkCreateToggle(basePage)
local toggleMagic = mkCreateToggle(magicPage)
local toggleRadar = mkCreateToggle(radarPage)

-- ============ 模块 1: 无限体力 ============
do
    local staminaLoop
    local originalStamina = {}
    local INFINITE_STAMINA = 1e9
    local cachedState = nil
    local function getStaminaState()
        if cachedState then
            local char = lp.Character
            local handler = char and char:FindFirstChild("ClientHandler")
            local sm = handler and handler:FindFirstChild("State")
            if sm and cachedState == sm then
                local ok, s = pcall(function() return require(sm) end)
                if ok and type(s) == "table" and s.stamina then return s end
            end
            cachedState = nil
        end
        local char = lp.Character
        if not char then return nil end
        local handler = char:FindFirstChild("ClientHandler")
        if not handler then return nil end
        local stateModule = handler:FindFirstChild("State")
        if not stateModule then return nil end
        local ok, s = pcall(function() return require(stateModule) end)
        if ok and type(s) == "table" and s.stamina then
            cachedState = stateModule
            return s
        end
        return nil
    end
    local function saveOrig(s)
        if next(originalStamina) ~= nil then return end
        originalStamina = {
            current = s.stamina.current, fullRegen = s.stamina.fullRegen,
            regenDelay = s.stamina.regenDelay, max = s.stamina.max,
            maxStamina = s.stamina.maxStamina, maximum = s.stamina.maximum,
        }
        _G._ExamStaminaBackup = originalStamina
    end
    local function applyInf(s)
        s.stamina.current = INFINITE_STAMINA
        s.stamina.fullRegen = false
        s.stamina.regenDelay = 0
        if s.stamina.max ~= nil then s.stamina.max = INFINITE_STAMINA end
        if s.stamina.maxStamina ~= nil then s.stamina.maxStamina = INFINITE_STAMINA end
        if s.stamina.maximum ~= nil then s.stamina.maximum = INFINITE_STAMINA end
    end
    local function restoreOrig()
        local s = getStaminaState()
        local backup = originalStamina
        if next(backup) == nil and _G._ExamStaminaBackup then backup = _G._ExamStaminaBackup end
        if not s or next(backup) == nil then
            originalStamina = {}
            _G._ExamStaminaBackup = nil
            return
        end
        if backup.current ~= nil then s.stamina.current = backup.current end
        if backup.fullRegen ~= nil then s.stamina.fullRegen = backup.fullRegen end
        if backup.regenDelay ~= nil then s.stamina.regenDelay = backup.regenDelay end
        if backup.max ~= nil then s.stamina.max = backup.max end
        if backup.maxStamina ~= nil then s.stamina.maxStamina = backup.maxStamina end
        if backup.maximum ~= nil then s.stamina.maximum = backup.maximum end
        originalStamina = {}
        _G._ExamStaminaBackup = nil
    end
    local function setupLoop()
        if staminaLoop then pcall(function() staminaLoop:Disconnect() end); staminaLoop = nil end
        if not infStaminaEnabled then return end
        staminaLoop = spawn(function()
            while infStaminaEnabled and gui.Parent do
                local s = getStaminaState()
                if s then saveOrig(s); applyInf(s) end
                wait(0.5)
            end
            staminaLoop = nil
        end)
    end
    toggleBase("无限体力", "stamina", false, function(v)
        infStaminaEnabled = v
        if v then
            originalStamina = {}
            cachedState = nil
            setupLoop()
        else
            if staminaLoop then pcall(function() staminaLoop:Disconnect() end); staminaLoop = nil end
            restoreOrig()
        end
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        cachedState = nil
        if infStaminaEnabled then
            originalStamina = {}
            setupLoop()
        end
    end)
    table.insert(cleanupFns, function()
        infStaminaEnabled = false
        if staminaLoop then pcall(function() staminaLoop:Disconnect() end) end
        restoreOrig()
    end)
end

-- ============ 模块 2: AI ESP ============
do
    local espConnections = {}
    local ESP_HL_NEW = "_ExamESP_HL"
    local ESP_HB_NEW = "_ExamESP_HB"
    local BIG = {
        ["SIN"]=true, ["Chimera"]=true, ["Gilbert"]=true, ["Mikhail"]=true,
        ["Leaper"]=true,
    }
    local MINI = { ["RIF Miniboss"]=true, ["Dave"]=true, ["CombatEngineer"]=true, ["Vorax"]=true }
    local C_NORMAL = Color3.fromRGB(255, 0, 0)
    local C_MINI = Color3.fromRGB(255, 140, 0)
    local C_BIG = Color3.fromRGB(170, 0, 255)
    local C_BTR = Color3.fromRGB(170, 0, 255)
    local C_DRONE = Color3.fromRGB(255, 80, 200)
    local showESPName = true
    local showESPHealth = true

    local function isAICharacter(m)
        if not m or not m:IsA("Model") then return false end
        if Players:GetPlayerFromCharacter(m) then return false end
        if m.Name == "Leaper" then return true end
        if m:FindFirstChild("AI")
           or m:FindFirstChild("GrabField")
           or m:FindFirstChild("AmbushScenery")
           or m:FindFirstChild("CharacterTeam") then
            return true
        end
        return false
    end

    local function isOurESPNode(c)
        if not c then return false end
        local n = c.Name
        return (c:IsA("Highlight") and (n == "AI_Highlight" or n == ESP_HL_NEW))
            or (c:IsA("BillboardGui") and (n == "AI_HealthUI" or n == ESP_HB_NEW))
    end
    local function classify(m)
        local n = m.Name
        if BIG[n] then return C_BIG, "BOSS" end
        if MINI[n] then return C_MINI, "Miniboss" end
        return C_NORMAL, "AI"
    end
    local function tagToPre(tag)
        if tag == "BOSS" then return "[BOSS] "
        elseif tag == "Miniboss" then return "[Miniboss] " end
        return ""
    end
    local function genText(model, hum, pre)
        local parts = {}
        if showESPName then table.insert(parts, model.Name) end
        if showESPHealth and hum then
            table.insert(parts, string.format("%d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth)))
        end
        if #parts == 0 then return pre ~= "" and pre:sub(1, -2) or "" end
        return pre .. table.concat(parts, " | ")
    end
    local function refreshAllLabels()
        local function refreshIn(obj)
            if not obj then return end
            local bb = obj:FindFirstChild(ESP_HB_NEW)
            if not bb then return end
            local tl = bb:FindFirstChildOfClass("TextLabel")
            if not tl then return end
            local _, tag = classify(obj)
            local hum = obj:FindFirstChildOfClass("Humanoid")
            tl.Text = genText(obj, hum, tagToPre(tag))
        end
        for _, folderName in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then for _, c in ipairs(folder:GetChildren()) do refreshIn(c) end end
        end
        local map = Workspace:FindFirstChild("Map")
        local btr = map and map:FindFirstChild("BTR-82 (BOSS)")
        if btr then refreshIn(btr) end
        local drone = Workspace:FindFirstChild("BTRDrone")
        if drone then refreshIn(drone) end
    end
    local function cleanAllESP()
        local function cleanIn(obj)
            if not obj then return end
            local kill = {}
            for _, c in ipairs(obj:GetChildren()) do
                if isOurESPNode(c) then table.insert(kill, c) end
            end
            for _, c in ipairs(kill) do pcall(function() c:Destroy() end) end
        end
        local map = Workspace:FindFirstChild("Map")
        if map then
            local btr = map:FindFirstChild("BTR-82 (BOSS)")
            if btr then cleanIn(btr) end
        end
        cleanIn(Workspace:FindFirstChild("BTRDrone"))
        for _, folderName in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then for _, c in ipairs(folder:GetChildren()) do cleanIn(c) end end
        end
    end
    local function clearESP()
        for _, conn in ipairs(espConnections) do pcall(function() conn:Disconnect() end) end
        espConnections = {}
        cleanAllESP()
    end
    local function tryHealth(m)
        local hum = m:FindFirstChildOfClass("Humanoid")
        if hum then return hum.Health, hum.MaxHealth end
        return nil, nil
    end
    local function highlightAI(model, color, tag)
        if not espEnabled then return end
        if model:FindFirstChild(ESP_HL_NEW) then return end
        local hl = Instance.new("Highlight")
        hl.Name = ESP_HL_NEW; hl.Adornee = model; hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.OutlineTransparency = 1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = model
        local bb = Instance.new("BillboardGui")
        bb.Name = ESP_HB_NEW; bb.Adornee = model
        bb.Size = UDim2.new(0, 220, 0, 25)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop = true; bb.MaxDistance = 300; bb.Parent = model
        local tl = Instance.new("TextLabel")
        tl.Parent = bb; tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1; tl.TextColor3 = color
        tl.TextStrokeTransparency = 0; tl.TextScaled = true
        tl.Font = Enum.Font.SourceSansBold
        local pre = tagToPre(tag)
        spawn(function()
            while model and model.Parent and espEnabled and model:FindFirstChild(ESP_HL_NEW) do
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then
                    if hum.Health <= 0 then
                        if hl then hl:Destroy() end
                        if bb then bb:Destroy() end
                        break
                    end
                    tl.Text = genText(model, hum, pre)
                end
                wait(0.3)
            end
        end)
    end
    local function getBTRModel()
        local map = Workspace:FindFirstChild("Map")
        return map and map:FindFirstChild("BTR-82 (BOSS)")
    end
    local function getBTRHealth(btr)
        if not btr then return nil end
        local hp = btr:GetAttribute("Health") or btr:GetAttribute("HP")
        if hp then return hp end
        local r = btr:FindFirstChild("BTRRoot")
        if r then
            hp = r:GetAttribute("Health") or r:GetAttribute("HP")
            if hp then return hp end
        end
        return nil
    end
    local function removeBTR(btr)
        if not btr then return end
        for _, ch in ipairs(btr:GetChildren()) do
            if isOurESPNode(ch) then pcall(function() ch:Destroy() end) end
        end
    end
    local function highlightBTR(btrModel)
        if not espEnabled then return end
        local hp = getBTRHealth(btrModel)
        if hp and hp <= 0 then removeBTR(btrModel); return end
        if btrModel:FindFirstChild(ESP_HL_NEW) then return end
        local hl = Instance.new("Highlight")
        hl.Name = ESP_HL_NEW; hl.Adornee = btrModel; hl.FillColor = C_BTR
        hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.OutlineTransparency = 1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = btrModel
        local bb = Instance.new("BillboardGui")
        bb.Name = ESP_HB_NEW; bb.Adornee = btrModel
        bb.Size = UDim2.new(0, 300, 0, 30)
        bb.StudsOffset = Vector3.new(0, 12, 0)
        bb.AlwaysOnTop = true; bb.MaxDistance = 600; bb.Parent = btrModel
        local tl = Instance.new("TextLabel")
        tl.Parent = bb; tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1; tl.TextColor3 = C_BTR
        tl.TextStrokeTransparency = 0; tl.TextScaled = true
        tl.Font = Enum.Font.SourceSansBold
        local function btrText(cur)
            local parts = {}
            if showESPName then table.insert(parts, "BTR-82") end
            if showESPHealth and cur then table.insert(parts, tostring(math.floor(cur))) end
            if #parts == 0 then return "[BOSS]" end
            return "[BOSS] " .. table.concat(parts, " | ")
        end
        tl.Text = btrText(hp)
        spawn(function()
            while btrModel and btrModel.Parent and espEnabled and btrModel:FindFirstChild(ESP_HL_NEW) do
                local cur = getBTRHealth(btrModel)
                if cur and cur <= 0 then removeBTR(btrModel); break end
                tl.Text = btrText(cur)
                wait(0.3)
            end
        end)
    end
    local function highlightDrone(drone)
        if not espEnabled then return end
        if drone:FindFirstChild(ESP_HL_NEW) then return end
        local part = drone:FindFirstChild("DroneHitbox") or drone.PrimaryPart
        if not part then
            for _, c in ipairs(drone:GetDescendants()) do
                if c:IsA("BasePart") then part = c; break end
            end
        end
        if not part then return end
        local hl = Instance.new("Highlight")
        hl.Name = ESP_HL_NEW; hl.Adornee = drone; hl.FillColor = C_DRONE
        hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.OutlineTransparency = 1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = drone
        local bb = Instance.new("BillboardGui")
        bb.Name = ESP_HB_NEW; bb.Adornee = drone
        bb.Size = UDim2.new(0, 200, 0, 25)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop = true; bb.MaxDistance = 400; bb.Parent = drone
        local tl = Instance.new("TextLabel")
        tl.Parent = bb; tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1; tl.TextColor3 = C_DRONE
        tl.TextStrokeTransparency = 0; tl.TextScaled = true
        tl.Font = Enum.Font.SourceSansBold
        local function droneText(cur, max)
            local parts = {}
            if showESPName then table.insert(parts, "无人机") end
            if showESPHealth then
                if cur and max then
                    table.insert(parts, string.format("%d / %d", math.floor(cur), math.floor(max)))
                elseif cur then table.insert(parts, tostring(math.floor(cur))) end
            end
            if #parts == 0 then return "[无人机]" end
            return "[无人机] " .. table.concat(parts, " | ")
        end
        tl.Text = droneText(tryHealth(drone))
        spawn(function()
            while drone and drone.Parent and espEnabled and drone:FindFirstChild(ESP_HL_NEW) do
                local cur, max = tryHealth(drone)
                tl.Text = droneText(cur, max)
                wait(0.3)
            end
        end)
    end
    local function setupESP()
        clearESP()
        if not espEnabled then return end
        for _, folderName in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                for _, v in ipairs(folder:GetChildren()) do
                    if isAICharacter(v) then
                        local c, t = classify(v)
                        highlightAI(v, c, t)
                    end
                end
                table.insert(espConnections, folder.ChildAdded:Connect(function(v)
                    wait(0.1)
                    if espEnabled and isAICharacter(v) then
                        local c, t = classify(v)
                        highlightAI(v, c, t)
                    end
                end))
            end
        end
        local btr = getBTRModel()
        if btr then highlightBTR(btr) end
        local map = Workspace:FindFirstChild("Map")
        if map then
            table.insert(espConnections, map.ChildAdded:Connect(function(c)
                if espEnabled and c.Name == "BTR-82 (BOSS)" then
                    wait(0.5); highlightBTR(c)
                end
            end))
            table.insert(espConnections, map.ChildRemoved:Connect(function(c)
                if espEnabled and c.Name == "BTR-82 (BOSS)" then
                    spawn(function()
                        wait(1.5)
                        if espEnabled then
                            local nb = getBTRModel()
                            if nb then highlightBTR(nb) end
                        end
                    end)
                end
            end))
        end
        local drone = Workspace:FindFirstChild("BTRDrone")
        if drone then highlightDrone(drone) end
        table.insert(espConnections, Workspace.ChildAdded:Connect(function(c)
            if espEnabled and c.Name == "BTRDrone" then
                wait(0.3); highlightDrone(c)
            end
        end))
        spawn(function()
            local lastHP = nil
            local lastRefresh = 0
            while espEnabled do
                wait(0.5)
                if not espEnabled then break end
                local b = getBTRModel()
                if b then
                    local hp = getBTRHealth(b)
                    local need = false
                    if hp and hp <= 0 then
                        removeBTR(b); lastHP = hp
                    else
                        if hp and lastHP and (lastHP - hp) > 30 then need = true end
                        if not b:FindFirstChild(ESP_HL_NEW) then need = true end
                        if need and tick() - lastRefresh > 1 then
                            lastRefresh = tick(); highlightBTR(b)
                        end
                        if hp then lastHP = hp end
                    end
                else lastHP = nil end
            end
        end)
    end
    toggleBase("AI ESP（高亮常开）", "esp", false, function(v)
        espEnabled = v
        setupESP()
    end)
    local nameBtn = Instance.new("TextButton", basePage)
    nameBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    nameBtn.Text = "显示名称: 开"
    nameBtn.TextColor3 = Color3.new(1, 1, 1)
    nameBtn.Font = Enum.Font.Gotham; nameBtn.TextSize = 11; nameBtn.Active = true
    Instance.new("UICorner", nameBtn).CornerRadius = UDim.new(0, 5)
    reg(nameBtn, "nameBtn")
    local hpBtn = Instance.new("TextButton", basePage)
    hpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    hpBtn.Text = "显示血量: 开"
    hpBtn.TextColor3 = Color3.new(1, 1, 1)
    hpBtn.Font = Enum.Font.Gotham; hpBtn.TextSize = 11; hpBtn.Active = true
    Instance.new("UICorner", hpBtn).CornerRadius = UDim.new(0, 5)
    reg(hpBtn, "hpBtn")
    bindTap(nameBtn, function()
        showESPName = not showESPName
        nameBtn.Text = showESPName and "显示名称: 开" or "显示名称: 关"
        nameBtn.BackgroundColor3 = showESPName and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        if espEnabled then refreshAllLabels() end
    end)
    bindTap(hpBtn, function()
        showESPHealth = not showESPHealth
        hpBtn.Text = showESPHealth and "显示血量: 开" or "显示血量: 关"
        hpBtn.BackgroundColor3 = showESPHealth and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        if espEnabled then refreshAllLabels() end
    end)
    spawn(function()
        while gui.Parent do
            wait(8)
            if not espEnabled then cleanAllESP() end
        end
    end)
    table.insert(cleanupFns, function() clearESP() end)
end

-- ============ 模块 3: 头部 Hitbox ============
do
    local hitboxConnections = {}
    local hitboxModified = {}
    local function restoreHeadHitbox()
        for p, orig in pairs(hitboxModified) do
            pcall(function()
                p.Size = orig.Size; p.CanCollide = orig.CanCollide; p.Transparency = orig.Transparency
            end)
        end
        table.clear(hitboxModified)
    end
    local function isDead(model)
        if not model then return true end
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum then return true end
        if hum.Health <= 0 then return true end
        return false
    end
    local function restoreOne(p)
        local orig = hitboxModified[p]
        if not orig then return end
        pcall(function()
            p.Size = orig.Size; p.CanCollide = orig.CanCollide; p.Transparency = orig.Transparency
        end)
        hitboxModified[p] = nil
    end
    local function applyHead(part)
        if not headHitboxEnabled then return end
        if not part or not part:IsA("BasePart") then return end
        if part.Name ~= "Head" then return end
        local model = part.Parent
        if not model or not model:IsA("Model") then return end
        if Players:GetPlayerFromCharacter(model) then return end
        if isDead(model) then
            if hitboxModified[part] then restoreOne(part) end
            return
        end
        if not hitboxModified[part] then
            hitboxModified[part] = { Size = part.Size, CanCollide = part.CanCollide, Transparency = part.Transparency }
        end
        pcall(function()
            part.Size = Vector3.new(headSize, headSize, headSize)
            part.CanCollide = false; part.Transparency = 0.5
        end)
    end
    local function setup()
        for _, conn in ipairs(hitboxConnections) do pcall(function() conn:Disconnect() end) end
        hitboxConnections = {}
        if not headHitboxEnabled then restoreHeadHitbox(); return end
        for _, desc in ipairs(Workspace:GetDescendants()) do applyHead(desc) end
        table.insert(hitboxConnections, Workspace.DescendantAdded:Connect(applyHead))
        spawn(function()
            while headHitboxEnabled and gui.Parent do
                for p in pairs(hitboxModified) do
                    if not p or not p.Parent then hitboxModified[p] = nil
                    else if isDead(p.Parent) then restoreOne(p) end end
                end
                wait(0.5)
            end
        end)
    end
    toggleBase("头部Hitbox扩大", "headHitbox", false, function(v)
        headHitboxEnabled = v
        setup()
    end)
    local sizeLabel = Instance.new("TextLabel", basePage)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Text = "头部:"
    sizeLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    sizeLabel.Font = Enum.Font.Gotham; sizeLabel.TextSize = 11
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    reg(sizeLabel, "headSizeLabel")
    local sizeInput = Instance.new("TextBox", basePage)
    sizeInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sizeInput.TextColor3 = Color3.new(1, 1, 1)
    sizeInput.Text = tostring(headSize)
    sizeInput.Font = Enum.Font.Gotham; sizeInput.TextSize = 11; sizeInput.BorderSizePixel = 0
    Instance.new("UICorner", sizeInput).CornerRadius = UDim.new(0, 4)
    reg(sizeInput, "headSizeInput")
    sizeInput.FocusLost:Connect(function()
        local val = tonumber(sizeInput.Text)
        if val and val >= 1 and val <= 20 then
            headSize = val; sizeInput.Text = tostring(headSize)
            if headHitboxEnabled then setup() end
        else sizeInput.Text = tostring(headSize) end
    end)
    table.insert(cleanupFns, function()
        for _, conn in ipairs(hitboxConnections) do pcall(function() conn:Disconnect() end) end
        restoreHeadHitbox()
    end)
end

-- ============ 模块 4: 及时交互 ============
do
    local promptConn
    local function setup()
        if promptConn then promptConn:Disconnect(); promptConn = nil end
        if not autoInteractEnabled then return end
        promptConn = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
            fireproximityprompt(prompt)
        end)
    end
    toggleBase("及时交互", "autoInteract", false, function(v)
        autoInteractEnabled = v
        setup()
    end)
    table.insert(cleanupFns, function()
        if promptConn then promptConn:Disconnect() end
    end)
end

-- ============ 模块 5: 无条件重置 ============
do
    local resetLoop
    local function setup()
        if resetLoop then resetLoop:Disconnect(); resetLoop = nil end
        if not forceResetEnabled then
            pcall(function() StarterGui:SetCore("ResetButtonCallback", false) end)
            return
        end
        resetLoop = RunService.Heartbeat:Connect(function()
            pcall(function() StarterGui:SetCore("ResetButtonCallback", true) end)
        end)
    end
    toggleBase("无条件重置", "forceReset", false, function(v)
        forceResetEnabled = v
        setup()
    end)
    table.insert(cleanupFns, function()
        if resetLoop then resetLoop:Disconnect() end
        pcall(function() StarterGui:SetCore("ResetButtonCallback", false) end)
    end)
end

-- ============ 模块 6: 滑铲距离修改 ============
do
    local badgeHooked = false
    local blockedHooked = false
    local slideSpeedLoop = nil
    local slideSlidingConn = nil
    local cooldownEndTime = 0
    local needsRefresh = false
    local SLIDE_COOLDOWN = 9
    local oldUserHasBadgeAsync = BadgeService.UserHasBadgeAsync
    local function hookBadge()
        if badgeHooked then return true end
        if not hookfunction then return false end
        local ok = pcall(function()
            hookfunction(BadgeService.UserHasBadgeAsync, function(self, uid, bid)
                if bid == 3938313051889761 then return true end
                return oldUserHasBadgeAsync(self, uid, bid)
            end)
        end)
        badgeHooked = ok
        return ok
    end
    local function hookIsBlocked()
        if blockedHooked then return true end
        if not (getgc and hookfunction) then return false end
        local count = 0
        for _, f in pairs(getgc(true)) do
            if type(f) == "function" then
                pcall(function()
                    local info = getinfo(f)
                    if info.name == "isSlideDirectionBlocked"
                       and (info.source or ""):find("MovementController") then
                        hookfunction(f, function() return false end)
                        count = count + 1
                    end
                end)
            end
        end
        blockedHooked = count > 0
        return blockedHooked
    end
    local function boostSlide(hum)
        spawn(function()
            wait(0.03)
            local char = hum.Parent
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local av = hrp:FindFirstChild("ActionVelocity")
            if av and av:IsA("LinearVelocity") then
                pcall(function()
                    av.VectorVelocity = av.VectorVelocity * slideDistanceMult
                    av.MaxForce = 1e9
                end)
            end
        end)
    end
    local function bindSlide(hum)
        if slideSlidingConn then slideSlidingConn:Disconnect(); slideSlidingConn = nil end
        slideSlidingConn = hum:GetAttributeChangedSignal("sliding"):Connect(function()
            if hum:GetAttribute("sliding") == true then
                boostSlide(hum); needsRefresh = false
            else cooldownEndTime = tick() + SLIDE_COOLDOWN end
        end)
    end
    local function setup()
        if slideSpeedLoop then slideSpeedLoop:Disconnect(); slideSpeedLoop = nil end
        if slideSlidingConn then slideSlidingConn:Disconnect(); slideSlidingConn = nil end
        if not slideEnabled then return end
        hookBadge(); hookIsBlocked(); needsRefresh = true
        slideSpeedLoop = RunService.Heartbeat:Connect(function()
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if hum.MoveDirection.Magnitude > 0.1 and hum.WalkSpeed < 18.5 and hum.WalkSpeed > 0 then
                hum.WalkSpeed = 18.5
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and hum:GetAttribute("sliding") == true then
                local av = hrp:FindFirstChild("ActionVelocity")
                if not av then hum:SetAttribute("sliding", false) end
            end
        end)
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then bindSlide(hum) end
        end
    end
    toggleBase("滑铲距离修改", "slide", false, function(v)
        slideEnabled = v
        setup()
    end)
    lp.CharacterAdded:Connect(function()
        wait(2)
        if slideEnabled then setup() end
    end)
    spawn(function()
        while gui.Parent do
            wait(0.2)
            if slideEnabled then
                if needsRefresh then
                    cdLabel.Text = "请滑铲一次刷新状态"
                    cdLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                else
                    local now = tick()
                    if now < cooldownEndTime then
                        cdLabel.Text = string.format("滑铲冷却: %.1f 秒", cooldownEndTime - now)
                        cdLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                    else
                        cdLabel.Text = "滑铲冷却: 就绪"
                        cdLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    end
                end
            else
                cdLabel.Text = "滑铲冷却显示关闭"
                cdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end)
    local slideDistLabel = Instance.new("TextLabel", basePage)
    slideDistLabel.BackgroundTransparency = 1
    slideDistLabel.Text = "滑铲距离倍率:"
    slideDistLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    slideDistLabel.Font = Enum.Font.Gotham; slideDistLabel.TextSize = 11
    slideDistLabel.TextXAlignment = Enum.TextXAlignment.Left
    reg(slideDistLabel, "slideDistLabel")
    local slideDistInput = Instance.new("TextBox", basePage)
    slideDistInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slideDistInput.TextColor3 = Color3.new(1, 1, 1)
    slideDistInput.Text = tostring(slideDistanceMult)
    slideDistInput.Font = Enum.Font.Gotham; slideDistInput.TextSize = 11; slideDistInput.BorderSizePixel = 0
    Instance.new("UICorner", slideDistInput).CornerRadius = UDim.new(0, 4)
    reg(slideDistInput, "slideDistInput")
    slideDistInput.FocusLost:Connect(function()
        local val = tonumber(slideDistInput.Text)
        if val and val >= 1 and val <= 10 then
            slideDistanceMult = val; slideDistInput.Text = tostring(slideDistanceMult)
        else slideDistInput.Text = tostring(slideDistanceMult) end
    end)
    table.insert(cleanupFns, function()
        if slideSpeedLoop then slideSpeedLoop:Disconnect() end
        if slideSlidingConn then slideSlidingConn:Disconnect() end
    end)
end

-- ============ 模块 6.5: 滑铲变向 ============
do
    local steerLoop = nil
    local function computeDir(hum, cam)
        if slideSteerMode == "camera" then
            if not cam then return nil end
            local dir = cam.CFrame.LookVector
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude < 0.1 then return nil end
            return dir.Unit
        else
            local md = hum.MoveDirection
            md = Vector3.new(md.X, 0, md.Z)
            if md.Magnitude < 0.1 then
                if cam then
                    local dir = cam.CFrame.LookVector
                    dir = Vector3.new(dir.X, 0, dir.Z)
                    if dir.Magnitude > 0.1 then return dir.Unit end
                end
                return nil
            end
            return md.Unit
        end
    end
    local function setup()
        if steerLoop then steerLoop:Disconnect(); steerLoop = nil end
        if not slideSteerEnabled then return end
        steerLoop = RunService.Heartbeat:Connect(function()
            if not slideSteerEnabled then return end
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if hum:GetAttribute("sliding") ~= true then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local av = hrp:FindFirstChild("ActionVelocity")
            if not av then return end
            local isLinear = av:IsA("LinearVelocity")
            local isVector = av:IsA("VectorForce")
            if not (isLinear or isVector) then return end
            local curVel = isLinear and av.VectorVelocity or av.Force
            local mag = curVel.Magnitude
            if mag < 0.1 then return end
            local dir = computeDir(hum, workspace.CurrentCamera)
            if not dir then return end
            local newVel = dir * mag
            if isLinear then
                pcall(function() av.VectorVelocity = newVel end)
            else
                pcall(function() av.Force = newVel end)
            end
        end)
    end
    toggleBase("滑铲变向（视角朝哪滑哪）", "slideSteer", false, function(v)
        slideSteerEnabled = v
        setup()
    end)
    local modeBtn = Instance.new("TextButton", basePage)
    modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    modeBtn.TextColor3 = Color3.new(1, 1, 1)
    modeBtn.Font = Enum.Font.GothamBold
    modeBtn.TextSize = 11
    modeBtn.Active = true
    Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 5)
    reg(modeBtn, "slideSteerMode")
    local function refreshModeText()
        modeBtn.Text = (slideSteerMode == "camera") and "变向模式: 视角控制" or "变向模式: 移动控制"
        modeBtn.BackgroundColor3 = (slideSteerMode == "camera")
            and Color3.fromRGB(60, 60, 100)
            or Color3.fromRGB(150, 80, 60)
    end
    bindTap(modeBtn, function()
        slideSteerMode = (slideSteerMode == "camera") and "move" or "camera"
        refreshModeText()
    end)
    refreshModeText()
    lp.CharacterAdded:Connect(function()
        wait(2)
        if slideSteerEnabled then setup() end
    end)
    table.insert(cleanupFns, function()
        if steerLoop then pcall(function() steerLoop:Disconnect() end) end
    end)
end

-- ============ 模块 7: 无限电量夜视仪 ============
do
    local nvgBadgeHooked = false
    local nvgBadgeOriginal = nil
    local function hookBadges()
        if nvgBadgeHooked then return end
        if not hookfunction then return end
        nvgBadgeOriginal = BadgeService.UserHasBadgeAsync
        pcall(function()
            hookfunction(BadgeService.UserHasBadgeAsync, function(self, uid, bid)
                if bid == 3938313051889761 or bid == 3801395471806771 then return true end
                return nvgBadgeOriginal(self, uid, bid)
            end)
        end)
        nvgBadgeHooked = true
    end
    local function makeCloaker()
        local char = lp.Character
        if not char then return end
        local existing = char:FindFirstChild("IsCloaker")
        if existing and existing:IsA("BoolValue") then
            if not existing.Value then existing.Value = true end
        else
            local bv = Instance.new("BoolValue")
            bv.Name = "IsCloaker"; bv.Value = true; bv.Parent = char
            _G._InfNVG_AddedCloaker = true
        end
    end
    local function bindBattery()
        if _G._InfNVG_TextSignalConn then return end
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return end
        local hud = pg:FindFirstChild("NightVisionHUD")
        if not hud then return end
        local container = hud:FindFirstChild("Container")
        if not container then return end
        local status = container:FindFirstChild("Status")
        if not status then return end
        local battery = status:FindFirstChild("Battery")
        if not battery then return end
        local percent = battery:FindFirstChild("Percentage")
        if percent and percent:IsA("TextLabel") then
            if not _G._InfNVG_OrigPercentText then _G._InfNVG_OrigPercentText = percent.Text end
            percent.Text = "无限"
            _G._InfNVG_TextSignalConn = percent:GetPropertyChangedSignal("Text"):Connect(function()
                if percent.Text ~= "无限" then percent.Text = "无限" end
            end)
        end
        local bar = battery:FindFirstChild("Bar")
        if bar and bar:IsA("Frame") and not _G._InfNVG_BarSignalConn then
            local barRef = bar
            spawn(function()
                wait(0.3)
                if not nvgEnabled then return end
                if _G._InfNVG_BarSignalConn then return end
                _G._InfNVG_OrigBarSize = barRef.Size
                barRef.Size = _G._InfNVG_OrigBarSize
                _G._InfNVG_BarSignalConn = barRef:GetPropertyChangedSignal("Size"):Connect(function()
                    if barRef.Size ~= _G._InfNVG_OrigBarSize then barRef.Size = _G._InfNVG_OrigBarSize end
                end)
            end)
        end
    end
    local function unbindBattery()
        if _G._InfNVG_TextSignalConn then _G._InfNVG_TextSignalConn:Disconnect(); _G._InfNVG_TextSignalConn = nil end
        if _G._InfNVG_BarSignalConn then _G._InfNVG_BarSignalConn:Disconnect(); _G._InfNVG_BarSignalConn = nil end
    end
    local function startLoop()
        if _G._InfNVG_Loop then pcall(function() _G._InfNVG_Loop:Disconnect() end); _G._InfNVG_Loop = nil end
        _G._InfNVG_Loop = spawn(function()
            while nvgEnabled and gui.Parent do
                makeCloaker()
                if not _G._InfNVG_TextSignalConn then bindBattery() end
                wait(0.3)
            end
        end)
    end
    local function stopRestore()
        if _G._InfNVG_Loop then pcall(function() _G._InfNVG_Loop:Disconnect() end); _G._InfNVG_Loop = nil end
        unbindBattery()
        local char = lp.Character
        if char and _G._InfNVG_AddedCloaker then
            local c = char:FindFirstChild("IsCloaker")
            if c then c:Destroy() end
        end
        local pg = lp:FindFirstChild("PlayerGui")
        if pg then
            local hud = pg:FindFirstChild("NightVisionHUD")
            if hud then
                local container = hud:FindFirstChild("Container")
                if container then
                    local status = container:FindFirstChild("Status")
                    if status then
                        local battery = status:FindFirstChild("Battery")
                        if battery then
                            local percent = battery:FindFirstChild("Percentage")
                            if percent and percent:IsA("TextLabel") and _G._InfNVG_OrigPercentText then
                                percent.Text = _G._InfNVG_OrigPercentText
                            end
                            local bar = battery:FindFirstChild("Bar")
                            if bar and bar:IsA("Frame") and _G._InfNVG_OrigBarSize then
                                bar.Size = _G._InfNVG_OrigBarSize
                            end
                        end
                    end
                end
            end
        end
        _G._InfNVG_AddedCloaker = nil
        _G._InfNVG_OrigPercentText = nil
        _G._InfNVG_OrigBarSize = nil
    end
    local function setup()
        if not nvgEnabled then stopRestore(); return end
        hookBadges(); bindBattery(); makeCloaker(); startLoop()
    end
    toggleBase("无限电量夜视仪", "nvg", false, function(v)
        nvgEnabled = v
        setup()
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        if nvgEnabled then
            unbindBattery()
            _G._InfNVG_OrigPercentText = nil
            _G._InfNVG_OrigBarSize = nil
            setup()
        end
    end)
    table.insert(cleanupFns, function()
        stopRestore()
        if nvgBadgeHooked and nvgBadgeOriginal and hookfunction then
            pcall(function() hookfunction(BadgeService.UserHasBadgeAsync, nvgBadgeOriginal) end)
        end
    end)
end

-- ============ 模块 8: 免疫象脚 + 致死区 ============
do
    local keywords = {"elephant","lookatme","playerdiedbylooking","diedbylooking"}
    local function match(name)
        local lower = name:lower()
        for _, kw in ipairs(keywords) do
            if lower:find(kw, 1, true) then return true end
        end
        return false
    end
    local disabledScripts = {}
    local function disableScripts()
        local char = lp.Character
        if not char then return 0 end
        local count = 0
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BaseScript") or d:IsA("LocalScript") or d:IsA("Script") then
                if match(d.Name) and not d.Disabled then
                    if disabledScripts[d] == nil then
                        disabledScripts[d] = false
                    end
                    local ok = pcall(function() d.Disabled = true end)
                    if ok then count = count + 1 end
                end
            end
        end
        _G._ElephantImmune_DisabledScripts = disabledScripts
        return count
    end
    local function restoreScripts()
        local n = 0
        for s, orig in pairs(disabledScripts) do
            if s and s.Parent then
                pcall(function() s.Disabled = orig end)
                n = n + 1
            end
        end
        disabledScripts = {}
        _G._ElephantImmune_DisabledScripts = nil
        return n
    end
    local killParts = {}
    local killPartBackup = {}
    local function killPartRestore()
        for kp, orig in pairs(killPartBackup) do
            if kp and kp.Parent then
                pcall(function()
                    kp.Size = orig.Size
                    kp.CFrame = orig.CFrame
                    kp.CanTouch = orig.CanTouch
                    kp.CanCollide = orig.CanCollide
                end)
            end
        end
        killPartBackup = {}
        killParts = {}
        _G._KillPartBackup = nil
    end
    local function neutralizeOne(kp)
        if not kp or not kp.Parent then return end
        if not killPartBackup[kp] then
            killPartBackup[kp] = {
                Size = kp.Size, CFrame = kp.CFrame,
                CanTouch = kp.CanTouch, CanCollide = kp.CanCollide,
            }
        end
        pcall(function()
            kp.Size = Vector3.new(0.001, 0.001, 0.001)
            kp.CFrame = CFrame.new(99999, 99999, 99999)
            kp.CanTouch = false
            kp.CanCollide = false
        end)
    end
    local function killPartFullScan()
        killParts = {}
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.Name == "KillPart" then
                table.insert(killParts, d)
                neutralizeOne(d)
            end
        end
        _G._KillPartBackup = killPartBackup
    end
    local killPartScanLoop = nil
    local function startKillPartScan()
        if killPartScanLoop then killPartScanLoop = nil end
        killPartScanLoop = spawn(function()
            while elephantImmuneEnabled and gui.Parent do
                wait(2)
                if not elephantImmuneEnabled then break end
                local function scanOne(inst)
                    if inst:IsA("BasePart") and inst.Name == "KillPart" then
                        if not killPartBackup[inst] then
                            table.insert(killParts, inst)
                            neutralizeOne(inst)
                        end
                    end
                end
                for _, c in ipairs(Workspace:GetChildren()) do
                    scanOne(c)
                    for _, cc in ipairs(c:GetChildren()) do scanOne(cc) end
                end
            end
            killPartScanLoop = nil
        end)
    end
    local elephantLoop = nil
    local function startElephantLoop()
        if elephantLoop then pcall(function() elephantLoop:Disconnect() end); elephantLoop = nil end
        if not elephantImmuneEnabled then return end
        elephantLoop = RunService.Heartbeat:Connect(function()
            if not elephantImmuneEnabled then return end
            disableScripts()
        end)
    end
    local function setup()
        if elephantLoop then pcall(function() elephantLoop:Disconnect() end); elephantLoop = nil end
        if killPartScanLoop then killPartScanLoop = nil end
        if not elephantImmuneEnabled then
            killPartRestore()
            restoreScripts()
            return
        end
        disableScripts()
        killPartFullScan()
        startKillPartScan()
        startElephantLoop()
    end
    toggleBase("免疫象脚 + 致死区", "elephantImmune", false, function(v)
        elephantImmuneEnabled = v
        setup()
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        disabledScripts = {}
        _G._ElephantImmune_DisabledScripts = nil
        if elephantImmuneEnabled then setup() end
    end)
    table.insert(cleanupFns, function()
        elephantImmuneEnabled = false
        if elephantLoop then elephantLoop:Disconnect() end
        if killPartScanLoop then killPartScanLoop = nil end
        killPartRestore()
        restoreScripts()
    end)
end
-- ============ 模块 11: 去除枪口遮挡 ============
do
    local muzzleHbConn = nil
    local muzzleDisabledParts = {}
    local lastTool = nil
    local watchConn = nil
    local function findFirePoint()
        local char = lp.Character
        if not char then return nil, nil end
        local tool = char:FindFirstChildWhichIsA("Tool")
        if not tool then return nil, char end
        for _, d in ipairs(tool:GetDescendants()) do
            if d:IsA("Attachment") and d.Name == "FirePoint" then return d, char end
        end
        return nil, char
    end
    local function isPointInPart(p, part)
        local ok, rel = pcall(function() return part.CFrame:PointToObjectSpace(p) end)
        if not ok then return false end
        local half = part.Size * 0.5
        return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
    end
    local function findSupportPart(char, hrp)
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = { char, Workspace.Terrain }
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local r = Workspace:Raycast(hrp.Position, Vector3.new(0, -200, 0), rp)
        if r then return r.Instance end
        return nil
    end
    local function restoreAll()
        for p, orig in pairs(muzzleDisabledParts) do
            if p and p.Parent then pcall(function() p.CanCollide = orig end) end
        end
        muzzleDisabledParts = {}
    end
    local function step()
        if not muzzleEnabled then return end
        local fp, char = findFirePoint()
        if not fp or not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local fpPos = fp.WorldPosition
        local hrpPos = hrp.Position
        local supportPart = findSupportPart(char, hrp)
        local fpBelow = fpPos.Y < hrpPos.Y - 1.0
        local walls = {}
        local overlapParams = OverlapParams.new()
        overlapParams.FilterDescendantsInstances = { char, Workspace.Terrain }
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.MaxParts = 100
        local ok1, near = pcall(function() return Workspace:GetPartBoundsInRadius(fpPos, 0.05, overlapParams) end)
        if ok1 and near then
            for _, p in ipairs(near) do
                if p:IsA("BasePart") and p ~= supportPart and isPointInPart(fpPos, p) then
                    walls[p] = true
                end
            end
        end
        if not fpBelow then
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = { char, Workspace.Terrain }
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local dir = hrpPos - fpPos
            if dir.Magnitude > 0.1 then
                local r = Workspace:Raycast(fpPos, dir, rp)
                if r and r.Instance and r.Instance ~= supportPart then walls[r.Instance] = true end
                local steps = math.min(15, math.max(1, math.floor(dir.Magnitude / 0.5)))
                for i = 0, steps do
                    local samplePos = fpPos + dir * (i / steps)
                    local r2 = Workspace:Raycast(samplePos, dir.Unit * 0.8, rp)
                    if r2 and r2.Instance and r2.Instance ~= supportPart then walls[r2.Instance] = true end
                end
            end
        end
        for p in pairs(walls) do
            if p and p.Parent then
                muzzleDisabledParts[p] = p.CanCollide
                pcall(function() p.CanCollide = false end)
            end
        end
    end
    local function setup()
        if muzzleHbConn then pcall(function() muzzleHbConn:Disconnect() end); muzzleHbConn = nil end
        if watchConn then watchConn:Disconnect(); watchConn = nil end
        if not muzzleEnabled then restoreAll(); lastTool = nil; return end
        muzzleHbConn = RunService.Heartbeat:Connect(function()
            if not muzzleEnabled then return end
            restoreAll()
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then pcall(step) end
        end)
        watchConn = RunService.Heartbeat:Connect(function()
            if not muzzleEnabled then return end
            local char = lp.Character
            local tool = char and char:FindFirstChildWhichIsA("Tool")
            if tool ~= lastTool then lastTool = tool; restoreAll() end
        end)
    end
    toggleBase("去除枪口遮挡", "muzzle", false, function(v)
        muzzleEnabled = v
        setup()
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        if muzzleEnabled then restoreAll(); lastTool = nil; setup() end
    end)
    table.insert(cleanupFns, function()
        if muzzleHbConn then pcall(function() muzzleHbConn:Disconnect() end) end
        if watchConn then watchConn:Disconnect() end
        restoreAll()
    end)
end

-- ============ 模块 12: 无后座 ============
do
    local NOOP = function() end
    local ZERO_V3 = Vector3.new()
    local recoilPatchedMTs = {}
    local recoilPatchedInsts = setmetatable({}, { __mode = "k" })
    local recoilZeroLoop = nil
    local function isSpringLike(v)
        if type(v) ~= "table" then return false end
        if rawget(v, "_position0") or rawget(v, "_velocity0")
           or rawget(v, "_damper") or rawget(v, "_speed")
           or rawget(v, "Accelerate") then
            return true
        end
        return false
    end
    local function patchMetatable(mt)
        if type(mt) ~= "table" then return false end
        if recoilPatchedMTs[mt] then return false end
        recoilPatchedMTs[mt] = true
        local hit = false
        local acc = rawget(mt, "Accelerate")
        if type(acc) == "function" and acc ~= NOOP then
            pcall(function() rawset(mt, "Accelerate", NOOP) end)
            hit = true
        end
        local pv = rawget(mt, "_positionVelocity")
        if type(pv) == "function" then
            pcall(function() rawset(mt, "_positionVelocity", function() return ZERO_V3, ZERO_V3 end) end)
            hit = true
        end
        local oi = rawget(mt, "__index")
        if type(oi) == "function" then
            local newIndex = function(self, key)
                if recoilPatchedInsts[self] then
                    if key == "Accelerate" then return NOOP end
                    if key == "_positionVelocity" then return function() return ZERO_V3, ZERO_V3 end end
                    if key == "Position" or key == "p" or key == "Value" then return ZERO_V3 end
                    if key == "Velocity" or key == "v" then return ZERO_V3 end
                end
                return oi(self, key)
            end
            pcall(function() rawset(mt, "__index", newIndex) end)
            hit = true
        elseif type(oi) == "table" and oi ~= mt then
            local a2 = rawget(oi, "Accelerate")
            if type(a2) == "function" and a2 ~= NOOP then
                pcall(function() rawset(oi, "Accelerate", NOOP) end)
                hit = true
            end
            local pv2 = rawget(oi, "_positionVelocity")
            if type(pv2) == "function" then
                pcall(function() rawset(oi, "_positionVelocity", function() return ZERO_V3, ZERO_V3 end) end)
                hit = true
            end
            local oi2 = rawget(oi, "__index")
            if type(oi2) == "function" then
                local newIndex2 = function(self, key)
                    if recoilPatchedInsts[self] then
                        if key == "Accelerate" then return NOOP end
                        if key == "_positionVelocity" then return function() return ZERO_V3, ZERO_V3 end end
                        if key == "Position" or key == "p" or key == "Value" then return ZERO_V3 end
                        if key == "Velocity" or key == "v" then return ZERO_V3 end
                    end
                    return oi2(self, key)
                end
                pcall(function() rawset(oi, "__index", newIndex2) end)
                hit = true
            end
        end
        return hit
    end
    local function patchInstance(inst)
        if type(inst) ~= "table" then return false end
        if recoilPatchedInsts[inst] then return false end
        if not isSpringLike(inst) then return false end
        recoilPatchedInsts[inst] = true
        local acc = rawget(inst, "Accelerate")
        if type(acc) == "function" and acc ~= NOOP then
            pcall(function() rawset(inst, "Accelerate", NOOP) end)
        end
        local pv = rawget(inst, "_positionVelocity")
        if type(pv) == "function" then
            pcall(function() rawset(inst, "_positionVelocity", function() return ZERO_V3, ZERO_V3 end) end)
        end
        local mt = getmetatable(inst)
        if mt and type(mt) == "table" then patchMetatable(mt) end
        return true
    end
    local function startZeroLoop()
        if recoilZeroLoop then return end
        recoilZeroLoop = spawn(function()
            while recoilEnabled and gui.Parent do
                for inst in pairs(recoilPatchedInsts) do
                    pcall(function()
                        rawset(inst, "_position0", ZERO_V3)
                        rawset(inst, "_velocity0", ZERO_V3)
                        rawset(inst, "_target", ZERO_V3)
                        rawset(inst, "_position", ZERO_V3)
                        rawset(inst, "_velocity", ZERO_V3)
                    end)
                end
                RunService.Heartbeat:Wait()
            end
            recoilZeroLoop = nil
        end)
    end
    local function stopZeroLoop()
        if recoilZeroLoop then
            pcall(function() recoilZeroLoop:Disconnect() end)
            recoilZeroLoop = nil
        end
    end
    local recoilSpringModule = nil
    local recoilSpring2Module = nil
    local function hookModule(path, label)
        local p = ReplicatedStorage
        for _, seg in ipairs(path) do p = p and p:FindFirstChild(seg) end
        if not p then return end
        local ok, m = pcall(require, p)
        if not ok or type(m) ~= "table" then return end
        local container = m
        local newFn = rawget(m, "new")
        if type(newFn) ~= "function" then
            local sp = rawget(m, "spring")
            if type(sp) == "table" then
                container = sp
                newFn = rawget(sp, "new")
            end
        end
        if type(newFn) ~= "function" then return end
        if label == "Spring" then
            if recoilSpringModule then return end
            recoilSpringModule = m
        else
            if recoilSpring2Module then return end
            recoilSpring2Module = m
        end
        local orig = newFn
        local mt = getmetatable(container)
        if mt then pcall(function() setmetatable(container, nil) end) end
        pcall(function()
            rawset(container, "new", function(...)
                local inst = orig(...)
                if recoilEnabled and type(inst) == "table" then
                    task.defer(function() patchInstance(inst) end)
                end
                return inst
            end)
        end)
        if mt then pcall(function() setmetatable(container, mt) end) end
    end
    local function rescan()
        pcall(function()
            for _, v in pairs(getgc(true)) do
                if isSpringLike(v) then patchInstance(v) end
            end
        end)
    end
    local function setup()
        if not recoilEnabled then
            stopZeroLoop()
            recoilPatchedInsts = setmetatable({}, { __mode = "k" })
            recoilPatchedMTs = {}
            return
        end
        hookModule({"Assets","Modules","Spring"}, "Spring")
        hookModule({"Assets","Modules","Spring2"}, "Spring2")
        rescan()
        startZeroLoop()
    end
    toggleBase("无后坐力", "recoil", false, function(v)
        recoilEnabled = v
        setup()
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        if recoilEnabled then rescan() end
    end)
    table.insert(cleanupFns, function()
        recoilEnabled = false
        stopZeroLoop()
    end)
end

-- ============ 模块 13: 聊天框强制显示 ============
do
    local TextChatService = game:GetService("TextChatService")
    local chatForceThread = nil
    local chatForceConn = nil
    local chatForceOrig = nil
    local function getCfg() return TextChatService:FindFirstChild("ChatWindowConfiguration") end
    local function startGuard()
        if chatForceThread then return end
        local cfg = getCfg()
        chatForceOrig = cfg and cfg.Enabled or false
        if cfg then
            chatForceConn = cfg:GetPropertyChangedSignal("Enabled"):Connect(function()
                if chatForceEnabled and not cfg.Enabled then cfg.Enabled = true end
            end)
        end
        chatForceThread = spawn(function()
            while chatForceEnabled do
                local c = getCfg()
                if c and not c.Enabled then c.Enabled = true end
                wait(0.25)
            end
            chatForceThread = nil
        end)
    end
    local function stopGuard()
        chatForceEnabled = false
        chatForceThread = nil
        if chatForceConn then pcall(function() chatForceConn:Disconnect() end); chatForceConn = nil end
        local cfg = getCfg()
        if cfg and chatForceOrig ~= nil then cfg.Enabled = chatForceOrig end
        chatForceOrig = nil
    end
    toggleBase("聊天框强制显示", "chatForce", false, function(v)
        chatForceEnabled = v
        if v then
            startGuard()
            local cfg = getCfg()
            if cfg then cfg.Enabled = true end
        else stopGuard() end
    end)
    table.insert(cleanupFns, function() stopGuard() end)
end

-- ============ 模块 14: 强制爆头 ============
do
    local fhHookInstalled = false
    local fhOrigInvoke = nil
    local fhNetwork = nil
    do
        local m = ReplicatedStorage
        for _, seg in ipairs({"Assets","Modules","Network"}) do
            m = m and m:FindFirstChild(seg)
        end
        if m then
            local ok, r = pcall(require, m)
            if ok and type(r) == "table" then fhNetwork = r end
        end
    end
    local function fhForceHeadshot(hitData)
        if type(hitData) ~= "table" then return false end
        local hum = hitData[1]
        local part = hitData[2]
        if not hum or not hum:IsA("Humanoid") then return false end
        if hum.Health <= 0 then return false end
        local char = hum.Parent
        if not char or not char.Parent then return false end
        if _playerChars[char] then return false end
        if char:GetAttribute("FriendlyToFlare") == true then return false end
        local head = char:FindFirstChild("Head")
        if not head then return false end
        if part == head then return false end
        local cam = Workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position
        local normal = hitData[4]
        if typeof(normal) ~= "Vector3" then
            local fp = hitData[5]
            if typeof(fp) == "Vector3" then normal = (head.Position - fp).Unit
            else normal = Vector3.new(0, 1, 0) end
        end
        hitData[2] = head
        hitData[3] = head.Position
        if camPos then hitData[5] = camPos end
        local root = hum.RootPart or char:FindFirstChild("HumanoidRootPart")
        if root then
            local cf = CFrame.new(head.Position, head.Position - normal * 1.5)
            hitData[7] = root.CFrame:ToObjectSpace(cf)
        end
        return true
    end
    local function installFH()
        if fhHookInstalled then return end
        if not fhNetwork or type(fhNetwork.InvokeServer) ~= "function" then return end
        fhHookInstalled = true
        fhOrigInvoke = fhNetwork.InvokeServer
        local w = function(self, action, ...)
            if action == "hit" and forceHeadshotEnabled then
                local args = {...}
                fhForceHeadshot(args[3])
                return fhOrigInvoke(self, action, args[1], args[2], args[3])
            end
            return fhOrigInvoke(self, action, ...)
        end
        local ok = pcall(function() rawset(fhNetwork, "InvokeServer", w) end)
        if not ok then pcall(function() fhNetwork.InvokeServer = w end) end
    end
    local function uninstallFH()
        if not fhHookInstalled then return end
        fhHookInstalled = false
        if fhNetwork and fhOrigInvoke then
            pcall(function() fhNetwork.InvokeServer = fhOrigInvoke end)
        end
        fhOrigInvoke = nil
    end
    local fhBtn, fhSetState = toggleBase("强制爆头", "forceHeadshot", false, function(v)
        forceHeadshotEnabled = v
        if v then
            installFH()
            if _G._ExamMB and _G._ExamMB.magicOffFn then
                pcall(_G._ExamMB.magicOffFn)
            end
        else
            uninstallFH()
        end
    end)
    _G._ExamFH.forceOffFn = function()
        if fhSetState then pcall(function() fhSetState(false) end) end
    end
    table.insert(cleanupFns, function() uninstallFH() end)
end

-- ============ 模块 15: 自动 QTE ============
do
    local qteModule = nil
    local qteInputRemote = nil
    do
        local m = ReplicatedStorage
        for _, seg in ipairs({"Assets","Modules","QTEManager"}) do
            m = m and m:FindFirstChild(seg)
        end
        if m then
            local ok, r = pcall(require, m)
            if ok and type(r) == "table" then qteModule = r end
        end
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then qteInputRemote = events:FindFirstChild("QTEInput") end
    end
    local qteConn = nil
    local lastQteTick = 0
    local function getRequested()
        if qteModule and type(qteModule.GetCurrentRequestedInput) == "function" then
            local ok, res = pcall(qteModule.GetCurrentRequestedInput)
            if ok then return res end
        end
        return nil
    end
    local function fireHandleInput(keyName)
        if not qteModule or type(qteModule.HandleInput) ~= "function" then return end
        local now = tick()
        if now - lastQteTick < 0.1 then return end
        lastQteTick = now
        pcall(qteModule.HandleInput, keyName)
    end
    local function onQTEInput(keyName)
        if not autoQTEEnabled then return end
        task.spawn(function()
            task.wait(0.05)
            local cur = getRequested()
            local targetKey = cur or keyName
            fireHandleInput(targetKey)
        end)
    end
    local function setup()
        if qteConn then pcall(function() qteConn:Disconnect() end); qteConn = nil end
        if not autoQTEEnabled then return end
        if not qteInputRemote then return end
        qteConn = qteInputRemote.OnClientEvent:Connect(onQTEInput)
    end
    toggleBase("自动 QTE", "autoQTE", false, function(v)
        autoQTEEnabled = v
        setup()
    end)
    table.insert(cleanupFns, function()
        if qteConn then pcall(function() qteConn:Disconnect() end) end
    end)
end

-- ============ 模块 16: 霰弹枪连发 ============
do
    local animatorConn = nil
    local function isTargetAnim(track)
        local an = track.Animation
        if not an then return false end
        local id = tostring(an.AnimationId or ""):match("%d+")
        if not id then return false end
        return SHOTGUN_PUMP_IDS[id] == true
    end
    local function restoreTracks()
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local ok, tracks = pcall(function() return hum:GetPlayingAnimationTracks() end)
        if not ok or type(tracks) ~= "table" then return end
        for _, t in ipairs(tracks) do
            local an = t.Animation
            if an then
                local id = tostring(an.AnimationId or ""):match("%d+")
                if id and SHOTGUN_PUMP_IDS[id] then
                    pcall(function() t:AdjustSpeed(1) end)
                end
            end
        end
    end
    local function setupAnimator()
        if animatorConn then pcall(function() animatorConn:Disconnect() end); animatorConn = nil end
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        animatorConn = animator.AnimationPlayed:Connect(function(track)
            if not shotgunNoPumpEnabled then return end
            if isTargetAnim(track) then
                pcall(function() track:AdjustSpeed(SHOTGUN_SPEED_MULT) end)
            end
        end)
    end
    toggleBase("霰弹枪连发", "shotgunNoPump", false, function(v)
        shotgunNoPumpEnabled = v
        if v then
            setupAnimator()
        else
            if animatorConn then pcall(function() animatorConn:Disconnect() end); animatorConn = nil end
            pcall(restoreTracks)
        end
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        if shotgunNoPumpEnabled then setupAnimator() end
    end)
    table.insert(cleanupFns, function()
        shotgunNoPumpEnabled = false
        if animatorConn then pcall(function() animatorConn:Disconnect() end) end
        pcall(restoreTracks)
    end)
end

-- ============ 模块 16.5: 修复盾牌滑铲/疾跑 ============
do
    local SLIDE_BADGE_ID = 3938313051889761
    local origBadgeAsync = nil
    local badgeHooked = false
    local trySlideFn = nil
    local startSlideFn = nil
    local origTrySlideFn = nil
    local trySlideHooked = false
    local pushLoop = nil
    local hudLoop = nil

    local function findPostureFrame()
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return nil end
        local gGui = pg:FindFirstChild("Gui")
        if not gGui then return nil end
        local posture = gGui:FindFirstChild("Posture")
        if posture and posture:IsA("GuiObject") then return posture end
        return nil
    end

    local function pushAttrs()
        local char = lp.Character
        if not char then return end
        if noCDEnabled and noCDActiveUntil > tick() then return end
        pcall(function() char:SetAttribute("RiotShieldEquipped", false) end)
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                local ok, v = pcall(function() return t:GetAttribute("RiotShieldTool") end)
                if ok and v == true then
                    pcall(function() t:SetAttribute("RiotShieldTool", false) end)
                end
            end
        end
    end

    local function startPush()
        if pushLoop then return end
        pushLoop = spawn(function()
            while shieldFixEnabled and gui.Parent do
                pcall(pushAttrs)
                wait(0.05)
            end
            pushLoop = nil
        end)
    end

    local function stopPush() pushLoop = nil end

    local function hookBadge()
        if badgeHooked or not hookfunction then return end
        if _G._shieldFixOrigBadge then
            badgeHooked = true
            return
        end
        origBadgeAsync = BadgeService.UserHasBadgeAsync
        local ok = pcall(function()
            hookfunction(BadgeService.UserHasBadgeAsync, function(self, uid, bid)
                if bid == SLIDE_BADGE_ID then return true end
                return origBadgeAsync(self, uid, bid)
            end)
        end)
        if ok then
            badgeHooked = true
            _G._shieldFixOrigBadge = origBadgeAsync
        end
    end

    local function findSlideFns()
        trySlideFn = nil
        startSlideFn = nil
        if not getgc or not getinfo then return false end
        local ok, gc = pcall(function() return getgc(true) end)
        if not ok or type(gc) ~= "table" then return false end
        for _, v in pairs(gc) do
            if type(v) == "function" then
                local ok2, info = pcall(function() return getinfo(v) end)
                if ok2 and type(info) == "table" then
                    local s = (info.source or ""):lower()
                    if s:find("movementcontroller", 1, true) then
                        local n = info.name or ""
                        if n == "TrySlide" and not trySlideFn then
                            trySlideFn = v
                        elseif n == "StartSlide" and not startSlideFn then
                            startSlideFn = v
                        end
                    end
                end
            end
        end
        return trySlideFn ~= nil and startSlideFn ~= nil
    end

    local function hookTrySlide()
        if trySlideHooked then return end
        if not trySlideFn or not startSlideFn then
            if not findSlideFns() then return end
        end
        if not hookfunction then return end
        origTrySlideFn = trySlideFn
        local ok = pcall(function()
            hookfunction(trySlideFn, function(...)
                if not shieldFixEnabled then
                    return origTrySlideFn(...)
                end
                local char = lp.Character
                if not char then return false end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then return false end
                if hum:GetAttribute("sliding") then return false end
                task.spawn(startSlideFn)
                return true
            end)
        end)
        if ok then
            trySlideHooked = true
            _G._shieldFixTargetTrySlide = trySlideFn
            _G._shieldFixOrigTrySlide = origTrySlideFn
            _G._shieldFixStartSlide = startSlideFn
        end
    end

    local function restoreTrySlide()
        if trySlideHooked and origTrySlideFn and hookfunction then
            pcall(function() hookfunction(origTrySlideFn, origTrySlideFn) end)
            trySlideHooked = false
        end
        _G._shieldFixTargetTrySlide = nil
        _G._shieldFixOrigTrySlide = nil
        _G._shieldFixStartSlide = nil
    end

    local function startHudFix()
        if hudLoop then return end
        hudLoop = spawn(function()
            while shieldFixEnabled and gui.Parent do
                local char = lp.Character
                if char then
                    local state = char:GetAttribute("RiotShieldState")
                    local active = state and state ~= "Inactive" and state ~= ""
                    if active then
                        local posture = findPostureFrame()
                        if posture and not posture.Visible then
                            pcall(function() posture.Visible = true end)
                        end
                    end
                end
                wait(0.05)
            end
            hudLoop = nil
        end)
    end

    local function stopHudFix() hudLoop = nil end

    local function setup()
        if shieldFixEnabled then
            hookBadge()
            findSlideFns()
            hookTrySlide()
            startPush()
            startHudFix()
        else
            stopPush()
            stopHudFix()
            restoreTrySlide()
        end
    end

    toggleBase("修复盾牌滑铲/疾跑", "shieldSlide", false, function(v)
        shieldFixEnabled = v
        setup()
    end)

    lp.CharacterAdded:Connect(function()
        wait(1)
        if shieldFixEnabled then
            findSlideFns()
            hookTrySlide()
        end
    end)

    table.insert(cleanupFns, function()
        shieldFixEnabled = false
        stopPush()
        stopHudFix()
        restoreTrySlide()
    end)
end

-- ============ 模块 16.6: 第一人称盾牌半透明 ============
do
    local tracked = {}
    local scanLoop = nil
    local lastVM = nil
    local function getViewmodel()
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        return cam:FindFirstChild("RiotShieldViewmodel")
    end
    local function applyToVM(vm)
        if not vm then return 0 end
        local count = 0
        for _, d in ipairs(vm:GetDescendants()) do
            if d:IsA("BasePart") then
                if tracked[d] == nil then
                    tracked[d] = d.Transparency
                end
                if tracked[d] < 0.95 then
                    if math.abs(d.Transparency - shieldVMAlpha) > 0.01 then
                        pcall(function() d.Transparency = shieldVMAlpha end)
                    end
                    count = count + 1
                end
            end
        end
        return count
    end
    local function restoreAll()
        for p, orig in pairs(tracked) do
            if p and p.Parent then
                pcall(function() p.Transparency = orig end)
            end
        end
        tracked = {}
    end
    local function startScanLoop()
        if scanLoop then scanLoop:Disconnect(); scanLoop = nil end
        scanLoop = RunService.Heartbeat:Connect(function()
            if not shieldVMEnabled then return end
            local vm = getViewmodel()
            if vm ~= lastVM then
                lastVM = vm
                if vm then applyToVM(vm) end
            elseif vm then
                applyToVM(vm)
            end
        end)
    end
    spawn(function()
        while gui.Parent do
            wait(0.5)
            for p in pairs(tracked) do
                if not p or not p.Parent then tracked[p] = nil end
            end
        end
    end)
    toggleBase("第一人称盾牌半透明", "shieldVM", false, function(v)
        shieldVMEnabled = v
        if v then
            local vm = getViewmodel()
            if vm then
                lastVM = vm
                applyToVM(vm)
            end
            startScanLoop()
        else
            if scanLoop then scanLoop:Disconnect(); scanLoop = nil end
            restoreAll()
            lastVM = nil
        end
    end)
    local alphaLabel = Instance.new("TextLabel", basePage)
    alphaLabel.BackgroundTransparency = 1
    alphaLabel.Text = "盾牌透明度:"
    alphaLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    alphaLabel.Font = Enum.Font.Gotham; alphaLabel.TextSize = 11
    alphaLabel.TextXAlignment = Enum.TextXAlignment.Left
    reg(alphaLabel, "shieldAlphaLabel")
    local alphaInput = Instance.new("TextBox", basePage)
    alphaInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    alphaInput.TextColor3 = Color3.new(1, 1, 1)
    alphaInput.Text = string.format("%.2f", shieldVMAlpha)
    alphaInput.Font = Enum.Font.Gotham; alphaInput.TextSize = 11; alphaInput.BorderSizePixel = 0
    Instance.new("UICorner", alphaInput).CornerRadius = UDim.new(0, 4)
    reg(alphaInput, "shieldAlphaInput")
    alphaInput.FocusLost:Connect(function()
        local val = tonumber(alphaInput.Text)
        if val and val >= 0.0 and val <= 0.99 then
            shieldVMAlpha = val
            alphaInput.Text = string.format("%.2f", val)
            if shieldVMEnabled then
                local vm = getViewmodel()
                if vm then applyToVM(vm) end
            end
        else
            alphaInput.Text = string.format("%.2f", shieldVMAlpha)
        end
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        tracked = {}
        lastVM = nil
        if shieldVMEnabled then
            local vm = getViewmodel()
            if vm then
                lastVM = vm
                applyToVM(vm)
            end
        end
    end)
    table.insert(cleanupFns, function()
        shieldVMEnabled = false
        if scanLoop then scanLoop:Disconnect() end
        restoreAll()
    end)
end

-- ============ 模块 16.7: 无滑铲冷却（有bug慎用）v16.4.9 ============
do
    local humConn = nil
    local keyConn = nil
    local slideGen = 0
    local lastKeyTick = 0

    local function refreshCDNow()
        local char = lp.Character
        if not char then return end
        noCDActiveUntil = tick() + 0.15
        pcall(function() char:SetAttribute("RiotShieldEquipped", true) end)
    end

    local function bindHum()
        if humConn then pcall(function() humConn:Disconnect() end); humConn = nil end
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        humConn = hum:GetAttributeChangedSignal("sliding"):Connect(function()
            local s = hum:GetAttribute("sliding")
            if s == true then
                slideGen = slideGen + 1
                local myGen = slideGen
                task.spawn(function()
                    task.wait(0.5)
                    if slideGen ~= myGen then return end
                    if not noCDEnabled then return end
                    local c = lp.Character
                    if not c then return end
                    local h = c:FindFirstChildOfClass("Humanoid")
                    if not h or not h:GetAttribute("sliding") then return end
                    noCDActiveUntil = tick() + 0.15
                    pcall(function() c:SetAttribute("RiotShieldEquipped", true) end)
                end)
            end
        end)
    end

    local function bindKeyboard()
        if keyConn then pcall(function() keyConn:Disconnect() end); keyConn = nil end
        keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if not noCDEnabled then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode ~= Enum.KeyCode.C then return end
            local now = tick()
            if now - lastKeyTick < 0.3 then return end
            lastKeyTick = now
            task.spawn(function()
                task.wait(0.15)
                local char = lp.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                local sliding = hum:GetAttribute("sliding")
                local moving = hum.MoveDirection.Magnitude > 0.1
                if not sliding and moving then
                    noCDActiveUntil = tick() + 0.15
                    pcall(function() char:SetAttribute("RiotShieldEquipped", true) end)
                end
            end)
        end)
    end

    spawn(function()
        while gui.Parent do
            wait(0.05)
            if noCDEnabled and noCDActiveUntil > 0 and noCDActiveUntil <= tick() then
                local char = lp.Character
                if char then
                    pcall(function() char:SetAttribute("RiotShieldEquipped", false) end)
                end
                noCDActiveUntil = 0
            end
        end
    end)

    toggleBase("无滑铲冷却（有bug慎用）", "noCD", false, function(v)
        noCDEnabled = v
        if v then
            bindHum()
            bindKeyboard()
            refreshCDNow()
        else
            noCDActiveUntil = 0
            if humConn then pcall(function() humConn:Disconnect() end); humConn = nil end
            if keyConn then pcall(function() keyConn:Disconnect() end); keyConn = nil end
            local char = lp.Character
            if char then
                pcall(function() char:SetAttribute("RiotShieldEquipped", false) end)
            end
        end
    end)

    lp.CharacterAdded:Connect(function()
        wait(1)
        if noCDEnabled then
            bindHum()
            bindKeyboard()
            refreshCDNow()
        end
    end)

    table.insert(cleanupFns, function()
        noCDEnabled = false
        noCDActiveUntil = 0
        if humConn then pcall(function() humConn:Disconnect() end) end
        if keyConn then pcall(function() keyConn:Disconnect() end) end
        local char = lp.Character
        if char then
            pcall(function() char:SetAttribute("RiotShieldEquipped", false) end)
        end
    end)
end

-- ============ 布局切换按钮 ============
local layoutSwitchBtn = Instance.new("TextButton", basePage)
layoutSwitchBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
layoutSwitchBtn.TextColor3 = Color3.new(1, 1, 1)
layoutSwitchBtn.Font = Enum.Font.GothamBold
layoutSwitchBtn.TextSize = 12
layoutSwitchBtn.Active = true
Instance.new("UICorner", layoutSwitchBtn).CornerRadius = UDim.new(0, 5)
reg(layoutSwitchBtn, "layoutSwitch")

local isCollapsed = false
local function applyLayout(layout)
    currentLayout = layout
    local L = LAYOUT[layout]
    titleBar.Size = UDim2.new(1, 0, 0, L.TitleH)
    tabBar.Position = UDim2.new(0, 15, 0, L.TabY)
    basePage.Size = UDim2.new(1, 0, 1, -L.PageTop)
    basePage.Position = UDim2.new(0, 0, 0, L.PageTop)
    magicPage.Size = UDim2.new(1, 0, 1, -L.PageTop)
    magicPage.Position = UDim2.new(0, 0, 0, L.PageTop)
    radarPage.Size = UDim2.new(1, 0, 1, -L.PageTop)
    radarPage.Position = UDim2.new(0, 0, 0, L.PageTop)
    for g, key in pairs(regControls) do
        if g.Parent then
            local info = L.items[key]
            if info then
                g.Position = info.p
                g.Size = info.s
            end
        end
    end
    local h = getTabHeight()
    if isCollapsed then
        main.Size = UDim2.new(0, L.W, 0, L.TitleH)
    else
        main.Size = UDim2.new(0, L.W, 0, h)
    end
    main.Position = UDim2.new(0.5, -L.W/2, 0.5, -h/2)
    layoutSwitchBtn.Text = (layout == "mobile") and "切换为电脑UI" or "切换为手机UI"
    title.Text = "Examination v16.4.9 - " .. (layout == "mobile" and "手机" or "电脑")
end

bindTap(layoutSwitchBtn, function()
    local nextLayout = (currentLayout == "mobile") and "desktop" or "mobile"
    applyLayout(nextLayout)
end)

layoutSwitchBtn.Text = (currentLayout == "mobile") and "切换为电脑UI" or "切换为手机UI"
title.Text = "Examination v16.4.9 - " .. (currentLayout == "mobile" and "手机" or "电脑")

-- ============ 模块 17: 魔法子弹页 ============
do
    local mbAimPartIndex = 1
    local mbFovRadius = 200
    local mbWorldDistMax = 5000
    local mbBBSizeStuds = 2.0
    local mbStudsOffsetY = 0.8
    local mbShowBox = false
    local mbRequireVisible = false
    local mbShowFovCircle = true

    local AIM_PARTS = {
        { name = "Head",      label = "头部" },
        { name = "Torso",     label = "躯干" },
        { name = "Left Arm",  label = "左臂" },
        { name = "Right Arm", label = "右臂" },
        { name = "Left Leg",  label = "左腿" },
        { name = "Right Leg", label = "右腿" },
    }
    local function getAimPart(model)
        if not model then return nil end
        local info = AIM_PARTS[mbAimPartIndex]
        if not info then return model:FindFirstChild("Head") end
        local name = info.name
        if name == "Head" then return model:FindFirstChild("Head") end
        if name == "Torso" then
            return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
        end
        local aliases = {
            ["Left Arm"]  = { "LeftUpperArm", "Left Arm" },
            ["Right Arm"] = { "RightUpperArm", "Right Arm" },
            ["Left Leg"]  = { "LeftUpperLeg", "Left Leg" },
            ["Right Leg"] = { "RightUpperLeg", "Right Leg" },
        }
        local list = aliases[name]
        if list then
            for _, n in ipairs(list) do
                local p = model:FindFirstChild(n)
                if p then return p end
            end
        end
        return model:FindFirstChild(name)
    end

    local mbNetwork = nil
    do
        local m = ReplicatedStorage
        for _, seg in ipairs({"Assets","Modules","Network"}) do
            m = m and m:FindFirstChild(seg)
        end
        if m then
            local ok, r = pcall(require, m)
            if ok and type(r) == "table" then mbNetwork = r end
        end
    end
    local mbRaycastPath = ReplicatedStorage
    for _, seg in ipairs({"Assets","Modules","Raycast"}) do
        mbRaycastPath = mbRaycastPath and mbRaycastPath:FindFirstChild(seg)
    end

    local function isAlive(m)
        if not m or not m.Parent then return false end
        local hum = m:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end
    local function isHostile(m)
        if not m or not m.Parent then return false end
        if m == lp.Character then return false end
        if _playerChars[m] then return false end
        if m:GetAttribute("FriendlyToFlare") == true then return false end
        return true
    end

    local function isPointVisible(origin, targetPos, targetModel, excludeBase)
        local dir = targetPos - origin
        local dist = dir.Magnitude
        if dist < 0.5 then return true end
        local dirUnit = dir.Unit
        local exclude = {}
        for _, v in ipairs(excludeBase) do table.insert(exclude, v) end
        local curOrigin = origin
        local remaining = dist
        local maxIter = 12
        for _ = 1, maxIter do
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = exclude
            rp.IgnoreWater = true
            local r = Workspace:Raycast(curOrigin, dirUnit * remaining, rp)
            if not r then return true end
            if r.Instance:IsDescendantOf(targetModel) then return true end
            local inst = r.Instance
            if inst:IsA("BasePart") then
                if inst.CanCollide then return false end
                if inst.Transparency >= 0.95 then
                    table.insert(exclude, inst)
                    local adv = (r.Position - curOrigin).Magnitude + 0.05
                    curOrigin = r.Position + dirUnit * 0.05
                    remaining = remaining - adv
                    if remaining <= 0 then return true end
                else
                    return false
                end
            else
                return false
            end
        end
        return true
    end

    local mbFovCircleGui = nil
    local mbFovCircleImg = nil
    local function ensureFov()
        if not magicBulletEnabled then return end
        if mbFovCircleGui and mbFovCircleGui.Parent then return end
        mbFovCircleGui = Instance.new("ScreenGui")
        mbFovCircleGui.Name = "ForceHS_FOVCircle"
        mbFovCircleGui.ResetOnSpawn = false
        mbFovCircleGui.IgnoreGuiInset = true
        mbFovCircleGui.DisplayOrder = 100
        mbFovCircleGui.Parent = uiParent
        mbFovCircleImg = Instance.new("Frame")
        mbFovCircleImg.AnchorPoint = Vector2.new(0.5, 0.5)
        mbFovCircleImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        mbFovCircleImg.BackgroundTransparency = 1
        mbFovCircleImg.BorderSizePixel = 0
        mbFovCircleImg.Parent = mbFovCircleGui
        Instance.new("UICorner", mbFovCircleImg).CornerRadius = UDim.new(1, 0)
        local s = Instance.new("UIStroke", mbFovCircleImg)
        s.Thickness = 1
        s.Color = Color3.fromRGB(120, 255, 120)
        s.Transparency = 0.35
    end
    local function updateFov()
        if not mbFovCircleImg then return end
        if magicBulletEnabled and mbShowFovCircle then
            mbFovCircleImg.Visible = true
            mbFovCircleImg.Size = UDim2.new(0, mbFovRadius * 2, 0, mbFovRadius * 2)
            mbFovCircleImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        else mbFovCircleImg.Visible = false end
    end
    local function destroyFov()
        if mbFovCircleGui then pcall(function() mbFovCircleGui:Destroy() end) end
        mbFovCircleGui = nil; mbFovCircleImg = nil
    end

    local lastFindTick = 0
    local cachedTarget = nil
    local function findTarget()
        local now = tick()
        if now - lastFindTick < 0.016 then return cachedTarget end
        lastFindTick = now
        local myChar = lp.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then cachedTarget = nil; return nil end
        local cam = Workspace.CurrentCamera
        if not cam then cachedTarget = nil; return nil end
        local vs = cam.ViewportSize
        local cx, cy = vs.X / 2, vs.Y / 2
        local myPos = myHrp.Position
        local r2 = mbFovRadius * mbFovRadius
        local best, bestD2 = nil, math.huge
        local camPos = cam.CFrame.Position
        local excludeVis = { lp.Character, Workspace.Terrain }
        table.insert(excludeVis, cam)
        local vms = Workspace:FindFirstChild("Viewmodels")
        if vms then table.insert(excludeVis, vms) end
        for _, folderName in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                for _, m in ipairs(folder:GetChildren()) do
                    if m ~= myChar and m:IsA("Model") and isAlive(m) and isHostile(m) then
                        local aimPart = getAimPart(m)
                        local head = m:FindFirstChild("Head")
                        if aimPart and head then
                            local wd = (aimPart.Position - myPos).Magnitude
                            if wd <= mbWorldDistMax then
                                local visible = true
                                if mbRequireVisible then
                                    visible = isPointVisible(camPos, aimPart.Position, m, excludeVis)
                                end
                                if visible then
                                    local s, onScreen = cam:WorldToViewportPoint(head.Position)
                                    if onScreen and s.Z > 0 then
                                        local dx = s.X - cx
                                        local dy = s.Y - cy
                                        local d2 = dx*dx + dy*dy
                                        if d2 <= r2 and d2 < bestD2 then
                                            bestD2 = d2
                                            best = { model = m, head = head, aimPart = aimPart }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        cachedTarget = best
        return best
    end

    local shieldCache = { list = {}, tick = 0 }
    local helmetCache = { list = {}, tick = 0 }
    local teammateCache = { list = {}, tick = 0 }
    local corpseCache = { list = {}, tick = 0 }

    local function forEachModel(fn)
        for _, folderName in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                for _, m in ipairs(folder:GetChildren()) do
                    if m:IsA("Model") then fn(m) end
                end
            end
        end
    end

    local function collectShields()
        local now = tick()
        if now - shieldCache.tick < 1 and #shieldCache.list > 0 then return shieldCache.list end
        shieldCache.tick = now
        local list = {}
        forEachModel(function(m)
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BasePart") then
                    local n = string.lower(d.Name)
                    if n:find("shield", 1, true) or n:find("riot", 1, true) then
                        table.insert(list, d)
                    end
                end
            end
        end)
        shieldCache.list = list
        return list
    end
    local function collectHelmets()
        local now = tick()
        if now - helmetCache.tick < 1 and #helmetCache.list > 0 then return helmetCache.list end
        helmetCache.tick = now
        local list = {}
        forEachModel(function(m)
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BasePart") then
                    local n = string.lower(d.Name)
                    if n:find("helmet", 1, true) or n:find("helm", 1, true)
                       or n:find("visor", 1, true) then
                        table.insert(list, d)
                    end
                end
            end
        end)
        helmetCache.list = list
        return list
    end
    local function collectTeammates()
        local now = tick()
        if now - teammateCache.tick < 1 and #teammateCache.list > 0 then return teammateCache.list end
        teammateCache.tick = now
        local list = {}
        forEachModel(function(m)
            if m ~= lp.Character and Players:GetPlayerFromCharacter(m) then
                for _, d in ipairs(m:GetDescendants()) do
                    if d:IsA("BasePart") then table.insert(list, d) end
                end
            end
        end)
        teammateCache.list = list
        return list
    end
    local function collectCorpses()
        local now = tick()
        if now - corpseCache.tick < 1 and #corpseCache.list > 0 then return corpseCache.list end
        corpseCache.tick = now
        local list = {}
        forEachModel(function(m)
            if m ~= lp.Character then
                local hum = m:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health <= 0 then
                    for _, d in ipairs(m:GetDescendants()) do
                        if d:IsA("BasePart") then table.insert(list, d) end
                    end
                end
            end
        end)
        corpseCache.list = list
        return list
    end
    local function applyExtraFilter(behavior)
        if type(behavior) ~= "table" then return end
        local params = behavior.RaycastParams
        if typeof(params) ~= "RaycastParams" then return end
        local fdi = params.FilterDescendantsInstances
        if type(fdi) ~= "table" then return end
        local newFdi = {}
        for _, v in ipairs(fdi) do table.insert(newFdi, v) end
        if pierceShieldEnabled then
            for _, s in ipairs(collectShields()) do
                if s and s.Parent then table.insert(newFdi, s) end
            end
        end
        if pierceHelmetEnabled then
            for _, s in ipairs(collectHelmets()) do
                if s and s.Parent then table.insert(newFdi, s) end
            end
        end
        if pierceTeammateEnabled then
            for _, s in ipairs(collectTeammates()) do
                if s and s.Parent then table.insert(newFdi, s) end
            end
        end
        if pierceCorpseEnabled then
            for _, s in ipairs(collectCorpses()) do
                if s and s.Parent then table.insert(newFdi, s) end
            end
        end
        pcall(function() params.FilterDescendantsInstances = newFdi end)
    end

    local lockBB = nil
    local lockTarget = nil
    local function destroyLockBB()
        if lockBB and lockBB.Parent then pcall(function() lockBB:Destroy() end) end
        lockBB = nil; lockTarget = nil
        forEachModel(function(m)
            local bb = m:FindFirstChild("Exam_MB_LockBB")
            if bb then pcall(function() bb:Destroy() end) end
        end)
    end
    local function createLockBB(part)
        local bb = Instance.new("BillboardGui")
        bb.Name = "Exam_MB_LockBB"
        bb.Adornee = part
        bb.Size = UDim2.new(mbBBSizeStuds, 0, mbBBSizeStuds, 0)
        bb.StudsOffsetWorldSpace = Vector3.new(0, mbStudsOffsetY, 0)
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.MaxDistance = mbWorldDistMax
        bb.ResetOnSpawn = false
        bb.Parent = part
        local f = Instance.new("Frame", bb)
        f.Name = "BoxFrame"
        f.Size = UDim2.new(1, 0, 1, 0)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.new(0.5, 0, 0.5, 0)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        local s = Instance.new("UIStroke", f)
        s.Color = Color3.fromRGB(120, 255, 120)
        s.Thickness = 2
        s.Transparency = 0.05
        local dot = Instance.new("Frame", bb)
        dot.Name = "CenterDot"
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(0.5, 0, 0.5, 0)
        dot.BackgroundColor3 = Color3.fromRGB(120, 255, 120)
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        spawn(function()
            local deg = 0
            while bb and bb.Parent do
                deg = (deg + 5) % 360
                if f and f.Parent then f.Rotation = deg end
                wait(0.03)
            end
        end)
        return bb
    end
    local function updateLockBB()
        if not magicBulletEnabled or not mbShowBox then
            if lockBB and lockBB.Parent then lockBB.Enabled = false end
            return
        end
        local target = findTarget()
        if not target then
            if lockBB and lockBB.Parent then lockBB.Enabled = false end
            return
        end
        local aimPart = target.aimPart
        if not aimPart then
            if lockBB and lockBB.Parent then lockBB.Enabled = false end
            return
        end
        if lockTarget ~= target.model or not lockBB or not lockBB.Parent
           or lockBB.Adornee ~= aimPart then
            if lockBB and lockBB.Parent then pcall(function() lockBB:Destroy() end) end
            lockBB = createLockBB(aimPart)
            lockTarget = target.model
        else lockBB.Enabled = true end
    end

    local mbOrigFire = nil
    local mbOrigRaycastNew = nil
    local mbOrigInvoke = nil
    local mbRaycastModule = nil
    local mbHookInstalled = false
    local function getFirePos(tool)
        if not tool or not tool:IsA("Tool") then return nil end
        local core = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
        if not core then return nil end
        local fp = core:FindFirstChild("FirePoint")
        if fp and fp:IsA("Attachment") then return fp.WorldPosition end
        return core.Position
    end
    local function forceAimPart(hitData)
        if type(hitData) ~= "table" then return false end
        local hum = hitData[1]
        local part = hitData[2]
        if not hum or not hum:IsA("Humanoid") then return false end
        if hum.Health <= 0 then return false end
        local char = hum.Parent
        if not char or not char.Parent then return false end
        if _playerChars[char] then return false end
        if char:GetAttribute("FriendlyToFlare") == true then return false end
        local aimPart = getAimPart(char)
        if not aimPart then return false end
        if part == aimPart then return false end
        local cam = Workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position
        local normal = hitData[4]
        if typeof(normal) ~= "Vector3" then
            local fp = hitData[5]
            if typeof(fp) == "Vector3" then normal = (aimPart.Position - fp).Unit
            else normal = Vector3.new(0, 1, 0) end
        end
        hitData[2] = aimPart
        hitData[3] = aimPart.Position
        if camPos then hitData[5] = camPos end
        local root = hum.RootPart or char:FindFirstChild("HumanoidRootPart")
        if root then
            local cf = CFrame.new(aimPart.Position, aimPart.Position - normal * 1.5)
            hitData[7] = root.CFrame:ToObjectSpace(cf)
        end
        return true
    end
    local function installHook()
        if mbHookInstalled then return end
        mbHookInstalled = true
        if mbNetwork and type(mbNetwork.InvokeServer) == "function" then
            mbOrigInvoke = mbNetwork.InvokeServer
            local w = function(self, action, ...)
                if action == "hit" and magicBulletEnabled then
                    local args = {...}
                    forceAimPart(args[3])
                    return mbOrigInvoke(self, action, args[1], args[2], args[3])
                end
                return mbOrigInvoke(self, action, ...)
            end
            local ok = pcall(function() rawset(mbNetwork, "InvokeServer", w) end)
            if not ok then pcall(function() mbNetwork.InvokeServer = w end) end
        end
        if mbNetwork and type(mbNetwork.FireServer) == "function" then
            mbOrigFire = mbNetwork.FireServer
            local w = function(self, action, ...)
                if action == "fire" and magicBulletEnabled then
                    local args = {...}
                    local dirIdx = nil
                    for i = #args, 1, -1 do
                        if typeof(args[i]) == "Vector3" then dirIdx = i; break end
                    end
                    if dirIdx then
                        local tool = nil
                        for i = 1, #args do
                            if typeof(args[i]) == "Instance" and args[i]:IsA("Tool") then
                                tool = args[i]; break
                            end
                        end
                        local target = findTarget()
                        if target and target.aimPart then
                            local firePos = getFirePos(tool)
                            if firePos then
                                local nd = target.aimPart.Position - firePos
                                if nd.Magnitude > 0.1 then args[dirIdx] = nd.Unit end
                            end
                        end
                    end
                    return mbOrigFire(self, action, unpack(args))
                end
                return mbOrigFire(self, action, ...)
            end
            local ok = pcall(function() rawset(mbNetwork, "FireServer", w) end)
            if not ok then pcall(function() mbNetwork.FireServer = w end) end
        end
        if mbRaycastPath then
            local ok, rc = pcall(require, mbRaycastPath)
            if ok and type(rc) == "table" and type(rc.new) == "function" then
                mbRaycastModule = rc
                mbOrigRaycastNew = rc.new
                local wrapper = function(...)
                    local inst = mbOrigRaycastNew(...)
                    if type(inst) ~= "table" then return inst end
                    if rawget(inst, "__MB_Fire") then return inst end
                    local origFire = inst.Fire
                    if type(origFire) ~= "function" then return inst end
                    rawset(inst, "__MB_Fire", true)
                    rawset(inst, "Fire", function(self, origin, dir, velocity, behavior, ...)
                        if magicBulletEnabled then
                            pcall(function() applyExtraFilter(behavior) end)
                            if typeof(dir) == "Vector3" then
                                local target = findTarget()
                                if target and target.aimPart then
                                    local originV
                                    if typeof(origin) == "Vector3" then originV = origin
                                    elseif typeof(origin) == "Instance" then originV = origin.Position end
                                    if originV then
                                        local nd = target.aimPart.Position - originV
                                        if nd.Magnitude > 0.1 then dir = nd.Unit end
                                    end
                                end
                            end
                        end
                        return origFire(self, origin, dir, velocity, behavior, ...)
                    end)
                    return inst
                end
                local ok2 = pcall(function() rawset(rc, "new", wrapper) end)
                if not ok2 then pcall(function() rc.new = wrapper end) end
            end
        end
    end
    local function uninstallHook()
        if not mbHookInstalled then return end
        mbHookInstalled = false
        if mbNetwork and mbOrigInvoke then pcall(function() mbNetwork.InvokeServer = mbOrigInvoke end) end
        if mbNetwork and mbOrigFire then pcall(function() mbNetwork.FireServer = mbOrigFire end) end
        if mbRaycastModule and mbOrigRaycastNew then
            pcall(function() rawset(mbRaycastModule, "new", mbOrigRaycastNew) end)
        end
        mbOrigInvoke = nil
    end
    local function mbSetup()
        if magicBulletEnabled then
            ensureFov()
            updateFov()
            installHook()
        else
            uninstallHook()
            updateFov()
        end
    end

    local mbBtn, mbSetState = toggleMagic("启用魔法子弹", UDim2.new(0, 15, 0, 4), false, function(v)
        magicBulletEnabled = v
        if v then
            if _G._ExamFH and _G._ExamFH.forceOffFn then
                pcall(_G._ExamFH.forceOffFn)
            end
        end
        mbSetup()
    end, UDim2.new(0, 290, 0, 28))
    _G._ExamMB.magicOffFn = function()
        if mbSetState then pcall(function() mbSetState(false) end) end
    end

    toggleMagic("显示 3D 头框", UDim2.new(0, 15, 0, 36), false, function(v)
        mbShowBox = v
        if not v then destroyLockBB() end
    end, UDim2.new(0, 140, 0, 28))
    toggleMagic("掩体检测", UDim2.new(0, 165, 0, 36), false, function(v)
        mbRequireVisible = v
        if not v then
            cachedTarget = nil
            lastFindTick = 0
        end
    end, UDim2.new(0, 140, 0, 28))

    toggleMagic("穿透盾牌", UDim2.new(0, 15, 0, 68), true, function(v)
        pierceShieldEnabled = v
        shieldCache.tick = 0
        shieldCache.list = {}
    end, UDim2.new(0, 140, 0, 28))
    toggleMagic("穿透SIN头盔", UDim2.new(0, 165, 0, 68), true, function(v)
        pierceHelmetEnabled = v
        helmetCache.tick = 0
        helmetCache.list = {}
    end, UDim2.new(0, 140, 0, 28))

    toggleMagic("穿透队友", UDim2.new(0, 15, 0, 100), true, function(v)
        pierceTeammateEnabled = v
        teammateCache.tick = 0
        teammateCache.list = {}
    end, UDim2.new(0, 140, 0, 28))
    toggleMagic("穿透尸体", UDim2.new(0, 165, 0, 100), true, function(v)
        pierceCorpseEnabled = v
        corpseCache.tick = 0
        corpseCache.list = {}
    end, UDim2.new(0, 140, 0, 28))

    toggleMagic("显示FOV圈", UDim2.new(0, 15, 0, 132), true, function(v)
        mbShowFovCircle = v
        updateFov()
        updateLockBB()
    end, UDim2.new(0, 290, 0, 28))

    local charBox = Instance.new("Frame", magicPage)
    charBox.Size = UDim2.new(1, -30, 0, 150)
    charBox.Position = UDim2.new(0, 15, 0, 164)
    charBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    charBox.BorderSizePixel = 0
    Instance.new("UICorner", charBox).CornerRadius = UDim.new(0, 6)

    local bodyColor = Color3.fromRGB(60, 60, 70)
    local bodyColorSel = Color3.fromRGB(0, 200, 100)
    local figure = Instance.new("Frame", charBox)
    figure.Size = UDim2.new(0, 130, 1, 0)
    figure.Position = UDim2.new(0, 0, 0, 0)
    figure.BackgroundTransparency = 1

    local partBtns = {}
    local function makePartBtn(x, y, w, h)
        local b = Instance.new("TextButton", figure)
        b.Size = UDim2.new(0, w, 0, h)
        b.Position = UDim2.new(0, x, 0, y)
        b.BackgroundColor3 = bodyColor
        b.Text = ""
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Active = true
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
        return b
    end
    partBtns[1] = makePartBtn(47, 8, 36, 28)
    partBtns[2] = makePartBtn(47, 40, 36, 44)
    partBtns[3] = makePartBtn(29, 40, 16, 44)
    partBtns[4] = makePartBtn(85, 40, 16, 44)
    partBtns[5] = makePartBtn(47, 88, 16, 42)
    partBtns[6] = makePartBtn(67, 88, 16, 42)

    local rightInfo = Instance.new("Frame", charBox)
    rightInfo.Size = UDim2.new(1, -145, 1, 0)
    rightInfo.Position = UDim2.new(0, 140, 0, 0)
    rightInfo.BackgroundTransparency = 1
    local infoTitle = Instance.new("TextLabel", rightInfo)
    infoTitle.Size = UDim2.new(1, 0, 0, 18)
    infoTitle.Position = UDim2.new(0, 0, 0, 16)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "当前锁定"
    infoTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoTitle.Font = Enum.Font.Gotham
    infoTitle.TextSize = 11
    infoTitle.TextXAlignment = Enum.TextXAlignment.Left
    local infoValue = Instance.new("TextLabel", rightInfo)
    infoValue.Size = UDim2.new(1, 0, 0, 44)
    infoValue.Position = UDim2.new(0, 0, 0, 42)
    infoValue.BackgroundTransparency = 1
    infoValue.Text = "头部"
    infoValue.TextColor3 = Color3.fromRGB(0, 220, 120)
    infoValue.Font = Enum.Font.GothamBold
    infoValue.TextSize = 24
    infoValue.TextXAlignment = Enum.TextXAlignment.Left

    local function refreshAimSelection()
        for i, btn in ipairs(partBtns) do
            if i == mbAimPartIndex then
                btn.BackgroundColor3 = bodyColorSel
            else btn.BackgroundColor3 = bodyColor end
        end
        local info = AIM_PARTS[mbAimPartIndex]
        if info then infoValue.Text = info.label end
    end
    local function selectAim(index)
        if not AIM_PARTS[index] then return end
        mbAimPartIndex = index
        refreshAimSelection()
        destroyLockBB()
    end
    for i, btn in ipairs(partBtns) do
        bindTap(btn, function() selectAim(i) end)
    end
    refreshAimSelection()

    local fovLbl = Instance.new("TextLabel", magicPage)
    fovLbl.Size = UDim2.new(0, 36, 0, 22)
    fovLbl.Position = UDim2.new(0, 15, 0, 322)
    fovLbl.BackgroundTransparency = 1
    fovLbl.Text = "FOV:"
    fovLbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    fovLbl.Font = Enum.Font.Gotham; fovLbl.TextSize = 10
    fovLbl.TextXAlignment = Enum.TextXAlignment.Left
    local fovInput = Instance.new("TextBox", magicPage)
    fovInput.Size = UDim2.new(0, 42, 0, 22)
    fovInput.Position = UDim2.new(0, 48, 0, 322)
    fovInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    fovInput.TextColor3 = Color3.new(1, 1, 1)
    fovInput.Text = tostring(mbFovRadius)
    fovInput.Font = Enum.Font.Gotham; fovInput.TextSize = 10; fovInput.BorderSizePixel = 0
    Instance.new("UICorner", fovInput).CornerRadius = UDim.new(0, 4)
    fovInput.FocusLost:Connect(function()
        local v = tonumber(fovInput.Text)
        if v and v >= 20 and v <= 800 then
            mbFovRadius = v; fovInput.Text = tostring(v)
            updateFov()
        else fovInput.Text = tostring(mbFovRadius) end
    end)

    local bsLbl = Instance.new("TextLabel", magicPage)
    bsLbl.Size = UDim2.new(0, 32, 0, 22)
    bsLbl.Position = UDim2.new(0, 100, 0, 322)
    bsLbl.BackgroundTransparency = 1
    bsLbl.Text = "框:"
    bsLbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    bsLbl.Font = Enum.Font.Gotham; bsLbl.TextSize = 10
    bsLbl.TextXAlignment = Enum.TextXAlignment.Left
    local bsInput = Instance.new("TextBox", magicPage)
    bsInput.Size = UDim2.new(0, 42, 0, 22)
    bsInput.Position = UDim2.new(0, 130, 0, 322)
    bsInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    bsInput.TextColor3 = Color3.new(1, 1, 1)
    bsInput.Text = tostring(mbBBSizeStuds)
    bsInput.Font = Enum.Font.Gotham; bsInput.TextSize = 10; bsInput.BorderSizePixel = 0
    Instance.new("UICorner", bsInput).CornerRadius = UDim.new(0, 4)
    bsInput.FocusLost:Connect(function()
        local v = tonumber(bsInput.Text)
        if v and v >= 0.5 and v <= 5 then
            mbBBSizeStuds = v; bsInput.Text = tostring(v)
            if lockBB and lockBB.Parent then lockBB.Size = UDim2.new(v, 0, v, 0) end
        else bsInput.Text = tostring(mbBBSizeStuds) end
    end)

    local wdLbl = Instance.new("TextLabel", magicPage)
    wdLbl.Size = UDim2.new(0, 30, 0, 22)
    wdLbl.Position = UDim2.new(0, 182, 0, 322)
    wdLbl.BackgroundTransparency = 1
    wdLbl.Text = "距:"
    wdLbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    wdLbl.Font = Enum.Font.Gotham; wdLbl.TextSize = 10
    wdLbl.TextXAlignment = Enum.TextXAlignment.Left
    local wdInput = Instance.new("TextBox", magicPage)
    wdInput.Size = UDim2.new(0, 60, 0, 22)
    wdInput.Position = UDim2.new(0, 212, 0, 322)
    wdInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    wdInput.TextColor3 = Color3.new(1, 1, 1)
    wdInput.Text = tostring(mbWorldDistMax)
    wdInput.Font = Enum.Font.Gotham; wdInput.TextSize = 10; wdInput.BorderSizePixel = 0
    Instance.new("UICorner", wdInput).CornerRadius = UDim.new(0, 4)
    wdInput.FocusLost:Connect(function()
        local v = tonumber(wdInput.Text)
        if v and v >= 50 and v <= 20000 then
            mbWorldDistMax = v; wdInput.Text = tostring(v)
        else wdInput.Text = tostring(mbWorldDistMax) end
    end)

    RunService.RenderStepped:Connect(function()
        if not gui.Parent then return end
        updateLockBB()
    end)

    table.insert(cleanupFns, function()
        uninstallHook()
        destroyFov()
        destroyLockBB()
    end)
end

-- ============ 模块 18: 雷达页 ============
do
    local rpEnabled = false
    local rpUseHeartbeat = true
    local rpShowArrow = true
    local RP_SAMPLE_INTERVAL = 0.02
    local RP_RADIUS_IN = 150
    local RP_RADIUS_OUT = 200
    local RP_LAYER_THRESHOLD = 4
    local RP_DIFF_LAYER_TRANSPARENCY = 0.65
    local RP_EDGE_FADE = 1.25
    local RP_MAP_RADIUS = 0.43
    local RP_ARROW_DIST = 8
    local rpRadarRadius = RP_RADIUS_OUT
    local rpCacheInside = false
    local rpCacheInsideTick = 0
    local rpCacheRotLocked = false
    local rpCacheRotLockedTick = 0
    local rpDotPool = {}
    local function rpGetMC()
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return nil end
        local mm = pg:FindFirstChild("Minimap")
        if not mm then return nil end
        return mm:FindFirstChild("MinimapContainer")
    end
    local function rpGetHighlights()
        local mc = rpGetMC()
        local core = mc and mc:FindFirstChild("Core")
        return core and core:FindFirstChild("Highlights")
    end
    local function rpIsInsideFacilityCached(p)
        local now = tick()
        if now - rpCacheInsideTick < 3 then return rpCacheInside end
        rpCacheInsideTick = now
        local mmd = Workspace:FindFirstChild("MinimapData")
        local fiv = mmd and mmd:FindFirstChild("FacilityInteriorVolumes")
        if not fiv then rpCacheInside = false; return false end
        for _, part in ipairs(fiv:GetDescendants()) do
            if part:IsA("BasePart") then
                local rel = part.CFrame:PointToObjectSpace(p)
                local half = part.Size * 0.5
                if math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z then
                    rpCacheInside = true
                    return true
                end
            end
        end
        rpCacheInside = false
        return false
    end
    local function rpIsRotLockedCached()
        local now = tick()
        if now - rpCacheRotLockedTick < 3 then return rpCacheRotLocked end
        rpCacheRotLockedTick = now
        local cs = lp:FindFirstChild("ClientSettings")
        local g = cs and cs:FindFirstChild("Game")
        rpCacheRotLocked = (g and g:GetAttribute("MinimapRotationLocked") == true) or false
        return rpCacheRotLocked
    end
    local function rpGetHeading()
        local cam = Workspace.CurrentCamera
        if not cam then return Vector2.new(0, -1) end
        local look = cam.CFrame.LookVector
        local h = Vector2.new(look.X, look.Z)
        if h.Magnitude > 0.001 then return h.Unit end
        return Vector2.new(0, -1)
    end
    local function rpCollectEnemies()
        local list = {}
        for _, folderName in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                for _, model in ipairs(folder:GetChildren()) do
                    if model:IsA("Model") then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        local hrp = model:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 then
                            if not _playerChars[model] then
                                local n = model.Name
                                local c
                                if n == "SIN" or n == "Chimera" or n == "Gilbert"
                                   or n == "Mikhail" or n == "Leaper" then
                                    c = Color3.fromRGB(170, 0, 255)
                                elseif n == "RIF Miniboss" or n == "Dave" or n == "CombatEngineer" or n == "Vorax" then
                                    c = Color3.fromRGB(255, 140, 0)
                                else
                                    c = Color3.fromRGB(255, 0, 0)
                                end
                                list[#list+1] = { pos = hrp.Position, color = c, hrp = hrp }
                            end
                        end
                    end
                end
            end
        end
        local map = Workspace:FindFirstChild("Map")
        local btr = map and map:FindFirstChild("BTR-82 (BOSS)")
        if btr then
            local root = btr:FindFirstChild("BTRRoot")
            local pos = (root and root:IsA("BasePart") and root.Position) or (btr.PrimaryPart and btr.PrimaryPart.Position)
            if pos then list[#list+1] = { pos = pos, color = Color3.fromRGB(170, 0, 255), hrp = root } end
        end
        local drone = Workspace:FindFirstChild("BTRDrone")
        if drone then
            local hit = drone:FindFirstChild("DroneHitbox")
            local pos = (hit and hit:IsA("BasePart") and hit.Position) or (drone.PrimaryPart and drone.PrimaryPart.Position)
            if pos then list[#list+1] = { pos = pos, color = Color3.fromRGB(255, 80, 200), hrp = hit } end
        end
        return list
    end
    local function rpCalcPos(tp, pp, heading)
        local dx = tp.X - pp.X
        local dz = tp.Z - pp.Z
        local distWorld = math.sqrt(dx*dx + dz*dz)
        if distWorld > rpRadarRadius * RP_EDGE_FADE then return nil, false end
        local dxz = Vector2.new(dx, dz)
        local rot = Vector2.new(-heading.Y, heading.X)
        local proj = Vector2.new(dxz:Dot(rot), -dxz:Dot(heading)) * (RP_MAP_RADIUS / rpRadarRadius)
        local mag = proj.Magnitude
        local clamped = false
        if mag > RP_MAP_RADIUS then
            proj = proj.Unit * RP_MAP_RADIUS
            clamped = true
        end
        return UDim2.fromScale(0.5 + proj.X, 0.5 + proj.Y), clamped
    end
    local function rpCalcArrowScreenVec(enemyHrp, heading)
        if not enemyHrp then return 0, -1 end
        local lv = enemyHrp.CFrame.LookVector
        local lvx, lvz = lv.X, lv.Z
        local hx, hz = heading.X, heading.Y
        local sx = lvx * (-hz) + lvz * hx
        local sy = -(lvx * hx + lvz * hz)
        local m = math.sqrt(sx*sx + sy*sy)
        if m < 1e-4 then return 0, -1 end
        return sx / m, sy / m
    end
    local function rpEnsureDot(hl, i)
        if rpDotPool[i] and rpDotPool[i].Parent then return rpDotPool[i] end
        local d = Instance.new("Frame")
        d.Name = "SPRadar_Enemy"
        d.Size = UDim2.new(0, 7, 0, 7)
        d.AnchorPoint = Vector2.new(0.5, 0.5)
        d.BorderSizePixel = 0
        d.ZIndex = 50
        Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
        local s = Instance.new("UIStroke", d)
        s.Name = "Outline"
        s.Thickness = 1
        s.Transparency = 0.2
        s.Color = Color3.fromRGB(0, 0, 0)
        local core = Instance.new("Frame", d)
        core.Name = "Core"
        core.Size = UDim2.new(0.4, 0, 0.4, 0)
        core.AnchorPoint = Vector2.new(0.5, 0.5)
        core.Position = UDim2.new(0.5, 0, 0.5, 0)
        core.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        core.BackgroundTransparency = 0.5
        core.BorderSizePixel = 0
        Instance.new("UICorner", core).CornerRadius = UDim.new(1, 0)
        local ar = Instance.new("TextLabel", d)
        ar.Name = "ArrowLabel"
        ar.Size = UDim2.new(0, 10, 0, 10)
        ar.AnchorPoint = Vector2.new(0.5, 0.5)
        ar.Position = UDim2.new(0.5, 0, 0.5, 0)
        ar.BackgroundTransparency = 1
        ar.Text = "▲"
        ar.TextColor3 = Color3.fromRGB(255, 255, 255)
        ar.TextStrokeTransparency = 0.3
        ar.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        ar.Font = Enum.Font.GothamBold
        ar.TextSize = 12
        ar.Rotation = 0
        ar.ZIndex = 51
        ar.Visible = true
        d.Parent = hl
        rpDotPool[i] = d
        return d
    end
    local function rpClearDots()
        for _, d in pairs(rpDotPool) do
            if d and d.Parent then pcall(function() d:Destroy() end) end
        end
        rpDotPool = {}
    end
    local function rpUpdateOnce()
        local hl = rpGetHighlights()
        if not hl then return end
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local ppos = hrp.Position
        rpRadarRadius = rpIsInsideFacilityCached(ppos) and RP_RADIUS_IN or RP_RADIUS_OUT
        local locked = rpIsRotLockedCached()
        local heading = locked and Vector2.new(0, -1) or rpGetHeading()
        local enemies = rpCollectEnemies()
        for i, e in ipairs(enemies) do
            local dot = rpEnsureDot(hl, i)
            local pos, clamped = rpCalcPos(e.pos, ppos, heading)
            local dy = math.abs(e.pos.Y - ppos.Y)
            local isSameLayer = dy <= RP_LAYER_THRESHOLD
            local ar = dot:FindFirstChild("ArrowLabel")
            if ar then
                if rpShowArrow then
                    local sx, sy = rpCalcArrowScreenVec(e.hrp, heading)
                    local ox = sx * RP_ARROW_DIST
                    local oy = sy * RP_ARROW_DIST
                    ar.Position = UDim2.new(0.5, ox, 0.5, oy)
                    ar.Rotation = math.deg(math.atan2(sy, sx)) + 90
                    if not ar.Visible then ar.Visible = true end
                    if ar.TextColor3 ~= e.color then ar.TextColor3 = e.color end
                    local arrowTrans = isSameLayer and 0 or RP_DIFF_LAYER_TRANSPARENCY
                    if clamped then arrowTrans = math.max(arrowTrans, 0.35) end
                    if ar.TextTransparency ~= arrowTrans then ar.TextTransparency = arrowTrans end
                else
                    if ar.Visible then ar.Visible = false end
                end
            end
            if pos then
                dot.Position = pos
                if not dot.Visible then dot.Visible = true end
                if dot.BackgroundColor3 ~= e.color then dot.BackgroundColor3 = e.color end
                local wantSize = clamped and UDim2.new(0, 5, 0, 5) or UDim2.new(0, 7, 0, 7)
                if dot.Size ~= wantSize then dot.Size = wantSize end
                local wantTrans
                if isSameLayer then
                    wantTrans = clamped and 0.35 or 0
                else
                    wantTrans = RP_DIFF_LAYER_TRANSPARENCY
                    if clamped and wantTrans < 0.35 then wantTrans = 0.35 end
                end
                if dot.BackgroundTransparency ~= wantTrans then dot.BackgroundTransparency = wantTrans end
                local core = dot:FindFirstChild("Core")
                if core then
                    local coreTrans = wantTrans + 0.5 * (1 - wantTrans)
                    if core.BackgroundTransparency ~= coreTrans then core.BackgroundTransparency = coreTrans end
                end
            else
                if dot.Visible then dot.Visible = false end
            end
        end
        for i = #rpDotPool, #enemies + 1, -1 do
            local d = rpDotPool[i]
            if d and d.Parent and d.Visible then d.Visible = false end
        end
    end

    local rpLastHB = 0
    RunService.Heartbeat:Connect(function()
        if not rpEnabled or not rpUseHeartbeat then return end
        local now = tick()
        if now - rpLastHB < RP_SAMPLE_INTERVAL then return end
        rpLastHB = now
        pcall(rpUpdateOnce)
    end)
    spawn(function()
        while gui.Parent do
            if rpEnabled and not rpUseHeartbeat then
                pcall(rpUpdateOnce)
                wait(RP_SAMPLE_INTERVAL)
            else
                wait(0.05)
            end
        end
    end)

    local rbZoneBackup = {}
    local rbScriptBackup = {}
    local rbMainLoop = nil
    local rbBoostLabel = nil
    local RB_LABEL_GAP = 18
    local RB_FONT_SCALE = 1.15
    local RB_NORMAL_VISIBLE = {"Player","FieldOfView","Area","Coords","Core","Glow","MapState","TeamBuffLabel"}
    local RB_FORCE_HIDE = {"BrokenScreenOverlay","NoSignalOverlay","InterferanceIndicator"}
    local function rbGetZones()
        local mdata = Workspace:FindFirstChild("MinimapData")
        return mdata and mdata:FindFirstChild("NoSignalZones")
    end
    local function rbGetMC()
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return nil end
        local mm = pg:FindFirstChild("Minimap")
        if not mm then return nil end
        return mm:FindFirstChild("MinimapContainer")
    end
    local function rbNeutralize()
        local zones = rbGetZones()
        if not zones then return 0 end
        local count = 0
        for _, z in ipairs(zones:GetDescendants()) do
            if z:IsA("BasePart") then
                if not rbZoneBackup[z] then
                    rbZoneBackup[z] = { Size = z.Size, CFrame = z.CFrame, CanTouch = z.CanTouch, CanCollide = z.CanCollide }
                end
                pcall(function()
                    z.Size = Vector3.new(0.001, 0.001, 0.001)
                    z.CFrame = CFrame.new(99999, 99999, 99999)
                    z.CanTouch = false
                end)
                count = count + 1
            end
        end
        return count
    end
    local function rbRestoreZones()
        for part, props in pairs(rbZoneBackup) do
            pcall(function()
                if part and part.Parent then
                    part.Size = props.Size; part.CFrame = props.CFrame
                    part.CanTouch = props.CanTouch; part.CanCollide = props.CanCollide
                end
            end)
        end
        rbZoneBackup = {}
    end
    local function rbDisableFadeScripts()
        local mc = rbGetMC()
        if not mc then return 0 end
        local count = 0
        for _, d in ipairs(mc:GetDescendants()) do
            if d:IsA("LocalScript") or d:IsA("BaseScript") then
                if d:FindFirstAncestor("NoSignalOverlay") then
                    if not d.Disabled then
                        pcall(function() d.Disabled = true end)
                        rbScriptBackup[d] = true
                        count = count + 1
                    end
                end
            end
        end
        return count
    end
    local function rbRestoreScripts()
        for d in pairs(rbScriptBackup) do pcall(function() d.Disabled = false end) end
        rbScriptBackup = {}
    end
    local function rbFixMinimapUI()
        local mc = rbGetMC()
        if not mc then return 0 end
        local fixed = 0
        for _, name in ipairs(RB_NORMAL_VISIBLE) do
            local el = mc:FindFirstChild(name)
            if el and el:IsA("GuiObject") and not el.Visible then
                pcall(function() el.Visible = true end)
                fixed = fixed + 1
            end
        end
        for _, name in ipairs(RB_FORCE_HIDE) do
            local el = mc:FindFirstChild(name)
            if el and el:IsA("GuiObject") and el.Visible then
                pcall(function() el.Visible = false end)
                fixed = fixed + 1
            end
        end
        for _, name in ipairs({"UIStroke","Stroke2"}) do
            local s = mc:FindFirstChild(name)
            if s and s:IsA("UIStroke") then
                local c = s.Color
                if c.R > 0.6 and c.G < 0.4 and c.B < 0.4 then
                    pcall(function() s.Color = Color3.fromRGB(255, 255, 255) end)
                    fixed = fixed + 1
                end
            end
        end
        return fixed
    end
    local function rbCalcLabelPos(mc)
        local coordsEl = mc:FindFirstChild("Coords")
        if not coordsEl then return nil end
        local pos = coordsEl.Position; local sz = coordsEl.Size
        return UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + sz.Y.Offset + RB_LABEL_GAP)
    end
    local function rbShowLabel()
        local mc = rbGetMC()
        if not mc then return end
        if rbBoostLabel and rbBoostLabel.Parent == mc then return end
        local areaEl = mc:FindFirstChild("Area")
        local coordsEl = mc:FindFirstChild("Coords")
        if not areaEl or not areaEl:IsA("TextLabel") then return end
        if not coordsEl then return end
        local lbl = areaEl:Clone()
        lbl.Name = "SignalBoosterLabel"
        lbl.Text = "信号增幅器已启用"
        lbl.Visible = true; lbl.RichText = false
        local cC = coordsEl:FindFirstChildOfClass("UITextSizeConstraint")
        local lC = lbl:FindFirstChildOfClass("UITextSizeConstraint")
        if cC and lC and cC.MaxTextSize > 0 then
            lC.MaxTextSize = math.max(1, math.floor(cC.MaxTextSize * RB_FONT_SCALE))
        end
        local tp = rbCalcLabelPos(mc)
        if tp then lbl.Position = tp end
        lbl.ZIndex = areaEl.ZIndex
        lbl.Parent = mc
        rbBoostLabel = lbl
    end
    local function rbHideLabel()
        if rbBoostLabel then pcall(function() rbBoostLabel:Destroy() end); rbBoostLabel = nil end
    end
    local function rbStartLoop()
        if rbMainLoop then pcall(function() rbMainLoop:Disconnect() end); rbMainLoop = nil end
        rbMainLoop = spawn(function()
            while radarBoostEnabled and gui.Parent do
                local zones = rbGetZones()
                if zones then
                    for _, z in ipairs(zones:GetDescendants()) do
                        if z:IsA("BasePart") and z.Size.X > 0.01 then
                            pcall(function()
                                z.Size = Vector3.new(0.001, 0.001, 0.001)
                                z.CFrame = CFrame.new(99999, 99999, 99999)
                                z.CanTouch = false
                            end)
                        end
                    end
                end
                rbFixMinimapUI()
                if not rbBoostLabel or not rbBoostLabel.Parent then rbShowLabel() end
                local mc = rbGetMC()
                if mc and rbBoostLabel and rbBoostLabel.Parent == mc then
                    local tp = rbCalcLabelPos(mc)
                    if tp and rbBoostLabel.Position ~= tp then rbBoostLabel.Position = tp end
                    if not rbBoostLabel.Visible then rbBoostLabel.Visible = true end
                end
                wait(0.1)
            end
            rbMainLoop = nil
        end)
    end
    local function rbSetup()
        if radarBoostEnabled then
            rbNeutralize(); rbDisableFadeScripts(); rbFixMinimapUI(); rbShowLabel(); rbStartLoop()
        else
            if rbMainLoop then pcall(function() rbMainLoop:Disconnect() end); rbMainLoop = nil end
            rbRestoreZones(); rbRestoreScripts(); rbHideLabel()
        end
    end

    toggleRadar("启用（雷达探敌）", UDim2.new(0, 15, 0, 4), false, function(v)
        rpEnabled = v
        if not v then rpClearDots() end
    end, UDim2.new(0, 290, 0, 28))
    toggleRadar("高刷新率（可能会造成卡顿）", UDim2.new(0, 15, 0, 36), true, function(v) rpUseHeartbeat = v end, UDim2.new(0, 290, 0, 28))
    toggleRadar("显示敌人朝向箭头", UDim2.new(0, 15, 0, 68), true, function(v)
        rpShowArrow = v
        if not v then
            for _, d in pairs(rpDotPool) do
                if d and d.Parent then
                    local ar = d:FindFirstChild("ArrowLabel")
                    if ar then ar.Visible = false end
                end
            end
        end
    end, UDim2.new(0, 290, 0, 28))
    toggleRadar("雷达信号增幅器", UDim2.new(0, 15, 0, 100), false, function(v)
        radarBoostEnabled = v
        rbSetup()
    end, UDim2.new(0, 290, 0, 28))

    local rpTip = Instance.new("TextLabel", radarPage)
    rpTip.Size = UDim2.new(1, -30, 0, 60)
    rpTip.Position = UDim2.new(0, 15, 0, 140)
    rpTip.BackgroundTransparency = 1
    rpTip.Text = "箭头贴在圆点外沿  |  不同层半透明  |  超出边缘钉住"
    rpTip.TextColor3 = Color3.fromRGB(150, 150, 150)
    rpTip.Font = Enum.Font.Gotham
    rpTip.TextSize = 10
    rpTip.TextXAlignment = Enum.TextXAlignment.Left
    rpTip.TextYAlignment = Enum.TextYAlignment.Top
    rpTip.TextWrapped = true

    table.insert(cleanupFns, function()
        rpEnabled = false
        rpClearDots()
        radarBoostEnabled = false
        if rbMainLoop then pcall(function() rbMainLoop:Disconnect() end) end
        rbRestoreZones(); rbRestoreScripts(); rbHideLabel()
    end)
end

-- ============ 折叠 ============
local function setCollapsed(v)
    isCollapsed = v
    local L = LAYOUT[currentLayout]
    if v then
        main.Size = UDim2.new(0, L.W, 0, L.TitleH)
        for _, child in ipairs(main:GetChildren()) do
            if child ~= titleBar and child:IsA("GuiObject") then child.Visible = false end
        end
        collapseBtn.Text = "▼"
    else
        main.Size = UDim2.new(0, L.W, 0, getTabHeight())
        for _, child in ipairs(main:GetChildren()) do
            if child ~= titleBar and child:IsA("GuiObject")
               and child ~= basePage and child ~= magicPage and child ~= radarPage then
                child.Visible = true
            end
        end
        basePage.Visible = (currentTab == "base")
        magicPage.Visible = (currentTab == "magic")
        radarPage.Visible = (currentTab == "radar")
        collapseBtn.Text = "▲"
    end
end
bindTap(collapseBtn, function() setCollapsed(not isCollapsed) end)

bindTap(closeBtn, function()
    infStaminaEnabled = false
    espEnabled = false
    headHitboxEnabled = false
    autoInteractEnabled = false
    forceResetEnabled = false
    slideEnabled = false
    slideSteerEnabled = false
    nvgEnabled = false
    elephantImmuneEnabled = false
    radarBoostEnabled = false
    recoilEnabled = false
    muzzleEnabled = false
    magicBulletEnabled = false
    forceHeadshotEnabled = false
    chatForceEnabled = false
    autoQTEEnabled = false
    shotgunNoPumpEnabled = false
    shieldFixEnabled = false
    shieldVMEnabled = false
    noCDEnabled = false
    noCDActiveUntil = 0
    wait(0.7)
    for _, fn in ipairs(cleanupFns) do pcall(fn) end
    cleanupFns = {}
    pcall(function() StarterGui:SetCore("ResetButtonCallback", false) end)
    _G.ExaminationUI = nil
    gui:Destroy()
    print("[Exam] v16.4.9 已完全卸载")
end)

print("[Exam] v16.4.9 已加载（布局=" .. currentLayout .. "）")

-- ===END OF SCRIPT===
