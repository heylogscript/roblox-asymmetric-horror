local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("RoundConfig"))

local eventsFolder = ReplicatedStorage:FindFirstChild("RoundEvents") or Instance.new("Folder")
eventsFolder.Name = "RoundEvents"
eventsFolder.Parent = ReplicatedStorage

local abilityEvent = eventsFolder:FindFirstChild("KillerAbilityActivate") or Instance.new("RemoteEvent")
abilityEvent.Name = "KillerAbilityActivate"
abilityEvent.Parent = eventsFolder

local feedbackEvent = eventsFolder:FindFirstChild("KillerAbilityFeedback") or Instance.new("RemoteEvent")
feedbackEvent.Name = "KillerAbilityFeedback"
feedbackEvent.Parent = eventsFolder

local cooldowns = {}
local teleportMarkers = {}
local activePulls = {}
local activeCharges = {}

local function getCharacter(player)
	local character = player.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	return character, root, humanoid
end

local function getAliveSurvivors()
	local survivors = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("Role") == "Survivor" then
			local _, root, humanoid = getCharacter(player)
			if root and humanoid and humanoid.Health > 0 then
				table.insert(survivors, { player = player, root = root, humanoid = humanoid })
			end
		end
	end

	return survivors
end

local function isOnCooldown(player)
	local cd = cooldowns[player]
	return cd and os.clock() < cd
end

local function setCooldown(player, duration)
	cooldowns[player] = os.clock() + duration
end

local function getKillerCooldown(player)
	local killerName = player:GetAttribute("BrainrotKiller")
	return Config.AbilityCooldowns[killerName] or 10
end

--------------------------------------------------------------------------------
-- GRITO SÔNICO (Tralalero Tralala)
--------------------------------------------------------------------------------
local function sonicScream(killer)
	local _, root, humanoid = getCharacter(killer)
	if not root then return end

	local radius = Config.SonicScreamRadius
	local damage = Config.SonicScreamDamage
	local origin = root.Position

	local ring = Instance.new("Part")
	ring.Name = "SonicRing"
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(1, 0.5, 1)
	ring.CFrame = CFrame.new(origin)
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 200, 80)
	ring.Transparency = 0.4
	ring.Parent = workspace
	Debris:AddItem(ring, 0.5)

	for i = 1, 8 do
		local progress = i / 8
		local currentRadius = radius * progress
		ring.Size = Vector3.new(currentRadius * 2, 0.5, currentRadius * 2)
		ring.Transparency = 0.3 + 0.5 * progress
		task.wait(0.025)
	end

	local survivors = getAliveSurvivors()
	local hitData = {}

	for _, data in ipairs(survivors) do
		local dist = (data.root.Position - origin).Magnitude
		if dist <= radius then
			local originalSpeed = data.humanoid.WalkSpeed
			data.humanoid:TakeDamage(damage)
			data.humanoid.WalkSpeed = originalSpeed * Config.SonicScreamSlowAmount

			task.delay(Config.SonicScreamSlowDuration, function()
				if data.humanoid and data.humanoid.Parent then
					data.humanoid.WalkSpeed = originalSpeed
				end
			end)

			table.insert(hitData, {
				playerName = data.player.Name,
				damage = damage,
				position = data.root.Position,
			})
		end
	end

	local cd = getKillerCooldown(killer)
	setCooldown(killer, cd)

	feedbackEvent:FireClient(killer, {
		type = "sonicScream",
		cooldown = cd,
		origin = origin,
		radius = radius,
		hits = hitData,
	})
end

--------------------------------------------------------------------------------
-- INVESTIDA CROCODILO (Bombardiro Crocodilo)
--------------------------------------------------------------------------------
local function crocodileCharge(killer)
	local _, root, humanoid = getCharacter(killer)
	if not root then return end

	if activeCharges[killer] then return end
	activeCharges[killer] = true

	local direction = root.CFrame.LookVector
	local distance = Config.ChargeDistance
	local speed = Config.ChargeSpeed
	local damage = Config.ChargeDamage
	local hitRadius = Config.ChargeHitRadius

	local startPos = root.Position

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { killer.Character }

	local result = workspace:Raycast(startPos, direction * distance, rayParams)
	local targetPos

	if result then
		targetPos = result.Position - direction * 4
	else
		targetPos = startPos + direction * distance
	end

	local actualDist = (targetPos - startPos).Magnitude
	local duration = math.min(actualDist / speed, 0.5)

	local origSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = speed
	humanoid.AutoRotate = false

	local moveTarget = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
	humanoid:MoveTo(moveTarget)

	local centerLine = Instance.new("Part")
	centerLine.Name = "ChargeTrail"
	centerLine.Anchored = true
	centerLine.CanCollide = false
	centerLine.CanQuery = false
	centerLine.Size = Vector3.new(1, 1, 1)
	centerLine.CFrame = CFrame.new(startPos)
	centerLine.Material = Enum.Material.Neon
	centerLine.Color = Color3.fromRGB(100, 200, 255)
	centerLine.Transparency = 0.3
	centerLine.Parent = workspace
	Debris:AddItem(centerLine, 1)

	local hitPlayers = {}
	local chargeStart = os.clock()
	local chargeConn = RunService.Heartbeat:Connect(function()
		if not root or not root.Parent or not chargeConn then
			return
		end

		local elapsed = os.clock() - chargeStart
		if elapsed >= duration then
			chargeConn:Disconnect()
			chargeConn = nil
			return
		end

		humanoid:MoveTo(moveTarget)
		centerLine.CFrame = root.CFrame

		local survivors = getAliveSurvivors()
		for _, data in ipairs(survivors) do
			if not hitPlayers[data.player] then
				local dist = (data.root.Position - root.Position).Magnitude
				if dist < hitRadius then
					hitPlayers[data.player] = true
					data.humanoid:TakeDamage(damage)

					local knockDir = (data.root.Position - root.Position).Unit
					data.root.AssemblyLinearVelocity = knockDir * 50 + Vector3.new(0, 25, 0)
				end
			end
		end
	end)

	task.delay(duration, function()
		if chargeConn then
			chargeConn:Disconnect()
			chargeConn = nil
		end

		humanoid:MoveTo(nil)

		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = origSpeed
			humanoid.AutoRotate = true
		end

		activeCharges[killer] = nil
	end)

	local cd = getKillerCooldown(killer)
	setCooldown(killer, cd)

	feedbackEvent:FireClient(killer, {
		type = "charge",
		cooldown = cd,
		startPos = startPos,
		endPos = targetPos,
		duration = duration,
	})
end

--------------------------------------------------------------------------------
-- RITMO DO TAMBOR (Tung Tung Tung Sahur)
--------------------------------------------------------------------------------
local function drumTeleport(killer)
	local _, root, humanoid = getCharacter(killer)
	if not root then return end

	local marker = teleportMarkers[killer]

	if marker then
		local targetPos = marker.position + Vector3.new(0, 2, 0)
		local startPos = root.Position

		local originEffect = Instance.new("Part")
		originEffect.Name = "TeleportFlash"
		originEffect.Anchored = true
		originEffect.CanCollide = false
		originEffect.CanQuery = false
		originEffect.Size = Vector3.new(3, 3, 3)
		originEffect.CFrame = CFrame.new(startPos)
		originEffect.Material = Enum.Material.Neon
		originEffect.Color = Color3.fromRGB(255, 150, 50)
		originEffect.Transparency = 0.2
		originEffect.Parent = workspace
		Debris:AddItem(originEffect, 0.6)

		root.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, root.Orientation.Y * math.pi / 180, 0)

		if marker.markerPart then
			marker.markerPart:Destroy()
		end

		teleportMarkers[killer] = nil

		local cd = getKillerCooldown(killer)
		setCooldown(killer, cd)

		feedbackEvent:FireClient(killer, {
			type = "teleportExecute",
			cooldown = cd,
			startPos = startPos,
			endPos = targetPos,
		})
	else
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { killer.Character }

		local direction = root.CFrame.LookVector
		local result = workspace:Raycast(root.Position, direction * Config.TeleportRange, rayParams)
		local markerPos = result and result.Position or (root.Position + direction * Config.TeleportRange)
		markerPos = markerPos + Vector3.new(0, 0.5, 0)

		local markerPart = Instance.new("Part")
		markerPart.Name = "DrumMarker"
		markerPart.Anchored = true
		markerPart.CanCollide = false
		markerPart.CanQuery = false
		markerPart.Size = Vector3.new(2.5, 0.5, 2.5)
		markerPart.CFrame = CFrame.new(markerPos)
		markerPart.Material = Enum.Material.Neon
		markerPart.Color = Color3.fromRGB(255, 100, 50)
		markerPart.Transparency = 0.15
		markerPart.Parent = workspace
		Debris:AddItem(markerPart, Config.TeleportMarkerDuration)

		coroutine.wrap(function()
			for _ = 1, Config.TeleportMarkerDuration * 4 do
				if not markerPart.Parent then break end
				markerPart.Transparency = 0.15 + math.sin(os.clock() * 4) * 0.2
				local pulseSize = 2 + math.sin(os.clock() * 5) * 0.5
				markerPart.Size = Vector3.new(pulseSize, 0.4, pulseSize)
				task.wait(0.25)
			end
		end)()

		local beam = Instance.new("Part")
		beam.Name = "DrumBeam"
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanQuery = false
		beam.Size = Vector3.new(0.3, 1, 0.3)
		beam.CFrame = CFrame.new(markerPos + Vector3.new(0, 5, 0))
		beam.Material = Enum.Material.Neon
		beam.Color = Color3.fromRGB(255, 200, 100)
		beam.Transparency = 0.3
		beam.Parent = workspace
		Debris:AddItem(beam, Config.TeleportMarkerDuration)

		local beamDir = Vector3.new(0, -1, 0)
		task.spawn(function()
			for i = 1, Config.TeleportMarkerDuration * 10 do
				if not beam.Parent then break end
				local height = 2 + math.sin(os.clock() * 3) * 2
				beam.Size = Vector3.new(0.3, height, 0.3)
				beam.CFrame = CFrame.new(markerPos + Vector3.new(0, height / 2, 0))
				task.wait(0.1)
			end
		end)

		teleportMarkers[killer] = {
			position = markerPos - Vector3.new(0, 0.5, 0),
			markerPart = markerPart,
			placedAt = os.clock(),
		}

		task.delay(Config.TeleportMarkerDuration, function()
			if teleportMarkers[killer] and teleportMarkers[killer].markerPart == markerPart then
				teleportMarkers[killer] = nil
			end
		end)

		local cd = 2
		setCooldown(killer, cd)

		feedbackEvent:FireClient(killer, {
			type = "teleportPlace",
			cooldown = cd,
			markerPos = markerPos,
		})
	end
end

--------------------------------------------------------------------------------
-- DANÇA ENCANTADORA (Ballerina Cappuccina)
--------------------------------------------------------------------------------
local function enchantingDance(killer)
	local _, root, humanoid = getCharacter(killer)
	if not root then return end

	if activePulls[killer] then return end
	activePulls[killer] = true

	local duration = Config.PullDuration
	local radius = Config.PullRadius
	local pullStrength = Config.PullStrength
	local originalSpeed = humanoid.WalkSpeed

	humanoid.WalkSpeed = originalSpeed * Config.KillerPullSlowMultiplier

	local pulsePart = Instance.new("Part")
	pulsePart.Name = "DancePulse"
	pulsePart.Anchored = true
	pulsePart.CanCollide = false
	pulsePart.CanQuery = false
	pulsePart.Shape = Enum.PartType.Cylinder
	pulsePart.Size = Vector3.new(radius * 2, 0.3, radius * 2)
	pulsePart.CFrame = CFrame.new(root.Position)
	pulsePart.Material = Enum.Material.Neon
	pulsePart.Color = Color3.fromRGB(255, 100, 200)
	pulsePart.Transparency = 0.6
	pulsePart.Parent = workspace
	Debris:AddItem(pulsePart, duration + 0.5)

	local cd = getKillerCooldown(killer)
	setCooldown(killer, cd)

	feedbackEvent:FireClient(killer, {
		type = "danceStart",
		cooldown = cd,
		center = root.Position,
		radius = radius,
		duration = duration,
	})

	local startTime = os.clock()
	local pullConn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime

		if elapsed >= duration or not root or not root.Parent then
			pullConn:Disconnect()
			return
		end

		if pulsePart and pulsePart.Parent then
			pulsePart.CFrame = CFrame.new(root.Position)
		end

		local survivors = getAliveSurvivors()
		for _, data in ipairs(survivors) do
			local dist = (data.root.Position - root.Position).Magnitude
			if dist <= radius and dist > 3 then
				local pullDir = (root.Position - data.root.Position).Unit
				data.root.AssemblyLinearVelocity = pullDir * pullStrength
			end
		end
	end)

	task.delay(duration, function()
		pullConn:Disconnect()

		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = originalSpeed
		end

		activePulls[killer] = nil

		feedbackEvent:FireClient(killer, {
			type = "danceEnd",
			cooldown = 0,
		})
	end)
end

--------------------------------------------------------------------------------
-- MAIN HANDLER
--------------------------------------------------------------------------------
abilityEvent.OnServerEvent:Connect(function(player)
	if player:GetAttribute("Role") ~= "Killer" then
		return
	end

	if isOnCooldown(player) then
		feedbackEvent:FireClient(player, {
			type = "denied",
			cooldown = cooldowns[player] - os.clock(),
		})
		return
	end

	local killerName = player:GetAttribute("BrainrotKiller")
	if not killerName or killerName == "" then return end

	if killerName == "Tralalero Tralala" then
		sonicScream(player)
	elseif killerName == "Bombardiro Crocodilo" then
		crocodileCharge(player)
	elseif killerName == "Tung Tung Tung Sahur" then
		drumTeleport(player)
	elseif killerName == "Ballerina Cappuccina" then
		enchantingDance(player)
	end
end)

Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("Role"):Connect(function()
		local role = player:GetAttribute("Role")
		if role ~= "Killer" then
			cooldowns[player] = nil

			if teleportMarkers[player] then
				if teleportMarkers[player].markerPart then
					teleportMarkers[player].markerPart:Destroy()
				end
				teleportMarkers[player] = nil
			end

			activePulls[player] = nil
			activeCharges[player] = nil
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil

	if teleportMarkers[player] then
		if teleportMarkers[player].markerPart then
			teleportMarkers[player].markerPart:Destroy()
		end
		teleportMarkers[player] = nil
	end

	activePulls[player] = nil
	activeCharges[player] = nil
end)
