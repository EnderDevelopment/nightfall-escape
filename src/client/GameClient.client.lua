local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("EscapeNightEvent")
local gui = Instance.new("ScreenGui")
gui.Name = "EscapeNightHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "StatusPanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.fromScale(0.5, 0.035)
panel.Size = UDim2.fromOffset(420, 86)
panel.BackgroundColor3 = Color3.fromRGB(20, 25, 24)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Phase"
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -32, 0, 28)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 220, 120)
title.TextSize = 21
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "ESCAPE NIGHT"
title.Parent = panel

local details = Instance.new("TextLabel")
details.Name = "Details"
details.Position = UDim2.fromOffset(16, 39)
details.Size = UDim2.new(1, -32, 0, 22)
details.BackgroundTransparency = 1
details.Font = Enum.Font.Gotham
details.TextColor3 = Color3.fromRGB(225, 235, 228)
details.TextSize = 15
details.TextXAlignment = Enum.TextXAlignment.Left
details.Text = "Waiting for players"
details.Parent = panel

local notice = Instance.new("TextLabel")
notice.Name = "Notice"
notice.AnchorPoint = Vector2.new(0.5, 1)
notice.Position = UDim2.fromScale(0.5, 0.93)
notice.Size = UDim2.fromOffset(560, 42)
notice.BackgroundTransparency = 1
notice.Font = Enum.Font.GothamBold
notice.TextColor3 = Color3.fromRGB(255, 255, 255)
notice.TextStrokeTransparency = 0.5
notice.TextSize = 20
notice.TextWrapped = true
notice.Visible = false
notice.Parent = gui

local sprinting = false
local noticeVersion = 0
local function showNotice(message)
	noticeVersion += 1
	local version = noticeVersion
	notice.Text = message
	notice.Visible = true
	task.delay(2.8, function()
		if version == noticeVersion then notice.Visible = false end
	end)
end
local function setSprint(active)
	sprinting = active
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and player:GetAttribute("Role") == "Survivor" then humanoid.WalkSpeed = active and 23 or 16 end
end
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.LeftShift then setSprint(true) end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then setSprint(false) end
end)
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid").WalkSpeed = 16
	if sprinting then setSprint(true) end
end)

event.OnClientEvent:Connect(function(kind, data)
	if kind == "State" then
		local phase = data.phase or "Waiting"
		local time = data.time or 0
		title.Text = phase == "Round" and string.format("SURVIVE  %03d", time) or string.upper(phase)
		local keys = player:GetAttribute("Keys") or 0
		if phase == "Round" then
			details.Text = string.format("Keys %d/%d   |   %s", keys, data.required or 3, data.message or "Stay alive")
		else
			details.Text = data.message or "Waiting for players"
		end
	elseif kind == "Notice" then
		showNotice(data)
	end
end)
player:GetAttributeChangedSignal("Keys"):Connect(function()
	local keys = player:GetAttribute("Keys") or 0
	if title.Text:find("SURVIVE") then details.Text = string.format("Keys %d/3   |   Find keys and reach the gate", keys) end
end)
