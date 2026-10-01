-- Syrex Hub Ultimate V30 (Fixed Aim + Realtime Target Gear HUD)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Config Values
local espEnabled = true
local inspectEnabled = true
local gearHudEnabled = true -- ระบบโชว์ไอเทมเรียลไทม์ใต้ตัวศัตรู
local teamCheckEnabled = false
local aimbotEnabled = true
local wallCheckEnabled = false -- ปิดไว้เป็นค่าเริ่มต้นเพื่อป้องกันปัญหาล็อคไม่ได้
local fovEnabled = true
local instantPickupEnabled = false
local hitboxExpanded = false
local recoilControlEnabled = true

-- Settings Data
local hitboxSizes = {4, 7, 10, 15}
local currentHitboxIndex = 2
local hitboxSize = hitboxSizes[currentHitboxIndex]

local aimModes = {"Smooth Cam", "Hard Lock", "Mouse Delta"}
local currentAimModeIndex = 1
local aimMode = aimModes[currentAimModeIndex]

local smoothnessLevels = {0.1, 0.25, 0.5, 0.8, 1.0}
local currentSmoothIndex = 2
local aimSmoothness = smoothnessLevels[currentSmoothIndex]

local fovRadius = 140
local fovSizes = {60, 100, 140, 180, 240, 300}
local currentFovIndex = 3

local targetParts = {"Head", "HumanoidRootPart"}
local currentTargetIndex = 1
local targetPartName = targetParts[currentTargetIndex]

local leadMultipliers = {0, 0.5, 1.0, 1.5, 2.0}
local currentLeadIndex = 1
local leadFactor = leadMultipliers[currentLeadIndex]

local stickyTarget = nil
local configFileName = "SyrexHub_Config.json"

-- Clean Old UI
local parentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if parentGui:FindFirstChild("SyrexHub_v30") then
    parentGui:FindFirstChild("SyrexHub_v30"):Destroy()
end

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyrexHub_v30"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

-- Main Container Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.3, 0, 0.22, 0)
MainFrame.Size = UDim2.new(0, 580, 0, 410)
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
Sidebar.Size = UDim2.new(0, 160, 1, 0)
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
HubTitle.TextSize = 16
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel")
SubTitle.Parent = HubTitle
SubTitle.Size = UDim2.new(1, 0, 0, 15)
SubTitle.Position = UDim2.new(0, 0, 0, 22)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "v30 • [Right-Ctrl Toggle]"
SubTitle.TextColor3 = Color3.fromRGB(120, 120, 130)
SubTitle.TextSize = 10
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

local TabList = Instance.new("Frame")
TabList.Parent = Sidebar
TabList.Position = UDim2.new(0, 10, 0, 65)
TabList.Size = UDim2.new(1, -20, 1, -80)
TabList.BackgroundTransparency = 1

local tabLayout = Instance.new("UIListLayout")
tabLayout.Parent = TabList
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 6)

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Parent = MainFrame
ContentArea.Position = UDim2.new(0, 170, 0, 10)
ContentArea.Size = UDim2.new(1, -180, 1, -20)
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
    btn.Text = "   " .. icon .. "   " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 190)
    btn.TextSize = 12
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

-- Custom UI Controls
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
    title.TextSize = 12
    title.Font = Enum.Font.Gotham
    title.TextXAlignment = Enum.TextXAlignment.Left

    local switchBg = Instance.new("Frame")
    switchBg.Parent = container
    switchBg.Position = UDim2.new(1, -50, 0.5, -10)
    switchBg.Size = UDim2.new(0, 38, 0, 20)
    switchBg.BackgroundColor3 = defaultState and Color3.fromRGB(0, 220, 255) or Color3.fromRGB(50, 50, 60)

    local swCorner = Instance.new("UICorner")
    swCorner.CornerRadius = UDim.new(1, 0)
    swCorner.Parent = switchBg

    local dot = Instance.new("Frame")
    dot.Parent = switchBg
    dot.Position = defaultState and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    dot.Size = UDim2.new(0, 14, 0, 14)
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
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(1, -18, 0.5, -7), BackgroundColor3 = Color3.fromRGB(15, 15, 20)}):Play()
        else
            TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = Color3.fromRGB(180, 180, 190)}):Play()
        end
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisuals(state)
        callback(state)
    end)
    return function(newState)
        state = newState
        updateVisuals(state)
    end
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
    title.TextSize = 12
    title.Font = Enum.Font.Gotham
    title.TextXAlignment = Enum.TextXAlignment.Left

    local valBox = Instance.new("TextLabel")
    valBox.Parent = container
    valBox.Position = UDim2.new(1, -130, 0.5, -11)
    valBox.Size = UDim2.new(0, 120, 0, 22)
    valBox.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    valBox.Text = defaultValText
    valBox.TextColor3 = Color3.fromRGB(0, 220, 255)
    valBox.TextSize = 11
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
    return function(txt) valBox.Text = txt end
end

local function addButton(page, btnText, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = page
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = btnText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
end

-- Initialize Pages
local aimPage = createPage("Aim")
local visualsPage = createPage("Visuals")
local gunPage = createPage("Gun Mods")
local miscPage = createPage("Misc & Config")

local aimTab = addTab("Aim", "🎯")
local visualsTab = addTab("Visuals", "👁️")
local gunTab = addTab("Gun Mods", "🔫")
local miscTab = addTab("Misc & Config", "⚙️")

-- Build Aim Page
addToggle(aimPage, "Aimbot Lock (คลิกขวาถือล็อก)", aimbotEnabled, function(s) aimbotEnabled = s end)
addToggle(aimPage, "Wall Check (ไม่ยิงทะลุกำแพง)", wallCheckEnabled, function(s) wallCheckEnabled = s end)
addToggle(aimPage, "Team Check (ไม่ล็อกพวกเดียวกัน)", teamCheckEnabled, function(s) teamCheckEnabled = s end)
addClicker(aimPage, "Target Part", targetPartName, function()
    currentTargetIndex = currentTargetIndex + 1
    if currentTargetIndex > #targetParts then currentTargetIndex = 1 end
    targetPartName = targetParts[currentTargetIndex]
    return targetPartName
end)
addClicker(aimPage, "Aim Mode", aimMode, function()
    currentAimModeIndex = currentAimModeIndex + 1
    if currentAimModeIndex > #aimModes then currentAimModeIndex = 1 end
    aimMode = aimModes[currentAimModeIndex]
    return aimMode
end)
addClicker(aimPage, "Aim Speed / Smoothness", tostring(aimSmoothness), function()
    currentSmoothIndex = currentSmoothIndex + 1
    if currentSmoothIndex > #smoothnessLevels then currentSmoothIndex = 1 end
    aimSmoothness = smoothnessLevels[currentSmoothIndex]
    return tostring(aimSmoothness)
end)
addToggle(aimPage, "FOV Circle", fovEnabled, function(s) fovEnabled = s end)
addClicker(aimPage, "FOV Radius (px)", tostring(fovRadius) .. " px", function()
    currentFovIndex = currentFovIndex + 1
    if currentFovIndex > #fovSizes then currentFovIndex = 1 end
    fovRadius = fovSizes[currentFovIndex]
    return tostring(fovRadius) .. " px"
end)

-- Build Visuals Page
addToggle(visualsPage, "Player ESP (กล่อง/ระยะ)", espEnabled, function(s) espEnabled = s end)
addToggle(visualsPage, "Target Gear HUD (โชว์ของใต้ตัวศัตรูแบบภาพ)", gearHudEnabled, function(s) gearHudEnabled = s end)
addToggle(visualsPage, "Inspect Panel (หน้าต่างพาเนลสรุปของ)", inspectEnabled, function(s) inspectEnabled = s end)

-- Build Gun Mods Page
addToggle(gunPage, "No Recoil / Anti-Camera Shake (ช่วยคุมปืน)", recoilControlEnabled, function(s) recoilControlEnabled = s end)

-- Build Misc & Config Page
addToggle(miscPage, "ขยาย Hitbox หัวจริง", hitboxExpanded, function(s) 
    hitboxExpanded = s 
    if not hitboxExpanded then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") then
                p.Character.Head.Size = Vector3.new(1.2, 1.2, 1.2)
                p.Character.Head.Transparency = 0
            end
        end
    end
end)
addClicker(miscPage, "ขนาด Hitbox (studs)", tostring(hitboxSize) .. " studs", function()
    currentHitboxIndex = currentHitboxIndex + 1
    if currentHitboxIndex > #hitboxSizes then currentHitboxIndex = 1 end
    hitboxSize = hitboxSizes[currentHitboxIndex]
    return tostring(hitboxSize) .. " studs"
end)
addToggle(miscPage, "Instant Pickup (เก็บของไว)", instantPickupEnabled, function(s) instantPickupEnabled = s end)

-- Config System
addButton(miscPage, "💾 บันทึกตั้งค่า (Save Config)", function()
    local cfg = {
        espEnabled = espEnabled,
        inspectEnabled = inspectEnabled,
        gearHudEnabled = gearHudEnabled,
        teamCheckEnabled = teamCheckEnabled,
        aimbotEnabled = aimbotEnabled,
        wallCheckEnabled = wallCheckEnabled,
        fovEnabled = fovEnabled,
        instantPickupEnabled = instantPickupEnabled,
        hitboxExpanded = hitboxExpanded,
        recoilControlEnabled = recoilControlEnabled,
        hitboxSize = hitboxSize,
        aimSmoothness = aimSmoothness,
        fovRadius = fovRadius,
        targetPartName = targetPartName
    }
    if writefile then
        writefile(configFileName, HttpService:JSONEncode(cfg))
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Syrex Hub", Text = "บันทึกการตั้งค่าสำเร็จ!", Duration = 3})
    end
end)

addButton(miscPage, "📂 โหลดตั้งค่า (Load Config)", function()
    if readfile and isfile and isfile(configFileName) then
        local success, result = pcall(function()
            return HttpService:JSONEncode(readfile(configFileName))
        end)
        if success and result then
            espEnabled = result.espEnabled or false
            inspectEnabled = result.inspectEnabled or false
            gearHudEnabled = result.gearHudEnabled or false
            teamCheckEnabled = result.teamCheckEnabled or false
            aimbotEnabled = result.aimbotEnabled or false
            wallCheckEnabled = result.wallCheckEnabled or false
            fovEnabled = result.fovEnabled or false
            instantPickupEnabled = result.instantPickupEnabled or false
            hitboxExpanded = result.hitboxExpanded or false
            recoilControlEnabled = result.recoilControlEnabled or false
            hitboxSize = result.hitboxSize or 7
            aimSmoothness = result.aimSmoothness or 0.25
            fovRadius = result.fovRadius or 140
            targetPartName = result.targetPartName or "Head"
            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Syrex Hub", Text = "โหลดการตั้งค่าสำเร็จ!", Duration = 3})
        end
    end
end)

-- Default Tab
aimPage.Visible = true
aimTab.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
aimTab.TextColor3 = Color3.fromRGB(255, 255, 255)

-- RIGHT CTRL HOTKEY
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- FOV Circle
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

-- TARGET GEAR BILLBOARD CREATOR (แสดงไอเทม 3 ช่องเรียลไทม์ใต้ตัวศัตรู)
local function createTargetGearHUD(character)
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    if not rootPart then return end

    if rootPart:FindFirstChild("TargetGearHUD") then
        rootPart.TargetGearHUD:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TargetGearHUD"
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 160, 0, 50)
    billboard.StudsOffset = Vector3.new(0, -3.8, 0) -- ตำแหน่งใต้เท้า/ใต้กล่อง ESP
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = rootPart

    local container = Instance.new("Frame")
    container.Parent = billboard
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = container
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Padding = UDim.new(0, 6)

    -- สร้างกล่องไอเทม 3 ช่อง
    for i = 1, 3 do
        local slot = Instance.new("Frame")
        slot.Name = "Slot" .. tostring(i)
        slot.Parent = container
        slot.Size = UDim2.new(0, 44, 0, 44)
        slot.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
        slot.BackgroundTransparency = 0.3

        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, 8)
        slotCorner.Parent = slot

        local slotStroke = Instance.new("UIStroke")
        slotStroke.Parent = slot
        slotStroke.Color = Color3.fromRGB(80, 70, 60)
        slotStroke.Thickness = 1

        local iconImg = Instance.new("ImageLabel")
        iconImg.Name = "Icon"
        iconImg.Parent = slot
        iconImg.Size = UDim2.new(0, 32, 0, 32)
        iconImg.Position = UDim2.new(0.5, -16, 0.5, -16)
        iconImg.BackgroundTransparency = 1
        iconImg.Visible = false

        local nameTxt = Instance.new("TextLabel")
        nameTxt.Name = "ItemName"
        nameTxt.Parent = slot
        nameTxt.Size = UDim2.new(1, -4, 1, -4)
        nameTxt.Position = UDim2.new(0, 2, 0, 2)
        nameTxt.BackgroundTransparency = 1
        nameTxt.Text = ""
        nameTxt.TextColor3 = Color3.fromRGB(240, 220, 200)
        nameTxt.TextSize = 9
        nameTxt.Font = Enum.Font.GothamBold
        nameTxt.TextWrapped = true
    end

    return billboard
end

-- Helper Functions
local function getRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head") or character.PrimaryPart
end

local function getTargetPart(character)
    if not character then return nil end
    return character:FindFirstChild(targetPartName) or character:FindFirstChild("Head") or getRootPart(character)
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
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local targetPart = getTargetPart(player.Character)
    return humanoid and humanoid.Health > 0 and targetPart ~= nil
end

-- Setup ESP and Gear HUD on players
local function applyESP(player)
    if player == LocalPlayer then return end

    local function setupChar(char)
        if not char then return end
        local rootPart = getRootPart(char) or char:WaitForChild("HumanoidRootPart", 5) or char:WaitForChild("Head", 5)
        if not rootPart then return end

        local highlight = char:FindFirstChild("ESPHighlight") or Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.Adornee = char
        highlight.FillColor = Color3.fromRGB(255, 50, 50)
        highlight.FillTransparency = 0.6
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Enabled = espEnabled and isEnemy(player)
        highlight.Parent = char

        if rootPart:FindFirstChild("ESPBillboard") then rootPart.ESPBillboard:Destroy() end
        local bgui = Instance.new("BillboardGui")
        bgui.Name = "ESPBillboard"
        bgui.Adornee = rootPart
        bgui.Size = UDim2.new(0, 180, 0, 25)
        bgui.StudsOffset = Vector3.new(0, 3.2, 0)
        bgui.AlwaysOnTop = true
        bgui.Enabled = espEnabled and isEnemy(player)
        bgui.Parent = rootPart

        local txt = Instance.new("TextLabel")
        txt.Name = "ESPText"
        txt.Parent = bgui
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = "[ " .. player.Name .. " ]"
        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        txt.TextStrokeTransparency = 0
        txt.TextSize = 12
        txt.Font = Enum.Font.GothamBold

        createTargetGearHUD(char)
    end

    if player.Character then task.spawn(setupChar, player.Character) end
    player.CharacterAdded:Connect(function(char) task.spawn(setupChar, char) end)
end

for _, p in pairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

-- Fast Realtime Gear Update & ESP Loop
task.spawn(function()
    while true do
        task.wait(0.08)
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local targetRoot = getRootPart(player.Character)
                    if targetRoot then
                        local gearHud = targetRoot:FindFirstChild("TargetGearHUD")
                        local shouldShowGear = gearHudEnabled and isEnemy(player)

                        if gearHud then
                            gearHud.Enabled = shouldShowGear
                            if shouldShowGear then
                                local itemsList = {}
                                local tool = player.Character:FindFirstChildOfClass("Tool")
                                if tool then table.insert(itemsList, tool) end

                                if player:FindFirstChild("Backpack") then
                                    for _, bItem in pairs(player.Backpack:GetChildren()) do
                                        if bItem:IsA("Tool") and #itemsList < 3 then
                                            table.insert(itemsList, bItem)
                                        end
                                    end
                                end

                                local container = gearHud:FindFirstChild("Frame")
                                if container then
                                    for i = 1, 3 do
                                        local slot = container:FindFirstChild("Slot" .. tostring(i))
                                        if slot then
                                            local item = itemsList[i]
                                            local iconImg = slot:FindFirstChild("Icon")
                                            local nameTxt = slot:FindFirstChild("ItemName")

                                            if item then
                                                if item.TextureId ~= "" and iconImg then
                                                    iconImg.Image = item.TextureId
                                                    iconImg.Visible = true
                                                    if nameTxt then nameTxt.Text = "" end
                                                elseif nameTxt then
                                                    if iconImg then iconImg.Visible = false end
                                                    nameTxt.Text = string.sub(item.Name, 1, 10)
                                                end
                                                slot.BackgroundTransparency = 0.2
                                            else
                                                if iconImg then iconImg.Visible = false end
                                                if nameTxt then nameTxt.Text = "-" end
                                                slot.BackgroundTransparency = 0.6
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- Hitbox Heartbeat
RunService.Heartbeat:Connect(function()
    if hitboxExpanded then
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    if head and isEnemy(player) then
                        head.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                        head.Transparency = 0.5
                        head.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- AIMBOT ENGINE (FIXED V30)
local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = fovEnabled and fovRadius or 99999
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

-- RenderStepped Aimbot Loop
RunService.RenderStepped:Connect(function()
    fovFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    fovFrame.Visible = fovEnabled

    -- No Recoil Camera Lock
    if recoilControlEnabled then
        Camera.RotVelocity = Vector3.new(0, 0, 0)
    end

    -- ตรวจจับคลิกขวา (MouseButton2) หรือคลิกซ้าย (MouseButton1)
    local isHoldingAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

    if aimbotEnabled and isHoldingAim then
        if not stickyTarget or not isValidTarget(stickyTarget) then
            stickyTarget = getClosestPlayerToMouse()
        end

        if stickyTarget and isValidTarget(stickyTarget) then
            local targetPart = getTargetPart(stickyTarget.Character)
            if targetPart then
                local targetPos = targetPart.Position
                
                if aimMode == "Smooth Cam" then
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), aimSmoothness)
                elseif aimMode == "Hard Lock" then
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
                elseif aimMode == "Mouse Delta" then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local deltaX = (screenPos.X - mousePos.X) * aimSmoothness
                        local deltaY = (screenPos.Y - mousePos.Y) * aimSmoothness
                        if mousemoverel then
                            mousemoverel(deltaX, deltaY)
                        else
                            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), aimSmoothness)
                        end
                    end
                end
            end
        end
    else
        stickyTarget = nil
    end
end)

-- Instant Pickup
ProximityPromptService.PromptShown:Connect(function(prompt)
    if instantPickupEnabled then prompt.HoldDuration = 0 end
end)
