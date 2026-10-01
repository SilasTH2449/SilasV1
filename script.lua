-- Syrex Hub V32 (Fixed Death Loop + Auto Heal + Back Alert + Full Unload)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Global State & Connections Tracking
local scriptRunning = true
local connections = {}

-- Config Data Table
local Config = {
    espEnabled = true,
    teamCheckEnabled = false,
    aimbotEnabled = false,
    aimModeIndex = 1,
    smoothIndex = 2,
    wallCheckEnabled = true,
    targetPartIndex = 1,
    noBulletDrop = true,
    hitboxExpanded = false,
    hitboxIndex = 2,
    instantPickupEnabled = false,
    fovEnabled = true,
    fovIndex = 3,
    leadIndex = 3,
    autoHealEnabled = false,
    backAlertEnabled = false
}

-- Options Lists
local aimModes = {"Smooth Cam", "Hard Lock", "Mouse Delta"}
local smoothnessLevels = {0.1, 0.25, 0.5, 0.8, 1.0}
local targetParts = {"Head", "Neck", "HumanoidRootPart"}
local targetPartNames = {"Head [หัว]", "Neck [คอ]", "Body [ลำตัว]"}
local hitboxSizes = {4, 7, 10, 15}
local fovSizes = {60, 100, 140, 180, 240, 300}
local leadMultipliers = {0, 0.5, 1.0, 1.5, 2.0}

local stickyTarget = nil
local configFileName = "SyrexHub_Config.json"

-- Clean Old GUI
local parentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if parentGui:FindFirstChild("SyrexHub_V32") then
    parentGui:FindFirstChild("SyrexHub_V32"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyrexHub_V32"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

-- Main UI Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.3, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 520, 0, 370)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Left Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Sidebar.BorderSizePixel = 0
Sidebar.Size = UDim2.new(0, 140, 1, 0)

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = Sidebar
TitleLabel.Size = UDim2.new(1, 0, 0, 45)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "  SYREX HUB V32"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local TabContainer = Instance.new("Frame")
TabContainer.Parent = Sidebar
TabContainer.Position = UDim2.new(0, 0, 0, 50)
TabContainer.Size = UDim2.new(1, 0, 1, -50)
TabContainer.BackgroundTransparency = 1

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Parent = TabContainer
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 5)

-- Right Content Panel
local ContentPanel = Instance.new("Frame")
ContentPanel.Name = "ContentPanel"
ContentPanel.Parent = MainFrame
ContentPanel.Position = UDim2.new(0, 145, 0, 0)
ContentPanel.Size = UDim2.new(1, -145, 1, 0)
ContentPanel.BackgroundTransparency = 1

local ContentTitle = Instance.new("TextLabel")
ContentTitle.Parent = ContentPanel
ContentTitle.Size = UDim2.new(1, -15, 0, 40)
ContentTitle.Position = UDim2.new(0, 10, 0, 5)
ContentTitle.BackgroundTransparency = 1
ContentTitle.Text = "Aim Settings"
ContentTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
ContentTitle.TextSize = 16
ContentTitle.Font = Enum.Font.SourceSansBold
ContentTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Warning Banner GUI
local AlertFrame = Instance.new("Frame")
AlertFrame.Name = "AlertFrame"
AlertFrame.Parent = ScreenGui
AlertFrame.AnchorPoint = Vector2.new(0.5, 0)
AlertFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
AlertFrame.Size = UDim2.new(0, 360, 0, 40)
AlertFrame.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
AlertFrame.BorderSizePixel = 0
AlertFrame.Visible = false

local AlertCorner = Instance.new("UICorner")
AlertCorner.CornerRadius = UDim.new(0, 6)
AlertCorner.Parent = AlertFrame

local AlertText = Instance.new("TextLabel")
AlertText.Parent = AlertFrame
AlertText.Size = UDim2.new(1, 0, 1, 0)
AlertText.BackgroundTransparency = 1
AlertText.Text = "⚠️ WARNING: ENEMY BEHIND YOU!"
AlertText.TextColor3 = Color3.fromRGB(255, 255, 255)
AlertText.TextSize = 14
AlertText.Font = Enum.Font.SourceSansBold

-- Tab Content Frames Storage
local tabs = {}
local tabButtons = {}

local function createTabContent(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name .. "Tab"
    scroll.Parent = ContentPanel
    scroll.Position = UDim2.new(0, 10, 0, 45)
    scroll.Size = UDim2.new(1, -20, 1, -55)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.Visible = false

    local layout = Instance.new("UIListLayout")
    layout.Parent = scroll
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)

    tabs[name] = scroll
    return scroll
end

local aimTab = createTabContent("Aim")
local visualsTab = createTabContent("Visuals")
local miscTab = createTabContent("Misc")
local settingsTab = createTabContent("Settings")

local function switchTab(tabName)
    for name, frame in pairs(tabs) do
        frame.Visible = (name == tabName)
    end
    for name, btn in pairs(tabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.TextColor3 = Color3.fromRGB(0, 255, 180)
        else
            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
    ContentTitle.Text = tabName .. " Settings"
end

local function createTabButton(name, iconText)
    local btn = Instance.new("TextButton")
    btn.Parent = TabContainer
    btn.Size = UDim2.new(0.9, 0, 0, 32)
    btn.Position = UDim2.new(0.05, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. iconText .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)

    tabButtons[name] = btn
end

createTabButton("Aim", "🎯")
createTabButton("Visuals", "👁️")
createTabButton("Misc", "📦")
createTabButton("Settings", "⚙️")

-- Toggle UI Keybind (Right Ctrl)
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end))

-- UI Components Helpers
local function createToggle(parent, text, defaultVal, callback)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.Size = UDim2.new(1, -5, 0, 32)
    container.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    container.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Parent = container
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 12
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left

    local switchBg = Instance.new("Frame")
    switchBg.Parent = container
    switchBg.Position = UDim2.new(1, -45, 0.5, -9)
    switchBg.Size = UDim2.new(0, 36, 0, 18)
    switchBg.BackgroundColor3 = defaultVal and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(60, 60, 60)
    switchBg.BorderSizePixel = 0

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Parent = switchBg
    knob.Position = defaultVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local btn = Instance.new("TextButton")
    btn.Parent = container
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""

    local state = defaultVal
    btn.MouseButton1Click:Connect(function()
        state = not state
        switchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(60, 60, 60)
        knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        callback(state)
    end)

    return {
        SetState = function(val)
            state = val
            switchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(60, 60, 60)
            knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        end
    }
end

local function createSelector(parent, text, options, currentIndex, callback)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.Size = UDim2.new(1, -5, 0, 32)
    container.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    container.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Parent = container
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 12
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left

    local optionBtn = Instance.new("TextButton")
    optionBtn.Parent = container
    optionBtn.Position = UDim2.new(0.5, 0, 0.15, 0)
    optionBtn.Size = UDim2.new(0.48, 0, 0.7, 0)
    optionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    optionBtn.BorderSizePixel = 0
    optionBtn.Text = tostring(options[currentIndex])
    optionBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
    optionBtn.TextSize = 11
    optionBtn.Font = Enum.Font.SourceSansBold

    local optCorner = Instance.new("UICorner")
    optCorner.CornerRadius = UDim.new(0, 4)
    optCorner.Parent = optionBtn

    local idx = currentIndex
    optionBtn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        optionBtn.Text = tostring(options[idx])
        callback(idx)
    end)

    return {
        SetIndex = function(newIdx)
            idx = newIdx
            optionBtn.Text = tostring(options[idx])
        end
    }
end

local function createActionButton(parent, text, bgColor, callback)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.Size = UDim2.new(1, -5, 0, 32)
    container.BackgroundColor3 = bgColor or Color3.fromRGB(35, 35, 35)
    container.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local btn = Instance.new("TextButton")
    btn.Parent = container
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansBold

    btn.MouseButton1Click:Connect(callback)
end

-- FOV Circle
local fovFrame = Instance.new("Frame")
fovFrame.Parent = ScreenGui
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.Size = UDim2.new(0, fovSizes[Config.fovIndex] * 2, 0, fovSizes[Config.fovIndex] * 2)
fovFrame.BackgroundTransparency = 1
fovFrame.Visible = false

local fovStroke = Instance.new("UIStroke")
fovStroke.Parent = fovFrame
fovStroke.Color = Color3.fromRGB(0, 255, 200)
fovStroke.Thickness = 1.5

local fovCorner = Instance.new("UICorner")
fovCorner.Parent = fovFrame
fovCorner.CornerRadius = UDim.new(1, 0)

-- Helper Functions
local function getRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head") or character.PrimaryPart
end

local function getTargetPart(character)
    if not character then return nil end
    local partName = targetParts[Config.targetPartIndex]
    return character:FindFirstChild(partName) or getRootPart(character)
end

local function isEnemy(player)
    if not Config.teamCheckEnabled then return true end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function isVisible(targetPart)
    if not Config.wallCheckEnabled then return true end
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = destination - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local ignoreList = {Camera}
    if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
    raycastParams.FilterDescendantsInstances = ignoreList

    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        if result.Instance:IsDescendantOf(targetPart.Parent) then return true end
        return false
    end
    return true
end

local function isValidTarget(player)
    if not player or player == LocalPlayer or not player.Character then return false end
    if not isEnemy(player) then return false end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local targetPart = getTargetPart(player.Character)
    if humanoid and humanoid.Health > 0 and targetPart then
        return true
    end
    return false
end

-- ESP System
local function applyESP(player)
    if player == LocalPlayer then return end

    local function setupChar(char)
        if not char or not scriptRunning then return end
        local rootPart = getRootPart(char) or char:WaitForChild("HumanoidRootPart", 5) or char:WaitForChild("Head", 5)
        if not rootPart then return end

        local highlight = char:FindFirstChild("ESPHighlight") or Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.Adornee = char
        highlight.FillColor = Color3.fromRGB(255, 30, 30)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Enabled = Config.espEnabled and isEnemy(player)
        highlight.Parent = char

        if rootPart:FindFirstChild("ESPBillboard") then rootPart.ESPBillboard:Destroy() end
        local bgui = Instance.new("BillboardGui")
        bgui.Name = "ESPBillboard"
        bgui.Adornee = rootPart
        bgui.Size = UDim2.new(0, 180, 0, 25)
        bgui.StudsOffset = Vector3.new(0, 3.5, 0)
        bgui.AlwaysOnTop = true
        bgui.Enabled = Config.espEnabled and isEnemy(player)
        bgui.Parent = rootPart

        local txt = Instance.new("TextLabel")
        txt.Name = "ESPText"
        txt.Parent = bgui
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = "[ " .. player.Name .. " ]"
        txt.TextColor3 = Color3.fromRGB(255, 50, 50)
        txt.TextStrokeTransparency = 0
        txt.TextSize = 12
        txt.Font = Enum.Font.SourceSansBold

        if rootPart:FindFirstChild("BoxESPBillboard") then rootPart.BoxESPBillboard:Destroy() end
        local boxGui = Instance.new("BillboardGui")
        boxGui.Name = "BoxESPBillboard"
        boxGui.Adornee = rootPart
        boxGui.Size = UDim2.new(4.5, 0, 6, 0)
        boxGui.AlwaysOnTop = true
        boxGui.Enabled = Config.espEnabled and isEnemy(player)
        boxGui.Parent = rootPart

        local boxFrame = Instance.new("Frame")
        boxFrame.Parent = boxGui
        boxFrame.Size = UDim2.new(1, 0, 1, 0)
        boxFrame.BackgroundTransparency = 1

        local stroke = Instance.new("UIStroke")
        stroke.Parent = boxFrame
        stroke.Color = Color3.fromRGB(255, 30, 30)
        stroke.Thickness = 1.5
    end

    if player.Character then task.spawn(setupChar, player.Character) end
    table.insert(connections, player.CharacterAdded:Connect(function(char) task.spawn(setupChar, char) end))
end

for _, p in pairs(Players:GetPlayers()) do applyESP(p) end
table.insert(connections, Players.PlayerAdded:Connect(applyESP))

-- ESP Update Loop
task.spawn(function()
    while scriptRunning do
        task.wait(0.1)
        if LocalPlayer.Character then
            local myRoot = getRootPart(LocalPlayer.Character)
            if myRoot then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local targetRoot = getRootPart(player.Character)
                        if targetRoot then
                            local bgui = targetRoot:FindFirstChild("ESPBillboard")
                            local boxGui = targetRoot:FindFirstChild("BoxESPBillboard")
                            local highlight = player.Character:FindFirstChild("ESPHighlight")

                            local shouldShow = Config.espEnabled and isEnemy(player)

                            if bgui then bgui.Enabled = shouldShow end
                            if boxGui then boxGui.Enabled = shouldShow end
                            if highlight then highlight.Enabled = shouldShow end

                            if shouldShow and bgui then
                                local txt = bgui:FindFirstChild("ESPText")
                                if txt then
                                    local dist = math.floor((myRoot.Position - targetRoot.Position).Magnitude)
                                    txt.Text = "[ " .. player.Name .. " ] [ " .. tostring(dist) .. "m ]"
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Head Hitbox Expansion
local function resetHitboxes()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                pcall(function()
                    head.Size = Vector3.new(1.2, 1.2, 1.2)
                    head.Transparency = 0
                    head.CanCollide = false
                end)
            end
        end
    end
end

local function updateHitboxes()
    if not Config.hitboxExpanded or not scriptRunning then return end
    local currentSize = hitboxSizes[Config.hitboxIndex]
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isEnemy(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                pcall(function()
                    head.Size = Vector3.new(currentSize, currentSize, currentSize)
                    head.Transparency = 0.5
                    head.CanCollide = false
                    head.Massless = true
                end)
            end
        end
    end
end

table.insert(connections, RunService.RenderStepped:Connect(function()
    if Config.hitboxExpanded then
        updateHitboxes()
    end
end))

-- Aim & No Bullet Drop Calculations
local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local radius = fovSizes[Config.fovIndex]
    local shortestDistance = Config.fovEnabled and radius or 999999
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local targetPart = getTargetPart(player.Character)
            if targetPart and isVisible(targetPart) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

table.insert(connections, RunService.RenderStepped:Connect(function()
    if not scriptRunning then return end
    
    -- เช็คว่าตัวเราตายอยู่หรือไม่ (ถ้าตายจะไม่ให้ทำงาน)
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            return
        end
    end

    local currentFovRadius = fovSizes[Config.fovIndex]
    fovFrame.Size = UDim2.new(0, currentFovRadius * 2, 0, currentFovRadius * 2)
    fovFrame.Visible = Config.fovEnabled

    local isHolding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

    if Config.aimbotEnabled and isHolding then
        if not stickyTarget or not isValidTarget(stickyTarget) or not isVisible(getTargetPart(stickyTarget.Character)) then
            stickyTarget = getClosestPlayerToMouse()
        end

        if stickyTarget and isValidTarget(stickyTarget) then
            local targetPart = getTargetPart(stickyTarget.Character)
            if targetPart then
                local targetPos = targetPart.Position
                local predictedPos = targetPos

                if not Config.noBulletDrop then
                    local velocity = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.new(0,0,0)
                    local distance = (targetPos - Camera.CFrame.Position).Magnitude
                    local leadFactor = leadMultipliers[Config.leadIndex]
                    local timeToHit = (distance / 2500) * leadFactor
                    predictedPos = targetPos + (velocity * timeToHit)
                end

                local smoothness = smoothnessLevels[Config.smoothIndex]
                local mode = aimModes[Config.aimModeIndex]

                if mode == "Smooth Cam" then
                    local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, predictedPos)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothness)
                elseif mode == "Hard Lock" then
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, predictedPos)
                elseif mode == "Mouse Delta" then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local deltaX = (screenPos.X - mousePos.X) * smoothness
                        local deltaY = (screenPos.Y - mousePos.Y) * smoothness
                        if mousemoverel then
                            mousemoverel(deltaX, deltaY)
                        else
                            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, predictedPos), smoothness)
                        end
                    end
                end
            end
        end
    else
        stickyTarget = nil
    end
end))

-- 1. Auto Heal Logic (ปั้มยาออโต้ - เพิ่มเช็คสถานะตาย)
local isHealing = false
local function sendKeyPress(keyCode)
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

task.spawn(function()
    while scriptRunning do
        task.wait(0.1)
        if Config.autoHealEnabled and not isHealing and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            -- ตรวจสอบว่าเลือดยังมากกว่า 0 และไม่ตาย
            if humanoid and humanoid.Health > 0 then
                local maxHealth = humanoid.MaxHealth
                local currentHealth = humanoid.Health
                local healthPercent = (currentHealth / maxHealth) * 100

                if healthPercent <= 85 and healthPercent > 3 then
                    isHealing = true
                    
                    sendKeyPress(Enum.KeyCode.Three)
                    task.wait(0.1)
                    sendKeyPress(Enum.KeyCode.Three)
                    task.wait(0.1)
                    sendKeyPress(Enum.KeyCode.One)

                    task.wait(2)
                    isHealing = false
                end
            else
                -- ถ้าตายให้รีเซ็ตสถานะการปั้มยาทันที
                isHealing = false
            end
        end
    end
end)

-- 2. Back Proximity Alert Logic (สัญญาณเตือนศัตรูข้างหลัง - เพิ่มเช็คสถานะตาย)
local lastAlertTime = 0
task.spawn(function()
    while scriptRunning do
        task.wait(0.2)
        local isAlive = false
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                isAlive = true
            end
        end

        if Config.backAlertEnabled and isAlive then
            local myRoot = getRootPart(LocalPlayer.Character)
            if myRoot then
                local myCFrame = myRoot.CFrame
                local detectedBehind = false
                local enemyName = ""
                local enemyDist = 0

                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and isEnemy(player) then
                        local targetRoot = getRootPart(player.Character)
                        if targetRoot then
                            local distance = (targetRoot.Position - myRoot.Position).Magnitude
                            
                            if distance <= 65.6 then
                                local relativePos = myCFrame:PointToObjectSpace(targetRoot.Position)
                                if relativePos.Z > 0 then
                                    detectedBehind = true
                                    enemyName = player.Name
                                    enemyDist = math.floor(distance / 3.28084)
                                    break
                                end
                            end
                        end
                    end
                end

                if detectedBehind then
                    AlertText.Text = "⚠️ WARNING: " .. enemyName .. " IS BEHIND YOU! (" .. tostring(enemyDist) .. "m)"
                    AlertFrame.Visible = true
                    lastAlertTime = tick()
                else
                    if tick() - lastAlertTime >= 3 then
                        AlertFrame.Visible = false
                    end
                end
            end
        else
            AlertFrame.Visible = false
        end
    end
end)

-- Instant Pickup
table.insert(connections, ProximityPromptService.PromptShown:Connect(function(prompt)
    if Config.instantPickupEnabled then prompt.HoldDuration = 0 end
end))

-- Full Unload Script Function
local function unloadScript()
    scriptRunning = false

    for _, conn in pairs(connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    table.clear(connections)

    resetHitboxes()

    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("ESPHighlight")
            if highlight then highlight:Destroy() end

            local root = getRootPart(player.Character)
            if root then
                if root:FindFirstChild("ESPBillboard") then root.ESPBillboard:Destroy() end
                if root:FindFirstChild("BoxESPBillboard") then root.BoxESPBillboard:Destroy() end
            end
        end
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

    print("[Syrex Hub] Script Unloaded Successfully!")
end

-- Populate UI Controls
local aimbotToggle = createToggle(aimTab, "Aimbot (ล็อกเป้า)", Config.aimbotEnabled, function(v) Config.aimbotEnabled = v end)
local noDropToggle = createToggle(aimTab, "No Bullet Drop (กระสุนยิงตรง/ไม่ย้อย)", Config.noBulletDrop, function(v) Config.noBulletDrop = v end)
local aimModeSel = createSelector(aimTab, "Aim Mode", aimModes, Config.aimModeIndex, function(v) Config.aimModeIndex = v end)
local smoothSel = createSelector(aimTab, "Aim Speed / Smooth", smoothnessLevels, Config.smoothIndex, function(v) Config.smoothIndex = v end)
local wallToggle = createToggle(aimTab, "Wall Check (เช็คกำแพง)", Config.wallCheckEnabled, function(v) Config.wallCheckEnabled = v end)
local targetSel = createSelector(aimTab, "Target Part", targetPartNames, Config.targetPartIndex, function(v) Config.targetPartIndex = v end)
local leadSel = createSelector(aimTab, "Lead Prediction", leadMultipliers, Config.leadIndex, function(v) Config.leadIndex = v end)
local fovToggle = createToggle(aimTab, "FOV Circle", Config.fovEnabled, function(v) Config.fovEnabled = v end)
local fovSel = createSelector(aimTab, "FOV Size (px)", fovSizes, Config.fovIndex, function(v) Config.fovIndex = v end)

local espToggle = createToggle(visualsTab, "Player ESP (มองทะลุ)", Config.espEnabled, function(v) Config.espEnabled = v end)
local teamToggle = createToggle(visualsTab, "Team Check (เฉพาะศัตรู)", Config.teamCheckEnabled, function(v) Config.teamCheckEnabled = v end)

local autoHealToggle = createToggle(miscTab, "Auto Heal (ปั้มยาออโต้)", Config.autoHealEnabled, function(v) Config.autoHealEnabled = v end)
local backAlertToggle = createToggle(miscTab, "Back Alert 20M (เตือนคนข้างหลัง)", Config.backAlertEnabled, function(v) Config.backAlertEnabled = v end)
local hitboxToggle = createToggle(miscTab, "Expand Head Hitbox (ขยายหัว)", Config.hitboxExpanded, function(v) 
    Config.hitboxExpanded = v 
    if not v then resetHitboxes() end
end)
local hitboxSel = createSelector(miscTab, "Hitbox Size (studs)", hitboxSizes, Config.hitboxIndex, function(v) 
    Config.hitboxIndex = v 
end)
local pickupToggle = createToggle(miscTab, "Instant Pickup (เก็บของไว)", Config.instantPickupEnabled, function(v) Config.instantPickupEnabled = v end)

createActionButton(settingsTab, "💾 Save Config (บันทึกการตั้งค่า)", Color3.fromRGB(35, 35, 35), function()
    if writefile then
        local json = HttpService:JSONEncode(Config)
        writefile(configFileName, json)
        print("[Syrex Hub] Config Saved!")
    end
end)

createActionButton(settingsTab, "📁 Load Config (โหลดการตั้งค่า)", Color3.fromRGB(35, 35, 35), function()
    if isfile and isfile(configFileName) and readfile then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(configFileName))
        end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                if Config[k] ~= nil then Config[k] = v end
            end
            aimbotToggle.SetState(Config.aimbotEnabled)
            noDropToggle.SetState(Config.noBulletDrop)
            aimModeSel.SetIndex(Config.aimModeIndex)
            smoothSel.SetIndex(Config.smoothIndex)
            wallToggle.SetState(Config.wallCheckEnabled)
            targetSel.SetIndex(Config.targetPartIndex)
            leadSel.SetIndex(Config.leadIndex)
            fovToggle.SetState(Config.fovEnabled)
            fovSel.SetIndex(Config.fovIndex)

            espToggle.SetState(Config.espEnabled)
            teamToggle.SetState(Config.teamCheckEnabled)

            autoHealToggle.SetState(Config.autoHealEnabled)
            backAlertToggle.SetState(Config.backAlertEnabled)
            hitboxToggle.SetState(Config.hitboxExpanded)
            hitboxSel.SetIndex(Config.hitboxIndex)
            pickupToggle.SetState(Config.instantPickupEnabled)

            if not Config.hitboxExpanded then resetHitboxes() end
            print("[Syrex Hub] Config Loaded Successfully!")
        end
    end
end)

createActionButton(settingsTab, "🔴 Unload Script (ปิดการทำงานสคริปต์ทั้งหมด)", Color3.fromRGB(150, 30, 30), function()
    unloadScript()
end)

switchTab("Aim")
