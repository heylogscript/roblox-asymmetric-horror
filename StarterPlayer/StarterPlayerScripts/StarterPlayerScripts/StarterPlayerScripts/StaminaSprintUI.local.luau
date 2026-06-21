-- StaminaSprintUI.local.luau
-- Upgraded Premium Movement and HUD System for Roblox
-- Camera bobbing, strafe tilt, dynamic FOV, enhanced glassmorphic UI

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local roundEvents = ReplicatedStorage:WaitForChild("RoundEvents")
local sprintEvent = roundEvents:WaitForChild("SetSprinting")

local Config
local success, err = pcall(function()
	return require(ReplicatedStorage:WaitForChild("RoundConfig"))
end)
if success and err then
	Config = err
else
	Config = {
		MaxStamina = 100,
		MinimumSprintStamina = 8,
	}
end

local MIN_SPRINT_STAMINA = Config.MinimumSprintStamina or 8

--------------------------------------------------------------------------------
-- STATE VARIABLES
--------------------------------------------------------------------------------
local wantsSprint = false
local currentStaminaPercent = 1.0
local currentHealthPercent = 1.0

-- Camera state
local bobTime = 0
local currentBobX = 0
local currentBobY = 0
local currentTilt = 0
local defaultFOV = camera.FieldOfView
if defaultFOV <= 0 or defaultFOV == nil then
	defaultFOV = 70
end
local extraSprintFOV = 12
local fovLerpSpeed = 8

-- UI Animation state
local staminaDeniedShakeTime = 0
local pulseTime = 0

--------------------------------------------------------------------------------
-- UI CREATION (Glassmorphic HUD)
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AbilityUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local hudCard = Instance.new("Frame")
hudCard.Size = UDim2.fromOffset(160, 80)
hudCard.Position = UDim2.new(0, 30, 1, -150)
hudCard.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
hudCard.BackgroundTransparency = 0.25
hudCard.BorderSizePixel = 0
hudCard.Parent = gui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 12)
cardCorner.Parent = hudCard

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(60, 60, 80)
cardStroke.Thickness = 1.5
cardStroke.Transparency = 0.5
cardStroke.Parent = hudCard

local function createAbilityGauge(name, themeColor, baseOffsetX)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(52, 52)
	frame.Position = UDim2.new(0, baseOffsetX, 0.5, -26)
	frame.BackgroundTransparency = 1
	frame.Parent = hudCard

	local trackCircle = Instance.new("Frame")
	trackCircle.Size = UDim2.fromScale(1, 1)
	trackCircle.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	trackCircle.BorderSizePixel = 0
	trackCircle.Parent = frame

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0.5, 0)
	trackCorner.Parent = trackCircle

	local trackStroke = Instance.new("UIStroke")
	trackStroke.Color = Color3.fromRGB(40, 40, 50)
	trackStroke.Thickness = 1.5
	trackStroke.Parent = trackCircle

	local innerBG = Instance.new("Frame")
	innerBG.Size = UDim2.new(1, -6, 1, -6)
	innerBG.Position = UDim2.fromOffset(3, 3)
	innerBG.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
	innerBG.BorderSizePixel = 0
	innerBG.ZIndex = 3
	innerBG.Parent = frame

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0.5, 0)
	innerCorner.Parent = innerBG

	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = themeColor
	glowStroke.Thickness = 1.5
	glowStroke.Transparency = 0.3
	glowStroke.Parent = innerBG

	local fillCircle = Instance.new("Frame")
	fillCircle.Size = UDim2.new(0, 0, 0, 0)
	fillCircle.Position = UDim2.fromScale(0.5, 0.5)
	fillCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	fillCircle.BackgroundColor3 = themeColor
	fillCircle.BorderSizePixel = 0
	fillCircle.ZIndex = 2
	fillCircle.Parent = frame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fillCircle

	local symbolLabel = Instance.new("TextLabel")
	symbolLabel.Size = UDim2.fromScale(1, 1)
	symbolLabel.BackgroundTransparency = 1
	symbolLabel.Font = Enum.Font.GothamBold
	symbolLabel.TextSize = 18
	symbolLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	symbolLabel.Text = name
	symbolLabel.ZIndex = 4
	symbolLabel.Parent = innerBG

	return {
		frame = frame,
		fill = fillCircle,
		label = symbolLabel,
		glow = glowStroke,
		track = trackStroke,
		currentPercent = 1.0,
	}
end

local healthGauge = createAbilityGauge("♥", Color3.fromRGB(230, 45, 65), 18)
local staminaGauge = createAbilityGauge("⚡", Color3.fromRGB(50, 160, 255), 90)

--------------------------------------------------------------------------------
-- AUXILIARY FUNCTIONS
--------------------------------------------------------------------------------
local function sendSprint(value)
	wantsSprint = value
	sprintEvent:FireServer(value)
end

local function getHumanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getMovementInfo()
	local character = player.Character
	if not character then return 0, false, false, false, nil, nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid then return 0, false, false, false, nil, nil end

	local velocity = rootPart.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local isMoving = speed > 1
	local isSprinting = player:GetAttribute("Sprinting") == true
	local isOnGround = humanoid.FloorMaterial ~= Enum.Material.Air

	return speed, isMoving, isSprinting, isOnGround, rootPart, humanoid
end

local function playStaminaDeniedShake()
	staminaDeniedShakeTime = 0.35
end

--------------------------------------------------------------------------------
-- INPUT CONNECTIONS
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		local role = player:GetAttribute("Role") or "Lobby"
		if role ~= "Lobby" then
			local stamina = player:GetAttribute("Stamina") or 0
			if stamina < MIN_SPRINT_STAMINA then
				playStaminaDeniedShake()
			else
				sendSprint(true)
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sendSprint(false)
	end
end)

--------------------------------------------------------------------------------
-- CORE UPDATE LOOP (CAMERA + UI ANIMATION)
--------------------------------------------------------------------------------
RunService:BindToRenderStep("UpgradedMovementSystem", Enum.RenderPriority.Camera.Value + 10, function(dt)
	local speed, isMoving, isSprinting, isOnGround, rootPart, humanoid = getMovementInfo()
	local isAlive = humanoid and humanoid.Health > 0

	local stamina = player:GetAttribute("Stamina") or 0
	local maxStamina = player:GetAttribute("MaxStamina") or 100
	local staminaPercent = stamina / maxStamina

	----------------------------------------------------------------------------
	-- CAMERA CALCULATIONS (BOB, TILT & FOV)
	----------------------------------------------------------------------------
	if isAlive and isOnGround then
		local frequency, amplitudeX, amplitudeY

		if isMoving then
			if isSprinting then
				frequency = 14
				amplitudeX = 0.08
				amplitudeY = 0.12
			else
				frequency = 10
				amplitudeX = 0.04
				amplitudeY = 0.06
			end
			bobTime = bobTime + dt * frequency * (speed / 16)
		else
			frequency = 1.6
			amplitudeX = 0.012
			amplitudeY = 0.018

			if staminaPercent < 0.25 then
				frequency = 3.2
				amplitudeX = 0.02
				amplitudeY = 0.03
			end

			bobTime = bobTime + dt * frequency
		end

		local targetBobX = math.cos(bobTime) * amplitudeX
		local targetBobY = math.sin(bobTime * 2) * amplitudeY

		currentBobX = currentBobX + (targetBobX - currentBobX) * math.clamp(dt * 10, 0, 1)
		currentBobY = currentBobY + (targetBobY - currentBobY) * math.clamp(dt * 10, 0, 1)

		local targetTilt = 0
		if isMoving and rootPart then
			local relativeVelocity = rootPart.CFrame:VectorToObjectSpace(rootPart.AssemblyLinearVelocity)
			targetTilt = -relativeVelocity.X * 0.0012
		end
		currentTilt = currentTilt + (targetTilt - currentTilt) * math.clamp(dt * 8, 0, 1)

		local bobOffset = CFrame.new(currentBobX, currentBobY, 0)
		local tiltOffset = CFrame.Angles(0, 0, currentTilt)
		camera.CFrame = camera.CFrame * bobOffset * tiltOffset

		local targetFOV = defaultFOV
		if isMoving and isSprinting then
			targetFOV = defaultFOV + extraSprintFOV
		end
		camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * math.clamp(dt * fovLerpSpeed, 0, 1)
	else
		currentBobX = currentBobX + (0 - currentBobX) * math.clamp(dt * 6, 0, 1)
		currentBobY = currentBobY + (0 - currentBobY) * math.clamp(dt * 6, 0, 1)
		currentTilt = currentTilt + (0 - currentTilt) * math.clamp(dt * 6, 0, 1)

		local bobOffset = CFrame.new(currentBobX, currentBobY, 0)
		local tiltOffset = CFrame.Angles(0, 0, currentTilt)
		camera.CFrame = camera.CFrame * bobOffset * tiltOffset

		camera.FieldOfView = camera.FieldOfView + (defaultFOV - camera.FieldOfView) * math.clamp(dt * fovLerpSpeed, 0, 1)
	end

	----------------------------------------------------------------------------
	-- UI ANIMATION & FEEDBACK
	----------------------------------------------------------------------------
	pulseTime = pulseTime + dt

	if humanoid then
		local targetHealthPercent = 0
		if humanoid.MaxHealth > 0 then
			targetHealthPercent = humanoid.Health / humanoid.MaxHealth
		end

		healthGauge.currentPercent = healthGauge.currentPercent + (targetHealthPercent - healthGauge.currentPercent) * math.clamp(dt * 12, 0, 1)

		local maxDiameter = 46
		healthGauge.fill.Size = UDim2.fromOffset(maxDiameter * healthGauge.currentPercent, maxDiameter * healthGauge.currentPercent)

		local targetStaminaPercent = stamina / maxStamina

		staminaGauge.currentPercent = staminaGauge.currentPercent + (targetStaminaPercent - staminaGauge.currentPercent) * math.clamp(dt * 12, 0, 1)
		staminaGauge.fill.Size = UDim2.fromOffset(maxDiameter * staminaGauge.currentPercent, maxDiameter * staminaGauge.currentPercent)

		local slowPulse = math.sin(pulseTime * 2) * 0.05 + 1.0
		local fastPulse = math.sin(pulseTime * 12) * 0.08 + 1.0

		if targetHealthPercent < 0.35 then
			healthGauge.label.TextColor3 = Color3.fromRGB(255, 60, 60)
			healthGauge.frame.Size = UDim2.fromOffset(52 * fastPulse, 52 * fastPulse)
			healthGauge.glow.Color = Color3.fromRGB(255, 30, 30)
			healthGauge.glow.Transparency = math.abs(math.sin(pulseTime * 6)) * 0.5
		else
			healthGauge.label.TextColor3 = Color3.fromRGB(255, 255, 255)
			healthGauge.frame.Size = UDim2.fromOffset(52, 52)
			healthGauge.glow.Color = Color3.fromRGB(230, 45, 65)
			healthGauge.glow.Transparency = 0.4
		end

		local staminaShakeOffset = 0
		if staminaDeniedShakeTime > 0 then
			staminaDeniedShakeTime = math.max(0, staminaDeniedShakeTime - dt)
			local shakeIntensity = (staminaDeniedShakeTime / 0.35) * 6
			staminaShakeOffset = math.sin(pulseTime * 60) * shakeIntensity

			staminaGauge.label.TextColor3 = Color3.fromRGB(255, 50, 50)
			staminaGauge.glow.Color = Color3.fromRGB(255, 20, 20)
			staminaGauge.glow.Transparency = 0.1
		elseif targetStaminaPercent < 0.25 then
			staminaGauge.label.TextColor3 = Color3.fromRGB(255, 120, 100)
			staminaGauge.frame.Size = UDim2.fromOffset(52 * slowPulse, 52 * slowPulse)
			staminaGauge.glow.Color = Color3.fromRGB(255, 100, 100)
			staminaGauge.glow.Transparency = math.abs(math.sin(pulseTime * 4)) * 0.4
		elseif isSprinting and isMoving then
			staminaGauge.label.TextColor3 = Color3.fromRGB(150, 220, 255)
			staminaGauge.frame.Size = UDim2.fromOffset(52 * slowPulse, 52 * slowPulse)
			staminaGauge.glow.Color = Color3.fromRGB(50, 200, 255)
			staminaGauge.glow.Transparency = 0.15
		else
			staminaGauge.label.TextColor3 = Color3.fromRGB(255, 255, 255)
			staminaGauge.frame.Size = UDim2.fromOffset(52, 52)
			staminaGauge.glow.Color = Color3.fromRGB(50, 160, 255)
			staminaGauge.glow.Transparency = 0.4
		end

		staminaGauge.frame.Position = UDim2.new(0, 90 + staminaShakeOffset, 0.5, -26)
	end

	if wantsSprint and stamina <= 0 then
		sendSprint(false)
	end
end)
