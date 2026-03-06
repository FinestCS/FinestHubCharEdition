--// Finest Hub - Char Edition 
--// [INITIAL SETUP]
pcall(function()
    if game.CoreGui:FindFirstChild("FinestHub") then game.CoreGui.FinestHub:Destroy() end
    if game.CoreGui:FindFirstChild("FinestWatermark") then game.CoreGui.FinestWatermark:Destroy() end
end)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local origAmbient = Lighting.Ambient
local origOutdoor = Lighting.OutdoorAmbient

local closed = false
local connections = {}
local flying, bv, bg = false, nil, nil
local ghostEnabled = false
local spinning = false
local triggerbotEnabled = false
local aimbotEnabled = false
local espEnabled = false
local orbiting = false
local orbitTarget = nil
local orbitAngle = 0
local healthBarEnabled = false
local skeletonEnabled = false
local nightModeEnabled = false
local chatSpamming = false
local spectating = false
local spectateTarget = nil
local freezeEnabled = false
local keybinds = {
    ["Menu"]    = Enum.KeyCode.RightControl,
    ["Fly"]     = Enum.KeyCode.F,
    ["Ghost"]   = Enum.KeyCode.G,
    ["ESP"]     = Enum.KeyCode.E,
    ["Trigger"] = Enum.KeyCode.T,
}
local listeningFor = nil
local espColor = Color3.fromRGB(170, 0, 255)
local WatermarkGui
local FooterGui
local glowTween
local gui

local function onClose()
    if closed then return end
    closed = true
    for _, c in pairs(connections) do c:Disconnect() end
    flying = false
    if bv then bv:Destroy(); bv = nil end
    if bg then bg:Destroy(); bg = nil end
    ghostEnabled = false; spinning = false; triggerbotEnabled = false; aimbotEnabled = false
    espEnabled = false; orbiting = false; orbitTarget = nil; chatSpamming = false
    skeletonEnabled = false; healthBarEnabled = false; nightModeEnabled = false
    spectating = false; spectateTarget = nil; freezeEnabled = false; freezeTarget = nil
    infiniteJump = false
    swimEnabled = false; workspace.Gravity = 196.2
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    local existingNight = Lighting:FindFirstChild("FinestNight")
    if existingNight then existingNight:Destroy() end
    Lighting.Ambient = origAmbient; Lighting.OutdoorAmbient = origOutdoor
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if hrp then
            hrp.Velocity = Vector3.zero; hrp.RotVelocity = Vector3.zero
            local fv = hrp:FindFirstChild("FlingVel"); if fv then fv:Destroy() end
        end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            if p.Character:FindFirstChild("FinestESP") then p.Character.FinestESP:Destroy() end
            if p.Character:FindFirstChild("FinestName") then p.Character.FinestName:Destroy() end
            if p.Character:FindFirstChild("FinestHealthBar") then p.Character.FinestHealthBar:Destroy() end
            if p.Character:FindFirstChild("FinestSkeleton") then p.Character.FinestSkeleton:Destroy() end
        end
    end
    if connections.renderStepped then connections.renderStepped:Disconnect() end
    if connections.inputBegan then connections.inputBegan:Disconnect() end
    if connections.m2Began then connections.m2Began:Disconnect() end
    if connections.m2Ended then connections.m2Ended:Disconnect() end
    if glowTween then glowTween:Cancel() end
    if WatermarkGui then WatermarkGui:Destroy() end
    if FooterGui then FooterGui:Destroy() end
    if gui then gui:Destroy() end
    pcall(function()
        if game.CoreGui:FindFirstChild("FinestCrosshair") then game.CoreGui.FinestCrosshair:Destroy() end
        if game.CoreGui:FindFirstChild("FinestParticles") then game.CoreGui.FinestParticles:Destroy() end
        if game.CoreGui:FindFirstChild("FinestFOVCircle") then game.CoreGui.FinestFOVCircle:Destroy() end
    end)
end

local VirtualUser = game:GetService("VirtualUser")
player.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "FinestHub"

local function playSound(id, vol)
    local s = Instance.new("Sound", gui); s.SoundId = "rbxassetid://" .. tostring(id); s.Volume = vol or 0.5; s:Play(); game.Debris:AddItem(s, 1)
end
local function click() playSound(6895079853, 0.5) end
local function menuSound() playSound(6031313768, 0.7) end

--// [NOTIFICATION SYSTEM - smooth slide in from right, slide out to right]
local notifYOffset = -70  -- base Y position from bottom
local activeNotifs = {}   -- track stacked notifications

local function notify(text, isOn)
    -- shift existing notifs up to make room
    for _, n in ipairs(activeNotifs) do
        if n and n.Parent then
            TweenService:Create(n, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -265, 1, n.Position.Y.Offset - 52)
            }):Play()
        end
    end

    local notif = Instance.new("Frame", gui)
    notif.Size = UDim2.new(0, 250, 0, 48)
    notif.Position = UDim2.new(1, 20, 1, notifYOffset)
    notif.BackgroundColor3 = isOn and Color3.fromRGB(0, 180, 90) or Color3.fromRGB(110, 0, 190)
    notif.BackgroundTransparency = 0
    notif.ZIndex = 20
    notif.ClipsDescendants = true
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 12)

    -- colored left accent bar
    local accent = Instance.new("Frame", notif)
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.BackgroundColor3 = isOn and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(190, 80, 255)
    accent.BorderSizePixel = 0; accent.ZIndex = 21
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 12)

    local label = Instance.new("TextLabel", notif)
    label.Size = UDim2.new(1, -16, 0, 38); label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1; label.Text = text
    label.Font = Enum.Font.GothamBold; label.TextSize = 14
    label.TextColor3 = Color3.new(1, 1, 1); label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 21; label.TextTruncate = Enum.TextTruncate.AtEnd

    -- progress bar track (dark background)
    local barTrack = Instance.new("Frame", notif)
    barTrack.Size = UDim2.new(1, 0, 0, 3)
    barTrack.Position = UDim2.new(0, 0, 1, -3)
    barTrack.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    barTrack.BackgroundTransparency = 0.5
    barTrack.BorderSizePixel = 0
    barTrack.ZIndex = 22

    -- progress bar fill (drains left to right over 2.2s)
    local barFill = Instance.new("Frame", barTrack)
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = isOn and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(200, 100, 255)
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 23
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    table.insert(activeNotifs, notif)

    -- slide IN from right
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -265, 1, notifYOffset)
    }):Play()

    -- drain the progress bar over the display duration (2.2s)
    task.delay(0.3, function()
        if not barFill or not barFill.Parent then return end
        TweenService:Create(barFill, TweenInfo.new(2.2, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0)
        }):Play()
    end)

    task.delay(2.5, function()
        if not notif or not notif.Parent then return end
        TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 20, 1, notif.Position.Y.Offset),
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        TweenService:Create(accent, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(barFill, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        task.wait(0.35)
        for i, n in ipairs(activeNotifs) do if n == notif then table.remove(activeNotifs, i); break end end
        if notif and notif.Parent then notif:Destroy() end
    end)
end

WatermarkGui = Instance.new("ScreenGui", game.CoreGui)
WatermarkGui.Name = "FinestWatermark"; WatermarkGui.Enabled = false
local WFrame = Instance.new("Frame", WatermarkGui)
WFrame.Size = UDim2.new(0, 380, 0, 30); WFrame.Position = UDim2.new(1, -390, 0, 10)
WFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 40); WFrame.BackgroundTransparency = 0.3
Instance.new("UICorner", WFrame).CornerRadius = UDim.new(0, 6)
local WStroke = Instance.new("UIStroke", WFrame); WStroke.Color = Color3.fromRGB(170, 0, 255); WStroke.Thickness = 1.5
local WText = Instance.new("TextLabel", WFrame); WText.Size = UDim2.new(1,0,1,0); WText.BackgroundTransparency = 1; WText.TextColor3 = Color3.new(1,1,1); WText.Font = Enum.Font.GothamBold; WText.TextSize = 14; WText.RichText = true

-- smooth FPS counter + dynamic color
WText.Text = "Finest Hub | Char Edition | <font color='#00FF44'>[ Anti AFK: On ]</font>"

local _wt = 0
local _wConn = RunService.RenderStepped:Connect(function(dt)
    if closed then return end
    _wt = _wt + dt * 1.2
    -- pulse between deep gold (#B8860B) and bright gold (#FFD700)
    local t = (math.sin(_wt) + 1) / 2
    local r = math.floor(184 + 71 * t)
    local g = math.floor(134 + 81 * t)
    local b2 = math.floor(11 + 0 * t)
    local hex = string.format("%02X%02X%02X", r, g, b2)
    WText.Text = "Finest Hub | <font color='#" .. hex .. "'><b>Char Edition</b></font> | <font color='#00FF44'>[ Anti AFK: On ]</font>"
end)
table.insert(connections, _wConn)
local Main = Instance.new("Frame", gui)
Main.Size = UDim2.new(0,550,0,300); Main.Position = UDim2.new(0.5,-275,-1,-150); Main.BackgroundColor3 = Color3.fromRGB(22,0,42); Main.BackgroundTransparency = 0.08; Main.Active = true; Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)

-- subtle diagonal gradient overlay
local glassTint = Instance.new("Frame", Main)
glassTint.Size = UDim2.new(1,0,1,0); glassTint.BackgroundColor3 = Color3.fromRGB(80,10,130)
glassTint.BackgroundTransparency = 0.75; glassTint.BorderSizePixel = 0; glassTint.ZIndex = 1
Instance.new("UICorner", glassTint).CornerRadius = UDim.new(0,18)
local tintGrad = Instance.new("UIGradient", glassTint)
tintGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(160,60,255)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(60,0,110)),ColorSequenceKeypoint.new(1,Color3.fromRGB(10,0,20))})
tintGrad.Rotation = 135

-- very subtle top-edge sheen line
local glassSheen = Instance.new("Frame", Main)
glassSheen.Size = UDim2.new(0.65,0,0,1); glassSheen.Position = UDim2.new(0.175,0,0,1)
glassSheen.BackgroundColor3 = Color3.fromRGB(210,170,255); glassSheen.BackgroundTransparency = 0.5
glassSheen.BorderSizePixel = 0; glassSheen.ZIndex = 3
Instance.new("UICorner", glassSheen).CornerRadius = UDim.new(1,0)
local sheenGrad = Instance.new("UIGradient", glassSheen)
sheenGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0,0,0)),ColorSequenceKeypoint.new(0.3,Color3.new(1,1,1)),ColorSequenceKeypoint.new(0.7,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(0,0,0))})

local Glow = Instance.new("UIStroke", Main); Glow.Color = Color3.fromRGB(170,0,255); Glow.Thickness = 2; Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; Glow.Transparency = 0.3
task.spawn(function()
    introGui = Instance.new("ScreenGui", game.CoreGui)
    introGui.Name = "FinestIntro"; introGui.ResetOnSpawn = false; introGui.IgnoreGuiInset = true
    introBg = Instance.new("Frame", introGui); introBg.Size = UDim2.new(1,0,1,0); introBg.BackgroundColor3 = Color3.fromRGB(8,0,18); introBg.BackgroundTransparency = 0; introBg.BorderSizePixel = 0; introBg.ZIndex = 10
    introLbl = Instance.new("TextLabel", introBg); introLbl.Size = UDim2.new(1,0,0,80); introLbl.AnchorPoint = Vector2.new(0.5,0.5); introLbl.Position = UDim2.new(0.5,0,0.5,0); introLbl.BackgroundTransparency = 1; introLbl.Font = Enum.Font.GothamBold; introLbl.TextSize = 48; introLbl.TextColor3 = Color3.fromRGB(255,215,0); introLbl.RichText = true; introLbl.ZIndex = 11
    introSub = Instance.new("TextLabel", introBg); introSub.Size = UDim2.new(1,0,0,28); introSub.AnchorPoint = Vector2.new(0.5,0.5); introSub.Position = UDim2.new(0.5,0,0.5,50); introSub.BackgroundTransparency = 1; introSub.Font = Enum.Font.Gotham; introSub.TextSize = 16; introSub.TextColor3 = Color3.fromRGB(180,100,255); introSub.Text = "finest hub"; introSub.TextTransparency = 1; introSub.ZIndex = 11
    -- intro particles
    introParticleLoop = true
    task.spawn(function()
        introColors = {Color3.fromRGB(255,215,0),Color3.fromRGB(200,100,255),Color3.fromRGB(255,180,50),Color3.fromRGB(170,0,255),Color3.fromRGB(255,255,200)}
        while introParticleLoop do
            task.wait(0.06)
            ipc = Instance.new("Frame", introBg)
            ipc.BorderSizePixel = 0; ipc.ZIndex = 10
            ipcSz = math.random(2,6); ipc.Size = UDim2.new(0,ipcSz,0,ipcSz)
            ipc.BackgroundColor3 = introColors[math.random(1,#introColors)]
            ipc.Position = UDim2.new(math.random(0,100)/100, 0, 1, 0)
            Instance.new("UICorner", ipc).CornerRadius = UDim.new(1,0)
            ipcDriftX = math.random(-40,40); ipcDur = math.random(12,22)/10
            TweenService:Create(ipc, TweenInfo.new(ipcDur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(ipc.Position.X.Scale, ipcDriftX, -0.1, 0),
                BackgroundTransparency = 1,
                Size = UDim2.new(0,1,0,1)
            }):Play()
            game.Debris:AddItem(ipc, ipcDur+0.1)
        end
    end)
    -- subtle bg pulse
    task.spawn(function()
        while introParticleLoop do
            TweenService:Create(introBg, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(20,0,40)}):Play()
            task.wait(1.2)
            TweenService:Create(introBg, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(5,0,15)}):Play()
            task.wait(1.2)
        end
    end)
    -- Loading bar at bottom
    loadBar = Instance.new("Frame", introBg); loadBar.Size = UDim2.new(0.7,0,0,4); loadBar.Position = UDim2.new(0.15,0,0.82,0); loadBar.BackgroundColor3 = Color3.fromRGB(30,0,50); loadBar.BorderSizePixel = 0; loadBar.ZIndex = 12
    Instance.new("UICorner", loadBar).CornerRadius = UDim.new(1,0)
    loadFill = Instance.new("Frame", loadBar); loadFill.Size = UDim2.new(0,0,1,0); loadFill.BackgroundColor3 = Color3.fromRGB(255,215,0); loadFill.BorderSizePixel = 0; loadFill.ZIndex = 13
    Instance.new("UICorner", loadFill).CornerRadius = UDim.new(1,0)
    loadLbl = Instance.new("TextLabel", introBg); loadLbl.Size = UDim2.new(1,0,0,20); loadLbl.Position = UDim2.new(0,0,0.86,0); loadLbl.BackgroundTransparency = 1; loadLbl.Font = Enum.Font.Gotham; loadLbl.TextSize = 13; loadLbl.TextColor3 = Color3.fromRGB(180,100,255); loadLbl.ZIndex = 12; loadLbl.Text = ""
    -- Run loading steps concurrently
    task.spawn(function()
        loadSteps = {
            {text="Loading Finest Kisses...",  pct=0.25, dur=0.6},
            {text="Loading Finest Hugs...",    pct=0.55, dur=0.6},
            {text="Injecting love...",         pct=0.82, dur=0.5},
            {text="Done!",                      pct=1.0,  dur=0.3},
        }
        for si = 1, #loadSteps do
            loadLbl.Text = loadSteps[si].text
            TweenService:Create(loadFill, TweenInfo.new(loadSteps[si].dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(loadSteps[si].pct, 0, 1, 0)}):Play()
            task.wait(loadSteps[si].dur + 0.15)
        end
    end)
    glitchPool = {"#","@","!","%","&","*","?","X","Z","$","~","^","/","\\","|","<",">"}
    glitchTarget = "Char Edition"
    glitchFn = function(resolve)
        glitchOut = ""
        for gi = 1, #glitchTarget do
            if gi <= resolve or glitchTarget:sub(gi,gi) == " " then glitchOut = glitchOut .. glitchTarget:sub(gi,gi)
            else glitchOut = glitchOut .. glitchPool[math.random(1,#glitchPool)] end
        end
        return glitchOut
    end
    glitchT0 = tick()
    while tick()-glitchT0 < 0.6 do introLbl.Text = glitchFn(0); task.wait(0.05) end
    for gi = 0, #glitchTarget do
        for _ = 1, 3 do introLbl.Text = glitchFn(gi); task.wait(0.04) end
    end
    introLbl.Text = glitchTarget
    TweenService:Create(introSub, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    task.wait(1.0)
    TweenService:Create(introBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(introLbl, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(introSub, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    task.wait(0.5)
    introParticleLoop = false
    introGui:Destroy()
    FooterGui.Enabled=true; WatermarkGui.Enabled=true
    TweenService:Create(Main, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5,-275,0.5,-150)}):Play()
end)
glowTween = TweenService:Create(Glow, TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Thickness=2.5, Color=Color3.fromRGB(195,65,255), Transparency=0})
glowTween:Play()

local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1,0,0,45); Title.BackgroundTransparency = 1; Title.Text = "Finest Hub"; Title.Font = Enum.Font.GothamBold; Title.TextSize = 24; Title.TextColor3 = Color3.fromRGB(220,180,255); Title.RichText = true

local particleGui = Instance.new("Frame", gui); particleGui.Name = "FinestParticles"; particleGui.BackgroundTransparency = 1; particleGui.Size = UDim2.new(1,0,1,0); particleGui.ZIndex = 0
local particleColors = {Color3.fromRGB(200,100,255),Color3.fromRGB(170,0,255),Color3.fromRGB(220,150,255),Color3.fromRGB(140,0,220)}
local function spawnParticle()
    if closed or not Main.Visible then return end
    local p = Instance.new("Frame", particleGui); p.BackgroundColor3 = particleColors[math.random(1,#particleColors)]; local sz = math.random(2,5); p.Size = UDim2.new(0,sz,0,sz); p.BorderSizePixel = 0; p.ZIndex = 10
    Instance.new("UICorner", p).CornerRadius = UDim.new(1,0)
    local mx=Main.AbsolutePosition.X; local my=Main.AbsolutePosition.Y; local mw=Main.AbsoluteSize.X; local mh=Main.AbsoluteSize.Y
    local edge=math.random(1,4); local startX,startY
    if edge==1 then startX=mx+math.random(0,mw); startY=my elseif edge==2 then startX=mx+math.random(0,mw); startY=my+mh elseif edge==3 then startX=mx; startY=my+math.random(0,mh) else startX=mx+mw; startY=my+math.random(0,mh) end
    p.Position=UDim2.new(0,startX,0,startY); p.BackgroundTransparency=0.2
    local driftX=math.random(-18,18); local driftY=math.random(-28,-8); local duration=math.random(8,16)/10
    TweenService:Create(p,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(0,startX+driftX,0,startY+driftY),BackgroundTransparency=1,Size=UDim2.new(0,1,0,1)}):Play()
    game.Debris:AddItem(p,duration+0.1)
end
task.spawn(function() while not closed do task.wait(0.12); if Main.Visible then spawnParticle() end end end)

local titleChars={"F","i","n","e","s","t"," ","H","u","b"}
local titleColors={Color3.fromRGB(220,180,255),Color3.fromRGB(200,120,255),Color3.fromRGB(180,60,255),Color3.fromRGB(160,0,240),Color3.fromRGB(180,60,255),Color3.fromRGB(200,120,255)}
local function buildWaveText(offset)
    local result=""
    for i,ch in ipairs(titleChars) do
        if ch==" " then result=result.." " else
            local ci=((i+offset-1)%#titleColors)+1; local c=titleColors[ci]; local hex=string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
            result=result.."<font color='#"..hex.."'>"..ch.."</font>"
        end
    end
    return result
end
task.spawn(function()
    Title.Text=""; task.wait(0.4)
    for i=1,#titleChars do if closed then return end; local partial=""; for j=1,i do partial=partial..titleChars[j] end; Title.Text=partial; task.wait(0.07) end
    task.wait(0.3); local offset=0
    while not closed do Title.Text=buildWaveText(offset); offset=(offset+1)%#titleColors; task.wait(0.18) end
end)

local Close = Instance.new("TextButton", Main); Close.Size=UDim2.new(0,40,0,40); Close.Position=UDim2.new(1,-45,0,0); Close.Text="X"; Close.BackgroundTransparency=1; Close.TextColor3=Color3.fromRGB(255,120,200); Close.Font=Enum.Font.GothamBold; Close.TextSize=22
local Min = Instance.new("TextButton", Main); Min.Size=UDim2.new(0,40,0,40); Min.Position=UDim2.new(1,-85,0,0); Min.Text="-"; Min.BackgroundTransparency=1; Min.TextColor3=Color3.fromRGB(200,150,255); Min.Font=Enum.Font.GothamBold; Min.TextSize=28

local Sidebar = Instance.new("ScrollingFrame", Main)
Sidebar.Size=UDim2.new(0,140,1,-55); Sidebar.Position=UDim2.new(0,5,0,45); Sidebar.BackgroundColor3=Color3.fromRGB(45,0,75); Sidebar.BackgroundTransparency=0.3
Sidebar.ScrollBarThickness=3; Sidebar.ScrollBarImageColor3=Color3.fromRGB(130,0,200); Sidebar.CanvasSize=UDim2.new(0,0,0,255); Sidebar.BorderSizePixel=0
Instance.new("UICorner", Sidebar).CornerRadius=UDim.new(0,14)

FooterGui = Instance.new("ScreenGui", game.CoreGui); FooterGui.Name="FinestFooter"; FooterGui.Enabled=false
local Footer = Instance.new("Frame", FooterGui); Footer.Size=UDim2.new(0,380,0,26); Footer.Position=UDim2.new(1,-390,0,45); Footer.BackgroundColor3=Color3.fromRGB(20,0,40); Footer.BackgroundTransparency=0.3
Instance.new("UICorner", Footer).CornerRadius=UDim.new(0,6)
local FooterStroke = Instance.new("UIStroke", Footer); FooterStroke.Color=Color3.fromRGB(170,0,255); FooterStroke.Thickness=1.5
local FooterLabel = Instance.new("TextLabel", Footer); FooterLabel.Size=UDim2.new(1,-10,1,0); FooterLabel.Position=UDim2.new(0,8,0,0); FooterLabel.BackgroundTransparency=1; FooterLabel.Text="<font color='#666688'>No features active</font>"; FooterLabel.Font=Enum.Font.Gotham; FooterLabel.TextSize=12; FooterLabel.TextColor3=Color3.fromRGB(180,130,255); FooterLabel.TextXAlignment=Enum.TextXAlignment.Left; FooterLabel.RichText=true

local activeFeatures = {}
local function updateFooter()
    local parts={}
    for feat,on in pairs(activeFeatures) do if on then table.insert(parts,"<font color='#BB66FF'>"..feat.."</font>") end end
    if #parts==0 then FooterLabel.Text="<font color='#666688'>No features active</font>" else FooterLabel.Text="● "..table.concat(parts,"  ·  ") end
end

local Content = Instance.new("Frame", Main); Content.Size=UDim2.new(1,-160,1,-60); Content.Position=UDim2.new(0,155,0,50); Content.BackgroundTransparency=1; Content.ClipsDescendants=true

local minimized = false
Min.MouseButton1Click:Connect(function()
    menuSound(); minimized = not minimized
    if minimized then
        Sidebar.Visible=false; Content.Visible=false; Close.Visible=false
        TweenService:Create(Main,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.new(0,200,0,45),BackgroundTransparency=0.3}):Play()
        Title.Size=UDim2.new(0,120,0,45); Min.Position=UDim2.new(1,-45,0,0); Min.Text="+"
    else
        local expand=TweenService:Create(Main,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.new(0,550,0,300),BackgroundTransparency=0.2})
        Title.Size=UDim2.new(1,0,0,45); Close.Visible=true; Close.Position=UDim2.new(1,-45,0,0); Min.Position=UDim2.new(1,-85,0,0); Min.Text="-"
        expand:Play(); expand.Completed:Wait()
        Sidebar.Visible=true; Content.Visible=true; Footer.Visible=true
    end
end)

local tabIcons = {["Misc"]="⚙️",["Movement"]="🏃",["FPS"]="🎮",["TP"]="📍",["Players"]="👥",["Troll"]="🌀",["Visuals"]="👁",["Settings"]="🔧"}

--// [TAB SYSTEM WITH SMOOTH FADE]
local currentPage = nil
local tabTransitioning = false

local function createTab(name, y)
    local icon = tabIcons[name] or ""
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size=UDim2.new(1,-10,0,28); btn.Position=UDim2.new(0,5,0,y); btn.Text=icon.." "..name
    btn.BackgroundColor3=Color3.fromRGB(70,0,110); btn.TextColor3=Color3.fromRGB(230,200,255); btn.Font=Enum.Font.GothamBold; btn.TextSize=13
    Instance.new("UICorner", btn).CornerRadius=UDim.new(0,8)
    local tabStroke=Instance.new("UIStroke", btn); tabStroke.Color=Color3.fromRGB(200,80,255); tabStroke.Thickness=1.5; tabStroke.Transparency=1

    local page=Instance.new("Frame", Content); page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1; page.Visible=false

    btn.MouseButton1Click:Connect(function()
        if tabTransitioning or currentPage == page then return end
        click()
        -- update tab visuals
        for _,v in pairs(Sidebar:GetChildren()) do
            if v:IsA("TextButton") then
                TweenService:Create(v,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(70,0,110),TextColor3=Color3.fromRGB(230,200,255)}):Play()
                local s=v:FindFirstChildOfClass("UIStroke"); if s then TweenService:Create(s,TweenInfo.new(0.15),{Transparency=1}):Play() end
            end
        end
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(130,0,210),TextColor3=Color3.fromRGB(255,255,255)}):Play()
        TweenService:Create(tabStroke,TweenInfo.new(0.15),{Transparency=0}):Play()

        -- smooth fade between pages
        if currentPage then
            tabTransitioning = true
            local oldPage = currentPage
            -- fade out old page
            for _,child in pairs(oldPage:GetChildren()) do
                if child:IsA("GuiObject") then
                    TweenService:Create(child, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {GroupTransparency = child:IsA("CanvasGroup") and 1 or nil}):Play()
                end
            end
            TweenService:Create(oldPage, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
            -- use a simple frame transparency approach: tween a cover frame
            oldPage.Visible = false
            currentPage = page
            -- fade in new page: start transparent then reveal
            page.Visible = true
            page.BackgroundTransparency = 1
            -- tween all direct children's transparency
            for _,child in pairs(page:GetChildren()) do
                if child:IsA("GuiObject") then
                    pcall(function()
                        local orig = child.BackgroundTransparency
                        child.BackgroundTransparency = 1
                        TweenService:Create(child, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = orig}):Play()
                    end)
                end
            end
            task.delay(0.18, function() tabTransitioning = false end)
        else
            currentPage = page
            page.Visible = true
        end
    end)

    return page, btn, tabStroke
end

local MovePage,    MoveTabBtn,  MoveStroke    = createTab("Movement",   5)
local FPSPage,     FPSTabBtn,   FPSStroke     = createTab("FPS",       35)
local TPPage,      TPTabBtn,    TPStroke      = createTab("TP",        65)
local PlayersPage, PlTabBtn,    PlStroke      = createTab("Players",   95)
local TrollPage,   TrTabBtn,    TrStroke      = createTab("Troll",    125)
local VisualPage,  VisTabBtn,   VisStroke     = createTab("Visuals",  155)
local MiscPage,    MiscBtn,     MiscStroke    = createTab("Misc",     185)
local SettingsPage, SetTabBtn,  SetStroke     = createTab("Settings", 215)
local FlyPage = MovePage
local GhostPage = MiscPage

-- Tab group separators: thin glowing lines between logical groups
-- Group 1: Movement, FPS, TP  |  Group 2: Players, Troll, Visuals  |  Group 3: Misc, Settings
local function addSeparator(y)
    local sep = Instance.new("Frame", Sidebar)
    sep.Size = UDim2.new(1, -20, 0, 1)
    sep.Position = UDim2.new(0, 10, 0, y)
    sep.BackgroundColor3 = Color3.fromRGB(130, 0, 200)
    sep.BackgroundTransparency = 0.6
    sep.BorderSizePixel = 0
    -- subtle gradient fade on edges
    local grad = Instance.new("UIGradient", sep)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
        ColorSequenceKeypoint.new(0.2, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(0.8, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
    })
end
addSeparator(93)   -- between TP and Players
addSeparator(183)  -- between Visuals and Misc

currentPage = MovePage
MovePage.Visible = true
TweenService:Create(MoveTabBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(130,0,210),TextColor3=Color3.fromRGB(255,255,255)}):Play()
TweenService:Create(MoveStroke,TweenInfo.new(0.15),{Transparency=0}):Play()

local function addBox(parent, placeholder, y, default)
    local box=Instance.new("TextBox",parent); box.Size=UDim2.new(0,180,0,45); box.Position=UDim2.new(0,0,0,y); box.PlaceholderText=placeholder; box.Text=default or ""; box.BackgroundColor3=Color3.fromRGB(60,0,100); box.TextColor3=Color3.new(1,1,1); box.Font=Enum.Font.GothamBold; box.TextSize=16
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,10); return box
end
local function addBtn(parent, text, y, keybind)
    local btn=Instance.new("TextButton",parent); btn.Size=UDim2.new(0,180,0,45); btn.Position=UDim2.new(0,0,0,y); btn.Text=text; btn.BackgroundColor3=Color3.fromRGB(120,0,200); btn.TextColor3=Color3.new(1,1,1); btn.Font=Enum.Font.GothamBold; btn.TextSize=18
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    if keybind then
        local hint=Instance.new("TextLabel",btn); hint.Size=UDim2.new(0,28,0,16); hint.Position=UDim2.new(1,-31,1,-18); hint.BackgroundColor3=Color3.fromRGB(80,0,140); hint.BackgroundTransparency=0.2; hint.Text=keybind; hint.Font=Enum.Font.GothamBold; hint.TextSize=10; hint.TextColor3=Color3.fromRGB(200,160,255); hint.ZIndex=2
        Instance.new("UICorner",hint).CornerRadius=UDim.new(0,4)
    end
    return btn
end

--// [MISC MODULE]
local healthBox=addBox(MiscPage,"Set Health",0); local maxHealthBox=addBox(MiscPage,"Max HP",0); maxHealthBox.Position=UDim2.new(0,190,0,0); maxHealthBox.Size=UDim2.new(0,95,0,45)
local setHealthBtn=addBtn(MiscPage,"Set Health",55)
setHealthBtn.MouseButton1Click:Connect(function()
    click(); local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        local newMax=tonumber(maxHealthBox.Text); local newHP=tonumber(healthBox.Text)
        if newMax and newMax>0 then hum.MaxHealth=newMax end
        if newHP then hum.Health=math.clamp(newHP,0,hum.MaxHealth) end
        setHealthBtn.BackgroundColor3=Color3.fromRGB(0,200,100); TweenService:Create(setHealthBtn,TweenInfo.new(0.5),{BackgroundColor3=Color3.fromRGB(120,0,200)}):Play()
        notify("Health: "..math.floor(hum.Health).." / "..math.floor(hum.MaxHealth),true)
    end
end)

miscSep=Instance.new("Frame",MiscPage); miscSep.Size=UDim2.new(1,-10,0,1); miscSep.Position=UDim2.new(0,5,0,107); miscSep.BackgroundColor3=Color3.fromRGB(130,0,200); miscSep.BackgroundTransparency=0.4; miscSep.BorderSizePixel=0
local ghostBtn=addBtn(MiscPage,"Ghost: OFF",110,"[G]")
ghostBtn.MouseButton1Click:Connect(function()
    click(); ghostEnabled=not ghostEnabled; ghostBtn.Text=ghostEnabled and "Ghost: ON" or "Ghost: OFF"; ghostBtn.BackgroundColor3=ghostEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["👻 Ghost"]=ghostEnabled; updateFooter()
end)

--// [MOVEMENT MODULE]
local moveScroll=Instance.new("ScrollingFrame",MovePage); moveScroll.Size=UDim2.new(1,0,1,0); moveScroll.BackgroundTransparency=1; moveScroll.ScrollBarThickness=3; moveScroll.ScrollBarImageColor3=Color3.fromRGB(140,0,220); moveScroll.CanvasSize=UDim2.new(0,0,0,345)
local function moveBtn(text,y,kb)
    local btn=Instance.new("TextButton",moveScroll); btn.Size=UDim2.new(0,180,0,45); btn.Position=UDim2.new(0,0,0,y); btn.Text=text; btn.BackgroundColor3=Color3.fromRGB(120,0,200); btn.TextColor3=Color3.new(1,1,1); btn.Font=Enum.Font.GothamBold; btn.TextSize=18
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    if kb then local hint=Instance.new("TextLabel",btn); hint.Size=UDim2.new(0,28,0,16); hint.Position=UDim2.new(1,-31,1,-18); hint.BackgroundColor3=Color3.fromRGB(80,0,140); hint.BackgroundTransparency=0.2; hint.Text=kb; hint.Font=Enum.Font.GothamBold; hint.TextSize=10; hint.TextColor3=Color3.fromRGB(200,160,255); hint.ZIndex=2; Instance.new("UICorner",hint).CornerRadius=UDim.new(0,4) end
    return btn
end
local function moveBox(ph,y,def) local box=Instance.new("TextBox",moveScroll); box.Size=UDim2.new(0,180,0,45); box.Position=UDim2.new(0,0,0,y); box.PlaceholderText=ph; box.Text=def or ""; box.BackgroundColor3=Color3.fromRGB(60,0,100); box.TextColor3=Color3.new(1,1,1); box.Font=Enum.Font.GothamBold; box.TextSize=16; Instance.new("UICorner",box).CornerRadius=UDim.new(0,10); return box end
local function sectionLabel(text,y) local lbl=Instance.new("TextLabel",moveScroll); lbl.Size=UDim2.new(1,0,0,18); lbl.Position=UDim2.new(0,0,0,y); lbl.BackgroundTransparency=1; lbl.Text=text; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11; lbl.TextColor3=Color3.fromRGB(170,100,255); lbl.TextXAlignment=Enum.TextXAlignment.Left end

sectionLabel("── Walk Speed",0)
local speedBox=moveBox("Enter Speed",20,"16")
local setSpeed=moveBtn("Set Speed",73)
setSpeed.MouseButton1Click:Connect(function() click(); if player.Character then player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed=tonumber(speedBox.Text) or 16 end end)
local presetData={{"Walk",16},{"Sprint",50},{"Sonic",150}}
for i,preset in ipairs(presetData) do
    local pb=Instance.new("TextButton",moveScroll); pb.Size=UDim2.new(0,78,0,28); pb.Position=UDim2.new(0,190,0,20+(i-1)*34); pb.Text=preset[1]; pb.BackgroundColor3=Color3.fromRGB(90,0,160); pb.TextColor3=Color3.new(1,1,1); pb.Font=Enum.Font.GothamBold; pb.TextSize=13
    Instance.new("UICorner",pb).CornerRadius=UDim.new(0,8)
    local sub=Instance.new("TextLabel",pb); sub.Size=UDim2.new(1,0,0,12); sub.Position=UDim2.new(0,0,1,-13); sub.BackgroundTransparency=1; sub.Text=tostring(preset[2]); sub.Font=Enum.Font.Gotham; sub.TextSize=10; sub.TextColor3=Color3.fromRGB(180,130,255)
    pb.MouseButton1Click:Connect(function() click(); speedBox.Text=tostring(preset[2]); if player.Character then player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed=preset[2] end; pb.BackgroundColor3=Color3.fromRGB(0,200,100); TweenService:Create(pb,TweenInfo.new(0.5),{BackgroundColor3=Color3.fromRGB(90,0,160)}):Play() end)
end

sectionLabel("── Fly",130)
local FlySpeedBox=moveBox("Fly Speed",150,"70")
local FlyBtn=moveBtn("Toggle Fly: OFF",203,"[F]")
FlyBtn.MouseButton1Click:Connect(function()
    click(); flying=not flying; FlyBtn.Text=flying and "Toggle Fly: ON" or "Toggle Fly: OFF"; FlyBtn.BackgroundColor3=flying and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["🕊 Fly"]=flying; updateFooter()
    local hrp=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if flying and hrp then bv=Instance.new("BodyVelocity",hrp); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bg=Instance.new("BodyGyro",hrp); bg.MaxTorque=Vector3.new(1e9,1e9,1e9) else if bv then bv:Destroy() end; if bg then bg:Destroy() end end
end)
local flyPresetData={{"Slow",30},{"Normal",70},{"Fast",150}}
for i,preset in ipairs(flyPresetData) do
    local pb=Instance.new("TextButton",moveScroll); pb.Size=UDim2.new(0,78,0,28); pb.Position=UDim2.new(0,190,0,150+(i-1)*34); pb.Text=preset[1]; pb.BackgroundColor3=Color3.fromRGB(90,0,160); pb.TextColor3=Color3.new(1,1,1); pb.Font=Enum.Font.GothamBold; pb.TextSize=13
    Instance.new("UICorner",pb).CornerRadius=UDim.new(0,8)
    local sub=Instance.new("TextLabel",pb); sub.Size=UDim2.new(1,0,0,12); sub.Position=UDim2.new(0,0,1,-13); sub.BackgroundTransparency=1; sub.Text=tostring(preset[2]); sub.Font=Enum.Font.Gotham; sub.TextSize=10; sub.TextColor3=Color3.fromRGB(180,130,255)
    pb.MouseButton1Click:Connect(function() click(); FlySpeedBox.Text=tostring(preset[2]); pb.BackgroundColor3=Color3.fromRGB(0,200,100); TweenService:Create(pb,TweenInfo.new(0.5),{BackgroundColor3=Color3.fromRGB(90,0,160)}):Play() end)
end

sectionLabel("── Infinite Jump",262)
local infiniteJump=false
local InfJumpBtn=moveBtn("Inf Jump: OFF",282)
InfJumpBtn.MouseButton1Click:Connect(function()
    click(); infiniteJump=not infiniteJump; InfJumpBtn.Text=infiniteJump and "Inf Jump: ON" or "Inf Jump: OFF"; InfJumpBtn.BackgroundColor3=infiniteJump and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["🦘 InfJump"]=infiniteJump; updateFooter()
    notify("Infinite Jump: "..(infiniteJump and "ON" or "OFF"),infiniteJump)
end)
UIS.JumpRequest:Connect(function()
    if infiniteJump and player.Character then local hum=player.Character:FindFirstChildOfClass("Humanoid"); if hum and hum:GetState()~=Enum.HumanoidStateType.Dead then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

sectionLabel("── Swim in Air",340)
local swimEnabled = false
local SwimBtn = moveBtn("Swim in Air: OFF", 358)
moveScroll.CanvasSize = UDim2.new(0,0,0,415)
SwimBtn.MouseButton1Click:Connect(function()
    click(); swimEnabled = not swimEnabled
    SwimBtn.Text = swimEnabled and "Swim in Air: ON" or "Swim in Air: OFF"
    SwimBtn.BackgroundColor3 = swimEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200)
    activeFeatures["Swim"] = swimEnabled; updateFooter()
    if not swimEnabled then
        workspace.Gravity = 196.2
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
    end
    notify("Swim in Air: "..(swimEnabled and "ON" or "OFF"), swimEnabled)
end)

--// [TP MODULE]
local savedPosition,autoReturn=nil,false; local clickTpEnabled=false
TPScroll=Instance.new("ScrollingFrame",TPPage); TPScroll.Size=UDim2.new(1,0,1,0); TPScroll.BackgroundTransparency=1; TPScroll.ScrollBarThickness=3; TPScroll.ScrollBarImageColor3=Color3.fromRGB(140,0,220); TPScroll.CanvasSize=UDim2.new(0,0,0,290)
local saveBtn=addBtn(TPScroll,"Save Position",0); local tpBtn=addBtn(TPScroll,"Teleport",55); local autoBtn=addBtn(TPScroll,"Auto-Return: OFF",110); local autoTimeBox=addBox(TPScroll,"Delay",110,"3.5")
autoTimeBox.Position=UDim2.new(0,190,0,0); autoTimeBox.Size=UDim2.new(0,80,0,45)
local clickTpBtn=addBtn(TPScroll,"Click TP: OFF",165)
saveBtn.MouseButton1Click:Connect(function() click(); if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then savedPosition=player.Character.HumanoidRootPart.CFrame; saveBtn.BackgroundColor3=Color3.fromRGB(0,255,120); TweenService:Create(saveBtn,TweenInfo.new(0.5),{BackgroundColor3=Color3.fromRGB(120,0,200)}):Play() end end)
tpBtn.MouseButton1Click:Connect(function() click(); if player.Character and savedPosition then player.Character.HumanoidRootPart.CFrame=savedPosition end end)
autoBtn.MouseButton1Click:Connect(function() click(); autoReturn=not autoReturn; autoBtn.Text=autoReturn and "Auto-Return: ON" or "Auto-Return: OFF"; autoBtn.BackgroundColor3=autoReturn and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["📍 Auto-Return"]=autoReturn; updateFooter() end)
clickTpBtn.MouseButton1Click:Connect(function() click(); clickTpEnabled=not clickTpEnabled; clickTpBtn.Text=clickTpEnabled and "Click TP: ON" or "Click TP: OFF"; clickTpBtn.BackgroundColor3=clickTpEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["📍 ClickTP"]=clickTpEnabled; updateFooter() end)
mouse.Button1Down:Connect(function() if clickTpEnabled and UIS:IsKeyDown(Enum.KeyCode.LeftControl) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then player.Character.HumanoidRootPart.CFrame=CFrame.new(mouse.Hit.p)+Vector3.new(0,3,0); playSound(12222242,0.4) end end)

tpSep2=Instance.new("Frame",TPScroll); tpSep2.Size=UDim2.new(1,-10,0,1); tpSep2.Position=UDim2.new(0,5,0,158); tpSep2.BackgroundColor3=Color3.fromRGB(130,0,200); tpSep2.BackgroundTransparency=0.4; tpSep2.BorderSizePixel=0
tpSep=Instance.new("Frame",TPScroll); tpSep.Size=UDim2.new(1,-10,0,1); tpSep.Position=UDim2.new(0,5,0,218); tpSep.BackgroundColor3=Color3.fromRGB(130,0,200); tpSep.BackgroundTransparency=0.4; tpSep.BorderSizePixel=0
lootTpNameBox=addBox(TPScroll,"Loot name",228,""); lootTpNameBox.Size=UDim2.new(0,95,0,40); lootTpNameBox.Position=UDim2.new(0,190,0,228)
lootTpBtn=addBtn(TPScroll,"Loot TP: OFF",228)

--// [PLAYERS TAB]
local function stopSpectate()
    if spectating then spectating=false; spectateTarget=nil; workspace.CurrentCamera.CameraType=Enum.CameraType.Custom; workspace.CurrentCamera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") or nil; activeFeatures["👁 Spec"]=false; updateFooter() end
end
local PlayerScroll=Instance.new("ScrollingFrame",PlayersPage); PlayerScroll.Size=UDim2.new(1,0,1,0); PlayerScroll.BackgroundTransparency=1; PlayerScroll.CanvasSize=UDim2.new(0,0,0,0); PlayerScroll.ScrollBarThickness=2
local UIList=Instance.new("UIListLayout",PlayerScroll); UIList.Padding=UDim.new(0,5)
local function refreshPlayers()
    for _,v in pairs(PlayerScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for _,p in pairs(Players:GetPlayers()) do if p~=player then
        local row=Instance.new("Frame",PlayerScroll); row.Size=UDim2.new(1,-5,0,42); row.BackgroundTransparency=1
        local avatarFrame=Instance.new("Frame",row); avatarFrame.Size=UDim2.new(0,36,0,36); avatarFrame.Position=UDim2.new(0,0,0.5,-18); avatarFrame.BackgroundColor3=Color3.fromRGB(50,0,80); avatarFrame.BorderSizePixel=0
        Instance.new("UICorner",avatarFrame).CornerRadius=UDim.new(0,6); local avatarStroke=Instance.new("UIStroke",avatarFrame); avatarStroke.Color=Color3.fromRGB(140,0,220); avatarStroke.Thickness=1
        local avatarImg=Instance.new("ImageLabel",avatarFrame); avatarImg.Size=UDim2.new(1,0,1,0); avatarImg.BackgroundTransparency=1; avatarImg.ScaleType=Enum.ScaleType.Crop; Instance.new("UICorner",avatarImg).CornerRadius=UDim.new(0,5)
        task.spawn(function() local ok,img=pcall(function() return Players:GetUserThumbnailAsync(p.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end); if ok and avatarImg and avatarImg.Parent then avatarImg.Image=img end end)
        local nameBtn=Instance.new("TextButton",row); nameBtn.Size=UDim2.new(1,-120,1,0); nameBtn.Position=UDim2.new(0,42,0,0); nameBtn.BackgroundColor3=Color3.fromRGB(60,0,100); nameBtn.Text=p.DisplayName; nameBtn.TextColor3=Color3.new(1,1,1); nameBtn.Font=Enum.Font.GothamBold; nameBtn.TextSize=13; Instance.new("UICorner",nameBtn).CornerRadius=UDim.new(0,8)
        nameBtn.MouseButton1Click:Connect(function() click(); stopSpectate(); if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then player.Character.HumanoidRootPart.CFrame=p.Character.HumanoidRootPart.CFrame end end)
        local specBtn=Instance.new("TextButton",row); specBtn.Size=UDim2.new(0,72,1,0); specBtn.Position=UDim2.new(1,-72,0,0); specBtn.BackgroundColor3=Color3.fromRGB(90,0,160); specBtn.Text="👁 Spec"; specBtn.TextColor3=Color3.new(1,1,1); specBtn.Font=Enum.Font.GothamBold; specBtn.TextSize=12; Instance.new("UICorner",specBtn).CornerRadius=UDim.new(0,8)
        specBtn.MouseButton1Click:Connect(function()
            click(); if spectating and spectateTarget==p then stopSpectate(); specBtn.BackgroundColor3=Color3.fromRGB(90,0,160); notify("Spectate: OFF",false)
            else stopSpectate(); spectating=true; spectateTarget=p; workspace.CurrentCamera.CameraType=Enum.CameraType.Custom; activeFeatures["👁 Spec"]=true; updateFooter(); specBtn.BackgroundColor3=Color3.fromRGB(0,200,100); notify("Spectating: "..p.DisplayName,true) end
        end)
    end end
    PlayerScroll.CanvasSize=UDim2.new(0,0,0,UIList.AbsoluteContentSize.Y)
end
task.spawn(function() while task.wait(5) do if PlayersPage.Visible then refreshPlayers() end end end)
connections.spectate=RunService.RenderStepped:Connect(function()
    if not spectating or not spectateTarget then return end
    local char=spectateTarget.Character; if char then local hum=char:FindFirstChildOfClass("Humanoid"); local hrp=char:FindFirstChild("HumanoidRootPart"); if hum then workspace.CurrentCamera.CameraSubject=hum elseif hrp then workspace.CurrentCamera.CameraSubject=hrp end end
end)

--// [TROLL MODULE]
local TrollScroll=Instance.new("ScrollingFrame",TrollPage); TrollScroll.Size=UDim2.new(1,0,1,0); TrollScroll.BackgroundTransparency=1; TrollScroll.ScrollBarThickness=3; TrollScroll.ScrollBarImageColor3=Color3.fromRGB(140,0,220); TrollScroll.CanvasSize=UDim2.new(0,0,0,330)
local function trollBtn(text,y) local btn=Instance.new("TextButton",TrollScroll); btn.Size=UDim2.new(0,180,0,45); btn.Position=UDim2.new(0,0,0,y); btn.Text=text; btn.BackgroundColor3=Color3.fromRGB(120,0,200); btn.TextColor3=Color3.new(1,1,1); btn.Font=Enum.Font.GothamBold; btn.TextSize=18; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10); return btn end
local function trollBox(ph,y,def) local box=Instance.new("TextBox",TrollScroll); box.Size=UDim2.new(0,180,0,45); box.Position=UDim2.new(0,0,0,y); box.PlaceholderText=ph; box.Text=def or ""; box.BackgroundColor3=Color3.fromRGB(60,0,100); box.TextColor3=Color3.new(1,1,1); box.Font=Enum.Font.GothamBold; box.TextSize=16; Instance.new("UICorner",box).CornerRadius=UDim.new(0,10); return box end

local FBtn=trollBtn("Fling: OFF",0); local FPower=trollBox("Power",0,"10000"); FPower.Position=UDim2.new(0,190,0,0); FPower.Size=UDim2.new(0,80,0,45)
FBtn.MouseButton1Click:Connect(function()
    click(); spinning=not spinning; FBtn.Text=spinning and "Fling: ON" or "Fling: OFF"; FBtn.BackgroundColor3=spinning and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["🌀 Fling"]=spinning; updateFooter()
    if not spinning and player.Character then local hrp=player.Character:FindFirstChild("HumanoidRootPart"); local hum=player.Character:FindFirstChildOfClass("Humanoid"); if hrp then hrp.Velocity=Vector3.zero; hrp.RotVelocity=Vector3.zero; if hrp:FindFirstChild("FlingVel") then hrp.FlingVel:Destroy() end end; if hum then hum.PlatformStand=false; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end end
end)

local OrbitBtn=trollBtn("Orbit: OFF",55); local OrbitTargetBox=trollBox("Target name",55,""); OrbitTargetBox.Position=UDim2.new(0,190,0,55); OrbitTargetBox.Size=UDim2.new(0,80,0,45); OrbitTargetBox.TextSize=11; OrbitTargetBox.PlaceholderText="Target"
OrbitBtn.MouseButton1Click:Connect(function()
    click(); local targetName=OrbitTargetBox.Text; local found=nil
    for _,p in pairs(Players:GetPlayers()) do if p~=player and p.Name:lower():find(targetName:lower()) then found=p; break end end
    if not orbiting and not found then notify("Orbit: Player not found!",false); return end
    orbiting=not orbiting; orbitTarget=orbiting and found or nil; OrbitBtn.Text=orbiting and "Orbit: ON" or "Orbit: OFF"; OrbitBtn.BackgroundColor3=orbiting and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["🌐 Orbit"]=orbiting; updateFooter()
    notify("Orbit: "..(orbiting and ("ON → "..(found and found.DisplayName or "?")) or "OFF"),orbiting)
end)

local trollSep=Instance.new("Frame",TrollScroll); trollSep.Size=UDim2.new(1,-10,0,1); trollSep.Position=UDim2.new(0,5,0,107); trollSep.BackgroundColor3=Color3.fromRGB(130,0,200); trollSep.BackgroundTransparency=0.4; trollSep.BorderSizePixel=0
ChatMsgBox=trollBox("Spam message",110,""); local ChatSpamBtn=trollBtn("Chat Spam: OFF",160); local ChatDelayBox=trollBox("Delay(s)",160,"0.5"); ChatDelayBox.Position=UDim2.new(0,190,0,110); ChatDelayBox.Size=UDim2.new(0,75,0,38)
ChatSpamBtn.MouseButton1Click:Connect(function()
    click(); if not chatSpamming and (ChatMsgBox.Text=="" or ChatMsgBox.Text==nil) then notify("Chat Spam: Enter a message first!",false); return end
    chatSpamming=not chatSpamming; ChatSpamBtn.Text=chatSpamming and "Chat Spam: ON" or "Chat Spam: OFF"; ChatSpamBtn.BackgroundColor3=chatSpamming and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["💬 Spam"]=chatSpamming; updateFooter()
    notify("Chat Spam: "..(chatSpamming and "ON" or "OFF"),chatSpamming)
    if chatSpamming then
        task.spawn(function()
            while chatSpamming and not closed do
                local msg=ChatMsgBox.Text
                if msg and msg~="" then
                    local tcs=game:GetService("TextChatService"); local sent=false
                    if tcs and tcs.TextChannels then local general=tcs.TextChannels:FindFirstChild("RBXGeneral"); if general then pcall(function() general:SendAsync(msg) end); sent=true end end
                    if not sent then local chatEvents=game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents"); if chatEvents then local sayMsg=chatEvents:FindFirstChild("SayMessageRequest"); if sayMsg then pcall(function() sayMsg:FireServer(msg,"All") end) end end end
                end
                local delay=tonumber(ChatDelayBox.Text) or 0.5; task.wait(math.max(delay,0.2))
            end
        end)
    end
end)

trollSep2=Instance.new("Frame",TrollScroll); trollSep2.Size=UDim2.new(1,-10,0,1); trollSep2.Position=UDim2.new(0,5,0,212); trollSep2.BackgroundColor3=Color3.fromRGB(130,0,200); trollSep2.BackgroundTransparency=0.4; trollSep2.BorderSizePixel=0
local followTarget=nil; local FollowTargetBox=trollBox("Target name",215,""); FollowTargetBox.Size=UDim2.new(0,80,0,40); FollowTargetBox.Position=UDim2.new(0,190,0,215); FollowTargetBox.TextSize=11; FollowTargetBox.PlaceholderText="Target"
local FollowBtn=trollBtn("Follow: OFF",215)
FollowBtn.MouseButton1Click:Connect(function()
    click(); local targetName=FollowTargetBox.Text; local found=nil
    for _,p in pairs(Players:GetPlayers()) do if p~=player and p.Name:lower():find(targetName:lower()) then found=p; break end end
    if not freezeEnabled and not found then notify("Follow: Player not found!",false); return end
    freezeEnabled=not freezeEnabled; followTarget=freezeEnabled and found or nil; FollowBtn.Text=freezeEnabled and "Follow: ON" or "Follow: OFF"; FollowBtn.BackgroundColor3=freezeEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["👣 Follow"]=freezeEnabled; updateFooter()
    notify("Follow: "..(freezeEnabled and ("ON → "..(found and found.DisplayName or "?")) or "OFF"),freezeEnabled)
end)
task.spawn(function()
    while not closed do task.wait(0.05)
        if freezeEnabled and followTarget and followTarget.Character and player.Character then
            local tHRP=followTarget.Character:FindFirstChild("HumanoidRootPart"); local myHRP=player.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and myHRP then myHRP.CFrame=tHRP.CFrame*CFrame.new(0,0,2) end
        end
    end
end)

--// [VISUALS]
local function createESP(p)
    if p==player then return end
    task.spawn(function()
        local char=p.Character or p.CharacterAdded:Wait(); local hrp=char:WaitForChild("HumanoidRootPart",5); if not hrp then return end
        if char:FindFirstChild("FinestESP") then return end
        local h=Instance.new("Highlight",char); h.Name="FinestESP"; h.FillColor=espColor; h.OutlineColor=Color3.new(1,1,1); h.FillTransparency=0.5
        local b=Instance.new("BillboardGui",char); b.Name="FinestName"; b.Size=UDim2.new(0,200,0,50); b.Adornee=hrp; b.AlwaysOnTop=true; b.ExtentsOffset=Vector3.new(0,3,0)
        local t=Instance.new("TextLabel",b); t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1; t.Text=p.DisplayName; t.TextColor3=Color3.fromRGB(190,100,255); t.Font=Enum.Font.GothamBold; t.TextSize=14
    end)
end
local applyHealthBar; local applySkeletonESP
task.spawn(function()
    while not closed do task.wait(0.5)
        for _,p in pairs(Players:GetPlayers()) do
            if p==player then continue end; local char=p.Character; if not char then continue end
            local hrp=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid"); if not hrp or not hum then continue end
            if hum.Health<=0 then continue end
            if espEnabled and not char:FindFirstChild("FinestESP") then
                local h=Instance.new("Highlight",char); h.Name="FinestESP"; h.FillColor=espColor; h.OutlineColor=Color3.new(1,1,1); h.FillTransparency=0.5
                local b=Instance.new("BillboardGui",char); b.Name="FinestName"; b.Size=UDim2.new(0,200,0,50); b.Adornee=hrp; b.AlwaysOnTop=true; b.ExtentsOffset=Vector3.new(0,3,0)
                local t=Instance.new("TextLabel",b); t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1; t.Text=p.DisplayName; t.TextColor3=Color3.fromRGB(190,100,255); t.Font=Enum.Font.GothamBold; t.TextSize=14
            end
            if healthBarEnabled and not char:FindFirstChild("FinestHealthBar") then applyHealthBar(char) end
            if skeletonEnabled and not char:FindFirstChild("FinestSkeleton") then applySkeletonESP(p) end
        end
    end
end)
local function removeESP() for _,v in pairs(Players:GetPlayers()) do if v.Character then if v.Character:FindFirstChild("FinestESP") then v.Character.FinestESP:Destroy() end; if v.Character:FindFirstChild("FinestName") then v.Character.FinestName:Destroy() end end end end

local EspBtn=addBtn(VisualPage,"ESP: OFF",0,"[E]")
local espSubData={{label="❤ Health",x=0},{label="💀 Skeleton",x=63},{label="🌑 Night",x=126}}
local espSubBtns={}
for _,d in ipairs(espSubData) do
    local sb=Instance.new("TextButton",VisualPage); sb.Size=UDim2.new(0,58,0,22); sb.Position=UDim2.new(0,d.x,0,50); sb.Text=d.label; sb.BackgroundColor3=Color3.fromRGB(55,0,90); sb.TextColor3=Color3.fromRGB(180,130,255); sb.Font=Enum.Font.GothamBold; sb.TextSize=10; sb.AutoButtonColor=false
    Instance.new("UICorner",sb).CornerRadius=UDim.new(0,6); local ss=Instance.new("UIStroke",sb); ss.Color=Color3.fromRGB(110,0,180); ss.Thickness=1; table.insert(espSubBtns,sb)
end
local function setSubBtn(btn,on) TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(0,160,80) or Color3.fromRGB(55,0,90),TextColor3=on and Color3.fromRGB(200,255,220) or Color3.fromRGB(180,130,255)}):Play() end

local espColorData={{Color3.fromRGB(170,0,255)},{Color3.fromRGB(255,30,30)},{Color3.fromRGB(0,120,255)},{Color3.fromRGB(0,220,80)},{Color3.fromRGB(255,140,0)}}
local espColorBtns={}
local function updateColorBtns(activeIndex) for i,v in ipairs(espColorBtns) do v.btn.Text=i==activeIndex and "●" or "○"; v.btn.TextColor3=i==activeIndex and Color3.new(1,1,1) or Color3.fromRGB(180,180,180); v.btn.TextSize=i==activeIndex and 16 or 13 end end
for i,cd in ipairs(espColorData) do
    local cb=Instance.new("TextButton",VisualPage); cb.Size=UDim2.new(0,34,0,22); cb.Position=UDim2.new(0,(i-1)*37,0,78); cb.Text="○"; cb.BackgroundColor3=cd[1]; cb.TextColor3=Color3.fromRGB(180,180,180); cb.Font=Enum.Font.GothamBold; cb.TextSize=13; cb.AutoButtonColor=false
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,6); table.insert(espColorBtns,{btn=cb,color=cd[1]})
    local idx=i; cb.MouseButton1Click:Connect(function() click(); espColor=cd[1]; updateColorBtns(idx); for _,p in pairs(Players:GetPlayers()) do if p.Character then local h=p.Character:FindFirstChild("FinestESP"); if h then h.FillColor=espColor end end end end)
end
updateColorBtns(1)

applyHealthBar=function(char)
    if char:FindFirstChild("FinestHealthBar") then return end; local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end; local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local hbGui=Instance.new("BillboardGui",char); hbGui.Name="FinestHealthBar"; hbGui.Adornee=hrp; hbGui.AlwaysOnTop=true; hbGui.Size=UDim2.new(0,4,0,4); hbGui.StudsOffset=Vector3.new(0,3.2,0)
    local container=Instance.new("Frame",hbGui); container.Size=UDim2.new(0,60,0,7); container.Position=UDim2.new(0.5,-30,0.5,-3); container.BackgroundColor3=Color3.fromRGB(40,0,0); container.BorderSizePixel=0; Instance.new("UICorner",container).CornerRadius=UDim.new(1,0)
    local bar=Instance.new("Frame",container); bar.Size=UDim2.new(math.clamp(hum.Health/hum.MaxHealth,0,1),0,1,0); bar.BackgroundColor3=Color3.fromRGB(0,220,80); bar.BorderSizePixel=0; Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)
    local conn; conn=RunService.RenderStepped:Connect(function()
        if not hbGui or not hbGui.Parent or not hum or not hum.Parent then conn:Disconnect(); return end
        local pct=math.clamp(hum.Health/hum.MaxHealth,0,1); bar.Size=UDim2.new(pct,0,1,0); bar.BackgroundColor3=pct>0.5 and Color3.fromRGB(0,220,80) or pct>0.25 and Color3.fromRGB(255,180,0) or Color3.fromRGB(220,0,0)
    end)
end

local skeletonBones={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"}}
applySkeletonESP=function(p)
    if not p.Character then return end; local char=p.Character; if char:FindFirstChild("FinestSkeleton") then return end
    local container=Instance.new("Folder",char); container.Name="FinestSkeleton"
    task.spawn(function()
        while skeletonEnabled and container and container.Parent do
            for _,bone in ipairs(skeletonBones) do
                local a=char:FindFirstChild(bone[1]); local b=char:FindFirstChild(bone[2])
                if a and b then local boneName=bone[1]..bone[2]; if not container:FindFirstChild(boneName) then local boneGui=Instance.new("BillboardGui",container); boneGui.Name=boneName; boneGui.Adornee=a; boneGui.AlwaysOnTop=true; boneGui.Size=UDim2.new(0,4,0,4); local dot=Instance.new("Frame",boneGui); dot.Size=UDim2.new(1,0,1,0); dot.BackgroundColor3=Color3.fromRGB(170,0,255); dot.BorderSizePixel=0; Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0) end end
            end
            task.wait(0.05)
        end
        if container and container.Parent then container:Destroy() end
    end)
end

local function applyNightMode(on)
    if on then
        if not Lighting:FindFirstChild("FinestNight") then local cc=Instance.new("ColorCorrectionEffect",Lighting); cc.Name="FinestNight"; cc.Brightness=-0.4; cc.Contrast=0.2; cc.Saturation=-0.3 end
        Lighting.Ambient=Color3.fromRGB(0,0,0); Lighting.OutdoorAmbient=Color3.fromRGB(10,0,20)
    else local existing=Lighting:FindFirstChild("FinestNight"); if existing then existing:Destroy() end; Lighting.Ambient=origAmbient; Lighting.OutdoorAmbient=origOutdoor end
end

espSubBtns[1].MouseButton1Click:Connect(function() click(); healthBarEnabled=not healthBarEnabled; setSubBtn(espSubBtns[1],healthBarEnabled); if healthBarEnabled then for _,p in pairs(Players:GetPlayers()) do if p~=player and p.Character then task.spawn(function() applyHealthBar(p.Character) end) end end else for _,p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("FinestHealthBar") then p.Character.FinestHealthBar:Destroy() end end end; notify("Health Bars: "..(healthBarEnabled and "ON" or "OFF"),healthBarEnabled) end)
espSubBtns[2].MouseButton1Click:Connect(function() click(); skeletonEnabled=not skeletonEnabled; setSubBtn(espSubBtns[2],skeletonEnabled); if skeletonEnabled then for _,p in pairs(Players:GetPlayers()) do if p~=player then task.spawn(function() applySkeletonESP(p) end) end end else for _,p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("FinestSkeleton") then p.Character.FinestSkeleton:Destroy() end end end; notify("Skeleton ESP: "..(skeletonEnabled and "ON" or "OFF"),skeletonEnabled) end)
espSubBtns[3].MouseButton1Click:Connect(function() click(); nightModeEnabled=not nightModeEnabled; setSubBtn(espSubBtns[3],nightModeEnabled); applyNightMode(nightModeEnabled); notify("Night Mode: "..(nightModeEnabled and "ON" or "OFF"),nightModeEnabled) end)
EspBtn.MouseButton1Click:Connect(function()
    click(); espEnabled=not espEnabled; EspBtn.Text=espEnabled and "ESP: ON" or "ESP: OFF"; EspBtn.BackgroundColor3=espEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["👁 ESP"]=espEnabled; updateFooter()
    if espEnabled then task.spawn(function() for _,p in pairs(Players:GetPlayers()) do createESP(p) end end) else removeESP() end
end)

--// [MASTER LOOP]
connections.renderStepped=RunService.RenderStepped:Connect(function()
    local char=player.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp=char.HumanoidRootPart; local hum=char:FindFirstChildOfClass("Humanoid")
    if spinning then
        local s=tonumber(FPower.Text) or 10000
        for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end
        hum.PlatformStand=true; hrp.Velocity=Vector3.new(0,0.4,0); hrp.RotVelocity=Vector3.new(0,s,0)
        local bodyVel=hrp:FindFirstChild("FlingVel") or Instance.new("BodyVelocity",hrp); bodyVel.Name="FlingVel"; bodyVel.MaxForce=Vector3.new(math.huge,0,math.huge); bodyVel.Velocity=hrp.CFrame.LookVector*0.1
    end
    if flying and bv and bg then
        local cam=workspace.CurrentCamera; local direction=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction+=cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction-=cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction-=cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction+=cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction+=Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction-=Vector3.new(0,1,0) end
        bv.Velocity=(direction.Magnitude>0) and (direction.Unit*(tonumber(FlySpeedBox.Text) or 70)) or Vector3.zero; bg.CFrame=cam.CFrame
    end
    if ghostEnabled and not spinning then for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end
    if swimEnabled then
        workspace.Gravity = 5
        -- force swim animation state
        hum:ChangeState(Enum.HumanoidStateType.Swimming)
        local cam = workspace.CurrentCamera; local swimDir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then swimDir = swimDir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then swimDir = swimDir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then swimDir = swimDir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then swimDir = swimDir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then swimDir = swimDir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then swimDir = swimDir - Vector3.new(0,1,0) end
        if swimDir.Magnitude > 0 then hrp.Velocity = swimDir.Unit * 20
        else hrp.Velocity = hrp.Velocity * 0.85 end
    end
    if orbiting and orbitTarget and orbitTarget.Character and orbitTarget.Character:FindFirstChild("HumanoidRootPart") then
        local targetHRP=orbitTarget.Character.HumanoidRootPart; orbitAngle=orbitAngle+0.03; local radius=8
        local ox=targetHRP.Position.X+math.cos(orbitAngle)*radius; local oz=targetHRP.Position.Z+math.sin(orbitAngle)*radius; local oy=targetHRP.Position.Y
        hrp.CFrame=CFrame.new(Vector3.new(ox,oy,oz),targetHRP.Position)
    end
end)

task.spawn(function()
    while true do local delayTime=tonumber(autoTimeBox.Text) or 3.5; task.wait(delayTime); if autoReturn and savedPosition and player.Character then local hrp=player.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame=savedPosition end end end
end)

--// [FPS TAB]
local TriggerBtn=addBtn(FPSPage,"Triggerbot: OFF",0,"[T]")
TriggerBtn.MouseButton1Click:Connect(function() click(); triggerbotEnabled=not triggerbotEnabled; TriggerBtn.Text=triggerbotEnabled and "Triggerbot: ON" or "Triggerbot: OFF"; TriggerBtn.BackgroundColor3=triggerbotEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["🎯 Trigger"]=triggerbotEnabled; updateFooter() end)
task.spawn(function()
    while task.wait() do
        if triggerbotEnabled and mouse.Target then local t=mouse.Target; local c=(t.Parent:FindFirstChildOfClass("Humanoid") and t.Parent) or (t.Parent.Parent:FindFirstChildOfClass("Humanoid") and t.Parent.Parent); if c and c~=player.Character and c:FindFirstChildOfClass("Humanoid").Health>0 then mouse1click() end end
    end
end)

local AimbotBtn=addBtn(FPSPage,"Aimbot: OFF",55); AimbotBtn.TextSize=14
local AimbotSensBox=addBox(FPSPage,"Sens",55,"0.3"); AimbotSensBox.Position=UDim2.new(0,190,0,55); AimbotSensBox.Size=UDim2.new(0,80,0,45)

local crosshairEnabled=false
local CrosshairGui=Instance.new("ScreenGui",game.CoreGui); CrosshairGui.Name="FinestCrosshair"; CrosshairGui.ResetOnSpawn=false; CrosshairGui.IgnoreGuiInset=true
local CHContainer=Instance.new("Frame",CrosshairGui); CHContainer.BackgroundTransparency=1; CHContainer.Size=UDim2.new(0,40,0,40); CHContainer.AnchorPoint=Vector2.new(0.5,0.5); CHContainer.Position=UDim2.new(0.5,0,0.5,0); CHContainer.Visible=false
local chDot=Instance.new("Frame",CHContainer); chDot.Size=UDim2.new(0,4,0,4); chDot.AnchorPoint=Vector2.new(0.5,0.5); chDot.Position=UDim2.new(0.5,0,0.5,0); chDot.BackgroundColor3=Color3.fromRGB(0,255,120); chDot.BorderSizePixel=0; Instance.new("UICorner",chDot).CornerRadius=UDim.new(1,0)
local chLines={}; local lineData={{size=UDim2.new(0,2,0,8),pos=UDim2.new(0.5,-1,0,2)},{size=UDim2.new(0,2,0,8),pos=UDim2.new(0.5,-1,1,-10)},{size=UDim2.new(0,8,0,2),pos=UDim2.new(0,2,0.5,-1)},{size=UDim2.new(0,8,0,2),pos=UDim2.new(1,-10,0.5,-1)}}
for _,ld in ipairs(lineData) do local ln=Instance.new("Frame",CHContainer); ln.Size=ld.size; ln.Position=ld.pos; ln.BackgroundColor3=Color3.fromRGB(0,255,120); ln.BorderSizePixel=0; Instance.new("UICorner",ln).CornerRadius=UDim.new(0,1); table.insert(chLines,ln) end

local CrosshairBtn=addBtn(FPSPage,"Crosshair: OFF",110); CrosshairBtn.TextSize=15
local chColorData={{Color3.fromRGB(0,255,120),"Green"},{Color3.fromRGB(255,255,255),"White"},{Color3.fromRGB(255,50,50),"Red"},{Color3.fromRGB(0,180,255),"Blue"},{Color3.fromRGB(255,200,0),"Yellow"}}
local chColorBtns={}
for i,cd in ipairs(chColorData) do
    local cb=Instance.new("TextButton",FPSPage); cb.Size=UDim2.new(0,30,0,18); cb.Position=UDim2.new(0,(i-1)*34,0,162); cb.Text=""; cb.BackgroundColor3=cd[1]; cb.AutoButtonColor=false
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4); local selStroke=Instance.new("UIStroke",cb); selStroke.Color=Color3.new(1,1,1); selStroke.Thickness=0; table.insert(chColorBtns,{btn=cb,stroke=selStroke,color=cd[1]})
    cb.MouseButton1Click:Connect(function() click(); local col=cd[1]; chDot.BackgroundColor3=col; for _,ln in ipairs(chLines) do ln.BackgroundColor3=col end; for _,v in ipairs(chColorBtns) do v.stroke.Thickness=0 end; selStroke.Thickness=2 end)
end
chColorBtns[1].stroke.Thickness=2
CrosshairBtn.MouseButton1Click:Connect(function() click(); crosshairEnabled=not crosshairEnabled; CrosshairBtn.Text=crosshairEnabled and "Crosshair: ON" or "Crosshair: OFF"; CrosshairBtn.BackgroundColor3=crosshairEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); CHContainer.Visible=crosshairEnabled; activeFeatures["➕ CH"]=crosshairEnabled; updateFooter(); notify("Crosshair: "..(crosshairEnabled and "ON" or "OFF"),crosshairEnabled) end)

local fovCircleGui=Instance.new("ScreenGui",game.CoreGui); fovCircleGui.Name="FinestFOVCircle"; fovCircleGui.ResetOnSpawn=false; fovCircleGui.IgnoreGuiInset=true
local fovCircleFrame=Instance.new("Frame",fovCircleGui); fovCircleFrame.BackgroundTransparency=1; fovCircleFrame.AnchorPoint=Vector2.new(0.5,0.5); fovCircleFrame.Position=UDim2.new(0.5,0,0.5,0); fovCircleFrame.Visible=false
local aimbotFovRadius=120; fovCircleFrame.Size=UDim2.new(0,aimbotFovRadius*2,0,aimbotFovRadius*2)
local circleSegments=64; local circleFrames={}
for i=1,circleSegments do
    local seg=Instance.new("Frame",fovCircleFrame); seg.Size=UDim2.new(0,3,0,3); seg.BackgroundColor3=Color3.fromRGB(200,100,255); seg.BackgroundTransparency=0.3; seg.BorderSizePixel=0; seg.AnchorPoint=Vector2.new(0.5,0.5)
    Instance.new("UICorner",seg).CornerRadius=UDim.new(1,0); local angle=(i/circleSegments)*math.pi*2; seg.Position=UDim2.new(0.5+math.cos(angle)*0.5,0,0.5+math.sin(angle)*0.5,0); table.insert(circleFrames,seg)
end

local fovCircleLabel=Instance.new("TextLabel",FPSPage); fovCircleLabel.Size=UDim2.new(0,180,0,16); fovCircleLabel.Position=UDim2.new(0,0,0,185); fovCircleLabel.BackgroundTransparency=1; fovCircleLabel.Text="Aimbot FOV Radius: 120px"; fovCircleLabel.Font=Enum.Font.Gotham; fovCircleLabel.TextSize=11; fovCircleLabel.TextColor3=Color3.fromRGB(170,120,255); fovCircleLabel.TextXAlignment=Enum.TextXAlignment.Left
local fovRadiusMinus=Instance.new("TextButton",FPSPage); fovRadiusMinus.Size=UDim2.new(0,28,0,22); fovRadiusMinus.Position=UDim2.new(0,0,0,205); fovRadiusMinus.Text="−"; fovRadiusMinus.BackgroundColor3=Color3.fromRGB(80,0,140); fovRadiusMinus.TextColor3=Color3.new(1,1,1); fovRadiusMinus.Font=Enum.Font.GothamBold; fovRadiusMinus.TextSize=16; Instance.new("UICorner",fovRadiusMinus).CornerRadius=UDim.new(0,6)
local fovRadiusPlus=Instance.new("TextButton",FPSPage); fovRadiusPlus.Size=UDim2.new(0,28,0,22); fovRadiusPlus.Position=UDim2.new(0,32,0,205); fovRadiusPlus.Text="+"; fovRadiusPlus.BackgroundColor3=Color3.fromRGB(80,0,140); fovRadiusPlus.TextColor3=Color3.new(1,1,1); fovRadiusPlus.Font=Enum.Font.GothamBold; fovRadiusPlus.TextSize=16; Instance.new("UICorner",fovRadiusPlus).CornerRadius=UDim.new(0,6)
local function setFovRadius(r) aimbotFovRadius=math.clamp(r,30,400); fovCircleFrame.Size=UDim2.new(0,aimbotFovRadius*2,0,aimbotFovRadius*2); fovCircleLabel.Text="Aimbot FOV Radius: "..aimbotFovRadius.."px" end
fovRadiusMinus.MouseButton1Click:Connect(function() click(); setFovRadius(aimbotFovRadius-10) end)
fovRadiusPlus.MouseButton1Click:Connect(function() click(); setFovRadius(aimbotFovRadius+10) end)

local altHeld=false
connections.m2Began=UIS.InputBegan:Connect(function(input,processed) if input.UserInputType==Enum.UserInputType.MouseButton2 then altHeld=true end end)
connections.m2Ended=UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton2 then altHeld=false end end)

AimbotBtn.MouseButton1Click:Connect(function()
    click(); aimbotEnabled=not aimbotEnabled; AimbotBtn.Text=aimbotEnabled and "Aimbot: ON (Hold M2)" or "Aimbot: OFF"; AimbotBtn.BackgroundColor3=aimbotEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); fovCircleFrame.Visible=aimbotEnabled; activeFeatures["🎯 Aimbot"]=aimbotEnabled; updateFooter()
    notify("Aimbot: "..(aimbotEnabled and "ON — Hold Mouse2" or "OFF"),aimbotEnabled)
end)

task.spawn(function()
    while task.wait() do
        if not aimbotEnabled or not altHeld or not player.Character then continue end
        local cam=workspace.CurrentCamera; local closestPlayer=nil; local closestDist=math.huge
        for _,p in pairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local head=p.Character:FindFirstChild("Head"); local hum=p.Character:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health>0 then
                    local screenPos,onScreen=cam:WorldToScreenPoint(head.Position)
                    if onScreen then local center=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2); local dist=(Vector2.new(screenPos.X,screenPos.Y)-center).Magnitude; if dist<aimbotFovRadius and dist<closestDist then closestDist=dist; closestPlayer=p end end
                end
            end
        end
        if closestPlayer and closestPlayer.Character then local head=closestPlayer.Character:FindFirstChild("Head"); if head then local sens=tonumber(AimbotSensBox.Text) or 0.3; cam.CFrame=cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position,head.Position),math.clamp(sens,0.01,1)) end end
    end
end)

connections.inputBegan=UIS.InputBegan:Connect(function(input,processed)
    if processed then return end; if listeningFor then return end
    if input.KeyCode==keybinds["Menu"] then
        menuSound(); Main.Visible=not Main.Visible; WFrame.Visible=Main.Visible; FooterGui.Enabled=Main.Visible
    end
    if input.KeyCode==keybinds["Trigger"] then triggerbotEnabled=not triggerbotEnabled; TriggerBtn.Text=triggerbotEnabled and "Triggerbot: ON" or "Triggerbot: OFF"; TriggerBtn.BackgroundColor3=triggerbotEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["🎯 Trigger"]=triggerbotEnabled; updateFooter(); click(); notify("Triggerbot: "..(triggerbotEnabled and "ON" or "OFF"),triggerbotEnabled) end
    if input.KeyCode==keybinds["Fly"] then
        flying=not flying; FlyBtn.Text=flying and "Toggle Fly: ON" or "Toggle Fly: OFF"; FlyBtn.BackgroundColor3=flying and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["🕊 Fly"]=flying; updateFooter()
        local hrp=player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if flying and hrp then bv=Instance.new("BodyVelocity",hrp); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bg=Instance.new("BodyGyro",hrp); bg.MaxTorque=Vector3.new(1e9,1e9,1e9) else if bv then bv:Destroy() end; if bg then bg:Destroy() end end
        click(); notify("Fly: "..(flying and "ON" or "OFF"),flying)
    end
    if input.KeyCode==keybinds["ESP"] then
        espEnabled=not espEnabled; EspBtn.Text=espEnabled and "ESP: ON" or "ESP: OFF"; EspBtn.BackgroundColor3=espEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["👁 ESP"]=espEnabled; updateFooter()
        if espEnabled then task.spawn(function() for _,p in pairs(Players:GetPlayers()) do createESP(p) end end) else removeESP() end
        click(); notify("ESP: "..(espEnabled and "ON" or "OFF"),espEnabled)
    end
    if input.KeyCode==keybinds["Ghost"] then ghostEnabled=not ghostEnabled; ghostBtn.Text=ghostEnabled and "Ghost: ON" or "Ghost: OFF"; ghostBtn.BackgroundColor3=ghostEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200); activeFeatures["👻 Ghost"]=ghostEnabled; updateFooter(); click(); notify("Ghost: "..(ghostEnabled and "ON" or "OFF"),ghostEnabled) end
end)

--// [SETTINGS TAB]
local settingsScroll=Instance.new("ScrollingFrame",SettingsPage); settingsScroll.Size=UDim2.new(1,0,1,0); settingsScroll.BackgroundTransparency=1; settingsScroll.ScrollBarThickness=3; settingsScroll.ScrollBarImageColor3=Color3.fromRGB(140,0,220); settingsScroll.CanvasSize=UDim2.new(0,0,0,310)
local settingsHeader=Instance.new("TextLabel",settingsScroll); settingsHeader.Size=UDim2.new(1,0,0,22); settingsHeader.Position=UDim2.new(0,0,0,0); settingsHeader.BackgroundTransparency=1; settingsHeader.Text="⌨  Keybind Remapper"; settingsHeader.Font=Enum.Font.GothamBold; settingsHeader.TextSize=13; settingsHeader.TextColor3=Color3.fromRGB(200,150,255); settingsHeader.TextXAlignment=Enum.TextXAlignment.Left

local bindSlots={}; local featureOrder={"Menu","Fly","Ghost","ESP","Trigger"}
for idx,feat in ipairs(featureOrder) do
    local y=28+(idx-1)*52
    local lbl=Instance.new("TextLabel",settingsScroll); lbl.Size=UDim2.new(0,90,0,20); lbl.Position=UDim2.new(0,0,0,y); lbl.BackgroundTransparency=1; lbl.Text=feat; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextColor3=Color3.fromRGB(210,170,255); lbl.TextXAlignment=Enum.TextXAlignment.Left
    local keyBtn=Instance.new("TextButton",settingsScroll); keyBtn.Size=UDim2.new(0,120,0,28); keyBtn.Position=UDim2.new(0,95,0,y-4); keyBtn.BackgroundColor3=Color3.fromRGB(60,0,100); keyBtn.TextColor3=Color3.fromRGB(220,180,255); keyBtn.Font=Enum.Font.GothamBold; keyBtn.TextSize=12; keyBtn.Text=tostring(keybinds[feat]):gsub("Enum.KeyCode.","")
    Instance.new("UICorner",keyBtn).CornerRadius=UDim.new(0,7); local ks=Instance.new("UIStroke",keyBtn); ks.Color=Color3.fromRGB(120,0,200); ks.Thickness=1
    local hint=Instance.new("TextLabel",settingsScroll); hint.Size=UDim2.new(1,0,0,14); hint.Position=UDim2.new(0,0,0,y+22); hint.BackgroundTransparency=1; hint.Text="click key button then press any key"; hint.Font=Enum.Font.Gotham; hint.TextSize=10; hint.TextColor3=Color3.fromRGB(120,80,160); hint.TextXAlignment=Enum.TextXAlignment.Left; hint.Visible=false
    local thisFeature=feat
    keyBtn.MouseButton1Click:Connect(function()
        click()
        if listeningFor==thisFeature then listeningFor=nil; keyBtn.Text=tostring(keybinds[thisFeature]):gsub("Enum.KeyCode.",""); keyBtn.BackgroundColor3=Color3.fromRGB(60,0,100); hint.Visible=false
        else
            listeningFor=thisFeature; keyBtn.Text="[ press key ]"; keyBtn.BackgroundColor3=Color3.fromRGB(100,0,170); hint.Visible=true
            for _,slot in pairs(bindSlots) do if slot.feat~=thisFeature then slot.btn.BackgroundColor3=Color3.fromRGB(60,0,100); slot.btn.Text=tostring(keybinds[slot.feat]):gsub("Enum.KeyCode.",""); slot.hint.Visible=false end end
        end
    end)
    table.insert(bindSlots,{feat=thisFeature,btn=keyBtn,hint=hint})
end
local settingsInputConn=UIS.InputBegan:Connect(function(input,processed)
    if not listeningFor then return end; if processed then return end; if input.UserInputType~=Enum.UserInputType.Keyboard then return end
    local kc=input.KeyCode
    if kc==Enum.KeyCode.Escape then for _,slot in pairs(bindSlots) do slot.btn.BackgroundColor3=Color3.fromRGB(60,0,100); slot.btn.Text=tostring(keybinds[slot.feat]):gsub("Enum.KeyCode.",""); slot.hint.Visible=false end; listeningFor=nil; return end
    keybinds[listeningFor]=kc; notify(listeningFor.." → "..tostring(kc):gsub("Enum.KeyCode.",""),true)
    for _,slot in pairs(bindSlots) do slot.btn.Text=tostring(keybinds[slot.feat]):gsub("Enum.KeyCode.",""); slot.btn.BackgroundColor3=Color3.fromRGB(60,0,100); slot.hint.Visible=false end
    listeningFor=nil
end)
table.insert(connections,settingsInputConn)

Close.MouseButton1Click:Connect(function() menuSound(); onClose() end)

-- Shared tooltip frame
tooltipFrame=Instance.new("Frame",Main); tooltipFrame.Size=UDim2.new(0,200,0,28); tooltipFrame.BackgroundColor3=Color3.fromRGB(15,0,30); tooltipFrame.BackgroundTransparency=0.1; tooltipFrame.BorderSizePixel=0; tooltipFrame.ZIndex=20; tooltipFrame.Visible=false
Instance.new("UICorner",tooltipFrame).CornerRadius=UDim.new(0,7)
Instance.new("UIStroke",tooltipFrame).Color=Color3.fromRGB(120,0,200)
tooltipLbl=Instance.new("TextLabel",tooltipFrame); tooltipLbl.Size=UDim2.new(1,-8,1,0); tooltipLbl.Position=UDim2.new(0,4,0,0); tooltipLbl.BackgroundTransparency=1; tooltipLbl.Font=Enum.Font.Gotham; tooltipLbl.TextSize=11; tooltipLbl.TextColor3=Color3.fromRGB(210,180,255); tooltipLbl.TextXAlignment=Enum.TextXAlignment.Left; tooltipLbl.ZIndex=21

--// [LOOT ESP - Visuals Tab]
local LootEspBtn = Instance.new("TextButton", VisualPage)
LootEspBtn.Size = UDim2.new(0,180,0,40); LootEspBtn.Position = UDim2.new(0,0,0,126)
LootEspBtn.Text = "Loot ESP: OFF"; LootEspBtn.BackgroundColor3 = Color3.fromRGB(120,0,200)
LootEspBtn.TextColor3 = Color3.new(1,1,1); LootEspBtn.Font = Enum.Font.GothamBold; LootEspBtn.TextSize = 16
Instance.new("UICorner", LootEspBtn).CornerRadius = UDim.new(0,10)

local lootRangeLabel = Instance.new("TextLabel", VisualPage)
lootRangeLabel.Size = UDim2.new(0,80,0,14); lootRangeLabel.Position = UDim2.new(0,0,0,172)
lootRangeLabel.BackgroundTransparency = 1; lootRangeLabel.Text = "Range (studs):"
lootRangeLabel.Font = Enum.Font.Gotham; lootRangeLabel.TextSize = 11
lootRangeLabel.TextColor3 = Color3.fromRGB(200,170,255); lootRangeLabel.TextXAlignment = Enum.TextXAlignment.Left

local lootRangeBox = Instance.new("TextBox", VisualPage)
lootRangeBox.Size = UDim2.new(0,90,0,28); lootRangeBox.Position = UDim2.new(0,85,0,168)
lootRangeBox.Text = "200"; lootRangeBox.PlaceholderText = "200"
lootRangeBox.BackgroundColor3 = Color3.fromRGB(60,0,100); lootRangeBox.TextColor3 = Color3.new(1,1,1)
lootRangeBox.Font = Enum.Font.GothamBold; lootRangeBox.TextSize = 14
Instance.new("UICorner", lootRangeBox).CornerRadius = UDim.new(0,8)

local lootEspEnabled = false


function isLootObj(n) return n:find("loot") or n:find("drop") or n:find("pickup") or n:find("item") or n:find("chest") or n:find("coin") or n:find("gem") or n:find("weapon") or n:find("gun") or n:find("ammo") or n:find("crate") or n:find("bag") or n:find("supply") or n:find("reward") or n:find("cash") or n:find("money") or n:find("gold") or n:find("key") or n:find("orb") or n:find("shard") or n:find("mat") or n:find("resource") end
local function clearLootLabels()
    for part,_ in pairs(lootTracked) do
        if part and part:FindFirstChild("LootESP") then part.LootESP:Destroy() end
    end
    lootTracked = {}
end
local function tryAddLoot(obj)
    if not lootEspEnabled then return end
    if not isLootObj(obj.Name:lower()) then return end
    part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and obj.PrimaryPart or nil)
    if not part or part:FindFirstChild("LootESP") then return end
    local bb = Instance.new("BillboardGui", part); bb.Name = "LootESP"; bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,120,0,28); bb.StudsOffset = Vector3.new(0,2,0)
    local lbl = Instance.new("TextLabel", bb); lbl.Name = "Lbl"
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 0.4
    lbl.BackgroundColor3 = Color3.fromRGB(20,0,40); lbl.TextColor3 = Color3.fromRGB(255,210,60)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0,6)
    lootTracked[part] = obj
end
local function updateLootLabels()
    if not lootEspEnabled then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local maxDist = tonumber(lootRangeBox.Text) or 200
    for part, obj in pairs(lootTracked) do
        if part and part.Parent then
            local dist = (part.Position - hrp.Position).Magnitude
            if dist <= maxDist then
                if not part:FindFirstChild("LootESP") then tryAddLoot(obj) end
                if part:FindFirstChild("LootESP") and part.LootESP:FindFirstChild("Lbl") then
                    part.LootESP.Lbl.Text = obj.Name .. " [" .. math.floor(dist) .. "]"
                end
            else
                if part:FindFirstChild("LootESP") then part.LootESP:Destroy() end
            end
        else lootTracked[part] = nil end
    end
end
LootEspBtn.MouseButton1Click:Connect(function()
    click()
    lootEspEnabled = not lootEspEnabled
    LootEspBtn.Text = lootEspEnabled and "Loot ESP: ON" or "Loot ESP: OFF"
    LootEspBtn.BackgroundColor3 = lootEspEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200)
    activeFeatures["🔍 Loot"] = lootEspEnabled; updateFooter()
    if lootEspEnabled then
        lootTracked = {}
        for _, obj in pairs(workspace:GetDescendants()) do tryAddLoot(obj) end
    else clearLootLabels() end
    notify("Loot ESP: " .. (lootEspEnabled and "ON" or "OFF"), lootEspEnabled)
end)
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then task.wait(0.1) end
    tryAddLoot(obj)
end)
workspace.DescendantRemoving:Connect(function(obj)
    part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and obj.PrimaryPart or nil)
    if part then lootTracked[part] = nil end
end)
task.spawn(function()
    while not closed do task.wait(0.5)
        if lootEspEnabled then updateLootLabels() end
    end
end)


--// [LOOT TP LOGIC]
lootTpEnabled=false; lootTpRunning=false
lootTpBtn.MouseButton1Click:Connect(function()
    click()
    lootTpEnabled=not lootTpEnabled
    lootTpBtn.Text=lootTpEnabled and "Loot TP: ON" or "Loot TP: OFF"
    lootTpBtn.BackgroundColor3=lootTpEnabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(120,0,200)
    activeFeatures["📍 Loot TP"]=lootTpEnabled; updateFooter()
    if lootTpEnabled and not lootTpRunning then
        lootTpRunning=true
        task.spawn(function()
            while lootTpEnabled and not closed do
                lootTpQuery=lootTpNameBox.Text:lower()
                if lootTpQuery~="" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    for _,obj in pairs(workspace:GetDescendants()) do
                        if not lootTpEnabled then break end
                        if obj:IsA("BasePart") or obj:IsA("Model") then
                            lootTpName=obj.Name:lower()
                            if lootTpName:find(lootTpQuery) then
                                lootTpCF=nil
                                if obj:IsA("BasePart") then lootTpCF=obj.CFrame
                                elseif obj:IsA("Model") and obj.PrimaryPart then lootTpCF=obj.PrimaryPart.CFrame end
                                if lootTpCF then
                                    player.Character.HumanoidRootPart.CFrame=lootTpCF*CFrame.new(0,3,0)
                                    notify("Loot TP → "..obj.Name,true)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
            lootTpRunning=false
        end)
    end
    if not lootTpEnabled then notify("Loot TP: OFF",false) end
end)


-- Tooltips: map button text keywords to descriptions
tooltipMap = {
    ["Fly"]="Hold to fly around freely",
    ["Speed"]="Boost your walk speed",
    ["Ghost"]="Pass through players",
    ["Fling"]="Launch nearby players into the air",
    ["Orbit"]="Circle around a target player",
    ["Chat Spam"]="Repeatedly send a message in chat",
    ["Follow"]="Teleport to follow a target player",
    ["ESP"]="See players through walls",
    ["Skeleton"]="Show player bone outlines",
    ["Health Bar"]="Show player health above their head",
    ["Night Mode"]="Brighten dark maps",
    ["Loot ESP"]="Show nearby loot items in the world",
    ["Triggerbot"]="Auto shoot when crosshair is on a player",
    ["Aimbot"]="Auto aim at nearest player",
    ["Crosshair"]="Show a custom crosshair on screen",
    ["Inf Jump"]="Jump again while in the air",
    ["Swim"]="Swim through the air like water",
    ["Spectate"]="Watch another player in first person",
    ["Freeze"]="Lock a player in place client side",
    ["Save Position"]="Save your current location",
    ["Teleport"]="Go back to your saved location",
    ["Auto-Return"]="Auto teleport back after a delay",
    ["Click TP"]="Ctrl+Click to teleport anywhere",
    ["Loot TP"]="Auto teleport to matching loot objects",
    ["Mimic"]="Copy a players movements with a delay",
}
function showTooltip(btn, text)
    tooltipLbl.Text = text
    tooltipFrame.Size = UDim2.new(0, math.max(160, #text*6+16), 0, 28)
    tooltipFrame.Position = UDim2.new(0, btn.AbsolutePosition.X - Main.AbsolutePosition.X, 0, btn.AbsolutePosition.Y - Main.AbsolutePosition.Y - 32)
    tooltipFrame.Visible = true
end
function hideTooltip() tooltipFrame.Visible = false end
for _,obj in pairs(Main:GetDescendants()) do
    if obj:IsA("TextButton") then
        for keyword, desc in pairs(tooltipMap) do
            if obj.Text:find(keyword) then
                obj.MouseEnter:Connect(function() showTooltip(obj, desc) end)
                obj.MouseLeave:Connect(hideTooltip)
                break
            end
        end
    end
end
