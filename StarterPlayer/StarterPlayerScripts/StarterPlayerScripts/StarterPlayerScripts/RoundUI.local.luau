local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("RoundEvents"):WaitForChild("UpdateRoundUI")

local gui = Instance.new("ScreenGui")
gui.Name = "RoundUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(360, 95)
frame.Position = UDim2.new(0.5, -180, 0, -8)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
frame.BackgroundTransparency = 0
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Waiting"
title.Parent = frame

local timer = Instance.new("TextLabel")
timer.Size = UDim2.new(0, 90, 0, 30)
timer.Position = UDim2.new(0.5, -45, 0, 42)
timer.BackgroundTransparency = 1
timer.Font = Enum.Font.GothamBlack
timer.TextSize = 28
timer.TextColor3 = Color3.fromRGB(255, 80, 80)
timer.Text = "--"
timer.Parent = frame

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 20)
info.Position = UDim2.fromOffset(10, 72)
info.BackgroundTransparency = 1
info.Font = Enum.Font.Gotham
info.TextSize = 14
info.TextColor3 = Color3.fromRGB(200, 200, 200)
info.Text = ""
info.TextTruncate = Enum.TextTruncate.AtEnd
info.Parent = frame

local roleLabel = Instance.new("TextLabel")
roleLabel.Size = UDim2.fromOffset(180, 36)
roleLabel.Position = UDim2.new(0, 24, 1, -60)
roleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
roleLabel.BackgroundTransparency = 0.1
roleLabel.BorderSizePixel = 0
roleLabel.Font = Enum.Font.GothamBold
roleLabel.TextSize = 16
roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roleLabel.Text = "Role: Lobby"
roleLabel.Parent = gui

local roleCorner = Instance.new("UICorner")
roleCorner.CornerRadius = UDim.new(0, 8)
roleCorner.Parent = roleLabel

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

local function updateRole()
	local role = player:GetAttribute("Role") or "Lobby"

	if role == "Killer" then
		roleLabel.Text = "Role: Killer"
		roleLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	elseif role == "Survivor" then
		roleLabel.Text = "Role: Survivor"
		roleLabel.TextColor3 = Color3.fromRGB(120, 220, 255)
	else
		roleLabel.Text = "Role: Lobby"
		roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

player:GetAttributeChangedSignal("Role"):Connect(updateRole)
updateRole()

event.OnClientEvent:Connect(function(data)
	title.Text = data.title or "Round"
	timer.Text = data.timer and data.timer > 0 and formatTime(data.timer) or "--"
	info.Text = data.info or ""
end)
