-- ==========================================
-- NIKU HUB（グラデーション背景 + 速度29）
-- ==========================================

-- サービスの設定
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- PlayerGuiが読み込まれるまで待機
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

-- Speed Boost用変数（デフォルト29）
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

-- ボタンコンテナ（4つ並べる）
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(0, 340, 0, 75)
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

-- 🎯 インスタントスティールボタン
local stealFrame = Instance.new("Frame")
stealFrame.Name = "StealFrame"
stealFrame.Size = UDim2.new(0, 75, 0, 75)
stealFrame.Position = UDim2.new(0, 255, 0, 0)
stealFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
stealFrame.Parent = buttonContainer

local stealButton = Instance.new("TextButton")
stealButton.Name = "StealButton"
stealButton.Text = "🎯"
stealButton.Size = UDim2.new(1, 0, 1, 0)
stealButton.BackgroundTransparency = 1
stealButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stealButton.Font = Enum.Font.GothamBold
stealButton.TextSize = 34
stealButton.Parent = stealFrame

-- ==========================================
-- 2. ☠️デスボタン（Death/リスポーン）
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
-- 3. メニュー画面（グラデーション背景）
-- ==========================================
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 320, 0, 530)
menuFrame.Position = UDim2.new(0.5, -160, 0.5, -265)
menuFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
menuFrame.Visible = false
menuFrame.Active = true 
menuFrame.ZIndex = 100
menuFrame.Parent = screenGui

-- グラデーション（右から黒→グレー→黒）
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(30, 30, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 60, 60)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(30, 30, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
})
gradient.Rotation = 0
gradient.Parent = menuFrame

-- タイトル「NIKU HUB」
local menuTitle = Instance.new("TextLabel")
menuTitle.Text = "  NIKU HUB"
menuTitle.Size = UDim2.new(1, 0, 0, 40)
menuTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
menuTitle.Font = Enum.Font.GothamBold
menuTitle.TextSize = 18
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

-- ==========================================
-- 3.1 アイテム自動切り替え（🥶）
-- ==========================================
local switchRow = Instance.new("Frame")
switchRow.Size = UDim2.new(1, 0, 0, 40)
switchRow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
switchRow.ZIndex = 110
switchRow.Parent = menuFrame

local switchLabel = Instance.new("TextLabel")
switchLabel.Text = "アイテム自動切り替え"
switchLabel.Size = UDim2.new(0.7, 0, 1, 0)
switchLabel.Position = UDim2.new(0, 10, 0, 0)
switchLabel.BackgroundTransparency = 1
switchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
switchLabel.Font = Enum.Font.Gotham
switchLabel.TextSize = 14
switchLabel.TextXAlignment = Enum.TextXAlignment.Left
switchLabel.ZIndex = 111
switchLabel.Parent = switchRow

local switchButton = Instance.new("TextButton")
switchButton.Name = "SwitchButton"
switchButton.Text = "[ OFF ]"
switchButton.Size = UDim2.new(0, 70, 0, 28)
switchButton.Position = UDim2.new(0.78, 0, 0.5, -14)
switchButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
switchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
switchButton.Font = Enum.Font.GothamBold
switchButton.TextSize = 11
switchButton.ZIndex = 111
switchButton.Parent = switchRow

-- ==========================================
-- 3.2 切り替え速度
-- ==========================================
local speedRow = Instance.new("Frame")
speedRow.Size = UDim2.new(1, 0, 0, 40)
speedRow.Position = UDim2.new(0, 0, 0, 45)
speedRow.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
speedRow.ZIndex = 110
speedRow.Parent = menuFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Text = "切り替え速度"
speedLabel.Size = UDim2.new(0.5, 0, 1, 0)
speedLabel.Position = UDim2.new(0, 10, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.ZIndex = 111
speedLabel.Parent = speedRow

local speedInputBox = Instance.new("TextBox")
speedInputBox.Name = "SpeedInputBox"
speedInputBox.Text = "0.001"
speedInputBox.Size = UDim2.new(0, 80, 0, 30)
speedInputBox.Position = UDim2.new(0.72, 0, 0.5, -15)
speedInputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
speedInputBox.TextColor3 = Color3.fromRGB(255, 215, 0)
speedInputBox.Font = Enum.Font.GothamBold
speedInputBox.TextSize = 14
speedInputBox.ClearTextOnFocus = false
speedInputBox.ZIndex = 111
speedInputBox.Parent = speedRow

-- ==========================================
-- 3.3 ロック状態
-- ==========================================
local lockRow = Instance.new("Frame")
lockRow.Size = UDim2.new(1, 0, 0, 40)
lockRow.Position = UDim2.new(0, 0, 0, 90)
lockRow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
lockRow.ZIndex = 110
lockRow.Parent = menuFrame

local lockLabel = Instance.new("TextLabel")
lockLabel.Text = "ロック状態"
lockLabel.Size = UDim2.new(0.5, 0, 1, 0)
lockLabel.Position = UDim2.new(0, 10, 0, 0)
lockLabel.BackgroundTransparency = 1
lockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
lockLabel.Font = Enum.Font.Gotham
lockLabel.TextSize = 14
lockLabel.TextXAlignment = Enum.TextXAlignment.Left
lockLabel.ZIndex = 111
lockLabel.Parent = lockRow

local lockStatusLabel = Instance.new("TextLabel")
lockStatusLabel.Name = "LockStatusLabel"
lockStatusLabel.Text = "ロック中"
lockStatusLabel.Size = UDim2.new(0.3, 0, 1, 0)
lockStatusLabel.Position = UDim2.new(0.7, 0, 0, 0)
lockStatusLabel.BackgroundTransparency = 1
lockStatusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
lockStatusLabel.Font = Enum.Font.GothamBold
lockStatusLabel.TextSize = 14
lockStatusLabel.TextXAlignment = Enum.TextXAlignment.Center
lockStatusLabel.ZIndex = 111
lockStatusLabel.Parent = lockRow

-- ==========================================
-- 3.4 ドロップアイテム
-- ==========================================
local dropRow = Instance.new("Frame")
dropRow.Size = UDim2.new(1, 0, 0, 40)
dropRow.Position = UDim2.new(0, 0, 0, 135)
dropRow.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
dropRow.ZIndex = 110
dropRow.Parent = menuFrame

local dropLabel = Instance.new("TextLabel")
dropLabel.Text = "ドロップアイテム"
dropLabel.Size = UDim2.new(0.7, 0, 1, 0)
dropLabel.Position = UDim2.new(0, 10, 0, 0)
dropLabel.BackgroundTransparency = 1
dropLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
dropLabel.Font = Enum.Font.Gotham
dropLabel.TextSize = 14
dropLabel.TextXAlignment = Enum.TextXAlignment.Left
dropLabel.ZIndex = 111
dropLabel.Parent = dropRow

local dropSwitch = Instance.new("TextButton")
dropSwitch.Name = "DropSwitch"
dropSwitch.Text = "[ OFF ]"
dropSwitch.Size = UDim2.new(0, 70, 0, 28)
dropSwitch.Position = UDim2.new(0.78, 0, 0.5, -14)
dropSwitch.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
dropSwitch.TextColor3 = Color3.fromRGB(255, 255, 255)
dropSwitch.Font = Enum.Font.GothamBold
dropSwitch.TextSize = 11
dropSwitch.ZIndex = 111
dropSwitch.Parent = dropRow

-- ==========================================
-- 3.5 Speed Boost
-- ==========================================
local boostRow = Instance.new("Frame")
boostRow.Size = UDim2.new(1, 0, 0, 40)
boostRow.Position = UDim2.new(0, 0, 0, 180)
boostRow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
boostRow.ZIndex = 110
boostRow.Parent = menuFrame

local boostLabel = Instance.new("TextLabel")
boostLabel.Text = "Speed Boost"
boostLabel.Size = UDim2.new(0.7, 0, 1, 0)
boostLabel.Position = UDim2.new(0, 10, 0, 0)
boostLabel.BackgroundTransparency = 1
boostLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
boostLabel.Font = Enum.Font.Gotham
boostLabel.TextSize = 14
boostLabel.TextXAlignment = Enum.TextXAlignment.Left
boostLabel.ZIndex = 111
boostLabel.Parent = boostRow

local boostSwitch = Instance.new("TextButton")
boostSwitch.Name = "BoostSwitch"
boostSwitch.Text = "[ OFF ]"
boostSwitch.Size = UDim2.new(0, 70, 0, 28)
boostSwitch.Position = UDim2.new(0.78, 0, 0.5, -14)
boostSwitch.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
boostSwitch.TextColor3 = Color3.fromRGB(255, 255, 255)
boostSwitch.Font = Enum.Font.GothamBold
boostSwitch.TextSize = 11
boostSwitch.ZIndex = 111
boostSwitch.Parent = boostRow

-- ==========================================
-- 3.6 速度設定（デフォルト29）
-- ==========================================
local speedSetRow = Instance.new("Frame")
speedSetRow.Size = UDim2.new(1, 0, 0, 40)
speedSetRow.Position = UDim2.new(0, 0, 0, 225)
speedSetRow.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
speedSetRow.ZIndex = 110
speedSetRow.Parent = menuFrame

local speedSetLabel = Instance.new("TextLabel")
speedSetLabel.Text = "速度設定"
speedSetLabel.Size = UDim2.new(0.5, 0, 1, 0)
speedSetLabel.Position = UDim2.new(0, 10, 0, 0)
speedSetLabel.BackgroundTransparency = 1
speedSetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedSetLabel.Font = Enum.Font.Gotham
speedSetLabel.TextSize = 14
speedSetLabel.TextXAlignment = Enum.TextXAlignment.Left
speedSetLabel.ZIndex = 111
speedSetLabel.Parent = speedSetRow

local speedBoostInput = Instance.new("TextBox")
speedBoostInput.Name = "SpeedBoostInput"
speedBoostInput.Text = "29"  -- ← 29に修正
speedBoostInput.Size = UDim2.new(0, 80, 0, 30)
speedBoostInput.Position = UDim2.new(0.72, 0, 0.5, -15)
speedBoostInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
speedBoostInput.TextColor3 = Color3.fromRGB(255, 215, 0)
speedBoostInput.Font = Enum.Font.GothamBold
speedBoostInput.TextSize = 14
speedBoostInput.ClearTextOnFocus = false
speedBoostInput.ZIndex = 111
speedBoostInput.Parent = speedSetRow

-- ==========================================
-- 3.7 インスタントスティール（手動）
-- ==========================================
local manualRow = Instance.new("Frame")
manualRow.Size = UDim2.new(1, 0, 0, 40)
manualRow.Position = UDim2.new(0, 0, 0, 270)
manualRow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
manualRow.ZIndex = 110
manualRow.Parent = menuFrame

local manualLabel = Instance.new("TextLabel")
manualLabel.Text = "インスタントスティール（手動）"
manualLabel.Size = UDim2.new(0.7, 0, 1, 0)
manualLabel.Position = UDim2.new(0, 10, 0, 0)
manualLabel.BackgroundTransparency = 1
manualLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
manualLabel.Font = Enum.Font.Gotham
manualLabel.TextSize = 14
manualLabel.TextXAlignment = Enum.TextXAlignment.Left
manualLabel.ZIndex = 111
manualLabel.Parent = manualRow

local manualButton = Instance.new("TextButton")
manualButton.Name = "ManualButton"
manualButton.Text = "[ 🎯 ]"
manualButton.Size = UDim2.new(0, 70, 0, 28)
manualButton.Position = UDim2.new(0.78, 0, 0.5, -14)
manualButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
manualButton.TextColor3 = Color3.fromRGB(255, 255, 255)
manualButton.Font = Enum.Font.GothamBold
manualButton.TextSize = 14
manualButton.ZIndex = 111
manualButton.Parent = manualRow

-- ==========================================
-- 3.8 自動スティール
-- ==========================================
local autoRow = Instance.new("Frame")
autoRow.Size = UDim2.new(1, 0, 0, 40)
autoRow.Position = UDim2.new(0, 0, 0, 315)
autoRow.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
autoRow.ZIndex = 110
autoRow.Parent = menuFrame

local autoLabel = Instance.new("TextLabel")
autoLabel.Text = "自動スティール"
autoLabel.Size = UDim2.new(0.7, 0, 1, 0)
autoLabel.Position = UDim2.new(0, 10, 0, 0)
autoLabel.BackgroundTransparency = 1
autoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
autoLabel.Font = Enum.Font.Gotham
autoLabel.TextSize = 14
autoLabel.TextXAlignment = Enum.TextXAlignment.Left
autoLabel.ZIndex = 111
autoLabel.Parent = autoRow

local autoSwitch = Instance.new("TextButton")
autoSwitch.Name = "AutoSwitch"
autoSwitch.Text = "[ OFF ]"
autoSwitch.Size = UDim2.new(0, 70, 0, 28)
autoSwitch.Position = UDim2.new(0.78, 0, 0.5, -14)
autoSwitch.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
autoSwitch.TextColor3 = Color3.fromRGB(255, 255, 255)
autoSwitch.Font = Enum.Font.GothamBold
autoSwitch.TextSize = 11
autoSwitch.ZIndex = 111
autoSwitch.Parent = autoRow

-- ==========================================
-- 3.9 Death（リスポーン）
-- ==========================================
local deathRow = Instance.new("Frame")
deathRow.Size = UDim2.new(1, 0, 0, 40)
deathRow.Position = UDim2.new(0, 0, 0, 360)
deathRow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
deathRow.ZIndex = 110
deathRow.Parent = menuFrame

local deathLabel = Instance.new("TextLabel")
deathLabel.Text = "Death（リスポーン）"
deathLabel.Size = UDim2.new(0.7, 0, 1, 0)
deathLabel.Position = UDim2.new(0, 10, 0, 0)
deathLabel.BackgroundTransparency = 1
deathLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
deathLabel.Font = Enum.Font.Gotham
deathLabel.TextSize = 14
deathLabel.TextXAlignment = Enum.TextXAlignment.Left
deathLabel.ZIndex = 111
deathLabel.Parent = deathRow

local deathButton = Instance.new("TextButton")
deathButton.Name = "DeathButton"
deathButton.Text = "[ ☠️ ]"
deathButton.Size = UDim2.new(0, 70, 0, 28)
deathButton.Position = UDim2.new(0.78, 0, 0.5, -14)
deathButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
deathButton.TextColor3 = Color3.fromRGB(255, 255, 255)
deathButton.Font = Enum.Font.GothamBold
deathButton.TextSize = 14
deathButton.ZIndex = 111
deathButton.Parent = deathRow

-- ==========================================
-- 3.10 アイテムリスト（スクロール内）
-- ==========================================
-- アイテムリストはrefreshMenu()で動的に生成

-- ==========================================
-- 3.11 インスタントスティールUI（画面上部）
-- ==========================================
local stealStatusUI = nil
local statusLabel = nil
local progressBar = nil

local function createStealStatusUI()
    local oldUI = CoreGui:FindFirstChild("StealStatusUI")
    if oldUI then oldUI:Destroy() end
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "StealStatusUI"
    mainFrame.Size = UDim2.new(0, 300, 0, 50)
    mainFrame.Position = UDim2.new(0.5, -150, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.8
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    mainFrame.Visible = true
    mainFrame.ZIndex = 999
    mainFrame.Parent = CoreGui
    
    local label = Instance.new("TextLabel")
    label.Name = "StatusLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🔍 待機中..."
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.ZIndex = 1000
    label.Parent = mainFrame
    
    local bar = Instance.new("Frame")
    bar.Name = "ProgressBar"
    bar.Size = UDim2.new(0, 0, 0, 4)
    bar.Position = UDim2.new(0, 0, 1, -4)
    bar.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    bar.BorderSizePixel = 0
    bar.ZIndex = 1000
    bar.Parent = mainFrame
    
    stealStatusUI = mainFrame
    statusLabel = label
    progressBar = bar
end

createStealStatusUI()

-- ==========================================
-- 3.12 Drop UI（🫨）
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
-- 4. 各機能のイベント
-- ==========================================

-- アイテム自動切り替え（🥶）
switchButton.MouseButton1Click:Connect(function()
    isLooping = not isLooping
    if isLooping then
        switchButton.Text = "[ ON ]"
        switchButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        coldFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        coldButton.Text = "🥶⚡"
        clonerUsed = false
    else
        switchButton.Text = "[ OFF ]"
        switchButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        coldFrame.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        coldButton.Text = "🥶"
    end
end)

-- 切り替え速度
speedInputBox.FocusLost:Connect(function()
    local num = tonumber(speedInputBox.Text)
    if num and num > 0 then
        switchSpeed = num
        speedInputBox.Text = tostring(switchSpeed)
    else
        switchSpeed = 0.001
        speedInputBox.Text = "0.001"
    end
end)

-- ドロップアイテム
dropSwitch.MouseButton1Click:Connect(function()
    dropEnabled = not dropEnabled
    if dropEnabled then
        dropSwitch.Text = "[ ON ]"
        dropSwitch.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        createDropUI()
        if dropUI then
            dropUI.Visible = true
        end
    else
        dropSwitch.Text = "[ OFF ]"
        dropSwitch.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        if dropUI then
            dropUI.Visible = false
        end
    end
end)

-- Speed Boost（✈️）
boostSwitch.MouseButton1Click:Connect(function()
    speedBoostEnabled = not speedBoostEnabled
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if speedBoostEnabled then
        boostSwitch.Text = "[ ON ]"
        boostSwitch.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        boostFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        boostButton.Text = "⚡"
        
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
        boostSwitch.Text = "[ OFF ]"
        boostSwitch.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        boostFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        boostButton.Text = "✈️"
        
        if humanoid then
            humanoid.WalkSpeed = originalWalkSpeed
        end
    end
end)

-- 速度設定（入力）
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

-- インスタントスティール（手動）
local function updateStealStatus(text, color)
    if statusLabel then
        statusLabel.Text = text
        statusLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    end
end

local function resetProgressBar()
    if progressBar then
        progressBar.Size = UDim2.new(0, 0, 0, 4)
    end
end

local function animateProgressBar()
    if progressBar then
        local tween = TweenService:Create(
            progressBar,
            TweenInfo.new(0.5, Enum.EasingStyle.Linear),
            {Size = UDim2.new(1, 0, 0, 4)}
        )
        tween:Play()
        return tween
    end
    return nil
end

local function completePromptWithDelay(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    
    updateStealStatus("⚡ 実行中...", Color3.fromRGB(255, 255, 0))
    local tween = animateProgressBar()
    
    task.wait(0.5)
    
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.01)
        prompt:InputHoldEnd()
    end)
    
    updateStealStatus("✅ 完了！", Color3.fromRGB(46, 204, 113))
    resetProgressBar()
    
    task.wait(1)
    updateStealStatus("🔍 待機中...", Color3.fromRGB(255, 255, 255))
end

local function findAndSteal()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then 
        updateStealStatus("❌ キャラクターが見つかりません", Color3.fromRGB(255, 0, 0))
        task.wait(1)
        updateStealStatus("🔍 待機中...", Color3.fromRGB(255, 255, 255))
        return 
    end
    
    local foundPrompt = nil
    local closestDistance = math.huge
    
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local parent = prompt.Parent
            local pos = nil
            
            if parent:IsA("BasePart") then
                pos = parent.Position
            elseif parent:IsA("Model") then
                local part = parent:FindFirstChild("HumanoidRootPart") or parent:FindFirstChild("Head")
                if part then pos = part.Position end
            end
            
            if pos then
                local distance = (pos - root.Position).Magnitude
                if distance <= prompt.MaxActivationDistance and distance < closestDistance then
                    closestDistance = distance
                    foundPrompt = prompt
                end
            end
        end
    end
    
    if foundPrompt then
        updateStealStatus("🎯 ターゲット発見！", Color3.fromRGB(0, 255, 255))
        task.wait(0.3)
        completePromptWithDelay(foundPrompt)
    else
        updateStealStatus("❌ 近くにプロンプトがありません", Color3.fromRGB(255, 100, 100))
        task.wait(1.5)
        updateStealStatus("🔍 待機中...", Color3.fromRGB(255, 255, 255))
    end
end

manualButton.MouseButton1Click:Connect(function()
    findAndSteal()
end)

-- 🎯ボタン（画面左上）
stealButton.MouseButton1Click:Connect(function()
    findAndSteal()
end)

-- 自動スティール
local autoStealRunning = false

autoSwitch.MouseButton1Click:Connect(function()
    autoStealRunning = not autoStealRunning
    
    if autoStealRunning then
        autoSwitch.Text = "[ ON ]"
        autoSwitch.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        updateStealStatus("🔄 自動モード ON", Color3.fromRGB(0, 255, 255))
        
        task.spawn(function()
            while autoStealRunning do
                findAndSteal()
                task.wait(1)
            end
        end)
    else
        autoSwitch.Text = "[ OFF ]"
        autoSwitch.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        updateStealStatus("⏹ 自動モード OFF", Color3.fromRGB(255, 200, 0))
        task.wait(0.5)
        updateStealStatus("🔍 待機中...", Color3.fromRGB(255, 255, 255))
    end
end)

-- Death（リスポーン）
deathButton.MouseButton1Click:Connect(function()
    topRightFrame.Visible = not topRightFrame.Visible
    if topRightFrame.Visible then
        deathButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        deathButton.Text = "[ ☠️ ON ]"
    else
        deathButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        deathButton.Text = "[ ☠️ ]"
    end
end)

topRightDeathButton.MouseButton1Click:Connect(function()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end
end)

-- ロック状態
local function updateLockStatus()
    if isLocked then
        lockStatusLabel.Text = "ロック中"
        lockStatusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    else
        lockStatusLabel.Text = "ロック解除"
        lockStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end
updateLockStatus()

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

-- メニューリフレッシュ（アイテムリスト）
local function refreshMenu()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then pcall(function() child:Destroy() end) end
    end
    
    local yOffset = 405
    
    for i, itemName in ipairs(activeItems) do
        local itemRow = Instance.new("Frame")
        itemRow.Size = UDim2.new(1, 0, 0, 38)
        itemRow.Position = UDim2.new(0, 0, 0, yOffset + (i-1) * 43)
        itemRow.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        itemRow.ZIndex = 103
        itemRow.Parent = menuFrame
        
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
        
        itemRow.Parent = menuFrame
    end
    
    local offY = yOffset + #activeItems * 43 + 5
    for _, masterName in ipairs(masterItems) do
        if not table.find(activeItems, masterName) then
            local addRow = Instance.new("Frame")
            addRow.Size = UDim2.new(1, 0, 0, 38)
            addRow.Position = UDim2.new(0, 0, 0, offY)
            addRow.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            addRow.ZIndex = 103
            addRow.Parent = menuFrame
            
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
            
            offY = offY + 43
        end
    end
    
    local totalHeight = offY + 20
    menuFrame.Size = UDim2.new(0, 320, 0, math.max(530, totalHeight))
    menuFrame.Position = UDim2.new(0.5, -160, 0.5, -totalHeight/2)
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

toolsButton.MouseButton2Click:Connect(function()
    isLocked = not isLocked
    updateLockStatus()
end)

lockRow.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    updateLockStatus()
end)

coldButton.MouseButton1Click:Connect(function()
    -- 既にswitchButtonで処理済み
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

print("✅ NIKU HUB 起動完了！")
print("🛠️ メニューを開くには🛠️ボタンを押してください")
