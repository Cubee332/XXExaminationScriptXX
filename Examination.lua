-- 此脚本使用AI生成
-- 因使用混淆加密会导致手机用户无法正常使用所以没有使用混淆加密
-- 请不要拿去缝合 此脚本永久免费
-- 若随意缝合和偷源码自称是自制的该脚本会进行删库处理并停止对外更新( AI写的史山代码你也要？？？？)
-- 倒卖脚本私冯！！！

--!nolint
-- Examination v1.10.44  HUD 创建即隐藏，消除「闪现+动画」两次出现
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

-- 重载时的清理
--   旧 HUD 要先播退场动画再销毁，否则会和新 HUD 叠在一起
do
    -- 1) 先让旧 HUD 播退场动画，并【同步等待】播完
    --    之前是异步的，新脚本立刻建新 HUD → 两个叠在一起
    local oldHUD = getgenv().__ExamHUDModule
    if oldHUD and oldHUD.DestroyHUDWithAnim then
        local done = false
        pcall(function()
            oldHUD.DestroyHUDWithAnim(function() done = true end)
        end)
        -- 最多等 0.5 秒（动画 0.32s + 余量）
        local waited = 0
        while not done and waited < 0.5 do
            task.wait(0.02)
            waited = waited + 0.02
        end
    end
    -- 2) 再跑完整清理
    if _G._ExamLastCleanup then
        pcall(_G._ExamLastCleanup)
        _G._ExamLastCleanup = nil
    end
    -- 2.5) 清掉旧的 ExamHiddenDock（toggle 按钮容器）
    pcall(function()
        local cgv = game:GetService("CoreGui")
        for _, d in ipairs(cgv:GetChildren()) do
            if d.Name == "ExamHiddenDock" then
                pcall(function() d:Destroy() end)
            end
        end
    end)
    -- 3) 兜底：彻底清掉所有残留的 HUD ScreenGui
    --    注意：要连子对象一起查，防止 ScreenGui 改名
    pcall(function()
        local pgv = lp and lp:FindFirstChild("PlayerGui")
        for _, root in ipairs({game:GetService("CoreGui"), pgv}) do
            if root then
                for _, d in ipairs(root:GetChildren()) do
                    if d.Name == "CDMUI_HUD" or (d:IsA("ScreenGui") and d:FindFirstChild("HudBox")) then
                        pcall(function() d:Destroy() end)
                    end
                end
            end
        end
    end)
    -- 4) 清掉旧模块引用，防止下次重载拿到失效对象
    getgenv().__ExamHUDModule = nil
    getgenv().__ExamHUDGui = nil
end
getgenv().__ExamHUDModule = nil
-- 生成唯一实例 ID：cleanup 只清自己这代的数据
local __EXAM_GEN = tostring(tick()) .. "_" .. tostring(math.random(1, 999999))
_G._ExamGen = __EXAM_GEN
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
local pierceExecutingEnabled = true   -- 穿透正在处决/被处决的目标
local headSize = 4
local slideDistanceMult = 1
local shieldVMAlpha = 0.9
local slideSteerMode = "camera"
local mbTargetMode = 1
-- 是否把 BTR 放出的无人机也纳入魔法子弹锁定（默认开）
local mbTargetDrones = true

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
-- BTR 放出来的无人机：没有 Humanoid、没有 Head，
-- 直接挂在 Workspace 下，靠属性识别。
--   属性：BTRDrone=true, BTRDroneActive=true, DroneState=Seeking
--   部件：DroneHitbox（命中盒）、DroneRoot（位置参考）
local function isBTRDrone(m)
    if not m then return false end
    if m:GetAttribute("BTRDrone") ~= true then return false end
    if m:GetAttribute("IsBTRDroneTemplate") == true then return false end
    return true
end

local function isDroneAlive(m)
    if not isBTRDrone(m) then return false end
    if m:GetAttribute("BTRDroneActive") == false then return false end
    if m:GetAttribute("BTRDroneShotDownResolved") == true then return false end
    local st = m:GetAttribute("DroneState")
    if st == "ShotDown" or st == "Destroyed" or st == "Dead" then return false end
    -- 命中盒还在就算活着
    local hit = m:FindFirstChild("DroneHitbox")
    if not hit or not hit:IsA("BasePart") then return false end
    return hit.Parent ~= nil
end

local function getDroneAimPart(m)
    if not m then return nil end
    local hit = m:FindFirstChild("DroneHitbox")
    if hit and hit:IsA("BasePart") then return hit end
    local root = m:FindFirstChild("DroneRoot")
    if root and root:IsA("BasePart") then return root end
    for _, c in ipairs(m:GetChildren()) do
        if c:IsA("BasePart") then return c end
    end
    return nil
end

-- 收集场景里所有活着的无人机
local function getAllBTRDrones()
    local out = {}
    for _, d in ipairs(Workspace:GetChildren()) do
        if isBTRDrone(d) and isDroneAlive(d) then
            table.insert(out, d)
        end
    end
    return out
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
    -- 同样加代次检查：避免误清新脚本的表
    if _G._ExamGen == __EXAM_GEN then
        _G._ExamSetters = {}
        _G._ExamStates = {}
        _G._CP_RefreshFns = {}
    end
end
pcall(safeCleanup)

_G._ExamLastCleanup = function()
    for _, fn in ipairs(cleanupFns) do pcall(fn) end

    -- 清掉 CDMUI 的 HUD（独立 ScreenGui，不在面板子树里）
    pcall(function()
        local CD = getgenv().CDMUI
        if HUD and HUD.DestroyHUD then HUD.DestroyHUD() end
    end)

    -- 断开 CDMUI 登记的所有连接（防止重载后残留）
    pcall(function()
        local CD = getgenv().CDMUI
        if CD and CD.DisconnectEverything then CD.DisconnectEverything() end
    end)
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
    -- 销毁隐藏 dock（所有 toggle 按钮的父容器）
    pcall(function()
        if _hiddenDock and _hiddenDock.Parent then
            _hiddenDock:Destroy()
        end
    end)

    -- 关键修复：只有"自己还是当前代"时才清空全局表
    --   否则新脚本已启动，旧 cleanup 会把新的 setter 全清掉
    if _G._ExamGen == __EXAM_GEN then
        _G._ExamSetters = {}
        _G._ExamStates = {}
        _G._CP_RefreshFns = {}
    end
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
["穿透处决目标"] = "pierceExecuting",
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
    local nodNeckRef = nil
    local nodBasePos = nil
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

    -- 必须在 stopHeadSpin 之前声明，否则里面清的是另一个变量
    local headStartT = nil

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
        while _hiddenDock.Parent do
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

-- ============ 模块 0.4: 人物半无敌（TauntEvent 高速触发）============
-- 原理：嘲讽动作（TauntEvent）在服务端会回满血。
--   触发越快，受伤到回满的间隙越小。
--
-- 触发方式（按速度排序）：
--   1) RenderStepped（每帧一次，60fps → 60 次/秒）
--   2) 同帧内连发 N 次（默认 3 次，相当于 180 次/秒）
--      → 覆盖同帧内的多次伤害
--
-- 只碰 Remote，不改任何客户端属性。
do
    local godEnabled = false
    local godConn = nil
    local TauntEvent = nil
    local fireCount = 0
    local BURST = 3                  -- 每帧连发次数

    local function ensureTaunt()
        if TauntEvent and TauntEvent.Parent then return TauntEvent end
        TauntEvent = nil
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            local t = rep:FindFirstChild("TauntEvent")
            if t and t:IsA("RemoteEvent") then
                TauntEvent = t
            end
        end)
        return TauntEvent
    end

    local function startLoop()
        if godConn then
            pcall(function() godConn:Disconnect() end)
            godConn = nil
        end

        godConn = RunService.RenderStepped:Connect(function()
            if not godEnabled then return end

            local char = lp.Character
            if not char then return end
            local t = ensureTaunt()
            if t then
                for _ = 1, BURST do
                    pcall(function()
                        t:FireServer()
                    end)
                    fireCount = fireCount + 1
                end
            end
        end)
    end

    local function stopLoop()
        if godConn then
            pcall(function() godConn:Disconnect() end)
            godConn = nil
        end
    end

    _G._ExamSetters.godMode = function(v)
        godEnabled = v and true or false
        _G._ExamStates.godMode = godEnabled
        if godEnabled then
            ensureTaunt()
            fireCount = 0
            startLoop()
        else
            stopLoop()
        end
    end
    _G._ExamStates.godMode = false

    _G._ExamSetters.godInterval = function(v) end

    -- 每帧连发次数可调（1~10）
    _G._ExamSetters.godBurst = function(v)
        local n = tonumber(v)
        if n then
            BURST = math.clamp(math.floor(n), 1, 10)
        end
    end

    _G._ExamGodStats = function()
        return {
            enabled = godEnabled,
            fires = fireCount,
            burst = BURST,
            hasTaunt = TauntEvent ~= nil and TauntEvent.Parent ~= nil,
            mode = "renderstepped-burst",
        }
    end

    table.insert(cleanupFns, function()
        godEnabled = false
        stopLoop()
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
    local staminaConn = nil
    local function setupLoop()
        -- 每次启动递增 token，旧循环检测到 token 变化就自行退出
        loopToken = loopToken + 1
        local myToken = loopToken
        staminaLoop = true

        -- 断开旧连接
        if staminaConn then
            pcall(function() staminaConn:Disconnect() end)
            staminaConn = nil
        end
        if not infStaminaEnabled then return end

        -- 关键修复：必须用 Stepped（游戏逻辑之前执行）
        --   RenderStepped / Heartbeat / BindToRenderStep 都会被游戏覆盖
        staminaConn = RunService.Stepped:Connect(function()
            if not infStaminaEnabled or loopToken ~= myToken then return end
            local s = getStaminaState()
            if s then
                saveOrig(s)
                applyInf(s)
            end
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
            if staminaConn then
                pcall(function() staminaConn:Disconnect() end)
                staminaConn = nil
            end
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
        if staminaConn then
            pcall(function() staminaConn:Disconnect() end)
            staminaConn = nil
        end
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
            -- 性能优化：文本没变就不写（写 Text 会触发 UI 重排，很贵）
            if tl.Text ~= txt then
                tl.Text = txt
            end
            local wantEnabled = (txt ~= "")
            if bb.Enabled ~= wantEnabled then
                bb.Enabled = wantEnabled
            end
        end
        for _, fn in ipairs(AI_CONTAINERS) do
            local f = Workspace:FindFirstChild(fn)
            if f then for _, c in ipairs(f:GetChildren()) do refreshIn(c) end end
        end
        -- 特殊变异体（Barnacles 等，无 Humanoid）
        local ms = Workspace:FindFirstChild("Mutant_Specials")
        if ms then for _, c in ipairs(ms:GetChildren()) do refreshIn(c) end end
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
        -- 特殊变异体
        local ms = Workspace:FindFirstChild("Mutant_Specials")
        if ms then for _, c in ipairs(ms:GetChildren()) do cleanIn(c) end end

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
    -- 读 BTR 血量，返回 hp, maxHp
    --   来源优先级：
    --     ① 模型自身的 Health / HP 属性
    --     ② BTRRoot 的 Health / HP 属性
    --     ③ 任意子孙的 Health / HP 属性（有些版本挂在 Weapon / Turret 上）
    --     ④ Humanoid.Health / MaxHealth
    --   之前只查 ① ②，且刷新时只认 Humanoid，
    --   BTR 没有 Humanoid 或血量放在属性里时就显示不对
    local function readNumAttr(inst)
        for _, k in ipairs({"Health", "HP", "health", "hp", "CurrentHealth", "currentHealth"}) do
            local v = inst:GetAttribute(k)
            if type(v) == "number" then return v end
        end
        return nil
    end

    local function readMaxAttr(inst)
        for _, k in ipairs({"MaxHealth", "MaxHP", "maxHealth", "maxHp",
                            "HealthMax", "TotalHealth", "ScaledMaxHealth", "scaledMaxHealth"}) do
            local v = inst:GetAttribute(k)
            if type(v) == "number" and v > 0 then return v end
        end
        return nil
    end

    -- 读 BTR 血量，返回 hp, maxHp
    --   实测数据（考试这张图）：
    --     Health         = 560      ← 永远不变，不能直接用
    --     MaxHealth      = 560
    --     HealthPercent  = 0.857    ← 真实百分比，随受伤更新
    --     ScaledMaxHealth= 560
    --   所以真实血量 = HealthPercent * MaxHealth
    local function getBTRHealth(btr)
        if not btr then return nil end

        local maxHp = readMaxAttr(btr)

        -- ① 优先用 HealthPercent（唯一会随伤害更新的字段）
        local pct = btr:GetAttribute("HealthPercent")
        if type(pct) ~= "number" then
            pct = btr:GetAttribute("healthPercent")
        end
        if type(pct) == "number" then
            if not maxHp then
                maxHp = readMaxAttr(btr)
            end
            -- 有些实现里百分比可能是 0~100
            if pct > 1.5 then pct = pct / 100 end
            if maxHp and maxHp > 0 then
                return pct * maxHp, maxHp
            end
            return pct, maxHp
        end

        -- ② 没有百分比：退回 Health 属性
        local hp = readNumAttr(btr)
        if hp then return hp, maxHp end

        -- ③ BTRRoot
        local r = btr:FindFirstChild("BTRRoot")
        if r then
            hp = readNumAttr(r)
            maxHp = readMaxAttr(r) or maxHp
            if hp then return hp, maxHp end
        end

        -- ④ 子孙属性（只扫两层，避免开销）
        for _, c in ipairs(btr:GetChildren()) do
            hp = readNumAttr(c)
            maxHp = readMaxAttr(c) or maxHp
            if hp then return hp, maxHp end
            if c:IsA("Model") or c:IsA("Folder") then
                for _, g in ipairs(c:GetChildren()) do
                    hp = readNumAttr(g)
                    maxHp = readMaxAttr(g) or maxHp
                    if hp then return hp, maxHp end
                end
            end
        end

        -- ⑤ Humanoid
        local hum = btr:FindFirstChildOfClass("Humanoid")
        if hum then
            maxHp = maxHp or hum.MaxHealth
            return hum.Health, maxHp
        end

        return nil, maxHp
    end
    -- 诊断用：打印 BTR 的真实数据结构，排查血量来源
    --   用法：getgenv().ExamDebugBTR()
    getgenv().ExamDebugBTR = function()
        local btr = getBTRModel()
        if not btr then
            print("[BTR] 当前地图没有 BTR-82 (BOSS)")
            return
        end
        print("[BTR] 模型=" .. btr:GetFullName())
        print("[BTR] 属性:")
        for k, v in pairs(btr:GetAttributes()) do
            print(string.format("       %s = %s (%s)", k, tostring(v), typeof(v)))
        end
        local root = btr:FindFirstChild("BTRRoot")
        if root then
            print("[BTR] BTRRoot 属性:")
            for k, v in pairs(root:GetAttributes()) do
                print(string.format("       %s = %s (%s)", k, tostring(v), typeof(v)))
            end
        end
        local sum = 0
        for _, d in ipairs(btr:GetDescendants()) do
            for k, v in pairs(d:GetAttributes()) do
                if k:lower():find("health") or k:lower():find("hp") then
                    print(string.format("[BTR] 子孙 %s -> %s = %s", d:GetFullName(), k, tostring(v)))
                end
            end
            sum = sum + 1
        end
        local hum = btr:FindFirstChildOfClass("Humanoid")
        if hum then
            print(string.format("[BTR] Humanoid: Health=%.1f Max=%.1f", hum.Health, hum.MaxHealth))
        else
            print("[BTR] 无 Humanoid")
        end
        local hp, mx = getBTRHealth(btr)
        print(string.format("[BTR] getBTRHealth 结果: hp=%s max=%s", tostring(hp), tostring(mx)))
        print("[BTR] 子孙数量=" .. sum)
    end

    -- BTR 是否已被摧毁（属性 Destroyed 或血量 <= 0）
    local function isBTRDead(btr)
        if not btr then return true end
        if btr:GetAttribute("Destroyed") == true then return true end
        local hp = getBTRHealth(btr)
        return hp ~= nil and hp <= 0
    end

    local function removeBTR(btr)
        if not btr then return end
        for _, ch in ipairs(btr:GetChildren()) do
            if isOurESPNode(ch) then pcall(function() ch:Destroy() end) end
        end
    end
    -- 模型是否已在刷新列表里
    local function isInLabelList(model)
        for _, it in ipairs(labelRefreshList) do
            if it.model == model then return true end
        end
        return false
    end

    local function highlightBTR(btrModel)
        if not espEnabled then return end
        local hp, maxHp = getBTRHealth(btrModel)
        if hp and hp <= 0 then removeBTR(btrModel); return end

        if btrModel:FindFirstChild(ESP_HL_NEW) then
            -- 节点还在，但不在刷新列表里（被上一轮清掉了）：
            --   重建一次，顺便重新登记，否则血量永远不更新
            if isInLabelList(btrModel) then return end
            removeBTR(btrModel)
        end
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
        local function btrText(cur, maxCur)
            local parts = {}
            if showESPName then table.insert(parts, "BTR-82") end
            if showESPHealth and cur then
                if maxCur and maxCur > 0 then
                    table.insert(parts, string.format("%d / %d",
                        math.floor(cur), math.floor(maxCur)))
                else
                    table.insert(parts, tostring(math.floor(cur)))
                end
            end
            if #parts == 0 then return "" end
            if showESPName then
                return "[BOSS] " .. table.concat(parts, " | ")
            end
            return table.concat(parts, " | ")
        end
        tl.Text = btrText(hp, maxHp)
        table.insert(labelRefreshList, {
            model = btrModel, tl = tl, pre = "", hl = hl, bb = bb,
            isBTR = true, maxHp = maxHp,
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
        -- 标签格式：[无人机] 血量
        --   之前是 "[无人机] 无人机 | 血量"，名字重复了
        local function droneText(cur, max)
            local parts = {}
            if showESPHealth then
                if cur and max then
                    table.insert(parts, string.format("%d / %d", math.floor(cur), math.floor(max)))
                elseif cur then
                    table.insert(parts, tostring(math.floor(cur)))
                end
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
        -- 特殊变异体（Barnacles 等，无 Humanoid 但有 GrabField）
        local ms = Workspace:FindFirstChild("Mutant_Specials")
        if ms then
            for _, v in ipairs(ms:GetChildren()) do
                if isAICharacter(v) then
                    local c, t = classify(v)
                    highlightAI(v, c, t)
                end
            end
            table.insert(espConnections, ms.ChildAdded:Connect(function(v)
                task.wait(0.1)
                if espEnabled and isAICharacter(v) then
                    local c, t = classify(v)
                    highlightAI(v, c, t)
                end
                if not espEnabled then cleanAllESP() end
            end))
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
                        -- 节点在但没登记进刷新列表：也要重建，否则血量冻结
                        if not isInLabelList(b) then need = true end
                        if need and tick() - lastRefresh > 1 then
                            lastRefresh = tick(); highlightBTR(b)
                        end
                        if hp then lastHP = hp end
                    end
                else lastHP = nil end
            end
        end)
    end

    -- 诊断：查看 ESP 刷新列表当前内容
    getgenv().ExamDebugESPList = function()
        local parts = {"tick=" .. tostring(_G.__ExamESPTick or 0),
                       "n=" .. #labelRefreshList,
                       "espEnabled=" .. tostring(espEnabled)}
        for i, it in ipairs(labelRefreshList) do
            parts[#parts+1] = string.format("[%d] model=%s isBTR=%s isDrone=%s text=%s",
                i,
                tostring(it.model and it.model.Name),
                tostring(it.isBTR),
                tostring(it.isDrone),
                tostring(it.tl and it.tl.Text))
        end
        return table.concat(parts, "\n")
    end

    spawn(function()
        while _hiddenDock.Parent do
            -- 性能优化：0.3 -> 0.5（透视文字不需要那么频繁刷新）
            task.wait(espLowLoad and 1.2 or 0.5)
            _G.__ExamESPTick = (_G.__ExamESPTick or 0) + 1
            if espEnabled then
                for i = #labelRefreshList, 1, -1 do
                    local item = labelRefreshList[i]
                    local m = item.model
                    if not m or not m.Parent or not m:FindFirstChild(ESP_HL_NEW) then
                        table.remove(labelRefreshList, i)
                    elseif item.isBTR then
                        -- ===== BTR 单独处理：不依赖 Humanoid =====
                        --   血量可能存在属性里，也可能在 Humanoid 上，
                        --   用 getBTRHealth 统一读，谁有就用谁
                        local hp, maxHp = getBTRHealth(m)
                        if maxHp then item.maxHp = maxHp end
                        -- 注意：这里的模型变量是 m，不是 btr
                        local dead = isBTRDead(m)
                        if dead then
                            -- 真死了：清掉高亮
                            for _, c in ipairs(m:GetChildren()) do
                                if isOurESPNode(c) then pcall(function() c:Destroy() end) end
                            end
                            table.remove(labelRefreshList, i)
                        elseif hp then
                            -- 活着：刷新文字
                            local txtParts = {}
                            if showESPName then table.insert(txtParts, "BTR-82") end
                            if showESPHealth then
                                local mx = item.maxHp
                                if mx and mx > 0 then
                                    table.insert(txtParts, string.format("%d / %d",
                                        math.floor(hp), math.floor(mx)))
                                else
                                    table.insert(txtParts, tostring(math.floor(hp)))
                                end
                            end
                            local btxt
                            if #txtParts > 0 then
                                btxt = (showESPName and "[BOSS] " or "")
                                    .. table.concat(txtParts, " | ")
                            else
                                btxt = ""
                            end
                            if item._lastTxt ~= btxt then
                                item._lastTxt = btxt
                                item.tl.Text = btxt
                            end
                        end
                    else
                        -- 性能优化：缓存 Humanoid 引用
                        local hum = item._hum
                        if not hum or not hum.Parent then
                            hum = m:FindFirstChildOfClass("Humanoid")
                            item._hum = hum
                        end
                        if hum then
                            if hum.Health <= 0 then
                                for _, c in ipairs(m:GetChildren()) do
                                    if isOurESPNode(c) then pcall(function() c:Destroy() end) end
                                end
                                table.remove(labelRefreshList, i)
                            elseif item.isDrone then
                                local dtxt = "[无人机] " .. math.floor(hum.Health)
                                    .. " / " .. math.floor(hum.MaxHealth)
                                if item._lastTxt ~= dtxt then
                                    item._lastTxt = dtxt
                                    item.tl.Text = dtxt
                                end
                            else
                                -- 性能优化：文本没变就不设置（避免 UI 重排）
                                local newTxt = genText(m, hum, item.pre)
                                if item._lastTxt ~= newTxt then
                                    item._lastTxt = newTxt
                                    item.tl.Text = newTxt
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
            while crateEnabled and _hiddenDock.Parent do
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

    -- 锁定部位（1=头部 2=身体 ...）
    -- 真正的 setter 在模块 17 里定义（需要刷新小人高亮），这里只初始化状态
    _G._ExamStates.mbAimPart = 1
    if _G._ExamAimPartIndex == nil then _G._ExamAimPartIndex = 1 end

    -- 玩家血量/名称需要持续刷新（血量会变）
    spawn(function()
        while _hiddenDock.Parent do
            task.wait(0.5)
            if espEnabled and showPlayers then
                refreshPlayerESP()
            end
        end
    end)
    -- 兜底轮询：只在开启状态下检查异常残留，关闭时由 clearESP 即时处理
    spawn(function()
        while _hiddenDock.Parent do
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
        while _hiddenDock.Parent do
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
            slideDistanceMult = val
            slideDistInput.Text = tostring(slideDistanceMult)
            _G._ExamStates.slideDistanceMult = slideDistanceMult
        else
            slideDistInput.Text = tostring(slideDistanceMult)
        end
    end)
    _G._ExamSetters.slideDistanceMult = function(v)
        if type(v) == "number" and v >= 1 and v <= 10 then
            slideDistanceMult = v
            slideDistInput.Text = tostring(v)
            _G._ExamStates.slideDistanceMult = v
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
            while nvgEnabled and _G._InfNVG_Token == _nvgTok and _hiddenDock.Parent do
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
            while elephantImmuneEnabled and elephantToken == _elTok and _hiddenDock.Parent do
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
            while frEnabled and _hiddenDock.Parent and frLoopToken == my do
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
            while recoilEnabled and recoilToken == _rcTok and _hiddenDock.Parent do
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

    -- 判断一只感染怪现在能不能被肘击
    --   和魔法子弹的 isDowned 判定完全对齐：
    --     不能：死亡 / 正在处决动画 / 瘫倒 / 复活中 / PlatformStand
    --   不建议：免处决（打了不理会）
    local function bashableState(model, hum)
        if not hum then return false, "no-hum" end
        if hum.Health <= 0 then return false, "dead" end

        local ok, st = pcall(function() return hum:GetState() end)
        if ok then
            if st == Enum.HumanoidStateType.Dead then return false, "dead" end
            -- 处决动画期间 Humanoid 会被 PlatformStand，
            -- 被打倒之类的是 FallingDown，这两种都不该再去打
            if st == Enum.HumanoidStateType.PlatformStanding then return false, "executing" end
            if st == Enum.HumanoidStateType.FallingDown then return false, "knocked" end
            if st == Enum.HumanoidStateType.Physics then return false, "physics" end
        end

        -- 处决中：和魔法子弹同款检测（属性 + 子对象）
        if hum.PlatformStand == true then return false, "platform-stand" end
        if model:FindFirstChild("BeingExecuted") ~= nil then return false, "executing" end
        if model:FindFirstChild("IsBeingExecuted") ~= nil then return false, "executing" end
        if model:GetAttribute("BeingExecuted") == true then return false, "executing" end
        if model:GetAttribute("IsExecuting") == true then return false, "executing" end

        -- 复活中
        local br = model:FindFirstChild("IsBusyResurrecting")
        if br and br:IsA("BoolValue") and br.Value then return false, "resurrecting" end

        return true, "ok"
    end

    -- 判断我们自己当前是否在处决流程里（处决者或被处决者）
    --   在处决动画期间，任何肘击都不该触发：
    --     · 肘击会打断处决动画
    --     · 处决期间角色被 PlatformStand，按键无效反而浪费
    local function iAmInExecution()
        local char = lp.Character
        if not char then return false end
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then
            -- 修复：PlatformStand 单独不足以判定「处决中」
            --   被打倒（downed/knocked）时 PlatformStand 也是 true，
            --   但那时候应该允许自动肘击
            --   真正的处决中：有处决标记 或 状态是 PlatformStanding 且有 Executing 子对象
            local hasExecMark = char:FindFirstChild("Executing") ~= nil
                or char:FindFirstChild("IsExecuting") ~= nil
                or char:GetAttribute("IsExecuting") == true
                or char:FindFirstChild("BeingExecuted") ~= nil
                or char:FindFirstChild("IsBeingExecuted") ~= nil
                or char:GetAttribute("BeingExecuted") == true

            -- 有明确的处决标记 → 真的在处决
            if hasExecMark then return true end

            -- PlatformStand 但没有处决标记 → 被打倒，不算处决
            --   但如果状态是 PlatformStanding 且血量 > 0，说明是在被处决流程
            local ok, st = pcall(function() return h:GetState() end)
            if ok and st == Enum.HumanoidStateType.PlatformStanding then
                -- 再检查一次：游戏是否在处决（有 Executing 属性/子对象）
                if char:GetAttribute("ExecutionTarget") ~= nil then return true end
                if char:FindFirstChild("ExecutionTarget") ~= nil then return true end
                if char:FindFirstChild("ExecutingTarget") ~= nil then return true end
            end
        end
        if char:FindFirstChild("BeingExecuted") ~= nil then return true end
        if char:FindFirstChild("IsBeingExecuted") ~= nil then return true end
        if char:FindFirstChild("Executing") ~= nil then return true end
        if char:FindFirstChild("IsExecuting") ~= nil then return true end
        if char:GetAttribute("BeingExecuted") == true then return true end
        if char:GetAttribute("IsBeingExecuted") == true then return true end
        if char:GetAttribute("IsExecuting") == true then return true end
        return false
    end

    -- 判断某个模型是否有其他玩家在处决它（或它在处决别人）
    --   避免我们去抢队友的处决目标
    local function otherPlayerInvolved(model)
        if not model then return false end
        local mHrp = model:FindFirstChild("HumanoidRootPart")
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp then
                local pc = pl.Character
                if pc then
                    -- 玩家自己在处决流程里
                    local ph = pc:FindFirstChildOfClass("Humanoid")
                    local pExec = false
                    if ph then
                        if ph.PlatformStand == true then pExec = true end
                        if not pExec then
                            local ok, st = pcall(function() return ph:GetState() end)
                            if ok and st == Enum.HumanoidStateType.PlatformStanding then pExec = true end
                        end
                    end
                    if not pExec then
                        if pc:FindFirstChild("BeingExecuted") ~= nil then pExec = true end
                        if pc:GetAttribute("IsExecuting") == true then pExec = true end
                        if pc:GetAttribute("BeingExecuted") == true then pExec = true end
                    end

                    if pExec then
                        -- 玩家和这个模型靠得很近（处决必须贴身）
                        local pHrp = pc:FindFirstChild("HumanoidRootPart")
                        if pHrp and mHrp then
                            if (pHrp.Position - mHrp.Position).Magnitude <= 8 then
                                return true
                            end
                        end
                        -- 或者模型上有指向该玩家的标记
                        if model:GetAttribute("ExecutedBy") == pl.Name then return true end
                        if model:GetAttribute("Executor") == pl.Name then return true end
                    end
                end
            end
        end
        return false
    end

    -- 免处决的怪打了不会有效果，记录一下供上层决策
    local function isImmuneToExecution(model)
        local imm = model:FindFirstChild("ImmuneToExecution")
        return imm ~= nil and imm:IsA("BoolValue") and imm.Value == true
    end

    -- 反伤风险判定：
    --   ImmuneToExecution + TaserImmune 同时成立的（奇美拉、Gilbert 这类）
    --   肘击有效果，但会把伤害反弹回来
    local function isReflectRisk(model)
        local imm = model:FindFirstChild("ImmuneToExecution")
        local taserImm = model:FindFirstChild("TaserImmune")
        local hasImm = imm ~= nil and imm:IsA("BoolValue") and imm.Value == true
        local hasTaserImm = taserImm ~= nil and taserImm:IsA("BoolValue") and taserImm.Value == true
        return hasImm and hasTaserImm
    end

    -- 完全打不动：既免处决、又不是反伤类型的（目前没发现，保留位）
    -- 这两个类型都需要用 EID 之外的手段，肘击本身不负责
    local function isBashIneffective(model)
        return isReflectRisk(model)
    end

    local function isInfected(model)
        if not model or not model:IsA("Model") then return false end
        -- 排除玩家
        if Players:GetPlayerFromCharacter(model) then return false end

        local hum = model:FindFirstChildOfClass("Humanoid")
        -- 必须活着：血量为 0 或已死亡状态都跳过，避免鞭尸
        if not hum or hum.Health <= 0 then return false end
        local ok, st = pcall(function() return hum:GetState() end)
        if ok and st == Enum.HumanoidStateType.Dead then return false end
        -- 处决中 / 瘫倒 / 复活中也不算有效目标（和魔法子弹一致）
        if hum.PlatformStand == true then return false end
        if ok and st == Enum.HumanoidStateType.PlatformStanding then return false end
        if model:FindFirstChild("BeingExecuted") ~= nil then return false end
        if model:GetAttribute("BeingExecuted") == true then return false end
        -- 有些尸体模型血还是正的，额外看 Humanoid 是否还能动
        if hum.WalkSpeed <= 0 and hum.Health <= 0 then return false end

        if model:GetAttribute("IsInfectedAI") == true then return true end
        return false
    end

    -- 检测范围要比肘击范围大，才能提前预判
    local SCAN_RANGE = 22
    -- 怪物进到这个距离就一定按，不等它贴脸（可由 UI 调）
    local PANIC_RANGE = 9
    -- 必须在 setter 之前声明：否则 setter 里写的是另一个变量，
    -- 环的尺寸缓存永远不会被清掉，改半径后圈不跟着变
    local lastRingRadius = nil
    _G._ExamSetters.bashRange = function(v)
        local n = tonumber(v)
        if not n then return end
        PANIC_RANGE = math.clamp(n, 4, 20)
        _G._ExamStates.bashRange = PANIC_RANGE
        -- 半径变了，让范围圈下帧重算尺寸
        lastRingRadius = nil
    end
    _G._ExamStates.bashRange = 9

    -- 是否主动去肘反伤类 BOSS（奇美拉、Gilbert）
    --   默认开启：肘击对它们是有效的，只是会反伤
    local bashReflectBoss = true
    _G._ExamSetters.bashReflectBoss = function(v)
        if v == 1 or v == "否" or v == "不击打" or v == "不反伤" or v == false then
            bashReflectBoss = false
            _G._ExamStates.bashReflectBoss = 1
        elseif v == 2 or v == "是" or v == "击打" or v == "可反伤" or v == true then
            bashReflectBoss = true
            _G._ExamStates.bashReflectBoss = 2
        else
            return
        end
    end
    -- 默认开启（击打反伤怪）
    _G._ExamStates.bashReflectBoss = 2

    ------------------------------------------------------------------
    -- 肘击范围显示（和 360° 半径显示同一套做法）
    ------------------------------------------------------------------
    local SEGMENTS = 48
    local ringParts = {}
    local ringModel = nil
    local facePart = nil
    local showRange = false
    local bashRangeMode = "line"

    local function destroyRingImpl()
        for _, q in ipairs(ringParts) do
            if q and q.Parent then pcall(function() q:Destroy() end) end
        end
        ringParts = {}
        if ringModel and ringModel.Parent then pcall(function() ringModel:Destroy() end) end
        ringModel = nil
        lastRingRadius = nil        -- 环重建了，尺寸要重算
        cachedGroundY = nil         -- 地面缓存也要清
        lastBaseX, lastBaseY, lastBaseZ = nil, nil, nil
    end

    local function destroyFaceImpl()
        if facePart and facePart.Parent then pcall(function() facePart:Destroy() end) end
        facePart = nil
    end

    local destroyRing = destroyRingImpl

    local destroyFace = destroyFaceImpl

    local function ensureRing()
        -- 用「1 个圆环 MeshPart + 1 个 SurfaceGui」画整圈，
        -- 替代原来的 48 个部件 + 48 个 SurfaceGui。
        -- 渲染调用从 96 次降到 2 次，掉帧问题基本消除。
        if ringModel and ringModel.Parent and ringModel:FindFirstChild("ExamBashRingDisc") then
            return
        end
        destroyRing()

        local m = Instance.new("Model")
        m.Name = "ExamBashRingModel"
        m.Parent = Workspace
        ringModel = m

        -- 圆环主体：薄方板，平放在地面，SurfaceGui 贴顶面
        -- （之前用 Cylinder + Face=Top，那个面是圆柱的窄边带，几乎看不见）
        local q = Instance.new("Part")
        q.Name = "ExamBashRingDisc"
        q.Shape = Enum.PartType.Block
        q.Size = Vector3.new(PANIC_RANGE * 2, 0.05, PANIC_RANGE * 2)
        q.Material = Enum.Material.SmoothPlastic
        q.Color = Color3.fromRGB(255, 190, 60)
        q.Transparency = 1
        q.CanCollide = false; q.CanQuery = false; q.CanTouch = false
        q.Anchored = true; q.CastShadow = false
        q.Parent = m

        -- SurfaceGui 画在圆柱顶面：一个圆环描边
        local sg = Instance.new("SurfaceGui")
        sg.Name = "Ring"
        sg.Face = Enum.NormalId.Top
        sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        sg.PixelsPerStud = 8             -- 圆环只需要轮廓，低分辨率就够
        sg.AlwaysOnTop = false
        sg.LightInfluence = 0
        sg.Adornee = q
        sg.Parent = q

        -- 用 UIStroke 画圆环：一个 UICorner 圆 + 描边
        local f = Instance.new("Frame")
        f.Name = "RingFrame"
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.new(0.5, 0, 0.5, 0)
        f.Size = UDim2.new(1, 0, 1, 0)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.Parent = sg
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = f
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 190, 60)
        stroke.Thickness = 3
        stroke.Transparency = 0.1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = f

        m.PrimaryPart = q
        lastRingRadius = PANIC_RANGE
        return
    end

    -- 地面射线缓存（每 6 帧更新一次）
    local cachedGroundY = nil
    local cachedRayX, cachedRayZ = 0, 0
    local lastBaseX, lastBaseY, lastBaseZ = nil, nil, nil
    local ringFrame = 0

    local function updateRing()
        ringFrame = ringFrame + 1
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then destroyRing(); destroyFace(); return end
        if not showRange then destroyRing(); destroyFace(); return end
        if not autoBashEnabled then destroyRing(); destroyFace(); return end

        -- 向下射线找地面：每 6 帧才做一次，缓存结果
        --   每帧射线是主要开销之一，角色移动慢时完全没必要
        local groundY = cachedGroundY
        if groundY == nil or ringFrame % 6 == 0
           or math.abs(hrp.Position.X - cachedRayX) > 3
           or math.abs(hrp.Position.Z - cachedRayZ) > 3 then
            groundY = hrp.Position.Y - 2.3
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {char}
            local origin = Vector3.new(hrp.Position.X, hrp.Position.Y + 2, hrp.Position.Z)
            local hit = Workspace:Raycast(origin, Vector3.new(0, -20, 0), params)
            if hit then groundY = hit.Position.Y end
            cachedGroundY = groundY
            cachedRayX = hrp.Position.X
            cachedRayZ = hrp.Position.Z
        end
        local base = Vector3.new(hrp.Position.X, groundY + 0.7, hrp.Position.Z)
        -- 圈按「真实判定半径」画，不用自适应预判值
        --   之前圈画的是含预判扩张的半径，比实际能肘到的距离大一截
        local r = PANIC_RANGE

        if bashRangeMode == "line" then
            if facePart then destroyFace() end
            ensureRing()

            local disc = ringModel and ringModel:FindFirstChild("ExamBashRingDisc")
            if disc then
                -- 每次都设尺寸和位置。
                --   单个 Part 的属性写入开销可以忽略，
                --   之前用 lastRingRadius 缓存判断，实测会出现「值变了圈没更新」的鬼情况
                --   （bashRange 5 时圈还是 8.6，明显是上一次的残留）。
                disc.Size = Vector3.new(r * 2, 0.05, r * 2)
                disc.CFrame = CFrame.new(base)
            end
        else
            if #ringParts > 0 then destroyRing() end
            if not facePart or not facePart.Parent then
                -- 用薄方板平放，SurfaceGui 贴顶面画实心圆
                --   之前用 Cylinder + Face=Top，那个 Top 是圆柱的窄边带，
                --   转了 90° 之后几乎看不见，所以面状模式一直不显示
                local q = Instance.new("Part")
                q.Name = "ExamBashFace"
                q.Shape = Enum.PartType.Block
                q.Material = Enum.Material.SmoothPlastic
                q.Color = Color3.fromRGB(255, 190, 60)
                q.Transparency = 1          -- 本体不渲染，靠 SurfaceGui 画
                q.CanCollide = false; q.CanQuery = false; q.CanTouch = false
                q.Anchored = true; q.CastShadow = false
                q.Parent = Workspace
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
                -- 圆角拉满 = 圆形
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = f
                facePart = q
            end
            local d = r * 2
            facePart.Size = Vector3.new(d, 0.05, d)
            facePart.CFrame = CFrame.new(base)
        end
    end

    -- 肘击循环里顺带刷新范围圈
    local rangeConn = nil
    local function startRangeLoop()
        if rangeConn then return end
        -- 用 Heartbeat 而不是 RenderStepped，并且隔一帧跑一次
        --   圈是地面装饰，30fps 更新完全够用，帧率直接翻倍回来
        local skip = false
        rangeConn = RunService.Heartbeat:Connect(function()
            if not showRange or not autoBashEnabled then return end
            skip = not skip
            if skip then return end
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

    -- 选目标：不是简单取最近的那只，而是按「威胁」排序
    --   威胁 = 到达时间（越快越危险）+ 是否在背后袭击 + 束缚距离
    -- 实战中经常是好几只同时冲过来，只盯最近的会被另一只抓
    local function nearestTarget()
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end

        local best, bestD, bestScore = nil, math.huge, math.huge
        local chars = Workspace:FindFirstChild("Characters")
        local containers = {}
        if chars then containers[#containers + 1] = chars end
        local ais = Workspace:FindFirstChild("AI")
        if ais then containers[#containers + 1] = ais end

        local myVel = hrp.AssemblyLinearVelocity
        local myPos = hrp.Position

        for _, c in ipairs(containers) do
            for _, m in ipairs(c:GetChildren()) do
                if isInfected(m) then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    -- 处决中 / 瘫倒 / 复活中 的直接跳过，不去摸
                    local can, why = bashableState(m, hum)
                    -- 反伤类：默认避开，除非用户自己打开
                    local reflectOK = bashReflectBoss or not isReflectRisk(m)
                    -- 队友正在处决这个目标 → 别去抢
                    if can and otherPlayerInvolved(m) then can = false end
                    if can and reflectOK then
                    local thrp = m:FindFirstChild("HumanoidRootPart")
                    if thrp then
                        local delta = thrp.Position - myPos
                        local d = delta.Magnitude
                        if d <= SCAN_RANGE then
                            -- 它朝我靠近的速度
                            local toMe = -delta
                            local approach = 0
                            if d > 0.1 then
                                approach = thrp.AssemblyLinearVelocity:Dot(delta.Unit)
                                if approach < 0 then approach = 0 end
                            end
                            -- 我自己朝它冲的速度（也算进来）
                            local myApproach = 0
                            if d > 0.1 then
                                myApproach = myVel:Dot(-delta.Unit)
                                if myApproach < 0 then myApproach = 0 end
                            end
                            local rel = approach + myApproach
                            -- 到达时间：用怪物真实速度算（不用固定 50 假设）
                            --   慢速怪物到达时间会很长 → 优先级自然降低
                            local monsterSpeed = thrp.AssemblyLinearVelocity.Magnitude
                            local eta
                            if rel > 1 then
                                -- 有相对接近速度：按真实速度算
                                eta = math.max(0, d - PANIC_RANGE) / rel
                            elseif monsterSpeed > 1 then
                                -- 怪物在动但没朝我：按它自身速度算
                                eta = d / monsterSpeed
                            else
                                -- 完全静止：给一个很大的 eta，优先级最低
                                eta = d / 2
                            end

                            -- 慢速怪额外惩罚：速度 < 10 的怪，eta 乘以惩罚系数
                            --   避免"怪走得很慢但离得近"被误判为高威胁
                            if monsterSpeed < 10 then
                                local slowPenalty = 1 + (10 - monsterSpeed) / 10 * 1.5
                                eta = eta * slowPenalty
                            end

                            -- 背后来的要提前发现：看正前方向和它位置的夹角
                            local score = eta
                            local look = hrp.CFrame.LookVector
                            if d > 0.1 then
                                local dot = look:Dot(delta.Unit)
                                if dot < -0.3 then
                                    -- 在背后，危险度提升
                                    score = score * 0.55
                                elseif dot < 0.3 then
                                    -- 侧面
                                    score = score * 0.8
                                end
                            end
                            -- 超近直接置顶（含提前量范围）
                            if d <= PANIC_RANGE + 2 then score = -1 end

                            if score < bestScore then
                                bestScore = score
                                best = m
                                bestD = d
                            end
                        end
                    end
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
        -- 危险距离：比 PANIC_RANGE 稍大，留出肘击判定时间
        local eff = PANIC_RANGE + 2
        if dist <= eff then return true end
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

        -- 怪物自身速度（判断它是不是真的在快速接近）
        local monsterSpeed = thrp.AssemblyLinearVelocity.Magnitude

        if approach < 1 then
            -- 双方都没在靠近，等它近一点再说
            --   慢速怪要求更近才触发（避免提前打空）
            if monsterSpeed < 8 then
                return dist <= PANIC_RANGE
            end
            return dist <= PANIC_RANGE + 3
        end

        -- 预判提前量：按怪物接近速度动态调整
        --   快速怪（fury 之类）要打得更早，否则会被它先砍到
        local lead = 0.28 + math.min(myApproach / 40, 0.22)

        if monsterApproach < 8 then
            -- 怪物自己没在快速靠近：不加提前量，等它进危险区
            lead = 0
        else
            -- 快速怪：接近速度越快，提前量越大
            --   monsterApproach = 20 → +0.25s
            --   monsterApproach = 40 → +0.50s
            --   monsterApproach = 60 → +0.75s（上限）
            local speedBonus = math.min(monsterApproach / 80, 0.75)
            lead = lead + speedBonus
        end

        -- 预测 lead 秒后会不会进入危险距离
        local eta = dist - approach * lead
        return eta <= eff
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

    -- 记录一次按下，返回按下时刻（自适应模式用来量延迟）
    local function pressBash()
        local t0 = os.clock()
        if IS_MOBILE then
            if fireBashButton() then return t0 end
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
        return t0
    end

    local function start()
        if loopToken > 0 then return end
        loopToken = (loopToken or 0) + 1
        local my = loopToken
        task.spawn(function()
            while autoBashEnabled and _hiddenDock.Parent and loopToken == my do
                -- 我们自己在处决流程里 → 完全停止肘击
                --   处决动画期间按 G 会打断处决，而且 PlatformStand 下按键无效
                if iAmInExecution() then
                    task.wait(0.1)
                else
                    local target, dist = nearestTarget()

                    if target and os.clock() - lastBash >= INTERVAL
                       and shouldBashNow(target, dist) then
                        lastBash = os.clock()
                        pressBash()
                    end
                    -- 扫得勤一点，反应才跟得上
                    task.wait(0.05)
                end
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
            while shieldFixEnabled and _hiddenDock.Parent do
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
            while shieldFixEnabled and _hiddenDock.Parent do
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
        while _hiddenDock.Parent do
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
        while _hiddenDock.Parent do
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
    -- 实时从 _G 读，UI 改了立刻生效
    local function getAimPartIndex() return _G._ExamAimPartIndex or 1 end
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
            while _hiddenDock.Parent do
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
            or m:FindFirstChild("IsBeingExecuted") ~= nil
            or m:GetAttribute("BeingExecuted") == true
            or m:GetAttribute("IsExecuting") == true
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

        -- 处决动画 / 瘫倒 / 复活中：不管是不是 BOSS 都不能锁
        -- （之前只对 BOSS 名单里的判断，普通怪进处决动画会被误锁）
        local ok, st = pcall(function() return hum:GetState() end)
        if ok then
            if st == Enum.HumanoidStateType.Dead then return true end
            if st == Enum.HumanoidStateType.PlatformStanding then return true end
            if st == Enum.HumanoidStateType.FallingDown then return true end
            if st == Enum.HumanoidStateType.Physics then return true end
        end
        if hum.PlatformStand == true then return true end

        -- 处决标记：和穿透判定同一套（否则处决中的怪还能被锁上）
        if m:FindFirstChild("BeingExecuted") ~= nil then return true end
        if m:FindFirstChild("IsBeingExecuted") ~= nil then return true end
        if m:FindFirstChild("Executing") ~= nil then return true end
        if m:FindFirstChild("IsExecuting") ~= nil then return true end
        if m:GetAttribute("BeingExecuted") == true then return true end
        if m:GetAttribute("IsBeingExecuted") == true then return true end
        if m:GetAttribute("IsExecuting") == true then return true end

        -- 复活中也不锁
        local br = m:FindFirstChild("IsBusyResurrecting")
        if br and br:IsA("BoolValue") and br.Value then return true end

        -- ============================================================
        -- 电锯无敌检测（Dave / Mikhail 这类带 Chainsaw 的 BOSS）
        --   游戏用音效 + 粒子特效标记无敌窗口，客户端能读到：
        --     · Torso.ChainsawPrepare  拉电锯准备（无敌开始）
        --     · Torso.ChainsawEnd      收起电锯（无敌结束）
        --     · Torso.Aura             无敌粒子（Enabled=true 时无敌）
        --     · Parry                  格挡音效
        --   这些期间打不动，锁了也没意义，直接跳过。
        -- ============================================================
        local torso = m:FindFirstChild("Torso")
        if torso then
            -- 拉电锯 / 收电锯 音效
            local prep = torso:FindFirstChild("ChainsawPrepare")
            if prep and prep:IsA("Sound") and prep.IsPlaying then return true end
            -- 无敌粒子
            local aura = torso:FindFirstChild("Aura")
            if aura and aura:IsA("ParticleEmitter") and aura.Enabled then return true end
        end
        -- 格挡音效（有些怪的 Parry 直接挂在模型上）
        local parry = m:FindFirstChild("Parry") or (torso and torso:FindFirstChild("Parry"))
        if parry and parry:IsA("Sound") and parry.IsPlaying then return true end

        -- 下面这些只对 BOSS 生效（普通怪不会有护盾阶段）
        if not BOSS_DOWNED_NAMES[m.Name] then return false end
        if m:FindFirstChildOfClass("ForceField") then return true end
        if hum:FindFirstChildOfClass("ForceField") then return true end
        if m:FindFirstChild("SIN_FORCEFIELD") then return true end
        if m:FindFirstChild("ExposeForceField") then return true end
        if m:FindFirstChild("DeathForceField") then return true end
        return false
    end
    -- 扫描 Mouse.Button1Down 的连接（这是游戏真正的开火路径）
    --   安全措施：
    --     1) 只扫描一次，缓存结果（不每帧扫）
    --     2) 调用前检查函数是否还有效
    --     3) 用 xpcall 包住，捕获所有错误
    local scanCache = { conns = {}, lastScan = 0 }
    local SCAN_TTL = 3   -- 3 秒内不重复扫描

    -- 收集一个事件的连接函数
    local function collectConns(signal, out)
        if not getconnections then return end
        local ok, list = pcall(getconnections, signal)
        if not ok or type(list) ~= "table" then return end
        for _, c in ipairs(list) do
            local fn = nil
            pcall(function() fn = c.Function end)
            if type(fn) ~= "function" then
                pcall(function() fn = c["function"] end)
            end
            if type(fn) == "function" then
                table.insert(out, { conn = c, fn = fn })
            end
        end
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
        local info = AIM_PARTS[getAimPartIndex()]
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
    -- 判断一个 Model 是否正在参与处决（处决者 或 被处决者）
    --   玩家和敌人通用，因为标记挂在各自的角色模型上
    --   覆盖 5 种标记：PlatformStand 属性 / 4 种处决标记 / PlatformStanding 状态
    local function isInExecution(m)
        if not m then return false end

        -- 1) 被处决 / 处决中的子对象标记
        if m:FindFirstChild("BeingExecuted") ~= nil then return true end
        if m:FindFirstChild("IsBeingExecuted") ~= nil then return true end
        if m:FindFirstChild("Executing") ~= nil then return true end
        if m:FindFirstChild("IsExecuting") ~= nil then return true end
        if m:FindFirstChild("ExecutionTarget") ~= nil then return true end
        if m:FindFirstChild("ExecutingTarget") ~= nil then return true end

        -- 2) 属性标记
        if m:GetAttribute("BeingExecuted") == true then return true end
        if m:GetAttribute("IsBeingExecuted") == true then return true end
        if m:GetAttribute("IsExecuting") == true then return true end
        if m:GetAttribute("ExecutionTarget") ~= nil then return true end

        -- 3) Humanoid 状态
        local h = m:FindFirstChildOfClass("Humanoid")
        if h then
            if h.PlatformStand == true then return true end
            local ok, st = pcall(function() return h:GetState() end)
            if ok and st == Enum.HumanoidStateType.PlatformStanding then return true end
        end

        -- 4) 判断「谁在处决谁」的配对关系
        --   覆盖 3 种情况：
        --     a) 我们自己在处决（处决者是我们）
        --     b) 别的玩家在处决敌人（处决者是别人）
        --     c) 别的玩家被敌人处决（被处决者是别人）
        --   任何一方在处决流程里，双方模型都不该挡子弹
        local mHrp = m:FindFirstChild("HumanoidRootPart")

        local function isExecutingActor(char)
            -- 判断一个角色是不是「处决者」
            if not char then return false end
            local hh = char:FindFirstChildOfClass("Humanoid")
            if hh then
                if hh.PlatformStand == true then return true end
                local ok3, st3 = pcall(function() return hh:GetState() end)
                if ok3 and st3 == Enum.HumanoidStateType.PlatformStanding then return true end
            end
            if char:FindFirstChild("BeingExecuted") ~= nil then return true end
            if char:GetAttribute("IsExecuting") == true then return true end
            if char:GetAttribute("BeingExecuted") == true then return true end
            if char:GetAttribute("Executing") == true then return true end
            return false
        end

        -- a) 我们自己在处决：m 离我们很近 → 认定 m 是被处决者
        local myChar = lp.Character
        if myChar and myChar ~= m and isExecutingActor(myChar) then
            local myHrp = myChar:FindFirstChild("HumanoidRootPart")
            if myHrp and mHrp then
                if (myHrp.Position - mHrp.Position).Magnitude <= 8 then return true end
            end
            if m:GetAttribute("ExecutedBy") == myChar.Name then return true end
            if m:GetAttribute("Executor") == myChar.Name then return true end
        end

        -- b) / c) 别的玩家参与处决
        --   m 是玩家角色：看它自己是否在处决流程里
        local mPlayer = Players:GetPlayerFromCharacter(m)
        if mPlayer then
            if isExecutingActor(m) then return true end
        end

        -- m 是敌人：看附近有没有正在处决的玩家
        if mHrp then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= lp then
                    local pc = pl.Character
                    if pc and pc ~= m then
                        -- 玩家自己在处决流程里
                        if isExecutingActor(pc) then
                            local pHrp = pc:FindFirstChild("HumanoidRootPart")
                            if pHrp then
                                local d = (pHrp.Position - mHrp.Position).Magnitude
                                -- 处决必须贴身，8 studs 内认定是配对关系
                                if d <= 8 then return true end
                            end
                            -- 或者敌人身上有指向该玩家的标记
                            if m:GetAttribute("ExecutedBy") == pl.Name then return true end
                            if m:GetAttribute("Executor") == pl.Name then return true end
                        end
                        -- 玩家被别人处决，且 m 就在旁边（处决者）
                        if pc:FindFirstChild("BeingExecuted") ~= nil
                           or pc:GetAttribute("BeingExecuted") == true then
                            local pHrp = pc:FindFirstChild("HumanoidRootPart")
                            if pHrp then
                                if (pHrp.Position - mHrp.Position).Magnitude <= 8 then return true end
                            end
                        end
                    end
                end
            end
        end

        return false
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
        -- 处决时可能有两具模型（处决者+被处决者）叠在一起挡视线，
        -- 再加上队友/尸体/盾牌，8 次不够，提到 16
        local maxIter = 16
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
                        -- 处决判定优先：处决是双向的，处决者和被处决者都算
                        --   放在队友/尸体之前，避免被 elseif 短路掉
                        if pierceExecutingEnabled and isInExecution(mdl) then
                            skip = true
                        elseif pierceTeammateEnabled and Players:GetPlayerFromCharacter(mdl) then
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

        -- 统一评估一个候选目标
        --   model    : 目标模型
        --   aimPart  : 实际瞄准的部件
        --   screenRef: 用于 FOV 判定的参考点（一般是头部）
        local function consider(model, aimPart, screenRef)
            if not aimPart or not screenRef then return end

            local wd = (aimPart.Position - myPos).Magnitude
            if wd > mbWorldDistMax then return end

            local screenD2 = nil
            if mbTargetMode ~= 3 then
                local s, onScreen = cam:WorldToViewportPoint(screenRef.Position)
                if onScreen and s.Z > 0 then
                    local dx = s.X - cx
                    local dy = s.Y - cy
                    screenD2 = dx * dx + dy * dy
                    if screenD2 > r2 then outFov = outFov + 1; return end
                else
                    outFov = outFov + 1
                    return
                end
            end

            if mbRequireVisible then
                if not isPointVisible(camPos, aimPart.Position, model, excludeVis) then
                    visBlocked = visBlocked + 1
                    return
                end
            end

            local prio = isLowPriority(model) and 1 or 0
            local accept = false
            if prio < bestPrio then
                accept = true
            elseif prio == bestPrio then
                if mbTargetMode == 3 then
                    accept = wd < bestWorldD
                elseif mbTargetMode == 1 then
                    accept = screenD2 ~= nil and screenD2 < bestScreenD2
                else
                    accept = wd < bestWorldD
                end
            end

            if accept then
                bestPrio = prio
                if mbTargetMode == 1 and screenD2 then
                    bestScreenD2 = screenD2
                else
                    bestWorldD = wd
                end
                best = { model = model, head = screenRef, aimPart = aimPart }
            end
        end

        -- ① 普通敌人
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
                                consider(m, aimPart, head)
                            end
                        end
                    end
                end
            end
        end

        -- ② BTR 放出的无人机
        --   它们没有 Humanoid / Head，直接挂在 Workspace 下，
        --   之前完全没被扫描到，所以魔法子弹永远锁不到
        if mbTargetDrones ~= false then
            for _, d in ipairs(getAllBTRDrones()) do
                candidates = candidates + 1
                local hit = getDroneAimPart(d)
                if hit then
                    -- FOV 判定用命中盒本身（无人机没有头）
                    consider(d, hit, hit)
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

    -- 调试：查看当前锁定结果
    getgenv().ExamDebugMBTarget = function()
        local t2 = findTarget()
        if not t2 then
            return "无目标 | 原因=" .. tostring(findLastReason)
        end
        return string.format("目标=%s | 瞄准部件=%s | 距离=%.1f",
            t2.model and t2.model.Name or "?",
            t2.aimPart and t2.aimPart.Name or "?",
            (t2.aimPart and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                and (t2.aimPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude) or -1)
    end

    -- 调试：列出所有被扫描到的无人机
    getgenv().ExamDebugDrones = function()
        local ds = getAllBTRDrones()
        local parts = {"活着的无人机=" .. #ds}
        for _, d in ipairs(ds) do
            local hit = getDroneAimPart(d)
            parts[#parts+1] = string.format("  %s hitbox=%s state=%s",
                d:GetFullName(),
                tostring(hit ~= nil),
                tostring(d:GetAttribute("DroneState")))
        end
        return table.concat(parts, "\n")
    end

    -- 必须在 destroyRadiusRing 之前声明：否则里面写的是另一个变量，
    -- 尺寸缓存清不掉，改半径后圈不跟着变
    local radiusRingModel = nil
    local radiusLastR = nil

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
    local radiusFaceModel = nil

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
        bb.AlwaysOnTop = true; bb.LightInfluence = 0
        bb.MaxDistance = mbWorldDistMax; bb.ResetOnSpawn = false

        bb.Size = UDim2.new(mbBBSizeStuds, 0, mbBBSizeStuds, 0)
        bb.StudsOffsetWorldSpace = Vector3.new(0, mbStudsOffsetY, 0)

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

    local _fx = select(2, toggleMagic("穿透处决目标", UDim2.new(0, 15, 0, 164), true, function(v)
        pierceExecutingEnabled = v
    end, UDim2.new(0, 140, 0, 28)))
    _G._ExamSetters.pierceExecuting = _fx; _G._ExamStates.pierceExecuting = true

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

    _G._ExamSetters.mbTargetDrones = function(v)
        mbTargetDrones = v and true or false
        _G._ExamStates.mbTargetDrones = mbTargetDrones
    end
    _G._ExamStates.mbTargetDrones = true

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
        v = v and true or false
        if v and not magicBulletEnabled then
            _G._ExamStates.autoFire = false
            autoFireStatus = "需先开魔法子弹"
            return
        end
        if v and not mbRequireVisible then
            _G._ExamStates.autoFire = false
            autoFireStatus = "需开启掩体检测"
            return
        end
        autoFireEnabled = v
        _G._ExamStates.autoFire = v          -- 修复：同步状态
        autoFireBtn.Text = v and "自动开火: 开" or "自动开火: 关（需开掩体检测）"
        autoFireBtn.BackgroundColor3 = v and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        if v then
            autoFireStatus = "已开启"
        else
            releaseFire()
            autoFireStatus = "关"
        end
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
            -- 半径变了，范围圈下帧重算尺寸
            radiusLastR = nil
        end
    end
    _G._ExamStates.mbWorldDistMax = mbWorldDistMax
    -- 和上面的东西留点间距
    local aimTitle = Instance.new("TextLabel", magicPage)
    aimTitle.Size = UDim2.new(1, -30, 0, 26)
    aimTitle.Position = UDim2.new(0, 15, 0, 266)
    aimTitle.BackgroundTransparency = 1
    aimTitle.Text = "锁定部位"
    aimTitle.TextColor3 = Color3.new(1, 1, 1)
    aimTitle.Font = Enum.Font.GothamBold
    aimTitle.TextSize = 16
    aimTitle.TextXAlignment = Enum.TextXAlignment.Left

    local aimValue = Instance.new("TextLabel", magicPage)
    aimValue.Size = UDim2.new(0, 90, 0, 26)
    aimValue.Position = UDim2.new(1, -120, 0, 266)
    aimValue.BackgroundTransparency = 1
    aimValue.Text = "头部"
    aimValue.TextColor3 = Color3.fromRGB(0, 220, 120)
    aimValue.Font = Enum.Font.GothamBold
    aimValue.TextSize = 16
    aimValue.TextXAlignment = Enum.TextXAlignment.Right

    -- 点标题展开/收起
    local aimHit = Instance.new("TextButton", magicPage)
    aimHit.Size = UDim2.new(1, -30, 0, 26)
    aimHit.Position = UDim2.new(0, 15, 0, 266)
    aimHit.BackgroundTransparency = 1
    aimHit.Text = ""
    aimHit.Active = true

    local charBox = Instance.new("Frame", magicPage)
    charBox.Size = UDim2.new(1, -30, 0, 0)
    charBox.Position = UDim2.new(0, 15, 0, 294)
    charBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    charBox.BorderSizePixel = 0
    charBox.ClipsDescendants = true
    local charBoxOpen = false
    Instance.new("UICorner", charBox).CornerRadius = UDim.new(0, 6)
    local bodyColor = Color3.fromRGB(60, 60, 70)
    local bodyColorSel = Color3.fromRGB(0, 200, 100)
    local figure = Instance.new("Frame", charBox)
    figure.Size = UDim2.new(0, 200, 1, 0)
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
    -- 完全按 R6 官方比例：
    --   Head  2x1x1  -> 宽：高 = 2:1
    --   Torso 2x2x1  -> 正方形
    --   四肢  1x2x1  -> 宽是躯干的一半，高和躯干一样
    local SCALE = 24                       -- 1 stud = 24 px
    local TORSO_W = 2 * SCALE              -- 48
    local TORSO_H = 2 * SCALE              -- 48
    local LIMB_W  = 1 * SCALE              -- 24（躯干的一半）
    local LIMB_H  = TORSO_H                -- 48（和躯干同高）
    local HEAD_W  = 2 * SCALE              -- 48
    local HEAD_H  = 1 * SCALE              -- 24
    local GAP = 0                          -- R6 本来就是贴着的，不留缝
    local totalW = LIMB_W * 2 + TORSO_W + GAP * 2
    local startX = math.floor((200 - totalW) / 2)

    local headX = startX + math.floor((totalW - HEAD_W) / 2)
    local headY = 4
    local torsoY = headY + HEAD_H + 2
    local torsoX = startX + LIMB_W + GAP
    local armL_x = startX
    local armR_x = torsoX + TORSO_W + GAP
    local legY = torsoY + TORSO_H
    local legL_x = torsoX + math.floor((TORSO_W - LIMB_W * 2) / 2)
    local legR_x = legL_x + LIMB_W

    partBtns[1] = makePartBtn(headX, headY, HEAD_W, HEAD_H)
    partBtns[2] = makePartBtn(torsoX, torsoY, TORSO_W, TORSO_H)
    partBtns[3] = makePartBtn(armL_x, torsoY, LIMB_W, LIMB_H)
    partBtns[4] = makePartBtn(armR_x, torsoY, LIMB_W, LIMB_H)
    partBtns[5] = makePartBtn(legL_x, legY, LIMB_W, LIMB_H)
    partBtns[6] = makePartBtn(legR_x, legY, LIMB_W, LIMB_H)
    local infoValue = aimValue
    local function refreshAimSelection()
        for i, btn in ipairs(partBtns) do
            if i == getAimPartIndex() then btn.BackgroundColor3 = bodyColorSel
            else btn.BackgroundColor3 = bodyColor end
        end
        local info = AIM_PARTS[getAimPartIndex()]
        if info then infoValue.Text = info.label end
    end
    local function selectAim(index)
        if not AIM_PARTS[index] then return end
        _G._ExamAimPartIndex = index
        _G._ExamStates.mbAimPart = index
        refreshAimSelection(); destroyLockBB()
    end
    for i, btn in ipairs(partBtns) do
        bindTap(btn, function() selectAim(i) end)
    end
    refreshAimSelection()

    -- 展开 / 收起
    local function setAimOpen(open)
        charBoxOpen = open and true or false
        local targetH = charBoxOpen and 152 or 0
        game:GetService("TweenService"):Create(charBox,
            TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Size = UDim2.new(1, -30, 0, targetH) }):Play()
    end
    bindTap(aimHit, function()
        setAimOpen(not charBoxOpen)
    end)

    _G._ExamSetters.mbAimPart = function(v)
        local n = tonumber(v)
        if not n then n = 1 end
        if n < 1 or n > #AIM_PARTS then n = 1 end
        -- 先写状态，后面刷新即使报错也不影响设置生效
        _G._ExamAimPartIndex = n
        _G._ExamStates.mbAimPart = n
        pcall(refreshAimSelection)
        pcall(destroyLockBB)
        -- 同步到小人图的勾选显示（如果存在）
        pcall(function()
            local w = getgenv().ExaminationWin
            if not w then return end
            local ctrl = w.Rows and w.Rows["mbAimPart"]
            if ctrl and type(ctrl.SetSilent) == "function" then
                ctrl.SetSilent(n)
            end
        end)
    end
    _G._ExamStates.mbAimPart = 1
    if _G._ExamAimPartIndex == nil then _G._ExamAimPartIndex = 1 end
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
    _G._ExamStates.mbFovRadius = mbFovRadius
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
        while _hiddenDock.Parent do
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
        while _hiddenDock.Parent do
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
            while radarBoostEnabled and _hiddenDock.Parent do
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
-- 人体部位选择器（用 CDMUI 的 Tab:Custom 预设行）
-- ============================================================
local function BodyPartPicker(tab, cfg)
    -- 不用 getgenv().CDMUI：加载时序不同可能拿不到
    -- 从 tab.Window 拿主题（一定存在）
    local CD = getgenv().CDMUI
    local T = (CD and CD.Theme) or {
        text = Color3.fromRGB(240, 240, 245),
        textDim = Color3.fromRGB(150, 150, 162),
        accent = Color3.fromRGB(120, 170, 255),
        row = Color3.fromRGB(30, 30, 36),
        rowChild = Color3.fromRGB(24, 24, 30),
    }
    local key = cfg.Key or cfg.key
    local selected = cfg.Default or 1

    -- ============================================================
    -- 2D 人体图标准布局（请勿随意改动，改之前先看这段）
    --   基准宽度 180 → S=45，实际渲染后（含 UI 缩放）约 213x282
    --
    --   横向排布（左→右）：左臂 | 躯干 | 右臂
    --   纵向排布（上→下）：头 / 躯干+双臂 / 双腿
    --
    --   各块尺寸（以 S=45 为基准）：
    --     头    HX x HY  = 60 x 60   （1.35S，居中于躯干上方）
    --     躯干  TW x TH  = 90 x 90   （2S）
    --     手臂  AW x AH  = 45 x 90   （1S x 2S，左右各一）
    --     腿    LW x LH  = 45 x 90   （1S x 2S，躯干下方左右并排）
    --     间隙  GAP      = 3
    --
    --   编号：1=头 2=躯干 3=左臂 4=右臂 5=左腿 6=右腿
    --   字号：按块宽 x0.42，限 13~22（头/躯干 22，四肢 18）
    -- ============================================================
    local TOTAL_W = 180
    local S = math.floor(TOTAL_W / 4)
    local TW, TH = 2 * S, 2 * S
    local HX, HY = math.floor(S * 1.35), math.floor(S * 1.35)
    local AW, AH = S, 2 * S
    local LW, LH = S, 2 * S
    local GAP = 3
    local totalW = AW + GAP + TW + GAP + AW
    local totalH = HY + GAP + TH + GAP + LH
    local CH_H = totalH + 32

    local buttons = {}
    local render

    local ctrl = tab:Custom({
        Key = key,
        Name = cfg.Name or "选择部位",
        Desc = cfg.Desc or "点击人体图选择",
        Height = CH_H,
        Arrow = true,
        Builder = function(inner, ctx)
            local canvas = Instance.new("Frame")
            canvas.Name = "Canvas"
            canvas.Size = UDim2.fromOffset(totalW, totalH)
            canvas.Position = UDim2.new(0.5, -totalW / 2, 0, 0)
            canvas.BackgroundTransparency = 1
            canvas.ZIndex = 5
            canvas.Parent = inner

            local COL_IDLE = Color3.fromRGB(58, 58, 68)
            local COL_HOVER = Color3.fromRGB(78, 78, 92)
            local COL_ON = T.accent

            local function mkPart(px, py, w, h, idx, label)
                local b = Instance.new("TextButton")
                b.Name = "Part" .. idx
                b.Size = UDim2.fromOffset(w, h)
                b.Position = UDim2.fromOffset(px, py)
                b.BackgroundColor3 = COL_IDLE
                b.BorderSizePixel = 0
                b.Text = ""
                b.AutoButtonColor = false
                b.ZIndex = 6
                b.Active = true
                b.Parent = canvas

                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 3)
                c.Parent = b

                local lbl = Instance.new("TextLabel")
                lbl.Name = "Lbl"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = label or ""
                lbl.TextColor3 = Color3.fromRGB(150, 150, 162)
                lbl.Font = Enum.Font.GothamBold
                -- 字号按格子宽度自适应（文字是横排的，宽度才是瓶颈）
                --   上限 22，避免"躯干"这种大方块字太大
                local fs = math.floor(w * 0.42)
                if fs > 22 then fs = 22 end
                if fs < 13 then fs = 13 end
                lbl.TextSize = fs
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.ZIndex = 7
                lbl.Active = false
                lbl.Parent = b

                buttons[idx] = { btn = b, lbl = lbl }
                return b
            end

            local xArmL = 0
            local xTorso = AW + GAP
            local xArmR = xTorso + TW + GAP
            local yHead = 0
            local yTorso = HY + GAP
            local yLegs = yTorso + TH + GAP

            mkPart(xTorso + (TW - HX) / 2, yHead, HX, HY, 1, "头")
            mkPart(xTorso, yTorso, TW, TH, 2, "躯干")
            mkPart(xArmL, yTorso, AW, AH, 3, "左臂")
            mkPart(xArmR, yTorso, AW, AH, 4, "右臂")
            local legsX = xTorso + (TW - LW * 2 - GAP) / 2
            mkPart(legsX, yLegs, LW, LH, 5, "左腿")
            mkPart(legsX + LW + GAP, yLegs, LW, LH, 6, "右腿")

            render = function()
                for idx, entry in pairs(buttons) do
                    if idx == selected then
                        entry.btn.BackgroundColor3 = COL_ON
                        entry.lbl.TextColor3 = Color3.fromRGB(18, 18, 22)
                    else
                        entry.btn.BackgroundColor3 = COL_IDLE
                        entry.lbl.TextColor3 = Color3.fromRGB(150, 150, 162)
                    end
                end
            end

            for idx, entry in pairs(buttons) do
                entry.btn.Activated:Connect(function()
                    -- 和库内其他控件一样播点击音效
                    local cd2 = getgenv().CDMUI
                    if cd2 and cd2.PlayClick then pcall(cd2.PlayClick) end
                    selected = idx
                    render()
                    if cfg.Callback then pcall(cfg.Callback, idx) end
                end)
                entry.btn.MouseEnter:Connect(function()
                    if idx ~= selected then entry.btn.BackgroundColor3 = COL_HOVER end
                end)
                entry.btn.MouseLeave:Connect(function()
                    if idx ~= selected then entry.btn.BackgroundColor3 = COL_IDLE end
                end)
            end

            render()
        end,
    })

    if ctrl and ctrl.Set then
        ctrl.Set = function(v)
            if type(v) == "number" and buttons[v] then
                selected = v
                if render then render() end
            end
        end
        ctrl.Get = function() return selected end
    end

    return ctrl
end


-- ============================================================
-- 屏幕 HUD 浮层（FPS / 延迟 / 服务器人数）
--   独立实现，不依赖 CDMUI
-- ============================================================
local HUD = {}
do
    local function mk(class, props, parent)
        local inst = Instance.new(class)
        if props then for k, v in pairs(props) do inst[k] = v end end
        if parent then inst.Parent = parent end
        return inst
    end
    local function safeCall(fn, ...)
        if type(fn) ~= "function" then return end
        pcall(fn, ...)
    end
    local function getGuiParent()
        local plrs = game:GetService("Players")
        local me = plrs and plrs.LocalPlayer
        return me and me:FindFirstChild("PlayerGui")
    end

    -- 全局拖动分发器（HUD 拖动依赖它）
    local dragListeners = setmetatable({}, { __mode = "k" })
    local dragDispatchReady = false
    local function addDragListener(fn)
        dragListeners[fn] = true
        if not dragDispatchReady then
            dragDispatchReady = true
            local uis = game:GetService("UserInputService")
            uis.InputChanged:Connect(function(input)
                local ut = input.UserInputType
                if ut ~= Enum.UserInputType.MouseMovement and ut ~= Enum.UserInputType.Touch then return end
                for f in pairs(dragListeners) do pcall(f, input) end
            end)
            uis.InputEnded:Connect(function(input)
                for f in pairs(dragListeners) do pcall(f, input) end
            end)
        end
        return function() dragListeners[fn] = nil end
    end

    local hudGui, hudFrame, hudInner, hudCorners, hudLockBtn
    local hudRows = {}
    local hudConn = nil
    local hudTweens = {}
    local hudDragConn = nil

    local showFPS, showPing, showPlayers = false, false, false
    local hudLocked = true
    local hudDragging = false
    local lockTouched = false
    local hudVisible = false

    -- 夜视仪同款资源
    local BORDER_IMG = "rbxassetid://110336735200080"

    -- 尺寸：完全对齐夜视仪框（184 x 84，位置 12, 849）
    local BOX_W    = 185      -- 和夜视仪框严格同宽（实测 184.55）
    local BOX_X   = 12
    -- 夜视仪框：顶部 y=849，高 84，底边距屏幕底 76px
    -- HUD 挂在它正上方，留 8px 间隙
    -- 用「距顶部」定位更稳：
    --   夜视仪框顶部在 y=849（AbsolutePosition，含 inset 语义）
    --   HUD 底边要落在 843（往上留 6px）
    --   AnchorPoint 用 (0,1)，Position.Y 直接给 843 就行
    local BOX_X = 12
    -- HUD 底边的绝对 Y：动态跟随夜视仪框（不写死，手机端屏幕高度不同）
    local function getNvgTopY()
        local pgv = nil
        pcall(function()
            local plrs = game:GetService("Players")
            local me = plrs and plrs.LocalPlayer
            pgv = me and me:FindFirstChild("PlayerGui")
        end)

        local cam = workspace.CurrentCamera
        local vpY = cam and cam.ViewportSize.Y or 1009

        if pgv then
            local nvg = pgv:FindFirstChild("NightVisionHUD")
            if nvg then
                local container = nvg:FindFirstChild("Container")

                -- ① 优先：Status 子对象（真正的左下角信息框）
                --   Container 是整个夜视仪区域，顶部有大量空白
                --   Status 才是实际显示 血量/状态 的地方
                if container then
                    local status = container:FindFirstChild("Status")
                    if status and status:IsA("GuiObject") then
                        -- 优先读 Status.Borders（真正的视觉边框，不含透明边距）
                        local borders = status:FindFirstChild("Borders")
                        if borders and borders:IsA("GuiObject") then
                            local by = borders.AbsolutePosition.Y
                            if by > 50 then return by end
                        end
                        -- 兜底：Status 本身
                        local sy = status.AbsolutePosition.Y
                        local sh = status.AbsoluteSize.Y
                        if sy > 50 and sh > 5 then
                            return sy
                        end
                    end
                end

                -- ② 兜底：找其他内容子容器
                if container then
                    for _, name in ipairs({"NVG", "Main", "Info"}) do
                        local sub = container:FindFirstChild(name)
                        if sub then
                            local sy = sub.AbsolutePosition.Y
                            if sy > 50 then return sy end
                        end
                    end
                end

                -- ③ 再兜底：Container 本身
                if container then
                    local cy = container.AbsolutePosition.Y
                    local ch = container.AbsoluteSize.Y
                    if cy > 50 and ch > 10 then
                        return cy
                    end
                end

                -- ③ 再兜底：Borders（旧的逻辑）
                local stack = {nvg}
                while #stack > 0 do
                    local cur = table.remove(stack)
                    for _, c in ipairs(cur:GetChildren()) do
                        if c.Name == "Borders" and c:IsA("ImageLabel") then
                            local y = c.AbsolutePosition.Y
                            if y > 50 then return y end
                        end
                        table.insert(stack, c)
                    end
                end
            end
        end

        -- ④ 最后兜底：按视口高度比例（夜视仪在底部约 84%）
        return math.floor(vpY * 0.841)
    end

    -- HUD 底边与夜视仪顶部的间隙（studs）
    local function getHudGap()
        return 10
    end
    -- 修复：改成函数，每次定位时实时读夜视仪位置
    --   原来只在加载时算一次，如果那时夜视仪还没创建就会用错值
    local function getBoxTopY()
        return getNvgTopY() - getHudGap()
    end

    -- 夜视仪布局稳定性跟踪
    local _nvgStable = { x = nil, w = nil, top = nil, count = 0 }

    -- 原子闸门：保证「首次显示」只发生一次
    --   HUD 有多条启动路径（startLoop / SetHUDAll / 自愈重建），
    --   它们都会调 ensureHud + refreshLayout，导致 HUD 出现两次。
    --   这里用状态机挡住：idle → creating → shown
    local _hudPhase = "idle"

    -- 读取夜视仪边框的位置和尺寸（用于 HUD 对齐）
    --   返回 x, width, topY, isStable
    local function getNvgFrame()
        local pgv = nil
        pcall(function()
            local plrs = game:GetService("Players")
            local me = plrs and plrs.LocalPlayer
            pgv = me and me:FindFirstChild("PlayerGui")
        end)
        if not pgv then return nil end
        local nvg = pgv:FindFirstChild("NightVisionHUD")
        if not nvg then return nil end
        local container = nvg:FindFirstChild("Container")
        if not container then return nil end
        local status = container:FindFirstChild("Status")
        if not status then return nil end
        local borders = status:FindFirstChild("Borders")
        if not borders or not borders:IsA("GuiObject") then return nil end
        local ap, as = borders.AbsolutePosition, borders.AbsoluteSize
        if as.X < 20 or as.Y < 10 then return nil end

        -- 稳定性检测
        local st = _nvgStable

        -- 已锁定：直接返回锁定的值（不再读实时值）
        --   夜视仪布局完成后偶尔还会有微小抖动，用锁定值保证稳定
        if st.locked then
            return st.x, st.w, st.top, true
        end

        local same = st.x ~= nil
            and math.abs(st.x - ap.X) < 0.5
            and math.abs(st.w - as.X) < 0.5
            and math.abs(st.top - ap.Y) < 0.5

        if same then
            st.count = st.count + 1
        else
            st.count = 1
        end
        st.x, st.w, st.top = ap.X, as.X, ap.Y

        -- 连续 8 次一致 → 锁定
        if st.count >= 8 then
            st.locked = true
            return st.x, st.w, st.top, true
        end
        return ap.X, as.X, ap.Y, false
    end
    -- 兼容旧代码：保留变量名，但每次使用时都会重新取值
    local BOX_TOP_Y = getNvgTopY() - getHudGap()
    local PAD_X    = IS_MOBILE and 14 or 12
    local PAD_Y    = IS_MOBILE and 6 or 5
    local ROW_H    = IS_MOBILE and 26 or 22
    local ROW_GAP  = IS_MOBILE and 5 or 4
    local FONT_SZ  = IS_MOBILE and 22 or 18
    local LABEL_SZ = IS_MOBILE and 20 or 17
    local BTN_W    = IS_MOBILE and 56 or 50
    local BTN_H    = IS_MOBILE and 22 or 18
    local LABEL_W  = IS_MOBILE and 50 or 40
    local BTN_FSZ  = IS_MOBILE and 13 or 12

    local frameCount, fpsWindow, curFPS = 0, 0, 0
    local pingSamples, curPing = {}, 0
    local pingBusy = false

    local statsPingItem = nil
    pcall(function()
        statsPingItem = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
    end)

    local function killTween(k)
        local tw = hudTweens[k]
        if tw then pcall(function() tw:Cancel() end); hudTweens[k] = nil end
    end

    -- Q 弹动画：高度和位置同时过渡，底边固定不动、顶边向外弹开
    --   只改高度的话看起来只是「拉长」，位置一起动才有「撑开」的感觉
    local function getInsetY()
        local y = 58
        pcall(function()
            local ins = game:GetService("GuiService"):GetGuiInset()
            if typeof(ins) == "Vector2" then y = ins.Y end
        end)
        return y
    end

    -- 整体缩放动画：用 UIScale，不改 Size，四角不受影响
    local hudScale = nil
    local function ensureScale()
        if not hudFrame then return nil end
        if not hudScale or not hudScale.Parent then
            hudScale = hudFrame:FindFirstChildOfClass("UIScale")
            if not hudScale then
                hudScale = Instance.new("UIScale")
                hudScale.Scale = 1
                hudScale.Parent = hudFrame
            end
        end
        return hudScale
    end

    -- 计算当前视口下的 HUD 缩放比例
    --   基准 1920x1009（PC 全屏），小屏按比例缩小
    local function calcHudScale()
        local cam = workspace.CurrentCamera
        local vpY = cam and cam.ViewportSize.Y or 1009
        if vpY >= 1009 then return 1 end
        return math.clamp(vpY / 1009, 0.7, 1)
    end

    -- 应用自适应缩放（不播放动画，直接设）
    local function applyHudScale()
        local sc = ensureScale()
        if sc then
            local want = calcHudScale()
            if math.abs(sc.Scale - want) > 0.01 then
                sc.Scale = want
            end
        end
        return sc
    end

    -- 统一的 HUD 定位：把底边贴到夜视仪顶部上方 HUD_GAP 处
    --   contentH 是「未缩放」的内容高度
    --   渲染后的视觉高度 = contentH * scale
    --   所以 Position.Y = getBoxTopY() - contentH * scale + insetY
    local function positionHud(contentH)
        if not hudFrame then return end
        local sc = ensureScale()
        local scale = sc and sc.Scale or 1
        local h = contentH or hudFrame.Size.Y.Offset
        local visualH = h * scale
        local insetY = 58
        pcall(function()
            local ins = game:GetService("GuiService"):GetGuiInset()
            if typeof(ins) == "Vector2" then insetY = ins.Y end
        end)

        -- 对齐夜视仪边框：X 和宽度都跟随
        local nvgX, nvgW, nvgTop, isStable = getNvgFrame()

        -- 关键：一旦成功定位过（_nvgStable.everPlaced），就永不隐藏
        --   之后无论位置怎么变，都只静默更新 Position，不碰 Visible
        if _nvgStable.everPlaced then
            if nvgX and nvgW and nvgTop then
                local wantW = nvgW / scale
                if math.abs(hudFrame.Size.X.Offset - wantW) > 1 then
                    hudFrame.Size = UDim2.new(0, wantW, 0, hudFrame.Size.Y.Offset)
                end
                local wantY = math.max(0, nvgTop - getHudGap() - visualH) + insetY
                hudFrame.Position = UDim2.new(0, nvgX, 0, wantY)
            end
            return
        end

        -- 首次定位：只要夜视仪边框有有效尺寸就定位
        --   不再要求 isStable（那会导致 HUD 反复隐藏/显示闪烁）
        if not nvgX or not nvgW or not nvgTop then
            hudFrame.Visible = false
            return
        end

        -- 首次定位成功 → 标记，之后永不隐藏
        _nvgStable.everPlaced = true
        if hudVisible and not hudFrame.Visible then
            hudFrame.Visible = true
        end

        local posX = nvgX
        -- 宽度按未缩放坐标设置（视觉宽度 = 设置值 * scale）
        local wantW = nvgW / scale
        if math.abs(hudFrame.Size.X.Offset - wantW) > 1 then
            hudFrame.Size = UDim2.new(0, wantW, 0, hudFrame.Size.Y.Offset)
        end

        local topY = nvgTop - getHudGap()
        hudFrame.Position = UDim2.new(0, posX, 0,
            math.max(0, topY - visualH) + insetY)
    end

    -- 入场：从左滑入 + 展开（高度从 0 撑到满）
    -- 入场：从左侧平移滑入（高度不变）
    -- popIn 接收「已经算好的目标位置」，自己不再调用 positionHud
    --   避免两次计算得到不同结果（getNvgFrame 有稳定性状态，结果可能不一致）
    local function popIn(targetX, targetY)
        applyHudScale()
        if not hudFrame then return end

        local fullH = PAD_Y * 2 + 3 * ROW_H + 2 * ROW_GAP
        hudFrame.Size = UDim2.fromOffset(BOX_W, fullH)

        -- 没传目标位置就自己算（兜底）
        if not targetX or not targetY then
            local nvgX0, nvgW0, nvgTop0 = getNvgFrame()
            if not nvgX0 or not nvgW0 or not nvgTop0 then
                hudFrame.Visible = false
                return
            end
            positionHud(fullH)
            targetX = hudFrame.Position.X.Offset
            targetY = hudFrame.Position.Y.Offset
        end

        local homeX = targetX
        local homeY = targetY

        -- 起点：完全在屏幕左侧外
        hudFrame.Position = UDim2.new(0, homeX - BOX_W - 30, 0, homeY)

        local info = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tw = TweenService:Create(hudFrame, info, {
            Position = UDim2.new(0, homeX, 0, homeY),
        })
        tw:Play()
        hudTweens.size = tw

    end

    -- 出场：两段动画，连贯执行
    --   ① 先滑回默认位置（用户可能拖过）
    --   ② 再往左滑出屏幕
    local function popOut(onDone)
        if not hudFrame then
            if onDone then onDone() end
            return
        end

        -- 默认位置（左下角，夜视仪上方）
        local fullH = PAD_Y * 2 + 3 * ROW_H + 2 * ROW_GAP
        -- 用统一函数算，保证和入场一致
        local sc2 = ensureScale()
        local scale2 = sc2 and sc2.Scale or 1
        local nvgX2, nvgW2, nvgTop2 = getNvgFrame()
        local homeX = nvgX2 or BOX_X
        local homeY = math.max(0, (nvgTop2 or getNvgTopY()) - getHudGap() - fullH * scale2) + getInsetY()

        local curX = hudFrame.Position.X.Offset
        local curY = hudFrame.Position.Y.Offset
        local dist = math.abs(curX - homeX) + math.abs(curY - homeY)

        local function slideOut()
            if not hudFrame then
                if onDone then onDone() end
                return
            end
            -- ② 往左滑出
            local tw = TweenService:Create(hudFrame,
                TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                { Position = UDim2.new(0, homeX - BOX_W - 40, 0, homeY) })
            tw:Play()
            tw.Completed:Connect(function()
                -- 归位（下次打开从正确位置开始）
                if hudFrame then
                    hudFrame.Position = UDim2.new(0, homeX, 0, homeY)
                end
                if onDone then onDone() end
            end)
        end

        if dist > 4 then
            -- ① 偏离了默认位置：先滑回去
            --   时长按距离算，最多 0.28 秒，保证连贯不拖沓
            local dur = math.clamp(dist / 900, 0.10, 0.28)
            local tw = TweenService:Create(hudFrame,
                TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Position = UDim2.new(0, homeX, 0, homeY) })
            tw:Play()
            tw.Completed:Connect(slideOut)
        else
            -- 已经在原位：直接滑出
            slideOut()
        end
    end

    local function tweenSize(target, instant, dur, style, dir)
        if not hudFrame then return nil end
        local targetH = target.Y.Offset
        local insetY = getInsetY()
        -- 底边固定在 getBoxTopY()，所以左上角 Y = getBoxTopY() - 高度
        local targetTop = math.max(0, getBoxTopY() - targetH) + insetY
        local targetPos = UDim2.new(0, BOX_X, 0, targetTop)

        if instant then
            killTween("size")
            hudFrame.Size = target
            hudFrame.Position = targetPos
            return nil
        end

        killTween("size")
        hudFrame.Position = UDim2.new(0, hudFrame.Position.X.Offset,
            0, math.max(0, getBoxTopY() - hudFrame.Size.Y.Offset) + insetY)

        local info = TweenInfo.new(dur or 0.42,
            style or Enum.EasingStyle.Back,
            dir or Enum.EasingDirection.Out)

        local tw = TweenService:Create(hudFrame, info, {
            Size = target,
            Position = targetPos,
        })
        tw:Play(); hudTweens.size = tw
        return tw
    end

    -- 按当前高度算左上角 Y，让底边固定落在 getBoxTopY()
    local function placeHud()
        if not hudFrame then return end
        local h = hudFrame.Size.Y.Offset
        if h < 1 then h = hudFrame.AbsoluteSize.Y end
        -- 统一走 positionHud（自动处理缩放）
        positionHud(h)
    end

    -- 高度固定 84（和夜视仪同高），四角不会变形
    local FIXED_H = 84
    local function desiredHeight(n)
        if n <= 0 then return 0 end
        return FIXED_H
    end

    local function activeRows()
        local r = {}
        if showFPS then table.insert(r, "fps") end
        if showPing then table.insert(r, "ping") end
        if showPlayers then table.insert(r, "players") end
        return r
    end

    -- 锁定状态切换
    --   必须在 ensureHud 之前定义：ensureHud 里会绑定按钮回调引用它
    local function setLocked(on)
        hudLocked = on and true or false

        -- 关键：
        --   锁定 = 整块不接收任何输入（和夜视仪一样，鼠标悬停没反应、也不挡后面 UI）
        --   解锁 = 整块可拖动，同时按钮可点
        --   锁定状态下按钮仍然可以点（否则解不开），靠 Active 单独控制
        if hudFrame then
            hudFrame.Active = not hudLocked     -- 拖动需要 Active
        end
        if hudInner then
            hudInner.Active = false             -- 行内容永远不吃输入
        end
        if hudLockBtn then
            hudLockBtn.Active = true            -- 按钮永远可点
            -- 文字形式：锁定 LOCKED / 解锁 FREE
            hudLockBtn.Text = hudLocked and "LOCKED" or "FREE"
            hudLockBtn.TextColor3 = hudLocked
                and Color3.fromRGB(255, 255, 255)
                or Color3.fromRGB(255, 210, 140)
            hudLockBtn.TextTransparency = hudLocked and 0.15 or 0
        end
    end

    -- ===== 构建 =====
    local function ensureHud()
        if hudGui and hudGui.Parent then return end
        hudRows = {}

        local parent = nil
        pcall(function()
            local plrs = game:GetService("Players")
            local me = plrs and plrs.LocalPlayer
            local pgv = me and me:FindFirstChild("PlayerGui")
            if pgv then parent = pgv end
        end)
        if not parent and lp then
            pcall(function()
                local pgv = lp:FindFirstChild("PlayerGui")
                if pgv then parent = pgv end
            end)
        end
        if not parent then parent = guiParent() end

        -- 修复：创建新 HUD 前先清掉残留的同名 ScreenGui，防止叠层
        pcall(function()
            for _, root in ipairs({game:GetService("CoreGui"), parent}) do
                if root then
                    for _, d in ipairs(root:GetChildren()) do
                        if d.Name == "CDMUI_HUD" then
                            pcall(function() d:Destroy() end)
                        end
                    end
                end
            end
        end)

        hudGui = Instance.new("ScreenGui")
        hudGui.Name = "CDMUI_HUD"
        hudGui.ResetOnSpawn = false
        hudGui.IgnoreGuiInset = true
        -- 提到最上层：否则面板(101)会盖住 HUD，按钮点不到
        hudGui.DisplayOrder = 200
        hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        hudGui.Enabled = true
        pcall(function() hudGui.Active = false end)
        hudGui.Parent = parent
        getgenv().__ExamHUDGui = hudGui

        hudFrame = Instance.new("Frame")
        hudFrame.Name = "HudBox"
        hudFrame.AnchorPoint = Vector2.new(0, 0)   -- 左上角锚点
        hudFrame.Size = UDim2.fromOffset(BOX_W, 84)
        -- 关键：创建后立刻隐藏，等 refreshLayout 确认夜视仪就绪后再显示
        --   否则会先以默认位置闪一下（瞬间出现，无动画），然后再播入场动画
        hudFrame.Visible = false
        -- 位置：底边贴住夜视仪顶部上方 6px
        --   AbsolutePosition.Y = Position.Y.Offset - GuiInset.Y（实测差 58）
        do
            local insetY = 58
            pcall(function()
                local ins = game:GetService("GuiService"):GetGuiInset()
                if typeof(ins) == "Vector2" then insetY = ins.Y end
            end)
            -- 自适应缩放（和 Relayout 一致）
            local vpY2 = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y) or 1009
            local sc0 = ensureScale()
            local scale0 = 1
            if sc0 then
                if vpY2 < 1009 then
                    scale0 = math.clamp(vpY2 / 1009, 0.7, 1)
                end
                sc0.Scale = scale0
            end

            -- 统一定位（自动处理缩放）
            positionHud(84)
        end
        hudFrame.BackgroundTransparency = 1
        hudFrame.BorderSizePixel = 0
        -- Frame 本身没有悬停样式，Active 只控制是否拦截输入
        --   这里设 true 让子按钮能收到点击；
        --   鼠标悬停不会改变任何外观（没有 AutoButtonColor 概念）
        hudFrame.Active = true
        hudFrame.Selectable = false
        hudFrame.BackgroundTransparency = 1
        hudFrame.ClipsDescendants = true
        hudFrame.Parent = hudGui

        -- 四角括号：和夜视仪完全一致（单图铺满 + Slice）
        --   高度固定 84，所以四角不会变形
        hudCorners = {}
        local corner = Instance.new("ImageLabel")
        corner.Name = "Borders"
        corner.Image = BORDER_IMG
        corner.ImageColor3 = Color3.fromRGB(255, 255, 255)
        corner.ImageTransparency = 0.30
        corner.BackgroundTransparency = 1
        corner.ScaleType = Enum.ScaleType.Slice
        corner.SliceCenter = Rect.new(500, 0, 524, 0)
        corner.SliceScale = 1
        corner.Size = UDim2.new(1, 0, 1, 0)
        corner.Position = UDim2.fromOffset(0, 0)
        corner.ZIndex = 1
        corner.Active = false
        corner.Selectable = false
        corner.Parent = hudFrame
        table.insert(hudCorners, corner)

        -- 锁定按钮：夜视仪同款「白色描边文字」风格，无底色
        hudLockBtn = Instance.new("TextButton")
        hudLockBtn.Name = "LockBtn"
        hudLockBtn.Size = UDim2.fromOffset(BTN_W, BTN_H)
        hudLockBtn.AnchorPoint = Vector2.new(1, 0)
        hudLockBtn.Position = UDim2.new(1, -10, 0, 6)
        hudLockBtn.BackgroundTransparency = 1
        hudLockBtn.BorderSizePixel = 0
        hudLockBtn.AutoButtonColor = false
        hudLockBtn.Text = "LOCKED"
        hudLockBtn.Font = Enum.Font.Unknown
        pcall(function()
            hudLockBtn.FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json",
                Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        end)
        hudLockBtn.TextSize = BTN_FSZ
        hudLockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        hudLockBtn.TextTransparency = 0.15
        hudLockBtn.TextStrokeTransparency = 0.55
        hudLockBtn.Active = true
        hudLockBtn.Selectable = false
        hudLockBtn.ZIndex = 10
        hudLockBtn.Parent = hudFrame

        -- 点击绑定：
        --   Activated 是 TextButton 标准事件（鼠标+触屏都触发），
        --   再挂 InputBegan 兜底，防止某些环境下 Activated 不响应
        -- 只用 Activated 一个事件：
        --   之前同时挂了 Activated / MouseButton1Click / InputEnded，
        --   点一下会连着触发好几次，状态被反复翻转，看起来像「点了就消失」
        local lockBusy = false
        hudLockBtn.Activated:Connect(function()
            if lockBusy then return end
            lockBusy = true
            setLocked(not hudLocked)
            task.delay(0.15, function() lockBusy = false end)
        end)
        -- 按钮不吃拖动：防止点击被 hudFrame 的拖动逻辑截走
        hudLockBtn.InputBegan:Connect(function(input)
            local ut = input.UserInputType
            if ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.Touch then
                hudDragging = false
            end
        end)

        -- 行容器
        hudInner = Instance.new("Frame")
        hudInner.Name = "Rows"
        hudInner.Size = UDim2.new(1, -PAD_X * 2, 1, -PAD_Y * 2)
        hudInner.Position = UDim2.fromOffset(PAD_X, PAD_Y)
        hudInner.BackgroundTransparency = 1
        hudInner.Active = false
        hudInner.Selectable = false
        hudInner.ZIndex = 5
        hudInner.Parent = hudFrame

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, ROW_GAP)
        layout.Parent = hudInner

        -- 一行：左侧标签 + 右侧数值（右侧给锁定按钮留出宽度）
        local function makeRow(key, order, labelText)
            local root = Instance.new("Frame")
            root.Name = key .. "Row"
            root.LayoutOrder = order
            root.Size = UDim2.new(1, 0, 0, ROW_H)
            root.BackgroundTransparency = 1
            root.Active = false
            root.Selectable = false
            root.Visible = false
            root.ZIndex = 5
            root.Parent = hudInner

            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.new(0, LABEL_W - 8, 1, 0)
            label.Position = UDim2.fromOffset(0, 0)
            label.BackgroundTransparency = 1
            -- 夜视仪同款标签字体
            label.Font = Enum.Font.Unknown
            pcall(function()
                label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",
                    Enum.FontWeight.Bold, Enum.FontStyle.Normal)
            end)
            label.TextSize = LABEL_SZ
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextTransparency = 0.25
            label.TextStrokeTransparency = 0.6
            label.TextXAlignment = Enum.TextXAlignment.Right
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.Text = labelText
            label.Active = false
            label.Selectable = false
            label.ZIndex = 5
            label.Parent = root

            local value = Instance.new("TextLabel")
            value.Name = "Value"
            value.Size = UDim2.new(1, -LABEL_W - BTN_W - 4, 1, 0)
            value.Position = UDim2.fromOffset(LABEL_W, 0)
            value.BackgroundTransparency = 1
            -- 夜视仪同款数值字体（等宽，数字不跳）
            value.Font = Enum.Font.Unknown
            pcall(function()
                value.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",
                    Enum.FontWeight.Bold, Enum.FontStyle.Normal)
            end)
            value.TextSize = FONT_SZ - 1
            value.TextColor3 = Color3.fromRGB(255, 255, 255)
            value.TextTransparency = 0
            value.TextStrokeTransparency = 0.6
            value.TextXAlignment = Enum.TextXAlignment.Left
            value.TextYAlignment = Enum.TextYAlignment.Center
            value.Text = "--"
            value.Active = false
            value.Selectable = false
            value.ZIndex = 5
            value.Parent = root

            return { root = root, label = label, value = value }
        end

        hudRows.fps = makeRow("fps", 1, "FPS")
        hudRows.ping = makeRow("ping", 2, "延迟")
        hudRows.players = makeRow("players", 3, "人数")
    end

    -- ===== 锁定 =====
    -- ===== 拖动 =====
    local function bindDrag()
        if hudDragConn then return end

        hudFrame.InputBegan:Connect(function(input)
            -- 锁定时不响应拖动
            if hudLocked then return end
            local ut = input.UserInputType
            if ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.Touch then
                -- 点在锁定按钮上时不拖动，交给按钮自己处理
                local btn = hudLockBtn
                if btn then
                    local mp = input.Position
                    local ax, ay = btn.AbsolutePosition.X, btn.AbsolutePosition.Y
                    local aw, ah = btn.AbsoluteSize.X, btn.AbsoluteSize.Y
                    if mp.X >= ax and mp.X <= ax + aw and mp.Y >= ay and mp.Y <= ay + ah then
                        return
                    end
                end
                hudDragging = true
                local ok, loc = pcall(function() return UserInputService:GetMouseLocation() end)
                hudTweens.dragStart = {
                    px = hudFrame.Position.X.Offset,
                    py = hudFrame.Position.Y.Offset,
                    mx = (ok and typeof(loc) == "Vector2") and loc.X or 0,
                    my = (ok and typeof(loc) == "Vector2") and loc.Y or 0,
                }
            end
        end)

        hudDragConn = addDragListener(function(input)
            local ut = input.UserInputType
            if ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.Touch then
                if input.UserInputState == Enum.UserInputState.End then
                    hudDragging = false
                    return
                end
            end
            if not hudDragging or hudLocked then return end
            if ut ~= Enum.UserInputType.MouseMovement and ut ~= Enum.UserInputType.Touch then return end
            local d = hudTweens.dragStart
            if not d then return end
            local ok, loc = pcall(function() return UserInputService:GetMouseLocation() end)
            if not ok or typeof(loc) ~= "Vector2" then return end

            -- 锚点是 (0,0)，Position 就是左上角，直接加减位移即可
            local nx = d.px + (loc.X - d.mx)
            local ny = d.py + (loc.Y - d.my)
            -- 夹在屏幕内，别拖出去找不回来
            local vx = hudGui and hudGui.AbsoluteSize.X or 1920
            local vy = hudGui and hudGui.AbsoluteSize.Y or 1009
            local w = hudFrame.AbsoluteSize.X
            local h = hudFrame.AbsoluteSize.Y
            nx = math.clamp(nx, -w + 40, vx - 40)
            ny = math.clamp(ny, 0, vy - 30)

            hudFrame.Position = UDim2.new(0, math.floor(nx), 0, math.floor(ny))
        end)
    end

    -- ===== 刷新 =====
    local function refreshLayout(instant)
        if not hudFrame or not hudFrame.Parent then return end
        local rows = activeRows()
        local n = #rows

        if n == 0 then
            -- 出场：Q 弹缩放（整体缩到 0 再隐藏）
            if hudVisible and hudFrame.Visible then
                hudVisible = false
                popOut(function()
                    if hudFrame and not hudVisible then
                        hudFrame.Visible = false
                        local sc = ensureScale()
                        if sc then sc.Scale = 1 end
                        -- 修复：动画结束后强制归位，防止下次显示跑到屏幕外
                        local fh = PAD_Y * 2 + 3 * ROW_H + 2 * ROW_GAP
                        positionHud(fh)
                    end
                end)
            else
                hudFrame.Visible = false
                -- 修复：直接隐藏时也归位
                local fh = PAD_Y * 2 + 3 * ROW_H + 2 * ROW_GAP
                positionHud(fh)
            end
            return
        end

        local wasVisible = hudVisible

        -- 闸门：已经 shown 过，就不再走「首次显示」流程
        --   只做静默定位，不动 Visible、不播动画
        if _hudPhase == "shown" then
            if hudFrame.Visible then
                positionHud(hudFrame.Size.Y.Offset)
            end
            return
        end

        -- 关键：夜视仪没就绪就先不显示
        --   否则会出现在错误位置，之后才被修正，非常突兀
        local nvgXr, nvgWr, nvgTopr, nvgStable = getNvgFrame()
        if not nvgXr or not nvgWr or not nvgTopr or not nvgStable then
            hudFrame.Visible = false
            hudVisible = false
            -- 轮询等夜视仪稳定
            task.spawn(function()
                for _ = 1, 150 do
                    task.wait(0.05)
                    if not hudFrame or not hudFrame.Parent then return end
                    local nx, nw, nt, ns = getNvgFrame()
                    if nx and nw and nt and ns then
                        pcall(refreshLayout, instant)
                        return
                    end
                end
            end)
            return
        end

        hudFrame.Visible = true
        hudVisible = true
        _hudPhase = "shown"    -- 标记：首次显示已完成，后续不再重复

        -- 用统一定位函数（含 X/宽度/垂直间距）
        local fullH = PAD_Y * 2 + 3 * ROW_H + 2 * ROW_GAP
        positionHud(fullH)

        -- 确保高度正常
        if hudFrame.Size.Y.Offset < 1 then
            hudFrame.Size = UDim2.fromOffset(BOX_W, desiredHeight(3))
        end

        -- 修复：确保缩放是自适应值（不是强制 1）
        applyHudScale()

        -- 首次出现时播入场动画（传入刚算好的位置，避免重复计算）
        if not wasVisible then
            popIn(hudFrame.Position.X.Offset, hudFrame.Position.Y.Offset)
        end

        -- 逐行同步显隐：新出现的行做淡入
        local order = 0
        local function syncRow(key, shouldShow)
            local r = hudRows[key]
            if not r then return end
            -- 直接从容器里找实际对象，避免 hudRows 里存的是旧引用
            local real = hudInner and hudInner:FindFirstChild(key .. "Row")
            local node = real or r.root
            if not node then return end

            if shouldShow then
                order = order + 1
                node.LayoutOrder = order
                node.Visible = true          -- 无条件设 true（不再判断）
                -- 淡入只在从隐藏变显示时做
                if r.label and r.value then
                    r.label.TextTransparency = 0.25
                    r.value.TextTransparency = 0
                end
            else
                node.Visible = false
            end
        end

        syncRow("fps", showFPS)
        syncRow("ping", showPing)
        syncRow("players", showPlayers)


        -- 高度必须按「实际显示的行数」算，不能用 activeRows() 的结果
        --   （activeRows 读的是标志位，若和实际 Visible 不一致就会算错）
        local function isRowVisible(key)
            local real = hudInner and hudInner:FindFirstChild(key .. "Row")
            if real then return real.Visible end
            local r = hudRows[key]
            return r and r.root and r.root.Visible or false
        end
        local visN = 0
        if isRowVisible("fps") then visN = visN + 1 end
        if isRowVisible("ping") then visN = visN + 1 end
        if isRowVisible("players") then visN = visN + 1 end
        if visN == 0 then
            -- 只在「真的关掉所有行」时隐藏；构建过程中行还没创建完不算
            if _nvgStable.everPlaced then
                hudFrame.Visible = false
            end
            return
        end
        local targetH = desiredHeight(visN)
        tweenSize(UDim2.fromOffset(BOX_W, targetH), instant, 0.42,
            Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    local function updateText()
        if not hudFrame or not hudFrame.Parent then return end
        if showFPS and hudRows.fps then
            if curFPS and curFPS > 0 then
                hudRows.fps.value.Text = string.format("%d", math.floor(curFPS + 0.5))
            else
                hudRows.fps.value.Text = "--"
            end
        end
        if showPing and hudRows.ping then
            hudRows.ping.value.Text = (curPing > 0)
                and string.format("%d ms", math.floor(curPing + 0.5)) or "-- ms"
        end
        if showPlayers and hudRows.players then
            hudRows.players.value.Text = string.format("%d / %d",
                #game:GetService("Players"):GetPlayers(), 20)
        end
    end

    -- ===== 采样 =====
    local function pushPing(v)
        table.insert(pingSamples, v)
        if #pingSamples > 4 then table.remove(pingSamples, 1) end
        local s = {}
        for i, x in ipairs(pingSamples) do s[i] = x end
        table.sort(s)
        local m = #s
        if m > 0 then
            curPing = (m % 2 == 1) and s[(m + 1) // 2] or ((s[m // 2] + s[m // 2 + 1]) / 2)
        end
    end

    local function doPing()
        if pingBusy or not statsPingItem then return end
        pingBusy = true
        local ok, v = pcall(function() return statsPingItem:GetValue() end)
        pingBusy = false
        if ok and type(v) == "number" and v > 0 then pushPing(v) end
    end

    local function destroyHud()
        if hudConn then pcall(function() hudConn:Disconnect() end); hudConn = nil end
        if hudDragConn then pcall(hudDragConn); hudDragConn = nil end
        killTween("size")
        hudRows = {}
        hudVisible = false
        if hudGui and hudGui.Parent then pcall(function() hudGui:Destroy() end) end
        hudGui, hudFrame, hudInner, hudCorners, hudLockBtn = nil, nil, nil, nil, nil
    end

    local function startLoop()
        -- 修复：移除"已存在就 return"的早退
        --   之前 hudFrame 存在时直接 return，跳过了下面的 sync 和循环创建
        --   导致 HUD 有框但没内容（行定义了但没 updateText、没连接）
        ensureHud()
        bindDrag()
        setLocked(hudLocked)

        -- 创建完行后同步显隐和高度
        --   修复：不要在这里直接显示，交给 refreshLayout 统一处理
        --   （refreshLayout 会等夜视仪稳定后才显示，避免出现在错误位置）
        local rows0 = activeRows()
        if #rows0 > 0 and hudFrame then
            local o = 0
            local function sync(key, on)
                local r = hudRows[key]
                if not r then return end
                if on then
                    o = o + 1
                    r.root.LayoutOrder = o
                    r.root.Visible = true
                else
                    r.root.Visible = false
                end
            end
            sync("fps", showFPS)
            sync("ping", showPing)
            sync("players", showPlayers)
            -- 直接算好尺寸和位置，首帧就是正确的
            local initH = desiredHeight(#rows0)
            hudFrame.Size = UDim2.fromOffset(BOX_W, initH)
            positionHud(initH)
        end

        local acc, pingAcc = 0, 0
        -- 修复：先断开旧连接，避免两个循环同时累加 frameCount/fpsWindow
        if hudConn then
            pcall(function() hudConn:Disconnect() end)
            hudConn = nil
        end
        frameCount, fpsWindow = 0, 0
        hudConn = RunService.RenderStepped:Connect(function(dt)
            frameCount = frameCount + 1
            fpsWindow = fpsWindow + dt
            acc = acc + dt
            pingAcc = pingAcc + dt
            if fpsWindow >= 0.3 then
                curFPS = frameCount / fpsWindow
                frameCount, fpsWindow = 0, 0
            end
            if pingAcc >= 0.5 then
                pingAcc = 0
                task.spawn(doPing)
            end
            if acc >= 0.15 then
                acc = 0
                updateText()
                -- 每 0.15 秒钉一次行可见性
                --   面板动画链路会反复改 Visible，与其追着改，
                --   不如在渲染循环里持续纠正（这是最后一道防线）
                if hudInner then
                    local f = hudInner:FindFirstChild("fpsRow")
                    local p2 = hudInner:FindFirstChild("pingRow")
                    local pl = hudInner:FindFirstChild("playersRow")
                    if f then f.Visible = showFPS and true or false end
                    if p2 then p2.Visible = showPing and true or false end
                    if pl then pl.Visible = showPlayers and true or false end
                end
            end
        end)
    end

    local function stopLoop()
        if hudConn then pcall(function() hudConn:Disconnect() end); hudConn = nil end
    end

    -- ===== 对外 =====
    -- 无论怎么调用，每次都做一次全量同步：建好缺失的 UI、同步显隐、同步高度
    local function syncAll(instant)
        if not hudGui or not hudGui.Parent then
            if showFPS or showPing or showPlayers then
                startLoop()      -- 内部会同步
                return true
            end
            return false
        end
        refreshLayout(instant and instant or false)
        updateText()
        return true
    end

    -- 批量设置：一次给全三个状态，避免分三次调用时状态不同步
    -- 建好 UI（如果还没建），然后按当前标志位刷一遍
    --   每次都走完整流程，不依赖 startLoop 的提前返回
    local function buildAndSync()
        -- 1. 确保 UI 存在
        if not hudGui or not hudGui.Parent then
            ensureHud()
        end
        if not hudFrame then return end

        -- 2. 确保拖拽/锁定绑定（这些只在首次需要）
        if not hudDragConn then
            bindDrag()
            setLocked(hudLocked)
        end

        -- 3. 确保采样循环在跑
        if not hudConn then
            local acc, pingAcc = 0, 0
            frameCount, fpsWindow = 0, 0
            hudConn = RunService.RenderStepped:Connect(function(dt)
                frameCount = frameCount + 1
                fpsWindow = fpsWindow + dt
                acc = acc + dt
                pingAcc = pingAcc + dt
                if fpsWindow >= 0.3 then
                    curFPS = frameCount / fpsWindow
                    frameCount, fpsWindow = 0, 0
                end
                if pingAcc >= 0.5 then
                    pingAcc = 0
                    task.spawn(doPing)
                end
                if acc >= 0.15 then
                    acc = 0
                    updateText()
                end
            end)
        end

        -- 4. 按标志位刷新（行显隐 + 高度动画都在 refreshLayout 里）
        refreshLayout(false)
        updateText()
    end

    -- 窗口大小变化时重新定位 + 自适应缩放
    --   小窗口（手机/窗口化）时缩小，大屏时保持原尺寸
    function HUD.Relayout()
        if not hudFrame or not hudFrame.Parent then return end

        -- 自适应缩放
        applyHudScale()

        local fh = hudFrame.Size.Y.Offset
        if fh <= 0 then return end

        -- 立即定位一次
        positionHud(fh)

        -- 延迟重试：夜视仪 UI 可能还没布局完（Status 的 AbsolutePosition 会变）
        task.spawn(function()
            for i = 1, 8 do
                task.wait(0.1)
                if not hudFrame or not hudFrame.Parent then return end
                positionHud(hudFrame.Size.Y.Offset)
            end
        end)
    end

    function HUD.SetHUDAll(fps, ping, players)
        -- 去重：状态完全没变就不重建（避免重复调用导致闪烁）
        local nf = fps and true or false
        local np = ping and true or false
        local nl = players and true or false
        if nf == showFPS and np == showPing and nl == showPlayers
           and hudFrame and hudFrame.Parent then
            return
        end
        showFPS = nf
        showPing = ping and true or false
        showPlayers = players and true or false

        if showFPS or showPing or showPlayers then
            buildAndSync()
        else
            -- 全关：播完收缩动画再销毁
            if hudFrame and hudFrame.Parent then
                refreshLayout(false)
                task.delay(0.45, function()
                    if not (showFPS or showPing or showPlayers) then
                        if hudConn then pcall(function() hudConn:Disconnect() end); hudConn = nil end
                        destroyHud()
                    end
                end)
            else
                if hudConn then pcall(function() hudConn:Disconnect() end); hudConn = nil end
                destroyHud()
            end
        end
    end

    function HUD.SetHUD(kind, on)
        if kind == "fps" then
            showFPS = on and true or false
        elseif kind == "ping" then
            showPing = on and true or false
        elseif kind == "players" then
            showPlayers = on and true or false
        else return end

        if showFPS or showPing or showPlayers then
            syncAll(false)
        else
            if hudFrame and hudFrame.Parent then
                refreshLayout(false)
                task.delay(0.42, function()
                    if not (showFPS or showPing or showPlayers) then
                        stopLoop(); destroyHud()
                    end
                end)
            else
                stopLoop(); destroyHud()
            end
        end
    end

    -- 重置 HUD 到默认位置
    -- 重置位置：带弹性回弹动画，不是瞬移
    function HUD.ResetHUDPosition()
        if not hudFrame then return end
        local h = hudFrame.Size.Y.Offset
        if h < 1 then h = hudFrame.AbsoluteSize.Y end
        local target = UDim2.new(0, BOX_X, 0, math.max(0, getBoxTopY() - h) + getInsetY())

        killTween("pos")
        -- 用 Quad 而不是 Back：Back 的过冲太大，看着像甩出去
        local info = TweenInfo.new(0.28,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out)
        local tw = TweenService:Create(hudFrame, info, { Position = target })
        tw:Play()
        hudTweens.pos = tw
    end

    function HUD.SetHUDLocked(on)
        if not hudFrame then hudLocked = on and true or false return end
        setLocked(on)
    end

    function HUD.DestroyHUD()
    getgenv().__ExamHUDGui = nil
        showFPS, showPing, showPlayers = false, false, false
        stopLoop(); destroyHud()
    end

    -- 带退场动画的销毁：先播左滑出场，动画完再销毁
    --   卸载脚本时用这个，避免 HUD 突然消失
    function HUD.DestroyHUDWithAnim(onDone)
        if not hudFrame or not hudFrame.Parent then
            HUD.DestroyHUD()
            if onDone then task.defer(onDone) end
            return
        end

        stopLoop()

        local homeX = hudFrame.Position.X.Offset
        local homeY = hudFrame.Position.Y.Offset
        local W = hudFrame.AbsoluteSize.X

        local tw = TweenService:Create(hudFrame,
            TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            { Position = UDim2.new(0, homeX - W - 40, 0, homeY) })
        tw:Play()
        tw.Completed:Connect(function()
            showFPS, showPing, showPlayers = false, false, false
            destroyHud()
            if onDone then task.defer(onDone) end
        end)
    end

    if lp then
        lp.CharacterAdded:Connect(function()
            task.wait(1)
            if showFPS or showPing or showPlayers then
                hudGui = nil
                startLoop()
            end
        end)
    end
end

-- ============================================================
-- 窗口大小变化：重新计算 HUD 位置
--   全屏/窗口化切换、手机横竖屏切换时，夜视仪位置会变，
--   HUD 必须跟着重新定位，否则会和夜视仪重叠
-- ============================================================
do
    local _lastVP = nil
    pcall(function()
        local cam = workspace.CurrentCamera
        _lastVP = cam and cam.ViewportSize
    end)

    -- 启动后强制校准几次（夜视仪 UI 是异步创建的，加载时位置可能还没定）
    task.spawn(function()
        for _, d in ipairs({0.3, 0.8, 1.5, 2.5, 4.0}) do
            task.wait(d)
            if HUD.Relayout then pcall(HUD.Relayout) end
        end
    end)

    -- 定期校准：每 2 秒检查一次 HUD 底边是否贴合夜视仪
    --   这样即使某次布局变化没被 ViewportSize 监听捕获，也能自愈
    local _lastVP = nil
    pcall(function()
        local cam = workspace.CurrentCamera
        _lastVP = cam and cam.ViewportSize
    end)

    local _vpConn = RunService.Heartbeat:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        if _lastVP and (vp.X ~= _lastVP.X or vp.Y ~= _lastVP.Y) then
            _lastVP = vp
            if HUD.Relayout then
                task.delay(0.15, function() pcall(HUD.Relayout) end)
                task.delay(0.5, function() pcall(HUD.Relayout) end)
                task.delay(1.2, function() pcall(HUD.Relayout) end)
            end
        end
    end)

    -- 定期自愈：每 2 秒校准一次（防止位置漂移）
    local _healAcc = 0
    local _healConn = RunService.Heartbeat:Connect(function(dt)
        _healAcc = _healAcc + dt
        if _healAcc < 0.2 then return end   -- 5Hz，快速积累稳定计数
        _healAcc = 0
        if HUD.Relayout then pcall(HUD.Relayout) end
    end)

    table.insert(cleanupFns, function()
        if _vpConn then pcall(function() _vpConn:Disconnect() end) end
        if _healConn then pcall(function() _healConn:Disconnect() end) end
    end)
end

-- 注册到全局：下次重载时可以拿到它播退场动画
getgenv().__ExamHUDModule = HUD


do
    -- 三项永远一起显示（已合并成一个总开关）
    local hudOn = true

    local function pushHudState()
        if HUD.SetHUDAll then
            pcall(HUD.SetHUDAll, hudOn, hudOn, hudOn)
        end
    end


    -- 总开关：关掉就整块隐藏，打开就恢复子项状态
    _G._ExamSetters.hudOn = function(v)
        hudOn = v and true or false
        _G._ExamStates.hudOn = hudOn
        pushHudState()
    end
    _G._ExamStates.hudOn = true

    -- 重置位置
    _G._ExamSetters.hudResetPos = function(v)
        if not v then return end
        if HUD and HUD.ResetHUDPosition then
            pcall(HUD.ResetHUDPosition)
        end
        -- 复位后自动弹回关（它是个动作型开关）
        task.defer(function()
            _G._ExamStates.hudResetPos = false
            if CALLBACK_SINK then pcall(CALLBACK_SINK, "hudResetPos", false) end
        end)
    end
    _G._ExamStates.hudResetPos = false

    _G._ExamStates.hudOn = true

    -- 默认开启：等主 UI 入场动画彻底结束后再启动 HUD
    task.spawn(function()
        -- 1. 等 CDMUI 就绪
        for _ = 1, 100 do
            if HUD and HUD.SetHUDAll then break end
            task.wait(0.05)
        end

        -- 2. 等面板窗口真正建完
        local win = getgenv().ExaminationWin
        for _ = 1, 200 do
            win = getgenv().ExaminationWin
            if win and win.Panel and win.Panel.AbsoluteSize.Y > 100 then break end
            task.wait(0.05)
        end

        -- 3. 等入场动画彻底结束（关键：之前只等尺寸，动画还在跑）
        win = getgenv().ExaminationWin
        if win and type(win.WaitForIntro) == "function" then
            pcall(win.WaitForIntro, win, 6)
        else
            -- 老版本没有这个 API，按经验等够时间
            task.wait(1.5)
        end

        -- 4. 再等一帧，让布局算完
        task.wait(0.1)

        -- 5. 现在启动 HUD（只调一次，SetHUDAll 内部会处理定位）
        if HUD and HUD.SetHUDAll then
            pcall(HUD.SetHUDAll, hudOn, hudOn, hudOn)
        end
    end)

    -- ============================================================
    -- HUD 自愈：定期检查，消失了就重建
    --   解决「有时候不加载」：夜视仪晚出现、重载时序错乱等情况
    -- ============================================================
    task.spawn(function()
        local failCount = 0
        while true do
            task.wait(2.0)

            -- 只在开关打开时检查
            if hudOn then
                -- 快速路径：先查已知引用（O(1)）
                local exists = false
                pcall(function()
                    local gui = getgenv().__ExamHUDGui
                    if gui and gui.Parent and gui:FindFirstChild("HudBox") then
                        exists = true
                    end
                end)

                -- 慢速路径：引用失效才全扫（只在出问题时走）
                if not exists then
                    pcall(function()
                        local pgv = lp and lp:FindFirstChild("PlayerGui")
                        local cg = game:GetService("CoreGui")
                        for _, root in ipairs({pgv, cg}) do
                            if root then
                                for _, d in ipairs(root:GetChildren()) do
                                    if d.Name == "CDMUI_HUD" and d:FindFirstChild("HudBox") then
                                        exists = true
                                        getgenv().__ExamHUDGui = d
                                        break
                                    end
                                end
                            end
                            if exists then break end
                        end
                    end)
                end

                if not exists then
                    failCount = failCount + 1
                    if failCount >= 2 then
                        -- 连续 2 次（4 秒）都没找到 → 重建
                        pcall(function()
                            if HUD and HUD.SetHUDAll then
                                HUD.SetHUDAll(hudOn, hudOn, hudOn)
                            end
                        end)
                        failCount = 0
                    end
                else
                    failCount = 0
                end
            else
                failCount = 0
            end
        end
    end)
end

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

-- ============================================================
-- 加载预热：把首次开启功能时会卡的工作提前做掉
--   每个任务都是真实的优化动作，进度条反映实际完成度
-- ============================================================
local function buildWarmupTasks()
    local tasks = {}

    -- 1) 预扫描场景容器（透视/雷达/魔法子弹都要用）
    --   首次扫描要走一遍 Workspace 树，人多时能卡 100~300ms
    tasks[#tasks + 1] = {
        Name = "扫描场景容器",
        Run = function()
            local found = {}
            for _, name in ipairs({
                "Characters", "Dummies", "AI", "NPCs",
                "Enemies", "Mobs", "Monsters",
            }) do
                local f = workspace:FindFirstChild(name)
                if f then found[#found + 1] = f end
            end
            _G._ExamContainersWarm = found

            -- 顺便统计一下当前玩家数，雷达/人数显示要用
            _G._ExamPlayerCountWarm = #game:GetService("Players"):GetPlayers()
        end,
    }

    -- 2) 预热 Highlight 实例池
    --   Roblox 的 Highlight 首次创建开销不小，预建 8 个循环复用
    tasks[#tasks + 1] = {
        Name = "预热高亮池",
        Run = function()
            local Lighting = game:GetService("Lighting")
            local holder = Lighting:FindFirstChild("__ExamHLPool")
            if not holder then
                holder = Instance.new("Folder")
                holder.Name = "__ExamHLPool"
                holder.Parent = Lighting
            end
            local pool = {}
            for i = 1, 8 do
                local h = holder:FindFirstChild("HL_" .. i)
                if not h then
                    h = Instance.new("Highlight")
                    h.Name = "HL_" .. i
                    h.Enabled = false
                    h.FillTransparency = 0.5
                    h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.Occluded
                    h.Parent = holder
                end
                pool[i] = h
            end
            _G._ExamHLPool = pool
        end,
    }

    -- 3) 预热音频池
    --   点击音效/命中音效如果每次 new Sound 会有明显延迟
    tasks[#tasks + 1] = {
        Name = "预热音频池",
        Run = function()
            local SoundService = game:GetService("SoundService")
            local holder = SoundService:FindFirstChild("__ExamSoundPool")
            if not holder then
                holder = Instance.new("Folder")
                holder.Name = "__ExamSoundPool"
                holder.Parent = SoundService
            end
            local pool = {}
            for i = 1, 4 do
                local s = holder:FindFirstChild("Snd_" .. i)
                if not s then
                    s = Instance.new("Sound")
                    s.Name = "Snd_" .. i
                    s.Volume = 0.5
                    s.Parent = holder
                end
                pool[i] = s
            end
            _G._ExamSoundPool = pool
        end,
    }

    -- 4) 预热相机/鼠标引用
    --   很多功能每帧都要读 CurrentCamera，缓存起来减少属性访问
    tasks[#tasks + 1] = {
        Name = "缓存运行环境",
        Run = function()
            _G._ExamCamWarm = workspace.CurrentCamera
            _G._ExamUISWarm = game:GetService("UserInputService")
            _G._ExamRunSvcWarm = game:GetService("RunService")
            -- 预读一次玩家角色，避免首次透视时等待
            local lp2 = game:GetService("Players").LocalPlayer
            _G._ExamLPWarm = lp2
            _G._ExamCharWarm = lp2 and lp2.Character
        end,
    }

    -- 5) 预热魔法子弹模块（首次开启要建 FOV 圈、装 hook）
    tasks[#tasks + 1] = {
        Name = "初始化战斗模块",
        Run = function()
            -- 预热 FOV 圈的 GUI 容器（不显示，只是提前建好）
            pcall(function()
                local plrs = game:GetService("Players")
                local me = plrs and plrs.LocalPlayer
                local pgv = me and me:FindFirstChild("PlayerGui")
                if pgv and not pgv:FindFirstChild("__ExamWarmGui") then
                    local g = Instance.new("ScreenGui")
                    g.Name = "__ExamWarmGui"
                    g.ResetOnSpawn = false
                    g.Enabled = false
                    g.Parent = pgv
                end
            end)
        end,
    }

    -- 6) 预热雷达点池
    tasks[#tasks + 1] = {
        Name = "预热雷达",
        Run = function()
            local plrs = game:GetService("Players")
            local me = plrs and plrs.LocalPlayer
            local pgv = me and me:FindFirstChild("PlayerGui")
            if pgv then
                local holder = pgv:FindFirstChild("__ExamRadarPool")
                if not holder then
                    holder = Instance.new("Folder")
                    holder.Name = "__ExamRadarPool"
                    holder.Parent = pgv
                end
                local pool = {}
                for i = 1, 12 do
                    local f = holder:FindFirstChild("Dot_" .. i)
                    if not f then
                        f = Instance.new("Frame")
                        f.Name = "Dot_" .. i
                        f.Size = UDim2.fromOffset(6, 6)
                        f.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                        f.BorderSizePixel = 0
                        f.Visible = false
                        f.Parent = holder
                    end
                    pool[i] = f
                end
                _G._ExamRadarPool = pool
            end
        end,
    }

    -- 7) 收尾：清理内存碎片
    tasks[#tasks + 1] = {
        Name = "整理内存",
        Run = function()
            pcall(function() collectgarbage("step") end)
            task.wait(0.03)
        end,
    }

    return tasks
end

-- 是否启用真实预热（默认开启：让加载条真的在干活）
--   关掉后加载动画只是装饰，不执行任何预热
local USE_REAL_WARMUP = true

-- Title     = 主UI里的大标题（游戏名字）
-- TopbarText = 左上角顶栏按钮的文字（固定「控制面板」）
local win = CDMUI.Create({
    Title = "试炼",
    TopbarText = "控制面板",
    RealLoading = USE_REAL_WARMUP,
    Tasks = USE_REAL_WARMUP and buildWarmupTasks() or nil,
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
tab:Expand({
    Key = "godMode",
    Name = "人物半无敌",
    Desc = "自动回满血量",
    Default = false,
    Callback = function(v) CB("godMode", v) end,
    Children = {
        { Kind = "slider", Key = "godBurst", Name = "每帧连发次数", Min = 1, Max = 10, Default = 3, Step = 1,
          Callback = function(v) CB("godBurst", v) end },
    },

})

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
tab:Expand({
    Key = "hudOn",
    Name = "屏幕信息显示",
    Desc = "显示 FPS / 延迟 / 人数 · 点 LOCKED 可拖动",
    Default = true,
    Callback = function(v) CB("hudOn", v) end,
    Children = {
        { Kind = "action", Key = "hudResetPos", Name = "重置位置",
          IconImage = "rbxassetid://112173305232811",
          IconColor = Color3.fromRGB(220, 225, 235),
          OnClick = function() CB("hudResetPos", true) end },
    },
})
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
    Desc = "子弹自动追踪已锁定的目标，命中判定跟随锁定部位",
    Default = false,
    Children = {
        { Kind = "toggle", Key = "mbShowBox", Name = "显示 3D 头框", Default = true, Callback = function(v) CB("mbShowBox", v) end },
        { Kind = "toggle", Key = "mbRequireVisible", Name = "掩体检测", Default = true, Callback = function(v) CB("mbRequireVisible", v) end },
        { Kind = "toggle", Key = "pierceShield", Name = "穿透盾牌", Default = true, Callback = function(v) CB("pierceShield", v) end },
        { Kind = "toggle", Key = "pierceHelmet", Name = "穿透 SIN 头盔", Default = true, Callback = function(v) CB("pierceHelmet", v) end },
        { Kind = "toggle", Key = "pierceTeammate", Name = "穿透队友", Default = true, Callback = function(v) CB("pierceTeammate", v) end },
        { Kind = "toggle", Key = "pierceCorpse", Name = "穿透尸体", Default = true, Callback = function(v) CB("pierceCorpse", v) end },
        { Kind = "toggle", Key = "pierceExecuting", Name = "穿透处决目标", Default = true, Callback = function(v) CB("pierceExecuting", v) end },
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
        { Kind = "toggle", Key = "mbTargetDrones", Name = "锁定BTR无人机", Default = true,
          Callback = function(v) CB("mbTargetDrones", v) end },
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
BodyPartPicker(tab, {
    Key = "mbAimPart",
    Name = "锁定部位",
    Desc = "点击人体图选择锁定的部位",
    Default = _G._ExamAimPartIndex or 1,
    Callback = function(idx)
        -- 关键：魔法子弹读的是 _G._ExamAimPartIndex，
        --   这里必须同步写，否则选了部位也不生效
        _G._ExamAimPartIndex = idx
        _G._ExamStates.mbAimPart = idx
        -- 再走统一回调（会触发 setter 和重新锁定）
        CB("mbAimPart", idx)
    end,
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
        { Kind = "cycle", Key = "bashRangeMode", Name = "范围样式", Options = { "线状", "面状" }, DefaultIndex = 1, Callback = function(v) CB("bashRangeMode", v) end },

        { Kind = "cycle", Key = "bashReflectBoss", Name = "是否击打反伤怪", Options = { "否", "是" }, DefaultIndex = 2, Callback = function(v) CB("bashReflectBoss", v) end },
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
        { Kind = "toggle", Key = "radarFast", Name = "高刷新率", Desc = "刷新更频繁，会吃点性能", Default = true, Callback = function(v) CB("radarFast", v) end },
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
local CURRENT_VERSION = "1.10.44"
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
-- 卸载流程（抽成具名函数，便于外部调用和测试）
local function doUnload()
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
        --    顶栏动画时长 = 0.24 * 0.85 + 0.04 兜底 ≈ 0.25s，这里留 0.10s 余量
        task.delay(0.35, function()
            -- 0) 先把鼠标还原成「打开面板之前」的状态
            --    必须在销毁 GUI 之前做：CDMUI 的恢复流程需要窗口对象还在，
            --    而且它内部会卸掉 __newindex hook、补写原值。
            --    之前这一步漏了，导致卸载后鼠标一直停在解锁态。
            pcall(function()
                local w = getgenv().ExaminationWin
                if w and w._RestoreMouse then
                    w:_RestoreMouse(true)
                elseif CDMUI and CDMUI.ForceRestoreMouse then
                    -- 窗口对象没了：直接强制卸 hook
                    CDMUI.ForceRestoreMouse(nil, nil)
                end
            end)

            -- 先播 HUD 退场动画，动画播完后再继续清理
            --   用 onDone 回调串联，避免在 task.delay 里用 task.wait
            local finished = false
            local function continueCleanup()
                if finished then return end
                finished = true

                -- 停功能
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
                               or d.Name == "CDMUIWidget" or d.Name == "ControlPanelBtn"
                               or d.Name == "CDMUI_HUD" then
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

            -- 最后再强制卸一次鼠标 hook（兜底）
            --   前面 _RestoreMouse(true) 是异步的（约 0.25s 后才卸），
            --   这里同步补一刀，保证卸载后鼠标一定回到原样
            pcall(function()
                local w = getgenv().ExaminationWin
                local want = w and w._savedMouseBehavior
                local wantIcon = w and w._savedMouseIcon
                if CDMUI and CDMUI.ForceRestoreMouse then
                    CDMUI.ForceRestoreMouse(want, wantIcon)
                end
            end)

                pcall(function() _G._ExamLastCleanup = nil end)
                pcall(function() _G._CDMUILastCleanup = nil end)
                pcall(function() getgenv().ExaminationUILoaded = nil end)
                pcall(function() getgenv().ExaminationWin = nil end)
            end

            -- 启动：有 HUD 就播退场动画，没有就直接清理
            if HUD and HUD.DestroyHUDWithAnim then
                local ok = pcall(function()
                    HUD.DestroyHUDWithAnim(continueCleanup)
                end)
                if not ok then continueCleanup() end
                -- 兜底：1 秒后强制完成（防止动画回调没触发）
                task.delay(1.0, continueCleanup)
            else
                continueCleanup()
            end
        end)
end

-- 暴露给外部（也可用于测试）
_G._ExamUnload = doUnload

unloadRow = tab:ClickableRow({
    Name = "卸载脚本",
    Desc = "停止所有功能并关闭面板",
    Arrow = true,
    Callback = doUnload,
})

getgenv().ExaminationUILoaded = true
print("[Examination] 已加载 · CDMUI v" .. tostring(CDMUI.Version))
