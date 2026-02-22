--// Finest Hub - Char Edition 
--// [INITIAL SETUP]
pcall(function()
    game.CoreGui:FindFirstChild("FinestHub"):Destroy() 
    if game.CoreGui:FindFirstChild("FinestWatermark") then game.CoreGui.FinestWatermark:Destroy() end
end)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

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

--// [WATERMARK SYSTEM]
local WatermarkGui = Instance.new("ScreenGui", game.CoreGui)
WatermarkGui.Name = "FinestWatermark"

local WFrame = Instance.new("Frame", WatermarkGui)
WFrame.Size = UDim2.new(0, 240, 0, 30)
WFrame.Position = UDim2.new(1, -250, 0, 10)
WFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 40)
WFrame.BackgroundTransparency = 0.3
Instance.new("UICorner", WFrame).CornerRadius = UDim.new(0, 6)
local WStroke = Instance.new("UIStroke", WFrame)
WStroke.Color = Color3.fromRGB(170, 0, 255)
WStroke.Thickness = 1.5

local WText = Instance.new("TextLabel", WFrame)
WText.Size = UDim2.new(1, 0, 1, 0)
WText.BackgroundTransparency = 1
WText.TextColor3 = Color3.new(1, 1, 1)
WText.Font = Enum.Font.GothamBold
WText.TextSize = 14
WText.Text = "Finest Hub | Char Edition | FPS: ..."

-- FPS Logic for Watermark
local fps = 0
RunService.RenderStepped:Connect(function(dt)
    fps = math.floor(1/dt)
    WText.Text = "Finest Hub | Char Edition | FPS: " .. tostring(fps)
end)

--// [MAIN UI]
local Main = Instance.new("Frame", gui)
Main.Size = UDim2.new(0,550,0,300)
Main.Position = UDim2.new(0.5,-275,0.5,-150)
Main.BackgroundColor3 = Color3.fromRGB(35,0,60)
Main.BackgroundTransparency = 0.2
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)

-- NEON GLOW EFFECT
local Glow = Instance.new("UIStroke", Main)
Glow.Color = Color3.fromRGB(170, 0, 255)
Glow.Thickness = 3.5 -- Thicker for neon look
Glow.Transparency = 0.2 -- Softer edge
Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

--// [TITLE]
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,45)
Title.BackgroundTransparency = 1
Title.Text = "Finest Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(220,180,255)

--// [CLOSE]
local Close = Instance.new("TextButton", Main)
Close.Size = UDim2.new(0,40,0,40)
Close.Position = UDim2.new(1,-45,0,0)
Close.Text = "X"
Close.BackgroundTransparency = 1
Close.TextColor3 = Color3.fromRGB(255,120,200)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 22
Close.MouseButton1Click:Connect(function() 
    menuSound()
    WatermarkGui:Destroy()
    gui:Destroy() 
end)

--// [MINIMIZE]
local Min = Instance.new("TextButton", Main)
Min.Size = UDim2.new(0,40,0,40)
Min.Position = UDim2.new(1,-85,0,0)
Min.Text = "-"
Min.BackgroundTransparency = 1
Min.TextColor3 = Color3.fromRGB(200,150,255)
Min.Font = Enum.Font.GothamBold
Min.TextSize = 28

--// [SIDEBAR]
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0,140,1,-50)
Sidebar.Position = UDim2.new(0,5,0,45)
Sidebar.BackgroundColor3 = Color3.fromRGB(45,0,75)
Sidebar.BackgroundTransparency = 0.3
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,14)

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1,-160,1,-60)
Content.Position = UDim2.new(0,155,0,50)
Content.BackgroundTransparency = 1

--// MINIMIZE LOGIC
local minimized = false
local animTime = 0.4 
local animStyle = Enum.EasingStyle.Quart 

Min.MouseButton1Click:Connect(function()
    menuSound()
    minimized = not minimized
    
    if minimized then
        Sidebar.Visible = false
        Content.Visible = false
        local shrink = TweenService:Create(Main, TweenInfo.new(animTime, animStyle, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 200, 0, 45),
            BackgroundTransparency = 0.3
        })
        Title.Size = UDim2.new(0, 120, 0, 45)
        Close.Position = UDim2.new(0, 160, 0, 0)
        Min.Position = UDim2.new(0, 130, 0, 0)
        Min.Text = "+"
        shrink:Play()
    else
        local expand = TweenService:Create(Main, TweenInfo.new(animTime, animStyle, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 550, 0, 300),
            BackgroundTransparency = 0.2
        })
        Title.Size = UDim2.new(1, 0, 0, 45)
        Close.Position = UDim2.new(1, -45, 0, 0)
        Min.Position = UDim2.new(1, -85, 0, 0)
        Min.Text = "-"
        expand:Play()
        expand.Completed:Wait()
        Sidebar.Visible = true
        Content.Visible = true
    end
end)

--// [TAB SYSTEM]
local function createTab(name, y)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1,-10,0,50)
    btn.Position = UDim2.new(0,5,0,y)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(70,0,110)
    btn.TextColor3 = Color3.fromRGB(230,200,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,12)

    local page = Instance.new("Frame", Content)
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false

    btn.MouseButton1Click:Connect(function()
        click() 
        for _,v in pairs(Content:GetChildren()) do
            if v:IsA("Frame") then v.Visible = false end
        end
        page.Visible = true
    end)
    return page
end

local SpeedPage = createTab("Speed", 10)
local FlyPage = createTab("Fly", 65)
local GhostPage = createTab("Ghost", 120)
local TPPage = createTab("TP", 175)
SpeedPage.Visible = true

--// [SPEED MODULE]
local speedBox = Instance.new("TextBox", SpeedPage)
speedBox.Size = UDim2.new(0,180,0,45)
speedBox.PlaceholderText = "Enter Speed"
speedBox.Text = ""
speedBox.ClearTextOnFocus = true
speedBox.BackgroundColor3 = Color3.fromRGB(60,0,100)
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 16
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0,10)

local setSpeed = Instance.new("TextButton", SpeedPage)
setSpeed.Size = UDim2.new(0,180,0,45)
setSpeed.Position = UDim2.new(0,0,0,55)
setSpeed.Text = "Set Speed"
setSpeed.BackgroundColor3 = Color3.fromRGB(120,0,200)
setSpeed.TextColor3 = Color3.new(1,1,1)
setSpeed.Font = Enum.Font.GothamBold
setSpeed.TextSize = 18
Instance.new("UICorner", setSpeed).CornerRadius = UDim.new(0,10)

setSpeed.MouseButton1Click:Connect(function()
    click()
    local val = tonumber(speedBox.Text)
    if val and player.Character then
        player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)

--// [FLY MODULE]
local flying = false
local flySpeed = 70
local bv, bg

local FlySpeedBox = Instance.new("TextBox", FlyPage)
FlySpeedBox.Size = UDim2.new(0,180,0,45)
FlySpeedBox.PlaceholderText = "Fly Speed"
FlySpeedBox.Text = ""
FlySpeedBox.BackgroundColor3 = Color3.fromRGB(60,0,100)
FlySpeedBox.TextColor3 = Color3.new(1,1,1)
FlySpeedBox.Font = Enum.Font.GothamBold
FlySpeedBox.TextSize = 16
FlySpeedBox.ClearTextOnFocus = true
Instance.new("UICorner", FlySpeedBox).CornerRadius = UDim.new(0,10)

local FlyBtn = Instance.new("TextButton", FlyPage)
FlyBtn.Size = UDim2.new(0,180,0,45)
FlyBtn.Position = UDim2.new(0,0,0,55)
FlyBtn.Text = "Toggle Fly: OFF"
FlyBtn.BackgroundColor3 = Color3.fromRGB(120,0,200)
FlyBtn.TextColor3 = Color3.new(1,1,1)
FlyBtn.Font = Enum.Font.GothamBold
FlyBtn.TextSize = 18
Instance.new("UICorner", FlyBtn).CornerRadius = UDim.new(0,10)

FlyBtn.MouseButton1Click:Connect(function()
    click() 
    flying = not flying
    FlyBtn.Text = flying and "Toggle Fly: ON" or "Toggle Fly: OFF"
    FlyBtn.BackgroundColor3 = flying and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flying then
        bv = Instance.new("BodyVelocity", hrp)
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bg = Instance.new("BodyGyro", hrp)
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    else
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
end)

--// [GHOST MODULE]
local ghostEnabled = false
local ghostBtn = Instance.new("TextButton", GhostPage)
ghostBtn.Size = UDim2.new(0, 180, 0, 45)
ghostBtn.Text = "Ghost: OFF"
ghostBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 200)
ghostBtn.TextColor3 = Color3.new(1, 1, 1)
ghostBtn.Font = Enum.Font.GothamBold
ghostBtn.TextSize = 18
Instance.new("UICorner", ghostBtn).CornerRadius = UDim.new(0, 10)

ghostBtn.MouseButton1Click:Connect(function()
    click() 
    ghostEnabled = not ghostEnabled
    ghostBtn.Text = ghostEnabled and "Ghost: ON" or "Ghost: OFF"
    ghostBtn.BackgroundColor3 = ghostEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(120, 0, 200)
end)

--// [TP MODULE]
local savedPosition = nil
local autoReturn = false

local saveBtn = Instance.new("TextButton", TPPage)
saveBtn.Size = UDim2.new(0,180,0,45)
saveBtn.Text = "Save Position"
saveBtn.BackgroundColor3 = Color3.fromRGB(120,0,200)
saveBtn.TextColor3 = Color3.new(1,1,1)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 18
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0,10)

local tpBtn = Instance.new("TextButton", TPPage)
tpBtn.Size = UDim2.new(0,180,0,45)
tpBtn.Position = UDim2.new(0,0,0,55)
tpBtn.Text = "Teleport"
tpBtn.BackgroundColor3 = Color3.fromRGB(120,0,200)
tpBtn.TextColor3 = Color3.new(1,1,1)
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextSize = 18
Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0,10)

local autoBtn = Instance.new("TextButton", TPPage)
autoBtn.Size = UDim2.new(0,180,0,45)
autoBtn.Position = UDim2.new(0,0,0,110)
autoBtn.Text = "Auto-Return: OFF"
autoBtn.BackgroundColor3 = Color3.fromRGB(60,0,100)
autoBtn.TextColor3 = Color3.new(1,1,1)
autoBtn.Font = Enum.Font.GothamBold
autoBtn.TextSize = 18
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0,10)

saveBtn.MouseButton1Click:Connect(function()
    click()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        savedPosition = hrp.CFrame
        saveBtn.Text = "DONE!"
        task.wait(0.5)
        saveBtn.Text = "Save Position"
    end
end)

tpBtn.MouseButton1Click:Connect(function()
    click()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and savedPosition then hrp.CFrame = savedPosition end
end)

autoBtn.MouseButton1Click:Connect(function()
    click()
    autoReturn = not autoReturn
    autoBtn.Text = autoReturn and "Auto-Return: ON" or "Auto-Return: OFF"
    autoBtn.BackgroundColor3 = autoReturn and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60,0,100)
end)

--// [LOOPS & INPUTS]
RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end

    if flying and bv and bg then
        flySpeed = tonumber(FlySpeedBox.Text) or 70
        local cam = workspace.CurrentCamera
        local direction = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.new(0,1,0) end
        bv.Velocity = (direction.Magnitude > 0) and (direction.Unit * flySpeed) or Vector3.zero
        bg.CFrame = cam.CFrame
    end

    if ghostEnabled then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightControl then
        menuSound() 
        Main.Visible = not Main.Visible
        WFrame.Visible = Main.Visible -- Watermark hides when menu hides
    end
end)

task.spawn(function()
    while task.wait(3.2) do
        if autoReturn and savedPosition and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = savedPosition end
        end
    end
end)

menuSound()