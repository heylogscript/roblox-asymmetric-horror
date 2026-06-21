local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("RoundConfig"))

local eventsFolder = ReplicatedStorage:FindFirstChild("RoundEvents") or Instance.new("Folder")
eventsFolder.Name = "RoundEvents"
eventsFolder.Parent = ReplicatedStorage

local selectEvent = eventsFolder:FindFirstChild("KillerSelected") or Instance.new("RemoteEvent")
selectEvent.Name = "KillerSelected"
selectEvent.Parent = eventsFolder

local function isValidKiller(name)
	for _, killer in ipairs(Config.Killers) do
		if killer == name then
			return true
		end
	end
	return false
end

selectEvent.OnServerEvent:Connect(function(player, killerName)
	if type(killerName) ~= "string" then return end
	if not isValidKiller(killerName) then return end

	player:SetAttribute("SelectedKiller", killerName)
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("SelectedKiller", "")
end)

Players.PlayerRemoving:Connect(function(player)
	player:SetAttribute("SelectedKiller", nil)
end)
