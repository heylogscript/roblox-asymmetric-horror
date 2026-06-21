local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("RoundConfig"))

local eventsFolder = ReplicatedStorage:FindFirstChild("RoundEvents") or Instance.new("Folder")
eventsFolder.Name = "RoundEvents"
eventsFolder.Parent = ReplicatedStorage

local sprintEvent = eventsFolder:FindFirstChild("SetSprinting") or Instance.new("RemoteEvent")
sprintEvent.Name = "SetSprinting"
sprintEvent.Parent = eventsFolder

local lastStoppedSprint = {}

local function getRole(player)
	return player:GetAttribute("Role") or "Lobby"
end

local function getWalkSpeed(role)
	if role == "Killer" then
		return Config.KillerWalkSpeed
	end

	return Config.SurvivorWalkSpeed
end

local function getSprintSpeed(role)
	if role == "Killer" then
		return Config.KillerSprintSpeed
	end

	return Config.SurvivorSprintSpeed
end

local function getMaxHealth(role)
	if role == "Killer" then
		return Config.KillerMaxHealth
	end

	return Config.SurvivorMaxHealth
end

local function applyCharacterStats(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local role = getRole(player)
	local maxHealth = getMaxHealth(role)

	humanoid.MaxHealth = maxHealth

	if humanoid.Health <= 0 or humanoid.Health > maxHealth then
		humanoid.Health = maxHealth
	end

	local stamina = player:GetAttribute("Stamina") or Config.MaxStamina
	local sprinting = player:GetAttribute("Sprinting") == true

	if sprinting and stamina >= Config.MinimumSprintStamina and role ~= "Lobby" then
		humanoid.WalkSpeed = getSprintSpeed(role)
	else
		humanoid.WalkSpeed = getWalkSpeed(role)
	end
end

local function setupPlayer(player)
	player:SetAttribute("Stamina", Config.MaxStamina)
	player:SetAttribute("MaxStamina", Config.MaxStamina)
	player:SetAttribute("Sprinting", false)

	lastStoppedSprint[player] = os.clock()

	player:GetAttributeChangedSignal("Role"):Connect(function()
		player:SetAttribute("Sprinting", false)
		player:SetAttribute("Stamina", Config.MaxStamina)
		applyCharacterStats(player)
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		player:SetAttribute("Sprinting", false)
		player:SetAttribute("Stamina", Config.MaxStamina)
		applyCharacterStats(player)
	end)
end

sprintEvent.OnServerEvent:Connect(function(player, wantsSprint)
	if typeof(wantsSprint) ~= "boolean" then return end

	local role = getRole(player)
	if role == "Lobby" then
		player:SetAttribute("Sprinting", false)
		return
	end

	local stamina = player:GetAttribute("Stamina") or 0

	if wantsSprint and stamina < Config.MinimumSprintStamina then
		player:SetAttribute("Sprinting", false)
		return
	end

	player:SetAttribute("Sprinting", wantsSprint)

	if not wantsSprint then
		lastStoppedSprint[player] = os.clock()
	end

	applyCharacterStats(player)
end)

RunService.Heartbeat:Connect(function(deltaTime)
	for _, player in ipairs(Players:GetPlayers()) do
		local stamina = player:GetAttribute("Stamina")
		if stamina == nil then
			continue
		end

		local role = getRole(player)
		local sprinting = player:GetAttribute("Sprinting") == true
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not humanoid or humanoid.Health <= 0 or role == "Lobby" then
			player:SetAttribute("Sprinting", false)
			continue
		end

		if sprinting then
			stamina -= Config.StaminaDrainPerSecond * deltaTime

			if stamina <= 0 then
				stamina = 0
				player:SetAttribute("Sprinting", false)
				lastStoppedSprint[player] = os.clock()
			end
		else
			local stoppedAt = lastStoppedSprint[player] or 0

			if os.clock() - stoppedAt >= Config.StaminaRegenDelay then
				stamina += Config.StaminaRegenPerSecond * deltaTime
			end
		end

		stamina = math.clamp(stamina, 0, Config.MaxStamina)
		player:SetAttribute("Stamina", stamina)
		applyCharacterStats(player)
	end
end)

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	lastStoppedSprint[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
