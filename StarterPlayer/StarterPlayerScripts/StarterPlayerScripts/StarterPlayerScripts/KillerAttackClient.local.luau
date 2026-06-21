local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local eventsFolder = ReplicatedStorage:WaitForChild("RoundEvents")
local attackEvent = eventsFolder:WaitForChild("KillerAttack")
local feedbackEvent = eventsFolder:WaitForChild("KillerAttackFeedback")

local gui = Instance.new("ScreenGui")
gui.Name = "KillerAttackUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Hitmarker container (center of screen)
local hitmarkerContainer = Instance.new("Frame")
hitmarkerContainer.Size = UDim2.fromOffset(40, 40)
hitmarkerContainer.Position = UDim2.new(0.5, -20, 0.5, -20)
hitmarkerContainer.BackgroundTransparency = 1
hitmarkerContainer.Visible = false
hitmarkerContainer.Parent = gui

local function createHitmarkerLine()
	local line = Instance.new("Frame")
	line.Size = UDim2.fromOffset(2, 14)
	line.Position = UDim2.new(0.5, -1, 0.5, -7)
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BorderSizePixel = 0
	line.BackgroundTransparency = 1
	line.Parent = hitmarkerContainer
	return line
end

local hitmarkerLines = {
	createHitmarkerLine(),
	createHitmarkerLine(),
}

hitmarkerLines[1].Rotation = 45
hitmarkerLines[2].Rotation = -45

-- Screen flash frame (red vignette on hit)
local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.fromScale(1, 1)
flashFrame.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.ZIndex = 10
flashFrame.Parent = gui

-- Cooldown display (bottom-right)
local cooldownFrame = Instance.new("Frame")
cooldownFrame.Size = UDim2.fromOffset(190, 38)
cooldownFrame.Position = UDim2.new(1, -214, 1, -78)
cooldownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
cooldownFrame.BackgroundTransparency = 0.1
cooldownFrame.BorderSizePixel = 0
cooldownFrame.Visible = false
cooldownFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = cooldownFrame

local attackText = Instance.new("TextLabel")
attackText.Size = UDim2.new(1, -16, 1, 0)
attackText.Position = UDim2.fromOffset(8, 0)
attackText.BackgroundTransparency = 1
attackText.Font = Enum.Font.GothamBold
attackText.TextSize = 15
attackText.TextColor3 = Color3.fromRGB(255, 255, 255)
attackText.Text = "Attack ready"
attackText.Parent = cooldownFrame

local canRequestAttack = true

------------------------------------------------------------------
-- HITMARKER ANIMATION
------------------------------------------------------------------
local function playHitmarker()
	hitmarkerContainer.Visible = true

	for _, line in ipairs(hitmarkerLines) do
		line.BackgroundTransparency = 0
		line.Size = UDim2.fromOffset(2, 16)
	end

	-- Slight outward scale burst, then fade
	local scaleTween = TweenService:Create(hitmarkerLines[1], TweenInfo.new(0.05), { Size = UDim2.fromOffset(2, 22) })
	local scaleTween2 = TweenService:Create(hitmarkerLines[2], TweenInfo.new(0.05), { Size = UDim2.fromOffset(2, 22) })

	local fadeTween = TweenService:Create(hitmarkerLines[1], TweenInfo.new(0.25), { BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 16) })
	local fadeTween2 = TweenService:Create(hitmarkerLines[2], TweenInfo.new(0.25), { BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 16) })

	scaleTween:Play()
	scaleTween2:Play()

	scaleTween.Completed:Connect(function()
		fadeTween:Play()
		fadeTween2:Play()
	end)

	fadeTween.Completed:Connect(function()
		hitmarkerContainer.Visible = false
	end)
end

------------------------------------------------------------------
-- SCREEN FLASH (red vignette on hit)
------------------------------------------------------------------
local function playHitFlash()
	flashFrame.BackgroundTransparency = 0.6
	local fadeTween = TweenService:Create(flashFrame, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
	fadeTween:Play()
end

------------------------------------------------------------------
-- MISS INDICATOR
------------------------------------------------------------------
local function playMissIndicator()
	-- Quick subtle red hitmarker for miss
	hitmarkerContainer.Visible = true

	for _, line in ipairs(hitmarkerLines) do
		line.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		line.BackgroundTransparency = 0
		line.Size = UDim2.fromOffset(2, 10)
	end

	local fadeTween = TweenService:Create(hitmarkerLines[1], TweenInfo.new(0.15), { BackgroundTransparency = 1 })
	local fadeTween2 = TweenService:Create(hitmarkerLines[2], TweenInfo.new(0.15), { BackgroundTransparency = 1 })

	fadeTween:Play()
	fadeTween2:Play()

	task.delay(0.2, function()
		for _, line in ipairs(hitmarkerLines) do
			line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
		hitmarkerContainer.Visible = false
	end)
end

------------------------------------------------------------------
-- DAMAGE NUMBERS (BillboardGui on hit survivor)
------------------------------------------------------------------
local function createDamageNumber(survivorName, damage)
	local survivor = Players:FindFirstChild(survivorName)
	if not survivor or not survivor.Character then return end

	local root = survivor.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 28
	label.TextColor3 = Color3.fromRGB(255, 200, 60)
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = "-" .. damage
	label.Parent = billboard

	local goal = { StudsOffset = Vector3.new(0, 8, 0) }
	local floatTween = TweenService:Create(billboard, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	floatTween:Play()

	local fadeGoal = { TextTransparency = 1 }
	local fadeTween = TweenService:Create(label, TweenInfo.new(0.8), fadeGoal)
	fadeTween:Play()

	fadeTween.Completed:Connect(function()
		billboard:Destroy()
	end)
end

------------------------------------------------------------------
-- ATTACK INPUT
------------------------------------------------------------------
local function updateVisibility()
	cooldownFrame.Visible = player:GetAttribute("Role") == "Killer"
end

local function requestAttack()
	if player:GetAttribute("Role") ~= "Killer" then return end
	if not canRequestAttack then return end

	canRequestAttack = false
	attackText.Text = "Attacking..."
	attackEvent:FireServer()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		requestAttack()
	end
end)

------------------------------------------------------------------
-- FEEDBACK EVENT (hitmarker + damage numbers + cooldown)
------------------------------------------------------------------
feedbackEvent.OnClientEvent:Connect(function(data)
	local cooldown = data.cooldown or 1
	local hitCount = data.hitCount or 0
	local hits = data.hits or {}

	if hitCount > 0 then
		attackText.Text = "Hit x" .. hitCount
		playHitmarker()
		playHitFlash()

		for _, hitData in ipairs(hits) do
			createDamageNumber(hitData.playerName, hitData.damage)
		end
	else
		attackText.Text = "Miss"
		playMissIndicator()
	end

	task.wait(0.35)

	local startedAt = os.clock()
	while os.clock() - startedAt < cooldown do
		local remaining = cooldown - (os.clock() - startedAt)
		attackText.Text = string.format("Cooldown %.1fs", math.max(remaining, 0))
		task.wait(0.05)
	end

	attackText.Text = "Attack ready"
	canRequestAttack = true
end)

player:GetAttributeChangedSignal("Role"):Connect(function()
	updateVisibility()
	canRequestAttack = true
	attackText.Text = "Attack ready"
end)

updateVisibility()
