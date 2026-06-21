local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("RoundConfig"))

local eventsFolder = ReplicatedStorage:FindFirstChild("RoundEvents") or Instance.new("Folder")
eventsFolder.Name = "RoundEvents"
eventsFolder.Parent = ReplicatedStorage

local updateEvent = eventsFolder:FindFirstChild("UpdateRoundUI") or Instance.new("RemoteEvent")
updateEvent.Name = "UpdateRoundUI"
updateEvent.Parent = eventsFolder

local currentKiller = nil
local aliveSurvivors = {}

local function sendUI(title, timer, info)
	updateEvent:FireAllClients({
		title = title,
		timer = timer,
		info = info or ""
	})
end

local function getPlayers()
	return Players:GetPlayers()
end

local function setRole(player, role)
	player:SetAttribute("Role", role)

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if role == "Killer" then
		humanoid.WalkSpeed = Config.KillerWalkSpeed
	else
		humanoid.WalkSpeed = Config.SurvivorWalkSpeed
	end
end

local function resetRoles()
	for _, player in ipairs(getPlayers()) do
		player:SetAttribute("Role", "Lobby")
		player:SetAttribute("BrainrotKiller", "")

		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.SurvivorWalkSpeed
			end
		end
	end
end

local function pickKiller()
	local players = getPlayers()
	if #players == 0 then return nil end

	return players[math.random(1, #players)]
end

local function survivorsAlive()
	local count = 0

	for player in pairs(aliveSurvivors) do
		if player.Parent == Players then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health > 0 then
				count += 1
			end
		end
	end

	return count
end

local function setupDeaths()
	for player in pairs(aliveSurvivors) do
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.Died:Connect(function()
				aliveSurvivors[player] = nil
			end)
		end
	end
end

local function startRound()
	currentKiller = pickKiller()
	if not currentKiller then return end

	local selectedKiller = currentKiller:GetAttribute("SelectedKiller") or ""
	local killerName = selectedKiller

	if killerName == "" or not table.find(Config.Killers, killerName) then
		killerName = Config.Killers[math.random(1, #Config.Killers)]
	end

	currentKiller:SetAttribute("BrainrotKiller", killerName)

	aliveSurvivors = {}

	for _, player in ipairs(getPlayers()) do
		if player == currentKiller then
			setRole(player, "Killer")
		else
			setRole(player, "Survivor")
			aliveSurvivors[player] = true
		end
	end

	setupDeaths()

	for timeLeft = Config.RoundTime, 0, -1 do
		if currentKiller.Parent ~= Players then
			sendUI("Survivors win", timeLeft, "The killer left.")
			return "Survivors"
		end

		if survivorsAlive() <= 0 then
			sendUI("Killer wins", timeLeft, killerName .. " eliminated everyone.")
			return "Killer"
		end

		sendUI("Survive", timeLeft, "Killer: " .. killerName)
		task.wait(1)
	end

	sendUI("Survivors win", 0, "Time ran out.")
	return "Survivors"
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Role", "Lobby")
	player:SetAttribute("BrainrotKiller", "")

	player.CharacterAdded:Connect(function()
		task.wait(0.2)

		local role = player:GetAttribute("Role")
		if role == "Killer" then
			setRole(player, "Killer")
		elseif role == "Survivor" then
			setRole(player, "Survivor")
		end
	end)
end)

while true do
	resetRoles()

	while #getPlayers() < Config.MinimumPlayers do
		sendUI("Waiting for players", 0, Config.MinimumPlayers .. " players needed.")
		task.wait(1)
	end

	for timeLeft = Config.IntermissionTime, 0, -1 do
		sendUI("Intermission", timeLeft, "Next round starting soon.")
		task.wait(1)

		if #getPlayers() < Config.MinimumPlayers then
			break
		end
	end

	if #getPlayers() >= Config.MinimumPlayers then
		startRound()
		task.wait(Config.EndDelay)
	end
end