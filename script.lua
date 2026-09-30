-- Syrex Hub Ultimate V14 (Spray Lock & No Recoil / Bullet Grouping Edition)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Config Settings
local espEnabled = true
local teamCheckEnabled = false
local aimbotEnabled = false
local fovEnabled = false
local noRecoilEnabled = false -- ฟังก์ชันกระสุนเกาะกลุ่ม / ลดแรงดีด
local fovRadius = 140
local fovSizes = {60, 100, 140, 180, 240, 300}
local currentFovIndex = 3
local targetPartName = "Head" -- Head, Neck, HumanoidRootPart

-- ตัวแปรล็อคเป้าแบบ Sticky
local stickyTarget = nil

-- Prediction Factor
local leadMultipliers = {0, 0.5, 1.0, 1.5, 2.0}
local currentLeadIndex = 3
local leadFactor = leadMultipliers[currentLeadIndex]

-- GUI Creation
local parentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if parentGui:FindFirstChild("SyrexHub_Ultimate_v14") then
    parentGui:FindFirstChild("SyrexHub_Ultimate_v14"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyrexHub_Ultimate_v14"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

-- 1. สร้างหน้าต่าง GUI (ขยายความสูงรองรับปุ่มใหม่)
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.75, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 330)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Title.BorderSizePixel = 0
Title.Text = "Snipe or Die - Syrex Hub V14"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.SourceSansBold

local function createButton(text, yOffset)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.Size = UDim2.new(0.9, 0, 0, 28)
    btn.Position = UDim2.new(0.05, 0, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansBold
    return btn
end

local ESPButton = createButton("ESP: ON (ALL PLAYERS)", 32)
ESPButton.TextColor3 = Color3.fromRGB(0, 255, 127)

local TeamCheckButton = createButton("Team Check: OFF (เห็นทุกคน)", 65)
TeamCheckButton.TextColor3 = Color3.fromRGB(255, 165, 0)

local AimbotButton = createButton("Aimbot (Spray Lock): OFF", 98)
AimbotButton.TextColor3 = Color3.fromRGB(255, 60, 60)

local RecoilButton = createButton("กระสุนเกาะกลุ่ม (No Recoil): OFF", 131)
RecoilButton.TextColor3 = Color3.fromRGB(255, 60, 60)

local TargetButton = createButton("Target: Head [หัว]", 164)
TargetButton.TextColor3 = Color3.fromRGB(255, 215, 0)

local FOVButton = createButton("FOV Circle: OFF", 197)
FOVButton.TextColor3 = Color3.fromRGB(255, 60, 60)

local FOVSizeButton = createButton("FOV Size: 140 px", 230)

local LeadButton = createButton("Lead Prediction: 1.0x", 263)
LeadButton.TextColor3 = Color3.fromRGB(0, 191, 255)

-- 2. วงกลม FOV
local fovFrame = Instance.new("Frame")
fovFrame.Parent = ScreenGui
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
fovFrame.BackgroundTransparency = 1
fovFrame.Visible = false

local fovStroke = Instance.new("UIStroke")
fovStroke.Parent = fovFrame
fovStroke.Color = Color3.fromRGB(0, 255, 200)
fovStroke.Thickness = 1.5

local fovCorner = Instance.new("UICorner")
fovCorner.Parent = fovFrame
fovCorner.CornerRadius = UDim.new(1, 0)

-- 3. ฟังก์ชันดึงชิ้นส่วนเป้าหมาย
local function getRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") 
        or character:FindFirstChild("Head") 
        or character:FindFirstChild("UpperTorso") 
        or character:FindFirstChild("Torso") 
        or character.PrimaryPart
end

local function getTargetPart(character)
    if not character then return nil end
    if targetPartName == "Neck" then
        return character:FindFirstChild("Neck") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("Head")
    elseif targetPartName == "HumanoidRootPart" then
        return getRootPart(character)
    end
    return character:FindFirstChild("Head") or getRootPart(character)
end

local function isEnemy(player)
    if not teamCheckEnabled then return true end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
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

-- 4. คำนวณตำแหน่งดักหน้า (Prediction) แบบเรียลไทม์
local function getPredictedPosition(player)
    if not isValidTarget(player) then return nil end
    local targetPart = getTargetPart(player.Character)
    if not targetPart then return nil end
    
    local targetPos = targetPart.Position
    if targetPartName == "Neck" and targetPart.Name == "Head" then
        targetPos = targetPos - Vector3.new(0, 0.4, 0)
    end
    
    local velocity = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.new(0, 0, 0)
    local distance = (targetPos - Camera.CFrame.Position).Magnitude
    
    local timeToHit = (distance / 2500) * leadFactor
    return targetPos + (velocity * timeToHit)
end

-- 5. ค้นหาเป้าหมายในวงกลม FOV
local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = fovRadius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local targetPart = getTargetPart(player.Character)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
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

-- 6. ฟังก์ชันปรับกระสุนเกาะกลุ่ม / ลบแรงดีดใน Memory (GC Scan)
local function applyNoRecoil()
    if not noRecoilEnabled or not getgc then return end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            if rawget(v, "Recoil") or rawget(v, "recoil") then
                rawset(v, "Recoil", 0)
                rawset(v, "recoil", 0)
            end
            if rawget(v, "Spread") or rawget(v, "spread") then
                rawset(v, "Spread", 0)
                rawset(v, "spread", 0)
            end
            if rawget(v, "Inaccuracy") or rawget(v, "inaccuracy") then
                rawset(v, "Inaccuracy", 0)
                rawset(v, "inaccuracy", 0)
            end
            if rawget(v, "RecoilControl") then
                rawset(v, "RecoilControl", 0)
            end
        end
    end
end

-- 7. Heavy Render Lock Loop (แก้ปัญหายิงค้างแล้วหลุดเป้า)
RunService.RenderStepped:Connect(function()
    fovFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    fovFrame.Visible = fovEnabled

    local isHolding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

    if aimbotEnabled and isHolding then
        -- ตรึงเป้าหมายเดิมไว้ตราบเท่าที่กดยิงค้างอยู่ ไม่ว่าจะสะบัดอย่างไร
        if not stickyTarget or not isValidTarget(stickyTarget) then
            stickyTarget = getClosestPlayerInFOV()
        end

        if stickyTarget and isValidTarget(stickyTarget) then
            local predictedPos = getPredictedPosition(stickyTarget)
            if predictedPos then
                -- บังคับมุมกล้องให้จับตำแหน่งดักหน้าโดยสมบูรณ์ หักล้างแรงดีดปืน
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, predictedPos)
            end
        end
    else
        stickyTarget = nil
    end

    -- Real-Time ESP Update
    if espEnabled and LocalPlayer.Character then
        local myRoot = getRootPart(LocalPlayer.Character)
        if myRoot then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local targetRoot = getRootPart(player.Character)
                    if targetRoot and targetRoot:FindFirstChild("ESPBillboard") then
                        local txt = targetRoot.ESPBillboard:FindFirstChildOfClass("TextLabel")
                        local isVisible = isEnemy(player) and espEnabled
                        
                        targetRoot.ESPBillboard.Enabled = isVisible
                        if targetRoot:FindFirstChild("BoxESPBillboard") then
                            targetRoot.BoxESPBillboard.Enabled = isVisible
                        end
                        if player.Character:FindFirstChild("ESPHighlight") then
                            player.Character.ESPHighlight.Enabled = isVisible
                        end

                        if txt and isVisible then
                            local dist = math.floor((myRoot.Position - targetRoot.Position).Magnitude)
                            txt.Text = "[ " .. player.Name .. " ] [ " .. tostring(dist) .. "m ]"
                        end
                    end
                end
            end
        end
    end
end)

-- Loop ดักจับแก้ไขแรงดีดกระสุนต่อเนื่องเมื่อเปิดใช้งาน
task.spawn(function()
    while task.wait(0.5) do
        if noRecoilEnabled then
            pcall(applyNoRecoil)
        end
    end
end)

-- 8. ระบบสร้าง ESP ติดตัวละคร
local function applyESP(player)
    if player == LocalPlayer then return end

    local function setupChar(char)
        if not char then return end
        local rootPart = getRootPart(char) or char:WaitForChild("HumanoidRootPart", 3) or char:WaitForChild("Head", 3)
        if not rootPart then return end

        local highlight = char:FindFirstChild("ESPHighlight") or Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.Adornee = char
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Enabled = espEnabled and isEnemy(player)
        highlight.Parent = char

        if rootPart:FindFirstChild("ESPBillboard") then rootPart.ESPBillboard:Destroy() end
        local bgui = Instance.new("BillboardGui")
        bgui.Name = "ESPBillboard"
        bgui.Adornee = rootPart
        bgui.Size = UDim2.new(0, 200, 0, 30)
        bgui.StudsOffset = Vector3.new(0, 3.8, 0)
        bgui.AlwaysOnTop = true
        bgui.Enabled = espEnabled and isEnemy(player)
        bgui.Parent = rootPart

        local txt = Instance.new("TextLabel")
        txt.Parent = bgui
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = "[ " .. player.Name .. " ]"
        txt.TextColor3 = Color3.fromRGB(255, 50, 50)
        txt.TextStrokeTransparency = 0
        txt.TextSize = 14
        txt.Font = Enum.Font.SourceSansBold

        if rootPart:FindFirstChild("BoxESPBillboard") then rootPart.BoxESPBillboard:Destroy() end
        local boxGui = Instance.new("BillboardGui")
        boxGui.Name = "BoxESPBillboard"
        boxGui.Adornee = rootPart
        boxGui.Size = UDim2.new(4.5, 0, 6, 0)
        boxGui.AlwaysOnTop = true
        boxGui.Enabled = espEnabled and isEnemy(player)
        boxGui.Parent = rootPart

        local boxFrame = Instance.new("Frame")
        boxFrame.Parent = boxGui
        boxFrame.Size = UDim2.new(1, 0, 1, 0)
        boxFrame.BackgroundTransparency = 1

        local stroke = Instance.new("UIStroke")
        stroke.Parent = boxFrame
        stroke.Color = Color3.fromRGB(255, 0, 0)
        stroke.Thickness = 2
    end

    if player.Character then task.spawn(setupChar, player.Character) end
    player.CharacterAdded:Connect(function(char) task.spawn(setupChar, char) end)
end

-- Scanner Loop สำหรับ ESP ผู้เล่นใหม่
task.spawn(function()
    while task.wait(0.3) do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local char = p.Character
                local rootPart = getRootPart(char)
                if rootPart and (not char:FindFirstChild("ESPHighlight") or not rootPart:FindFirstChild("ESPBillboard")) then
                    applyESP(p)
                end
            end
        end
    end
end)

-- 9. Event ปุ่มกด GUI
ESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPButton.Text = espEnabled and "ESP: ON (ALL PLAYERS)" or "ESP: OFF"
    ESPButton.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(255, 60, 60)
end)

TeamCheckButton.MouseButton1Click:Connect(function()
    teamCheckEnabled = not teamCheckEnabled
    TeamCheckButton.Text = teamCheckEnabled and "Team Check: ON (เฉพาะศัตรู)" or "Team Check: OFF (เห็นทุกคน)"
    TeamCheckButton.TextColor3 = teamCheckEnabled and Color3.fromRGB(0, 191, 255) or Color3.fromRGB(255, 165, 0)
end)

AimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    AimbotButton.Text = aimbotEnabled and "Aimbot (Spray Lock): ON" or "Aimbot (Spray Lock): OFF"
    AimbotButton.TextColor3 = aimbotEnabled and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(255, 60, 60)
end)

RecoilButton.MouseButton1Click:Connect(function()
    noRecoilEnabled = not noRecoilEnabled
    RecoilButton.Text = noRecoilEnabled and "กระสุนเกาะกลุ่ม (No Recoil): ON" or "กระสุนเกาะกลุ่ม (No Recoil): OFF"
    RecoilButton.TextColor3 = noRecoilEnabled and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(255, 60, 60)
    if noRecoilEnabled then pcall(applyNoRecoil) end
end)

TargetButton.MouseButton1Click:Connect(function()
    if targetPartName == "Head" then
        targetPartName = "Neck"
        TargetButton.Text = "Target: Neck [คอ]"
        TargetButton.TextColor3 = Color3.fromRGB(255, 165, 0)
    elseif targetPartName == "Neck" then
        targetPartName = "HumanoidRootPart"
        TargetButton.Text = "Target: Body [ลำตัว]"
        TargetButton.TextColor3 = Color3.fromRGB(0, 191, 255)
    else
        targetPartName = "Head"
        TargetButton.Text = "Target: Head [หัว]"
        TargetButton.TextColor3 = Color3.fromRGB(255, 215, 0)
    end
end)

FOVButton.MouseButton1Click:Connect(function()
    fovEnabled = not fovEnabled
    FOVButton.Text = fovEnabled and "FOV Circle: ON" or "FOV Circle: OFF"
    FOVButton.TextColor3 = fovEnabled and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(255, 60, 60)
end)

FOVSizeButton.MouseButton1Click:Connect(function()
    currentFovIndex = currentFovIndex + 1
    if currentFovIndex > #fovSizes then currentFovIndex = 1 end
    fovRadius = fovSizes[currentFovIndex]
    FOVSizeButton.Text = "FOV Size: " .. tostring(fovRadius) .. " px"
end)

LeadButton.MouseButton1Click:Connect(function()
    currentLeadIndex = currentLeadIndex + 1
    if currentLeadIndex > #leadMultipliers then currentLeadIndex = 1 end
    leadFactor = leadMultipliers[currentLeadIndex]
    LeadButton.Text = "Lead Prediction: " .. tostring(leadFactor) .. "x"
end)
