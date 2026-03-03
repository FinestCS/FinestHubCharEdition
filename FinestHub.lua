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
local player = Players.LocalPlayer
local mouse = player:GetMouse()

--// [SHUTDOWN SYSTEM]
local closed = false
local connections = {}
-- pre-declare feature states so onClose can reference them before modules load
local flying, bv, bg = false, nil, nil
local ghostEnabled = false
local spinning = false
local triggerbotEnabled = false
local espEnabled = false
local function onClose()
    if closed then return end
    closed = true
    for _, c in pairs(connections) do c:Disconnect() end
    flying = false
    if bv then bv:Destroy(); bv = nil end
    if bg then bg:Destroy(); bg = nil end
    ghostEnabled = false
    spinning = false
    triggerbotEnabled = false
    espEnabled = false
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if hrp then
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
            local fv = hrp:FindFirstChild("FlingVel")
            if fv then fv:Destroy() end
        end
    end
end

--// [ANTI-AFK BACKGROUND LOGIC]
local VirtualUser = game:GetService("VirtualUser")
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "FinestHub" 

--// [AUDIO SYSTEM]
local function playSound(id, vol)
    local s = Instance.new("Sound", gui)
    s.SoundId = "rbxassetid://" .. tostring(id)
    s.Volume = vol or 0.5
    s:Play()
    game.Debris:AddItem(s, 1)
end
local function click() playSound(6895079853, 0.5) end
local function menuSound() playSound(6031313768, 0.7) end

--// NOTIFICATION SYSTEM
local function notify(text, isOn)
    local notif = Instance.new("Frame", gui)
    notif.Size = UDim2.new(0, 250, 0, 45)
    notif.Position = UDim2.new(1, 300, 1, -70)
    notif.BackgroundColor3 = isOn and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
    notif.BackgroundTransparency = 0.1

    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 12)

    local label = Instance.new("TextLabel", notif)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextColor3 = Color3.new(1,1,1)

    TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -270, 1, -70)
    }):Play()

    task.delay(2, function()
        TweenService:Create(notif, TweenInfo.new(0.3), {
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.3)
        notif:Destroy()
    end)
end

--// [WATERMARK + ANTI-AFK STATUS]
local WatermarkGui = Instance.new("ScreenGui", game.CoreGui)
WatermarkGui.Name = "FinestWatermark"
local WFrame = Instance.new("Frame", WatermarkGui)
WFrame.Size = UDim2.new(0, 380, 0, 30); WFrame.Position = UDim2.new(1, -390, 0, 10); WFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 40); WFrame.BackgroundTransparency = 0.3
Instance.new("UICorner", WFrame).CornerRadius = UDim.new(0, 6)
local WStroke = Instance.new("UIStroke", WFrame); WStroke.Color = Color3.fromRGB(170, 0, 255); WStroke.Thickness = 1.5
local WText = Instance.new("TextLabel", WFrame); WText.Size = UDim2.new(1, 0, 1, 0); WText.BackgroundTransparency = 1; WText.TextColor3 = Color3.new(1, 1, 1); WText.Font = Enum.Font.GothamBold; WText.TextSize = 14; WText.RichText = true
RunService.RenderStepped:Connect(function(dt) WText.Text = "Finest Hub | Char Edition | FPS: " .. math.floor(1/dt) .. " | <font color='#00FF00'>[ Anti AFK: On ]</font>" end)

--// [MAIN UI]
local Main = Instance.new("Frame", gui)
Main.Size = UDim2.new(0,550,0,300); Main.Position = UDim2.new(0.5,-275,0.5,-150); Main.BackgroundColor3 = Color3.fromRGB(35,0,60); Main.BackgroundTransparency = 0.2; Main.Active = true; Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)
local Glow = Instance.new("UIStroke", Main); Glow.Color = Color3.fromRGB(170, 0, 255); Glow.Thickness = 3.5; Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

--// [PULSING GLOW ANIMATION - smooth infinite sine]
local pulsing = true
local glowTween = TweenService:Create(
    Glow,
    TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Thickness = 3.8, Color = Color3.fromRGB(195, 65, 255) }
)
glowTween:Play()

local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1,0,0,45); Title.BackgroundTransparency = 1; Title.Text = "Finest Hub"; Title.Font = Enum.Font.GothamBold; Title.TextSize = 24; Title.TextColor3 = Color3.fromRGB(220,180,255); Title.RichText = true

--// [ANIMATED TITLE - cycles each letter through purple shades in sync with glow]
local titleChars = {"F","i","n","e","s","t"," ","H","u","b"}
local titleColors = {
    Color3.fromRGB(220, 180, 255),
    Color3.fromRGB(200, 120, 255),
    Color3.fromRGB(180,  60, 255),
    Color3.fromRGB(160,   0, 240),
    Color3.fromRGB(180,  60, 255),
    Color3.fromRGB(200, 120, 255),
}
task.spawn(function()
    local offset = 0
    while not closed do
        local result = ""
        for i, ch in ipairs(titleChars) do
            if ch == " " then
                result = result .. " "
            else
                local colorIndex = ((i + offset - 1) % #titleColors) + 1
                local c = titleColors[colorIndex]
                local hex = string.format("%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
                result = result .. "<font color='#" .. hex .. "'>" .. ch .. "</font>"
            end
        end
        Title.Text = result
        offset = (offset + 1) % #titleColors
        task.wait(0.18)
    end
end)
local Close = Instance.new("TextButton", Main); Close.Size = UDim2.new(0,40,0,40); Close.Position = UDim2.new(1,-45,0,0); Close.Text = "X"; Close.BackgroundTransparency = 1; Close.TextColor3 = Color3.fromRGB(255,120,200); Close.Font = Enum.Font.GothamBold; Close.TextSize = 22
-- Close wired below after FooterGui is declared
local Min = Instance.new("TextButton", Main); Min.Size = UDim2.new(0,40,0,40); Min.Position = UDim2.new(1,-85,0,0); Min.Text = "-"; Min.BackgroundTransparency = 1; Min.TextColor3 = Color3.fromRGB(200,150,255); Min.Font = Enum.Font.GothamBold; Min.TextSize = 28

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0,140,1,-55); Sidebar.Position = UDim2.new(0,5,0,45); Sidebar.BackgroundColor3 = Color3.fromRGB(45,0,75); Sidebar.BackgroundTransparency = 0.3
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,14)

-- [SEPARATE FOOTER BAR GUI] declared first so updateFooter and Close can reference it safely
local FooterGui = Instance.new("ScreenGui", game.CoreGui)
FooterGui.Name = "FinestFooter"

local Footer = Instance.new("Frame", FooterGui)
Footer.Size = UDim2.new(0, 380, 0, 26)
Footer.Position = UDim2.new(1, -390, 0, 45)
Footer.BackgroundColor3 = Color3.fromRGB(20, 0, 40)
Footer.BackgroundTransparency = 0.3
Instance.new("UICorner", Footer).CornerRadius = UDim.new(0, 6)
local FooterStroke = Instance.new("UIStroke", Footer)
FooterStroke.Color = Color3.fromRGB(170, 0, 255)
FooterStroke.Thickness = 1.5

local FooterLabel = Instance.new("TextLabel", Footer)
FooterLabel.Size = UDim2.new(1, -10, 1, 0)
FooterLabel.Position = UDim2.new(0, 8, 0, 0)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Text = "<font color='#666688'>No features active</font>"
FooterLabel.Font = Enum.Font.Gotham
FooterLabel.TextSize = 12
FooterLabel.TextColor3 = Color3.fromRGB(180, 130, 255)
FooterLabel.TextXAlignment = Enum.TextXAlignment.Left
FooterLabel.RichText = true

-- active features tracker - defined after FooterLabel so it can reference it
local activeFeatures = {}
local function updateFooter()
    local parts = {}
    for feat, on in pairs(activeFeatures) do
        if on then
            table.insert(parts, "<font color='#BB66FF'>" .. feat .. "</font>")
        end
    end
    if #parts == 0 then
        FooterLabel.Text = "<font color='#666688'>No features active</font>"
    else
        FooterLabel.Text = "● " .. table.concat(parts, "  ·  ")
    end
end

-- Close button - fully wired at end of file to ensure all vars exist
-- We use a deferred approach: store the handler and call it after all declarations

local Content = Instance.new("Frame", Main); Content.Size = UDim2.new(1,-160,1,-60); Content.Position = UDim2.new(0,155,0,50); Content.BackgroundTransparency = 1

--// MINIMIZE LOGIC
local minimized = false
Min.MouseButton1Click:Connect(function()
    menuSound()
    minimized = not minimized

    if minimized then
        Sidebar.Visible = false
        Content.Visible = false
        Close.Visible = false

        TweenService:Create(
            Main,
            TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 200, 0, 45), BackgroundTransparency = 0.3}
        ):Play()

        Title.Size = UDim2.new(0, 120, 0, 45)
        Min.Position = UDim2.new(1, -45, 0, 0)
        Min.Text = "+"
    else
        local expand = TweenService:Create(
            Main,
            TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 550, 0, 300), BackgroundTransparency = 0.2}
        )

        Title.Size = UDim2.new(1, 0, 0, 45)
        Close.Visible = true
        Close.Position = UDim2.new(1, -45, 0, 0)
        Min.Position = UDim2.new(1, -85, 0, 0)
        Min.Text = "-"

        expand:Play()
        expand.Completed:Wait()

        Sidebar.Visible = true
        Content.Visible = true
        Footer.Visible = true
    end
end)

--// [NEW] TAB ICONS MAP
local tabIcons = {
    ["Speed"]   = "⚡",
    ["Fly"]     = "🕊",
    ["Ghost"]   = "👻",
    ["Trigger"] = "🎯",
    ["TP"]      = "📍",
    ["Players"] = "👥",
    ["Troll"]   = "🌀",
    ["Visuals"] = "👁",
}

local function createTab(name, y)
    local icon = tabIcons[name] or ""
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1,-10,0,28); btn.Position = UDim2.new(0,5,0,y)
    btn.Text = icon .. " " .. name
    btn.BackgroundColor3 = Color3.fromRGB(70,0,110); btn.TextColor3 = Color3.fromRGB(230,200,255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    -- per-tab glow stroke, hidden by default
    local tabStroke = Instance.new("UIStroke", btn)
    tabStroke.Color = Color3.fromRGB(200, 80, 255)
    tabStroke.Thickness = 1.5
    tabStroke.Transparency = 1 -- hidden until active

    local page = Instance.new("Frame", Content); page.Size = UDim2.new(1,0,1,0); page.BackgroundTransparency = 1; page.Visible = false

    btn.MouseButton1Click:Connect(function()
        click()
        -- dim all tabs and hide their strokes
        for _, v in pairs(Sidebar:GetChildren()) do
            if v:IsA("TextButton") then
                TweenService:Create(v, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(70, 0, 110),
                    TextColor3 = Color3.fromRGB(230, 200, 255)
                }):Play()
                local s = v:FindFirstChildOfClass("UIStroke")
                if s then
                    TweenService:Create(s, TweenInfo.new(0.15), { Transparency = 1 }):Play()
                end
            end
        end
        -- highlight active tab + show its glow
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(130, 0, 210),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TweenService:Create(tabStroke, TweenInfo.new(0.15), { Transparency = 0 }):Play()
        -- show this page
        for _,v in pairs(Content:GetChildren()) do if v:IsA("Frame") then v.Visible = false end end
        page.Visible = true
    end)

    return page, btn, tabStroke
end

--// ALL TABS
local SpeedPage,   SpeedBtn,    SpeedStroke   = createTab("Speed",   5)
local FlyPage,     FlyTabBtn,   FlyStroke     = createTab("Fly",     35)
local GhostPage,   GhostTabBtn, GhostStroke   = createTab("Ghost",   65)
local TriggerPage, TrigTabBtn,  TrigStroke    = createTab("Trigger", 95)
local TPPage,      TPTabBtn,    TPStroke      = createTab("TP",      125)
local PlayersPage, PlTabBtn,    PlStroke      = createTab("Players", 155)
local TrollPage,   TrTabBtn,    TrStroke      = createTab("Troll",   185)
local VisualPage,  VisTabBtn,   VisStroke     = createTab("Visuals", 215)

-- highlight Speed as default active tab + show its glow
SpeedPage.Visible = true
TweenService:Create(SpeedBtn, TweenInfo.new(0.15), {
    BackgroundColor3 = Color3.fromRGB(130, 0, 210),
    TextColor3 = Color3.fromRGB(255, 255, 255)
}):Play()
TweenService:Create(SpeedStroke, TweenInfo.new(0.15), { Transparency = 0 }):Play()

--// HOVER EFFECT FUNCTION
local function applyHover(button, normalColor, hoverColor)
    local originalSize = button.Size
    button.AutoButtonColor = false

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = hoverColor,
            Size = UDim2.new(
                originalSize.X.Scale,
                originalSize.X.Offset,
                originalSize.Y.Scale,
                originalSize.Y.Offset + 2
            )
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = normalColor,
            Size = originalSize
        }):Play()
    end)
end

local function addBox(parent, placeholder, y, default)
    local box = Instance.new("TextBox", parent); box.Size = UDim2.new(0,180,0,45); box.Position = UDim2.new(0,0,0,y); box.PlaceholderText = placeholder; box.Text = default or ""; box.BackgroundColor3 = Color3.fromRGB(60,0,100); box.TextColor3 = Color3.new(1,1,1); box.Font = Enum.Font.GothamBold; box.TextSize = 16
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,10); return box
end
local function addBtn(parent, text, y)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(0,180,0,45); btn.Position = UDim2.new(0,0,0,y); btn.Text = text; btn.BackgroundColor3 = Color3.fromRGB(120,0,200); btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 18
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10); return btn
end

--// [SPEED MODULE]
local speedBox = addBox(SpeedPage, "Enter Speed", 0); local setSpeed = addBtn(SpeedPage, "Set Speed", 55)
setSpeed.MouseButton1Click:Connect(function() click(); if player.Character then player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = tonumber(speedBox.Text) or 16 end end)

--// [FLY MODULE]
local FlySpeedBox = addBox(FlyPage, "Fly Speed", 0, "70"); local FlyBtn = addBtn(FlyPage, "Toggle Fly: OFF", 55)
FlyBtn.MouseButton1Click:Connect(function()
    click(); flying = not flying
    FlyBtn.Text = flying and "Toggle Fly: ON" or "Toggle Fly: OFF"
    FlyBtn.BackgroundColor3 = flying and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
    activeFeatures["🕊 Fly"] = flying; updateFooter()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if flying and hrp then bv = Instance.new("BodyVelocity", hrp); bv.MaxForce = Vector3.new(1e9, 1e9, 1e9); bg = Instance.new("BodyGyro", hrp); bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    else if bv then bv:Destroy() end if bg then bg:Destroy() end end
end)

--// [GHOST MODULE]
local ghostBtn = addBtn(GhostPage, "Ghost: OFF", 0)
ghostBtn.MouseButton1Click:Connect(function()
    click(); ghostEnabled = not ghostEnabled
    ghostBtn.Text = ghostEnabled and "Ghost: ON" or "Ghost: OFF"
    ghostBtn.BackgroundColor3 = ghostEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
    activeFeatures["👻 Ghost"] = ghostEnabled; updateFooter()
end)

--// [TP MODULE + CLICK TP]
local savedPosition, autoReturn = nil, false; local clickTpEnabled = false
local saveBtn = addBtn(TPPage, "Save Position", 0); local tpBtn = addBtn(TPPage, "Teleport", 55); local autoBtn = addBtn(TPPage, "Auto-Return: OFF", 110); local autoTimeBox = addBox(TPPage, "Delay", 110, "3.5")
autoTimeBox.Position = UDim2.new(0, 190, 0, 0); autoTimeBox.Size = UDim2.new(0, 80, 0, 45)
local clickTpBtn = addBtn(TPPage, "Click TP: OFF", 165)
saveBtn.MouseButton1Click:Connect(function() click(); if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then savedPosition = player.Character.HumanoidRootPart.CFrame; saveBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120); TweenService:Create(saveBtn, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(120, 0, 200)}):Play() end end)
tpBtn.MouseButton1Click:Connect(function() click(); if player.Character and savedPosition then player.Character.HumanoidRootPart.CFrame = savedPosition end end)
autoBtn.MouseButton1Click:Connect(function()
    click(); autoReturn = not autoReturn
    autoBtn.Text = autoReturn and "Auto-Return: ON" or "Auto-Return: OFF"
    autoBtn.BackgroundColor3 = autoReturn and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
    activeFeatures["📍 Auto-Return"] = autoReturn; updateFooter()
end)
clickTpBtn.MouseButton1Click:Connect(function()
    click(); clickTpEnabled = not clickTpEnabled
    clickTpBtn.Text = clickTpEnabled and "Click TP: ON" or "Click TP: OFF"
    clickTpBtn.BackgroundColor3 = clickTpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
    activeFeatures["📍 ClickTP"] = clickTpEnabled; updateFooter()
end)
mouse.Button1Down:Connect(function() if clickTpEnabled and UIS:IsKeyDown(Enum.KeyCode.LeftControl) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then player.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.p) + Vector3.new(0, 3, 0); playSound(12222242, 0.4) end end)

--// [PLAYERS TAB]
local PlayerScroll = Instance.new("ScrollingFrame", PlayersPage); PlayerScroll.Size = UDim2.new(1, 0, 1, 0); PlayerScroll.BackgroundTransparency = 1; PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0); PlayerScroll.ScrollBarThickness = 2
local UIList = Instance.new("UIListLayout", PlayerScroll); UIList.Padding = UDim.new(0, 5)
local function refreshPlayers()
    for _, v in pairs(PlayerScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do if p ~= player then
        local pBtn = Instance.new("TextButton", PlayerScroll); pBtn.Size = UDim2.new(1, -5, 0, 35); pBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 100); pBtn.Text = p.DisplayName; pBtn.TextColor3 = Color3.new(1, 1, 1); pBtn.Font = Enum.Font.GothamBold; Instance.new("UICorner", pBtn)
        pBtn.MouseButton1Click:Connect(function() click(); if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame end end)
    end end
    PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y)
end
task.spawn(function() while task.wait(5) do if PlayersPage.Visible then refreshPlayers() end end end)

--// [FLING MODULE]
local FBtn = addBtn(TrollPage, "Fling: OFF", 0); local FPower = addBox(TrollPage, "Power", 55, "10000")
FBtn.MouseButton1Click:Connect(function() 
    click(); spinning = not spinning
    FBtn.Text = spinning and "Fling: ON" or "Fling: OFF"
    FBtn.BackgroundColor3 = spinning and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
    activeFeatures["🌀 Fling"] = spinning; updateFooter()
    if not spinning and player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart"); local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.Velocity = Vector3.zero; hrp.RotVelocity = Vector3.zero; if hrp:FindFirstChild("FlingVel") then hrp.FlingVel:Destroy() end end
        if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end
end)

--// [VISUALS]
local function createESP(p)
    if p == player then return end
    local function apply()
        local char = p.Character or p.CharacterAdded:Wait(); local hrp = char:WaitForChild("HumanoidRootPart", 5); if not hrp then return end
        local h = Instance.new("Highlight", char); h.Name = "FinestESP"; h.FillColor = Color3.fromRGB(170, 0, 255); h.OutlineColor = Color3.new(1, 1, 1); h.FillTransparency = 0.5
        local b = Instance.new("BillboardGui", char); b.Name = "FinestName"; b.Size = UDim2.new(0, 200, 0, 50); b.Adornee = hrp; b.AlwaysOnTop = true; b.ExtentsOffset = Vector3.new(0, 3, 0)
        local t = Instance.new("TextLabel", b); t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1; t.Text = p.DisplayName; t.TextColor3 = Color3.fromRGB(190, 100, 255); t.Font = Enum.Font.GothamBold; t.TextSize = 14
    end
    p.CharacterAdded:Connect(apply); if p.Character then apply() end
end
local function removeESP() for _, v in pairs(Players:GetPlayers()) do if v.Character then if v.Character:FindFirstChild("FinestESP") then v.Character.FinestESP:Destroy() end if v.Character:FindFirstChild("FinestName") then v.Character.FinestName:Destroy() end end end end
local EspBtn = addBtn(VisualPage, "ESP: OFF", 0)
EspBtn.MouseButton1Click:Connect(function()
    click(); espEnabled = not espEnabled
    EspBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    EspBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
    activeFeatures["👁 ESP"] = espEnabled; updateFooter()
    if espEnabled then for _, p in pairs(Players:GetPlayers()) do createESP(p) end else removeESP() end
end)

--// [ORIGINAL MASTER LOOP]
connections.renderStepped = RunService.RenderStepped:Connect(function()
    local char = player.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart; local hum = char:FindFirstChildOfClass("Humanoid")
    if spinning then
        local s = tonumber(FPower.Text) or 10000
        for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        hum.PlatformStand = true; hrp.Velocity = Vector3.new(0, 0.4, 0); hrp.RotVelocity = Vector3.new(0, s, 0) 
        local bodyVel = hrp:FindFirstChild("FlingVel") or Instance.new("BodyVelocity", hrp)
        bodyVel.Name = "FlingVel"; bodyVel.MaxForce = Vector3.new(math.huge, 0, math.huge); bodyVel.Velocity = hrp.CFrame.LookVector * 0.1
    end
    if flying and bv and bg then
        local cam = workspace.CurrentCamera; local direction = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.new(0,1,0) end
        bv.Velocity = (direction.Magnitude > 0) and (direction.Unit * (tonumber(FlySpeedBox.Text) or 70)) or Vector3.zero; bg.CFrame = cam.CFrame
    end
    if ghostEnabled and not spinning then for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
end)

--// [DYNAMIC AUTO-RETURN]
task.spawn(function()
    while true do
        local delayTime = tonumber(autoTimeBox.Text) or 3.5; task.wait(delayTime)
        if autoReturn and savedPosition and player.Character then local hrp = player.Character:FindFirstChild("HumanoidRootPart") if hrp then hrp.CFrame = savedPosition end end
    end
end)

--// [TRIGGERBOT ADDON - COMPLETELY ISOLATED]
local TriggerBtn = addBtn(TriggerPage, "Triggerbot: OFF", 0)
TriggerBtn.MouseButton1Click:Connect(function()
    click(); triggerbotEnabled = not triggerbotEnabled
    TriggerBtn.Text = triggerbotEnabled and "Triggerbot: ON" or "Triggerbot: OFF"
    TriggerBtn.BackgroundColor3 = triggerbotEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
    activeFeatures["🎯 Trigger"] = triggerbotEnabled; updateFooter()
end)

task.spawn(function()
    while task.wait() do
        if triggerbotEnabled and mouse.Target then
            local t = mouse.Target
            local c = (t.Parent:FindFirstChildOfClass("Humanoid") and t.Parent) or (t.Parent.Parent:FindFirstChildOfClass("Humanoid") and t.Parent.Parent)
            if c and c ~= player.Character and c:FindFirstChildOfClass("Humanoid").Health > 0 then
                mouse1click()
            end
        end
    end
end)

connections.inputBegan = UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightControl then
        menuSound()
        Main.Visible = not Main.Visible
        WFrame.Visible = Main.Visible
        FooterGui.Enabled = Main.Visible
    end

    if input.KeyCode == Enum.KeyCode.T then
        triggerbotEnabled = not triggerbotEnabled
        TriggerBtn.Text = triggerbotEnabled and "Triggerbot: ON" or "Triggerbot: OFF"
        TriggerBtn.BackgroundColor3 = triggerbotEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
        activeFeatures["🎯 Trigger"] = triggerbotEnabled; updateFooter()
        click()
        notify("Triggerbot: " .. (triggerbotEnabled and "ON" or "OFF"), triggerbotEnabled)
    end

    if input.KeyCode == Enum.KeyCode.F then
        flying = not flying
        FlyBtn.Text = flying and "Toggle Fly: ON" or "Toggle Fly: OFF"
        FlyBtn.BackgroundColor3 = flying and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
        activeFeatures["🕊 Fly"] = flying; updateFooter()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if flying and hrp then
            bv = Instance.new("BodyVelocity", hrp)
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bg = Instance.new("BodyGyro", hrp)
            bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        else
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        click()
        notify("Fly: " .. (flying and "ON" or "OFF"), flying)
    end

    if input.KeyCode == Enum.KeyCode.E then
        espEnabled = not espEnabled
        EspBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
        EspBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
        activeFeatures["👁 ESP"] = espEnabled; updateFooter()
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do createESP(p) end
        else
            removeESP()
        end
        click()
        notify("ESP: " .. (espEnabled and "ON" or "OFF"), espEnabled)
    end

    -- Ghost Toggle (G)
    if input.KeyCode == Enum.KeyCode.G then
        ghostEnabled = not ghostEnabled
        ghostBtn.Text = ghostEnabled and "Ghost: ON" or "Ghost: OFF"
        ghostBtn.BackgroundColor3 = ghostEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
        activeFeatures["👻 Ghost"] = ghostEnabled; updateFooter()
        click()
        notify("Ghost: " .. (ghostEnabled and "ON" or "OFF"), ghostEnabled)
    end
end)

--// [CLOSE BUTTON - wired last so glowTween, WatermarkGui, FooterGui, gui are all guaranteed in scope]
Close.MouseButton1Click:Connect(function()
    onClose()
    removeESP()
    glowTween:Cancel()
    menuSound()
    WatermarkGui:Destroy()
    FooterGui:Destroy()
    gui:Destroy()
end)
