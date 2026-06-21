local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("RoundConfig"))

local eventsFolder = ReplicatedStorage:WaitForChild("RoundEvents")
local selectEvent = eventsFolder:WaitForChild("KillerSelected")

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.7
overlay.BorderSizePixel = 0
overlay.Active = true
overlay.Visible = false
overlay.Parent = gui

local container = Instance.new("Frame")
container.Size = UDim2.fromOffset(880, 320)
container.Position = UDim2.new(0.5, -440, 0.5, -160)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
container.BorderSizePixel = 0
container.ClipsDescendants = true
container.Visible = false
container.Parent = gui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 12)
containerCorner.Parent = container

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = Color3.fromRGB(255, 255, 255)
containerStroke.Transparency = 0.8
containerStroke.Thickness = 1
containerStroke.Parent = container

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 36)
title.Position = UDim2.fromOffset(20, 12)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "SELECT YOUR KILLER"
title.Parent = container

local closeBtn = Instance.new("ImageButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 14)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.BackgroundTransparency = 0.5
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Parent = container

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

local closeLabel = Instance.new("TextLabel")
closeLabel.Size = UDim2.fromScale(1, 1)
closeLabel.BackgroundTransparency = 1
closeLabel.Font = Enum.Font.GothamBold
closeLabel.TextSize = 14
closeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
closeLabel.Text = "X"
closeLabel.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	closeBtn.BackgroundTransparency = 0.1
end)

closeBtn.MouseLeave:Connect(function()
	closeBtn.BackgroundTransparency = 0.5
end)

local listFrame = Instance.new("Frame")
listFrame.Size = UDim2.new(1, -40, 1, -70)
listFrame.Position = UDim2.fromOffset(20, 56)
listFrame.BackgroundTransparency = 1
listFrame.Parent = container

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 14)
listLayout.Parent = listFrame

local cards = {}
local selectedKiller = ""
local inventoryOpen = false

local function setSelected(killerName)
	selectedKiller = killerName

	for name, data in pairs(cards) do
		local isSelected = name == killerName
		data.stroke.Transparency = isSelected and 0 or 0.75
		data.stroke.Thickness = isSelected and 2 or 1.5
		data.selectedOver.Visible = isSelected
		data.selLabel.Visible = isSelected
	end
end

local function createCard(killerName)
	local info = Config.KillerInfo[killerName]
	if not info then return end

	local card = Instance.new("ImageButton")
	card.Name = killerName
	card.Size = UDim2.fromOffset(185, 240)
	card.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.Parent = listFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = info.Color
	cardStroke.Transparency = 0.75
	cardStroke.Thickness = 1.5
	cardStroke.Parent = card

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(1, 0, 0, 3)
	accent.BackgroundColor3 = info.Color
	accent.BorderSizePixel = 0
	accent.Parent = card

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 10)
	accentCorner.Parent = accent

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 44)
	icon.Position = UDim2.fromOffset(0, 16)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 32
	icon.Text = info.Icon or "?"
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.Parent = card

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -16, 0, 20)
	nameLbl.Position = UDim2.fromOffset(8, 64)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 14
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Text = killerName
	nameLbl.Parent = card

	local abLbl = Instance.new("TextLabel")
	abLbl.Size = UDim2.new(1, -16, 0, 16)
	abLbl.Position = UDim2.fromOffset(8, 84)
	abLbl.BackgroundTransparency = 1
	abLbl.Font = Enum.Font.Gotham
	abLbl.TextSize = 11
	abLbl.TextColor3 = info.Color
	abLbl.TextXAlignment = Enum.TextXAlignment.Left
	abLbl.Text = info.AbilityName
	abLbl.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -20, 0, 72)
	desc.Position = UDim2.fromOffset(10, 106)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 10
	desc.TextColor3 = Color3.fromRGB(180, 180, 195)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.Text = info.Description
	desc.Parent = card

	local selectedOver = Instance.new("Frame")
	selectedOver.Size = UDim2.fromScale(1, 1)
	selectedOver.BackgroundColor3 = info.Color
	selectedOver.BackgroundTransparency = 0.8
	selectedOver.BorderSizePixel = 0
	selectedOver.Visible = false
	selectedOver.Parent = card

	local overCorner = Instance.new("UICorner")
	overCorner.CornerRadius = UDim.new(0, 10)
	overCorner.Parent = selectedOver

	local selLabel = Instance.new("TextLabel")
	selLabel.Size = UDim2.new(1, 0, 0, 22)
	selLabel.Position = UDim2.new(0, 0, 1, -26)
	selLabel.BackgroundColor3 = info.Color
	selLabel.BackgroundTransparency = 0.15
	selLabel.Font = Enum.Font.GothamBold
	selLabel.TextSize = 11
	selLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	selLabel.Text = "✓ SELECTED"
	selLabel.Visible = false
	selLabel.Parent = card

	local selCorner = Instance.new("UICorner")
	selCorner.CornerRadius = UDim.new(0, 10)
	selCorner.Parent = selLabel

	card.MouseEnter:Connect(function()
		if selectedKiller ~= killerName then
			card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
			card:TweenSize(UDim2.fromOffset(190, 247), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
		end
	end)

	card.MouseLeave:Connect(function()
		if selectedKiller ~= killerName then
			card.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
			card:TweenSize(UDim2.fromOffset(185, 240), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
		end
	end)

	card.MouseButton1Click:Connect(function()
		selectEvent:FireServer(killerName)
		setSelected(killerName)
	end)

	cards[killerName] = {
		card = card,
		stroke = cardStroke,
		selectedOver = selectedOver,
		selLabel = selLabel,
	}
end

for _, name in ipairs(Config.Killers) do
	createCard(name)
end

------------------------------------------------------------------
-- BUTTON
------------------------------------------------------------------
local invBtn = Instance.new("ImageButton")
invBtn.Size = UDim2.fromOffset(150, 36)
invBtn.Position = UDim2.fromOffset(12, 12)
invBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
invBtn.BackgroundTransparency = 0
invBtn.BorderSizePixel = 0
invBtn.AutoButtonColor = false
invBtn.Visible = false
invBtn.Parent = gui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = invBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Thickness = 1
btnStroke.Color = Color3.fromRGB(255, 255, 255)
btnStroke.Transparency = 0.75
btnStroke.Parent = invBtn

local btnText = Instance.new("TextLabel")
btnText.Size = UDim2.fromScale(1, 1)
btnText.BackgroundTransparency = 1
btnText.Font = Enum.Font.GothamBold
btnText.TextSize = 13
btnText.TextColor3 = Color3.fromRGB(255, 255, 255)
btnText.Text = "INVENTORY"
btnText.Parent = invBtn

invBtn.MouseEnter:Connect(function()
	invBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
	invBtn:TweenSize(UDim2.fromOffset(155, 40), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
end)

invBtn.MouseLeave:Connect(function()
	invBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
	invBtn:TweenSize(UDim2.fromOffset(150, 36), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
end)

------------------------------------------------------------------
-- TOGGLE
------------------------------------------------------------------
local function show()
	inventoryOpen = true
	overlay.Visible = true
	container.Visible = true
	container.Size = UDim2.fromOffset(880, 0)
	container:TweenSize(UDim2.fromOffset(880, 320), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.35, true)
	btnText.Text = "CLOSE"

	local saved = player:GetAttribute("SelectedKiller") or ""
	if saved ~= "" and saved ~= selectedKiller and cards[saved] then
		setSelected(saved)
	end
end

local function hide()
	inventoryOpen = false
	btnText.Text = "INVENTORY"
	local tween = TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(880, 0)
	})
	tween:Play()
	tween.Completed:Connect(function()
		overlay.Visible = false
		container.Visible = false
	end)
end

invBtn.MouseButton1Click:Connect(function()
	if inventoryOpen then hide() else show() end
end)

closeBtn.MouseButton1Click:Connect(hide)
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		hide()
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Escape and inventoryOpen then
		hide()
	end
end)

------------------------------------------------------------------
-- VISIBILITY
------------------------------------------------------------------
local function updateBtn()
	local role = player:GetAttribute("Role")
	invBtn.Visible = role == "Lobby"
	if role ~= "Lobby" and inventoryOpen then
		hide()
	end
end

player:GetAttributeChangedSignal("Role"):Connect(updateBtn)

player:GetAttributeChangedSignal("SelectedKiller"):Connect(function()
	local saved = player:GetAttribute("SelectedKiller") or ""
	if saved ~= "" and saved ~= selectedKiller and cards[saved] then
		setSelected(saved)
	end
end)

updateBtn()
