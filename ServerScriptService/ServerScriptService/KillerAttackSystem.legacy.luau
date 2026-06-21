local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("RoundConfig"))

local eventsFolder = ReplicatedStorage:FindFirstChild("RoundEvents") or Instance.new("Folder")
eventsFolder.Name = "RoundEvents"
eventsFolder.Parent = ReplicatedStorage

local attackEvent = eventsFolder:FindFirstChild("KillerAttack") or Instance.new("RemoteEvent")
attackEvent.Name = "KillerAttack"
attackEvent.Parent = eventsFolder

local feedbackEvent = eventsFolder:FindFirstChild("KillerAttackFeedback") or Instance.new("RemoteEvent")
feedbackEvent.Name = "KillerAttackFeedback"
feedbackEvent.Parent = eventsFolder

local lastAttackTime = {}

local function isAliveHumanoid(humanoid)
	return humanoid and humanoid.Health > 0
end

local function getCharacterParts(player)
	local character = player.Character
	if not character then return nil end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root or not isAliveHumanoid(humanoid) then
		return nil
	end

	return character, root, humanoid
end

local function createDebugHitbox(cframe, size)
	local part = Instance.new("Part")
	part.Name = "KillerAttackHitbox"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 0.75
	part.Color = Color3.fromRGB(255, 45, 45)
	part.Material = Enum.Material.Neon
	part.Size = size
	part.CFrame = cframe
	part.Parent = workspace

	Debris:AddItem(part, 0.15)
end

local function getPlayersInHitbox(killer, boxCFrame, boxSize)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { killer.Character }

	local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)
	local hitPlayers = {}

	for _, part in ipairs(parts) do
		local character = part:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)

		if player and player ~= killer and player:GetAttribute("Role") == "Survivor" then
			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if isAliveHumanoid(humanoid) then
				hitPlayers[player] = humanoid
			end
		end
	end

	return hitPlayers
end

attackEvent.OnServerEvent:Connect(function(player)
	if player:GetAttribute("Role") ~= "Killer" then
		return
	end

	local now = os.clock()
	local lastAttack = lastAttackTime[player] or 0

	if now - lastAttack < Config.KillerAttackCooldown then
		return
	end

	local character, root = getCharacterParts(player)
	if not character or not root then
		return
	end

	lastAttackTime[player] = now

	local boxSize = Vector3.new(
		Config.KillerAttackWidth,
		Config.KillerAttackHeight,
		Config.KillerAttackRange
	)

	local boxCFrame = root.CFrame * CFrame.new(0, 0, -Config.KillerAttackRange / 2)
	local hitPlayers = getPlayersInHitbox(player, boxCFrame, boxSize)
	local hitCount = 0

	createDebugHitbox(boxCFrame, boxSize)

	local hitData = {}
	for survivor, humanoid in pairs(hitPlayers) do
		local pos = survivor.Character and survivor.Character:FindFirstChild("HumanoidRootPart")
		table.insert(hitData, {
			playerName = survivor.Name,
			damage = Config.KillerAttackDamage,
			position = pos and pos.Position or Vector3.new(),
		})
		humanoid:TakeDamage(Config.KillerAttackDamage)
		hitCount += 1
	end

	feedbackEvent:FireClient(player, {
		hitCount = hitCount,
		cooldown = Config.KillerAttackCooldown,
		hits = hitData,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	lastAttackTime[player] = nil
end)
