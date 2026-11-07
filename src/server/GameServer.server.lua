-- Escape Night round controller and runtime arena builder.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local INTERMISSION = 12
local ROUND_LENGTH = 150
local REQUIRED_KEYS = 3
local CATCH_DISTANCE = 6
local HUNTER_SPEED = 19
local SURVIVOR_SPEED = 16

local event = ReplicatedStorage:FindFirstChild("EscapeNightEvent") or Instance.new("RemoteEvent")
event.Name = "EscapeNightEvent"
event.Parent = ReplicatedStorage

local arena = workspace:FindFirstChild("EscapeNightArena")
if arena then arena:Destroy() end
arena = Instance.new("Folder")
arena.Name = "EscapeNightArena"
arena.Parent = workspace

local function part(name, size, position, color, material, parent)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.Position = position
	object.Anchored = true
	object.Color = color
	object.Material = material or Enum.Material.SmoothPlastic
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent or arena
	return object
end

part("Ground", Vector3.new(180, 2, 180), Vector3.new(0, -1, 0), Color3.fromRGB(50, 78, 49), Enum.Material.Grass)
for _, spec in ipairs({
	{Vector3.new(180, 18, 2), Vector3.new(0, 8, -90)},
	{Vector3.new(180, 18, 2), Vector3.new(0, 8, 90)},
	{Vector3.new(2, 18, 180), Vector3.new(-90, 8, 0)},
	{Vector3.new(2, 18, 180), Vector3.new(90, 8, 0)},
}) do part("Boundary", spec[1], spec[2], Color3.fromRGB(37, 43, 39), Enum.Material.WoodPlanks) end

-- Cover, trees, and simple paths make navigation readable without external assets.
for _, spec in ipairs({
	{Vector3.new(18, 7, 8), Vector3.new(-35, 3.5, -28)},
	{Vector3.new(8, 8, 20), Vector3.new(25, 4, -22)},
	{Vector3.new(20, 5, 7), Vector3.new(-15, 2.5, 27)},
	{Vector3.new(9, 9, 9), Vector3.new(42, 4.5, 25)},
	{Vector3.new(12, 6, 8), Vector3.new(45, 3, -50)},
	{Vector3.new(8, 7, 12), Vector3.new(-48, 3.5, 48)},
}) do part("Cover", spec[1], spec[2], Color3.fromRGB(93, 67, 45), Enum.Material.Wood) end
for _, pos in ipairs({Vector3.new(-60,0,-50), Vector3.new(60,0,-10), Vector3.new(-60,0,30), Vector3.new(10,0,60), Vector3.new(65,0,65), Vector3.new(-15,0,-62)}) do
	part("TreeTrunk", Vector3.new(3, 12, 3), pos + Vector3.new(0, 6, 0), Color3.fromRGB(83, 57, 37), Enum.Material.Wood)
	local leaves = part("TreeCanopy", Vector3.new(12, 12, 12), pos + Vector3.new(0, 14, 0), Color3.fromRGB(42, 93, 48), Enum.Material.Grass)
	leaves.Shape = Enum.PartType.Ball
end

local exit = part("ExitGate", Vector3.new(20, 13, 2), Vector3.new(0, 6.5, -82), Color3.fromRGB(150, 95, 45), Enum.Material.Wood)
exit.CanCollide = true
local exitPrompt = Instance.new("ProximityPrompt")
exitPrompt.ActionText = "Unlock and escape"
exitPrompt.ObjectText = "Front Gate"
exitPrompt.HoldDuration = 1.2
exitPrompt.MaxActivationDistance = 10
exitPrompt.Parent = exit
local keySpots = {
	Vector3.new(-50, 2, -35), Vector3.new(42, 2, -36), Vector3.new(-48, 2, 44),
	Vector3.new(48, 2, 48), Vector3.new(5, 2, 42), Vector3.new(20, 2, -5),
}
local lobbySpawn = part("LobbySpawn", Vector3.new(10, 1, 10), Vector3.new(0, 1, 125), Color3.fromRGB(75, 120, 170), Enum.Material.Neon)
lobbySpawn.Transparency = 0.35
local survivorSpawns = {Vector3.new(-65, 3, -65), Vector3.new(65, 3, -65), Vector3.new(-65, 3, 65), Vector3.new(65, 3, 65), Vector3.new(0, 3, 55)}
local hunterSpawn = Vector3.new(0, 3, 35)

local phase = "Waiting"
local timeLeft = 0
local hunter = nil
local alive = {}
local escaped = {}
local keys = {}
local connections = {}
local roundId = 0

local function broadcast(message)
	event:FireAllClients("State", {phase = phase, time = timeLeft, message = message, required = REQUIRED_KEYS})
end
local function sendPlayer(player, message)
	event:FireClient(player, "Notice", message)
end
local function teleport(player, position)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then character:PivotTo(CFrame.new(position)) end
end
local function setSpeed(player, speed)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = speed end
end
local function clearKeys()
	for _, object in ipairs(keys) do if object and object.Parent then object:Destroy() end end
	table.clear(keys)
end
local function finishRound(winner)
	if phase ~= "Round" then return end
	phase = "Results"
	clearKeys()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	table.clear(connections)
	broadcast(winner .. " win!")
	for _, player in ipairs(Players:GetPlayers()) do
		setSpeed(player, 16)
		task.delay(4, function() if player.Parent then teleport(player, lobbySpawn.Position + Vector3.new(0, 4, 0)) end end)
	end
end
local function survivorCount()
	local count = 0
	for player in pairs(alive) do if player.Parent and not escaped[player] then count += 1 end end
	return count
end
local function setupPlayer(player)
	player:SetAttribute("Keys", 0)
	player:SetAttribute("Role", "Lobby")
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		if phase == "Round" and alive[player] then
			teleport(player, player == hunter and hunterSpawn or survivorSpawns[math.random(#survivorSpawns)])
			setSpeed(player, player == hunter and HUNTER_SPEED or SURVIVOR_SPEED)
		else
			teleport(player, lobbySpawn.Position + Vector3.new(0, 4, 0))
		end
	end)
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
	alive[player] = nil
	escaped[player] = nil
	if phase == "Round" then
		if player == hunter then finishRound("Survivors") elseif survivorCount() == 0 then finishRound("Hunter") end
	end
end)

exitPrompt.Triggered:Connect(function(player)
	if phase ~= "Round" or player == hunter or not alive[player] or escaped[player] then return end
	local count = player:GetAttribute("Keys") or 0
	if count < REQUIRED_KEYS then sendPlayer(player, string.format("Find %d more key%s", REQUIRED_KEYS - count, REQUIRED_KEYS - count == 1 and "" or "s")); return end
	escaped[player] = true
	alive[player] = nil
	teleport(player, lobbySpawn.Position + Vector3.new(0, 4, 0))
	setSpeed(player, 16)
	sendPlayer(player, "You escaped!")
	if survivorCount() == 0 then finishRound("Survivors") end
end)

local function startRound()
	local roster = Players:GetPlayers()
	if #roster < 2 then return false end
	roundId += 1
	local thisRound = roundId
	phase, timeLeft = "Round", ROUND_LENGTH
	hunter = roster[math.random(#roster)]
	table.clear(alive); table.clear(escaped)
	for _, player in ipairs(roster) do
		alive[player] = true
		player:SetAttribute("Keys", 0)
		player:SetAttribute("Role", player == hunter and "Hunter" or "Survivor")
		if player.Character then player.Character:PivotTo(CFrame.new(player == hunter and hunterSpawn or survivorSpawns[math.random(#survivorSpawns)])) end
		setSpeed(player, player == hunter and HUNTER_SPEED or SURVIVOR_SPEED)
		sendPlayer(player, player == hunter and "You are the Hunter. Catch every survivor!" or "Collect three keys and escape through the gate!")
	end
	clearKeys()
	for index, position in ipairs(keySpots) do
		local key = part("Key", Vector3.new(2, 2, 2), position, ({Color3.fromRGB(255, 215, 45), Color3.fromRGB(50, 220, 255), Color3.fromRGB(255, 75, 120)})[(index - 1) % 3 + 1], Enum.Material.Neon)
		key.Shape = Enum.PartType.Ball
		key:SetAttribute("Taken", false)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Collect key"; prompt.ObjectText = "Rusty Key"; prompt.HoldDuration = 0.35; prompt.MaxActivationDistance = 9; prompt.Parent = key
		prompt.Triggered:Connect(function(player)
			if phase ~= "Round" or player == hunter or not alive[player] or key:GetAttribute("Taken") then return end
			key:SetAttribute("Taken", true)
			player:SetAttribute("Keys", (player:GetAttribute("Keys") or 0) + 1)
			sendPlayer(player, string.format("Key collected (%d/%d)", player:GetAttribute("Keys"), REQUIRED_KEYS))
			key:Destroy()
		end)
		table.insert(keys, key)
	end
	table.insert(connections, RunService.Heartbeat:Connect(function()
		if phase ~= "Round" or not hunter or not hunter.Character then return end
		local hunterRoot = hunter.Character:FindFirstChild("HumanoidRootPart")
		if not hunterRoot then return end
		for player in pairs(alive) do
			if player ~= hunter and not escaped[player] and player.Character then
				local root = player.Character:FindFirstChild("HumanoidRootPart")
				if root and (root.Position - hunterRoot.Position).Magnitude <= CATCH_DISTANCE then
					alive[player] = nil
					player:SetAttribute("Role", "Caught")
					player:SetAttribute("Keys", 0)
					teleport(player, lobbySpawn.Position + Vector3.new(0, 4, 0))
					setSpeed(player, 16)
					sendPlayer(player, "The Hunter caught you!")
					if survivorCount() == 0 then finishRound("Hunter") end
				end
			end
		end
	end))
	task.spawn(function()
		while phase == "Round" and roundId == thisRound and timeLeft > 0 do
			broadcast("Find keys, then reach the gate!")
			task.wait(1)
			timeLeft -= 1
		end
		if phase == "Round" and roundId == thisRound then finishRound("Hunter") end
	end)
	return true
end

task.spawn(function()
	while true do
		phase = "Waiting"
		while #Players:GetPlayers() < 2 do
			timeLeft = 0; broadcast("Waiting for at least 2 players"); task.wait(2)
		end
		for seconds = INTERMISSION, 1, -1 do
			if #Players:GetPlayers() < 2 then break end
			timeLeft = seconds; broadcast("Round starts soon"); task.wait(1)
		end
		if #Players:GetPlayers() >= 2 then startRound() end
		while phase == "Round" do task.wait(0.25) end
		task.wait(5)
	end
end)
