-- Syrex Hub Ultimate V36 (Clean UI + Fixed Aim Engine)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Config Values
local espEnabled = true
local espBoxEnabled = true
local teamCheckEnabled = false
local aimbotEnabled = true
local wallCheckEnabled = false
local fovEnabled = true
local recoilControlEnabled = true

-- Aim Settings
local aimKeysList = {"Always On", "Right Click", "Left Click", "Left Shift", "E Key"}
local currentAimKeyIndex = 1
local selectedAimKey = aimKeysList[currentAimKeyIndex]

local isAimingState = true

local aimModes = {"Direct CFrame", "Smooth Cam", "Mouse Delta"}
local currentAimModeIndex = 1
local aimMode = aimModes[currentAimModeIndex]

local smoothnessLevels = {0.1, 0.25, 0.5, 0.75, 1.0}
local currentSmoothIndex = 3
local aimSmoothness = smoothnessLevels[currentSmoothIndex]

local fovRadius = 180
local fovSizes = {80, 120, 160, 220, 300, 400}
local currentFovIndex = 3

local targetParts = {"Head", "HumanoidRootPart", "UpperTorso"}
local currentTargetIndex = 1
local targetPartName = targetParts[currentTargetIndex]

-- Clean Old UI
local parentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if parentGui:FindFirstChild("SyrexHub_v36") then
    parentGui:FindFirstChild("SyrexHub_v36"):Destroy()
end

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyrexHub_v36"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

-- Main Container Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 520, 0, 380)
MainFrame.Active = true
MainFrame.Draggable = true

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = MainFrame

-- Sidebar Layout
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BorderSizePixel = 0

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 8)
sidebarCorner.Parent = Sidebar

local HubTitle = Instance.new("TextLabel")
HubTitle.Parent = Sidebar
HubTitle.Size = UDim2.new(1, -20, 0, 40)
HubTitle.Position = UDim2.new(0, 10, 0, 10)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "SYREX HUB"
HubTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HubTitle.TextSize = 15
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel")
SubTitle.Parent = HubTitle
SubTitle.Size = UDim2.new(1, 0, 0, 15)
SubTitle.Position = UDim2.new(0, 0, 0, 20)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "v36 • [Right-Ctrl]"
SubTitle.TextColor3 = Color3.fromRGB(120, 120, 130)
SubTitle.TextSize = 10
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

local TabList = Instance.new("Frame")
TabList.Parent = Sidebar
TabList.Position = UDim2.new(0, 10, 0, 60)
TabList.Size = UDim2.new(1, -20, 1, -70)
TabList.BackgroundTransparency = 1

local tabLayout = Instance.new("UIListLayout")
tabLayout.Parent = TabList
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 6)

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Parent = MainFrame
ContentArea.Position = UDim2.new(0, 150, 0, 10)
ContentArea.Size = UDim2.new(1, -160, 1, -20)
ContentArea.BackgroundTransparency = 1

local pages = {}

local function createPage(pageName)
    local page = Instance.new("ScrollingFrame")
    page.Name = pageName .. "Page"
    page.Parent = ContentArea
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    page.Visible = false

    local layout = Instance.new("UIListLayout")
    layout.Parent = page
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)

    local padding = Instance.new("UIPadding")
    padding.Parent = page
    padding.PaddingRight = UDim.new(0, 6)

    pages[pageName] = page
    return page
end

local function addTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Parent = TabList
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 190)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        for pName, pFrame in pairs(pages) do
            pFrame.Visible = (pName == name)
        end
        for _, child in pairs(TabList:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                child.TextColor3 = Color3.fromRGB(180, 180, 190)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    return btn
end

-- UI Controls
local function addToggle(page, labelText, defaultState, callback)
    local container = Instance.new("Frame")
    container.Parent = page
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = container

    local title = Instance.new("TextLabel")
    title.Parent = container
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = labelText
    title.TextColor3 = Color3.fromRGB(220, 220, 230)
    title.TextSize = 11
    title.Font = Enum.Font.Gotham
    title.TextXAlignment = Enum.TextXAlignment.Left

    local switchBg = Instance.new("Frame")
    switchBg.Parent = container
    switchBg.Position = UDim2.new(1, -45, 0.5, -9)
    switchBg.Size = UDim2.new(0, 34, 0, 18)
    switchBg.BackgroundColor3 = defaultState and Color3.fromRGB(0, 220, 255) or Color3.fromRGB(50, 50, 60)

    local swCorner = Instance.new("UICorner")
    swCorner.CornerRadius = UDim.new(1, 0)
    swCorner.Parent = switchBg

    local dot = Instance.new("Frame")
    dot.Parent = switchBg
    dot.Position = defaultState and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.BackgroundColor3 = defaultState and Color3.fromRGB(15, 15, 20) or Color3.fromRGB(180, 180, 190)

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    local state = defaultState
    local btn = Instance.new("TextButton")
    btn.Parent = container
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""

    local function updateVisuals(st)
        if st then
            TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 220, 255)}):Play()
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(1, -15, 0.5, -6), BackgroundColor3 = Color3.fromRGB(15, 15, 20)}):Play()
        else
            TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = Color3.fromRGB(180, 180, 190)}):Play()
        end
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisuals(state)
        callback(state)
    end)
end

local function addClicker(page, labelText, defaultValText, callback)
    local container = Instance.new("Frame")
    container.Parent = page
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = container

    local title = Instance.new("TextLabel")
    title.Parent = container
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = labelText
    title.TextColor3 = Color3.fromRGB(220, 220, 230)
    title.TextSize = 11
    title.Font = Enum.Font.Gotham
    title.TextXAlignment = Enum.TextXAlignment.Left

    local valBox = Instance.new("TextLabel")
    valBox.Parent = container
    valBox.Position = UDim2.new(1, -120, 0.5, -10)
    valBox.Size = UDim2.new(0, 110, 0, 20)
    valBox.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    valBox.Text = defaultValText
    valBox.TextColor3 = Color3.fromRGB(0, 220, 255)
    valBox.TextSize = 10
    valBox.Font = Enum.Font.GothamBold

    local vCorner = Instance.new("UICorner")
    vCorner.CornerRadius = UDim.new(0, 4)
    vCorner.Parent = valBox

    local btn = Instance.new("TextButton")
    btn.Parent = container
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""

    btn.MouseButton1Click:Connect(function()
        local newVal = callback()
        if newVal then valBox.Text = newVal end
    end)
end

-- Create Pages
local aimPage = createPage("Aim")
local visualsPage = createPage("Visuals")
local gunPage = createPage("Gun Mods")

local aimTab = addTab("Aim", "🎯")
local visualsTab = addTab("Visuals", "👁️")
local gunTab = addTab("Gun Mods", "🔫")

-- Build Aim Page
addToggle(aimPage, "Aimbot Master Lock", aimbotEnabled, function(s) aimbotEnabled = s end)
addClicker(aimPage, "Aim Key (ปุ่มเล็ง)", selectedAimKey, function()
    currentAimKeyIndex = currentAimKeyIndex + 1
    if currentAimKeyIndex > #aimKeysList then currentAimKeyIndex = 1 end
    selectedAimKey = aimKeysList[currentAimKeyIndex]
    isAimingState = (selectedAimKey == "Always On")
    return selectedAimKey
end)
addClicker(aimPage, "Aim Mode", aimMode, function()
    currentAimModeIndex = currentAimModeIndex + 1
    if currentAimModeIndex > #aimModes then currentAimModeIndex = 1 end
    aimMode = aimModes[currentAimModeIndex]
    return aimMode
end)
addClicker(aimPage, "Aim Smoothness", tostring(aimSmoothness), function()
    currentSmoothIndex = currentSmoothIndex + 1
    if currentSmoothIndex > #smoothnessLevels then currentSmoothIndex = 1 end
    aimSmoothness = smoothnessLevels[currentSmoothIndex]
    return tostring(aimSmoothness)
end)
addToggle(aimPage, "Wall Check (ไม่ยิงหลังกำแพง)", wallCheckEnabled, function(s) wallCheckEnabled = s end)
addToggle(aimPage, "Team Check (ไม่ล็อกพวกเดียวกัน)", teamCheckEnabled, function(s) teamCheckEnabled = s end)
addClicker(aimPage, "Target Part", targetPartName, function()
    currentTargetIndex = currentTargetIndex + 1
    if currentTargetIndex > #targetParts then currentTargetIndex = 1 end
    targetPartName = targetParts[currentTargetIndex]
    return targetPartName
end)
addToggle(aimPage, "FOV Circle", fovEnabled, function(s) fovEnabled = s end)
addClicker(aimPage, "FOV Radius (px)", tostring(fovRadius) .. " px", function()
    currentFovIndex = currentFovIndex + 1
    if currentFovIndex > #fovSizes then currentFovIndex = 1 end
    fovRadius = fovSizes[currentFovIndex]
    return tostring(fovRadius) .. " px"
end)

-- Build Visuals Page
addToggle(visualsPage, "Player ESP (ชื่อ)", espEnabled, function(s) espEnabled = s end)
addToggle(visualsPage, "2D Box ESP (กรอบตัวศัตรู)", espBoxEnabled, function(s) espBoxEnabled = s end)

-- Build Gun Mods Page
addToggle(gunPage, "No Recoil / Anti Shake", recoilControlEnabled, function(s) recoilControlEnabled = s end)

-- Default Tab
aimPage.Visible = true
aimTab.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
aimTab.TextColor3 = Color3.fromRGB(255, 255, 255)

-- UI Toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Aim Key Logic
local function isAimInput(input)
    if selectedAimKey == "Always On" then return true end
    if selectedAimKey == "Right Click" and input.UserInputType == Enum.UserInputType.MouseButton2 then return true end
    if selectedAimKey == "Left Click" and input.UserInputType == Enum.UserInputType.MouseButton1 then return true end
    if selectedAimKey == "Left Shift" and input.KeyCode == Enum.KeyCode.LeftShift then return true end
    if selectedAimKey == "E Key" and input.KeyCode == Enum.KeyCode.E then return true end
    return false
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if isAimInput(input) and selectedAimKey ~= "Always On" then
        isAimingState = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if isAimInput(input) and selectedAimKey ~= "Always On" then
        isAimingState = false
    end
end)

-- FOV Circle Visual
local fovFrame = Instance.new("Frame")
fovFrame.Parent = ScreenGui
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
fovFrame.BackgroundTransparency = 1
fovFrame.Visible = false

local fovStroke = Instance.new("UIStroke")
fovStroke.Parent = fovFrame
fovStroke.Color = Color3.fromRGB(0, 220, 255)
fovStroke.Thickness = 1.5

local fovCorner = Instance.new("UICorner")
fovCorner.Parent = fovFrame
fovCorner.CornerRadius = UDim.new(1, 0)

-- Core Helpers
local function getRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso") or character.PrimaryPart
end

local function getTargetPart(character)
    if not character then return nil end
    return character:FindFirstChild(targetPartName) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
end

local function isEnemy(player)
    if not teamCheckEnabled then return true end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
    return true
end

local function isVisible(targetPart)
    if not wallCheckEnabled then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local ignoreList = {Camera}
    if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
    raycastParams.FilterDescendantsInstances = ignoreList

    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then return result.Instance:IsDescendantOf(targetPart.Parent) end
    return true
end

local function isValidTarget(player)
    if not player or player == LocalPlayer or not player.Character then return false end
    if not isEnemy(player) then return false end
    local targetPart = getTargetPart(player.Character)
    if not targetPart then return false end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then return false end

    return true
end

-- CLEAN ESP (NAMES & BOXES ONLY)
local function applyESP(player)
    if player == LocalPlayer then return end

    local function setupChar(char)
        if not char then return end
        local rootPart = getRootPart(char) or char:WaitForChild("HumanoidRootPart", 5) or char:WaitForChild("Head", 5)
        if not rootPart then return end

        if rootPart:FindFirstChild("ESPBillboard") then rootPart.ESPBillboard:Destroy() end
        local bgui = Instance.new("BillboardGui")
        bgui.Name = "ESPBillboard"
        bgui.Adornee = rootPart
        bgui.Size = UDim2.new(0, 140, 0, 20)
        bgui.StudsOffset = Vector3.new(0, 3.2, 0)
        bgui.AlwaysOnTop = true
        bgui.Parent = rootPart

        local txt = Instance.new("TextLabel")
        txt.Name = "ESPText"
        txt.Parent = bgui
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = player.Name
        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        txt.TextStrokeTransparency = 0
        txt.TextSize = 11
        txt.Font = Enum.Font.GothamBold

        if rootPart:FindFirstChild("BoxESPBillboard") then rootPart.BoxESPBillboard:Destroy() end
        local boxBillboard = Instance.new("BillboardGui")
        boxBillboard.Name = "BoxESPBillboard"
        boxBillboard.Adornee = rootPart
        boxBillboard.Size = UDim2.new(4.5, 0, 6, 0)
        boxBillboard.AlwaysOnTop = true
        boxBillboard.Parent = rootPart

        local boxFrame = Instance.new("Frame")
        boxFrame.Parent = boxBillboard
        boxFrame.Size = UDim2.new(1, 0, 1, 0)
        boxFrame.BackgroundTransparency = 1

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Parent = boxFrame
        boxStroke.Color = Color3.fromRGB(255, 50, 50)
        boxStroke.Thickness = 1.8
    end

    if player.Character then task.spawn(setupChar, player.Character) end
    player.CharacterAdded:Connect(function(char) task.spawn(setupChar, char) end)
end

for _, p in pairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

-- Sync ESP Visibility
task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local targetRoot = getRootPart(player.Character)
                    if targetRoot then
                        local espBgui = targetRoot:FindFirstChild("ESPBillboard")
                        local boxEsp = targetRoot:FindFirstChild("BoxESPBillboard")
                        local isTargetEnemy = isEnemy(player)

                        if espBgui then espBgui.Enabled = espEnabled and isTargetEnemy end
                        if boxEsp then boxEsp.Enabled = espBoxEnabled and isTargetEnemy end
                    end
                end
            end
        end)
    end
end)

-- AIMBOT TARGET LOCATOR
local function getClosestPlayerToMouse()
    local closestTarget = nil
    local shortestDistance = fovEnabled and fovRadius or 99999
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local targetPart = getTargetPart(player.Character)
            if targetPart and isVisible(targetPart) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestTarget = {player = player, part = targetPart}
                    end
                end
            end
        end
    end
    return closestTarget
end

-- DIRECT RENDERSTEPPED AIM LOCK ENGINE
RunService.RenderStepped:Connect(function()
    -- FOV Circle Position & Size Update
    fovFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    fovFrame.Visible = fovEnabled

    -- No Recoil
    if recoilControlEnabled then
        Camera.RotVelocity = Vector3.new(0, 0, 0)
    end

    -- Aim Engine
    local activeAiming = (selectedAimKey == "Always On") or isAimingState

    if aimbotEnabled and activeAiming then
        local targetData = getClosestPlayerToMouse()
        if targetData and targetData.part then
            local targetPos = targetData.part.Position
            local currentCamPos = Camera.CFrame.Position

            if aimMode == "Direct CFrame" then
                Camera.CFrame = CFrame.new(currentCamPos, targetPos)
            elseif aimMode == "Smooth Cam" then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(currentCamPos, targetPos), aimSmoothness)
            elseif aimMode == "Mouse Delta" then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local deltaX = (screenPos.X - mousePos.X) * aimSmoothness
                    local deltaY = (screenPos.Y - mousePos.Y) * aimSmoothness
                    if mousemoverel then
                        mousemoverel(deltaX, deltaY)
                    else
                        Camera.CFrame = CFrame.new(currentCamPos, targetPos)
                    end
                end
            end
        end
    end
end)
