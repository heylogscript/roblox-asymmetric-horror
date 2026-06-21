local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local eventsFolder = ReplicatedStorage:WaitForChild("RoundEvents")
local abilityEvent = eventsFolder:WaitForChild("KillerAbilityActivate")
local feedbackEvent = eventsFolder:WaitForChild("KillerAbilityFeedback")

local gui = Instance.new("ScreenGui")
gui.Name = "KillerAbilityUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local cooldownFrame = Instance.new("Frame")
cooldownFrame.Size = UDim2.fromOffset(220, 38)
cooldownFrame.Position = UDim2.new(1, -244, 1, -48)
cooldownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
cooldownFrame.BackgroundTransparency = 0.1
cooldownFrame.BorderSizePixel = 0
cooldownFrame.Visible = false
cooldownFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = cooldownFrame

local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.fromOffset(28, 38)
keyLabel.Position = UDim2.fromOffset(0, 0)
keyLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
keyLabel.BackgroundTransparency = 0.3
keyLabel.Font = Enum.Font.GothamBold
keyLabel.TextSize = 16
keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
keyLabel.Text = "Q"
keyLabel.Parent = cooldownFrame

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 8)
keyCorner.Parent = keyLabel

local abilityText = Instance.new("TextLabel")
abilityText.Size = UDim2.new(1, -36, 1, 0)
abilityText.Position = UDim2.fromOffset(32, 0)
abilityText.BackgroundTransparency = 1
abilityText.Font = Enum.Font.GothamBold
abilityText.TextSize = 14
abilityText.TextColor3 = Color3.fromRGB(255, 200, 100)
abilityText.TextXAlignment = Enum.TextXAlignment.Left
abilityText.Text = "Habilidade [Q]"
abilityText.Parent = cooldownFrame

local canUseAbility = true

local abilityNames = {
	sonicScream = "Grito Sônico",
	charge = "Investida",
	teleportPlace = "Marca",
	teleportExecute = "Ritmo!",
	danceStart = "Dança",
	danceEnd = "Pronto",
}

local function updateVisibility()
	cooldownFrame.Visible = player:GetAttribute("Role") == "Killer"
end

local function startCooldown(duration, displayName)
	local startedAt = os.clock()

	while os.clock() - startedAt < duration do
		local remaining = duration - (os.clock() - startedAt)
		abilityText.Text = string.format("%s (%.1fs)", displayName or "Cooldown", math.max(remaining, 0))
		abilityText.TextColor3 = Color3.fromRGB(255, 200, 100)
		task.wait(0.05)
	end

	abilityText.Text = "Habilidade [Q]"
	abilityText.TextColor3 = Color3.fromRGB(255, 200, 100)
	canUseAbility = true
end

local function requestAbility()
	if player:GetAttribute("Role") ~= "Killer" then return end
	if not canUseAbility then return end

	canUseAbility = false
	abilityText.Text = "Ativando..."
	abilityText.TextColor3 = Color3.fromRGB(200, 200, 200)
	abilityEvent:FireServer()

	task.delay(1, function()
		if not canUseAbility then
			canUseAbility = true
			abilityText.Text = "Habilidade [Q]"
			abilityText.TextColor3 = Color3.fromRGB(255, 200, 100)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		requestAbility()
	end
end)

--------------------------------------------------------------------------------
-- SONIC SCREAM
--------------------------------------------------------------------------------
local function playSonicScream(origin, radius)
	local shakeStart = os.clock()
	local shakeConn = RunService.RenderStepped:Connect(function()
		if os.clock() - shakeStart > 0.35 then
			shakeConn:Disconnect()
			return
		end
		camera.CFrame = camera.CFrame * CFrame.new(
			math.random(-100, 100) / 100 * 4,
			math.random(-100, 100) / 100 * 4,
			0
		)
	end)

	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 220, 150)
	flash.BackgroundTransparency = 0.75
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = gui

	local flashTween = TweenService:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
	flashTween:Play()
	flashTween.Completed:Connect(function()
		flash:Destroy()
	end)

	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromOffset(10, 10)
	ring.Position = UDim2.new(0.5, -5, 0.5, -5)
	ring.BackgroundTransparency = 1
	ring.BorderColor3 = Color3.fromRGB(255, 200, 100)
	ring.BorderSizePixel = 3
	ring.ZIndex = 8
	ring.Parent = gui

	local expandSize = radius * 6
	local expandTween = TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(expandSize, expandSize),
		Position = UDim2.new(0.5, -expandSize / 2, 0.5, -expandSize / 2),
		BorderColor3 = Color3.fromRGB(255, 255, 200),
	})
	expandTween:Play()

	local fadeTween = TweenService:Create(ring, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BorderColor3 = Color3.fromRGB(255, 200, 100),
	})
	task.delay(0.2, function()
		fadeTween:Play()
	end)

	expandTween.Completed:Connect(function()
		task.delay(0.1, function()
			ring:Destroy()
		end)
	end)
end

--------------------------------------------------------------------------------
-- CHARGE
--------------------------------------------------------------------------------
local function playCharge(startPos, endPos, duration)
	local chargeDir = (endPos - startPos).Unit
	if chargeDir.Magnitude < 0.1 then chargeDir = Vector3.new(0, 0, -1) end

	local originalType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local chargeConn
	chargeConn = RunService.RenderStepped:Connect(function()
		if not chargeConn then return end
		if not player.Character then
			chargeConn:Disconnect()
			chargeConn = nil
			return
		end

		local head = player.Character:FindFirstChild("Head")
		if head then
			local camPos = head.Position - chargeDir * 8 + Vector3.new(0, 5, 0)
			local lookAt = head.Position + chargeDir * 15
			camera.CFrame = CFrame.lookAt(camPos, lookAt)
		end
	end)

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	overlay.BackgroundTransparency = 0.9
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 10
	overlay.Parent = gui

	local overlayTween = TweenService:Create(overlay, TweenInfo.new(duration), { BackgroundTransparency = 1 })
	overlayTween:Play()
	overlayTween.Completed:Connect(function()
		overlay:Destroy()
	end)

	task.delay(duration, function()
		if chargeConn then
			chargeConn:Disconnect()
			chargeConn = nil
		end
		camera.CameraType = originalType
	end)
end

--------------------------------------------------------------------------------
-- TELEPORT PLACE
--------------------------------------------------------------------------------
local function playTeleportPlace(markerPos)
	local ping = Instance.new("Frame")
	ping.Size = UDim2.fromOffset(20, 20)
	ping.Position = UDim2.new(0.5, -10, 0.5, -10)
	ping.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
	ping.BackgroundTransparency = 0.5
	ping.BorderSizePixel = 0
	ping.ZIndex = 8
	ping.Parent = gui

	local pingCorner = Instance.new("UICorner")
	pingCorner.CornerRadius = UDim.new(1, 0)
	pingCorner.Parent = ping

	local pingTween = TweenService:Create(ping, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(100, 100),
		Position = UDim2.new(0.5, -50, 0.5, -50),
		BackgroundTransparency = 1,
	})
	pingTween:Play()
	pingTween.Completed:Connect(function()
		ping:Destroy()
	end)

	local markerLabel = Instance.new("TextLabel")
	markerLabel.Size = UDim2.fromScale(1, 1)
	markerLabel.Position = UDim2.new(0.5, -50, 0.75, 0)
	markerLabel.BackgroundTransparency = 1
	markerLabel.Font = Enum.Font.GothamBold
	markerLabel.TextSize = 18
	markerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	markerLabel.TextStrokeTransparency = 0.3
	markerLabel.Text = "Marca colocada!"
	markerLabel.TextTransparency = 0
	markerLabel.Parent = gui

	markerLabel:TweenPosition(UDim2.new(0.5, -50, 0.7, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
	local labelFade = TweenService:Create(markerLabel, TweenInfo.new(0.8), { TextTransparency = 1 })
	task.delay(0.3, function()
		labelFade:Play()
	end)
	labelFade.Completed:Connect(function()
		markerLabel:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- TELEPORT EXECUTE
--------------------------------------------------------------------------------
local function playTeleportExecute(startPos, endPos)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 0.7
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = gui

	local flashTween = TweenService:Create(flash, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
	flashTween:Play()
	flashTween.Completed:Connect(function()
		flash:Destroy()
	end)

	local shakeConn
	local shakeStart = os.clock()
	shakeConn = RunService.RenderStepped:Connect(function()
		if os.clock() - shakeStart > 0.15 then
			shakeConn:Disconnect()
			return
		end
		camera.CFrame = camera.CFrame * CFrame.new(
			math.random(-100, 100) / 100 * 3,
			math.random(-100, 100) / 100 * 3,
			0
		)
	end)

	local teleportLabel = Instance.new("TextLabel")
	teleportLabel.Size = UDim2.fromScale(1, 1)
	teleportLabel.Position = UDim2.new(0.5, -60, 0.75, 0)
	teleportLabel.BackgroundTransparency = 1
	teleportLabel.Font = Enum.Font.GothamBold
	teleportLabel.TextSize = 20
	teleportLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	teleportLabel.TextStrokeTransparency = 0.3
	teleportLabel.Text = "Ritmo do Tambor!"
	teleportLabel.TextTransparency = 0
	teleportLabel.Parent = gui

	teleportLabel:TweenPosition(UDim2.new(0.5, -60, 0.7, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
	local labelFade = TweenService:Create(teleportLabel, TweenInfo.new(1), { TextTransparency = 1 })
	task.delay(0.4, function()
		labelFade:Play()
	end)
	labelFade.Completed:Connect(function()
		teleportLabel:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- DANCE
--------------------------------------------------------------------------------
local function playDanceStart(center, radius, duration)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(255, 80, 200)
	overlay.BackgroundTransparency = 0.92
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 5
	overlay.Parent = gui

	local function pulseOverlay()
		if not overlay.Parent then return end

		local pulseUp = TweenService:Create(overlay, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0.8
		})
		local pulseDown = TweenService:Create(overlay, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0.92
		})

		pulseUp:Play()
		pulseUp.Completed:Connect(function()
			if not overlay.Parent then return end
			pulseDown:Play()
			pulseDown.Completed:Connect(function()
				if not overlay.Parent then return end
				pulseOverlay()
			end)
		end)
	end

	pulseOverlay()

	task.delay(duration, function()
		if overlay.Parent then
			local fadeOut = TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				overlay:Destroy()
			end)
		end
	end)

	local danceLabel = Instance.new("TextLabel")
	danceLabel.Size = UDim2.fromScale(1, 1)
	danceLabel.Position = UDim2.new(0.5, -70, 0.75, 0)
	danceLabel.BackgroundTransparency = 1
	danceLabel.Font = Enum.Font.GothamBold
	danceLabel.TextSize = 18
	danceLabel.TextColor3 = Color3.fromRGB(255, 100, 200)
	danceLabel.TextStrokeTransparency = 0.3
	danceLabel.Text = "Dança Encantadora!"
	danceLabel.TextTransparency = 0
	danceLabel.Parent = gui

	danceLabel:TweenPosition(UDim2.new(0.5, -70, 0.7, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
	local labelFade = TweenService:Create(danceLabel, TweenInfo.new(duration), { TextTransparency = 1 })
	task.delay(duration - 0.5, function()
		labelFade:Play()
	end)
	labelFade.Completed:Connect(function()
		danceLabel:Destroy()
	end)
end

local function playDanceEnd()
end

--------------------------------------------------------------------------------
-- DENIED
--------------------------------------------------------------------------------
local function playDenied()
	abilityText.Text = "Em cooldown!"
	abilityText.TextColor3 = Color3.fromRGB(255, 80, 80)
end

--------------------------------------------------------------------------------
-- FEEDBACK HANDLER
--------------------------------------------------------------------------------
feedbackEvent.OnClientEvent:Connect(function(data)
	if not data or not data.type then return end

	if data.type == "denied" then
		playDenied()
		startCooldown(data.cooldown, "Cooldown")
		return
	end

	local displayName = abilityNames[data.type] or "Habilidade"

	if data.type == "sonicScream" then
		playSonicScream(data.origin, data.radius)
		abilityText.Text = "Grito Sônico!"
	elseif data.type == "charge" then
		playCharge(data.startPos, data.endPos, data.duration)
		abilityText.Text = "Investida!"
	elseif data.type == "teleportPlace" then
		playTeleportPlace(data.markerPos)
		abilityText.Text = "Marca colocada!"
	elseif data.type == "teleportExecute" then
		playTeleportExecute(data.startPos, data.endPos)
		abilityText.Text = "Ritmo!"
	elseif data.type == "danceStart" then
		playDanceStart(data.center, data.radius, data.duration)
		abilityText.Text = "Dançando!"
	elseif data.type == "danceEnd" then
		playDanceEnd()
		abilityText.Text = "Dança acabou"
	end

	if data.cooldown and data.cooldown > 0 then
		startCooldown(data.cooldown, displayName)
	else
		canUseAbility = true
	end
end)

player:GetAttributeChangedSignal("Role"):Connect(function()
	updateVisibility()
	canUseAbility = true
	abilityText.Text = "Habilidade [Q]"
	abilityText.TextColor3 = Color3.fromRGB(255, 200, 100)
end)

updateVisibility()
