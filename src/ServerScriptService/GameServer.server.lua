local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Curriculum = require(Modules:WaitForChild("Curriculum"))
local MissionRules = require(Modules:WaitForChild("MissionRules"))
local MissionEngine = require(script.Parent:WaitForChild("MissionEngine"))

local remotes = ReplicatedStorage:FindFirstChild("GameRemotes") or Instance.new("Folder")
remotes.Name = "GameRemotes"
remotes.Parent = ReplicatedStorage

local lessonSelected = remotes:FindFirstChild("LessonSelected") or Instance.new("RemoteEvent")
lessonSelected.Name = "LessonSelected"
lessonSelected.Parent = remotes

local missionInfo = remotes:FindFirstChild("MissionInfo") or Instance.new("RemoteEvent")
missionInfo.Name = "MissionInfo"
missionInfo.Parent = remotes

local pythonCommand = remotes:FindFirstChild("PythonCommand") or Instance.new("RemoteEvent")
pythonCommand.Name = "PythonCommand"
pythonCommand.Parent = remotes

local pythonConsole = remotes:FindFirstChild("PythonConsole") or Instance.new("RemoteEvent")
pythonConsole.Name = "PythonConsole"
pythonConsole.Parent = remotes

local posterCommand = remotes:FindFirstChild("PosterCommand") or Instance.new("RemoteEvent")
posterCommand.Name = "PosterCommand"
posterCommand.Parent = remotes

local typingCommand = remotes:FindFirstChild("TypingCommand") or Instance.new("RemoteEvent")
typingCommand.Name = "TypingCommand"
typingCommand.Parent = remotes

local world = workspace:FindFirstChild("CyberEscapeWorld") or Instance.new("Folder")
world.Name = "CyberEscapeWorld"
world.Parent = workspace

local function makePart(name, size, position, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = anchored ~= false
	p.Parent = world
	return p
end

local function ensureWorld()
	if world:FindFirstChild("LobbyFloor") then
		return
	end

	local floor = makePart("LobbyFloor", Vector3.new(80, 1, 80), Vector3.new(0, -0.5, 0))
	floor.Material = Enum.Material.SmoothPlastic

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 20)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = world

	local terminal = makePart("MissionTerminal", Vector3.new(12, 8, 2), Vector3.new(0, 4, -18))
	terminal.Material = Enum.Material.Metal

	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(900, 600)
	surface.Parent = terminal

	local text = Instance.new("TextLabel")
	text.Name = "TerminalText"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextWrapped = true
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Text = "CYBER ESCAPE ROOM\nWybierz klasę i temat na ekranie startowym."
	text.Parent = surface

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Sprawdź misję"
	prompt.ObjectText = "Terminal misji"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = terminal

	prompt.Triggered:Connect(function(player)
		local grade = player:GetAttribute("SelectedGrade")
		local lessonNo = player:GetAttribute("SelectedLesson")
		if not grade or not lessonNo then
			missionInfo:FireClient(player, "Najpierw wybierz klasę i temat.")
			return
		end
		local gradeData = Curriculum[grade]
		local lesson = gradeData and gradeData.lessons[lessonNo]
		if not lesson then
			return
		end
		local mission = MissionRules.GetForLesson(lesson, grade)
		missionInfo:FireClient(player, mission.description)
	end)
end

pythonCommand.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.action == "reset" then
		MissionEngine.ResetPython(player, pythonConsole)
		return
	end
	if payload.action == "run" and type(payload.code) == "string" then
		MissionEngine.ExecutePython(player, payload.code, pythonConsole, missionInfo)
	end
end)

posterCommand.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" then
		return
	end
	MissionEngine.HandlePosterInput(player, payload)
end)

typingCommand.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" then
		return
	end
	MissionEngine.HandleTypingInput(player, payload)
end)

lessonSelected.OnServerEvent:Connect(function(player, grade, lessonNo)
	if type(grade) ~= "string" or type(lessonNo) ~= "number" then
		return
	end
	local gradeData = Curriculum[grade]
	if not gradeData then
		return
	end
	local lesson = gradeData.lessons[lessonNo]
	if not lesson then
		return
	end

	local mission = MissionRules.GetForLesson(lesson, grade)
	if not mission.available then
		missionInfo:FireClient(player, {
			kind = "message",
			text = "Ta plansza jest jeszcze w przygotowaniu. Wybierz lekcję 3–10.",
			good = false,
		})
		return
	end
	player:SetAttribute("SelectedGrade", grade)
	player:SetAttribute("SelectedLesson", lessonNo)
	player:SetAttribute("SelectedTopic", lesson.topic)
	player:SetAttribute("MissionType", mission.type)

	MissionEngine.Start(player, lesson, mission, missionInfo)
end)

local function setupPlayer(player)
	if player:GetAttribute("Score") == nil then
		player:SetAttribute("Score", 0)
	end

	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local points = leaderstats:FindFirstChild("Punkty") or Instance.new("IntValue")
	points.Name = "Punkty"
	points.Value = player:GetAttribute("Score") or 0
	points.Parent = leaderstats

	player:GetAttributeChangedSignal("Score"):Connect(function()
		points.Value = player:GetAttribute("Score") or 0
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

ensureWorld()
print("[CER] GameServer ready")