-- ==========================================
-- アイテム自動切り替え + Speed表示 + Drop機能 + SpeedBoost(✈️)
-- ==========================================

-- サービスの設定
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- PlayerGuiが読み込まれるまで確実に待機
local playerGui = nil
while not playerGui do
    pcall(function()
        playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
    end)
    if not playerGui then
        task.wait(0.1)
    end
end

-- ==========================================
-- 0. 全員の頭の上にSpeed表示
-- ==========================================
local function createSpeedLabel(plr)
    local char = plr.Character
    if not char then return nil end
    
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    
    local oldLabel = char:FindFirstChild("SpeedLabel")
    if oldLabel then oldLabel:Destroy() end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SpeedLabel"
    billboard.Parent = char
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.MaxDistance = 100
    
    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.Text = "0"
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    return billboard
end

local function updateAllSpeedLabels()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local existing = plr.Character:FindFirstChild("SpeedLabel")
            if not existing then
                createSpeedLabel(plr)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        createSpeedLabel(plr)
    end)
end)

task.wait(1)
updateAllSpeedLabels()

task.spawn(function()
    while true do
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local label = char:FindFirstChild("SpeedLabel")
                if humanoid and label then
                    local speed = math.floor(humanoid.WalkSpeed * 10) / 10
                    local textLabel = label:FindFirstChildOfClass("TextLabel")
                    if textLabel then
                        textLabel.Text = tostring(speed)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- 初期アイテムマスターリスト
-- ==========================================
local masterItems = {
    "Bat", 
    "Giant Potion", 
    "Quantum Cloner",
    "Cape", 
    "Gummy Bear",
    "Beehive"
}

local activeItems = { "Bat", "Giant Potion", "Quantum Cloner", "Cape", "Gummy Bear", "Beehive" }
local currentIndex = 1
local switchSpeed = 0.001
local isLooping = false
local toolCache = {}

clonerUsed = false
local isLocked = true
local dropEnabled = false
local dropUI = nil

-- Speed Boost用変数
local speedBoostEnabled = false
local originalWalkSpeed = 29
local currentBoostSpeed = 29

local function onCharacterAdded(char)
    toolCache = {}
    task.wait(0.5)
    createSpeedLabel(player)
    if speedBoostEnabled then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = currentBoostSpeed
        end
    end
end
pcall(function()
    player.CharacterAdded:Connect(onCharacterAdded)
end)

-- ==========================================
-- 1. GUIのベース作成
-- ==========================================
local function destroyOldGui()
    local oldGui = playerGui:FindFirstChild("DraggableSwitchGui") or CoreGui:FindFirstChild("DraggableSwitchGui")
    if oldGui then 
        pcall(function() oldGui:Destroy() end) 
    end
end
destroyOldGui()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DraggableSwitchGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 99999

local success, err = pcall(function()
    screenGui.Parent = playerGui
end)
if not success then
    screenGui.Parent = CoreGui
end

-- ボタンコンテナ（3つ並べるので横幅拡大）
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(0, 255, 0, 75)
buttonContainer.Position = UDim2.new(0, 100, 0, 150)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Active = true
buttonContainer.Parent = screenGui

-- 🛠️ボタン
local toolsFrame = Instance.new("Frame")
toolsFrame.Name = "ToolsFrame"
toolsFrame.Size = UDim2.new(0, 75, 0, 75)
toolsFrame.Position = UDim2.new(0, 0, 0, 0)
toolsFrame.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
toolsFrame.Parent = buttonContainer

local toolsButton = Instance.new("TextButton")
toolsButton.Name = "ToolsButton"
toolsButton.Text = "🛠️"
toolsButton.Size = UDim2.new(1, 0, 1, 0) 
toolsButton.BackgroundTransparency = 1
toolsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toolsButton.Font = Enum.Font.GothamBold
toolsButton.TextSize = 34
toolsButton.Parent = toolsFrame

-- 🥶ボタン
local coldFrame = Instance.new("Frame")
coldFrame.Name = "ColdFrame"
coldFrame.Size = UDim2.new(0, 75, 0, 75)
coldFrame.Position = UDim2.new(0, 85, 0, 0)
coldFrame.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
coldFrame.Parent = buttonContainer

local coldButton = Instance.new("TextButton")
coldButton.Name = "ColdButton"
coldButton.Text = "🥶"
coldButton.Size = UDim2.new(1, 0, 1, 0)
coldButton.BackgroundTransparency = 1
coldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
coldButton.Font = Enum.Font.GothamBold
coldButton.TextSize = 34
coldButton.Parent = coldFrame

-- ✈️ Speed Boostボタン
local boostFrame = Instance.new("Frame")
boostFrame.Name = "BoostFrame"
boostFrame.Size = UDim2.new(0, 75, 0, 75)
boostFrame.Position = UDim2.new(0, 170, 0, 0)
boostFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
boostFrame.Parent = buttonContainer

local boostButton = Instance.new("TextButton")
boostButton.Name = "BoostButton"
boostButton.Text = "✈️"
boostButton.Size = UDim2.new(1, 0, 1, 0)
boostButton.BackgroundTransparency = 1
boostButton.TextColor3 = Color3.fromRGB(255, 255, 255)
boostButton.Font = Enum.Font.GothamBold
boostButton.TextSize = 34
boostButton.Parent = boostFrame

-- ==========================================
-- 2. ☠️デスボタン
-- ==========================================
local topRightFrame = Instance.new("Frame")
topRightFrame.Name = "TopRightFrame"
topRightFrame.Size = UDim2.new(0, 75, 0, 75)
topRightFrame.Position = UDim2.new(1, -100, 0, 20)
topRightFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
topRightFrame.Visible = false 
topRightFrame.Active = true 
topRightFrame.Parent = screenGui

local topRightDeathButton = Instance.new("TextButton")
topRightDeathButton.Name = "TopRightDeathButton"
topRightDeathButton.Text = "☠️"
topRightDeathButton.Size = UDim2.new(1, 0, 1, 0)
topRightDeathButton.BackgroundTransparency = 1
topRightDeathButton.TextColor3 = Color3.fromRGB(255, 255, 255)
topRightDeathButton.Font = Enum.Font.GothamBold
topRightDeathButton.TextSize = 34
topRightDeathButton.Parent = topRightFrame

-- ==========================================
-- 3. メニュー画面（背景黒）
-- ==========================================
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 300, 0, 480)
menuFrame.Position = UDim2.new(0.5, -150, 0.5, -240)
menuFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
menuFrame.Visible = false
menuFrame.Active = true 
menuFrame.ZIndex = 100
menuFrame.Parent = screenGui

local menuTitle = Instance.new("TextLabel")
menuTitle.Text = "  MENU"
menuTitle.Size = UDim2.new(1, 0, 0, 40)
menuTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
menuTitle.Font = Enum.Font.GothamBold
menuTitle.TextSize = 15
menuTitle.TextXAlignment = Enum.TextXAlignment.Left
menuTitle.Active = true 
menuTitle.ZIndex = 101
menuTitle.Parent = menuFrame

local closeMenuButton = Instance.new("TextButton")
closeMenuButton.Name = "CloseMenuButton"
closeMenuButton.Text = "❌"
closeMenuButton.Size = UDim2.new(0, 32, 0, 32)
closeMenuButton.Position = UDim2.new(1, -36, 0, 4) 
closeMenuButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
closeMenuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeMenuButton.Font = Enum.Font.GothamBold
closeMenuButton.TextSize = 14
closeMenuButton.ZIndex = 105
closeMenuButton.Parent = menuFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -55)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.ZIndex = 102
scrollFrame.Parent = menuFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = scrollFrame

local menuDeathButton = Instance.new("TextButton")
menuDeathButton.Name = "MenuDeathButton"
menuDeathButton.Text = "☠️\nDEATH BTN\n[ OFF ]"
menuDeathButton.Size = UDim2.new(0, 80, 0, 48) 
menuDeathButton.Position = UDim2.new(1, 8, 0, 0)
menuDeathButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50) 
menuDeathButton.TextColor3 = Color3.fromRGB(255, 255, 255)
menuDeathButton.Font = Enum.Font.GothamBold
menuDeathButton.TextSize = 10
menuDeathButton.ZIndex = 110
menuDeathButton.Parent = menuFrame 

local lockGuiButton = Instance.new("TextButton")
lockGuiButton.Name = "LockGuiButton"
lockGuiButton.Text = "🔐\nLOCK\n[ ON ]"
lockGuiButton.Size = UDim2.new(0, 80, 0, 48) 
lockGuiButton.Position = UDim2.new(1, 8, 0, 53)
lockGuiButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50) 
lockGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockGuiButton.Font = Enum.Font.GothamBold
lockGuiButton.TextSize = 11
lockGuiButton.ZIndex = 110
lockGuiButton.Parent = menuFrame 

local speedInputBox = Instance.new("TextBox")
speedInputBox.Name = "SpeedInputBox"
speedInputBox.Text = tostring(switchSpeed) 
speedInputBox.PlaceholderText = "秒数"
speedInputBox.Size = UDim2.new(0, 80, 0, 40)
speedInputBox.Position = UDim2.new(1, 8, 0, 106)
speedInputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
speedInputBox.TextColor3 = Color3.fromRGB(255, 215, 0) 
speedInputBox.Font = Enum.Font.GothamBold
speedInputBox.TextSize = 14
speedInputBox.ClearTextOnFocus = false
speedInputBox.ZIndex = 110
speedInputBox.Parent = menuFrame

-- ==========================================
-- 3.5 Dropスイッチ（メニュー内）
-- ==========================================
local dropSwitchRow = Instance.new("Frame")
dropSwitchRow.Name = "DropSwitchRow"
dropSwitchRow.Size = UDim2.new(1, 0, 0, 45)
dropSwitchRow.Position = UDim2.new(0, 0, 0, 155)
dropSwitchRow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dropSwitchRow.ZIndex = 110
dropSwitchRow.Parent = menuFrame

local dropLabel = Instance.new("TextLabel")
dropLabel.Name = "DropLabel"
dropLabel.Text = "drop"
dropLabel.Size = UDim2.new(0.5, 0, 1, 0)
dropLabel.Position = UDim2.new(0, 10, 0, 0)
dropLabel.BackgroundTransparency = 1
dropLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
dropLabel.Font = Enum.Font.Gotham
dropLabel.TextSize = 16
dropLabel.TextXAlignment = Enum.TextXAlignment.Left
dropLabel.ZIndex = 111
dropLabel.Parent = dropSwitchRow

local dropSwitchButton = Instance.new("TextButton")
dropSwitchButton.Name = "DropSwitchButton"
dropSwitchButton.Text = "OFF"
dropSwitchButton.Size = UDim2.new(0, 60, 0, 30)
dropSwitchButton.Position = UDim2.new(0.8, 0, 0.5, -15)
dropSwitchButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
dropSwitchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dropSwitchButton.Font = Enum.Font.GothamBold
dropSwitchButton.TextSize = 12
dropSwitchButton.ZIndex = 111
dropSwitchButton.Parent = dropSwitchRow

-- ==========================================
-- 3.6 Speed Boost（メニュー内 - 速度入力用）
-- ==========================================
local speedBoostRow = Instance.new("Frame")
speedBoostRow.Name = "SpeedBoostRow"
speedBoostRow.Size = UDim2.new(1, 0, 0, 45)
speedBoostRow.Position = UDim2.new(0, 0, 0, 205)
speedBoostRow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
speedBoostRow.ZIndex = 110
speedBoostRow.Parent = menuFrame

local speedBoostLabel = Instance.new("TextLabel")
speedBoostLabel.Name = "SpeedBoostLabel"
speedBoostLabel.Text = "speed"
speedBoostLabel.Size = UDim2.new(0.3, 0, 1, 0)
speedBoostLabel.Position = UDim2.new(0, 10, 0, 0)
speedBoostLabel.BackgroundTransparency = 1
speedBoostLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBoostLabel.Font = Enum.Font.Gotham
speedBoostLabel.TextSize = 16
speedBoostLabel.TextXAlignment = Enum.TextXAlignment.Left
speedBoostLabel.ZIndex = 111
speedBoostLabel.Parent = speedBoostRow

local speedBoostInput = Instance.new("TextBox")
speedBoostInput.Name = "SpeedBoostInput"
speedBoostInput.Text = "29"
speedBoostInput.PlaceholderText = "速度"
speedBoostInput.Size = UDim2.new(0, 60, 0, 30)
speedBoostInput.Position = UDim2.new(0.35, 0, 0.5, -15)
speedBoostInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
speedBoostInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBoostInput.Font = Enum.Font.GothamBold
speedBoostInput.TextSize = 14
speedBoostInput.ClearTextOnFocus = false
speedBoostInput.ZIndex = 111
speedBoostInput.Parent = speedBoostRow

-- ==========================================
-- 3.7 Drop UI（🫨）
-- ==========================================
local function createDropUI()
    if dropUI then return end
    
    dropUI = Instance.new("Frame")
    dropUI.Name = "DropUI"
    dropUI.Size = UDim2.new(0, 75, 0, 75)
    dropUI.Position = UDim2.new(0.5, -37, 0.3, 0)
    dropUI.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    dropUI.BackgroundTransparency = 0
    dropUI.Visible = false
    dropUI.Active = true
    dropUI.ZIndex = 200
    dropUI.Parent = screenGui
    
    local dropText = Instance.new("TextButton")
    dropText.Name = "DropText"
    dropText.Text = "🫨"
    dropText.Size = UDim2.new(1, 0, 1, 0)
    dropText.BackgroundTransparency = 1
    dropText.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropText.Font = Enum.Font.GothamBold
    dropText.TextSize = 34
    dropText.ZIndex = 201
    dropText.Parent = dropUI
    
    dropText.MouseButton1Click:Connect(function()
        performDrop()
    end)
end

-- ==========================================
-- 4. イベント
-- ==========================================
speedInputBox.FocusLost:Connect(function(enterPressed)
    local num = tonumber(speedInputBox.Text)
    if num and num > 0 then
        switchSpeed = num
        speedInputBox.Text = tostring(switchSpeed)
    else
        switchSpeed = 0.001
        speedInputBox.Text = "0.001"
    end
end)

menuDeathButton.MouseButton1Click:Connect(function()
    topRightFrame.Visible = not topRightFrame.Visible
    if topRightFrame.Visible then
        menuDeathButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        menuDeathButton.Text = "☠️\nDEATH BTN\n[ ON ]"
    else
        menuDeathButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        menuDeathButton.Text = "☠️\nDEATH BTN\n[ OFF ]"
    end
end)

lockGuiButton.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    if isLocked then
        lockGuiButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50) 
        lockGuiButton.Text = "🔐\nLOCK\n[ ON ]"
    else
        lockGuiButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
        lockGuiButton.Text = "🔓\nLOCK\n[ OFF ]"
    end
end)

dropSwitchButton.MouseButton1Click:Connect(function()
    dropEnabled = not dropEnabled
    if dropEnabled then
        dropSwitchButton.Text = "ON"
        dropSwitchButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        createDropUI()
        if dropUI then
            dropUI.Visible = true
        end
    else
        dropSwitchButton.Text = "OFF"
        dropSwitchButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        if dropUI then
            dropUI.Visible = false
        end
    end
end)

-- ✈️ Speed Boostボタン
boostButton.MouseButton1Click:Connect(function()
    speedBoostEnabled = not speedBoostEnabled
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if speedBoostEnabled then
        boostButton.Text = "⚡"
        boostFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        
        local num = tonumber(speedBoostInput.Text)
        if num and num > 0 then
            currentBoostSpeed = num
        else
            currentBoostSpeed = 29
            speedBoostInput.Text = "29"
        end
        
        if humanoid then
            originalWalkSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = currentBoostSpeed
        end
    else
        boostButton.Text = "✈️"
        boostFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        
        if humanoid then
            humanoid.WalkSpeed = originalWalkSpeed
        end
    end
end)

-- 速度入力ボックス（Enterで更新）
speedBoostInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local num = tonumber(speedBoostInput.Text)
        if num and num > 0 then
            currentBoostSpeed = num
            if speedBoostEnabled then
                local char = player.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = currentBoostSpeed
                end
            end
        else
            speedBoostInput.Text = "29"
            currentBoostSpeed = 29
        end
    end
end)

-- Drop動作
local function performDrop()
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    local originalPos = rootPart.Position
    local targetPos = originalPos + Vector3.new(0, 70, 0)
    
    rootPart.CFrame = CFrame.new(targetPos)
    task.wait(0.05)
    rootPart.CFrame = CFrame.new(originalPos)
end

-- メニューリフレッシュ
local function refreshMenu()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then pcall(function() child:Destroy() end) end
    end
    
    for i, itemName in ipairs(activeItems) do
        local itemRow = Instance.new("Frame")
        itemRow.Size = UDim2.new(1, 0, 0, 38)
        itemRow.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        itemRow.ZIndex = 103
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = "  " .. itemName
        nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 13
        nameLabel.BackgroundTransparency = 1
        nameLabel.ZIndex = 104
        nameLabel.Parent = itemRow
        
        local upBtn = Instance.new("TextButton")
        upBtn.Text = "⬆️"
        upBtn.Size = UDim2.new(0, 28, 0, 28)
        upBtn.Position = UDim2.new(0.55, 0, 0.5, -14)
        upBtn.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
        upBtn.TextColor3 = Color3.fromRGB(255,255,255)
        upBtn.ZIndex = 104
        upBtn.Parent = itemRow
        upBtn.MouseButton1Click:Connect(function()
            if i > 1 then
                table.remove(activeItems, i)
                table.insert(activeItems, i - 1, itemName)
                refreshMenu()
            end
        end)
        
        local downBtn = Instance.new("TextButton")
        downBtn.Text = "⬇️"
        downBtn.Size = UDim2.new(0, 28, 0, 28)
        downBtn.Position = UDim2.new(0.7, 0, 0.5, -14)
        downBtn.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
        downBtn.TextColor3 = Color3.fromRGB(255,255,255)
        downBtn.ZIndex = 104
        downBtn.Parent = itemRow
        downBtn.MouseButton1Click:Connect(function()
            if i < #activeItems then
                table.remove(activeItems, i)
                table.insert(activeItems, i + 1, itemName)
                refreshMenu()
            end
        end)
        
        local delBtn = Instance.new("TextButton")
        delBtn.Text = "❌"
        delBtn.Size = UDim2.new(0, 28, 0, 28)
        delBtn.Position = UDim2.new(0.85, 0, 0.5, -14)
        delBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
        delBtn.TextColor3 = Color3.fromRGB(255,255,255)
        delBtn.ZIndex = 104
        delBtn.Parent = itemRow
        delBtn.MouseButton1Click:Connect(function()
            table.remove(activeItems, i)
            refreshMenu()
        end)
        
        itemRow.Parent = scrollFrame
    end
    
    for _, masterName in ipairs(masterItems) do
        if not table.find(activeItems, masterName) then
            local addRow = Instance.new("Frame")
            addRow.Size = UDim2.new(1, 0, 0, 38)
            addRow.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            addRow.ZIndex = 103
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text = "  [OFF] " .. masterName
            nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 13
            nameLabel.BackgroundTransparency = 1
            nameLabel.ZIndex = 104
            nameLabel.Parent = addRow
            
            local addBtn = Instance.new("TextButton")
            addBtn.Text = "➕"
            addBtn.Size = UDim2.new(0, 40, 0, 28)
            addBtn.Position = UDim2.new(0.82, 0, 0.5, -14)
            addBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 60)
            addBtn.TextColor3 = Color3.fromRGB(255,255,255)
            addBtn.ZIndex = 104
            addBtn.Parent = addRow
            addBtn.MouseButton1Click:Connect(function()
                table.insert(activeItems, masterName)
                refreshMenu()
            end)
            
            addRow.Parent = scrollFrame
        end
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y + 10)
end

closeMenuButton.MouseButton1Click:Connect(function() menuFrame.Visible = false end)

-- ==========================================
-- 🛠️ ドラッグ＆クリック判定
-- ==========================================
local activeDragFrame = nil
local dragStart = nil
local startPos = nil
local hasMoved = false 

toolsButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = input.Position
        startPos = buttonContainer.Position
        hasMoved = false
        if not isLocked then activeDragFrame = buttonContainer end
    end
end)
toolsButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isLocked or (not isLocked and not hasMoved) then
            menuFrame.Visible = not menuFrame.Visible
            if menuFrame.Visible then refreshMenu() end
        end
        activeDragFrame = nil
    end
end)

coldButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = input.Position
        startPos = buttonContainer.Position
        hasMoved = false
        if not isLocked then activeDragFrame = buttonContainer end
    end
end)
coldButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isLocked then
            isLooping = not isLooping
            if isLooping then
                coldFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
                coldButton.Text = "🥶⚡"
                clonerUsed = false 
            else
                coldFrame.BackgroundColor3 = Color3.fromRGB(100, 180, 255) 
                coldButton.Text = "🥶"
            end
        end
        activeDragFrame = nil
    end
end)

topRightDeathButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = input.Position
        startPos = topRightFrame.Position
        hasMoved = false
        if not isLocked then activeDragFrame = topRightFrame end
    end
end)
topRightDeathButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isLocked then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.Health = 0 end
            end
        end
        activeDragFrame = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragStart then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then
                hasMoved = true
            end
            
            if not isLocked and activeDragFrame and startPos then
                activeDragFrame.Position = UDim2.new(
                    startPos.X.Scale, 
                    startPos.X.Offset + delta.X, 
                    startPos.Y.Scale, 
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeDragFrame = nil
    end
end)

local menuDragging = false
local menuDragStart, menuStartPos
menuTitle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        menuDragging = true
        menuDragStart = input.Position
        menuStartPos = menuFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if menuDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - menuDragStart
        menuFrame.Position = UDim2.new(menuStartPos.X.Scale, menuStartPos.X.Offset + delta.X, menuStartPos.Y.Scale, menuStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        menuDragging = false
    end
end)

-- ==========================================
-- 5. アイテムループ
-- ==========================================
local function findToolEverywhere(searchName)
    if toolCache[searchName] and toolCache[searchName].Parent then return toolCache[searchName] end
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    local function isMatch(toolObj)
        if not toolObj or not toolObj:IsA("Tool") then return false end
        if searchName == "Giant Potion" then
            if string.find(string.lower(toolObj.Name), "giant potion") or string.find(toolObj.Name, "巨大ポーション") then return true end
            return false
        end
        if string.find(string.lower(toolObj.Name), string.lower(searchName)) then return true end
        return false
    end

    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do if isMatch(tool) then toolCache[searchName] = tool return tool end end
    end
    if character then
        for _, tool in ipairs(character:GetChildren()) do if isMatch(tool) then toolCache[searchName] = tool return tool end end
    end
    return nil
end

task.spawn(function()
    while true do
        if isLooping and #activeItems > 0 then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            if character and humanoid and humanoid.Health > 0 and character:IsDescendantOf(workspace) then
                local foundTool = nil
                local attempts = 0
                
                while not foundTool and attempts < #activeItems do
                    if currentIndex > #activeItems then currentIndex = 1 end
                    local itemName = activeItems[currentIndex]
                    
                    if itemName == "Quantum Cloner" and clonerUsed then
                        currentIndex = currentIndex % #activeItems + 1
                        attempts = attempts + 1
                    else
                        foundTool = findToolEverywhere(itemName)
                        if not foundTool then
                            currentIndex = currentIndex % #activeItems + 1
                            attempts = attempts + 1
                        end
                    end
                end
                
                if foundTool then
                    local currentTool = character:FindFirstChildOfClass("Tool")
                    if currentTool and currentTool ~= foundTool then
                        humanoid:UnequipTools()
                    end
                    if foundTool.Parent ~= character then
                        humanoid:EquipTool(foundTool)
                    end
                    
                    local lowerName = string.lower(foundTool.Name)
                    
                    if string.find(lowerName, "bat") or string.find(foundTool.Name, "バット") then
                        foundTool:Activate()
                        task.wait(0.02)
                        local potion = findToolEverywhere("Giant Potion")
                        if potion then
                            humanoid:UnequipTools()
                            humanoid:EquipTool(potion)
                            potion:Activate()
                            task.wait(0.02)
                            local pIdx = table.find(activeItems, "Giant Potion")
                            if pIdx then currentIndex = pIdx end
                        end
                    end
                    
                    if string.find(lowerName, "giant potion") or string.find(foundTool.Name, "巨大ポーション") then
                        foundTool:Activate()
                        task.wait(0.5) 
                        if not clonerUsed then
                            local cloner = findToolEverywhere("Quantum Cloner")
                            if cloner then
                                humanoid:UnequipTools()
                                humanoid:EquipTool(cloner)
                                task.wait(0.01)
                                cloner:Activate() 
                                clonerUsed = true 
                                task.wait(0.01)   
                                local cIdx = table.find(activeItems, "Quantum Cloner")
                                if cIdx then currentIndex = cIdx end
                            end
                        end
                    end

                    if string.find(lowerName, "quantum cloner") or string.find(foundTool.Name, "量子") then
                        if not clonerUsed then
                            foundTool:Activate()
                            clonerUsed = true 
                            task.wait(0.01)
                        end
                    end
                    
                    if string.find(lowerName, "cape") or string.find(foundTool.Name, "ケープ") then
                        foundTool:Activate() task.wait(0.01)      
                    end
                    if string.find(lowerName, "gummy bear") or string.find(foundTool.Name, "グミベア") then
                        foundTool:Activate() task.wait(0.01)      
                    end
                    if string.find(lowerName, "beehive") or string.find(foundTool.Name, "蜂の巣") then
                        foundTool:Activate() task.wait(0.01)      
                    end
                    
                    currentIndex = currentIndex % #activeItems + 1
                end
            end
        end
        task.wait(switchSpeed) 
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        createSpeedLabel(plr)
    end)
end)
