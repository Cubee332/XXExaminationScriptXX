-- 此脚本使用AI生成
-- 因使用混淆加密会导致手机用户无法正常使用所以没有使用混淆加密
-- 请不要拿去缝合 此脚本永久免费
-- 若随意缝合和偷源码自称是自制的该脚本会进行删库处理并停止对外更新( AI写的史山代码你也要？？？？)
-- 倒卖脚本私冯！！！

--!nolint
-- Examination v1.2.5  卸载脚本加退出动画；自动肘击范围；圆环改用射线贴地
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")
local BadgeService = game:GetService("BadgeService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer

if _G._ExamLastCleanup then pcall(_G._ExamLastCleanup); _G._ExamLastCleanup = nil end
_G._ExamSetters = {}
_G._ExamStates = {}

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
local mbTargetMode = 1

local shootVisualEnabled = false
local tracerEnabled = true
local hitMarkerEnabled = true
local tracerColorIdx = 3
local tracerDurationSec = 1
local hmColorIdx = 3
local hmDurationSec = 1
local hmSizeIdx = 1

local AI_CONTAINERS = {"Characters", "Reactor1", "Reactor2", "Reactor3", "Reactor4"}

-- 只能被 AT-7 击毁的 BTR 载具：枪械打不到，锁定与雷达都不纳入。
-- 无人机不在此列，正常参与锁定。
local VEHICLE_NAMES = {
    ["BTR-82 (BOSS)"] = true,
}
local function isVehicle(m)
    return m ~= nil and VEHICLE_NAMES[m.Name] == true
end
local SHOTGUN_PUMP_IDS = {
    ["115903749552317"]=true,["80315455447277"]=true,["89272072134105"]=true,
    ["96917301511774"]=true,["135326741887023"]=true,["116710355675938"]=true,
}
local SHOTGUN_SPEED_MULT = 1000

local function batchScan(list, callback, batchSize)
    batchSize = batchSize or 200
    spawn(function()
        local batch = {}
        for _, d in ipairs(list) do
            table.insert(batch, d)
            if #batch >= batchSize then
                for _, item in ipairs(batch) do pcall(callback, item) end
                batch = {}
                RunService.Heartbeat:Wait()
            end
        end
        for _, item in ipairs(batch) do pcall(callback, item) end
    end)
end

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

-- ============================================================
-- 清理
-- ============================================================
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
    for _, k in ipairs({"_NR6UI","_MB2UI","_FH2UI","_MZ8UI","_MZ9UI","_MZ10UI","_MZ11UI","MBT2_UI","MBT2_FovCircle","MB_TargetLock","SPRadar_UI","ExamAutoQTE","ExamQTEProbe","ExamQTEUIProbe","ExamNetHook","ExamQTEDecomp","ExamHelmetTest","ExamR8Probe","ExamR8Decomp","ExamR8Capture","ExamR8v11","ExamR8v12","ExamR8v13","ExamR8v14","ExamR8v15","ExamShotgunTest","ExamMuzzle","ExamCanShoot","NewShotgunTest","SlideSteer","ExamRadiusTip"}) do
        if _G[k] and _G[k].Parent then pcall(function() _G[k]:Destroy() end) end
        _G[k] = nil
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
        _G._shieldFixTargetTrySlide = nil; _G._shieldFixOrigTrySlide = nil
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
    if map then local btr = map:FindFirstChild("BTR-82 (BOSS)"); if btr then cleanESP(btr) end end
    cleanESP(Workspace:FindFirstChild("BTRDrone"))
    for _, fn in ipairs(AI_CONTAINERS) do
        local f = Workspace:FindFirstChild(fn)
        if f then for _, c in ipairs(f:GetChildren()) do cleanESP(c) end end
    end
    do
        local pg = lp:FindFirstChild("PlayerGui")
        local mm = pg and pg:FindFirstChild("Minimap")
        local mc = mm and mm:FindFirstChild("MinimapContainer")
        local core = mc and mc:FindFirstChild("Core")
        local hl = core and core:FindFirstChild("Highlights")
        if hl then
            for _, c in ipairs(hl:GetChildren()) do
                if c.Name == "SPRadar_Enemy" then pcall(function() c:Destroy() end) end
            end
        end
    end
    local char = lp.Character
    if char and _G._InfNVG_AddedCloaker then
        local c = char:FindFirstChild("IsCloaker"); if c then c:Destroy() end
    end
    for _, k in ipairs({"_InfNVG_TextSignalConn","_InfNVG_BarSignalConn","_InfNVG_Loop"}) do
        if _G[k] then pcall(function() _G[k]:Disconnect() end); _G[k] = nil end
    end
    _G._InfNVG_AddedCloaker = nil; _G._InfNVG_OrigPercentText = nil; _G._InfNVG_OrigBarSize = nil
    if _G._ElephantImmune_Loop then pcall(function() _G._ElephantImmune_Loop:Disconnect() end); _G._ElephantImmune_Loop = nil end
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
                    p.Size = orig.Size; p.CFrame = orig.CFrame
                    p.CanTouch = orig.CanTouch; p.CanCollide = orig.CanCollide
                end)
            end
        end
        _G._KillPartBackup = nil
    end
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
    for _, n in ipairs({"ExamRadiusRing", "ExamRadiusFace"}) do
        for _, d in ipairs(Workspace:GetChildren()) do
            if d.Name == n then pcall(function() d:Destroy() end) end
        end
    end
    for _, d in ipairs(Workspace:GetChildren()) do
        if d.Name == "ExamTracer_Visual" then pcall(function() d:Destroy() end) end
    end
    if _G.ExamRadiusTip and _G.ExamRadiusTip.Parent then pcall(function() _G.ExamRadiusTip:Destroy() end) end
    _G.ExamRadiusTip = nil
    if _G.ControlPanelUI and _G.ControlPanelUI.Parent then
        pcall(function() _G.ControlPanelUI:Destroy() end)
    end
    _G.ControlPanelUI = nil
    local _pg = lp:FindFirstChild("PlayerGui")
    if _pg then
        local _tb = _pg:FindFirstChild("TopbarStandard")
        if _tb then
            local _h = _tb:FindFirstChild("Holders")
            local _l = _h and _h:FindFirstChild("Left")
            if _l then
                for _, _n in ipairs({"ControlPanelBtn", "TrialBtn"}) do
                    local _old = _l:FindFirstChild(_n)
                    if _old then pcall(function() _old:Destroy() end) end
                end
            end
        end
    end
    _G._ExamSetters = {}
    _G._ExamStates = {}
    _G._CP_RefreshFns = {}
end
pcall(safeCleanup)

_G._ExamLastCleanup = function()
    for _, fn in ipairs(cleanupFns) do pcall(fn) end
    if _G._ExamMB and _G._ExamMB.magicOffFn then pcall(_G._ExamMB.magicOffFn) end
    if _G._ExamFH and _G._ExamFH.forceOffFn then pcall(_G._ExamFH.forceOffFn) end
    if _G.ControlPanelUI and _G.ControlPanelUI.Parent then
        pcall(function() _G.ControlPanelUI:Destroy() end)
    end
    _G.ControlPanelUI = nil
    local _pg = lp:FindFirstChild("PlayerGui")
    if _pg then
        local _tb = _pg:FindFirstChild("TopbarStandard")
        if _tb then
            local _h = _tb:FindFirstChild("Holders")
            local _l = _h and _h:FindFirstChild("Left")
            if _l then
                for _, _n in ipairs({"ControlPanelBtn", "TrialBtn"}) do
                    local _old = _l:FindFirstChild(_n)
                    if _old then pcall(function() _old:Destroy() end) end
                end
            end
        end
    end
    if _G.ExaminationUI and _G.ExaminationUI.Parent then
        pcall(function() _G.ExaminationUI:Destroy() end)
    end
    _G.ExaminationUI = nil
    if _G.ExamRadiusTip and _G.ExamRadiusTip.Parent then
        pcall(function() _G.ExamRadiusTip:Destroy() end)
    end
    _G.ExamRadiusTip = nil
    _G._ExamSetters = {}
    _G._ExamStates = {}
    _G._CP_RefreshFns = {}
    cleanupFns = {}
end

local function detectLayout()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then return "mobile" end
    return "desktop"
end
local currentLayout = detectLayout()

-- ============================================================
-- 基础设施
-- ============================================================
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

-- ============================================================
-- UI 库：CDMUI
-- ============================================================
local CDMUI
do
    local errs = {}

    -- 1) 优先读本地 CDMUI.lua（调试时改完立刻生效，不受 CDN 缓存影响）
    local ok1, res1 = pcall(function()
        local src = readfile("CDMUI.lua")
        return loadstring(src)()
    end)
    if ok1 and type(res1) == "table" and res1.Create then
        CDMUI = res1
    else
        table.insert(errs, "local: " .. tostring(res1))
    end

    -- 2) 本地没有则走网络
    if not CDMUI then
        local urls = {
            "https://raw.githubusercontent.com/Cubee332/CDMUI/main/CDMUI.lua",
            "https://cdn.jsdelivr.net/gh/Cubee332/CDMUI@main/CDMUI.lua",
        }
        for _, url in ipairs(urls) do
            local ok, res = pcall(function()
                local chunk = loadstring(game:HttpGet(url))
                if not chunk then error("loadstring failed") end
                return chunk()
            end)
            if ok and type(res) == "table" and res.Create then
                CDMUI = res
                break
            end
            table.insert(errs, url .. " -> " .. tostring(res))
        end
    end

    if not CDMUI then
        error("[Examination] CDMUI 加载失败: " .. table.concat(errs, " | "))
    end
end

local uiParent = CoreGui
local _hiddenDock = Instance.new("Frame")
_hiddenDock.Name = "ExamHiddenDock"
_hiddenDock.Size = UDim2.fromOffset(1, 1)
_hiddenDock.BackgroundTransparency = 1
_hiddenDock.Visible = false
_hiddenDock.Parent = uiParent

local basePage  = _hiddenDock
local magicPage = _hiddenDock
local radarPage = _hiddenDock
local main      = _hiddenDock

-- 模块里到处用 `if not gui.Parent then return end` 判断界面是否存活，
-- 在 win 创建后指向 CDMUI 面板
local gui = _hiddenDock

local function reg(g, key) --[[ 兼容旧 UI 的位置登记接口，新 UI 不需要 ]] return g end

_G._ExamFH = _G._ExamFH or {}
_G._ExamFH.forceOffFn = nil
_G._ExamMB = _G._ExamMB or {}
_G._ExamMB.magicOffFn = nil
_G._CP_RefreshFns = _G._CP_RefreshFns or {}

local cdLabel = Instance.new("TextLabel")
cdLabel.Name = "cdLabel"
cdLabel.Size = UDim2.fromOffset(1, 1)
cdLabel.BackgroundTransparency = 1
cdLabel.TextTransparency = 1
cdLabel.Parent = _hiddenDock

-- ============================================================
-- 回调注册表
-- ============================================================
local Callbacks = {}

-- UI 状态同步钩子（win 创建后指向 CB，保证 UI 与模块状态一致）
local CALLBACK_SINK = nil

-- 中文 label -> 正确状态 key 的映射
-- toggleMagic / toggleRadar 的调用签名里第二参是 UDim2 而不是 key，
-- 会导致状态被写进中文 label 里，这里统一映射回来
local TOGGLE_KEY_MAP = {
    ["启用魔法子弹"] = "magicBullet",
    ["显示 3D 头框"] = "mbShowBox",
    ["掩体检测"] = "mbRequireVisible",
    ["穿透盾牌"] = "pierceShield",
    ["穿透SIN头盔"] = "pierceHelmet",
    ["穿透队友"] = "pierceTeammate",
    ["穿透尸体"] = "pierceCorpse",
    ["显示FOV圈"] = "mbShowFovCircle",
    ["未锁定不穿透"] = "mbOnlyWhenLocked",
    ["启用（雷达探敌）"] = "radar",
    ["高刷新率（可能会造成卡顿）"] = "radarFast",
    ["显示敌人朝向箭头"] = "radarArrow",
    ["雷达信号增幅器"] = "radarBoost",
}

local function mkToggleRegistrar(group)
    return function(text, posSpec, default, callback, sizeSpec)
        local key = (type(posSpec) == "string") and posSpec or (TOGGLE_KEY_MAP[text] or text)
        Callbacks[key] = callback

        local state = default and true or false
        _G._ExamSetters[key] = function(nv)
            nv = nv and true or false
            -- 不要因为状态相同就跳过：外部把 _ExamStates 改成和内部 state 不一致时，
            -- 再点一次必须能真正跑一遍 setup，否则开关会卡死
            state = nv
            _G._ExamStates[key] = state
            if CALLBACK_SINK then pcall(CALLBACK_SINK, key, state) end
            if callback then pcall(callback, state) end
        end
        _G._ExamStates[key] = state

        local btn = Instance.new("TextButton")
        btn.Visible = false
        btn.Size = UDim2.fromOffset(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = _hiddenDock

        return btn, _G._ExamSetters[key]
    end
end

local toggleBase  = mkToggleRegistrar("base")
local toggleMagic = mkToggleRegistrar("magic")
local toggleRadar = mkToggleRegistrar("radar")


-- ============ 模块 0: 硬直免疫 ============
do
    local staggerEnabled = false
    local lockLoop = nil

    -- 把 StaggerImmune 一直保持在 true
    -- 这个属性客户端可改，实测有效：受击不僵直、不被击退
    local function tick()
        if not staggerEnabled then return end
        local char = lp.Character
        if not char then return end
        pcall(function()
            if char:GetAttribute("StaggerImmune") ~= true then
                char:SetAttribute("StaggerImmune", true)
            end
        end)
    end

    local function setup()
        if lockLoop then lockLoop:Disconnect(); lockLoop = nil end
        if not staggerEnabled then
            local char = lp.Character
            if char then pcall(function() char:SetAttribute("StaggerImmune", false) end) end
            return
        end
        tick()
        lockLoop = RunService.Heartbeat:Connect(function()
            if not staggerEnabled then return end
            tick()
        end)
    end

    _G._ExamSetters.staggerImmune = function(v)
        staggerEnabled = v and true or false
        _G._ExamStates.staggerImmune = staggerEnabled
        setup()
    end
    _G._ExamStates.staggerImmune = false

    lp.CharacterAdded:Connect(function()
        task.wait(1)
        if staggerEnabled then setup() end
    end)

    table.insert(cleanupFns, function()
        staggerEnabled = false
        if lockLoop then pcall(function() lockLoop:Disconnect() end) end
    end)
end

-- ============ 模块 0.15: 镜头防抖 ============
-- 游戏在跑动/冲刺/受击时会调用几个 Shake 函数让镜头晃，
-- 这里把它们 hook 成空函数。关掉时还原。
do
    local hooked = {}

    local NAMES = { doshake = true, startshake = true, shakeonce = true, shakesustain = true }

    local function install()
        if #hooked > 0 then return end
        if not (getgc and hookfunction) then return end
        pcall(function()
            for _, f in pairs(getgc(true)) do
                if type(f) == "function" then
                    local ok, info = pcall(getinfo, f)
                    if ok and info and NAMES[(info.name or ""):lower()] then
                        local ok2 = pcall(function()
                            local orig = f
                            hookfunction(f, function() return end)
                            table.insert(hooked, { fn = f, orig = orig })
                        end)
                        if ok2 then
                            -- 记录原始函数用于还原
                            hooked[#hooked].orig = f
                        end
                    end
                end
            end
        end)
    end

    _G._ExamSetters.noShake = function(v)
        _G._ExamStates.noShake = v and true or false
        if v then
            install()
        else
            -- 还原：hookfunction 反向调用拿不到原函数时只能跳过
            hooked = {}
        end
    end
    _G._ExamStates.noShake = false

    table.insert(cleanupFns, function()
        hooked = {}
    end)
end

-- ============ 模块 0.2: 假身动作 ============
-- 旋转：BodyAngularVelocity（同 IY 的 spin）
-- 点头：改 Motor6D.Transform，叠加在游戏自己的 C0 之上，不会被覆盖
do
    local spinObj = nil

    -- 记下角色原始的 Neck C0/C1，供复原用
    local origNeckC0 = nil
    local origNeckC1 = nil
    local origNeckFor = nil
    local function snapshotNeck()
        local c = lp.Character
        if not c then return end
        local torso = c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
        local neck = torso and torso:FindFirstChild("Neck")
        if not neck or not neck:IsA("Motor6D") then return end
        if origNeckFor == neck then return end
        origNeckFor = neck
        origNeckC0 = neck.C0
        origNeckC1 = neck.C1
    end
    task.spawn(function()
        task.wait(2)
        snapshotNeck()
    end)
    lp.CharacterAdded:Connect(function()
        task.wait(2)
        origNeckFor = nil
        snapshotNeck()
    end)

    local nodEnabled = false
    local nodMode = 1      -- 1=低头固定 2=抬头固定 3=来回切
    local nodSwapped = false
    local nodTimer = 0
    local nodConn = nil

    ------------------------------------------------------------------
    -- 旋转
    ------------------------------------------------------------------
    local function removeSpin()
        if spinObj then
            pcall(function() spinObj:Destroy() end)
            spinObj = nil
        end
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, c in ipairs(hrp:GetChildren()) do
                if c.Name == "ExamSpinning" then pcall(function() c:Destroy() end) end
            end
        end
    end

    local function setSpin(speed)
        removeSpin()
        if not speed or speed == 0 then return end
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local spin = Instance.new("BodyAngularVelocity")
        spin.Name = "ExamSpinning"
        spin.MaxTorque = Vector3.new(0, math.huge, 0)
        spin.AngularVelocity = Vector3.new(0, speed, 0)
        spin.Parent = hrp
        spinObj = spin
    end

    _G._ExamSetters.spin = function(v)
        _G._ExamStates.spin = v and true or false
        if v then
            setSpin(tonumber(_G._ExamStates.spinSpeed) or 20)
        else
            removeSpin()
        end
    end
    _G._ExamStates.spin = false

    _G._ExamSetters.spinSpeed = function(v)
        local n = tonumber(v)
        if not n then return end
        n = math.clamp(n, 0, 500)
        _G._ExamStates.spinSpeed = n
        if _G._ExamStates.spin then setSpin(n) end
    end
    _G._ExamStates.spinSpeed = 20

    ------------------------------------------------------------------
    -- 点头
    -- 游戏每帧重写 Neck.C0，所以只能改 Transform。
    -- 低头固定 / 抬头固定 / 两者来回快速切换。
    ------------------------------------------------------------------
    local DIP = math.rad(70)     -- 低头角度

    local function findNeck(char)
        if not char then return nil end
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        local neck = torso and torso:FindFirstChild("Neck")
        if neck and neck:IsA("Motor6D") then return neck end
        return nil
    end

    local function resetNod()
        local char = lp.Character
        if not char then return end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Motor6D") then
                pcall(function() d.Transform = CFrame.identity end)
            end
        end
        -- C0 交还给游戏（游戏自己会重写，这里清掉我们的锁定即可）
        nodNeckRef = nil
        nodBasePos = nil
    end

    local function stopNod()
        if nodConn then nodConn:Disconnect(); nodConn = nil end
        nodSwapped = false
        nodTimer = 0
        resetNod()
    end

    -- 关键：游戏每帧重写 Neck.C0 的旋转部分，只写 Transform 会被压制。
    -- 所以要同时锁住 C0（保留位置、朝向归零）和 Transform（我们设的角度）。
    local nodNeckRef = nil
    local nodBasePos = nil

    -- 实测结论：这个游戏里 Motor6D.Transform 不起作用，
    -- 只有直接写 Neck.C0 才能改头部朝向。
    -- C0 角度 0 => 脸朝下；180 => 脸朝上。
    local LOOK_DOWN = 0
    local LOOK_UP = 180

    local function applyNod(dt)
        local char = lp.Character
        if not char then return end
        local neck = findNeck(char)
        if not neck then return end

        if nodNeckRef ~= neck or not nodBasePos then
            nodNeckRef = neck
            nodBasePos = neck.C0.Position
        end

        local deg
        if nodMode == 1 then
            deg = LOOK_DOWN
        elseif nodMode == 2 then
            deg = LOOK_UP
        else
            nodTimer = nodTimer + dt
            if nodTimer >= 0.18 then
                nodTimer = 0
                nodSwapped = not nodSwapped
            end
            deg = nodSwapped and LOOK_UP or LOOK_DOWN
        end

        pcall(function()
            neck.C0 = CFrame.new(nodBasePos) * CFrame.Angles(math.rad(deg), 0, 0)
            neck.Transform = CFrame.identity
        end)
    end

    _G._ExamSetters.nod = function(v)
        if v and _G._ExamStates.headSpin then
            _G._ExamSetters.headSpin(false)
            local fn = _G._ExamSyncCheckbox and _G._ExamSyncCheckbox["headSpin"]
            if fn then pcall(fn, false) end
        end
        nodEnabled = v and true or false
        _G._ExamStates.nod = nodEnabled
        if not nodEnabled then
            stopNod()
            return
        end
        if nodConn then return end
        nodSwapped = false
        nodTimer = 0
        nodConn = RunService.Heartbeat:Connect(function(dt)
            if not nodEnabled then return end
            applyNod(dt)
        end)
    end
    _G._ExamStates.nod = false

    _G._ExamSetters.nodMode = function(v)
        local n = tonumber(v)
        if not n then
            if v == "低头" then n = 1
            elseif v == "抬头" then n = 2
            elseif v == "低头+抬头" then n = 3 end
        end
        if not n or n < 1 or n > 3 then return end
        nodMode = n
        _G._ExamStates.nodMode = n
        nodSwapped = false
        nodTimer = 0
    end
    _G._ExamStates.nodMode = 1

    ------------------------------------------------------------------
    -- 头部旋转（XYZ 三轴独立）
    -- 基准 = 平视姿态，再叠三轴角度。
    -- 和抬头低头互斥，开这个会把 nod 关掉。
    local headSpinOn = false
    local hxSpeed, hySpeed, hzSpeed = 0, 120, 0    -- 度/秒
    local hxAng, hyAng, hzAng = 0, 0, 0
    local headSpinConn = nil
    local headBasePos = nil
    local headNeckRef = nil
    local headLastT = nil

    local function stopHeadSpin()
        if headSpinConn then headSpinConn:Disconnect(); headSpinConn = nil end
        headSpinOn = false
        hxAng, hyAng, hzAng = 0, 0, 0
        headLastT = nil
        headStartT = nil
        headNeckRef = nil
        headBasePos = nil
    end

    -- 用绝对时间算角度，避免逐帧累加误差
    local headStartT = nil

    local function headTickAbs()
        local char = lp.Character
        if not char then return end
        local neck = findNeck(char)
        if not neck then return end

        if headNeckRef ~= neck or not headBasePos then
            headNeckRef = neck
            headBasePos = neck.C0.Position
        end
        if not headStartT then headStartT = os.clock() end

        local el = os.clock() - headStartT
        -- 单位换算：填 10 ≈ 573 度/秒
        local hx = (hxSpeed * 57.3 * el) % 360
        local hy = (hySpeed * 57.3 * el) % 360
        local hz = (hzSpeed * 57.3 * el) % 360

        pcall(function()
            neck.C0 = CFrame.new(headBasePos)
                * CFrame.Angles(0, math.rad(hy), 0)
                * CFrame.Angles(math.rad(90 + hx), 0, math.rad(hz))
            neck.Transform = CFrame.identity
        end)
    end

    _G._ExamSetters.headSpin = function(v)
        if v then
            -- 互斥：先把抬头低头关掉（逻辑 + 勾选框一起关）
            if _G._ExamStates.nod then
                _G._ExamSetters.nod(false)
                syncBox("nod", false)
            end
            headSpinOn = true
            _G._ExamStates.headSpin = true
            if headSpinConn then return end
            hxAng, hyAng, hzAng = 0, 0, 0
            headSpinConn = RunService.RenderStepped:Connect(function()
                if not headSpinOn then return end
                headTickAbs()
            end)
        else
            stopHeadSpin()
            _G._ExamStates.headSpin = false
        end
    end
    _G._ExamStates.headSpin = false

    -- 三轴各自的速度（绝对值），方向由 headSpinDir 统一控制
    local hxAbs, hyAbs, hzAbs = 0, 10, 0
    local spinDir = 1        -- 1=顺时针 -1=逆时针

    local function applyDirs()
        hxSpeed = hxAbs * spinDir
        hySpeed = hyAbs * spinDir
        hzSpeed = hzAbs * spinDir
    end

    local function setAxisSpeed(axis, v)
        local n = tonumber(v)
        if not n then return end
        n = math.clamp(n, 0, 50)
        if axis == "X" then hxAbs = n; _G._ExamStates.headSpinX = n
        elseif axis == "Y" then hyAbs = n; _G._ExamStates.headSpinY = n
        else hzAbs = n; _G._ExamStates.headSpinZ = n end
        applyDirs()
    end

    _G._ExamSetters.headSpinX = function(v) setAxisSpeed("X", v) end
    _G._ExamSetters.headSpinY = function(v) setAxisSpeed("Y", v) end
    _G._ExamSetters.headSpinZ = function(v) setAxisSpeed("Z", v) end
    _G._ExamStates.headSpinX = 0
    _G._ExamStates.headSpinY = 10
    _G._ExamStates.headSpinZ = 0

    _G._ExamSetters.headSpinDir = function(v)
        if v == 1 or v == "顺时针" then spinDir = 1
        elseif v == 2 or v == "逆时针" then spinDir = -1
        else return end
        _G._ExamStates.headSpinDir = (spinDir > 0) and 1 or 2
        applyDirs()
    end
    _G._ExamStates.headSpinDir = 1
    applyDirs()

    lp.CharacterAdded:Connect(function()
        task.wait(1)
        if _G._ExamStates.spin then
            setSpin(tonumber(_G._ExamStates.spinSpeed) or 20)
        end
        if _G._ExamStates.nod then
            _G._ExamSetters.nod(false)
            task.wait(0.1)
            _G._ExamSetters.nod(true)
        end
    end)

    table.insert(cleanupFns, function()
        nodEnabled = false
        if nodConn then pcall(function() nodConn:Disconnect() end); nodConn = nil end
        headSpinOn = false
        if headSpinConn then pcall(function() headSpinConn:Disconnect() end); headSpinConn = nil end
        removeSpin()
        stopNod()

        -- 头部姿态是我们直接写 Neck.C0 改的，
        -- 必须复位，否则重载后头还歪着。
        local c = lp.Character
        if c then
            local torso = c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
            local neck = torso and torso:FindFirstChild("Neck")
            if neck and neck:IsA("Motor6D") then
                pcall(function()
                    neck.Transform = CFrame.identity
                    if origNeckC0 then neck.C0 = origNeckC0 end
                    if origNeckC1 then neck.C1 = origNeckC1 end
                end)
            end
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("Motor6D") then
                    pcall(function() d.Transform = CFrame.identity end)
                end
            end
        end
    end)
end

-- ============ 模块 0.1: 视角解锁 ============
-- 第一人称 / 第三人称自由切
-- 切到第三人称时放开 CameraMode；切回第一人称恢复游戏原本的锁定
do
    local unlocked = false
    local backup = nil

    local function setUnlock(on)
        unlocked = on and true or false
        if unlocked then
            if not backup then
                backup = {
                    camMode = lp.CameraMode,
                    camMax = lp.CameraMaxZoomDistance,
                    camMin = lp.CameraMinZoomDistance,
                }
            end
            pcall(function()
                lp.CameraMode = Enum.CameraMode.Classic
                lp.CameraMaxZoomDistance = 30
                lp.CameraMinZoomDistance = 4
            end)
        else
            if backup then
                pcall(function()
                    lp.CameraMode = backup.camMode
                    lp.CameraMaxZoomDistance = backup.camMax
                    lp.CameraMinZoomDistance = backup.camMin
                end)
                backup = nil
            end
        end
    end

    local thirdConn = nil
    _G._ExamSetters.thirdPerson = function(v)
        if thirdConn then thirdConn:Disconnect(); thirdConn = nil end
        if not v then
            setUnlock(false)
            _G._ExamStates.thirdPerson = false
            return
        end
        setUnlock(true)
        _G._ExamStates.thirdPerson = true
        -- 游戏会不停拉回第一人称，这里持续保持
        thirdConn = RunService.RenderStepped:Connect(function()
            if not _G._ExamStates.thirdPerson then return end
            pcall(function()
                if lp.CameraMode ~= Enum.CameraMode.Classic then
                    lp.CameraMode = Enum.CameraMode.Classic
                end
                if lp.CameraMaxZoomDistance < 20 then
                    lp.CameraMaxZoomDistance = 30
                end
            end)
        end)
    end
    _G._ExamStates.thirdPerson = false

    -- 重生后游戏会把相机拉回第一人称，
    -- 这里只要开关还开着就重新挂上循环，持续把它掰回来。
    lp.CharacterAdded:Connect(function()
        task.wait(1.5)
        if _G._ExamStates.thirdPerson then
            _G._ExamSetters.thirdPerson(true)
        end
    end)

    -- 兜底：每 2 秒检查一次，开关开着但相机被拉回去了就补上
    task.spawn(function()
        while gui.Parent do
            task.wait(2)
            if _G._ExamStates.thirdPerson then
                if not thirdConn then
                    _G._ExamSetters.thirdPerson(true)
                elseif lp.CameraMode ~= Enum.CameraMode.Classic then
                    pcall(function()
                        lp.CameraMode = Enum.CameraMode.Classic
                        lp.CameraMaxZoomDistance = 30
                    end)
                end
            end
        end
    end)

    table.insert(cleanupFns, function()
        if thirdConn then pcall(function() thirdConn:Disconnect() end) end
        setUnlock(false)
    end)
end

-- ============ 模块 0.3: 免疫摔伤 ============
-- 摔伤由服务端按落地速度判定，客户端没有直接开关。
-- 这里在下落过程中限制最大垂直速度，落地速度不够就判定不出摔伤。
do
    local fallEnabled = false
    local fallConn = nil
    local MAX_FALL_SPEED = 60      -- 超过这个速度开始压制

    local function setup()
        if fallConn then fallConn:Disconnect(); fallConn = nil end
        if not fallEnabled then return end

        fallConn = RunService.Heartbeat:Connect(function()
            if not fallEnabled then return end
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            if hum.Health <= 0 then return end

            if hum:GetState() ~= Enum.HumanoidStateType.Freefall then return end

            local v = hrp.AssemblyLinearVelocity
            if v.Y < -MAX_FALL_SPEED then
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.new(v.X, -MAX_FALL_SPEED, v.Z)
                end)
            end
        end)
    end

    _G._ExamSetters.fallImmune = function(v)
        fallEnabled = v and true or false
        _G._ExamStates.fallImmune = fallEnabled
        setup()
    end
    _G._ExamStates.fallImmune = false

    lp.CharacterAdded:Connect(function()
        task.wait(1)
        if fallEnabled then setup() end
    end)

    table.insert(cleanupFns, function()
        fallEnabled = false
        if fallConn then pcall(function() fallConn:Disconnect() end) end
    end)
end

-- ============ 模块 0.5: 全图高亮（全亮）============
-- 和 IY 的 loopfb 一样：只改 Lighting 的几个值，每帧重写一遍，
-- 不碰任何后期特效（受伤模糊、夜视滤镜之类的照常工作）。
do
    local brightEnabled = false
    local loopConn = nil
    local backup = nil

    local function apply()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end

    local function setup()
        if loopConn then loopConn:Disconnect(); loopConn = nil end

        if not brightEnabled then
            if backup then
                pcall(function()
                    Lighting.Brightness = backup.Brightness
                    Lighting.ClockTime = backup.ClockTime
                    Lighting.FogEnd = backup.FogEnd
                    Lighting.GlobalShadows = backup.GlobalShadows
                    Lighting.OutdoorAmbient = backup.OutdoorAmbient
                end)
                backup = nil
            end
            return
        end

        if not backup then
            backup = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end

        apply()
        loopConn = RunService.RenderStepped:Connect(function()
            if brightEnabled then apply() end
        end)
    end

    _G._ExamSetters.worldESP = function(v)
        brightEnabled = v and true or false
        _G._ExamStates.worldESP = brightEnabled
        setup()
    end
    _G._ExamStates.worldESP = false

    table.insert(cleanupFns, function()
        brightEnabled = false
        if loopConn then pcall(function() loopConn:Disconnect() end) end
        if backup then
            pcall(function()
                Lighting.Brightness = backup.Brightness
                Lighting.ClockTime = backup.ClockTime
                Lighting.FogEnd = backup.FogEnd
                Lighting.GlobalShadows = backup.GlobalShadows
                Lighting.OutdoorAmbient = backup.OutdoorAmbient
            end)
        end
    end)
end

-- ============ 模块 1: 无限体力（v66.1: 一步恢复，不延迟/不循环） ============
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
        if not infStaminaEnabled then return end
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
            originalStamina = {}; _G._ExamStaminaBackup = nil; return
        end
        if backup.current ~= nil then s.stamina.current = backup.current end
        if backup.fullRegen ~= nil then s.stamina.fullRegen = backup.fullRegen end
        if backup.regenDelay ~= nil then s.stamina.regenDelay = backup.regenDelay end
        if backup.max ~= nil then s.stamina.max = backup.max end
        if backup.maxStamina ~= nil then s.stamina.maxStamina = backup.maxStamina end
        if backup.maximum ~= nil then s.stamina.maximum = backup.maximum end
        originalStamina = {}; _G._ExamStaminaBackup = nil
    end
    local loopToken = 0
    local function setupLoop()
        -- 每次启动递增 token，旧循环检测到 token 变化就自行退出
        loopToken = loopToken + 1
        local myToken = loopToken
        staminaLoop = true
        if not infStaminaEnabled then return end
        spawn(function()
            while infStaminaEnabled and loopToken == myToken and gui.Parent do
                local s = getStaminaState()
                if s and infStaminaEnabled and loopToken == myToken then
                    saveOrig(s)
                    applyInf(s)
                end
                wait(0.5)
            end
            if loopToken == myToken then staminaLoop = nil end
        end)
    end
    toggleBase("无限体力", "stamina", false, function(v)
        infStaminaEnabled = v
        if v then
            originalStamina = {}; cachedState = nil; setupLoop()
        else
            -- v66.1: 关闭必须"丝滑"= 一步恢复到开启前 current
            -- 不 tween / 不延迟 / 不循环连刷
            -- 逻辑：flag 已 false → 循环下一轮 applyInf 会立即 return
            --       task.wait() 等一帧让正在跑的 applyInf 收尾
            --       restoreOrig() 一步写回开启前的值
            -- 先让循环失效，再等一帧确保它不会把值刷回去
            loopToken = loopToken + 1
            staminaLoop = nil
            task.wait()
            restoreOrig()
            -- 再等一帧后补一次，防止引擎自动回填
            task.wait()
            restoreOrig()
        end
    end)
    lp.CharacterAdded:Connect(function()
        wait(1); cachedState = nil
        if infStaminaEnabled then originalStamina = {}; setupLoop() end
    end)
    table.insert(cleanupFns, function()
        infStaminaEnabled = false
        loopToken = loopToken + 1
        staminaLoop = nil
        restoreOrig()
    end)
end

-- ============ 模块 2: AI ESP ============
do
    local espConnections = {}
    local ESP_HL_NEW = "_ExamESP_HL"
    local ESP_HB_NEW = "_ExamESP_HB"
    local BIG = {["SIN"]=true,["Chimera"]=true,["Gilbert"]=true,["Mikhail"]=true,["Leaper"]=true}
    local MINI = {["RIF Miniboss"]=true,["Dave"]=true,["CombatEngineer"]=true,["Vorax"]=true}
    local C_NORMAL = Color3.fromRGB(255, 0, 0)
    local C_MINI = Color3.fromRGB(255, 140, 0)
    local C_BIG = Color3.fromRGB(170, 0, 255)
    local C_BTR = Color3.fromRGB(170, 0, 255)
    local C_DRONE = Color3.fromRGB(255, 80, 200)
    local showESPName = true
    local showESPHealth = true
    local espLowLoad = false        -- 透视低负载模式
    local labelRefreshList = {}

    -- 玩家透视（默认关闭，需显式开启）
    local showPlayers = false
    local showPlayerName = false
    local showPlayerHealth = false
    local playerESPNodes = {}   -- [player] = { hl = Highlight, bb = BillboardGui, tl = TextLabel }

    -- ESP 节点判定（要在 applyPlayerESP 之前定义）
    local function isOurESPNode(c)
        if not c then return false end
        local n = c.Name
        return (c:IsA("Highlight") and (n == "AI_Highlight" or n == ESP_HL_NEW))
            or (c:IsA("BillboardGui") and (n == "AI_HealthUI" or n == ESP_HB_NEW))
    end


    local C_PLAYER = Color3.fromRGB(0, 200, 255)

    local function clearPlayerESP()
        for pl, node in pairs(playerESPNodes) do
            if node.hl then pcall(function() node.hl:Destroy() end) end
            if node.bb then pcall(function() node.bb:Destroy() end) end
            playerESPNodes[pl] = nil
        end
    end

    local function playerLabelText(pl)
        local parts = {}
        -- 显示用户名（Name），不是昵称（DisplayName）
        if showPlayerName then table.insert(parts, pl.Name) end
        if showPlayerHealth then
            local ch = pl.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum then
                table.insert(parts, string.format("%d / %d",
                    math.floor(hum.Health), math.floor(hum.MaxHealth)))
            end
        end
        -- 名称和血量都没开时返回空串（不回退名字）
        if #parts == 0 then return "" end
        return table.concat(parts, " | ")
    end

    local function applyPlayerESP(pl)
        local node = playerESPNodes[pl]

        -- 彻底清除该玩家角色上的所有 ESP 节点（含失控残留）
        local function purgePlayer(ch)
            if not ch then return end
            local kill = {}
            for _, c in ipairs(ch:GetChildren()) do
                if isOurESPNode(c) then table.insert(kill, c) end
            end
            for _, c in ipairs(kill) do
                pcall(function() c:Destroy() end)
            end
        end

        local function removeNode()
            if node then
                if node.hl then pcall(function() node.hl:Destroy() end) end
                if node.bb then pcall(function() node.bb:Destroy() end) end
                playerESPNodes[pl] = nil
            end
            node = nil
        end

        if not showPlayers or pl == Players.LocalPlayer then
            removeNode()
            return
        end

        local ch = pl.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not ch or not hum or hum.Health <= 0 then
            removeNode()
            return
        end

        -- 角色换了（重生）或节点已失效：清掉重建
        if node and ((not node.hl) or node.hl.Parent ~= ch or (node.bb and node.bb.Parent ~= ch)) then
            removeNode()
        end

        if not node then
            -- 建之前先扫一遍，防止历史残留堆叠
            purgePlayer(ch)

            local empty = {}
            playerESPNodes[pl] = empty
            node = empty

            local hl = Instance.new("Highlight")
            hl.Name = ESP_HL_NEW
            hl.Adornee = ch
            hl.FillColor = C_PLAYER
            hl.OutlineColor = C_PLAYER
            hl.OutlineTransparency = 0
            hl.FillTransparency = 0.5
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            node.hl = hl
            hl.Parent = ch

            local bb = Instance.new("BillboardGui")
            bb.Name = ESP_HB_NEW
            bb.Adornee = ch
            -- 和 AI 透视保持一致：220x25
            bb.Size = UDim2.new(0, 220, 0, 25)
            bb.StudsOffset = Vector3.new(0, 4, 0)
            bb.AlwaysOnTop = true
            bb.MaxDistance = 800
            bb.LightInfluence = 0
            bb.Enabled = false
            node.bb = bb
            bb.Parent = ch

            local tl = Instance.new("TextLabel")
            tl.Parent = bb
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.TextColor3 = C_PLAYER
            tl.TextStrokeTransparency = 0
            tl.TextScaled = true
            tl.Font = Enum.Font.SourceSansBold
            node.tl = tl
        end

        -- 更新文本（名称/血量 都由子开关控制）
        if node and node.tl and node.bb then
            local txt = playerLabelText(pl)
            node.tl.Text = txt
            node.bb.Enabled = (txt ~= "")
        end
    end

    local function refreshPlayerESP()
        _G._ExamDebug = _G._ExamDebug or {}
        _G._ExamDebug.refreshCalls = (_G._ExamDebug.refreshCalls or 0) + 1
        _G._ExamDebug.lastShowPlayers = showPlayers

        if not showPlayers then
            clearPlayerESP()
            return
        end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= Players.LocalPlayer then
                local ok, err = pcall(applyPlayerESP, pl)
                if not ok then
                    _G._ExamDebug.lastErr = tostring(err)
                end
            end
        end
        _G._ExamDebug.lastNilCheck = next(playerESPNodes) ~= nil
    end
    local function isAICharacter(m)
        if not m or not m:IsA("Model") then return false end

        -- 1) 是某个玩家的角色 → 不是 AI
        if Players:GetPlayerFromCharacter(m) then return false end

        -- 2) 是玩家变身的实体 → 不是 AI
        if m:GetAttribute("IsEntity") == true
           or m:GetAttribute("PlayerEntity") == true then
            return false
        end

        -- 3) 模型里挂着某个玩家的角色（子父关系）→ 不是 AI
        for _, pl in ipairs(Players:GetPlayers()) do
            local ch = pl.Character
            if ch and (ch == m or ch:IsDescendantOf(m) or m:IsDescendantOf(ch)) then
                return false
            end
        end

        if m.Name == "Leaper" then return true end
        if m:FindFirstChild("AI") or m:FindFirstChild("GrabField")
           or m:FindFirstChild("AmbushScenery") or m:FindFirstChild("CharacterTeam") then
            return true
        end
        return false
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
        -- 名称和血量都关掉时，整个标签不显示
        if #parts == 0 then return "" end
        -- [BOSS] 前缀跟随「显示名称」开关
        if showESPName then
            return pre .. table.concat(parts, " | ")
        end
        return table.concat(parts, " | ")
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
            local txt = genText(obj, hum, tagToPre(tag))
            tl.Text = txt
            -- 文本为空时把整个 BillboardGui 隐藏，避免留下空白框
            bb.Enabled = (txt ~= "")
        end
        for _, fn in ipairs(AI_CONTAINERS) do
            local f = Workspace:FindFirstChild(fn)
            if f then for _, c in ipairs(f:GetChildren()) do refreshIn(c) end end
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
        if map then local btr = map:FindFirstChild("BTR-82 (BOSS)"); if btr then cleanIn(btr) end end
        cleanIn(Workspace:FindFirstChild("BTRDrone"))
        for _, fn in ipairs(AI_CONTAINERS) do
            local f = Workspace:FindFirstChild(fn)
            if f then for _, c in ipairs(f:GetChildren()) do cleanIn(c) end end
        end

        -- 兜底：全场景扫一遍，把任何残留的 ESP 节点都清掉
        -- （BTR 重生、实体换容器等情况下，上面的定点清理会漏）
        local scanned = 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if isOurESPNode(d) then
                pcall(function() d:Destroy() end)
            end
            scanned = scanned + 1
            if scanned % 2000 == 0 then task.wait() end
        end
    end
    local function clearESP()
        clearPlayerESP()
        for _, conn in ipairs(espConnections) do pcall(function() conn:Disconnect() end) end
        espConnections = {}; cleanAllESP()
        labelRefreshList = {}
    end
    local function tryHealth(m)
        local hum = m:FindFirstChildOfClass("Humanoid")
        if hum then return hum.Health, hum.MaxHealth end
        return nil, nil
    end
    local function highlightAI(model, color, tag)
        if not espEnabled then return end

        -- 0 血 / 死亡实体不高亮
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then
            -- 已死：清掉可能残留的高亮
            for _, c in ipairs(model:GetChildren()) do
                if isOurESPNode(c) then pcall(function() c:Destroy() end) end
            end
            return
        end

        if model:FindFirstChild(ESP_HL_NEW) then return end
        local hl = Instance.new("Highlight")
        hl.Name = ESP_HL_NEW; hl.Adornee = model; hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.OutlineTransparency = 1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = model
        local bb = Instance.new("BillboardGui")
        bb.Name = ESP_HB_NEW; bb.Adornee = model
        bb.Size = UDim2.new(0, 220, 0, 25); bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop = true; bb.MaxDistance = 300; bb.Parent = model
        local tl = Instance.new("TextLabel")
        tl.Name = "Label"
        tl.Parent = bb; tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1; tl.TextColor3 = color
        tl.TextStrokeTransparency = 0; tl.TextScaled = true
        tl.Font = Enum.Font.SourceSansBold
        local pre = tagToPre(tag)
        -- 关键：创建时立刻赋文本，否则要等刷新循环才更新
        local hum = model:FindFirstChildOfClass("Humanoid")
        local initialText = genText(model, hum, pre)
        tl.Text = initialText
        bb.Enabled = (initialText ~= "")
        table.insert(labelRefreshList, {
            model = model, tl = tl, pre = pre, hl = hl, bb = bb,
        })
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
        bb.Size = UDim2.new(0, 300, 0, 30); bb.StudsOffset = Vector3.new(0, 12, 0)
        bb.AlwaysOnTop = true; bb.MaxDistance = 600; bb.Parent = btrModel
        local tl = Instance.new("TextLabel")
        tl.Name = "Label"
        tl.Parent = bb; tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1; tl.TextColor3 = C_BTR
        tl.TextStrokeTransparency = 0; tl.TextScaled = true
        tl.Font = Enum.Font.SourceSansBold
        local function btrText(cur)
            local parts = {}
            if showESPName then table.insert(parts, "BTR-82") end
            if showESPHealth and cur then table.insert(parts, tostring(math.floor(cur))) end
            if #parts == 0 then return "" end
            if showESPName then
                return "[BOSS] " .. table.concat(parts, " | ")
            end
            return table.concat(parts, " | ")
        end
        tl.Text = btrText(hp)
        table.insert(labelRefreshList, {
            model = btrModel, tl = tl, pre = "", hl = hl, bb = bb,
            isBTR = true,
        })
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
        bb.Size = UDim2.new(0, 200, 0, 25); bb.StudsOffset = Vector3.new(0, 4, 0)
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
        table.insert(labelRefreshList, {
            model = drone, tl = tl, pre = "", hl = hl, bb = bb,
            isDrone = true,
        })
    end
    local function setupESP()
        clearESP()
        if not espEnabled then return end
        for _, fn in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(fn)
            if folder then
                for _, v in ipairs(folder:GetChildren()) do
                    if isAICharacter(v) then
                        local c, t = classify(v)
                        highlightAI(v, c, t)
                    end
                end
                table.insert(espConnections, folder.ChildAdded:Connect(function(v)
                    task.wait(0.1)
                    -- 两次检查：wait 期间可能已被关闭
                    if espEnabled and isAICharacter(v) then
                        local c, t = classify(v)
                        highlightAI(v, c, t)
                    end
                    if not espEnabled then cleanAllESP() end
                end))
            end
        end
        local btr = getBTRModel()
        if btr then highlightBTR(btr) end
        local map = Workspace:FindFirstChild("Map")
        if map then
            table.insert(espConnections, map.ChildAdded:Connect(function(c)
                if c.Name == "BTR-82 (BOSS)" then
                    task.wait(0.5)
                    if espEnabled then
                        highlightBTR(c)
                    else
                        cleanAllESP()
                    end
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

        -- 玩家透视
        refreshPlayerESP()
        table.insert(espConnections, Players.PlayerAdded:Connect(function(pl)
            if espEnabled and showPlayers then
                pl.CharacterAdded:Wait()
                task.wait(0.3)
                if espEnabled then refreshPlayerESP() end
            end
        end))
        table.insert(espConnections, Players.PlayerRemoving:Connect(function(pl)
            local node = playerESPNodes[pl]
            if node then
                if node.hl then pcall(function() node.hl:Destroy() end) end
                if node.bb then pcall(function() node.bb:Destroy() end) end
                playerESPNodes[pl] = nil
            end
        end))
        for _, pl in ipairs(Players:GetPlayers()) do
            table.insert(espConnections, pl.CharacterAdded:Connect(function()
                task.wait(0.5)
                if espEnabled and showPlayers then refreshPlayerESP() end
            end))
        end
        table.insert(espConnections, Workspace.ChildAdded:Connect(function(c)
            if c.Name == "BTRDrone" then
                task.wait(0.3)
                if espEnabled then
                    highlightDrone(c)
                else
                    cleanAllESP()
                end
            end
        end))
        spawn(function()
            local lastHP = nil
            local lastRefresh = 0
            while espEnabled do
                task.wait(0.5)
                if not espEnabled then
                    cleanAllESP()
                    break
                end
                local b = getBTRModel()
                if b then
                    local hp = getBTRHealth(b)
                    local need = false
                    if hp and hp <= 0 then removeBTR(b); lastHP = hp
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

    spawn(function()
        while gui.Parent do
            task.wait(espLowLoad and 1.0 or 0.3)
            if espEnabled then
                for i = #labelRefreshList, 1, -1 do
                    local item = labelRefreshList[i]
                    local m = item.model
                    if not m or not m.Parent or not m:FindFirstChild(ESP_HL_NEW) then
                        table.remove(labelRefreshList, i)
                    elseif (function()
                        local h = m:FindFirstChildOfClass("Humanoid")
                        return h and h.Health <= 0
                    end)() then
                        -- 死亡后移除高亮
                        for _, c in ipairs(m:GetChildren()) do
                            if isOurESPNode(c) then pcall(function() c:Destroy() end) end
                        end
                        table.remove(labelRefreshList, i)
                    else
                        local hum = m:FindFirstChildOfClass("Humanoid")
                        if hum then
                            if hum.Health <= 0 then
                                if item.hl then item.hl:Destroy() end
                                if item.bb then item.bb:Destroy() end
                                table.remove(labelRefreshList, i)
                            else
                                if item.isBTR then
                                    item.tl.Text = "[BOSS] BTR-82 | " .. math.floor(hum.Health)
                                elseif item.isDrone then
                                    item.tl.Text = "[无人机] " .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                                else
                                    item.tl.Text = genText(m, hum, item.pre)
                                end
                            end
                        end
                    end
                end
            else
                if #labelRefreshList > 0 then
                    for _, item in ipairs(labelRefreshList) do
                        if item.hl then pcall(function() item.hl:Destroy() end) end
                        if item.bb then pcall(function() item.bb:Destroy() end) end
                    end
                    labelRefreshList = {}
                end
            end
        end
    end)

    -- ============================================================
    -- 箱子透视：只标记能交互的箱子（带 ProximityPrompt）。
    -- 地图上纯装饰的同名模型没有交互，自动排除。
    -- ============================================================
    local crateEnabled = false
    local C_WEAPON = Color3.fromRGB(120, 220, 255)
    local CRATE_HL = "CrateESP_HL"
    local CRATE_BB = "CrateESP_BB"
    local crateLinks = {}      -- [prompt] = { hl=, bb=, tl=, kind=, model= }
    local crateOwnerUsed = {}  -- [model] = prompt，避免同一模型挂多份
    local crateDecoList = nil  -- 预先收集的无 prompt 箱子外观模型

    -- 判定：只认带交互提示的箱子
    -- 只透视武器箱（能开、能拿枪的那种）。
    -- 弹药箱是补子弹的，标记意义不大，去掉了。
    local function crateKindOf(pp)
        if not pp then return nil end
        if pp.ObjectText == "Weapons Crate" then return "weapon" end
        return nil
    end

    -- 从 prompt 往上找该挂高亮的模型。
    -- 有的箱子 prompt 挂在里面的小部件上，直接挂会在模型上只亮一小块，
    -- 所以逐层往上比，取「部件数量最多、且增长不明显」的那一层。
    local function countParts(m)
        local n = 0
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("BasePart") then n = n + 1 end
        end
        return n
    end

    -- 箱子模型的特征：名字比较"像箱子"，或者部件数在一个合理区间
    -- LootBox / LootCrate / Case / AmmoBox / AmmoBoxGiver 等
    -- 只收「箱子本体」的名字；LootBox / LootCrate 是外层容器，不算
    local CRATE_NAME_HINT = {
        case = true,
        ammobox = true,
        ammoboxgiver = true,
    }
    local function looksLikeCrate(name)
        local n = string.lower(name)
        return CRATE_NAME_HINT[n] == true
    end

    -- 有些箱子的 prompt 挂在一个只有 1 个部件的隐藏触发点上，
    -- 真正的箱子模型是它的「同父级同名兄弟」，需要找出来。
    local function findRealBox(owner)
        if not owner or not owner.Parent then return nil end
        local parent = owner.Parent
        local best = nil
        local bestParts = 0
        for _, s in ipairs(parent:GetChildren()) do
            if s ~= owner and s:IsA("Model") and s.Name == owner.Name then
                local n = countParts(s)
                if n > bestParts then
                    bestParts = n
                    best = s
                end
            end
        end
        return best, bestParts
    end

    local function crateOwner(pp)
        local candidates = {}
        local cur = pp.Parent
        while cur and cur ~= Workspace do
            if cur:IsA("Model") then
                candidates[#candidates + 1] = cur
            end
            cur = cur.Parent
        end
        if #candidates == 0 then return nil end

        -- 从内往外找第一个「像箱子」的层。
        -- 有些箱子的 prompt 挂在一个 0.1 格的隐藏触发点上，
        -- 那种不能满足，要往外找到真正的模型。
        for i = 1, #candidates do
            local m = candidates[i]
            local n = countParts(m)
            local bigEnough = (n >= 8)            -- 至少 8 个部件才算一个箱子
            if bigEnough and looksLikeCrate(m.Name) then
                return m
            end
        end

        -- 名字都不匹配时按部件数挑，10~130 之间最靠内的一层
        local best = nil
        for i = 1, #candidates do
            local n = countParts(candidates[i])
            if n >= 10 and n <= 130 then
                best = candidates[i]
                break
            end
        end
        if best then return best end

        -- 走到这里说明候选都不够大。
        -- 只有当「当前层太小（<10 部件）」时，才去同父级找同名的大模型，
        -- 否则会把本来就合格的 AmmoBox:20 替换成 AmmoBox:1。
        local first = candidates[1]
        if countParts(first) < 10 then
            local real, parts = findRealBox(first)
            if real and parts >= 10 then
                return real
            end
        end

        -- 兜底：往外取第一个部件数够的
        for i = 1, #candidates do
            if countParts(candidates[i]) >= 10 then
                return candidates[i]
            end
        end

        return nil
    end

    local function removeCrate(pp)
        local info = crateLinks[pp]
        if not info then return end
        if info.hl then pcall(function() info.hl:Destroy() end) end
        if info.bb then pcall(function() info.bb:Destroy() end) end
        if info.extraHLs then
            for _, e in ipairs(info.extraHLs) do
                pcall(function() e:Destroy() end)
            end
        end
        if info.model then crateOwnerUsed[info.model] = nil end
        crateLinks[pp] = nil
    end

    -- 记录所有建出来的高亮节点，清理时直接 Destroy，不再全图扫
    local crateNodes = {}

    local function cleanAllCrates()
        for pp in pairs(crateLinks) do removeCrate(pp) end
        crateLinks = {}
        crateOwnerUsed = {}
        for node in pairs(crateNodes) do
            pcall(function() if node and node.Parent then node:Destroy() end end)
        end
        crateNodes = {}
    end

    local function addCrate(pp, kind)
        if crateLinks[pp] then return end
        local node = crateOwner(pp)
        if not node then return end

        -- 不去重：每个交互点都独立标记。
        -- 曾经按模型去重，结果多个 trigger 指向同一模型时只剩一个，
        -- 玩家附近的那个反而被跳过。

        local color = C_WEAPON

        -- 这个游戏不少箱子是「触发器 + 独立外观模型」分开做的，
        -- 外观模型没有 prompt。这里在预先收集好的列表里按距离匹配，
        -- 避免每个箱子都遍历一次整张地图。
        local extraModels = {}
        local basePart
        for _, k in ipairs(node:GetDescendants()) do
            if k:IsA("BasePart") and k.Name ~= "Ammo" then basePart = k break end
        end
        if basePart and crateDecoList then
            local pos = basePart.Position
            for _, entry in ipairs(crateDecoList) do
                if not entry.used and (entry.pos - pos).Magnitude <= 6 then
                    entry.used = true
                    extraModels[#extraModels + 1] = entry.model
                end
            end
        end

        local hl = Instance.new("Highlight")
        hl.Name = CRATE_HL
        hl.Adornee = node
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = node
        crateNodes[hl] = true

        -- 找该模型最高的部件当作标签锚点
        local topPart, topY = nil, -math.huge
        for _, d in ipairs(node:GetDescendants()) do
            if d:IsA("BasePart") and d.Position.Y > topY then
                topY = d.Position.Y
                topPart = d
            end
        end

        local bb = Instance.new("BillboardGui")
        bb.Name = CRATE_BB
        bb.Adornee = topPart or node
        bb.Size = UDim2.new(0, 160, 0, 20)
        bb.StudsOffset = Vector3.new(0, 2.0, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 800
        bb.LightInfluence = 0
        bb.Parent = node
        crateNodes[bb] = true

        local tl = Instance.new("TextLabel")
        tl.Parent = bb
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.TextColor3 = color
        tl.TextStrokeColor3 = Color3.new(0, 0, 0)
        tl.TextStrokeTransparency = 0.35
        tl.TextSize = 13           -- 固定字号，不会随距离变大变小
        tl.TextScaled = false
        tl.RichText = false
        tl.Font = Enum.Font.SourceSansBold
        tl.Text = "[武器箱]"

        -- 额外模型也挂上（只挂 Highlight，不挂标签）
        local extraHLs = {}
        for _, d in ipairs(extraModels) do
            if not d:FindFirstChild(CRATE_HL) then
                local ehl = Instance.new("Highlight")
                ehl.Name = CRATE_HL
                ehl.Adornee = d
                ehl.FillColor = color
                ehl.OutlineColor = color
                ehl.FillTransparency = 0.6
                ehl.OutlineTransparency = 0.1
                ehl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                ehl.Parent = d
                extraHLs[#extraHLs + 1] = ehl
            end
        end

        crateLinks[pp] = { hl = hl, bb = bb, tl = tl, kind = kind, model = node, extraHLs = extraHLs }
    end

    -- 地图静态，只扫一次；之后不再遍历 Workspace
    local crateScanned = false
    local function scanCratesOnce()
        if crateScanned then return end
        crateScanned = true
        local found = 0
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    local kind = crateKindOf(d)
                    if kind then
                        addCrate(d, kind)
                        found = found + 1
                    end
                end
            end
        end)
        return found
    end

    -- 刷新策略：箱子不会动，没必要定时轮询。
    -- 改成「一次建好 → 只在 prompt 的 Enabled 变化时更新那一个」。
    local crateSignals = {}    -- [prompt] = connection

    local function bindPrompt(pp, info)
        if crateSignals[pp] then return end
        crateSignals[pp] = pp:GetPropertyChangedSignal("Enabled"):Connect(function()
            local cur = crateLinks[pp]
            if not cur then return end
            local kind = crateKindOf(pp)
            if not kind then
                removeCrate(pp)
                return
            end
            local baseColor = C_WEAPON
            if pp.Enabled == false then
                cur.tl.Text = "[武器箱] 已开启"
                cur.tl.TextColor3 = Color3.fromRGB(150, 150, 150)
                if cur.hl then
                    cur.hl.FillColor = Color3.fromRGB(120, 120, 120)
                    cur.hl.OutlineColor = Color3.fromRGB(120, 120, 120)
                end
            else
                cur.tl.Text = "[武器箱] 未开启"
                cur.tl.TextColor3 = baseColor
                if cur.hl then
                    cur.hl.FillColor = baseColor
                    cur.hl.OutlineColor = baseColor
                end
            end
        end)
    end

    local function unbindPrompt(pp)
        local c = crateSignals[pp]
        if c then pcall(function() c:Disconnect() end) end
        crateSignals[pp] = nil
    end

    -- 建立：扫一遍地图，给还没挂过的箱子挂高亮并绑定状态信号
    -- 支持重复调用（增量补扫），地图流式加载后新刷出来的箱子也能补上
    local crateBuilt = false
    local crateScanning = false
    local function buildCrates()
        if crateScanning then return end
        crateScanning = true
        crateBuilt = true
        pcall(function()
            -- 外观模型列表只在第一次收集；后续重扫只补新的
            local firstScan = (crateDecoList == nil)
            if firstScan then crateDecoList = {} end

            -- 收集外观模型 + 顺便抓 ProximityPrompt，只遍历一次
            local prompts = {}
            local decoSeen = {}
            if firstScan then
                for _, e in ipairs(crateDecoList) do decoSeen[e.model] = true end
            else
                for _, e in ipairs(crateDecoList) do decoSeen[e.model] = true end
            end

            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    prompts[#prompts + 1] = d
                elseif d:IsA("Model") then
                    local n = d.Name
                    if (n == "BigCrateOpen" or n == "Big Crate" or n == "LootCrate" or n == "LootBox")
                       and not decoSeen[d] then
                        if not d:FindFirstChildWhichIsA("ProximityPrompt", true) then
                            local part
                            for _, k in ipairs(d:GetDescendants()) do
                                if k:IsA("BasePart") then part = k break end
                            end
                            if part then
                                crateDecoList[#crateDecoList + 1] = {
                                    model = d, pos = part.Position, used = false,
                                }
                                decoSeen[d] = true
                            end
                        end
                    end
                end
            end

            for _, d in ipairs(prompts) do
                if d:IsA("ProximityPrompt") then
                    local kind = crateKindOf(d)
                    if kind then
                        addCrate(d, kind)
                        local info = crateLinks[d]
                        if info then
                            -- 初始状态
                            local baseColor = C_WEAPON
                            if d.Enabled == false then
                                info.tl.Text = "[武器箱] 已开启"
                                info.tl.TextColor3 = Color3.fromRGB(150, 150, 150)
                                if info.hl then
                                    info.hl.FillColor = Color3.fromRGB(120, 120, 120)
                                    info.hl.OutlineColor = Color3.fromRGB(120, 120, 120)
                                end
                            else
                                info.tl.Text = "[武器箱] 未开启"
                                info.tl.TextColor3 = baseColor
                            end
                            bindPrompt(d, info)
                        end
                    end
                end
            end
        end)
        crateScanning = false
    end

    local function destroyCrates()
        for pp in pairs(crateSignals) do unbindPrompt(pp) end
        crateSignals = {}
        cleanAllCrates()
        crateBuilt = false
    end

    -- 定时补扫：地图是流式加载的，刚进游戏很多箱子还没刷出来，
    -- 靠一次扫描会漏掉。开着的时候每 3 秒补扫一次，只补新增的。
    local crateLoop = nil
    local CRATE_RESCAN = 3.0

    local function startCrateLoop()
        if crateLoop then return end
        task.spawn(function()
            while crateEnabled and gui.Parent do
                task.wait(CRATE_RESCAN)
                if not crateEnabled then break end
                pcall(buildCrates)
            end
            crateLoop = nil
        end)
        crateLoop = true
    end

    local function stopCrateLoop()
        crateLoop = nil
    end

    -- 开/关
    _G._ExamSetters.crateESP = function(v)
        crateEnabled = v and true or false
        _G._ExamStates.crateESP = crateEnabled
        if crateEnabled then
            buildCrates()
            startCrateLoop()
        else
            stopCrateLoop()
            destroyCrates()
        end
    end

    -- 清理时也要断开
    table.insert(cleanupFns, function()
        crateEnabled = false
        stopCrateLoop()
        for pp in pairs(crateSignals) do unbindPrompt(pp) end
        crateSignals = {}
        cleanAllCrates()
    end)

    toggleBase("人物角色透视", "esp", false, function(v)
        espEnabled = v
        if v then
            setupESP()
        else
            -- 关闭立即清理，不等 8 秒轮询
            clearESP()
        end
    end)

    -- 低负载：拉长标签刷新间隔
    _G._ExamSetters.espLowLoad = function(v)
        espLowLoad = v and true or false
    end
    _G._ExamStates.espLowLoad = false

    _G._ExamStates.crateESP = false
    local nameBtn = Instance.new("TextButton", basePage)
    nameBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    nameBtn.Text = "显示名称: 开"
    nameBtn.TextColor3 = Color3.new(1, 1, 1)
    nameBtn.Font = Enum.Font.Gotham; nameBtn.TextSize = 11; nameBtn.Active = true
    nameBtn.Visible = false
    Instance.new("UICorner", nameBtn).CornerRadius = UDim.new(0, 5)
    reg(nameBtn, "nameBtn")
    local hpBtn = Instance.new("TextButton", basePage)
    hpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    hpBtn.Text = "显示血量: 开"
    hpBtn.TextColor3 = Color3.new(1, 1, 1)
    hpBtn.Font = Enum.Font.Gotham; hpBtn.TextSize = 11; hpBtn.Active = true
    hpBtn.Visible = false
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
    _G._ExamSetters.espName = function(v)
        showESPName = v
        nameBtn.Text = v and "显示名称: 开" or "显示名称: 关"
        nameBtn.BackgroundColor3 = v and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        if espEnabled then refreshAllLabels() end
    end
    _G._ExamStates.espName = true
    _G._ExamSetters.espHP = function(v)
        showESPHealth = v
        hpBtn.Text = v and "显示血量: 开" or "显示血量: 关"
        hpBtn.BackgroundColor3 = v and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        if espEnabled then refreshAllLabels() end
    end
    _G._ExamStates.espHP = true

    -- 玩家透视子项（默认关闭）
    _G._ExamSetters.hlPlayers = function(v)
        showPlayers = v
        if espEnabled then
            refreshPlayerESP()
        else
            clearPlayerESP()
        end
    end
    _G._ExamStates.hlPlayers = false

    _G._ExamSetters.hlPlayerName = function(v)
        showPlayerName = v
        if espEnabled and showPlayers then refreshPlayerESP() end
    end
    _G._ExamStates.hlPlayerName = false

    _G._ExamSetters.hlPlayerHP = function(v)
        showPlayerHealth = v
        if espEnabled and showPlayers then refreshPlayerESP() end
    end
    _G._ExamStates.hlPlayerHP = false

    -- 锁定部位（1=头部 2=身体 ...，与原版 AIM_PARTS 表对应）
    _G._ExamSetters.mbAimPart = function(v)
        local idx = tonumber(v)
        if idx then mbAimPartIndex = idx end
    end
    _G._ExamStates.mbAimPart = 1

    -- 玩家血量/名称需要持续刷新（血量会变）
    spawn(function()
        while gui.Parent do
            task.wait(0.5)
            if espEnabled and showPlayers then
                refreshPlayerESP()
            end
        end
    end)
    -- 兜底轮询：只在开启状态下检查异常残留，关闭时由 clearESP 即时处理
    spawn(function()
        while gui.Parent do
            wait(2)
            if not espEnabled then
                -- 双保险：万一有漏网的 ESP 节点（比如别的脚本加的），清掉
                cleanAllESP()
            end
        end
    end)
    table.insert(cleanupFns, function() espEnabled = false; clearESP() end)
end

-- ============ 模块 3: 头部 Hitbox ============
do
    -- 头部 Hitbox 放大
    -- 直接改 Head 的 Size（和原版一样），这样服务端能认到同一个部件，
    -- 命中判定才有效。之前用附加球的做法只有客户端有，打不中。
    -- 为了避免物理卡住，额外把 Head 的 CanCollide 设为 false。
    local hitboxConns = {}
    local hitboxModified = {}   -- [part] = { Size, CanCollide, Transparency, Massless }

    local function restoreOne(part)
        local orig = hitboxModified[part]
        if not orig then return end
        pcall(function()
            part.Size = orig.Size
            part.CanCollide = orig.CanCollide
            part.Transparency = orig.Transparency
            part.Massless = orig.Massless
        end)
        hitboxModified[part] = nil
    end

    local function restoreAll()
        for part in pairs(hitboxModified) do restoreOne(part) end
    end

    local function isDead(model)
        if not model then return true end
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum then return true end
        return hum.Health <= 0
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
            hitboxModified[part] = {
                Size = part.Size,
                CanCollide = part.CanCollide,
                Transparency = part.Transparency,
                Massless = part.Massless,
            }
        end

        pcall(function()
            part.Size = Vector3.new(headSize, headSize, headSize)
            -- 关键：关碰撞，避免放大后的头部把 AI 卡在墙里
            part.CanCollide = false
            part.Massless = true
            part.Transparency = 0.5
        end)
    end

    local function setup()
        for _, c in ipairs(hitboxConns) do pcall(function() c:Disconnect() end) end
        hitboxConns = {}

        if not headHitboxEnabled then
            restoreAll()
            return
        end

        for _, fn in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(fn)
            if folder then
                for _, m in ipairs(folder:GetChildren()) do
                    if m:IsA("Model") then
                        local h = m:FindFirstChild("Head")
                        if h then applyHead(h) end
                    end
                end
            end
        end

        for _, fn in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(fn)
            if folder then
                table.insert(hitboxConns, folder.ChildAdded:Connect(function(m)
                    task.wait(0.3)
                    if not headHitboxEnabled then return end
                    local h = m:FindFirstChild("Head")
                    if h then applyHead(h) end
                end))
            end
        end

        table.insert(hitboxConns, RunService.Heartbeat:Connect(function()
            if not headHitboxEnabled then return end
            for part in pairs(hitboxModified) do
                local model = part.Parent
                if not model or isDead(model) then
                    restoreOne(part)
                else
                    local want = Vector3.new(headSize, headSize, headSize)
                    if (part.Size - want).Magnitude > 0.1 then
                        pcall(function()
                            part.Size = want
                            part.CanCollide = false
                        end)
                    end
                end
            end
        end))
    end

    toggleBase("头部Hitbox扩大", "headHitbox", false, function(v)
        headHitboxEnabled = v
        setup()
    end)

    _G._ExamSetters.headSizeVal = function(v)
        if type(v) == "number" and v >= 1 and v <= 20 then
            headSize = v
            for part in pairs(hitboxModified) do
                pcall(function()
                    part.Size = Vector3.new(headSize, headSize, headSize)
                end)
            end
        end
    end
    _G._ExamStates.headSizeVal = headSize

    table.insert(cleanupFns, function()
        for _, c in ipairs(hitboxConns) do pcall(function() c:Disconnect() end) end
        restoreAll()
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
        autoInteractEnabled = v; setup()
    end)
    table.insert(cleanupFns, function() if promptConn then promptConn:Disconnect() end end)
end

-- ============ 模块 5: 无条件重置 ============
do
    local resetLoop
    local function setup()
        if resetLoop then resetLoop:Disconnect(); resetLoop = nil end
        if not forceResetEnabled then
            pcall(function() StarterGui:SetCore("ResetButtonCallback", false) end); return
        end
        resetLoop = RunService.Heartbeat:Connect(function()
            pcall(function() StarterGui:SetCore("ResetButtonCallback", true) end)
        end)
    end
    toggleBase("无条件重置", "forceReset", false, function(v)
        forceResetEnabled = v; setup()
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
        badgeHooked = ok; return ok
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
        blockedHooked = count > 0; return blockedHooked
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
        slideEnabled = v; setup()
    end)
    lp.CharacterAdded:Connect(function() wait(2); if slideEnabled then setup() end end)
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
    slideDistLabel.Visible = false
    reg(slideDistLabel, "slideDistLabel")
    local slideDistInput = Instance.new("TextBox", basePage)
    slideDistInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slideDistInput.TextColor3 = Color3.new(1, 1, 1)
    slideDistInput.Text = tostring(slideDistanceMult)
    slideDistInput.Font = Enum.Font.Gotham; slideDistInput.TextSize = 11; slideDistInput.BorderSizePixel = 0
    slideDistInput.Visible = false
    Instance.new("UICorner", slideDistInput).CornerRadius = UDim.new(0, 4)
    reg(slideDistInput, "slideDistInput")
    slideDistInput.FocusLost:Connect(function()
        local val = tonumber(slideDistInput.Text)
        if val and val >= 1 and val <= 10 then
            slideDistanceMult = val; slideDistInput.Text = tostring(slideDistanceMult)
        else slideDistInput.Text = tostring(slideDistanceMult) end
    end)
    _G._ExamSetters.slideDistanceMult = function(v)
        if type(v) == "number" and v >= 1 and v <= 10 then
            slideDistanceMult = v; slideDistInput.Text = tostring(v)
        end
    end
    _G._ExamStates.slideDistanceMult = slideDistanceMult
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
            if isLinear then pcall(function() av.VectorVelocity = newVel end)
            else pcall(function() av.Force = newVel end) end
        end)
    end
    toggleBase("滑铲变向（视角朝哪滑哪）", "slideSteer", false, function(v)
        slideSteerEnabled = v; setup()
    end)
    local modeBtn = Instance.new("TextButton", basePage)
    modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    modeBtn.TextColor3 = Color3.new(1, 1, 1)
    modeBtn.Font = Enum.Font.GothamBold
    modeBtn.TextSize = 11; modeBtn.Active = true
    modeBtn.Visible = false
    Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 5)
    reg(modeBtn, "slideSteerMode")
    local function refreshModeText()
        modeBtn.Text = (slideSteerMode == "camera") and "变向模式: 视角控制" or "变向模式: 移动控制"
        modeBtn.BackgroundColor3 = (slideSteerMode == "camera")
            and Color3.fromRGB(60, 60, 100) or Color3.fromRGB(150, 80, 60)
    end
    bindTap(modeBtn, function()
        slideSteerMode = (slideSteerMode == "camera") and "move" or "camera"
        refreshModeText()
    end)
    refreshModeText()
    _G._ExamSetters.slideSteerMode = function(v)
        -- CDMUI 的 Cycle 传的是选项文字，原版按钮传的是 1/2，两种都得认
        if v == 1 or v == "视角控制" then
            slideSteerMode = "camera"
        elseif v == 2 or v == "移动控制" then
            slideSteerMode = "move"
        elseif v == "camera" or v == "move" then
            slideSteerMode = v
        end
        _G._ExamStates.slideSteerMode = (slideSteerMode == "camera") and 1 or 2
        refreshModeText()
    end
    _G._ExamStates.slideSteerMode = 1
    lp.CharacterAdded:Connect(function() wait(2); if slideSteerEnabled then setup() end end)
    table.insert(cleanupFns, function() if steerLoop then pcall(function() steerLoop:Disconnect() end) end end)
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
        _G._InfNVG_Token = (_G._InfNVG_Token or 0) + 1; _G._InfNVG_Loop = nil
        _G._InfNVG_Token = (_G._InfNVG_Token or 0) + 1
    local _nvgTok = _G._InfNVG_Token
    _G._InfNVG_Loop = true
    spawn(function()
            while nvgEnabled and _G._InfNVG_Token == _nvgTok and gui.Parent do
                makeCloaker()
                if not _G._InfNVG_TextSignalConn then bindBattery() end
                wait(0.3)
            end
        end)
    end
    local function stopRestore()
        _G._InfNVG_Token = (_G._InfNVG_Token or 0) + 1; _G._InfNVG_Loop = nil
        unbindBattery()
        local char = lp.Character
        if char and _G._InfNVG_AddedCloaker then
            local c = char:FindFirstChild("IsCloaker"); if c then c:Destroy() end
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
        _G._InfNVG_AddedCloaker = nil; _G._InfNVG_OrigPercentText = nil; _G._InfNVG_OrigBarSize = nil
    end
    local function setup()
        if not nvgEnabled then stopRestore(); return end
        hookBadges(); bindBattery(); makeCloaker(); startLoop()
    end
    toggleBase("无限电量夜视仪", "nvg", false, function(v)
        nvgEnabled = v; setup()
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        if nvgEnabled then
            unbindBattery(); _G._InfNVG_OrigPercentText = nil; _G._InfNVG_OrigBarSize = nil; setup()
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
        for _, kw in ipairs(keywords) do if lower:find(kw, 1, true) then return true end end
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
                    if disabledScripts[d] == nil then disabledScripts[d] = false end
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
            if s and s.Parent then pcall(function() s.Disabled = orig end); n = n + 1 end
        end
        disabledScripts = {}; _G._ElephantImmune_DisabledScripts = nil
        return n
    end
    local killParts = {}
    local killPartBackup = {}
    local function killPartRestore()
        for kp, orig in pairs(killPartBackup) do
            if kp and kp.Parent then
                pcall(function()
                    kp.Size = orig.Size; kp.CFrame = orig.CFrame
                    kp.CanTouch = orig.CanTouch; kp.CanCollide = orig.CanCollide
                end)
            end
        end
        killPartBackup = {}; killParts = {}; _G._KillPartBackup = nil
    end
    local function neutralizeOne(kp)
        if not kp or not kp.Parent then return end
        if not killPartBackup[kp] then
            killPartBackup[kp] = { Size = kp.Size, CFrame = kp.CFrame, CanTouch = kp.CanTouch, CanCollide = kp.CanCollide }
        end
        pcall(function()
            kp.Size = Vector3.new(0.001, 0.001, 0.001)
            kp.CFrame = CFrame.new(99999, 99999, 99999)
            kp.CanTouch = false; kp.CanCollide = false
        end)
    end
    local function killPartFullScan()
        killParts = {}
        batchScan(Workspace:GetDescendants(), function(d)
            if d:IsA("BasePart") and d.Name == "KillPart" then
                table.insert(killParts, d); neutralizeOne(d)
            end
        end, 200)
        _G._KillPartBackup = killPartBackup
    end
    local killPartScanLoop = nil
    local function startKillPartScan()
        elephantToken = (elephantToken or 0) + 1
        local _elTok = elephantToken
        killPartScanLoop = true
        spawn(function()
            while elephantImmuneEnabled and elephantToken == _elTok and gui.Parent do
                wait(2)
                if not elephantImmuneEnabled then break end
                local function scanOne(inst)
                    if inst:IsA("BasePart") and inst.Name == "KillPart" then
                        if not killPartBackup[inst] then
                            table.insert(killParts, inst); neutralizeOne(inst)
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
    local lastElephantScan = 0
    local function startElephantLoop()
        elephantToken = (elephantToken or 0) + 1; elephantLoop = nil
        if not elephantImmuneEnabled then return end
        elephantLoop = RunService.Heartbeat:Connect(function()
            if not elephantImmuneEnabled then return end
            local now = tick()
            if now - lastElephantScan < 0.5 then return end
            lastElephantScan = now; disableScripts()
        end)
    end
    local function setup()
        elephantToken = (elephantToken or 0) + 1; elephantLoop = nil
        if killPartScanLoop then killPartScanLoop = nil end
        if not elephantImmuneEnabled then killPartRestore(); restoreScripts(); return end
        disableScripts(); killPartFullScan(); startKillPartScan(); startElephantLoop()
    end
    toggleBase("免疫象脚 + 致死区", "elephantImmune", false, function(v)
        elephantImmuneEnabled = v; setup()
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        disabledScripts = {}; _G._ElephantImmune_DisabledScripts = nil
        if elephantImmuneEnabled then setup() end
    end)
    table.insert(cleanupFns, function()
        elephantImmuneEnabled = false
        if elephantLoop then elephantLoop:Disconnect() end
        if killPartScanLoop then killPartScanLoop = nil end
        killPartRestore(); restoreScripts()
    end)
end

-- ============ 模块 9: 快速换弹（v66: 立即恢复 + 1秒连刷 + 结束时清 backup） ============
do
    local FR_TARGET_MULT = 2.0
    local frEnabled = false
    local frLoopToken = 0
    local frBackup = nil
    local frRestoreToken = 0
    local function frCaptureBackup(char)
        if frBackup then return end
        frBackup = { Active = char:GetAttribute("SquadBuffActive"), Reload = char:GetAttribute("SquadReloadSpeedMultiplier") }
    end
    local function frPush()
        local char = lp.Character
        if not char then return end
        pcall(function() char:SetAttribute("SquadBuffActive", true) end)
        pcall(function() char:SetAttribute("SquadReloadSpeedMultiplier", FR_TARGET_MULT) end)
    end
    -- v66: SquadBuffActive / SquadReloadSpeedMultiplier 是游戏维护字段
    -- 恢复必须：立即恢复一次 + 1 秒内 50ms 连刷 + 结束时才清 backup
    local function frRestore()
        frRestoreToken = frRestoreToken + 1
        local myToken = frRestoreToken
        local backup = frBackup
        if not backup then return end
        local tA = backup.Active; if tA == nil then tA = false end
        local tR = backup.Reload; if tR == nil then tR = 1 end
        -- 1) 立即恢复一次（同一帧）
        local c0 = lp.Character
        if c0 then
            pcall(function() c0:SetAttribute("SquadBuffActive", tA) end)
            pcall(function() c0:SetAttribute("SquadReloadSpeedMultiplier", tR) end)
        end
        -- 2) 之后 1 秒内 50ms 连刷，防止被游戏写回
        spawn(function()
            local endAt = tick() + 1
            while frRestoreToken == myToken and tick() < endAt do
                local c = lp.Character
                if c then
                    pcall(function() c:SetAttribute("SquadBuffActive", tA) end)
                    pcall(function() c:SetAttribute("SquadReloadSpeedMultiplier", tR) end)
                end
                task.wait(0.05)
            end
            -- 3) 连刷结束后才清 backup
            if frRestoreToken == myToken then frBackup = nil end
        end)
    end
    local function frStartLoop()
        frLoopToken = frLoopToken + 1
        local my = frLoopToken
        spawn(function()
            while frEnabled and gui.Parent and frLoopToken == my do
                frPush(); wait(0.15)
            end
        end)
    end
    toggleBase("快速换弹", "fastReload", false, function(v)
        frEnabled = v
        if v then
            local char = lp.Character
            if char then frCaptureBackup(char) end
            frStartLoop()
        else frLoopToken = frLoopToken + 1; frRestore() end
    end)
    lp.CharacterAdded:Connect(function()
        wait(1.5)
        if frEnabled then
            frBackup = nil
            local char = lp.Character
            if char then frCaptureBackup(char) end
            frStartLoop()
        end
    end)
    table.insert(cleanupFns, function()
        frEnabled = false; frLoopToken = frLoopToken + 1; frRestore()
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
        if next(muzzleDisabledParts) == nil then return end
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
                if p:IsA("BasePart") and p ~= supportPart and isPointInPart(fpPos, p) then walls[p] = true end
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
        muzzleEnabled = v; setup()
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
           or rawget(v, "Accelerate") then return true end
        return false
    end
    local function patchMetatable(mt)
        if type(mt) ~= "table" then return false end
        if recoilPatchedMTs[mt] then return false end
        recoilPatchedMTs[mt] = true
        local hit = false
        local acc = rawget(mt, "Accelerate")
        if type(acc) == "function" and acc ~= NOOP then
            pcall(function() rawset(mt, "Accelerate", NOOP) end); hit = true
        end
        local pv = rawget(mt, "_positionVelocity")
        if type(pv) == "function" then
            pcall(function() rawset(mt, "_positionVelocity", function() return ZERO_V3, ZERO_V3 end) end); hit = true
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
            pcall(function() rawset(mt, "__index", newIndex) end); hit = true
        elseif type(oi) == "table" and oi ~= mt then
            local a2 = rawget(oi, "Accelerate")
            if type(a2) == "function" and a2 ~= NOOP then
                pcall(function() rawset(oi, "Accelerate", NOOP) end); hit = true
            end
            local pv2 = rawget(oi, "_positionVelocity")
            if type(pv2) == "function" then
                pcall(function() rawset(oi, "_positionVelocity", function() return ZERO_V3, ZERO_V3 end) end); hit = true
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
                pcall(function() rawset(oi, "__index", newIndex2) end); hit = true
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
        if type(acc) == "function" and acc ~= NOOP then pcall(function() rawset(inst, "Accelerate", NOOP) end) end
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
        recoilToken = (recoilToken or 0) + 1
        local _rcTok = recoilToken
        recoilZeroLoop = true
        spawn(function()
            local frame = 0
            while recoilEnabled and recoilToken == _rcTok and gui.Parent do
                frame = frame + 1
                if frame % 3 == 0 then
                    for inst in pairs(recoilPatchedInsts) do
                        pcall(function()
                            rawset(inst, "_position0", ZERO_V3)
                            rawset(inst, "_velocity0", ZERO_V3)
                            rawset(inst, "_target", ZERO_V3)
                            rawset(inst, "_position", ZERO_V3)
                            rawset(inst, "_velocity", ZERO_V3)
                        end)
                    end
                end
                RunService.Heartbeat:Wait()
            end
            recoilZeroLoop = nil
        end)
    end
    local function stopZeroLoop()
        recoilToken = (recoilToken or 0) + 1; recoilZeroLoop = nil
    end
    local recoilSpringModule = nil
    local recoilSpring2Module = nil
    local recoilSpringOrigNew = nil
    local recoilSpring2OrigNew = nil
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
            if type(sp) == "table" then container = sp; newFn = rawget(sp, "new") end
        end
        if type(newFn) ~= "function" then return end
        local orig = newFn
        if label == "Spring" then
            if recoilSpringModule then return end
            recoilSpringModule = m
            recoilSpringOrigNew = orig
        else
            if recoilSpring2Module then return end
            recoilSpring2Module = m
            recoilSpring2OrigNew = orig
        end
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
        rescan(); startZeroLoop()
    end
    -- 还原被改过的 Spring 模块和实例
    local function restoreAll()
        -- Spring / Spring2 的 new 改回去
        if recoilSpringModule and recoilSpringOrigNew then
            pcall(function() rawset(recoilSpringModule, "new", recoilSpringOrigNew) end)
        end
        if recoilSpring2Module and recoilSpring2OrigNew then
            pcall(function() rawset(recoilSpring2Module, "new", recoilSpring2OrigNew) end)
        end
        -- 被 patch 的实例恢复原方法
        pcall(function()
            for inst, orig in pairs(recoilPatchedInsts or {}) do
                if inst then
                    if orig.Accelerate then pcall(function() rawset(inst, "Accelerate", orig.Accelerate) end) end
                    if orig._positionVelocity then pcall(function() rawset(inst, "_positionVelocity", orig._positionVelocity) end) end
                end
            end
        end)
        recoilPatchedInsts = setmetatable({}, { __mode = "k" })
        recoilPatchedMTs = {}
        recoilSpringModule = nil
        recoilSpring2Module = nil
        recoilSpringOrigNew = nil
        recoilSpring2OrigNew = nil
    end

    toggleBase("无后坐力", "recoil", false, function(v)
        recoilEnabled = v
        if v then setup() else restoreAll() end
    end)
    lp.CharacterAdded:Connect(function() wait(1); if recoilEnabled then rescan() end end)
    table.insert(cleanupFns, function()
        recoilEnabled = false
        stopZeroLoop()
        restoreAll()
    end)
end-- ============ 模块 12.6: 自动肘击 ============
-- 靠近怪物时自动按 G 键肘击。
-- 只模拟按键，不碰游戏函数。
do
    local autoBashEnabled = false
    local loopToken = 0
    local RANGE = 8             -- 触发距离
    local INTERVAL = 0.22       -- 两次肘击最小间隔
    local lastBash = 0

    local function isInfected(model)
        if not model or not model:IsA("Model") then return false end
        -- 排除玩家
        if Players:GetPlayerFromCharacter(model) then return false end

        local hum = model:FindFirstChildOfClass("Humanoid")
        -- 必须活着：血量为 0 或已死亡状态都跳过，避免鞭尸
        if not hum or hum.Health <= 0 then return false end
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Dead then return false end
        -- 有些尸体模型血还是正的，额外看 Humanoid 是否还能动
        if hum.WalkSpeed <= 0 and hum.Health <= 0 then return false end

        if model:GetAttribute("IsInfectedAI") == true then return true end
        return false
    end

    -- 检测范围要比肘击范围大，才能提前预判
    local SCAN_RANGE = 22
    -- 怪物进到这个距离就一定按，不等它贴脸（可由 UI 调）
    local PANIC_RANGE = 9
    _G._ExamSetters.bashRange = function(v)
        local n = tonumber(v)
        if not n then return end
        PANIC_RANGE = math.clamp(n, 4, 20)
        _G._ExamStates.bashRange = PANIC_RANGE
        -- 半径变了，让范围圈下帧重算尺寸
        lastRingRadius = nil
    end
    _G._ExamStates.bashRange = 9

    ------------------------------------------------------------------
    -- 肘击范围显示（和 360° 半径显示同一套做法）
    ------------------------------------------------------------------
    local SEGMENTS = 48
    local ringParts = {}
    local ringModel = nil
    local facePart = nil
    local showRange = false
    local bashRangeMode = "line"
    local lastRingRadius = nil

    local function destroyRingImpl()
        for _, q in ipairs(ringParts) do
            if q and q.Parent then pcall(function() q:Destroy() end) end
        end
        ringParts = {}
        if ringModel and ringModel.Parent then pcall(function() ringModel:Destroy() end) end
        ringModel = nil
        lastRingRadius = nil        -- 环重建了，尺寸要重算
    end

    local function destroyFaceImpl()
        if facePart and facePart.Parent then pcall(function() facePart:Destroy() end) end
        facePart = nil
    end

    local destroyRing = destroyRingImpl

    local destroyFace = destroyFaceImpl

    local function ensureRing()
        if #ringParts == SEGMENTS and ringParts[1] and ringParts[1].Parent then
            return ringParts
        end
        destroyRing()
        -- 用一个 Model 包住，整体移动只调一次 PivotTo
        local m = Instance.new("Model")
        m.Name = "ExamBashRingModel"
        m.Parent = Workspace
        ringModel = m
        for i = 1, SEGMENTS do
            local q = Instance.new("Part")
            q.Name = "ExamBashRing"
            q.Size = Vector3.new(0.4, 0.05, 1)
            q.Material = Enum.Material.SmoothPlastic
            q.Color = Color3.fromRGB(255, 190, 60)
            q.Transparency = 1
            q.CanCollide = false; q.CanQuery = false; q.CanTouch = false
            q.Anchored = true; q.CastShadow = false
            q.Parent = m
            local sg = Instance.new("SurfaceGui")
            sg.Name = "Line"; sg.Face = Enum.NormalId.Top
            sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
            sg.PixelsPerStud = 40
            sg.AlwaysOnTop = false        -- 会被物体遮挡，符合真实透视
            sg.LightInfluence = 0; sg.Adornee = q; sg.Parent = q
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, 0, 1, 0)
            f.BackgroundColor3 = Color3.fromRGB(255, 190, 60)
            f.BackgroundTransparency = 0.15
            f.BorderSizePixel = 0
            f.Parent = sg
            table.insert(ringParts, q)

            -- 建好就按当前半径摆一次，避免尺寸一直是默认的 1
            local rr = PANIC_RANGE
            local ang = (i - 1) / SEGMENTS * math.pi * 2
            local segLen = 2 * rr * math.sin(math.pi / SEGMENTS) + 0.05
            q.Size = Vector3.new(0.4, 0.05, segLen)
            q.CFrame = CFrame.new(math.cos(ang) * rr, 0, math.sin(ang) * rr)
                * CFrame.Angles(0, -ang, 0)
        end
        lastRingRadius = PANIC_RANGE
        return ringParts
    end

    local function updateRing()
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then destroyRing(); destroyFace(); return end
        if not showRange then destroyRing(); destroyFace(); return end
        if not autoBashEnabled then destroyRing(); destroyFace(); return end

        -- 向下射线找地面，下蹲/滑铲都不影响
        local groundY = hrp.Position.Y - 2.3
        do
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {char}
            local origin = Vector3.new(hrp.Position.X, hrp.Position.Y + 2, hrp.Position.Z)
            local hit = Workspace:Raycast(origin, Vector3.new(0, -20, 0), params)
            if hit then groundY = hit.Position.Y end
        end
        local base = Vector3.new(hrp.Position.X, groundY + 0.7, hrp.Position.Z)
        local r = PANIC_RANGE

        if bashRangeMode == "line" then
            if facePart then destroyFace() end
            local parts = ensureRing()

            -- 尺寸只在半径变了才重设
            if lastRingRadius ~= r then
                lastRingRadius = r
                local segLen = 2 * r * math.sin(math.pi / SEGMENTS) + 0.05
                for i, q in ipairs(parts) do
                    local ang = (i - 1) / SEGMENTS * math.pi * 2
                    q.Size = Vector3.new(0.4, 0.05, segLen)
                    -- 以原点为圆心摆好，之后整体移动就行
                    q.CFrame = CFrame.new(math.cos(ang) * r, 0, math.sin(ang) * r)
                        * CFrame.Angles(0, -ang, 0)
                end
            end
            -- 整个 Model 跟着角色走，只动一次
            if ringModel and ringModel.Parent then
                pcall(function() ringModel:PivotTo(CFrame.new(base)) end)
            end
        else
            if #ringParts > 0 then destroyRing() end
            if not facePart or not facePart.Parent then
                local q = Instance.new("Part")
                q.Name = "ExamBashFace"
                q.Shape = Enum.PartType.Cylinder
                q.Material = Enum.Material.SmoothPlastic
                q.Color = Color3.fromRGB(255, 190, 60)
                q.Transparency = 1          -- 本体不渲染，靠 SurfaceGui 画
                q.CanCollide = false; q.CanQuery = false; q.CanTouch = false
                q.Anchored = true; q.CastShadow = false
                q.Parent = Workspace
                -- 圆面用顶面 SurfaceGui 画，AlwaysOnTop 保证穿透显示
                local sg = Instance.new("SurfaceGui")
                sg.Name = "Face"; sg.Face = Enum.NormalId.Top
                sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
                sg.PixelsPerStud = 8
                sg.AlwaysOnTop = false     -- 会被遮挡
                sg.LightInfluence = 0
                sg.Adornee = q
                sg.Parent = q
                local f = Instance.new("Frame")
                f.Name = "Fill"
                f.Size = UDim2.new(1, 0, 1, 0)
                f.BackgroundColor3 = Color3.fromRGB(255, 190, 60)
                f.BackgroundTransparency = 0.82
                f.BorderSizePixel = 0
                f.Parent = sg
                facePart = q
            end
            local d = r * 2
            facePart.Size = Vector3.new(0.1, d, d)
            facePart.CFrame = CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90))
        end
    end

    -- 肘击循环里顺带刷新范围圈
    local rangeConn = nil
    local function startRangeLoop()
        if rangeConn then return end
        rangeConn = RunService.RenderStepped:Connect(function()
            if not showRange or not autoBashEnabled then return end
            pcall(updateRing)
        end)
    end
    local function stopRangeLoop()
        if rangeConn then pcall(function() rangeConn:Disconnect() end); rangeConn = nil end
        destroyRing(); destroyFace()
    end

    _G._ExamSetters.bashShowRange = function(v)
        showRange = v and true or false
        _G._ExamStates.bashShowRange = showRange
        -- 主功能没开就不显示
        if showRange and autoBashEnabled then
            startRangeLoop()
        else
            stopRangeLoop()
        end
    end
    _G._ExamStates.bashShowRange = false

    _G._ExamSetters.bashRangeMode = function(v)
        -- 兼容数字索引和中文标签
        if v == 1 or v == "线状" then bashRangeMode = "line"
        elseif v == 2 or v == "面状" then bashRangeMode = "face"
        else return end
        _G._ExamStates.bashRangeMode = (bashRangeMode == "line") and 1 or 2
        destroyRing(); destroyFace()
    end
    _G._ExamStates.bashRangeMode = 1

    local function nearestTarget()
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end

        local best, bestD = nil, math.huge
        local chars = Workspace:FindFirstChild("Characters")
        local containers = {}
        if chars then containers[#containers + 1] = chars end
        local ais = Workspace:FindFirstChild("AI")
        if ais then containers[#containers + 1] = ais end

        for _, c in ipairs(containers) do
            for _, m in ipairs(c:GetChildren()) do
                if isInfected(m) then
                    local thrp = m:FindFirstChild("HumanoidRootPart")
                    if thrp then
                        local d = (thrp.Position - hrp.Position).Magnitude
                        if d < bestD then bestD = d; best = m end
                    end
                end
            end
        end
        return best, bestD
    end

    -- 判断该不该现在出手：
    --   距离很近 -> 立刻打
    --   还有点距离 -> 按「相对接近速度」提前打
    --   相对速度同时考虑：怪物冲过来 + 我自己冲过去
    local function shouldBashNow(target, dist)
        if not target then return false end
        if dist <= PANIC_RANGE then return true end
        if dist > SCAN_RANGE then return false end

        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local thrp = target:FindFirstChild("HumanoidRootPart")
        local thum = target:FindFirstChildOfClass("Humanoid")
        if not hrp or not thrp or not thum then return false end

        -- 单位方向
        local fromMonsterToMe = (hrp.Position - thrp.Position).Unit
        local fromMeToMonster = -fromMonsterToMe

        -- 怪物朝我靠近的速度
        local monsterApproach = thrp.AssemblyLinearVelocity:Dot(fromMonsterToMe)
        if monsterApproach < 0 then monsterApproach = 0 end

        -- 我自己朝怪物冲过去的速度
        local myApproach = hrp.AssemblyLinearVelocity:Dot(fromMeToMonster)
        if myApproach < 0 then myApproach = 0 end

        -- 相对接近速度
        local approach = monsterApproach + myApproach

        if approach < 1 then
            -- 双方都没在靠近，等它近一点再说
            return dist <= PANIC_RANGE + 3
        end

        -- 自己冲得越快，预判窗口要越长，否则会撞上才出手
        local lead = 0.28 + math.min(myApproach / 40, 0.22)

        -- 预测 lead 秒后会不会进入危险距离
        local eta = dist - approach * lead
        return eta <= PANIC_RANGE
    end

    -- 手机 / PC 都能用：
    --   手机端优先走 MobileControls 的 Bash 按钮（游戏自己绑定的）
    --   PC 端走 G 键
    local IS_MOBILE = false
    pcall(function()
        IS_MOBILE = game:GetService("UserInputService").TouchEnabled
            and not game:GetService("UserInputService").KeyboardEnabled
    end)

    local function fireBashButton()
        local pg = lp:FindFirstChild("PlayerGui")
        local mc = pg and pg:FindFirstChild("MobileControls")
        local root = mc and mc:FindFirstChild("Root")
        local btn = root and root:FindFirstChild("Bash")
        if not btn then return false end

        -- 优先 firesignal（直接触发游戏自己的监听）
        if firesignal and getconnections then
            local ok = pcall(function()
                local conns = getconnections(btn.InputBegan)
                if conns and #conns > 0 then
                    firesignal(btn.InputBegan, {
                        UserInputType = Enum.UserInputType.MouseButton1,
                        Position = Vector3.new(0, 0, 0),
                        KeyCode = Enum.KeyCode.Unknown,
                        UserInputState = Enum.UserInputState.Begin,
                    })
                    return true
                end
            end)
            if ok then return true end
        end

        -- 退路：VIM 点按钮位置
        if btn.Visible then
            local ok2 = pcall(function()
                local VIM = game:GetService("VirtualInputManager")
                local p2, s2 = btn.AbsolutePosition, btn.AbsoluteSize
                local cx, cy = p2.X + s2.X / 2, p2.Y + s2.Y / 2
                VIM:SendMouseButtonEvent(cx, cy, 0, true, lp, 1)
                task.wait(0.02)
                VIM:SendMouseButtonEvent(cx, cy, 0, false, lp, 1)
            end)
            return ok2
        end
        return false
    end

    local function pressBash()
        if IS_MOBILE then
            if fireBashButton() then return end
        end
        -- PC / 兜底：模拟 G 键
        local ok = pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true, Enum.KeyCode.G, false, game)
            task.wait(0.02)
            VIM:SendKeyEvent(false, Enum.KeyCode.G, false, game)
        end)
        if not ok and not IS_MOBILE then
            fireBashButton()
        end
    end

    local function start()
        if loopToken > 0 then return end
        loopToken = (loopToken or 0) + 1
        local my = loopToken
        task.spawn(function()
            while autoBashEnabled and gui.Parent and loopToken == my do
                local target, dist = nearestTarget()
                if target and os.clock() - lastBash >= INTERVAL
                   and shouldBashNow(target, dist) then
                    lastBash = os.clock()
                    pressBash()
                end
                -- 扫得勤一点，反应才跟得上
                task.wait(0.05)
            end
            if loopToken == my then loopToken = 0 end
        end)
    end

    local function stop()
        autoBashEnabled = false
        loopToken = 0
    end

    _G._ExamSetters.autoBash = function(v)
        autoBashEnabled = v and true or false
        _G._ExamStates.autoBash = autoBashEnabled
        if autoBashEnabled then
            start()
            if showRange then startRangeLoop() end
        else
            stop()
            stopRangeLoop()     -- 主功能关了，范围圈也收掉
        end
    end
    _G._ExamStates.autoBash = false

    table.insert(cleanupFns, function()
        stop()
        stopRangeLoop()
        destroyRingImpl()
        destroyFaceImpl()
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
        chatForceEnabled = false; chatForceThread = nil
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
        for _, seg in ipairs({"Assets","Modules","Network"}) do m = m and m:FindFirstChild(seg) end
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
        hitData[2] = head; hitData[3] = head.Position
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
        if fhNetwork and fhOrigInvoke then pcall(function() fhNetwork.InvokeServer = fhOrigInvoke end) end
        fhOrigInvoke = nil
    end
    local fhBtn, fhSetState = toggleBase("强制爆头", "forceHeadshot", false, function(v)
        forceHeadshotEnabled = v
        if v then
            installFH()
            if _G._ExamMB and _G._ExamMB.magicOffFn then pcall(_G._ExamMB.magicOffFn) end
        else uninstallFH() end
    end)
    _G._ExamFH.forceOffFn = function()
        if fhSetState then pcall(function() fhSetState(false) end) end
        _G._ExamStates.forceHeadshot = false
        if _G._CP_RefreshFns and _G._CP_RefreshFns.forceHeadshot then
            pcall(_G._CP_RefreshFns.forceHeadshot)
        end
    end
    table.insert(cleanupFns, function() uninstallFH() end)
end

-- ============ 模块 15: 自动 QTE ============
do
    local qteModule = nil
    local qteInputRemote = nil
    do
        local m = ReplicatedStorage
        for _, seg in ipairs({"Assets","Modules","QTEManager"}) do m = m and m:FindFirstChild(seg) end
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
        autoQTEEnabled = v; setup()
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
                if id and SHOTGUN_PUMP_IDS[id] then pcall(function() t:AdjustSpeed(1) end) end
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
            if isTargetAnim(track) then pcall(function() track:AdjustSpeed(SHOTGUN_SPEED_MULT) end) end
        end)
    end
    toggleBase("霰弹枪连发", "shotgunNoPump", false, function(v)
        shotgunNoPumpEnabled = v
        if v then setupAnimator()
        else
            if animatorConn then pcall(function() animatorConn:Disconnect() end); animatorConn = nil end
            pcall(restoreTracks)
        end
    end)
    lp.CharacterAdded:Connect(function() wait(1); if shotgunNoPumpEnabled then setupAnimator() end end)
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
                if ok and v == true then pcall(function() t:SetAttribute("RiotShieldTool", false) end) end
            end
        end
    end
    local function startPush()
        if pushLoop then return end
        pushLoop = spawn(function()
            while shieldFixEnabled and gui.Parent do
                pcall(pushAttrs); wait(0.05)
            end
            pushLoop = nil
        end)
    end
    local function stopPush() pushLoop = nil end
    local function hookBadge()
        if badgeHooked or not hookfunction then return end
        if _G._shieldFixOrigBadge then badgeHooked = true; return end
        origBadgeAsync = BadgeService.UserHasBadgeAsync
        local ok = pcall(function()
            hookfunction(BadgeService.UserHasBadgeAsync, function(self, uid, bid)
                if bid == SLIDE_BADGE_ID then return true end
                return origBadgeAsync(self, uid, bid)
            end)
        end)
        if ok then badgeHooked = true; _G._shieldFixOrigBadge = origBadgeAsync end
    end
    local function findSlideFns()
        trySlideFn = nil; startSlideFn = nil
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
                        if n == "TrySlide" and not trySlideFn then trySlideFn = v
                        elseif n == "StartSlide" and not startSlideFn then startSlideFn = v end
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
                if not shieldFixEnabled then return origTrySlideFn(...) end
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
            hookBadge(); findSlideFns(); hookTrySlide(); startPush(); startHudFix()
        else stopPush(); stopHudFix(); restoreTrySlide() end
    end
    toggleBase("修复盾牌滑铲/疾跑", "shieldSlide", false, function(v)
        shieldFixEnabled = v; setup()
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        if shieldFixEnabled then findSlideFns(); hookTrySlide() end
    end)
    table.insert(cleanupFns, function()
        shieldFixEnabled = false; stopPush(); stopHudFix(); restoreTrySlide()
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
                if tracked[d] == nil then tracked[d] = d.Transparency end
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
            if p and p.Parent then pcall(function() p.Transparency = orig end) end
        end
        tracked = {}
    end
    local function startScanLoop()
        if scanLoop then scanLoop:Disconnect(); scanLoop = nil end
        local frameCount = 0
        scanLoop = RunService.Heartbeat:Connect(function()
            if not shieldVMEnabled then return end
            local vm = getViewmodel()
            if vm ~= lastVM then
                lastVM = vm
                if vm then applyToVM(vm) end
                return
            end
            frameCount = frameCount + 1
            if frameCount % 3 ~= 0 then return end
            if vm then applyToVM(vm) end
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
            if vm then lastVM = vm; applyToVM(vm) end
            startScanLoop()
        else
            if scanLoop then scanLoop:Disconnect(); scanLoop = nil end
            restoreAll(); lastVM = nil
        end
    end)
    local alphaLabel = Instance.new("TextLabel", basePage)
    alphaLabel.BackgroundTransparency = 1
    alphaLabel.Text = "盾牌透明度:"
    alphaLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    alphaLabel.Font = Enum.Font.Gotham; alphaLabel.TextSize = 11
    alphaLabel.TextXAlignment = Enum.TextXAlignment.Left
    alphaLabel.Visible = false
    reg(alphaLabel, "shieldAlphaLabel")
    local alphaInput = Instance.new("TextBox", basePage)
    alphaInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    alphaInput.TextColor3 = Color3.new(1, 1, 1)
    alphaInput.Text = string.format("%.2f", shieldVMAlpha)
    alphaInput.Font = Enum.Font.Gotham; alphaInput.TextSize = 11; alphaInput.BorderSizePixel = 0
    alphaInput.Visible = false
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
        else alphaInput.Text = string.format("%.2f", shieldVMAlpha) end
    end)
    _G._ExamSetters.shieldVMAlpha = function(v)
        if type(v) == "number" and v >= 0 and v <= 0.99 then
            shieldVMAlpha = v; alphaInput.Text = string.format("%.2f", v)
            if shieldVMEnabled then
                local vm = getViewmodel()
                if vm then applyToVM(vm) end
            end
        end
    end
    _G._ExamStates.shieldVMAlpha = shieldVMAlpha
    lp.CharacterAdded:Connect(function()
        wait(1); tracked = {}; lastVM = nil
        if shieldVMEnabled then
            local vm = getViewmodel()
            if vm then lastVM = vm; applyToVM(vm) end
        end
    end)
    table.insert(cleanupFns, function()
        shieldVMEnabled = false
        if scanLoop then scanLoop:Disconnect() end
        restoreAll()
    end)
end

-- ============ 模块 16.7: 无滑铲冷却 ============
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
                if char then pcall(function() char:SetAttribute("RiotShieldEquipped", false) end) end
                noCDActiveUntil = 0
            end
        end
    end)
    toggleBase("实验型无滑铲冷却（会导致盾牌无法防御和其他bug）", "noCD", false, function(v)
        noCDEnabled = v
        if v then
            bindHum(); bindKeyboard(); refreshCDNow()
        else
            noCDActiveUntil = 0
            if humConn then pcall(function() humConn:Disconnect() end); humConn = nil end
            if keyConn then pcall(function() keyConn:Disconnect() end); keyConn = nil end
            local char = lp.Character
            if char then pcall(function() char:SetAttribute("RiotShieldEquipped", false) end) end
        end
    end)
    lp.CharacterAdded:Connect(function()
        wait(1)
        if noCDEnabled then bindHum(); bindKeyboard(); refreshCDNow() end
    end)
    table.insert(cleanupFns, function()
        noCDEnabled = false; noCDActiveUntil = 0
        if humConn then pcall(function() humConn:Disconnect() end) end
        if keyConn then pcall(function() keyConn:Disconnect() end) end
        local char = lp.Character
        if char then pcall(function() char:SetAttribute("RiotShieldEquipped", false) end) end
    end)
end

-- ============ 布局切换按钮（隐藏） ============
local layoutSwitchBtn = Instance.new("TextButton", basePage)
layoutSwitchBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
layoutSwitchBtn.TextColor3 = Color3.new(1, 1, 1)
layoutSwitchBtn.Font = Enum.Font.GothamBold
layoutSwitchBtn.TextSize = 12; layoutSwitchBtn.Active = true
layoutSwitchBtn.Visible = false
Instance.new("UICorner", layoutSwitchBtn).CornerRadius = UDim.new(0, 5)
reg(layoutSwitchBtn, "layoutSwitch")

-- ============ 右下角提示系统 ============
local tipGui = Instance.new("ScreenGui")
tipGui.Name = "ExamRadiusTip"
tipGui.ResetOnSpawn = false
tipGui.DisplayOrder = 200
tipGui.Parent = uiParent
_G.ExamRadiusTip = tipGui
local tipLbl = Instance.new("TextLabel")
tipLbl.Size = UDim2.new(0, 360, 0, 32)
tipLbl.Position = UDim2.new(1, -370, 1, -44)
tipLbl.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tipLbl.BackgroundTransparency = 0.1
tipLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
tipLbl.Font = Enum.Font.GothamBold
tipLbl.TextSize = 12
tipLbl.Visible = false
tipLbl.BorderSizePixel = 0
tipLbl.TextWrapped = true
Instance.new("UICorner", tipLbl).CornerRadius = UDim.new(0, 6)
tipLbl.Parent = tipGui

local tipToken = 0
local function showCountdownTip(msg, duration)
    tipToken = tipToken + 1
    local myToken = tipToken
    local endAt = tick() + (duration or 10)
    tipLbl.Visible = true
    while tick() < endAt do
        if tipToken ~= myToken then return end
        local remain = math.max(0, math.ceil(endAt - tick()))
        tipLbl.Text = msg .. "  [" .. remain .. "s]"
        task.wait(0.15)
    end
    if tipToken == myToken then tipLbl.Visible = false end
end

-- ============ 模块 17: 魔法子弹 + 自动开火 + 射击视觉效果 ============
(function()
    local mbAimPartIndex = 1
    local mbFovRadius = 200
    local mbWorldDistMax = 200
    local mbBBSizeStuds = 2.0
    local mbStudsOffsetY = 0.8
    local mbShowBox = true
    local mbRequireVisible = true
    local mbLowLoad = false         -- 低负载模式
    local mbShowFovCircle = true
    local mbOnlyWhenLocked = true
    local autoFireEnabled = false
    local conns = {}
    local fireCount = 0
    local autoFireStatus = "关"
    local reloadPauseUntil = 0
    local reloadWindowActive = false
    local reloadWindowEnd = 0
    local emergencyCooldownUntil = 0
    local qteLockUntil = 0
    local mbShowRadiusCircle = false
    local radiusMode = "line"
    local RADIUS_LIMIT = 500
    local RING_SEGMENTS = 48
    local radiusRingParts = {}
    local radiusFacePart = nil
    local wasTooLarge = false
    local autoFireBtn = nil
    local clipMaxByTool = {}
    local clipMaxTickByTool = {}
    local EMERGENCY_SKIP_RATIO = 0.7
    local CLIP_MAX_TTL = 30

    local TRACER_COLORS = {Color3.fromRGB(255,60,60), Color3.fromRGB(60,255,60), Color3.fromRGB(60,180,255)}
    local HM_COLORS = {Color3.new(1,1,1), Color3.fromRGB(255,60,60), Color3.fromRGB(60,255,255)}
    local HM_SIZE = {
        {size=15, gap=4, thickness=2},
        {size=25, gap=6, thickness=2.5},
        {size=40, gap=8, thickness=3},
    }
    local MAX_TRACERS = 30
    local MAX_HIT_MARKERS = 20
    local tracerPool = {}
    local tracerActive = {}
    local hitMarkerPool = {}
    local hitMarkerActive = {}
    local tracerLoopStarted = false

    local function initPools()
        for i = 1, MAX_TRACERS do
            local p = Instance.new("Part")
            p.Name = "ExamTracer_Visual"
            p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
            p.CastShadow = false; p.Material = Enum.Material.Neon; p.Transparency = 1
            p.Parent = nil
            tracerPool[i] = p
        end
        for i = 1, MAX_HIT_MARKERS do
            local lines = {}
            for j = 1, 4 do
                local l = Drawing.new("Line")
                l.Thickness = 2; l.Transparency = 1; l.Visible = false
                lines[j] = l
            end
            hitMarkerPool[i] = lines
        end
    end
    initPools()

    local function spawnTracer(startPos, endPos)
        if not shootVisualEnabled or not tracerEnabled then return end
        local part = table.remove(tracerPool)
        if not part then
            local oldest = table.remove(tracerActive, 1)
            if oldest and oldest.part then
                oldest.part.Parent = nil
                part = oldest.part
            else return end
        end
        part.Size = Vector3.new(0.1, 0.1, (startPos - endPos).Magnitude)
        part.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -part.Size.Z / 2)
        part.Transparency = 0
        part.Color = TRACER_COLORS[tracerColorIdx] or Color3.fromRGB(255,60,60)
        part.Parent = Workspace
        table.insert(tracerActive, {part = part, startTick = tick(), duration = tracerDurationSec})
    end

    local function spawnHitMarker(worldPos)
        if not shootVisualEnabled or not hitMarkerEnabled then return end
        local lines = table.remove(hitMarkerPool)
        if not lines then
            local oldest = table.remove(hitMarkerActive, 1)
            if oldest and oldest.lines then
                for _, l in ipairs(oldest.lines) do l.Visible = false end
                lines = oldest.lines
            else return end
        end
        table.insert(hitMarkerActive, {lines = lines, worldPos = worldPos, startTick = tick(), duration = hmDurationSec})
    end

    local function startTracerLoop()
        if tracerLoopStarted then return end
        tracerLoopStarted = true
        spawn(function()
            local frame = 0
            while gui.Parent do
                RunService.RenderStepped:Wait()
                frame = frame + 1
                local now = tick()
                if frame % 2 == 0 then
                    for i = #tracerActive, 1, -1 do
                        local item = tracerActive[i]
                        local t = (now - item.startTick) / item.duration
                        if t >= 1 then
                            item.part.Parent = nil
                            item.part.Transparency = 1
                            table.insert(tracerPool, item.part)
                            table.remove(tracerActive, i)
                        else
                            item.part.Transparency = t
                            if tracerColorIdx == 4 then
                                item.part.Color = Color3.fromHSV((now * 0.5) % 1, 1, 1)
                            end
                        end
                    end
                end
                if #hitMarkerActive > 0 then
                    local cam = Workspace.CurrentCamera
                    if cam then
                        for i = #hitMarkerActive, 1, -1 do
                            local item = hitMarkerActive[i]
                            local lifeT = (now - item.startTick) / item.duration
                            if lifeT >= 1 then
                                for _, l in ipairs(item.lines) do l.Visible = false end
                                table.insert(hitMarkerPool, item.lines)
                                table.remove(hitMarkerActive, i)
                            else
                                local sp, onScreen = cam:WorldToViewportPoint(item.worldPos)
                                if onScreen then
                                    local col = HM_COLORS[hmColorIdx] or Color3.new(1,1,1)
                                    if hmColorIdx == 4 then
                                        col = Color3.fromHSV((now * 0.3) % 1, 1, 1)
                                    end
                                    local sizeP = HM_SIZE[hmSizeIdx] or HM_SIZE[1]
                                    local pulse = 1 + 0.3 * math.sin(lifeT * math.pi * 4)
                                    local size = sizeP.size * pulse
                                    local gap = sizeP.gap * pulse
                                    local baseAngles = {45, 135, 225, 315}
                                    for j = 1, 4 do
                                        local line = item.lines[j]
                                        local a = math.rad(baseAngles[j])
                                        local cosA, sinA = math.cos(a), math.sin(a)
                                        line.From = Vector2.new(sp.X + cosA * gap, sp.Y + sinA * gap)
                                        line.To = Vector2.new(sp.X + cosA * (gap + size), sp.Y + sinA * (gap + size))
                                        line.Color = col
                                        line.Thickness = sizeP.thickness
                                        line.Transparency = math.max(0, 1 - lifeT * 0.3)
                                        line.Visible = true
                                    end
                                else
                                    for _, l in ipairs(item.lines) do l.Visible = false end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local function processHitVisuals(args)
        local hitData = nil
        for i = #args, 1, -1 do
            local v = args[i]
            if type(v) == "table" then
                local h = v[1]
                if typeof(h) == "Instance" and h:IsA("Humanoid") then
                    hitData = v
                    break
                end
            end
        end
        if not hitData then return end
        local endPos = hitData[3]
        if typeof(endPos) ~= "Vector3" then return end
        local startPos = hitData[5]
        if typeof(startPos) ~= "Vector3" then
            local cam = Workspace.CurrentCamera
            if cam then startPos = cam.CFrame.Position end
        end
        if tracerEnabled and startPos then spawnTracer(startPos, endPos) end
        if hitMarkerEnabled then spawnHitMarker(endPos) end
    end

    _G._ExamSetters.shootVisual = function(v)
        shootVisualEnabled = v
        if v then startTracerLoop() end
        if _G._ExamMB and _G._ExamMB.recheckHookFn then pcall(_G._ExamMB.recheckHookFn) end
    end
    _G._ExamStates.shootVisual = false
    _G._ExamSetters.tracerOn = function(v)
        tracerEnabled = v
        if v then startTracerLoop() end
        if _G._ExamMB and _G._ExamMB.recheckHookFn then pcall(_G._ExamMB.recheckHookFn) end
    end
    _G._ExamStates.tracerOn = true
    _G._ExamSetters.hitMarkerOn = function(v)
        hitMarkerEnabled = v
        if v then startTracerLoop() end
        if _G._ExamMB and _G._ExamMB.recheckHookFn then pcall(_G._ExamMB.recheckHookFn) end
    end
    _G._ExamStates.hitMarkerOn = true
    _G._ExamSetters.tracerColor = function(v)
        local n = tonumber(v)
        if not n then
            if v == "红" then n = 1 elseif v == "绿" then n = 2
            elseif v == "蓝" then n = 3 elseif v == "彩虹" then n = 4 end
        end
        if not n then return end
        tracerColorIdx = n
        _G._ExamStates.tracerColor = n
    end
    _G._ExamStates.tracerColor = 3
    _G._ExamSetters.tracerDuration = function(v)
        local n = tonumber(v)
        if not n then
            if v == "1秒" then n = 1 elseif v == "2秒" then n = 2
            elseif v == "3秒" then n = 3 elseif v == "5秒" then n = 4 end
        end
        if not n then return end
        tracerDurationSec = ({1,2,3,5})[n] or 1
        _G._ExamStates.tracerDuration = n
    end
    _G._ExamStates.tracerDuration = 1
    _G._ExamSetters.hmColor = function(v)
        local n = tonumber(v)
        if not n then
            if v == "白" then n = 1 elseif v == "红" then n = 2
            elseif v == "青" then n = 3 elseif v == "彩虹" then n = 4 end
        end
        if not n then return end
        hmColorIdx = n
        _G._ExamStates.hmColor = n
    end
    _G._ExamStates.hmColor = 3
    _G._ExamSetters.hmDuration = function(v)
        local n = tonumber(v)
        if not n then
            if v == "1秒" then n = 1 elseif v == "2秒" then n = 2
            elseif v == "3秒" then n = 3 elseif v == "5秒" then n = 4 end
        end
        if not n then return end
        hmDurationSec = ({1,2,3,5})[n] or 1
        _G._ExamStates.hmDuration = n
    end
    _G._ExamStates.hmDuration = 1
    _G._ExamSetters.hmSize = function(v)
        local n = tonumber(v)
        if not n then
            if v == "小" then n = 1 elseif v == "中" then n = 2
            elseif v == "大" then n = 3 end
        end
        if not n then return end
        hmSizeIdx = n
        _G._ExamStates.hmSize = n
    end
    _G._ExamStates.hmSize = 1

    startTracerLoop()

    local function getTool()
        local char = lp.Character
        if not char then return nil end
        return char:FindFirstChildWhichIsA("Tool")
    end
    local function getClip()
        local tool = getTool()
        if not tool then return nil end
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return nil end
        local gunUI = pg:FindFirstChild(tool.Name)
        if not gunUI then return nil end
        local data = gunUI:FindFirstChild("Data")
        if not data then return nil end
        local clip = data:FindFirstChild("clip")
        if not clip or not clip:IsA("TextLabel") then return nil end
        local ok, txt = pcall(function() return clip.Text end)
        if not ok then return nil end
        if txt == "--" then return -1 end
        local n = tonumber(txt)
        if n and n > 0 then
            local now = tick()
            local lastT = clipMaxTickByTool[tool.Name]
            if lastT and (now - lastT) > CLIP_MAX_TTL then
                clipMaxByTool[tool.Name] = nil
                clipMaxTickByTool[tool.Name] = nil
            end
            local cur = clipMaxByTool[tool.Name] or 0
            if n > cur then
                clipMaxByTool[tool.Name] = n
                clipMaxTickByTool[tool.Name] = now
            end
        end
        return n
    end
    local function isReloading()
        local tool = getTool()
        if not tool then return nil end
        local ok, v = pcall(function() return tool:GetAttribute("Reloading") end)
        if not ok then return nil end
        return v
    end
    local _busyCache = {}
    local BUSY_CACHE_TTL = 0.5
    local function isBusy(m)
        if not m then return false end
        local now = tick()
        local c = _busyCache[m]
        if c and (now - c.t) < BUSY_CACHE_TTL then return c.v end
        local v = m:FindFirstChild("BeingExecuted") ~= nil
        _busyCache[m] = { v = v, t = now }
        return v
    end
    local LOW_PRIORITY_NAMES = { GrabbyMutant = true }
    local function isLowPriority(m) return m and LOW_PRIORITY_NAMES[m.Name] == true end
    local DORMANT_NAMES = { Leaper = true, SIN = true }
    local function isDormant(m)
        if not m or not DORMANT_NAMES[m.Name] then return false end
        local ca = m:FindFirstChild("CanAttack")
        if not ca or not ca:IsA("ValueBase") then return true end
        local ok, v = pcall(function() return ca.Value end)
        if not ok then return true end
        return v ~= true
    end
    local BOSS_DOWNED_NAMES = {
        SIN = true, Chimera = true, Gilbert = true,
        Riser = true, Riser1 = true, Riser2 = true, Riser3 = true, Riser4 = true, Riser5 = true,
        Mikhail = true, Leaper = true,
    }
    local function isDowned(m)
        if not m then return true end
        local hum = m:FindFirstChildOfClass("Humanoid")
        if not hum then return true end
        if hum.Health <= 0 then return true end
        if not BOSS_DOWNED_NAMES[m.Name] then return false end
        if m:FindFirstChildOfClass("ForceField") then return true end
        if hum:FindFirstChildOfClass("ForceField") then return true end
        if m:FindFirstChild("SIN_FORCEFIELD") then return true end
        if m:FindFirstChild("ExposeForceField") then return true end
        if m:FindFirstChild("DeathForceField") then return true end
        local ok, st = pcall(function() return hum:GetState() end)
        if ok then
            if st == Enum.HumanoidStateType.Dead then return true end
            if st == Enum.HumanoidStateType.PlatformStanding then return true end
        end
        if hum.PlatformStand == true then return true end
        return false
    end
    local function scanConnsFresh()
        local Mouse = lp:GetMouse()
        if not Mouse or not getconnections then return end
        local ok, list = pcall(getconnections, Mouse.Button1Down)
        if not ok or type(list) ~= "table" then return end
        local newConns = {}
        for _, c in ipairs(list) do
            local fn = nil
            pcall(function() fn = c.Function end)
            if type(fn) ~= "function" then pcall(function() fn = c["function"] end) end
            if type(fn) == "function" and getinfo then
                local ok2, info = pcall(getinfo, fn)
                if ok2 and type(info) == "table" then
                    local src = (info.source or ""):lower()
                    if src:find("client") or src:find("backpack") then
                        table.insert(newConns, { conn = c, info = info })
                    end
                end
            end
        end
        if #newConns > 0 then conns = newConns end
    end
    local function releaseFire()
        local tool = getTool()
        if not tool then return end
        pcall(function() tool:Activate() end)
        pcall(function() tool:Deactivate() end)
        if getconnections then
            local ok, list = pcall(getconnections, tool.Deactivated)
            if ok and type(list) == "table" then
                for _, c in ipairs(list) do
                    local fn = nil
                    pcall(function() fn = c.Function end)
                    if type(fn) ~= "function" then pcall(function() fn = c["function"] end) end
                    if type(fn) == "function" then pcall(fn) end
                end
            end
        end
    end
    local function doFireOnce(isEmergency)
        local tool = getTool()
        if not tool then return false, "无工具" end
        if not isEmergency then
            local clip = getClip()
            if clip == nil then return false, "无子弹UI" end
            if clip == -1 then return false, "子弹--" end
            if clip <= 0 then return false, "子弹=0" end
        end
        scanConnsFresh()
        if #conns == 0 then return false, "无handler" end
        releaseFire()
        local fired = 0
        for _, e in ipairs(conns) do
            local fn = nil
            pcall(function() fn = e.conn.Function end)
            if type(fn) == "function" then pcall(fn); fired = fired + 1 end
        end
        releaseFire()
        if isEmergency then return true, "紧急开火!" end
        return true, "开火"
    end
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
        if name == "Torso" then return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") end
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
        for _, seg in ipairs({"Assets","Modules","Network"}) do m = m and m:FindFirstChild(seg) end
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
        if isVehicle(m) then return false end
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
        local maxIter = 8
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
                local skip = false
                local ln = string.lower(inst.Name)
                if pierceShieldEnabled and (ln:find("shield", 1, true) or ln:find("riot", 1, true)) then
                    skip = true
                elseif pierceHelmetEnabled and (ln:find("helmet", 1, true) or ln:find("helm", 1, true) or ln:find("visor", 1, true)) then
                    skip = true
                else
                    local mdl = inst:FindFirstAncestorOfClass("Model")
                    if mdl and mdl ~= lp.Character then
                        if pierceTeammateEnabled and Players:GetPlayerFromCharacter(mdl) then
                            skip = true
                        elseif pierceCorpseEnabled then
                            local h = mdl:FindFirstChildOfClass("Humanoid")
                            if h and h.Health <= 0 then skip = true end
                        end
                    end
                end
                if skip then
                    table.insert(exclude, inst)
                    local adv = (r.Position - curOrigin).Magnitude + 0.05
                    curOrigin = r.Position + dirUnit * 0.05
                    remaining = remaining - adv
                    if remaining <= 0 then return true end
                elseif inst.CanCollide then return false
                elseif inst.Transparency >= 0.95 then
                    table.insert(exclude, inst)
                    local adv = (r.Position - curOrigin).Magnitude + 0.05
                    curOrigin = r.Position + dirUnit * 0.05
                    remaining = remaining - adv
                    if remaining <= 0 then return true end
                else return false end
            else return false end
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
        s.Thickness = 1; s.Color = Color3.fromRGB(120, 255, 120); s.Transparency = 0.35
    end
    local function updateFov()
        if not mbFovCircleImg then return end
        if magicBulletEnabled and mbShowFovCircle and mbTargetMode ~= 3 then
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
    local findLastReason = "init"
    local function findTarget()
        local now = tick()
        -- 低负载模式把刷新间隔拉长，扫描开销直接降到原来的一成多
        local interval = mbLowLoad and 0.35 or 0.05
        if now - lastFindTick < interval then return cachedTarget end
        lastFindTick = now

        local myChar = lp.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then cachedTarget = nil; findLastReason = "no-hrp"; return nil end
        local cam = Workspace.CurrentCamera
        if not cam then cachedTarget = nil; findLastReason = "no-cam"; return nil end
        local vs = cam.ViewportSize
        local cx, cy = vs.X / 2, vs.Y / 2
        local myPos = myHrp.Position
        local r2 = mbFovRadius * mbFovRadius
        local best = nil
        local bestScreenD2 = math.huge
        local bestWorldD = math.huge
        local bestPrio = 99
        local camPos = cam.CFrame.Position
        local excludeVis = { lp.Character, Workspace.Terrain, cam }
        local vms = Workspace:FindFirstChild("Viewmodels")
        if vms then table.insert(excludeVis, vms) end
        local candidates, visBlocked, outFov, downedSkip = 0, 0, 0, 0
        for _, folderName in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                for _, m in ipairs(folder:GetChildren()) do
                    if m ~= myChar and m:IsA("Model") and isAlive(m) and isHostile(m) then
                        if isDormant(m) or isDowned(m) or isBusy(m) then
                            downedSkip = downedSkip + 1
                        else
                            candidates = candidates + 1
                            local aimPart = getAimPart(m)
                            local head = m:FindFirstChild("Head")
                            if aimPart and head then
                                local wd = (aimPart.Position - myPos).Magnitude
                                if wd <= mbWorldDistMax then
                                    local screenD2 = nil
                                    local skipThis = false
                                    if mbTargetMode ~= 3 then
                                        local s, onScreen = cam:WorldToViewportPoint(head.Position)
                                        if onScreen and s.Z > 0 then
                                            local dx = s.X - cx
                                            local dy = s.Y - cy
                                            screenD2 = dx*dx + dy*dy
                                            if screenD2 > r2 then outFov = outFov + 1; skipThis = true end
                                        else outFov = outFov + 1; skipThis = true end
                                    end
                                    if not skipThis then
                                        local visible = true
                                        if mbRequireVisible then
                                            visible = isPointVisible(camPos, aimPart.Position, m, excludeVis)
                                        end
                                        if not visible then
                                            visBlocked = visBlocked + 1
                                        else
                                            local prio = isLowPriority(m) and 1 or 0
                                            local accept = false
                                            if prio < bestPrio then accept = true
                                            elseif prio == bestPrio then
                                                if mbTargetMode == 3 then accept = wd < bestWorldD
                                                elseif mbTargetMode == 1 then accept = screenD2 ~= nil and screenD2 < bestScreenD2
                                                else accept = wd < bestWorldD end
                                            end
                                            if accept then
                                                bestPrio = prio
                                                if mbTargetMode == 1 and screenD2 then bestScreenD2 = screenD2
                                                else bestWorldD = wd end
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
        end
        if best then findLastReason = "locked"
        elseif candidates == 0 and downedSkip > 0 then findLastReason = "all-downed"
        elseif candidates == 0 then findLastReason = "no-hostiles"
        elseif visBlocked == candidates then findLastReason = "all-blocked"
        elseif outFov == candidates - visBlocked then findLastReason = "all-outFOV"
        else findLastReason = "no-target" end
        cachedTarget = best
        return best
    end

    local function destroyRadiusRing()
        for _, p in ipairs(radiusRingParts) do
            if p and p.Parent then pcall(function() p:Destroy() end) end
        end
        radiusRingParts = {}
        if radiusRingModel and radiusRingModel.Parent then pcall(function() radiusRingModel:Destroy() end) end
        radiusRingModel = nil
        radiusLastR = nil
        -- 兜底：清掉同名残留 Model，避免叠加
        pcall(function()
            for _, d in ipairs(Workspace:GetChildren()) do
                if d.Name == "ExamRadiusRingModel" then pcall(function() d:Destroy() end) end
            end
        end)
    end
    local function destroyRadiusFace()
        if radiusFacePart and radiusFacePart.Parent then pcall(function() radiusFacePart:Destroy() end) end
        radiusFacePart = nil
        if radiusFaceModel and radiusFaceModel.Parent then pcall(function() radiusFaceModel:Destroy() end) end
        radiusFaceModel = nil
        pcall(function()
            for _, d in ipairs(Workspace:GetChildren()) do
                if d.Name == "ExamRadiusFaceModel" then pcall(function() d:Destroy() end) end
            end
        end)
    end
    local function destroyAllRadius() destroyRadiusRing(); destroyRadiusFace() end
    local radiusRingModel = nil
    local radiusLastR = nil

    local function ensureRadiusRing()
        if #radiusRingParts == RING_SEGMENTS and radiusRingParts[1] and radiusRingParts[1].Parent then
            return radiusRingParts
        end
        destroyRadiusRing()
        local m = Instance.new("Model")
        m.Name = "ExamRadiusRingModel"
        m.Parent = Workspace
        radiusRingModel = m
        for i = 1, RING_SEGMENTS do
            local p = Instance.new("Part")
            p.Name = "ExamRadiusRing"
            p.Size = Vector3.new(0.4, 0.05, 1)
            p.Material = Enum.Material.SmoothPlastic
            p.Color = Color3.fromRGB(120, 255, 120)
            p.Transparency = 1
            p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
            p.Anchored = true; p.CastShadow = false
            p.Parent = m
            local sg = Instance.new("SurfaceGui")
            sg.Name = "Line"; sg.Face = Enum.NormalId.Top
            sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
            sg.PixelsPerStud = 40
            sg.AlwaysOnTop = false        -- 会被墙壁/地面遮挡
            sg.LightInfluence = 0; sg.Adornee = p; sg.Parent = p
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, 0, 1, 0)
            f.BackgroundColor3 = Color3.fromRGB(120, 255, 120)
            f.BackgroundTransparency = 0.15
            f.BorderSizePixel = 0
            f.Parent = sg
            table.insert(radiusRingParts, p)
        end
        return radiusRingParts
    end
    local radiusFaceModel = nil

    local radiusFaceModel = nil

    -- 面模式：和自动肘击范围完全一样的做法（薄圆盘 + 顶面 SurfaceGui）
    local function ensureRadiusFace()
        if radiusFacePart and radiusFacePart.Parent then return radiusFacePart end

        local q = Instance.new("Part")
        q.Name = "ExamRadiusFace"
        q.Shape = Enum.PartType.Cylinder
        q.Material = Enum.Material.SmoothPlastic
        q.Color = Color3.fromRGB(120, 255, 120)
        q.Transparency = 1
        q.CanCollide = false; q.CanQuery = false; q.CanTouch = false
        q.Anchored = true; q.CastShadow = false
        q.Parent = Workspace

        -- Cylinder 的轴是 X，端面是 Right/Left（圆形），侧壁是曲面
        -- 用 Right 端面画，才是完整的圆
        local sg = Instance.new("SurfaceGui")
        sg.Name = "Face"; sg.Face = Enum.NormalId.Right
        sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        sg.PixelsPerStud = 8
        sg.AlwaysOnTop = false
        sg.LightInfluence = 0
        sg.Adornee = q
        sg.Parent = q
        local f = Instance.new("Frame")
        f.Name = "Fill"
        f.Size = UDim2.new(1, 0, 1, 0)
        f.BackgroundColor3 = Color3.fromRGB(120, 255, 120)
        f.BackgroundTransparency = 0.65
        f.BorderSizePixel = 0
        f.Parent = sg
        -- 圆形：UICorner 半径 50% 就是一个正圆
        local corner2 = Instance.new("UICorner")
        corner2.CornerRadius = UDim.new(0.5, 0)
        corner2.Parent = f
        -- 外圈描边，边缘更明显
        local edge = Instance.new("UIStroke")
        edge.Color = Color3.fromRGB(120, 255, 120)
        edge.Thickness = 5
        edge.Transparency = 0
        edge.Parent = f

        radiusFacePart = q
        return q
    end

    local function updateRadiusDisplay()
        if not magicBulletEnabled then destroyAllRadius(); wasTooLarge = false; return end
        if not mbShowRadiusCircle or mbTargetMode ~= 3 then
            destroyAllRadius(); wasTooLarge = false; return
        end
        if mbWorldDistMax > RADIUS_LIMIT then
            destroyAllRadius()
            if not wasTooLarge then
                wasTooLarge = true
                task.spawn(function()
                    showCountdownTip("360° 锁定范围过大，已关闭范围显示（上限 " .. RADIUS_LIMIT .. "）", 10)
                end)
            end
            return
        else wasTooLarge = false end
        local myChar = lp.Character
        if not myChar then destroyAllRadius(); return end
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then destroyAllRadius(); return end
        local myHrp = myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then destroyAllRadius(); return end
        local r = mbWorldDistMax
        -- 用向下射线找真实地面，下蹲/滑铲都不会影响
        local groundY = myHrp.Position.Y - 2.3
        do
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {myChar}
            local origin = Vector3.new(myHrp.Position.X, myHrp.Position.Y + 2, myHrp.Position.Z)
            local hit = Workspace:Raycast(origin, Vector3.new(0, -20, 0), params)
            if hit then groundY = hit.Position.Y end
        end
        local basePos = Vector3.new(myHrp.Position.X, groundY + 0.7, myHrp.Position.Z)
        if radiusMode == "line" then
            destroyRadiusFace()
            local parts = ensureRadiusRing()

            -- 尺寸只在半径变化时重算
            if radiusLastR ~= r then
                radiusLastR = r
                local segLen = 2 * r * math.sin(math.pi / RING_SEGMENTS) + 0.05
                for i, p in ipairs(parts) do
                    local angle = (i - 1) / RING_SEGMENTS * math.pi * 2
                    p.Size = Vector3.new(0.4, 0.05, segLen)
                    p.CFrame = CFrame.new(math.cos(angle) * r, 0, math.sin(angle) * r)
                        * CFrame.Angles(0, -angle, 0)
                end
            end
            -- 整个 Model 跟随角色，一次操作
            if radiusRingModel and radiusRingModel.Parent then
                pcall(function() radiusRingModel:PivotTo(CFrame.new(basePos)) end)
            end
        else
            destroyRadiusRing()
            local p = ensureRadiusFace()
            local d = r * 2
            p.Size = Vector3.new(0.1, d, d)
            -- 和自动肘击同高，不再额外抬高
            p.CFrame = CFrame.new(basePos)
                * CFrame.Angles(0, 0, math.rad(90))
        end
    end
    local lockBB = nil
    local lockTarget = nil
    local function destroyLockBB()
        if lockBB and lockBB.Parent then pcall(function() lockBB:Destroy() end) end
        lockBB = nil; lockTarget = nil
    end
    local function createLockBB(part)
        local bb = Instance.new("BillboardGui")
        bb.Name = "Exam_MB_LockBB"
        bb.Adornee = part
        bb.Size = UDim2.new(mbBBSizeStuds, 0, mbBBSizeStuds, 0)
        bb.StudsOffsetWorldSpace = Vector3.new(0, mbStudsOffsetY, 0)
        bb.AlwaysOnTop = true; bb.LightInfluence = 0
        bb.MaxDistance = mbWorldDistMax; bb.ResetOnSpawn = false
        bb.Parent = part
        local f = Instance.new("Frame", bb)
        f.Name = "BoxFrame"
        f.Size = UDim2.new(1, 0, 1, 0)
        f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.new(0.5, 0, 0.5, 0)
        f.BackgroundTransparency = 1; f.BorderSizePixel = 0
        local s = Instance.new("UIStroke", f)
        s.Color = Color3.fromRGB(120, 255, 120); s.Thickness = 2; s.Transparency = 0.05
        local dot = Instance.new("Frame", bb)
        dot.Name = "CenterDot"
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.new(0.5, 0, 0.5, 0)
        dot.BackgroundColor3 = Color3.fromRGB(120, 255, 120); dot.BorderSizePixel = 0
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
        hitData[2] = aimPart; hitData[3] = aimPart.Position
        if camPos then hitData[5] = camPos end
        local root = hum.RootPart or char:FindFirstChild("HumanoidRootPart")
        if root then
            local cf = CFrame.new(aimPart.Position, aimPart.Position - normal * 1.5)
            hitData[7] = root.CFrame:ToObjectSpace(cf)
        end
        return true
    end
    local shieldCache = { list = {}, tick = 0 }
    local helmetCache = { list = {}, tick = 0 }
    local teammateCache = { list = {}, tick = 0 }
    local corpseCache = { list = {}, tick = 0 }
    local function forEachModel(fn)
        for _, fn2 in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(fn2)
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
                    if n:find("helmet", 1, true) or n:find("helm", 1, true) or n:find("visor", 1, true) then
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
        if mbOnlyWhenLocked then
            if not findTarget() then return end
        end
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
    local function installHook()
        if mbHookInstalled then return end
        mbHookInstalled = true
        if mbNetwork and type(mbNetwork.InvokeServer) == "function" then
            mbOrigInvoke = mbNetwork.InvokeServer
            local w = function(self, action, ...)
                if action == "hit" then
                    local args = {...}
                    if shootVisualEnabled and (tracerEnabled or hitMarkerEnabled) then
                        pcall(processHitVisuals, args)
                    end
                    if magicBulletEnabled then
                        forceAimPart(args[3])
                    end
                    return mbOrigInvoke(self, action, unpack(args))
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
    local function needHook()
        return magicBulletEnabled or (shootVisualEnabled and (tracerEnabled or hitMarkerEnabled))
    end
    _G._ExamMB.recheckHookFn = function()
        if needHook() then installHook() else uninstallHook() end
    end
    local function mbSetup()
        if needHook() then
            if magicBulletEnabled then
                ensureFov(); updateFov()
            end
            installHook()
        else
            uninstallHook(); updateFov(); destroyAllRadius(); wasTooLarge = false
            if autoFireEnabled then
                autoFireEnabled = false
                if autoFireBtn then
                    autoFireBtn.Text = "自动开火: 关（需开掩体检测）"
                    autoFireBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                end
                releaseFire()
                autoFireStatus = "魔法子弹已关"
            end
        end
    end
    local mbBtn, mbSetState = toggleMagic("启用魔法子弹", UDim2.new(0, 15, 0, 4), false, function(v)
        magicBulletEnabled = v
        getgenv()._mbDiag = (getgenv()._mbDiag or "") .. "|cb(" .. tostring(v) .. ")->" .. tostring(magicBulletEnabled)
        if v then
            if _G._ExamFH and _G._ExamFH.forceOffFn then pcall(_G._ExamFH.forceOffFn) end
        end
        mbSetup()
    end, UDim2.new(0, 290, 0, 28))
    _G._ExamMB.magicOffFn = function()
        getgenv()._mbDiag = (getgenv()._mbDiag or "") .. "|magicOffFn调用"
        if mbSetState then pcall(function() mbSetState(false) end) end
        _G._ExamStates.magicBullet = false
        if _G._CP_RefreshFns and _G._CP_RefreshFns.magicBullet then
            pcall(_G._CP_RefreshFns.magicBullet)
        end
    end
    _G._ExamSetters.magicBullet = mbSetState
    _G._ExamStates.magicBullet = false

    local _a = select(2, toggleMagic("显示 3D 头框", UDim2.new(0, 15, 0, 36), true, function(v)
        mbShowBox = v
        if not v then destroyLockBB() end
    end, UDim2.new(0, 140, 0, 28)))
    _G._ExamSetters.mbShowBox = _a; _G._ExamStates.mbShowBox = true

    local _b = select(2, toggleMagic("掩体检测", UDim2.new(0, 165, 0, 36), true, function(v)
        mbRequireVisible = v
        if not v then
            cachedTarget = nil; lastFindTick = 0
            if autoFireEnabled then
                autoFireEnabled = false
                if autoFireBtn then
                    autoFireBtn.Text = "自动开火: 关（需开掩体检测）"
                    autoFireBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                end
                releaseFire()
                autoFireStatus = "掩体检测已关"
            end
        end
    end, UDim2.new(0, 140, 0, 28)))
    _G._ExamSetters.mbRequireVisible = _b; _G._ExamStates.mbRequireVisible = true

    -- 低负载模式：降低扫描频率，缓存更久，关掉持续刷新
    _G._ExamSetters.mbLowLoad = function(v)
        mbLowLoad = v and true or false
        cachedTarget = nil
        lastFindTick = 0          -- 切换后立刻重新扫一次
        if mbLowLoad then
            destroyLockBB()       -- 低负载下不挂 3D 头框
        end
    end
    _G._ExamStates.mbLowLoad = false

    local _c = select(2, toggleMagic("穿透盾牌", UDim2.new(0, 15, 0, 68), true, function(v)
        pierceShieldEnabled = v
        shieldCache.tick = 0; shieldCache.list = {}
    end, UDim2.new(0, 140, 0, 28)))
    _G._ExamSetters.pierceShield = _c; _G._ExamStates.pierceShield = true

    local _d = select(2, toggleMagic("穿透SIN头盔", UDim2.new(0, 165, 0, 68), true, function(v)
        pierceHelmetEnabled = v
        helmetCache.tick = 0; helmetCache.list = {}
    end, UDim2.new(0, 140, 0, 28)))
    _G._ExamSetters.pierceHelmet = _d; _G._ExamStates.pierceHelmet = true

    local _e = select(2, toggleMagic("穿透队友", UDim2.new(0, 15, 0, 100), true, function(v)
        pierceTeammateEnabled = v
        teammateCache.tick = 0; teammateCache.list = {}
    end, UDim2.new(0, 140, 0, 28)))
    _G._ExamSetters.pierceTeammate = _e; _G._ExamStates.pierceTeammate = true

    local _f = select(2, toggleMagic("穿透尸体", UDim2.new(0, 165, 0, 100), true, function(v)
        pierceCorpseEnabled = v
        corpseCache.tick = 0; corpseCache.list = {}
    end, UDim2.new(0, 140, 0, 28)))
    _G._ExamSetters.pierceCorpse = _f; _G._ExamStates.pierceCorpse = true

    local _g = select(2, toggleMagic("显示FOV圈", UDim2.new(0, 15, 0, 132), true, function(v)
        mbShowFovCircle = v; updateFov(); updateLockBB()
    end, UDim2.new(0, 140, 0, 28)))
    _G._ExamSetters.mbShowFovCircle = _g; _G._ExamStates.mbShowFovCircle = true

    local _h = select(2, toggleMagic("未锁定不穿透", UDim2.new(0, 165, 0, 132), true, function(v)
        mbOnlyWhenLocked = v
    end, UDim2.new(0, 140, 0, 28)))
    _G._ExamSetters.mbOnlyWhenLocked = _h; _G._ExamStates.mbOnlyWhenLocked = true

    local MODE_NAMES = { [1] = "准星最近（FOV内）", [2] = "距离最近（FOV内）", [3] = "360° 距离最近" }
    local modeBtn = Instance.new("TextButton", magicPage)
    modeBtn.Size = UDim2.new(1, -30, 0, 28)
    modeBtn.Position = UDim2.new(0, 15, 0, 164)
    modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    modeBtn.TextColor3 = Color3.new(1, 1, 1)
    modeBtn.Font = Enum.Font.GothamBold
    modeBtn.TextSize = 12; modeBtn.Active = true
    modeBtn.Visible = false
    Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 5)
    local function refreshModeBtnText()
        modeBtn.Text = "锁定模式: " .. (MODE_NAMES[mbTargetMode] or "?")
        if mbTargetMode == 3 then modeBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
        elseif mbTargetMode == 2 then modeBtn.BackgroundColor3 = Color3.fromRGB(150, 110, 50)
        else modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100) end
    end
    bindTap(modeBtn, function()
        mbTargetMode = mbTargetMode % 3 + 1
        cachedTarget = nil; lastFindTick = 0
        destroyLockBB(); refreshModeBtnText(); updateFov(); wasTooLarge = false
    end)
    refreshModeBtnText()
    _G._ExamSetters.mbTargetMode = function(v)
        -- 索引、中文标签、英文键都认
        local n = v
        if type(v) == "string" then
            if v == "FOV内准星最近" then n = 1
            elseif v == "FOV内距离最近" then n = 2
            elseif v == "360°全向锁定" then n = 3
            else n = tonumber(v) end
        end
        if type(n) ~= "number" or n < 1 or n > 3 then return end
        mbTargetMode = n
        _G._ExamStates.mbTargetMode = n
        cachedTarget = nil; lastFindTick = 0
        destroyLockBB(); refreshModeBtnText(); updateFov(); wasTooLarge = false
    end
    _G._ExamStates.mbTargetMode = 1
    autoFireBtn = Instance.new("TextButton", magicPage)
    autoFireBtn.Size = UDim2.new(1, -30, 0, 28)
    autoFireBtn.Position = UDim2.new(0, 15, 0, 196)
    autoFireBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    autoFireBtn.TextColor3 = Color3.new(1, 1, 1)
    autoFireBtn.Font = Enum.Font.GothamBold
    autoFireBtn.TextSize = 12; autoFireBtn.Active = true
    autoFireBtn.Visible = false
    autoFireBtn.Text = "自动开火: 关（需开掩体检测）"
    Instance.new("UICorner", autoFireBtn).CornerRadius = UDim.new(0, 5)
    bindTap(autoFireBtn, function()
        if not magicBulletEnabled then autoFireStatus = "请先开魔法子弹"; return end
        if not mbRequireVisible then autoFireStatus = "请先开掩体检测"; return end
        autoFireEnabled = not autoFireEnabled
        autoFireBtn.Text = autoFireEnabled and "自动开火: 开" or "自动开火: 关（需开掩体检测）"
        autoFireBtn.BackgroundColor3 = autoFireEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        if autoFireEnabled then
            scanConnsFresh(); autoFireStatus = "启动中"
        else
            releaseFire(); releaseFire(); autoFireStatus = "关"
        end
    end)
    _G._ExamSetters.autoFire = function(v)
        if v and not magicBulletEnabled then return end
        if v and not mbRequireVisible then return end
        autoFireEnabled = v
        autoFireBtn.Text = v and "自动开火: 开" or "自动开火: 关（需开掩体检测）"
        autoFireBtn.BackgroundColor3 = v and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        if v then scanConnsFresh(); autoFireStatus = "启动中"
        else releaseFire(); releaseFire(); autoFireStatus = "关" end
    end
    _G._ExamStates.autoFire = false
    local radiusBtn = Instance.new("TextButton", magicPage)
    radiusBtn.Size = UDim2.new(0, 140, 0, 28)
    radiusBtn.Position = UDim2.new(0, 15, 0, 228)
    radiusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    radiusBtn.TextColor3 = Color3.new(1, 1, 1)
    radiusBtn.Font = Enum.Font.GothamBold
    radiusBtn.TextSize = 11; radiusBtn.Active = true
    radiusBtn.Visible = false
    Instance.new("UICorner", radiusBtn).CornerRadius = UDim.new(0, 5)
    radiusBtn.Text = "半径显示: 关"
    bindTap(radiusBtn, function()
        mbShowRadiusCircle = not mbShowRadiusCircle
        radiusBtn.Text = mbShowRadiusCircle and "半径显示: 开" or "半径显示: 关"
        radiusBtn.BackgroundColor3 = mbShowRadiusCircle and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(70, 70, 70)
        if not mbShowRadiusCircle then destroyAllRadius() end
    end)
    _G._ExamSetters.mbShowRadius = function(v)
        mbShowRadiusCircle = v and true or false
        _G._ExamStates.mbShowRadius = mbShowRadiusCircle
        radiusBtn.Text = v and "半径显示: 开" or "半径显示: 关"
        radiusBtn.BackgroundColor3 = v and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(70, 70, 70)
        if not v then destroyAllRadius() end
    end
    _G._ExamStates.mbShowRadius = false
    local radiusModeBtn = Instance.new("TextButton", magicPage)
    radiusModeBtn.Size = UDim2.new(0, 140, 0, 28)
    radiusModeBtn.Position = UDim2.new(0, 165, 0, 228)
    radiusModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    radiusModeBtn.TextColor3 = Color3.new(1, 1, 1)
    radiusModeBtn.Font = Enum.Font.GothamBold
    radiusModeBtn.TextSize = 11; radiusModeBtn.Active = true
    radiusModeBtn.Visible = false
    Instance.new("UICorner", radiusModeBtn).CornerRadius = UDim.new(0, 5)
    radiusModeBtn.Text = "半径模式: 线"
    bindTap(radiusModeBtn, function()
        radiusMode = (radiusMode == "line") and "face" or "line"
        if radiusMode == "line" then
            radiusModeBtn.Text = "半径模式: 线"
            radiusModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
        else
            radiusModeBtn.Text = "半径模式: 面"
            radiusModeBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
        end
        destroyAllRadius()
    end)
    _G._ExamSetters.radiusMode = function(v)
        -- 兼容数字索引和中文标签
        if v == 1 or v == "线" or v == "line" then
            radiusMode = "line"
        elseif v == 2 or v == "面" or v == "face" then
            radiusMode = "face"
        else
            return
        end
        _G._ExamStates.radiusMode = (radiusMode == "line") and 1 or 2
        if radiusMode == "line" then
            radiusModeBtn.Text = "半径模式: 线"
            radiusModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
        else
            radiusModeBtn.Text = "半径模式: 面"
            radiusModeBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
        end
        destroyAllRadius()
    end
    _G._ExamStates.radiusMode = 1
    local distLbl = Instance.new("TextLabel", magicPage)
    distLbl.Size = UDim2.new(0, 75, 0, 22)
    distLbl.Position = UDim2.new(0, 15, 0, 262)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "最大距离:"
    distLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 11
    distLbl.TextXAlignment = Enum.TextXAlignment.Left
    distLbl.Visible = false
    local distIn = Instance.new("TextBox", magicPage)
    distIn.Size = UDim2.new(0, 60, 0, 22)
    distIn.Position = UDim2.new(0, 88, 0, 262)
    distIn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    distIn.TextColor3 = Color3.new(1, 1, 1)
    distIn.Text = tostring(mbWorldDistMax)
    distIn.Font = Enum.Font.Gotham; distIn.TextSize = 11; distIn.BorderSizePixel = 0
    distIn.Visible = false
    Instance.new("UICorner", distIn).CornerRadius = UDim.new(0, 4)
    distIn.FocusLost:Connect(function()
        local v = tonumber(distIn.Text)
        if v and v >= 10 and v <= 50000 then
            mbWorldDistMax = v; distIn.Text = tostring(v)
            cachedTarget = nil; lastFindTick = 0
        else distIn.Text = tostring(mbWorldDistMax) end
    end)
    local quick50 = Instance.new("TextButton", magicPage)
    quick50.Size = UDim2.new(0, 60, 0, 22)
    quick50.Position = UDim2.new(0, 152, 0, 262)
    quick50.BackgroundColor3 = Color3.fromRGB(60, 80, 100)
    quick50.Text = "50"
    quick50.TextColor3 = Color3.fromRGB(220, 220, 220)
    quick50.Font = Enum.Font.GothamBold
    quick50.TextSize = 11; quick50.Active = true
    quick50.Visible = false
    Instance.new("UICorner", quick50).CornerRadius = UDim.new(0, 4)
    bindTap(quick50, function()
        mbWorldDistMax = 50; distIn.Text = "50"
        cachedTarget = nil; lastFindTick = 0
    end)
    local quick200 = Instance.new("TextButton", magicPage)
    quick200.Size = UDim2.new(0, 60, 0, 22)
    quick200.Position = UDim2.new(0, 216, 0, 262)
    quick200.BackgroundColor3 = Color3.fromRGB(60, 80, 100)
    quick200.Text = "200"
    quick200.TextColor3 = Color3.fromRGB(220, 220, 220)
    quick200.Font = Enum.Font.GothamBold
    quick200.TextSize = 11; quick200.Active = true
    quick200.Visible = false
    Instance.new("UICorner", quick200).CornerRadius = UDim.new(0, 4)
    bindTap(quick200, function()
        mbWorldDistMax = 200; distIn.Text = "200"
        cachedTarget = nil; lastFindTick = 0
    end)
    _G._ExamSetters.mbWorldDistMax = function(v)
        local n = tonumber(v)
        if n and n >= 10 and n <= 50000 then
            mbWorldDistMax = n
            _G._ExamStates.mbWorldDistMax = n
            distIn.Text = tostring(n)
            cachedTarget = nil; lastFindTick = 0
        end
    end
    _G._ExamStates.mbWorldDistMax = mbWorldDistMax
    local charBox = Instance.new("Frame", magicPage)
    charBox.Size = UDim2.new(1, -30, 0, 120)
    charBox.Position = UDim2.new(0, 15, 0, 294)
    charBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    charBox.BorderSizePixel = 0; charBox.Visible = false
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
        b.Text = ""; b.BorderSizePixel = 0
        b.AutoButtonColor = false; b.Active = true
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
        return b
    end
    partBtns[1] = makePartBtn(47, 5, 36, 26)
    partBtns[2] = makePartBtn(47, 34, 36, 40)
    partBtns[3] = makePartBtn(29, 34, 16, 40)
    partBtns[4] = makePartBtn(85, 34, 16, 40)
    partBtns[5] = makePartBtn(47, 78, 16, 38)
    partBtns[6] = makePartBtn(67, 78, 16, 38)
    local rightInfo = Instance.new("Frame", charBox)
    rightInfo.Size = UDim2.new(1, -145, 1, 0)
    rightInfo.Position = UDim2.new(0, 140, 0, 0)
    rightInfo.BackgroundTransparency = 1
    local infoValue = Instance.new("TextLabel", rightInfo)
    infoValue.Size = UDim2.new(1, 0, 0, 40)
    infoValue.Position = UDim2.new(0, 0, 0, 36)
    infoValue.BackgroundTransparency = 1
    infoValue.Text = "头部"
    infoValue.TextColor3 = Color3.fromRGB(0, 220, 120)
    infoValue.Font = Enum.Font.GothamBold
    infoValue.TextSize = 22
    infoValue.TextXAlignment = Enum.TextXAlignment.Left
    local function refreshAimSelection()
        for i, btn in ipairs(partBtns) do
            if i == mbAimPartIndex then btn.BackgroundColor3 = bodyColorSel
            else btn.BackgroundColor3 = bodyColor end
        end
        local info = AIM_PARTS[mbAimPartIndex]
        if info then infoValue.Text = info.label end
    end
    local function selectAim(index)
        if not AIM_PARTS[index] then return end
        mbAimPartIndex = index
        refreshAimSelection(); destroyLockBB()
    end
    for i, btn in ipairs(partBtns) do
        bindTap(btn, function() selectAim(i) end)
    end
    refreshAimSelection()
    _G._ExamSetters.mbAimPart = function(v)
        if type(v) ~= "number" or v < 1 or v > 6 then return end
        mbAimPartIndex = v; refreshAimSelection(); destroyLockBB()
    end
    _G._ExamStates.mbAimPart = 1
    local fovLbl = Instance.new("TextLabel", magicPage)
    fovLbl.Size = UDim2.new(0, 36, 0, 22)
    fovLbl.Position = UDim2.new(0, 15, 0, 432)
    fovLbl.BackgroundTransparency = 1
    fovLbl.Text = "FOV:"
    fovLbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    fovLbl.Font = Enum.Font.Gotham; fovLbl.TextSize = 10
    fovLbl.TextXAlignment = Enum.TextXAlignment.Left
    fovLbl.Visible = false
    local fovInput = Instance.new("TextBox", magicPage)
    fovInput.Size = UDim2.new(0, 42, 0, 22)
    fovInput.Position = UDim2.new(0, 48, 0, 432)
    fovInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    fovInput.TextColor3 = Color3.new(1, 1, 1)
    fovInput.Text = tostring(mbFovRadius)
    fovInput.Font = Enum.Font.Gotham; fovInput.TextSize = 10; fovInput.BorderSizePixel = 0
    fovInput.Visible = false
    Instance.new("UICorner", fovInput).CornerRadius = UDim.new(0, 4)
    fovInput.FocusLost:Connect(function()
        local v = tonumber(fovInput.Text)
        if v and v >= 20 and v <= 800 then
            mbFovRadius = v; fovInput.Text = tostring(v); updateFov()
        else fovInput.Text = tostring(mbFovRadius) end
    end)
    _G._ExamSetters.mbParams = function(p)
        if type(p) == "number" and p >= 20 and p <= 800 then
            mbFovRadius = p; fovInput.Text = tostring(p); updateFov()
        end
    end
    _G._ExamStates.mbParams = mbFovRadius
    do
        local ev = ReplicatedStorage:FindFirstChild("Events")
        local qteIn = ev and ev:FindFirstChild("QTEInput")
        local qteFb = ev and ev:FindFirstChild("QTEFeedback")
        if qteIn then qteIn.OnClientEvent:Connect(function() qteLockUntil = tick() + 3 end) end
        if qteFb then qteFb.OnClientEvent:Connect(function() qteLockUntil = math.max(qteLockUntil, tick() + 0.3) end) end
    end
    local lastFire = 0
    local inFiring = false
    RunService.Heartbeat:Connect(function()
        if not gui.Parent then return end
        if not autoFireEnabled then
            if inFiring then releaseFire(); inFiring = false end
            return
        end
        if not magicBulletEnabled then
            if inFiring then releaseFire(); inFiring = false end
            autoFireStatus = "需先开魔法子弹"; return
        end
        if not mbRequireVisible then
            if inFiring then releaseFire(); inFiring = false end
            autoFireStatus = "需开启掩体检测"; return
        end
        if tick() < qteLockUntil then
            if inFiring then releaseFire(); inFiring = false end
            autoFireStatus = "QTE中"; return
        end
        local target = findTarget()
        local reloadFlag = isReloading()
        local inReloadState = (reloadFlag == true) or reloadWindowActive or tick() < reloadPauseUntil
        local isEmergency = false
        if inReloadState then
            if tick() < emergencyCooldownUntil then
                if inFiring then releaseFire(); inFiring = false end
                autoFireStatus = "紧急冷却"; return
            end
            if target then
                local _tool = getTool()
                local _curClip = getClip()
                local _maxClip = _tool and clipMaxByTool[_tool.Name] or nil
                local _nearDone = false
                local function _clipClose()
                    if _curClip and _curClip > 0 and _maxClip and _maxClip > 0 then
                        if _curClip >= _maxClip - 1 or _curClip >= _maxClip * EMERGENCY_SKIP_RATIO then
                            return true
                        end
                    end
                    return false
                end
                if reloadFlag == true then _nearDone = _clipClose()
                elseif reloadFlag == false then _nearDone = false
                else _nearDone = _clipClose() end
                if _nearDone then
                    if inFiring then releaseFire(); inFiring = false end
                    autoFireStatus = "换弹快完成(跳过紧急)"
                    emergencyCooldownUntil = 0; return
                end
                isEmergency = true
                emergencyCooldownUntil = tick() + 0.5
                reloadWindowActive = false; reloadWindowEnd = 0; reloadPauseUntil = 0
            else
                if inFiring then releaseFire(); inFiring = false end
                autoFireStatus = "装填中"; return
            end
        end
        if not target then
            if inFiring then releaseFire(); inFiring = false end
            autoFireStatus = "无锁定目标"; return
        end
        if isLowPriority(target.model) then
            if inFiring then releaseFire(); inFiring = false end
            autoFireStatus = "低优先目标(不自动)"; return
        end
        local now = tick()
        if now - lastFire < 0.1 then return end
        lastFire = now; inFiring = true
        local ok, reason = doFireOnce(isEmergency)
        autoFireStatus = reason
        if ok then fireCount = fireCount + 1 end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not autoFireEnabled then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.R then
            reloadPauseUntil = math.max(reloadPauseUntil, tick() + 0.3)
            reloadWindowActive = true; reloadWindowEnd = tick() + 6
        end
    end)
    spawn(function()
        while gui.Parent do
            wait(1)
            local pg2 = lp:FindFirstChild("PlayerGui")
            local mc = pg2 and pg2:FindFirstChild("MobileControls")
            local root = mc and mc:FindFirstChild("Root")
            local reloadBtn = root and root:FindFirstChild("Reload")
            if reloadBtn and not reloadBtn:GetAttribute("__ExamAFMBBound") then
                reloadBtn:SetAttribute("__ExamAFMBBound", true)
                local startPos = nil
                reloadBtn.InputBegan:Connect(function(input)
                    local ut = input.UserInputType
                    if ut == Enum.UserInputType.Touch or ut == Enum.UserInputType.MouseButton1 then
                        startPos = input.Position
                    end
                end)
                reloadBtn.InputEnded:Connect(function(input)
                    if not startPos then return end
                    local ut = input.UserInputType
                    if ut == Enum.UserInputType.Touch or ut == Enum.UserInputType.MouseButton1 then
                        local d = (input.Position - startPos).Magnitude
                        startPos = nil
                        if d < 30 and autoFireEnabled then
                            reloadPauseUntil = math.max(reloadPauseUntil, tick() + 0.3)
                            reloadWindowActive = true; reloadWindowEnd = tick() + 6
                        end
                    end
                end)
            end
        end
    end)
    local lockBBFrame = 0
    RunService.RenderStepped:Connect(function()
        if not gui.Parent then return end
        lockBBFrame = lockBBFrame + 1
        -- 半径圈每帧跟，锁框每 3 帧刷一次
        updateRadiusDisplay()
        if lockBBFrame % 3 ~= 0 then return end
        updateLockBB()
    end)
    lp.CharacterAdded:Connect(function() destroyAllRadius(); wasTooLarge = false end)
    table.insert(cleanupFns, function()
        autoFireEnabled = false
        releaseFire(); releaseFire()
        uninstallHook(); destroyFov(); destroyLockBB(); destroyAllRadius()
        for _, item in ipairs(tracerActive) do
            if item.part then item.part.Parent = nil end
        end
        tracerActive = {}
        for _, lines in ipairs(hitMarkerActive) do
            for _, l in ipairs(lines.lines) do pcall(function() l:Remove() end) end
        end
        hitMarkerActive = {}
        for _, p in ipairs(tracerPool) do if p then p:Destroy() end end
        for _, lines in ipairs(hitMarkerPool) do
            for _, l in ipairs(lines) do pcall(function() l:Remove() end) end
        end
    end)
end)()

-- ============ 模块 18: 雷达页 ============
do
    local rpEnabled = false
    local rpUseHeartbeat = true
    local rpShowArrow = true
    local RP_SAMPLE_INTERVAL = 0.03
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
                    rpCacheInside = true; return true
                end
            end
        end
        rpCacheInside = false; return false
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
        for _, fn in ipairs(AI_CONTAINERS) do
            local folder = Workspace:FindFirstChild(fn)
            if folder then
                for _, model in ipairs(folder:GetChildren()) do
                    if model:IsA("Model") then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        local hrp = model:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 then
                            if not _playerChars[model] and not isVehicle(model) then
                                local n = model.Name
                                local c
                                if n == "SIN" or n == "Chimera" or n == "Gilbert"
                                   or n == "Mikhail" or n == "Leaper" then
                                    c = Color3.fromRGB(170, 0, 255)
                                elseif n == "RIF Miniboss" or n == "Dave" or n == "CombatEngineer" or n == "Vorax" then
                                    c = Color3.fromRGB(255, 140, 0)
                                else c = Color3.fromRGB(255, 0, 0) end
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
            proj = proj.Unit * RP_MAP_RADIUS; clamped = true
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
        d.BorderSizePixel = 0; d.ZIndex = 50
        Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
        local s = Instance.new("UIStroke", d)
        s.Name = "Outline"; s.Thickness = 1
        s.Transparency = 0.2; s.Color = Color3.fromRGB(0, 0, 0)
        local core = Instance.new("Frame", d)
        core.Name = "Core"
        core.Size = UDim2.new(0.4, 0, 0.4, 0)
        core.AnchorPoint = Vector2.new(0.5, 0.5)
        core.Position = UDim2.new(0.5, 0, 0.5, 0)
        core.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        core.BackgroundTransparency = 0.5; core.BorderSizePixel = 0
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
        ar.TextSize = 12; ar.Rotation = 0; ar.ZIndex = 51
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
                if isSameLayer then wantTrans = clamped and 0.35 or 0
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
                pcall(rpUpdateOnce); wait(RP_SAMPLE_INTERVAL)
            else wait(0.05) end
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
                pcall(function() el.Visible = true end); fixed = fixed + 1
            end
        end
        for _, name in ipairs(RB_FORCE_HIDE) do
            local el = mc:FindFirstChild(name)
            if el and el:IsA("GuiObject") and el.Visible then
                pcall(function() el.Visible = false end); fixed = fixed + 1
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
        rbToken = (rbToken or 0) + 1; rbMainLoop = nil
        rbToken = (rbToken or 0) + 1
        local _rbTok = rbToken
        rbMainLoop = true
        spawn(function()
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
            rbToken = (rbToken or 0) + 1; rbMainLoop = nil
            rbRestoreZones(); rbRestoreScripts(); rbHideLabel()
        end
    end

    local _r1 = select(2, toggleRadar("启用（雷达探敌）", UDim2.new(0, 15, 0, 4), false, function(v)
        rpEnabled = v
        if not v then rpClearDots() end
    end, UDim2.new(0, 290, 0, 28)))
    _G._ExamSetters.radar = _r1; _G._ExamStates.radar = false

    local _r2 = select(2, toggleRadar("高刷新率（可能会造成卡顿）", UDim2.new(0, 15, 0, 36), true, function(v) rpUseHeartbeat = v end, UDim2.new(0, 290, 0, 28)))
    _G._ExamSetters.radarFast = _r2; _G._ExamStates.radarFast = true

    local _r3 = select(2, toggleRadar("显示敌人朝向箭头", UDim2.new(0, 15, 0, 68), true, function(v)
        rpShowArrow = v
        if not v then
            for _, d in pairs(rpDotPool) do
                if d and d.Parent then
                    local ar = d:FindFirstChild("ArrowLabel")
                    if ar then ar.Visible = false end
                end
            end
        end
    end, UDim2.new(0, 290, 0, 28)))
    _G._ExamSetters.radarArrow = _r3; _G._ExamStates.radarArrow = true

    local _r4 = select(2, toggleRadar("雷达信号增幅器", UDim2.new(0, 15, 0, 100), false, function(v)
        radarBoostEnabled = v; rbSetup()
    end, UDim2.new(0, 290, 0, 28)))
    _G._ExamSetters.radarBoost = _r4; _G._ExamStates.radarBoost = false

    table.insert(cleanupFns, function()
        rpEnabled = false; rpClearDots(); radarBoostEnabled = false
        rbToken = (rbToken or 0) + 1; rbMainLoop = nil
        rbRestoreZones(); rbRestoreScripts(); rbHideLabel()
    end)
end

-- ============================================================

-- ============================================================
-- CDMUI 控制面板
-- ============================================================
-- 统一回调入口
local function CB(key, value)
    -- 先不要直接写 _ExamStates：
    -- cycle 控件传的是中文标签，直接写会把 setter 写入的数字覆盖掉
    local setter = _G._ExamSetters and _G._ExamSetters[key]
    if setter then
        local ok = pcall(setter, value)
        if ok then return end
    end

    -- 没有 setter，或 setter 执行失败：直接写状态并调回调
    _G._ExamStates[key] = value
    local cb = Callbacks[key]
    if cb then pcall(cb, value) end
end

local win = CDMUI.Create({
    Title = "控制面板",
    TopbarText = "控制面板",
})

-- 让模块 setter 能反向同步 UI 状态
CALLBACK_SINK = function(key, value)
    if win and win.State then
        win.State[key] = value
    end
end

-- 让模块的 `gui.Parent` 判断绑定到真实面板
gui = win.Panel or win.Gui or _hiddenDock

-- 所有控件回调统一走这里
win.OnToggle = function(key, value)
    -- 先让模块 setter 处理（它会把中文标签转成内部值再写状态）
    local setter = _G._ExamSetters and _G._ExamSetters[key]
    if setter then
        local ok = pcall(setter, value)
        if ok then return end
    end
    _G._ExamStates[key] = value
    local cb = Callbacks[key]
    if cb then pcall(cb, value) end
end

-- 互斥功能：模块内部互相关闭时，把 UI 勾选框同步掉
-- 控件存在各自的 Tab 里，这里遍历所有 Tab 找对应的 key
local function refreshToggle(key, value)
    for _, tabObj in ipairs(win.Tabs) do
        local row = tabObj.Rows and tabObj.Rows[key]
        if row and row.SetSilent then
            pcall(row.SetSilent, value)
            win.State[key] = value
            return
        end
    end
end

_G._CP_RefreshFns.forceHeadshot = function()
    refreshToggle("forceHeadshot", false)
end

_G._CP_RefreshFns.magicBullet = function()
    refreshToggle("magicBullet", false)
end


local tab

-- ── 基础 ──
-- ============================================================
-- 人物
-- ============================================================
tab = win:Tab("人物")

tab:Section({ Name = "生存" })
tab:Toggle({ Key = "stamina", Name = "无限体力", Desc = "让体力永远保持满状态", Default = false,
    Callback = function(v) CB("stamina", v) end })
tab:Toggle({ Key = "staggerImmune", Name = "硬直免疫", Desc = "受击不僵直、不被击退", Default = false,
    Callback = function(v) CB("staggerImmune", v) end })
tab:Toggle({ Key = "fallImmune", Name = "免疫摔伤", Desc = "从高处落下不掉血", Default = false,
    Callback = function(v) CB("fallImmune", v) end })
tab:Toggle({ Key = "elephantImmune", Name = "免疫象脚", Desc = "免疫象脚和致死区", Default = false,
    Callback = function(v) CB("elephantImmune", v) end })
tab:Toggle({ Key = "forceReset", Name = "无条件重置", Desc = "随时可以重置角色", Default = false,
    Callback = function(v) CB("forceReset", v) end })

tab:Section({ Name = "移动" })
tab:Expand({
    Key = "slide",
    Callback = function(v) CB("slide", v) end,
    Name = "滑铲距离修改",
    Desc = "调整滑铲距离倍率",
    Default = false,
    Children = {
        { Kind = "number", Key = "slideDistanceMult", Name = "滑铲距离倍率", Min = 1, Max = 10, Default = 1, Callback = function(v) CB("slideDistanceMult", v) end },
    },
})
tab:Expand({
    Key = "slideSteer",
    Callback = function(v) CB("slideSteer", v) end,
    Name = "滑铲变向",
    Desc = "滑铲时根据方向变向",
    Default = false,
    Children = {
        { Kind = "cycle", Key = "slideSteerMode", Name = "变向模式", Options = { "视角控制", "移动控制" }, Callback = function(v) CB("slideSteerMode", v) end },
    },
})
tab:Toggle({ Key = "noCD", Name = "无滑铲冷却", Desc = "滑铲无冷却（会导致盾牌无法防御）", Default = false,
    Callback = function(v) CB("noCD", v) end })


tab:Section({ Name = "盾牌" })
tab:Toggle({ Key = "shieldSlide", Name = "修复盾牌滑铲/疾跑", Desc = "持盾也能滑铲疾跑", Default = false,
    Callback = function(v) CB("shieldSlide", v) end })
tab:Expand({
    Key = "shieldVM",
    Callback = function(v) CB("shieldVM", v) end,
    Name = "第一人称盾牌半透明",
    Desc = "第一人称盾牌半透明显示",
    Default = false,
    Children = {
        { Kind = "slider", Key = "shieldVMAlpha", Name = "盾牌透明度", Min = 0, Max = 0.99, Step = 0.05, Default = 0.9, Callback = function(v) CB("shieldVMAlpha", v) end },
    },
})

tab:Section({ Name = "装备" })
tab:Toggle({ Key = "nvg", Name = "无限电量夜视仪", Desc = "夜视仪电量无限", Default = false,
    Callback = function(v) CB("nvg", v) end })

-- ============================================================
-- 枪械
-- ============================================================
tab = win:Tab("枪械")

tab:Section({ Name = "射击" })
tab:Toggle({ Key = "recoil", Name = "无后坐力", Desc = "消除枪械后坐力", Default = false,
    Callback = function(v) CB("recoil", v) end })
tab:Toggle({ Key = "muzzle", Name = "去除枪口遮挡", Desc = "贴墙时不会挡住枪口", Default = false,
    Callback = function(v) CB("muzzle", v) end })
tab:Toggle({ Key = "shotgunNoPump", Name = "霰弹枪连发", Desc = "霰弹枪免拉栓动画", Default = false,
    Callback = function(v) CB("shotgunNoPump", v) end })

tab:Section({ Name = "换弹" })
tab:Toggle({ Key = "fastReload", Name = "快速换弹", Desc = "换弹速度 2 倍", Default = false,
    Callback = function(v) CB("fastReload", v) end })


-- ============================================================
-- 视觉
-- ============================================================
tab = win:Tab("视觉")

tab:Section({ Name = "透视" })
tab:Expand({
    Key = "esp",
    Callback = function(v) CB("esp", v) end,
    Name = "人物角色透视",
    Desc = "高亮 AI 实体，可开启玩家透视",
    Default = false,
    Children = {
        { Kind = "toggle", Key = "espName", Name = "显示名称", Default = true, Callback = function(v) CB("espName", v) end },
        { Kind = "toggle", Key = "espHP", Name = "显示血量", Default = true, Callback = function(v) CB("espHP", v) end },
        { Kind = "toggle", Key = "hlPlayers", Name = "高亮玩家", Default = false, Callback = function(v) CB("hlPlayers", v) end },
        { Kind = "toggle", Key = "hlPlayerName", Name = "显示玩家名称", Default = false, Callback = function(v) CB("hlPlayerName", v) end },
        { Kind = "toggle", Key = "hlPlayerHP", Name = "显示玩家血量", Default = false, Callback = function(v) CB("hlPlayerHP", v) end },
        { Kind = "toggle", Key = "espLowLoad", Name = "低负载模式", Desc = "降低透视刷新频率，人多时开启", Default = false, Callback = function(v) CB("espLowLoad", v) end },
    },
})
tab:Toggle({
    Key = "crateESP",
    Name = "武器箱透视",
    Desc = "透视可开启的武器箱，并显示是否已开启",
    Default = false,
    Callback = function(v) CB("crateESP", v) end,
})

tab:Section({ Name = "画面" })
tab:Toggle({ Key = "worldESP", Name = "全图高亮", Desc = "全图变亮", Default = false,
    Callback = function(v) CB("worldESP", v) end })

tab:Section({ Name = "界面" })
tab:Toggle({ Key = "chatForce", Name = "聊天框强制显示", Desc = "始终显示聊天窗口", Default = false,
    Callback = function(v) CB("chatForce", v) end })

-- ============================================================
-- 战斗
-- ============================================================
tab = win:Tab("战斗")

tab:Section({ Name = "瞄准" })
tab:Expand({
    Key = "magicBullet",
    Callback = function(v) CB("magicBullet", v) end,
    Name = "启用魔法子弹",
    Desc = "自动锁定准星内最近的敌人",
    Default = false,
    Children = {
        { Kind = "toggle", Key = "mbShowBox", Name = "显示 3D 头框", Default = true, Callback = function(v) CB("mbShowBox", v) end },
        { Kind = "toggle", Key = "mbRequireVisible", Name = "掩体检测", Default = true, Callback = function(v) CB("mbRequireVisible", v) end },
        { Kind = "toggle", Key = "pierceShield", Name = "穿透盾牌", Default = true, Callback = function(v) CB("pierceShield", v) end },
        { Kind = "toggle", Key = "pierceHelmet", Name = "穿透 SIN 头盔", Default = true, Callback = function(v) CB("pierceHelmet", v) end },
        { Kind = "toggle", Key = "pierceTeammate", Name = "穿透队友", Default = true, Callback = function(v) CB("pierceTeammate", v) end },
        { Kind = "toggle", Key = "pierceCorpse", Name = "穿透尸体", Default = true, Callback = function(v) CB("pierceCorpse", v) end },
        { Kind = "toggle", Key = "mbShowFovCircle", Name = "显示 FOV 圈", Default = true, Callback = function(v) CB("mbShowFovCircle", v) end },
        { Kind = "toggle", Key = "mbOnlyWhenLocked", Name = "未锁定不穿透", Default = true, Callback = function(v) CB("mbOnlyWhenLocked", v) end },
    },
})
tab:Expand({
    Key = "mbTargetMode",
    Name = "锁定模式",
    Desc = "切换目标选择方式（点击右侧切换）",
    Default = false,
    Callback = function(v) CB("mbTargetMode", v) end,
    Cycle = {
        Key = "mbTargetMode",
        Options = {
            "FOV内准星最近",
            "FOV内距离最近",
            "360°全向锁定",
        },
        DefaultIndex = 1,
        Callback = function(idx) CB("mbTargetMode", idx) end,
    },
    Children = {
        { Kind = "toggle", Key = "mbShowRadius", Name = "360°锁定半径锁定显示", Default = false,
          Callback = function(v) CB("mbShowRadius", v) end },
        { Kind = "cycle", Key = "radiusMode", Name = "360°锁定半径显示模式",
          Options = { "线", "面" }, Callback = function(v) CB("radiusMode", v) end },
    },
})
tab:Input({ Key = "mbParams", Name = "FOV锁定半径", Desc = "FOV=锁定半径（像素）", Default = "200",
    Callback = function(v) CB("mbParams", v) end })
tab:Input({ Key = "mbWorldDistMax", Name = "最大锁定距离", Desc = "锁定目标的最远距离（studs）", Default = "200",
    Callback = function(v) CB("mbWorldDistMax", v) end })
tab:Body2D({
    Key = "mbAimPart",
    Name = "锁定部位",
    Desc = "点击小人选择锁定的身体部位",
    Default = 1,
    Callback = function(idx) CB("mbAimPart", idx) end,
    Parts = {
        { Key = 1, Name = "头部" },
        { Key = 2, Name = "躯干" },
        { Key = 3, Name = "左臂" },
        { Key = 4, Name = "右臂" },
        { Key = 5, Name = "左腿" },
        { Key = 6, Name = "右腿" },
    },
})

tab:Section({ Name = "开火" })
tab:Toggle({ Key = "autoFire", Name = "自动开火", Desc = "锁定后自动开火（需先开魔法子弹+掩体检测）", Default = false,
    Callback = function(v) CB("autoFire", v) end })
tab:Toggle({ Key = "forceHeadshot", Name = "强制爆头", Desc = "命中四肢/身体判定为爆头/不能和魔法子弹同时开启", Default = false,
    Callback = function(v) CB("forceHeadshot", v) end })

tab:Section({ Name = "近战" })
tab:Expand({
    Key = "autoBash",
    Callback = function(v) CB("autoBash", v) end,
    Name = "自动肘击",
    Desc = "提前预判怪物靠近，先手肘击不吃伤害",
    Default = false,
    Children = {
        { Kind = "number", Key = "bashRange", Name = "触发距离", Min = 4, Max = 20, Default = 9, Callback = function(v) CB("bashRange", v) end },
        { Kind = "toggle", Key = "bashShowRange", Name = "显示范围", Callback = function(v) CB("bashShowRange", v) end },
        { Kind = "cycle", Key = "bashRangeMode", Name = "范围样式", Options = { "线状", "面状" }, Callback = function(v) CB("bashRangeMode", v) end },
    },
})

tab:Section({ Name = "判定" })
tab:Expand({
    Key = "headHitbox",
    Callback = function(v) CB("headHitbox", v) end,
    Name = "头部 Hitbox 放大",
    Desc = "放大头部判定范围，不影响敌人移动",
    Default = false,
    Children = {
        { Kind = "number", Key = "headSizeVal", Name = "头部大小", Min = 1, Max = 20, Default = 1, Callback = function(v) CB("headSizeVal", v) end },
    },
})

tab:Section({ Name = "性能" })
tab:Toggle({ Key = "mbLowLoad", Name = "低负载模式", Desc = "降低扫描频率，人多或卡顿时开启", Default = false,
    Callback = function(v) CB("mbLowLoad", v) end })

tab:Section({ Name = "射击效果" })
tab:Expand({
    Key = "shootVisual",
    Callback = function(v) CB("shootVisual", v) end,
    Name = "射击视觉效果",
    Desc = "命中时显示追踪线 / 命中标记",
    Default = false,
    Children = {
        { Kind = "toggle", Key = "tracerOn", Name = "子弹追踪", Default = true, Callback = function(v) CB("tracerOn", v) end },
        { Kind = "cycle", Key = "tracerColor", Name = "追踪线颜色", Options = { "红", "绿", "蓝", "彩虹" }, Callback = function(v) CB("tracerColor", v) end },
        { Kind = "cycle", Key = "tracerDuration", Name = "追踪线时长", Options = { "1秒", "2秒", "3秒", "5秒" }, Callback = function(v) CB("tracerDuration", v) end },
        { Kind = "toggle", Key = "hitMarkerOn", Name = "命中标记", Default = true, Callback = function(v) CB("hitMarkerOn", v) end },
        { Kind = "cycle", Key = "hmColor", Name = "命中标记颜色", Options = { "白", "红", "青", "彩虹" }, Callback = function(v) CB("hmColor", v) end },
        { Kind = "cycle", Key = "hmDuration", Name = "命中标记时长", Options = { "1秒", "2秒", "3秒", "5秒" }, Callback = function(v) CB("hmDuration", v) end },
        { Kind = "cycle", Key = "hmSize", Name = "命中标记大小", Options = { "小", "中", "大" }, Callback = function(v) CB("hmSize", v) end },
    },
})

-- ============================================================
-- 雷达
-- ============================================================
tab = win:Tab("雷达")

tab:Section({ Name = "显示" })
tab:Expand({
    Key = "radar",
    Callback = function(v) CB("radar", v) end,
    Name = "雷达探敌",
    Desc = "小地图上显示所有敌人",
    Default = false,
    Children = {
        { Kind = "toggle", Key = "radarFast", Name = "高刷新率", Desc = "刷新更频繁，会吃点性能", Default = false, Callback = function(v) CB("radarFast", v) end },
        { Kind = "toggle", Key = "radarArrow", Name = "朝向箭头", Default = true, Callback = function(v) CB("radarArrow", v) end },
    },
})

tab:Section({ Name = "信号" })
tab:Toggle({ Key = "radarBoost", Name = "信号增幅器", Desc = "去除无信号区域干扰", Default = false,
    Callback = function(v) CB("radarBoost", v) end })

-- ============================================================
-- 其他
-- ============================================================
tab = win:Tab("其他")

tab:Section({ Name = "辅助" })
tab:Toggle({ Key = "autoInteract", Name = "及时交互", Desc = "与可互动的物体进行秒交互", Default = false,
    Callback = function(v) CB("autoInteract", v) end })
tab:Toggle({ Key = "autoQTE", Name = "自动 QTE", Desc = "QTE 自动完美完成", Default = false,
    Callback = function(v) CB("autoQTE", v) end })

tab:Section({ Name = "视角与假身（娱乐）" })
tab:Toggle({ Key = "thirdPerson", Name = "第三人称", Desc = "解锁视角，可拉远拉近", Default = false,
    Callback = function(v) CB("thirdPerson", v) end })
tab:Toggle({ Key = "noShake", Name = "镜头防抖", Desc = "去掉跑动和冲刺时的镜头晃动", Default = false,
    Callback = function(v) CB("noShake", v) end })
tab:Expand({
    Key = "spin",
    Callback = function(v) CB("spin", v) end,
    Name = "原地旋转",
    Desc = "角色原地转圈，视角不受影响",
    Default = false,
    Children = {
        { Kind = "number", Key = "spinSpeed", Name = "旋转速度", Min = 0, Max = 500, Default = 20, Callback = function(v) CB("spinSpeed", v) end },
    },
})
local nodCtrl = tab:Expand({
    Key = "nod",
    Callback = function(v) CB("nod", v) end,
    Name = "抬头低头",
    Desc = "只有头在动，身体保持直立",
    Default = false,
    Children = {
        { Kind = "cycle", Key = "nodMode", Name = "模式", Options = { "低头", "抬头", "低头+抬头" }, Callback = function(v) CB("nodMode", v) end },
    },
})
local headSpinCtrl = tab:Expand({
    Key = "headSpin",
    Callback = function(v) CB("headSpin", v) end,
    Name = "头部旋转",
    Desc = "平视后绕三轴转，10 已经很快",
    Default = false,
    Children = {
        { Kind = "cycle", Key = "headSpinDir", Name = "方向", Options = { "顺时针", "逆时针" }, Callback = function(v) CB("headSpinDir", v) end },
        { Kind = "number", Key = "headSpinX", Name = "X轴速度", Min = 0, Max = 50, Default = 0, Callback = function(v) CB("headSpinX", v) end },
        { Kind = "number", Key = "headSpinY", Name = "Y轴速度", Min = 0, Max = 50, Default = 10, Callback = function(v) CB("headSpinY", v) end },
        { Kind = "number", Key = "headSpinZ", Name = "Z轴速度", Min = 0, Max = 50, Default = 0, Callback = function(v) CB("headSpinZ", v) end },
    },
})

-- 互斥时把另一个开关的勾选框一起刷掉
_G._ExamSyncCheckbox = _G._ExamSyncCheckbox or {}
if nodCtrl and nodCtrl.SetSilent then
    _G._ExamSyncCheckbox["nod"] = function(v) nodCtrl.SetSilent(v) end
end
if headSpinCtrl and headSpinCtrl.SetSilent then
    _G._ExamSyncCheckbox["headSpin"] = function(v) headSpinCtrl.SetSilent(v) end
end

-- ============================================================
-- 版本检测
-- ============================================================
local CURRENT_VERSION = "1.2.5"
local VERSION_URL = "https://raw.githubusercontent.com/Cubee332/XXExaminationScriptXX/main/Examination.lua"

local function parseVersion(s)
    if type(s) ~= "string" then return nil end
    local a, b, c = s:match("(%d+)%.(%d+)%.(%d+)")
    if not a then return nil end
    return tonumber(a) * 10000 + tonumber(b) * 100 + tonumber(c)
end

local function versionString(v)
    local a = math.floor(v / 10000)
    local b = math.floor((v % 10000) / 100)
    local c = v % 100
    return string.format("%d.%d.%d", a, b, c)
end

local statusLabel
local hasUpdate = false
local remoteVer = nil

tab:Section({ Name = "关于脚本" })

-- 版本行：整行可点击，点一下就检测更新
local verRow
verRow = tab:ClickableRow({
    Name = "当前 v" .. CURRENT_VERSION,
    Desc = "点击此行检测最新版本",
    Arrow = true,
    Callback = function()
        if not verRow then return end
        verRow.SetBusy(true)
        verRow.Set("检测中…", "正在连接 GitHub…")

        task.spawn(function()
            local ok, result = pcall(function()
                local src = game:HttpGet(VERSION_URL .. "?t=" .. tostring(os.time()))
                return src:match("%-%-%s*Examination%s+v([%d%.]+)")
            end)

            verRow.SetBusy(false)

            if not ok or not result then
                verRow.Set("检测失败", "无法连接 GitHub，请检查网络")
                return
            end

            remoteVer = result
            local cur = parseVersion(CURRENT_VERSION)
            local rem = parseVersion(result)

            if not rem then
                verRow.Set("检测失败", "版本号解析失败")
                return
            end

            if rem > cur then
                hasUpdate = true
                verRow.Set("发现新版本 v" .. result,
                    "当前 v" .. CURRENT_VERSION .. "，请更新")
            elseif rem == cur then
                hasUpdate = false
                verRow.Set("已是最新版本", "当前 v" .. CURRENT_VERSION)
            else
                hasUpdate = false
                verRow.Set("本地版本较新",
                    "当前 v" .. CURRENT_VERSION .. " / 线上 v" .. result)
            end
        end)
    end,
})

tab:Label({ Name = "敬请期待", Desc = "此页面功能正在开发中" })

-- 注意：safeCleanup 会在开头调用一次清理旧实例；
-- 这里不要再调，否则会把刚注册的 _G._ExamSetters / _G._ExamStates 清空

getgenv().ExaminationWin = win

-- 卸载按钮
local unloadRow
unloadRow = tab:ClickableRow({
    Name = "卸载脚本",
    Desc = "停止所有功能并关闭面板",
    Arrow = true,
    Callback = function()
        if unloadRow then
            unloadRow.SetBusy(true)
            unloadRow.Set("正在卸载…", "正在清理功能…")
        end

        -- 1) 先播放面板 + 顶栏按钮的退出动画（不阻塞）
        pcall(function()
            if CDMUI and CDMUI.PlayExitAnim then
                CDMUI.PlayExitAnim(0.24)
            else
                -- 退路：手动播
                local panel = win and win.Panel
                local sc = win and win.Scale
                if panel and panel.Parent then
                    local basePos = panel.Position
                    TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        BackgroundTransparency = 1,
                    }):Play()
                    TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        Position = UDim2.new(basePos.X.Scale, basePos.X.Offset,
                                              basePos.Y.Scale, basePos.Y.Offset - 20),
                    }):Play()
                    if sc then
                        TweenService:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                            Scale = 0.85,
                        }):Play()
                    end
                    local fadeT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    for _, d in ipairs(panel:GetDescendants()) do
                        pcall(function()
                            if d:IsA("Frame") or d:IsA("ScrollingFrame") then
                                TweenService:Create(d, fadeT, { BackgroundTransparency = 1 }):Play()
                                if d:IsA("ScrollingFrame") then
                                    pcall(function()
                                        d.ScrollBarImageTransparency = 1
                                    end)
                                end
                            elseif d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                                TweenService:Create(d, fadeT, {
                                    TextTransparency = 1,
                                    BackgroundTransparency = 1,
                                }):Play()
                            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                                TweenService:Create(d, fadeT, {
                                    ImageTransparency = 1,
                                    BackgroundTransparency = 1,
                                }):Play()
                            elseif d:IsA("UIStroke") then
                                TweenService:Create(d, fadeT, { Transparency = 1 }):Play()
                            end
                        end)
                    end
                end
                -- 顶栏按钮
                local pgx = lp:FindFirstChild("PlayerGui")
                local tbx = pgx and pgx:FindFirstChild("TopbarStandard")
                local hx = tbx and tbx:FindFirstChild("Holders")
                local lx = hx and hx:FindFirstChild("Left")
                if lx then
                    for _, n in ipairs({"ControlPanelBtn", "TrialBtn"}) do
                        local o = lx:FindFirstChild(n)
                        if o then
                            pcall(function()
                                TweenService:Create(o, TweenInfo.new(0.18), {
                                    BackgroundTransparency = 1,
                                    TextTransparency = 1,
                                }):Play()
                            end)
                        end
                    end
                end
            end
        end)

        -- 2) 等动画真正播完再清理
        task.delay(0.32, function()
            -- 先停功能（可能耗时，放前面）
            pcall(function()
                if _G._ExamLastCleanup then _G._ExamLastCleanup() end
            end)

            -- 再销毁所有 UI 实例（一次性，不留给后续）
            pcall(function()
                local cg2 = game:GetService("CoreGui")
                local pg2 = lp:FindFirstChild("PlayerGui")
                for _, root in ipairs({cg2, pg2}) do
                    if root then
                        for _, d in ipairs(root:GetDescendants()) do
                            if d.Name == "ControlPanelUI" or d.Name == "CDMUIGuide"
                               or d.Name == "CDMUIWidget" or d.Name == "ControlPanelBtn" then
                                pcall(function() d:Destroy() end)
                            end
                        end
                    end
                end
                -- 顶栏按钮
                local tb3 = pg2 and pg2:FindFirstChild("TopbarStandard")
                local h3 = tb3 and tb3:FindFirstChild("Holders")
                local l3 = h3 and h3:FindFirstChild("Left")
                if l3 then
                    for _, n in ipairs({"ControlPanelBtn", "TrialBtn"}) do
                        local o = l3:FindFirstChild(n)
                        if o then pcall(function() o:Destroy() end) end
                    end
                end
            end)

            pcall(function() _G._ExamLastCleanup = nil end)
            pcall(function() _G._CDMUILastCleanup = nil end)
            pcall(function() getgenv().ExaminationUILoaded = nil end)
            pcall(function() getgenv().ExaminationWin = nil end)
        end)
    end,
})

getgenv().ExaminationUILoaded = true
print("[Examination] 已加载 · CDMUI v" .. tostring(CDMUI.Version))
