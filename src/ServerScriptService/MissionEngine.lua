local MissionEngine = {}
print("[CER] MissionEngine loaded")

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DecisionScenarios = require(script.Parent:WaitForChild("DecisionScenarios"))
local PythonSubset = require(script.Parent:WaitForChild("PythonSubset"))
local PythonRobotDock = require(script.Parent:WaitForChild("PythonRobotDock"))
local PythonRobotMaze = require(script.Parent:WaitForChild("PythonRobotMaze"))
local PythonPowerPlant = require(script.Parent:WaitForChild("PythonPowerPlant"))
local LoopFactory = require(script.Parent:WaitForChild("LoopFactory"))
local ParameterLab = require(script.Parent:WaitForChild("ParameterLab"))
local CommandYard = require(script.Parent:WaitForChild("CommandYard"))
local MessageLab = require(script.Parent:WaitForChild("MessageLab"))
local NumberFoundry = require(script.Parent:WaitForChild("NumberFoundry"))
local SearchRace = require(script.Parent:WaitForChild("SearchRace"))
local SortingArena = require(script.Parent:WaitForChild("SortingArena"))
local SportsNewsroom = require(script.Parent:WaitForChild("SportsNewsroom"))
local LanguagePort = require(script.Parent:WaitForChild("LanguagePort"))
local MathEngine = require(script.Parent:WaitForChild("MathEngine"))
local DecisionDrone = require(script.Parent:WaitForChild("DecisionDrone"))
local LogicGateControl = require(script.Parent:WaitForChild("LogicGateControl"))
local SequenceReactor = require(script.Parent:WaitForChild("SequenceReactor"))
local PositionalVault = require(script.Parent:WaitForChild("PositionalVault"))
local ConversionMachine = require(script.Parent:WaitForChild("ConversionMachine"))
local RailSort = require(script.Parent:WaitForChild("RailSort"))
local TextForensics = require(script.Parent:WaitForChild("TextForensics"))
local CaesarCipherVault = require(script.Parent:WaitForChild("CaesarCipherVault"))
local MailMergeFactory = require(script.Parent:WaitForChild("MailMergeFactory"))
local DataImportDock = require(script.Parent:WaitForChild("DataImportDock"))
local SessionStandings = require(script.Parent:WaitForChild("SessionStandings"))
local SoftwareTower = require(script.Parent:WaitForChild("SoftwareTower"))
local FileWarehouse = require(script.Parent:WaitForChild("FileWarehouse"))
local CloudSyncStation = require(script.Parent:WaitForChild("CloudSyncStation"))
local CyberDefenseFortress = require(script.Parent:WaitForChild("CyberDefenseFortress"))
local ThreatWaveSOC = require(script.Parent:WaitForChild("ThreatWaveSOC"))
local InventorWorkshop = require(script.Parent:WaitForChild("InventorWorkshop"))
local PhotoLabOne = require(script.Parent:WaitForChild("PhotoLabOne"))
local PhotoRestorationLab = require(script.Parent:WaitForChild("PhotoRestorationLab"))
local ScratchLoopGrid = require(script.Parent:WaitForChild("ScratchLoopGrid"))
local ScratchMiniStage = require(script.Parent:WaitForChild("ScratchMiniStage"))
local ScratchEventCity = require(script.Parent:WaitForChild("ScratchEventCity"))
local ScratchGameJam = require(script.Parent:WaitForChild("ScratchGameJam"))
local RobotRescue = require(script.Parent:WaitForChild("RobotRescue"))
local PseudocodeConveyor = require(script.Parent:WaitForChild("PseudocodeConveyor"))
local DataCity = require(script.Parent:WaitForChild("DataCity"))
local SpreadsheetFactory = require(script.Parent:WaitForChild("SpreadsheetFactory"))
local NatureAnimationLab = require(script.Parent:WaitForChild("NatureAnimationLab"))
local ProjectionTunnel = require(script.Parent:WaitForChild("ProjectionTunnel"))
local JavaBlockLine = require(script.Parent:WaitForChild("JavaBlockLine"))
local DataDecoderChamber = require(script.Parent:WaitForChild("DataDecoderChamber"))
local ChapterFinale = require(script.Parent:WaitForChild("ChapterFinale"))
local NewsroomEvidence = require(script.Parent:WaitForChild("NewsroomEvidence"))
local PaintStudioShapes = require(script.Parent:WaitForChild("PaintStudioShapes"))
local PaintStudioText = require(script.Parent:WaitForChild("PaintStudioText"))
local PaintStudioComposition = require(script.Parent:WaitForChild("PaintStudioComposition"))
local AIPaintPrintLab = require(script.Parent:WaitForChild("AIPaintPrintLab"))
local LayeredGraphicsTextLab = require(script.Parent:WaitForChild("LayeredGraphicsTextLab"))
local TimelineMuseum = require(script.Parent:WaitForChild("TimelineMuseum"))
local ChronoMuseum = require(script.Parent:WaitForChild("ChronoMuseum"))
local DecisionCity = require(script.Parent:WaitForChild("DecisionCity"))
local PCEmergencyRoom = require(script.Parent:WaitForChild("PCEmergencyRoom"))
local InternetConstruction = require(script.Parent:WaitForChild("InternetConstruction"))
local NetworkServiceDistrict = require(script.Parent:WaitForChild("NetworkServiceDistrict"))
local HTMLConstructionStudio = require(script.Parent:WaitForChild("HTMLConstructionStudio"))
local CSSStyleStudio = require(script.Parent:WaitForChild("CSSStyleStudio"))
local WebsiteLaunchStudio = require(script.Parent:WaitForChild("WebsiteLaunchStudio"))
local RouterDefense = require(script.Parent:WaitForChild("RouterDefense"))
local SearchEscape = require(script.Parent:WaitForChild("SearchEscape"))
local InternetDetective = require(script.Parent:WaitForChild("InternetDetective"))
local ProblemSolvingFactory = require(script.Parent:WaitForChild("ProblemSolvingFactory"))
local TypingTerminalRun = require(script.Parent:WaitForChild("TypingTerminalRun"))
local IllusionStudio = require(script.Parent:WaitForChild("IllusionStudio"))
local ImageTransformChamber = require(script.Parent:WaitForChild("ImageTransformChamber"))
local VisualThemes = require(script.Parent:WaitForChild("VisualThemes"))

local active = {}
local respawnState = {}
local respawnConnections = {}
local lastHudState = {}
local pythonSessions = {}
local slotByUser = {}
local nextSlot = 0

local archetype = {
	LabSafety = "Decision",
	SoftwareSort = "Sort",
	CyberTerminal = "Decision",
	CyberDefense = "Defense",
	CloudAccess = "Decision",
	SourceCheck = "Decision",
	EscapeMission = "Escape",
	SearchMission = "Decision",
	CommunicationMission = "Decision",
	AICheck = "Decision",
	DigitalLaw = "Decision",
	FileSort = "Sort",
	GraphicsLab = "Collect",
	PresentationLab = "Collect",
	DocumentRepair = "Collect",
	TypingRush = "Collect",
	RobotSequence = "Sequence",
	BlockProgram = "Sequence",
	AlgorithmPath = "Sequence",
	CodeRepair = "Vault",
	PythonLab = "Python",
	SpreadsheetLab = "Vault",
	DataFactory = "Factory",
	CipherVault = "Vault",
	BinaryVault = "Vault",
	HardwareBuild = "Build",
	NetworkBuilder = "Build",
	WebBuilder = "Build",
	StyleLab = "Build",
	DatabaseMission = "Build",
	ThreeDLab = "Build",
	TechHistory = "Collect",
	ProjectQuest = "Collect",
	MixedChallenge = "Collect",
	GenericChallenge = "Hunt",
}

local palette = {
	Decision = { Color3.fromRGB(12, 35, 55), Color3.fromRGB(0, 210, 255) },
	Defense = { Color3.fromRGB(50, 18, 28), Color3.fromRGB(255, 70, 95) },
	Escape = { Color3.fromRGB(42, 18, 42), Color3.fromRGB(255, 95, 170) },
	Collect = { Color3.fromRGB(35, 20, 55), Color3.fromRGB(190, 70, 255) },
	Sort = { Color3.fromRGB(45, 28, 10), Color3.fromRGB(255, 150, 30) },
	Sequence = { Color3.fromRGB(18, 48, 32), Color3.fromRGB(75, 255, 140) },
	Vault = { Color3.fromRGB(60, 35, 10), Color3.fromRGB(255, 185, 55) },
	Factory = { Color3.fromRGB(15, 48, 45), Color3.fromRGB(55, 220, 175) },
	Python = { Color3.fromRGB(18, 32, 55), Color3.fromRGB(70, 185, 255) },
	Build = { Color3.fromRGB(25, 30, 60), Color3.fromRGB(85, 125, 255) },
	Hunt = { Color3.fromRGB(45, 20, 25), Color3.fromRGB(255, 80, 100) },
}
local questions = {
	LabSafety = {
		"W pracowni widzisz uszkodzony przewód. Co robisz?",
		{ "Ignoruję go", "Zgłaszam nauczycielowi i nie dotykam", "Naprawiam sam" },
		2,
	},
	DigitalLaw = {
		"Chcesz użyć cudzego obrazu w projekcie. Co robisz?",
		{ "Sprawdzam licencję i podaję źródło", "Usuwam podpis autora", "Biorę dowolny obraz bez sprawdzania" },
		1,
	},
	CyberTerminal = { "Które hasło jest najmocniejsze?", { "12345678", "K0t!Lubi_7Ryb#", "informatyka" }, 2 },
	CloudAccess = {
		"Jak bezpiecznie udostępnić plik?",
		{ "Publicznie każdemu", "Tylko wskazanym osobom", "Wysłać hasło w nazwie" },
		2,
	},
	SourceCheck = {
		"Co najlepiej zwiększa wiarygodność informacji?",
		{ "Dużo wykrzykników", "Porównanie kilku źródeł", "Anonimowy autor" },
		2,
	},
	SearchMission = {
		"Które zapytanie zwykle daje trafniejszy wynik?",
		{ "komputer", "budowa komputera procesor pamięć", "internet" },
		2,
	},
	CommunicationMission = {
		"Co jest zgodne z netykietą?",
		{ "Pisanie WIELKIMI LITERAMI", "Szacunek i rzeczowy język", "Rozsyłanie cudzych danych" },
		2,
	},
	AICheck = {
		"Co zrobić z odpowiedzią AI przed użyciem?",
		{ "Zawsze uznać za prawdę", "Zweryfikować ważne fakty", "Usunąć źródła" },
		2,
	},
	FileSort = {
		"Gdzie najlepiej trzymać pliki jednego projektu?",
		{ "W uporządkowanym folderze", "Losowo na pulpicie", "W Koszu" },
		1,
	},
	GraphicsLab = {
		"Co opisuje grafikę rastrową?",
		{ "Składa się z pikseli", "Zawsze jest 3D", "Nie ma rozdzielczości" },
		1,
	},
	DocumentRepair = {
		"Co pomaga zachować spójny wygląd dokumentu?",
		{ "Style i formatowanie", "Losowe czcionki", "Wiele spacji" },
		1,
	},
	TypingRush = {
		"Która praktyka ułatwia szybkie pisanie?",
		{ "Patrzenie stale na klawiaturę", "Regularne ćwiczenie układu palców", "Jeden palec" },
		2,
	},
	RobotSequence = { "Robot ma iść: przód, prawo, przód. Co wykona najpierw?", { "Prawo", "Przód", "Stop" }, 2 },
	BlockProgram = {
		"Co wykonuje program krok po kroku?",
		{ "Sekwencję instrukcji", "Tapetę pulpitu", "Nazwę pliku" },
		1,
	},
	AlgorithmPath = {
		"Czym jest algorytm?",
		{ "Uporządkowanym sposobem rozwiązania problemu", "Rodzajem monitora", "Formatem obrazu" },
		1,
	},
	CodeRepair = { "Co wypisze: local x=3; x=x+2; print(x)?", { "2", "3", "5" }, 3 },
	SpreadsheetLab = { "Od czego zwykle zaczyna się formuła w arkuszu?", { "=", "#", "@" }, 1 },
	CipherVault = { "Szyfr Cezara to przykład szyfru...", { "podstawieniowego", "graficznego", "dźwiękowego" }, 1 },
	BinaryVault = { "Liczba binarna 10 to dziesiętnie...", { "1", "2", "10" }, 2 },
	NetworkBuilder = { "Które urządzenie łączy sieci i kieruje ruchem?", { "Router", "Klawiatura", "Drukarka" }, 1 },
	WebBuilder = { "Który język opisuje strukturę strony WWW?", { "HTML", "PNG", "MP3" }, 1 },
	StyleLab = { "Który język odpowiada głównie za wygląd strony?", { "CSS", "SQL", "CSV" }, 1 },
	DatabaseMission = { "Co łączy rekordy między tabelami?", { "Relacja/klucz", "Tapeta", "Piksel" }, 1 },
	GenericChallenge = {
		"Co jest podstawą skutecznego rozwiązania problemu?",
		{ "Analiza i kolejne kroki", "Losowe klikanie", "Pomijanie testów" },
		1,
	},
}

local variantQuestions = {
	cloud = {
		"Która opcja najlepiej chroni współdzielony dokument?",
		{ "Link publiczny dla każdego", "Dostęp tylko dla wskazanych osób", "Hasło w nazwie pliku" },
		2,
	},
	passwords = {
		"Które hasło najlepiej spełnia zasady cyberhigieny?",
		{ "ania2014", "K0t!Lubi_7Ryb#", "qwerty" },
		2,
	},
	cyber = {
		"Co robisz, gdy strona prosi o pilne logowanie z nietypowego adresu?",
		{ "Loguję się od razu", "Sprawdzam adres i wchodzę przez znaną stronę", "Podaję hasło znajomemu" },
		2,
	},
	threats = {
		"Co zrobić z podejrzanym załącznikiem od nieznanego nadawcy?",
		{ "Otworzyć dla testu", "Nie otwierać i zgłosić", "Przesłać dalej" },
		2,
	},
	sources = {
		"Który sygnał najlepiej pomaga ocenić wiarygodność informacji?",
		{ "Krzykliwy tytuł", "Autor, data i potwierdzenie w innych źródłach", "Dużo polubień" },
		2,
	},
	search = {
		"Które zapytanie jest bardziej precyzyjne?",
		{ "komputer", "budowa komputera CPU RAM dysk", "internet" },
		2,
	},
	research = {
		"Jak najlepiej rozwiązać problem z pomocą internetu?",
		{
			"Skopiować pierwszą odpowiedź",
			"Porównać kilka źródeł i przetestować rozwiązanie",
			"Wybrać najkrótszy tekst",
		},
		2,
	},
	digitization = {
		"Które działanie ogranicza ryzyko cyfryzacji?",
		{ "Silne uwierzytelnianie i kopie zapasowe", "Jedno hasło wszędzie", "Brak aktualizacji" },
		1,
	},

	data_representation = {
		"Jaki zapis najlepiej pasuje do danych komputera?",
		{ "Bity 0 i 1", "Tylko litery", "Tylko obrazy" },
		1,
	},
	number_systems = { "Który zapis jest binarny?", { "10201", "101101", "89AF" }, 2 },
	conversion = { "Liczba 1010₂ to dziesiętnie...", { "8", "10", "12" }, 2 },
	caesar = { "Przesuń D o 3 litery w szyfrze Cezara.", { "F", "G", "H" }, 2 },

	python_intro = { "Co wypisze: x = 2; print(x + 3)?", { "23", "5", "x+3" }, 2 },
	python_programs = {
		"Co robi instrukcja print() w Pythonie?",
		{ "Wyświetla wynik", "Usuwa zmienną", "Kończy komputer" },
		1,
	},
	languages = { "Który z podanych jest tekstowym językiem programowania?", { "Python", "PNG", "PDF" }, 1 },
	assignment = { "Po x = 4; x += 3 wartość x wynosi...", { "1", "7", "43" }, 2 },
	math_functions = {
		"Która funkcja daje pierwiastek w module math?",
		{ "math.sqrt()", "math.print()", "math.loop()" },
		1,
	},
	logic = {
		"Kiedy wyrażenie A and B jest prawdziwe?",
		{ "Gdy oba warunki są prawdziwe", "Gdy dowolny jest prawdziwy", "Zawsze" },
		1,
	},
	strings = { "Co zwraca len('kot')?", { "2", "3", "kot3" }, 2 },

	charts = {
		"Do porównania wartości kilku kategorii najlepiej pasuje...",
		{ "Wykres kolumnowy", "Losowy kolor komórki", "Komentarz" },
		1,
	},
	spreadsheet_use = { "Formuła sumująca A1:A3 to...", { "=SUMA(A1:A3)", "A1+A3?", "#SUM" }, 1 },
	data_import = {
		"Po imporcie danych warto najpierw...",
		{ "Sprawdzić format i nagłówki", "Usunąć wszystkie kolumny", "Zmienić wszystko na obraz" },
		1,
	},
}

local function getQuestion(mission)
	return variantQuestions[mission.variant] or questions[mission.type] or questions.GenericChallenge
end

local function getSlot(player)
	if not slotByUser[player.UserId] then
		nextSlot += 1
		slotByUser[player.UserId] = nextSlot
	end
	return slotByUser[player.UserId]
end
local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.Color = color or Color3.new(1, 1, 1)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function label(target, text, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(1024, 512)
	gui.LightInfluence = 0
	gui.Brightness = 1.2
	gui.Parent = target

	local luminance = target.Color.R * 0.2126 + target.Color.G * 0.7152 + target.Color.B * 0.0722
	local useDarkText = luminance > 0.58
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -52, 1, -38)
	t.Position = UDim2.fromOffset(26, 19)
	t.BackgroundColor3 = useDarkText and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(8, 12, 18)
	t.BackgroundTransparency = 0.18
	t.Text = text
	t.TextWrapped = true
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = useDarkText and Color3.fromRGB(24, 31, 42) or Color3.fromRGB(248, 250, 252)
	t.TextStrokeColor3 = useDarkText and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
	t.TextStrokeTransparency = useDarkText and 0.72 or 0.58
	t.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = t

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = t

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 16
	constraint.MaxTextSize = 54
	constraint.Parent = t
	return t
end

local function prompt(target, action, obj, callback)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = obj or ""
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.HoldDuration = 0.15
	pr.Parent = target
	pr.Triggered:Connect(callback)
	return pr
end

local function teleport(player, pos)
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")
	root.CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1))
end
local function setHud(player, remote, title, objective, score, timeLeft)
	lastHudState[player] = {
		title = title,
		objective = objective,
		score = score or 0,
		timeLeft = timeLeft,
	}
	remote:FireClient(player, {
		kind = "hud",
		title = title,
		objective = objective,
		score = score or 0,
		timeLeft = timeLeft,
	})
end

local function restoreActiveMissionOnRespawn(player, character)
	local info = respawnState[player]
	if not info or active[player] ~= info.model or not info.model.Parent or info.state.completed then
		return
	end

	task.defer(function()
		local root = character:WaitForChild("HumanoidRootPart", 8)
		local humanoid = character:WaitForChild("Humanoid", 8)
		if not root or not humanoid then
			return
		end

		task.wait(0.12)
		if respawnState[player] ~= info or active[player] ~= info.model or info.state.completed then
			return
		end

		root.CFrame = CFrame.lookAt(info.position, info.position + Vector3.new(0, 0, 1))
		local hud = lastHudState[player]
		local title = hud and hud.title or info.title
		local objective = hud and hud.objective or info.state.objective
		local score = hud and hud.score or info.state.score
		local timeLeft = hud and hud.timeLeft or nil
		setHud(player, info.remote, title, objective, score, timeLeft)
		info.remote:FireClient(player, { kind = "camera", mode = info.cameraMode })
	end)
end

local function bindRespawn(player)
	if respawnConnections[player] then
		return
	end
	respawnConnections[player] = player.CharacterAdded:Connect(function(character)
		restoreActiveMissionOnRespawn(player, character)
	end)
end

local function successFlash(player, remote, text)
	remote:FireClient(player, { kind = "message", text = text, good = true })
end

local function failFlash(player, remote, text)
	remote:FireClient(player, { kind = "message", text = text, good = false })
end

local function addHighlight(target, color)
	local h = Instance.new("Highlight")
	h.FillColor = color
	h.FillTransparency = 0.72
	h.OutlineColor = Color3.new(1, 1, 1)
	h.OutlineTransparency = 0.08
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = target
	h.Parent = target
	return h
end

local function addBob(target, height, duration)
	local base = target.Position
	TweenService:Create(
		target,
		TweenInfo.new(duration or 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Position = base + Vector3.new(0, height or 1.5, 0) }
	):Play()
end

local function addSparkle(target, color)
	local sparkle = Instance.new("Sparkles")
	sparkle.SparkleColor = color
	sparkle.Parent = target
	return sparkle
end

local function billboard(target, text, color, offset)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(460, 124)
	gui.StudsOffset = offset or Vector3.new(0, 6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 125
	gui.Parent = target

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(248, 250, 252)
	frame.BackgroundTransparency = 0.06
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 4
	stroke.Transparency = 0.05
	stroke.Parent = frame

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -30, 1, -24)
	txt.Position = UDim2.fromOffset(15, 12)
	txt.BackgroundTransparency = 1
	txt.Text = text
	txt.TextWrapped = true
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.fromRGB(25, 31, 40)
	txt.TextStrokeTransparency = 1
	txt.Parent = frame

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 17
	constraint.MaxTextSize = 30
	constraint.Parent = txt
	return gui, txt
end

local function addDecor(model, origin, profile)
	local accent = profile.accent
	local accent2 = profile.accent2
	local trimMaterial = VisualThemes.GetTrimMaterial(profile)
	local architecture = profile.architecture

	if architecture == "industrial" then
		for i = 1, 8 do
			local z = -62 + (i - 1) * 21
			for _, side in ipairs({ -1, 1 }) do
				local rib = part(
					model,
					string.format("IndustrialRib_%d_%d", i, side),
					Vector3.new(2.2, 13, 5),
					origin + Vector3.new(side * 38.5, 6.5, z),
					profile.surface,
					Enum.Material.Metal
				)
				local stripe = part(
					model,
					string.format("SafetyStripe_%d_%d", i, side),
					Vector3.new(0.4, 5, 3),
					rib.Position + Vector3.new(-side * 1.25, -2, 0),
					i % 2 == 0 and accent or accent2,
					trimMaterial
				)
				stripe.Transparency = profile.glowTrims and 0.12 or 0
			end
		end
		for i = 1, 6 do
			local z = -50 + (i - 1) * 25
			part(
				model,
				"IndustrialFloorLane" .. i,
				Vector3.new(30, 0.12, 0.8),
				origin + Vector3.new(0, 0.62, z),
				i % 2 == 0 and accent2 or accent,
				Enum.Material.SmoothPlastic
			)
		end
	elseif architecture == "studio" then
		for i = 1, 5 do
			local z = -54 + (i - 1) * 31
			for _, side in ipairs({ -1, 1 }) do
				local panel = part(
					model,
					string.format("StudioPanel_%d_%d", i, side),
					Vector3.new(1, 10, 20),
					origin + Vector3.new(side * 39.1, 7, z),
					i % 2 == 0 and accent or accent2,
					Enum.Material.SmoothPlastic
				)
				panel.Transparency = 0.08
			end
			local skylight = part(
				model,
				"StudioSkylight" .. i,
				Vector3.new(44, 0.45, 8),
				origin + Vector3.new(0, 16.8, z),
				Color3.fromRGB(245, 248, 250),
				Enum.Material.Glass
			)
			skylight.Transparency = 0.18
			skylight.CanCollide = false
		end
	elseif architecture == "museum" then
		for i = 1, 5 do
			local z = -54 + (i - 1) * 31
			for _, side in ipairs({ -1, 1 }) do
				local column = part(
					model,
					string.format("MuseumColumn_%d_%d", i, side),
					Vector3.new(5, 15, 5),
					origin + Vector3.new(side * 35, 7.5, z),
					profile.surface,
					Enum.Material.Sandstone
				)
				part(
					model,
					string.format("MuseumCap_%d_%d", i, side),
					Vector3.new(8, 1, 8),
					column.Position + Vector3.new(0, 7.4, 0),
					accent,
					Enum.Material.SmoothPlastic
				)
			end
		end
	elseif architecture == "office" then
		for i = 1, 5 do
			local z = -54 + (i - 1) * 31
			for _, side in ipairs({ -1, 1 }) do
				local board = part(
					model,
					string.format("OfficeBoard_%d_%d", i, side),
					Vector3.new(1, 9, 20),
					origin + Vector3.new(side * 39.1, 7, z),
					i % 2 == 0 and profile.surface or profile.surface2,
					Enum.Material.Wood
				)
				part(
					model,
					string.format("OfficeHeader_%d_%d", i, side),
					Vector3.new(1.2, 2, 18),
					board.Position + Vector3.new(-side * 0.2, 4.8, 0),
					i % 2 == 0 and accent or accent2,
					Enum.Material.SmoothPlastic
				)
			end
		end
	elseif architecture == "workshop" then
		for i = 1, 5 do
			local z = -55 + (i - 1) * 31
			local beam = part(
				model,
				"WorkshopCrossbeam" .. i,
				Vector3.new(72, 1.2, 3),
				origin + Vector3.new(0, 16, z),
				profile.surface2,
				Enum.Material.WoodPlanks
			)
			beam.CanCollide = false
			for _, side in ipairs({ -1, 1 }) do
				part(
					model,
					string.format("ToolRail_%d_%d", i, side),
					Vector3.new(1, 5, 17),
					origin + Vector3.new(side * 39, 5, z),
					i % 2 == 0 and accent2 or accent,
					Enum.Material.Metal
				)
			end
		end
	elseif architecture == "stage" then
		for _, side in ipairs({ -1, 1 }) do
			local curtain = part(
				model,
				"StageCurtain" .. side,
				Vector3.new(8, 17, 145),
				origin + Vector3.new(side * 36, 8.5, 15),
				side == -1 and accent or accent2,
				Enum.Material.Fabric
			)
			curtain.Transparency = 0.08
		end
		for i = 1, 5 do
			local z = -55 + (i - 1) * 31
			part(
				model,
				"StageTruss" .. i,
				Vector3.new(70, 0.7, 2),
				origin + Vector3.new(0, 16, z),
				Color3.fromRGB(125, 125, 132),
				Enum.Material.Metal
			)
		end
	elseif architecture == "arcade" then
		for i = 1, 14 do
			local x = i % 2 == 0 and -20 or 20
			local z = -58 + (i - 1) * 11
			local tile = part(
				model,
				"ArcadePad" .. i,
				Vector3.new(16, 0.14, 8),
				origin + Vector3.new(x, 0.62, z),
				i % 3 == 0 and accent2 or accent,
				Enum.Material.SmoothPlastic
			)
			tile.Transparency = 0.08
		end
	else
		for i = 1, 6 do
			local z = -55 + (i - 1) * 25
			for _, side in ipairs({ -1, 1 }) do
				local rail = part(
					model,
					string.format("LabRail_%d_%d", i, side),
					Vector3.new(1, 8, 12),
					origin + Vector3.new(side * 39, 6, z),
					profile.surface,
					Enum.Material.Metal
				)
				local badge = part(
					model,
					string.format("LabBadge_%d_%d", i, side),
					Vector3.new(1.2, 2.4, 8),
					rail.Position + Vector3.new(-side * 0.3, 2.4, 0),
					i % 2 == 0 and accent or accent2,
					trimMaterial
				)
				badge.Transparency = profile.glowTrims and 0.12 or 0
			end
		end
	end
end

local function addKindArchitecture(model, origin, kind, profile)
	local accent = profile.accent
	local dark = profile.surface2
	local trimMaterial = VisualThemes.GetTrimMaterial(profile)
	if kind == "Sort" then
		for sideIndex, side in ipairs({ -1, 1 }) do
			local shelf = part(
				model,
				"SortShelf" .. sideIndex,
				Vector3.new(12, 12, 42),
				origin + Vector3.new(side * 31, 6, -3),
				profile.surface2,
				profile.structureMaterial
			)
			shelf.CanCollide = true
			for row = 1, 3 do
				local rail = part(
					model,
					string.format("SortShelfRail_%d_%d", sideIndex, row),
					Vector3.new(13, 0.5, 42),
					shelf.Position + Vector3.new(0, -5 + row * 3.2, 0),
					accent,
					Enum.Material.Metal
				)
				rail.Transparency = 0.12
			end
		end
	elseif kind == "Collect" then
		for i = 1, 4 do
			local x = ({ -27, -9, 9, 27 })[i]
			local plinth = part(
				model,
				"GalleryPlinth" .. i,
				Vector3.new(10, 3, 10),
				origin + Vector3.new(x, 1.5, -2),
				profile.surface,
				profile.structureMaterial
			)
			local trim = part(
				model,
				"GalleryTrim" .. i,
				Vector3.new(10.5, 0.35, 10.5),
				plinth.Position + Vector3.new(0, 1.7, 0),
				accent,
				trimMaterial
			)
			trim.Transparency = profile.glowTrims and 0.22 or 0.05
		end
	elseif kind == "Sequence" then
		for x = -3, 3 do
			local line = part(
				model,
				"SequenceGridX" .. x,
				Vector3.new(0.15, 0.12, 64),
				origin + Vector3.new(x * 10, 0.62, 10),
				accent,
				trimMaterial
			)
			line.Transparency = 0.55
		end
		for z = -2, 4 do
			local line = part(
				model,
				"SequenceGridZ" .. z,
				Vector3.new(62, 0.12, 0.15),
				origin + Vector3.new(0, 0.63, z * 10),
				accent,
				trimMaterial
			)
			line.Transparency = 0.55
		end
	elseif kind == "Vault" then
		local frame = part(
			model,
			"VaultBackdrop",
			Vector3.new(58, 20, 5),
			origin + Vector3.new(0, 10, -3),
			Color3.fromRGB(48, 46, 44),
			Enum.Material.DiamondPlate
		)
		local inner = part(
			model,
			"VaultInset",
			Vector3.new(38, 14, 1),
			frame.Position + Vector3.new(0, 0, 3),
			Color3.fromRGB(28, 30, 34),
			Enum.Material.Metal
		)
		inner.CanCollide = false
	elseif kind == "Build" then
		for i = 1, 3 do
			local x = -24 + (i - 1) * 24
			local bench = part(
				model,
				"WorkshopBench" .. i,
				Vector3.new(18, 3, 12),
				origin + Vector3.new(x, 2.2, 4),
				profile.surface2,
				profile.structureMaterial
			)
			local panel = part(
				model,
				"WorkshopPanel" .. i,
				Vector3.new(18, 9, 1),
				origin + Vector3.new(x, 8, 10),
				profile.surface,
				Enum.Material.Metal
			)
			label(panel, i == 1 and "STANOWISKO A" or (i == 2 and "STANOWISKO B" or "STANOWISKO C"))
			bench.CanCollide = true
		end
	elseif kind == "Decision" then
		for i = 1, 3 do
			local x = -24 + (i - 1) * 24
			local bay = part(
				model,
				"DecisionBay" .. i,
				Vector3.new(19, 0.4, 26),
				origin + Vector3.new(x, 0.7, -8),
				profile.surface2,
				profile.structureMaterial
			)
			local edge = part(
				model,
				"DecisionBayEdge" .. i,
				Vector3.new(19, 0.25, 1),
				bay.Position + Vector3.new(0, 0.3, -12),
				accent,
				trimMaterial
			)
			edge.Transparency = 0.2
		end
	elseif kind == "Python" then
		for i = 1, 3 do
			local rack = part(
				model,
				"PythonRack" .. i,
				Vector3.new(10, 15, 6),
				origin + Vector3.new(29, 7.5, -25 + (i - 1) * 18),
				profile.surface2,
				Enum.Material.Metal
			)
			local display = part(
				model,
				"PythonRackDisplay" .. i,
				Vector3.new(7, 3, 0.3),
				rack.Position + Vector3.new(0, 2, -3.2),
				profile.accent2,
				Enum.Material.Glass
			)
			display.CanCollide = false
		end
	elseif kind == "Factory" then
		for i = 1, 5 do
			local belt = part(
				model,
				"FactoryBelt" .. i,
				Vector3.new(12, 1, 10),
				origin + Vector3.new(-24 + (i - 1) * 12, 1.2, 4),
				profile.surface2,
				Enum.Material.DiamondPlate
			)
			local marker = part(
				model,
				"FactoryMarker" .. i,
				Vector3.new(2, 0.25, 10),
				belt.Position + Vector3.new(0, 0.65, 0),
				accent,
				trimMaterial
			)
			marker.Transparency = 0.22
		end
	end
end

local function themeSign(model, origin, text, pos, color, size)
	local s =
		part(model, "ThemeSign_" .. text, (size or Vector3.new(14, 6, 2)), origin + pos, color, Enum.Material.Metal)
	label(s, text)
	return s
end

local function addThemeDecor(model, origin, missionType, accent, dark)
	if missionType == "HardwareBuild" then
		local tower = part(
			model,
			"PC_Tower",
			Vector3.new(18, 28, 12),
			origin + Vector3.new(-27, 14, -10),
			Color3.fromRGB(30, 34, 42),
			Enum.Material.Metal
		)
		label(tower, "KOMPUTER\nZŁÓŻ PODZESPOŁY")
		local cpu = part(
			model,
			"CPU_Decor",
			Vector3.new(6, 2, 6),
			origin + Vector3.new(-27, 17, -3),
			Color3.fromRGB(210, 210, 210),
			Enum.Material.Metal
		)
		label(cpu, "CPU", Enum.NormalId.Top)
		local ram = part(
			model,
			"RAM_Decor",
			Vector3.new(2, 10, 2),
			origin + Vector3.new(-33, 13, -3),
			Color3.fromRGB(40, 190, 80),
			Enum.Material.Neon
		)
		label(ram, "RAM")
		local disk = part(
			model,
			"DISK_Decor",
			Vector3.new(8, 3, 7),
			origin + Vector3.new(-20, 7, -3),
			Color3.fromRGB(70, 110, 180),
			Enum.Material.Metal
		)
		label(disk, "DYSK", Enum.NormalId.Top)
	elseif missionType == "NetworkBuilder" then
		for i = 1, 3 do
			local rack = part(
				model,
				"Rack" .. i,
				Vector3.new(12, 20, 7),
				origin + Vector3.new(-26 + (i - 1) * 26, 10, -8),
				Color3.fromRGB(24, 28, 35),
				Enum.Material.Metal
			)
			for j = 1, 4 do
				local led = part(
					model,
					"LED_" .. i .. "_" .. j,
					Vector3.new(8, 1, 1),
					origin + Vector3.new(-26 + (i - 1) * 26, 16 - (j * 3), -4),
					accent,
					Enum.Material.Neon
				)
				led.Transparency = 0.08
			end
		end
		themeSign(model, origin, "SERWER", Vector3.new(-26, 23, -8), accent, Vector3.new(12, 5, 2))
		themeSign(model, origin, "SWITCH", Vector3.new(0, 23, -8), accent, Vector3.new(12, 5, 2))
		themeSign(model, origin, "ROUTER", Vector3.new(26, 23, -8), accent, Vector3.new(12, 5, 2))
	elseif missionType == "WebBuilder" or missionType == "StyleLab" then
		local browser = part(
			model,
			"Browser",
			Vector3.new(64, 30, 2),
			origin + Vector3.new(0, 16, -9),
			Color3.fromRGB(235, 238, 245),
			Enum.Material.SmoothPlastic
		)
		local bar = part(
			model,
			"BrowserBar",
			Vector3.new(64, 4, 1),
			origin + Vector3.new(0, 29, -7.8),
			Color3.fromRGB(55, 62, 76),
			Enum.Material.Metal
		)
		label(bar, "◀  ▶   https://moja-strona.local")
		local nav =
			part(model, "Nav", Vector3.new(56, 5, 1), origin + Vector3.new(0, 22, -7.7), accent, Enum.Material.Neon)
		label(nav, missionType == "StyleLab" and "CSS: KOLOR • ODSTĘP • CZCIONKA" or "<header>  <nav>  <main>")
		local content = part(
			model,
			"PageContent",
			Vector3.new(36, 12, 1),
			origin + Vector3.new(-9, 12, -7.7),
			Color3.fromRGB(120, 150, 210),
			Enum.Material.SmoothPlastic
		)
		label(content, "TREŚĆ STRONY")
		local aside = part(
			model,
			"Aside",
			Vector3.new(16, 12, 1),
			origin + Vector3.new(20, 12, -7.7),
			Color3.fromRGB(90, 205, 160),
			Enum.Material.SmoothPlastic
		)
		label(aside, "MENU")
	elseif missionType == "DatabaseMission" then
		for t = 1, 2 do
			local x = t == 1 and -18 or 18
			local tableTop = part(
				model,
				"DBTable" .. t,
				Vector3.new(28, 5, 2),
				origin + Vector3.new(x, 20, -8),
				accent,
				Enum.Material.Neon
			)
			label(tableTop, t == 1 and "UCZNIOWIE" or "KLASY")
			for r = 1, 4 do
				local row = part(
					model,
					"DBRow" .. t .. "_" .. r,
					Vector3.new(28, 3, 2),
					origin + Vector3.new(x, 15 - (r * 3), -8),
					Color3.fromRGB(55, 62, 76),
					Enum.Material.Metal
				)
				label(row, string.format("%s | %s", r, t == 1 and ("ID=" .. r) or ("KLASA=" .. r)))
			end
		end
		local rel = part(
			model,
			"RelationLine",
			Vector3.new(12, 1, 1),
			origin + Vector3.new(0, 13, -8),
			Color3.fromRGB(255, 210, 65),
			Enum.Material.Neon
		)
		label(rel, "RELACJA", Enum.NormalId.Top)
	elseif missionType == "GraphicsLab" or missionType == "PresentationLab" then
		local canvas = part(
			model,
			"Canvas",
			Vector3.new(46, 28, 2),
			origin + Vector3.new(0, 15, -8),
			Color3.fromRGB(245, 245, 245),
			Enum.Material.SmoothPlastic
		)
		label(
			canvas,
			missionType == "GraphicsLab" and "PŁÓTNO\nKOLOR • KSZTAŁT • WARSTWA"
				or "SLAJD\nTYTUŁ • OBRAZ • TREŚĆ"
		)
		local colors = {
			Color3.fromRGB(255, 80, 90),
			Color3.fromRGB(255, 205, 70),
			Color3.fromRGB(70, 210, 125),
			Color3.fromRGB(70, 140, 255),
		}
		for i, c in ipairs(colors) do
			local sw = part(
				model,
				"Palette" .. i,
				Vector3.new(5, 5, 2),
				origin + Vector3.new(-28 + i * 9, 2, -7.8),
				c,
				Enum.Material.Neon
			)
			sw.Shape = Enum.PartType.Ball
		end
	elseif missionType == "RobotSequence" or missionType == "BlockProgram" or missionType == "AlgorithmPath" then
		local body = part(
			model,
			"RobotBody",
			Vector3.new(10, 8, 8),
			origin + Vector3.new(-26, 5, -8),
			Color3.fromRGB(95, 105, 120),
			Enum.Material.Metal
		)
		label(body, "BOT")
		local eye1 =
			part(model, "Eye1", Vector3.new(2, 2, 1), origin + Vector3.new(-29, 6, -3.5), accent, Enum.Material.Neon)
		local eye2 =
			part(model, "Eye2", Vector3.new(2, 2, 1), origin + Vector3.new(-23, 6, -3.5), accent, Enum.Material.Neon)
		for i = 1, 6 do
			local tile = part(
				model,
				"RobotPath" .. i,
				Vector3.new(8, 1, 8),
				origin + Vector3.new(-15 + i * 9, 1, -5 + (i % 2) * 8),
				Color3.fromRGB(42, 52, 64),
				Enum.Material.Metal
			)
			label(tile, tostring(i), Enum.NormalId.Top)
		end
	elseif missionType == "CodeRepair" or missionType == "CipherVault" or missionType == "BinaryVault" then
		local code = part(
			model,
			"CodeWall",
			Vector3.new(58, 24, 2),
			origin + Vector3.new(0, 14, -9),
			Color3.fromRGB(15, 18, 22),
			Enum.Material.Metal
		)
		local txt = missionType == "CodeRepair" and "local x = 3\nx = x + 2\nprint(x)"
			or (missionType == "CipherVault" and "KHOOR → ?\nPRZESUNIĘCIE -3" or "1010₂ = ?₁₀")
		label(code, txt)
	elseif
		missionType == "CyberTerminal"
		or missionType == "SourceCheck"
		or missionType == "AICheck"
		or missionType == "DigitalLaw"
	then
		for i = 1, 3 do
			local warn = themeSign(
				model,
				origin,
				i == 1 and "UWAGA" or (i == 2 and "SPRAWDŹ ŹRÓDŁO" or "PODEJMIJ DECYZJĘ"),
				Vector3.new(-26 + (i - 1) * 26, 7, -10),
				i == 1 and Color3.fromRGB(220, 50, 55) or accent,
				Vector3.new(20, 10, 2)
			)
			local light = Instance.new("PointLight")
			light.Color = warn.Color
			light.Range = 15
			light.Brightness = 1.2
			light.Parent = warn
		end
	end
end

local function baseArena(player, lesson, mission, remote)
	local slot = getSlot(player)
	local origin = Vector3.new((slot - 1) * 180, 0, -900)
	if active[player] then
		active[player]:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Mission_" .. player.UserId
	model.Parent = workspace:FindFirstChild("PlayerMissions") or workspace
	active[player] = model
	local kind = archetype[mission.type] or "Hunt"
	local profile, styleName = VisualThemes.Get(mission)
	local dark, accent = profile.surface2, profile.accent
	model:SetAttribute("VisualStyle", styleName)
	model:SetAttribute("MissionVariant", mission.variant or "legacy")

	part(model, "Floor", Vector3.new(82, 1, 180), origin + Vector3.new(0, 0, 15), profile.floor, profile.floorMaterial)
	part(
		model,
		"LeftWall",
		Vector3.new(2, 18, 180),
		origin + Vector3.new(-41, 9, 15),
		profile.wall,
		profile.wallMaterial
	)
	part(
		model,
		"RightWall",
		Vector3.new(2, 18, 180),
		origin + Vector3.new(41, 9, 15),
		profile.wall,
		profile.wallMaterial
	)

	local header = part(
		model,
		"Header",
		Vector3.new(60, 12, 2),
		origin + Vector3.new(0, 8, -66),
		profile.surface2,
		profile.structureMaterial
	)
	label(header, string.format("%s • %02d\n%s", player:GetAttribute("SelectedGrade") or "", lesson.nr, lesson.topic))
	-- Semantic physical props are injected by SemanticAssetDecorator.

	local hasDedicatedWorld = mission.variant == "paint_shapes"
		or mission.variant == "paint_text"
		or mission.variant == "paint_composition"
		or mission.variant == "ai_paint_print"
		or mission.variant == "layered_graphics_text"
		or mission.variant == "timeline"
		or mission.variant == "cyber"
		or mission.variant == "search"
		or mission.variant == "research"
		or mission.variant == "problem_solving"
		or mission.variant == "typing"
		or mission.variant == "graphics_tricks"
		or mission.variant == "image_transform"
		or mission.variant == "threats"
		or mission.variant == "devices"
		or mission.variant == "photo_edit_1"
		or mission.variant == "photo_edit_2"
		or mission.variant == "scratch_loop"
		or mission.variant == "scratch_media"
		or mission.variant == "scratch_events"
		or mission.variant == "scratch_project"
		or mission.variant == "robot"
		or mission.variant == "pseudocode"
		or mission.variant == "python_robot_intro_sp7"
		or mission.variant == "python_robot_maze_sp8"
		or mission.variant == "python_world_control_sp8"
		or mission.variant == "natural_numbers"
		or mission.variant == "search_algorithm"
		or mission.variant == "sorting"
		or mission.variant == "sports_media"
		or mission.variant == "languages"
		or mission.variant == "math_functions"
		or mission.variant == "conditions"
		or mission.variant == "logic"
		or mission.variant == "sequences"
		or mission.variant == "number_systems"
		or mission.variant == "conversion"
		or mission.variant == "charts"
		or mission.variant == "spreadsheet_use"
		or mission.variant == "slides_animation"
		or mission.variant == "slides_sound"
		or mission.variant == "javablock"
		or mission.variant == "data_representation"
		or mission.variant == "chapter_finale"
		or mission.variant == "mail_merge"
		or mission.variant == "data_import"
		or mission.variant == "os_troubleshooting"
		or mission.variant == "internet"
		or mission.variant == "network_services"
		or mission.variant == "html"
		or mission.variant == "css"
		or mission.variant == "website"
	if not hasDedicatedWorld then
		addDecor(model, origin, profile)
		addKindArchitecture(model, origin, kind, profile)
		addThemeDecor(model, origin, mission.type, accent, dark)
	end

	local checkpoint = origin + Vector3.new(0, 4, 18)
	if kind == "Escape" or kind == "Defense" or kind == "Hunt" then
		local archLeft = part(
			model,
			"FirewallPostL",
			Vector3.new(5, 14, 5),
			origin + Vector3.new(-30, 7, 31),
			Color3.fromRGB(50, 55, 65),
			Enum.Material.Metal
		)
		local archRight = part(
			model,
			"FirewallPostR",
			Vector3.new(5, 14, 5),
			origin + Vector3.new(30, 7, 31),
			Color3.fromRGB(50, 55, 65),
			Enum.Material.Metal
		)
		local archTop = part(
			model,
			"FirewallHeader",
			Vector3.new(65, 4, 5),
			origin + Vector3.new(0, 14, 31),
			Color3.fromRGB(42, 48, 58),
			Enum.Material.Metal
		)
		label(archTop, "STREFA FIREWALLA • OMIJAJ CZERWONE WIĄZKI")
		for _, post in ipairs({ archLeft, archRight }) do
			local lamp = Instance.new("PointLight")
			lamp.Color = Color3.fromRGB(255, 80, 80)
			lamp.Brightness = 0.9
			lamp.Range = 10
			lamp.Parent = post
		end

		for i = 1, 2 do
			local z = 43 + (i - 1) * 17
			local emitterX = i == 1 and -31 or 31
			local emitter = part(
				model,
				"LaserEmitter" .. i,
				Vector3.new(5, 7, 5),
				origin + Vector3.new(emitterX, 3.5, z),
				Color3.fromRGB(55, 58, 66),
				Enum.Material.Metal
			)
			billboard(emitter, "LASER " .. i, Color3.fromRGB(255, 80, 80), Vector3.new(0, 5, 0))
			local laser = part(
				model,
				"SecurityLaser" .. i,
				Vector3.new(38, 0.65, 0.65),
				origin + Vector3.new(i == 1 and -8 or 8, 4.5 + i, z),
				Color3.fromRGB(255, 55, 70),
				Enum.Material.Neon
			)
			laser.Transparency = 0.08
			local glow = Instance.new("PointLight")
			glow.Color = laser.Color
			glow.Brightness = 0.7
			glow.Range = 8
			glow.Parent = laser
			laser.Touched:Connect(function(hit)
				local p = Players:GetPlayerFromCharacter(hit.Parent)
				if p == player then
					teleport(player, checkpoint)
					failFlash(
						player,
						remote,
						"Dotknąłeś czerwonej wiązki. Wróciłeś do checkpointu przed strefą."
					)
				end
			end)
			local targetX = i == 1 and 8 or -8
			TweenService:Create(
				laser,
				TweenInfo.new(2.6 + i * 0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Position = origin + Vector3.new(targetX, 4.5 + i, z) }
			):Play()
		end
	else
		local guide = part(
			model,
			"StageTwoPath",
			Vector3.new(24, 0.22, 58),
			origin + Vector3.new(0, 0.62, 49),
			Color3.fromRGB(55, 62, 72),
			Enum.Material.Metal
		)
		guide.Transparency = 0.15
	end

	return model, origin, kind, dark, accent
end

local function addFinalCore(model, origin, player, remote, state, accent)
	local pedestal = part(
		model,
		"CorePedestal",
		Vector3.new(18, 3, 18),
		origin + Vector3.new(0, 1.5, 75),
		Color3.fromRGB(35, 42, 52),
		Enum.Material.Metal
	)
	local core =
		part(model, "MissionCore", Vector3.new(9, 9, 9), origin + Vector3.new(0, 8, 75), accent, Enum.Material.Glass)
	core.Shape = Enum.PartType.Ball
	core.Transparency = 0.08
	addHighlight(core, accent)

	local light = Instance.new("PointLight")
	light.Color = accent
	light.Brightness = 1.4
	light.Range = 18
	light.Parent = core

	local marker, markerText = billboard(
		pedestal,
		"ETAP 2/3 • AKTYWUJ RDZEŃ\nPodejdź i naciśnij E",
		Color3.fromRGB(255, 205, 70),
		Vector3.new(0, 10, 0)
	)
	marker.Enabled = false
	state.coreMarker = marker
	state.coreMarkerText = markerText

	local corePrompt = prompt(core, "AKTYWUJ", "RDZEŃ MISJI • ETAP 2/3", function(p)
		if p ~= player then
			return
		end
		if not state.done then
			failFlash(player, remote, "Najpierw wykonaj zadanie z etapu 1. Rdzeń odblokuje się dopiero potem.")
			return
		end
		if state.exitReady then
			return
		end

		state.exitReady = true
		corePrompt.Enabled = false
		if state.exitPrompt then
			state.exitPrompt.Enabled = true
		end
		state.score += 50
		core.Color = Color3.fromRGB(70, 255, 135)
		light.Color = core.Color
		marker.Enabled = false
		if state.exitGate then
			state.exitGate.Color = Color3.fromRGB(45, 210, 105)
			state.exitGate.Material = Enum.Material.Neon
		end
		if state.exitGateLabel then
			state.exitGateLabel.Text = "WYJŚCIE AKTYWNE\nETAP 3/3"
		end
		if state.exitMarker then
			state.exitMarker.Enabled = true
		end
		successFlash(player, remote, "Rdzeń aktywny. Teraz idź do oznaczonego zielonego portalu WYJŚCIE.")
		setHud(
			player,
			remote,
			"ETAP 3/3",
			"Idź do zielonego portalu WYJŚCIE na końcu planszy i naciśnij E.",
			state.score
		)
	end)
	corePrompt.Enabled = false
	state.corePrompt = corePrompt

	task.spawn(function()
		while player.Parent and active[player] == model and not state.completed and not state.done do
			task.wait(0.15)
		end
		if player.Parent and active[player] == model and state.done and not state.completed and not state.exitReady then
			marker.Enabled = true
			corePrompt.Enabled = true
		end
	end)
end

local function finishGate(model, origin, player, remote, state)
	local gate = part(
		model,
		"ExitGate",
		Vector3.new(28, 14, 3),
		origin + Vector3.new(0, 7, 94),
		Color3.fromRGB(105, 55, 55),
		Enum.Material.Metal
	)
	local gateLabel = label(gate, "WYJŚCIE ZABLOKOWANE\nAKTYWUJ RDZEŃ")
	local exitMarker = billboard(
		gate,
		"ETAP 3/3 • WYJŚCIE\nPodejdź i naciśnij E",
		Color3.fromRGB(70, 255, 135),
		Vector3.new(0, 11, 0)
	)
	exitMarker.Enabled = false
	state.exitGate = gate
	state.exitGateLabel = gateLabel
	state.exitMarker = exitMarker

	local exitPrompt = prompt(gate, "ZAKOŃCZ", "WYJŚCIE", function(p)
		if p ~= player then
			return
		end
		if not state.exitReady then
			failFlash(player, remote, "WYJŚCIE ZABLOKOWANE. Ukończ etap 1, potem aktywuj oznaczony rdzeń etapu 2.")
			return
		end
		state.completed = true
		exitMarker.Enabled = false
		local elapsed = math.floor(os.clock() - state.started)
		state.score += math.max(0, 120 - elapsed)
		setHud(player, remote, "MISJA UKOŃCZONA", "Wynik końcowy: " .. state.score, state.score, 0)
		player:SetAttribute("Score", state.score)
		local standings = {}
		for _, competitor in ipairs(Players:GetPlayers()) do
			table.insert(standings, {
				name = competitor.DisplayName,
				score = competitor:GetAttribute("Score") or 0,
				userId = competitor.UserId,
			})
		end
		local rank, total, top = SessionStandings.build(standings, player.UserId)
		remote:FireClient(player, {
			kind = "complete",
			score = state.score,
			time = elapsed,
			rank = rank,
			total = #standings,
			top = top,
		})
	end)
	exitPrompt.Enabled = false
	state.exitPrompt = exitPrompt

	task.spawn(function()
		while player.Parent and active[player] == model and not state.completed and not state.exitReady do
			task.wait(0.15)
		end
		if player.Parent and active[player] == model and state.exitReady and not state.completed then
			exitPrompt.Enabled = true
		end
	end)
end

local function decisionGame(model, origin, player, lesson, mission, remote, state, accent)
	local questionSet = DecisionScenarios.Get(mission.variant) or { getQuestion(mission) }
	state.decisionStep = 1

	local board = part(
		model,
		"Question",
		Vector3.new(62, 10, 2),
		origin + Vector3.new(0, 7, -38),
		Color3.fromRGB(25, 25, 30),
		Enum.Material.Metal
	)
	local questionLabel = label(board, "")
	local doors = {}
	local answerLabels = {}

	local function rewardForStep(step)
		local base = math.floor(100 / #questionSet)
		if step == #questionSet then
			return 100 - base * (#questionSet - 1)
		end
		return base
	end

	local function renderStep()
		local q = questionSet[state.decisionStep]
		questionLabel.Text = string.format("ETAP %d/%d\n%s", state.decisionStep, #questionSet, q[1])
		for i = 1, 3 do
			answerLabels[i].Text = q[2][i] or "—"
			doors[i].Color = accent
			local pr = doors[i]:FindFirstChildOfClass("ProximityPrompt")
			if pr then
				pr.Enabled = q[2][i] ~= nil
			end
		end
		setHud(
			player,
			remote,
			lesson.topic,
			string.format("Scenariusz %d/%d: wybierz najlepszą decyzję.", state.decisionStep, #questionSet),
			state.score
		)
	end

	for i = 1, 3 do
		local x = (i - 2) * 20
		local door = part(
			model,
			"Answer" .. i,
			Vector3.new(16, 12, 3),
			origin + Vector3.new(x, 6, -17),
			accent,
			Enum.Material.Neon
		)
		doors[i] = door
		answerLabels[i] = label(door, "")
		addHighlight(door, accent)
		prompt(door, "Wybierz", "Odpowiedź " .. i, function(p)
			if p ~= player or state.done then
				return
			end

			local q = questionSet[state.decisionStep]
			if i == q[3] then
				state.score += rewardForStep(state.decisionStep)
				door.Color = Color3.fromRGB(45, 220, 90)
				local feedback = q[4] or "Dobra decyzja."
				state.decisionStep += 1
				if state.decisionStep > #questionSet then
					state.done = true
					successFlash(player, remote, feedback .. " Scenariusz ukończony — znajdź wyjście.")
					setHud(player, remote, lesson.topic, "Dotrzyj do wyjścia.", state.score)
				else
					successFlash(player, remote, feedback .. " Następny etap.")
					renderStep()
				end
			else
				state.score = math.max(0, state.score - 10)
				door.Color = Color3.fromRGB(220, 50, 55)
				failFlash(player, remote, "Ta decyzja zwiększa ryzyko. Przeanalizuj sytuację i spróbuj ponownie.")
				setHud(
					player,
					remote,
					lesson.topic,
					string.format("Scenariusz %d/%d: spróbuj ponownie.", state.decisionStep, #questionSet),
					state.score
				)
			end
		end)
	end

	renderStep()
end
local collectSets = {
	GraphicsLab = { "KOLOR", "KSZTAŁT", "WARSTWA", "KADR" },
	paint_shapes = { "LINIA", "PROSTOKĄT", "OKRĄG", "KOLOR" },
	paint_text = { "OBRAZ", "TEKST", "ZAPIS", "FORMAT" },
	paint_composition = { "TŁO", "KSZTAŁT", "KOLOR", "UKŁAD" },
	graphics_tricks = { "KOPIA", "OBRÓT", "SKALA", "KOLOR" },
	image_transform = { "KADR", "OBRÓT", "ROZMIAR", "KONTRAST" },
	photo_edit_1 = { "KADR", "JASNOŚĆ", "KONTRAST", "ZAPIS" },
	photo_edit_2 = { "WARSTWA", "KOLOR", "FILTR", "EKSPORT" },
	PresentationLab = { "TYTUŁ", "OBRAZ", "TREŚĆ", "ANIMACJA" },
	slides_animation = { "TYTUŁ", "OBIEKT", "ANIMACJA", "CZAS" },
	slides_sound = { "SLAJD", "PRZEJŚCIE", "DŹWIĘK", "TEST" },
	DocumentRepair = { "NAGŁÓWEK", "AKAPIT", "STYL", "STOPKA" },
	mail_merge = { "SZABLON", "ŹRÓDŁO", "POLE", "SCAL" },
	TypingRush = { "A", "S", "D", "F" },
	typing = { "LEWA RĘKA", "PRAWA RĘKA", "SPACJA", "ENTER" },
	ProjectQuest = { "CEL", "PLAN", "ZASOBY", "TEST" },
	sports_media = { "ZDJĘCIE", "WYNIK", "OPIS", "PUBLIKACJA" },
	TechHistory = { "ENIAC", "PC", "INTERNET", "SMARTFON" },
	timeline = { "ABAKUS", "ENIAC", "PC", "SMARTFON" },
	tech_history = { "MAINFRAME", "PC", "WWW", "AI" },
	MixedChallenge = { "LOGIKA", "DANE", "SIEĆ", "KOD" },
	chapter_finale = { "ALGORYTM", "DANE", "PREZENTACJA", "DEBATA" },
}

local function collectGame(model, origin, player, lesson, mission, remote, state, accent)
	state.collected = 0
	local names = collectSets[mission.variant]
		or collectSets[mission.type]
		or { "PAKIET DANYCH", "PLIK", "ZNACZNIK", "FRAGMENT" }
	for i = 1, 4 do
		local x = ({ -26, 22, -18, 28 })[i]
		local z = ({ -35, -8, 7, 70 })[i]
		local orb = part(
			model,
			"Collectible" .. i,
			Vector3.new(5, 5, 5),
			origin + Vector3.new(x, 4, z),
			accent,
			Enum.Material.Neon
		)
		orb.Shape = Enum.PartType.Ball
		addHighlight(orb, accent)
		addSparkle(orb, accent)
		addBob(orb, 1.8, 1.4 + i * 0.12)
		local light = Instance.new("PointLight")
		light.Color = accent
		light.Range = 16
		light.Brightness = 2
		light.Parent = orb
		prompt(orb, "Zbierz", names[i], function(p)
			if p ~= player or orb:GetAttribute("Taken") then
				return
			end
			orb:SetAttribute("Taken", true)
			state.collected += 1
			state.score += 25
			orb.Transparency = 1
			orb.CanCollide = false
			local pr = orb:FindFirstChildOfClass("ProximityPrompt")
			if pr then
				pr.Enabled = false
			end
			if state.collected >= 4 then
				state.done = true
				successFlash(player, remote, "Komplet danych! Pokonaj firewall i znajdź wyjście.")
			end
			setHud(player, remote, lesson.topic, string.format("Zebrano %d/4 elementów", state.collected), state.score)
		end)
	end
end

local sortSets = {
	FileSort = {
		bins = { "DOKUMENTY", "OBRAZY", "KOD", "DANE" },
		items = {
			{ "raport.docx", "DOKUMENTY" },
			{ "zdjecie.png", "OBRAZY" },
			{ "skrypt.py", "KOD" },
			{ "tabela.xlsx", "DANE" },
		},
	},
	files = {
		bins = { "DOKUMENTY", "OBRAZY", "KOD", "DANE" },
		items = {
			{ "plan.docx", "DOKUMENTY" },
			{ "logo.png", "OBRAZY" },
			{ "gra.lua", "KOD" },
			{ "wyniki.csv", "DANE" },
		},
	},
	SoftwareSort = {
		bins = { "SYSTEM", "APLIKACJA" },
		items = {
			{ "Windows", "SYSTEM" },
			{ "Linux", "SYSTEM" },
			{ "Paint", "APLIKACJA" },
			{ "Word", "APLIKACJA" },
		},
	},
	software = {
		bins = { "SYSTEM", "APLIKACJA" },
		items = {
			{ "Windows", "SYSTEM" },
			{ "Android", "SYSTEM" },
			{ "Paint", "APLIKACJA" },
			{ "Teams", "APLIKACJA" },
		},
	},
	os_troubleshooting = {
		bins = { "PROBLEM SYSTEMU", "PROBLEM APLIKACJI" },
		items = {
			{ "Brak sterownika", "PROBLEM SYSTEMU" },
			{ "Aktualizacja jądra", "PROBLEM SYSTEMU" },
			{ "Zawieszony edytor", "PROBLEM APLIKACJI" },
			{ "Błąd w przeglądarce", "PROBLEM APLIKACJI" },
		},
	},
}

local function sortGame(model, origin, player, lesson, mission, remote, state, accent)
	local cfg = sortSets[mission.variant] or sortSets[mission.type] or sortSets.FileSort
	state.sorted = 0
	state.carry = nil
	state.source = nil

	local board = part(
		model,
		"SortBoard",
		Vector3.new(62, 9, 2),
		origin + Vector3.new(0, 7, -40),
		Color3.fromRGB(55, 32, 10),
		Enum.Material.Metal
	)
	label(board, "SORTOWNIA\nPodnieś element, a potem włóż go do właściwej kategorii.")

	for i, item in ipairs(cfg.items) do
		local x = ({ -27, -9, 9, 27 })[i]
		local obj = part(
			model,
			"SortItem" .. i,
			Vector3.new(11, 5, 7),
			origin + Vector3.new(x, 3, -20),
			accent,
			Enum.Material.Neon
		)
		label(obj, item[1], Enum.NormalId.Top)
		addHighlight(obj, accent)
		addBob(obj, 1.2, 1.5 + i * 0.1)
		prompt(obj, "Podnieś", item[1], function(p)
			if p ~= player or state.done or obj:GetAttribute("Sorted") then
				return
			end
			if state.carry then
				failFlash(player, remote, "Najpierw odłóż trzymany element.")
				return
			end
			state.carry = item
			state.source = obj
			obj.Transparency = 0.65
			successFlash(player, remote, "Trzymasz: " .. item[1] .. ". Znajdź właściwą kategorię.")
			setHud(player, remote, lesson.topic, "Przenieś " .. item[1] .. " do właściwej kategorii.", state.score)
		end)
	end

	local count = #cfg.bins
	for i, binName in ipairs(cfg.bins) do
		local x = (i - (count + 1) / 2) * 22
		local bin = part(
			model,
			"Bin" .. i,
			Vector3.new(18, 8, 12),
			origin + Vector3.new(x, 4, 6),
			Color3.fromRGB(60, 45, 25),
			Enum.Material.Metal
		)
		label(bin, binName, Enum.NormalId.Top)
		prompt(bin, "Odłóż", binName, function(p)
			if p ~= player or state.done then
				return
			end
			if not state.carry then
				failFlash(player, remote, "Najpierw podnieś element.")
				return
			end
			if state.carry[2] == binName then
				state.sorted += 1
				state.score += 40
				if state.source then
					state.source:SetAttribute("Sorted", true)
					state.source.Transparency = 1
					state.source.CanCollide = false
					local pr = state.source:FindFirstChildOfClass("ProximityPrompt")
					if pr then
						pr.Enabled = false
					end
				end
				successFlash(player, remote, "Dobrze: " .. state.carry[1] .. " → " .. binName)
				state.carry = nil
				state.source = nil
				if state.sorted == #cfg.items then
					state.done = true
					successFlash(player, remote, "Wszystko posegregowane. Wyjście aktywne!")
				end
			else
				state.score = math.max(0, state.score - 10)
				failFlash(player, remote, "Zła kategoria. Spróbuj ponownie.")
			end
			setHud(
				player,
				remote,
				lesson.topic,
				string.format("Posegregowano %d/%d", state.sorted, #cfg.items),
				state.score
			)
		end)
	end
end

local sequenceSets = {
	RobotSequence = {
		labels = { "PRZÓD", "PRAWO", "LEWO", "STOP" },
		order = { 1, 2, 1, 4 },
		instruction = "Zaprogramuj trasę: PRZÓD → PRAWO → PRZÓD → STOP",
	},
	robot = {
		labels = { "START", "PRZÓD", "SKRĘT", "STOP" },
		order = { 1, 2, 3, 4 },
		instruction = "Uruchom robota: START → PRZÓD → SKRĘT → STOP",
	},
	BlockProgram = {
		labels = { "START", "RUCH", "PĘTLA", "STOP" },
		order = { 1, 3, 2, 4 },
		instruction = "Ułóż program: START → PĘTLA → RUCH → STOP",
	},
	scratch_loop = {
		labels = { "START", "PĘTLA", "ZMIENNA", "META" },
		order = { 1, 2, 3, 4 },
		instruction = "Zbuduj logikę gry: START → PĘTLA → ZMIENNA → META",
	},
	scratch_media = {
		labels = { "TŁO", "DUSZEK", "DŹWIĘK", "START" },
		order = { 1, 2, 3, 4 },
		instruction = "Przygotuj scenę: TŁO → DUSZEK → DŹWIĘK → START",
	},
	scratch_events = {
		labels = { "FLAGA", "ZDARZENIE", "AKCJA", "EFEKT" },
		order = { 1, 2, 3, 4 },
		instruction = "Połącz zdarzenia: FLAGA → ZDARZENIE → AKCJA → EFEKT",
	},
	scratch_project = {
		labels = { "POMYSŁ", "SKRYPT", "TEST", "POPRAWKA" },
		order = { 1, 2, 3, 4 },
		instruction = "Dokończ projekt: POMYSŁ → SKRYPT → TEST → POPRAWKA",
	},
	AlgorithmPath = {
		labels = { "DANE", "WARUNEK", "DZIAŁANIE", "WYNIK" },
		order = { 1, 2, 3, 4 },
		instruction = "Ułóż algorytm: DANE → WARUNEK → DZIAŁANIE → WYNIK",
	},
	problem_solving = {
		labels = { "PROBLEM", "DANE", "PLAN", "TEST" },
		order = { 1, 2, 3, 4 },
		instruction = "Rozwiąż problem: PROBLEM → DANE → PLAN → TEST",
	},
	javablock = {
		labels = { "START", "WARUNEK", "KROK", "STOP" },
		order = { 1, 2, 3, 4 },
		instruction = "Odtwórz algorytm w JavaBlock.",
	},
	pseudocode = {
		labels = { "WEJŚCIE", "JEŻELI", "WYKONAJ", "WYJŚCIE" },
		order = { 1, 2, 3, 4 },
		instruction = "Przejdź od bloków do pseudokodu.",
	},
	natural_numbers = {
		labels = { "LICZBA", "DZIELNIK", "TEST", "WYNIK" },
		order = { 1, 2, 3, 4 },
		instruction = "Przetwórz liczbę naturalną krok po kroku.",
	},
	search_algorithm = {
		labels = { "START", "PORÓWNAJ", "DALEJ", "ZNALEZIONO" },
		order = { 1, 2, 3, 4 },
		instruction = "Uruchom algorytm wyszukiwania.",
	},
	sorting = {
		labels = { "PORÓWNAJ", "ZAMIEŃ", "POWTÓRZ", "GOTOWE" },
		order = { 1, 2, 3, 4 },
		instruction = "Posortuj ciąg krokami algorytmu.",
	},
	conditions = {
		labels = { "DANE", "WARUNEK", "TAK/NIE", "WYNIK" },
		order = { 1, 2, 3, 4 },
		instruction = "Zbuduj warunek w Pythonie.",
	},
	iterations = {
		labels = { "START", "WARUNEK", "CIAŁO PĘTLI", "POWRÓT" },
		order = { 1, 2, 3, 4 },
		instruction = "Zamknij poprawną pętlę.",
	},
	sequences = {
		labels = { "PIERWSZY", "REGUŁA", "NASTĘPNY", "WYNIK" },
		order = { 1, 2, 3, 4 },
		instruction = "Wygeneruj kolejne wyrazy ciągu.",
	},
	linear_sort = {
		labels = { "POBIERZ", "PORÓWNAJ", "WSTAW", "DALEJ" },
		order = { 1, 2, 3, 4 },
		instruction = "Ułóż liniowe porządkowanie.",
	},
	text_algorithms = {
		labels = { "TEKST", "ZNAK", "PORÓWNAJ", "WYNIK" },
		order = { 1, 2, 3, 4 },
		instruction = "Przejdź prosty algorytm tekstowy.",
	},
}

local function sequenceGame(model, origin, player, lesson, mission, remote, state, accent)
	local cfg = sequenceSets[mission.variant] or sequenceSets[mission.type] or sequenceSets.AlgorithmPath
	state.step = 1

	local board = part(
		model,
		"SequenceBoard",
		Vector3.new(62, 8, 2),
		origin + Vector3.new(0, 7, -40),
		Color3.fromRGB(15, 55, 35),
		Enum.Material.Metal
	)
	label(board, cfg.instruction)

	for i = 1, 4 do
		local x = (i - 2.5) * 16
		local pad = part(
			model,
			"Sequence" .. i,
			Vector3.new(12, 2, 12),
			origin + Vector3.new(x, 1, -12),
			accent,
			Enum.Material.Neon
		)
		label(pad, cfg.labels[i], Enum.NormalId.Top)
		addHighlight(pad, accent)
		prompt(pad, "Aktywuj", cfg.labels[i], function(p)
			if p ~= player or state.done then
				return
			end
			local expected = cfg.order[state.step]
			if i == expected then
				state.step += 1
				state.score += 30
				pad.Color = Color3.fromRGB(45, 220, 90)
				successFlash(player, remote, "Poprawny krok: " .. cfg.labels[i])
				if state.step > #cfg.order then
					state.done = true
					successFlash(player, remote, "Sekwencja działa! Wyjście aktywne.")
				end
			else
				state.step = 1
				state.score = math.max(0, state.score - 10)
				failFlash(player, remote, "Błędna kolejność — zacznij sekwencję od początku.")
				for _, obj in ipairs(model:GetChildren()) do
					if string.match(obj.Name, "^Sequence%d+$") then
						obj.Color = accent
					end
				end
			end
			local obj = state.done and "Sekwencja gotowa. Do wyjścia!" or ("Krok " .. state.step .. "/" .. #cfg.order)
			setHud(player, remote, lesson.topic, obj, state.score)
		end)
	end
end
local buildSets = {
	HardwareBuild = { "CPU", "RAM", "DYSK", "PŁYTA GŁÓWNA" },
	devices = { "CZUJNIK", "STEROWNIK", "EKRAN", "PAMIĘĆ" },
	NetworkBuilder = { "ROUTER", "SWITCH", "SERWER", "KLIENT" },
	internet = { "MODEM", "ROUTER", "DNS", "SERWER WWW" },
	network_services = { "DNS", "HTTP", "POCZTA", "CHMURA" },
	WebBuilder = { "HTML", "HEAD", "BODY", "LINK" },
	html = { "<html>", "<head>", "<body>", "<a>" },
	website = { "NAGŁÓWEK", "NAWIGACJA", "TREŚĆ", "STOPKA" },
	StyleLab = { "SELEKTOR", "KOLOR", "MARGINES", "CZCIONKA" },
	css = { "SELEKTOR", "COLOR", "PADDING", "FONT" },
	DatabaseMission = { "TABELA", "KLUCZ", "RELACJA", "KWERENDA" },
	ThreeDLab = { "BRYŁA", "MATERIAŁ", "ŚWIATŁO", "KAMERA" },
}

local function buildGame(model, origin, player, lesson, mission, remote, state, accent)
	local names = buildSets[mission.variant]
		or buildSets[mission.type]
		or { "MODUŁ A", "MODUŁ B", "MODUŁ C", "MODUŁ D" }
	state.nodes = 0

	local board = part(
		model,
		"BuildBoard",
		Vector3.new(62, 8, 2),
		origin + Vector3.new(0, 7, -40),
		Color3.fromRGB(22, 28, 65),
		Enum.Material.Metal
	)
	label(board, "URUCHOM SYSTEM\nAktywuj wszystkie wymagane elementy.")

	for i = 1, 4 do
		local x = ({ -27, -9, 9, 27 })[i]
		local node = part(
			model,
			"Node" .. i,
			Vector3.new(10, 8, 10),
			origin + Vector3.new(x, 4, -12),
			Color3.fromRGB(45, 55, 70),
			Enum.Material.Metal
		)
		label(node, names[i])
		addHighlight(node, accent)
		prompt(node, "Aktywuj", names[i], function(p)
			if p ~= player or node:GetAttribute("On") then
				return
			end
			node:SetAttribute("On", true)
			node.Color = accent
			node.Material = Enum.Material.Neon
			state.nodes += 1
			state.score += 25
			successFlash(player, remote, names[i] .. " działa.")
			if state.nodes == 4 then
				state.done = true
				successFlash(player, remote, "System uruchomiony! Przejdź do wyjścia.")
			end
			setHud(player, remote, lesson.topic, string.format("Aktywne elementy %d/4", state.nodes), state.score)
		end)
	end
end

local function vaultGame(model, origin, player, lesson, mission, remote, state, accent)
	local q = getQuestion(mission)
	local vault = part(
		model,
		"Vault",
		Vector3.new(28, 18, 8),
		origin + Vector3.new(0, 9, -15),
		Color3.fromRGB(65, 55, 45),
		Enum.Material.DiamondPlate
	)
	label(vault, "CYFROWY SEJF\n" .. q[1])
	for i, answer in ipairs(q[2]) do
		local key = part(
			model,
			"Key" .. i,
			Vector3.new(12, 4, 8),
			origin + Vector3.new((i - 2) * 17, 3, 1),
			accent,
			Enum.Material.Neon
		)
		label(key, answer, Enum.NormalId.Top)
		addHighlight(key, accent)
		addBob(key, 0.8, 1.8 + i * 0.1)
		prompt(key, "Wprowadź", "Kod " .. i, function(p)
			if p ~= player or state.done then
				return
			end
			if i == q[3] then
				state.score += 120
				state.done = true
				vault.Color = Color3.fromRGB(45, 220, 90)
				successFlash(player, remote, "Sejf otwarty! Zdobądź wyjście.")
			else
				state.score = math.max(0, state.score - 15)
				failFlash(player, remote, "Błędny kod.")
			end
			setHud(
				player,
				remote,
				lesson.topic,
				state.done and "Sejf otwarty — do wyjścia." or "Otwórz cyfrowy sejf.",
				state.score
			)
		end)
	end
end
local function huntGame(model, origin, player, lesson, mission, remote, state, accent)
	state.collected = 0
	for i = 1, 5 do
		local x = ((i % 2) == 0) and 27 or -27
		local z = -42 + i * 25
		local shard =
			part(model, "Shard" .. i, Vector3.new(4, 9, 4), origin + Vector3.new(x, 5, z), accent, Enum.Material.Neon)
		prompt(shard, "Przejmij", "Fragment wiedzy", function(p)
			if p ~= player or shard:GetAttribute("Taken") then
				return
			end
			shard:SetAttribute("Taken", true)
			shard.Transparency = 1
			shard.CanCollide = false
			local pr = shard:FindFirstChildOfClass("ProximityPrompt")
			if pr then
				pr.Enabled = false
			end
			state.collected += 1
			state.score += 20
			if state.collected == 5 then
				state.done = true
				successFlash(player, remote, "Wszystkie fragmenty zdobyte!")
			end
			setHud(player, remote, lesson.topic, string.format("Fragmenty %d/5", state.collected), state.score)
		end)
	end
end

local PYTHON_GRID = 6
local PYTHON_STEP = 8
local PYTHON_CHIP = Vector2.new(2, 2)
local PYTHON_SERVER = Vector2.new(4, 4)

local function pythonRemote(name)
	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	return remotes and remotes:FindFirstChild(name) or nil
end

local function pythonWorldPosition(session, x, y)
	return session.gridOrigin + Vector3.new(x * PYTHON_STEP, 3.5, y * PYTHON_STEP)
end

local function pythonFacingCFrame(session)
	local looks = {
		Vector3.new(1, 0, 0),
		Vector3.new(0, 0, 1),
		Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, -1),
	}
	local pos = pythonWorldPosition(session, session.x, session.y)
	return CFrame.lookAt(pos, pos + looks[session.dir + 1])
end

local function resetPythonState(session)
	session.x = 0
	session.y = 0
	session.dir = 0
	session.carrying = false
	session.busy = false

	if session.robot and session.robot.Parent then
		session.robot.CFrame = pythonFacingCFrame(session)
	end
	if session.chip and session.chip.Parent then
		session.chip.Transparency = session.power and 1 or 0
		session.chip.CanCollide = false
		session.chip.Position = pythonWorldPosition(session, PYTHON_CHIP.X, PYTHON_CHIP.Y) + Vector3.new(0, 1.6, 0)
	end
	if session.carryLight and session.carryLight.Parent then
		session.carryLight.Enabled = false
	end
	if session.dock then
		PythonRobotDock.Reset(session.dock)
	end
	if session.maze then
		PythonRobotMaze.Reset(session.maze)
	end
	if session.power then
		PythonPowerPlant.Reset(session.power)
	end
end

local pythonVariantInfo = {
	python_robot_intro_sp7 = {
		challenge = "Pierwszy prawdziwy program: odbierz CHIP z (2,2), dowieź go na SERWER (4,4) i użyj drop(). Obserwuj, jak każda linia kodu zmienia dok.",
		starter = "# Komendy: move(n), turn_left(), turn_right(), pickup(), drop()\n# BOT startuje na (0,0) i patrzy w prawo.\n",
	},
	python_robot_maze_sp8 = {
		challenge = "Przejedź przez SENSOR (0,2), odbierz CHIP (2,2), omiń lasery i dostarcz go do SERWERA (4,4).",
		starter = "# move(n), turn_left(), turn_right(), pickup(), drop()\n# Najpierw SENSOR (0,2). Lasery blokują: (1,0), (1,1), (3,2), (3,3).\n",
	},
	python_robot_intro = {
		challenge = "Odbierz CHIP z (2,2), dowieź go na SERWER (4,4) i wykonaj drop().",
		starter = "# Dostępne: move(n), turn_left(), turn_right(), pickup(), drop()\n",
	},
	python_world_control_sp8 = {
		challenge = "Uruchom elektrownię w kolejności POMPA (0,2) → FAN (2,2) → MOST (2,4) → RDZEŃ (4,4). Użyj pętli for ... in range(...).",
		starter = "# Użyj move(n), turn_left(), turn_right() oraz co najmniej jednej pętli.\n# POMPA (0,2) → FAN (2,2) → MOST (2,4) → RDZEŃ (4,4).\n",
		requireLoop = true,
	},
	python_robot_program = {
		challenge = "Napisz cały program robota od startu do dostarczenia CHIP-u. Spróbuj zrobić to bez ręcznego sterowania.",
		starter = "# Robot startuje na (0,0) i patrzy w prawo.\n# CHIP: (2,2), SERWER: (4,4)\n",
	},
	python_variables = {
		challenge = "Użyj co najmniej jednej zmiennej, np. kroki = 2, a potem steruj robotem przez move(kroki).",
		starter = "kroki = 2\n# użyj zmiennej kroki w swoim programie\n",
		requireVariable = true,
	},
	python_loop = {
		challenge = "Użyj pętli for ... in range(...), aby co najmniej jeden odcinek trasy wykonać w pętli.",
		starter = "for i in range(2):\n    move(1)\n# dopisz resztę programu\n",
		requireLoop = true,
	},
}

local function pythonGame(model, origin, player, lesson, mission, remote, state, accent)
	local consoleRemote = pythonRemote("PythonConsole")
	local gridOrigin = origin + Vector3.new(-20, 0, -30)
	local variantInfo = pythonVariantInfo[mission.variant] or pythonVariantInfo.python_robot_intro

	if mission.variant == "python_robot_intro" then
		local commandYard =
			CommandYard.Build(model, origin, player, lesson, mission, remote, state, accent, consoleRemote)
		pythonSessions[player] = {
			player = player,
			model = model,
			state = state,
			remote = remote,
			mission = mission,
			lesson = lesson,
			accent = accent,
			commandYard = commandYard,
			busy = false,
		}
		return
	end

	if mission.variant == "python_loop" then
		local loopFactory =
			LoopFactory.Build(model, origin, player, lesson, mission, remote, state, accent, consoleRemote)
		pythonSessions[player] = {
			player = player,
			model = model,
			state = state,
			remote = remote,
			mission = mission,
			lesson = lesson,
			accent = accent,
			loopFactory = loopFactory,
			busy = false,
		}
		return
	end

	if mission.variant == "python_variables" then
		local parameterLab =
			ParameterLab.Build(model, origin, player, lesson, mission, remote, state, accent, consoleRemote)
		pythonSessions[player] = {
			player = player,
			model = model,
			state = state,
			remote = remote,
			mission = mission,
			lesson = lesson,
			accent = accent,
			parameterLab = parameterLab,
			busy = false,
		}
		return
	end

	if mission.variant == "strings" then
		local messageLab =
			MessageLab.Build(model, origin, player, lesson, mission, remote, state, accent, consoleRemote)
		pythonSessions[player] = {
			player = player,
			model = model,
			state = state,
			remote = remote,
			mission = mission,
			lesson = lesson,
			accent = accent,
			messageLab = messageLab,
			busy = false,
		}
		return
	end

	local board = part(
		model,
		"PythonBoard",
		Vector3.new(58, 14, 2),
		origin + Vector3.new(0, 9, -42),
		Color3.fromRGB(12, 20, 34),
		Enum.Material.Metal
	)
	local boardTitle = "PYTHON LAB\nNapisz program → uruchom robota\nCHIP: (2,2)   SERWER: (4,4)"
	if mission.variant == "python_robot_intro_sp7" then
		boardTitle = "PYTHON ROBOT DOCK\nWpisz kod → obserwuj ruch → debuguj\nCHIP: (2,2)   SERWER: (4,4)"
	elseif mission.variant == "python_robot_maze_sp8" then
		boardTitle = "PYTHON ROBOT MAZE\nSENSOR (0,2) → CHIP (2,2) → SERWER (4,4)\nOMIJAJ LASERY"
	elseif mission.variant == "python_world_control_sp8" then
		boardTitle = "PYTHON POWER PLANT\nPOMPA → FAN → MOST → RDZEŃ\nKOD STERUJE MASZYNAMI"
	end
	label(board, boardTitle, Enum.NormalId.Front)
	addHighlight(board, accent)

	for x = 0, PYTHON_GRID - 1 do
		for y = 0, PYTHON_GRID - 1 do
			local usesCargoGoal = mission.variant ~= "python_world_control_sp8"
			local isChip = usesCargoGoal and x == PYTHON_CHIP.X and y == PYTHON_CHIP.Y
			local isServer = usesCargoGoal and x == PYTHON_SERVER.X and y == PYTHON_SERVER.Y
			local tileColor = Color3.fromRGB(30, 42, 60)
			if isChip then
				tileColor = Color3.fromRGB(255, 185, 55)
			elseif isServer then
				tileColor = Color3.fromRGB(60, 210, 125)
			elseif (x + y) % 2 == 0 then
				tileColor = Color3.fromRGB(38, 52, 72)
			end

			local tile = part(
				model,
				string.format("PyTile_%d_%d", x, y),
				Vector3.new(7.2, 0.8, 7.2),
				gridOrigin + Vector3.new(x * PYTHON_STEP, 0.4, y * PYTHON_STEP),
				tileColor,
				Enum.Material.SmoothPlastic
			)
			label(tile, string.format("(%d,%d)", x, y), Enum.NormalId.Top)
		end
	end

	local chip = part(
		model,
		"DataChip",
		Vector3.new(3.2, 3.2, 3.2),
		pythonWorldPosition({ gridOrigin = gridOrigin }, PYTHON_CHIP.X, PYTHON_CHIP.Y) + Vector3.new(0, 1.6, 0),
		Color3.fromRGB(255, 200, 65),
		Enum.Material.Neon
	)
	chip.Shape = Enum.PartType.Ball
	chip.CanCollide = false
	addHighlight(chip, Color3.fromRGB(255, 210, 80))
	addBob(chip, 0.8, 1.3)

	local serverPad = part(
		model,
		"PythonServer",
		Vector3.new(7, 5, 7),
		gridOrigin + Vector3.new(PYTHON_SERVER.X * PYTHON_STEP, 2.5, PYTHON_SERVER.Y * PYTHON_STEP),
		Color3.fromRGB(45, 185, 105),
		Enum.Material.Neon
	)
	label(serverPad, "SERWER\nDROP HERE")
	addHighlight(serverPad, Color3.fromRGB(80, 255, 150))
	if mission.variant == "python_world_control_sp8" then
		chip.Transparency = 1
		for _, child in ipairs(chip:GetChildren()) do
			if child:IsA("Highlight") then
				child.Enabled = false
			end
		end
		serverPad.Transparency = 1
		for _, child in ipairs(serverPad:GetChildren()) do
			if child:IsA("SurfaceGui") then
				child.Enabled = false
			elseif child:IsA("Highlight") then
				child.Enabled = false
			end
		end
	end

	local robot = part(
		model,
		"PythonRobot",
		Vector3.new(5.5, 4.5, 5.5),
		gridOrigin + Vector3.new(0, 3.5, 0),
		Color3.fromRGB(55, 150, 255),
		Enum.Material.Metal
	)
	label(robot, "BOT", Enum.NormalId.Top)
	addHighlight(robot, accent)

	local arrow = Instance.new("Part")
	arrow.Name = "RobotFront"
	arrow.Size = Vector3.new(1.2, 1.2, 2.2)
	arrow.Color = Color3.fromRGB(255, 245, 120)
	arrow.Material = Enum.Material.Neon
	arrow.CanCollide = false
	arrow.Massless = true
	arrow.CFrame = robot.CFrame * CFrame.new(0, 0.4, -3.5)
	arrow.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = robot
	weld.Part1 = arrow
	weld.Parent = arrow

	local carryLight = Instance.new("PointLight")
	carryLight.Color = Color3.fromRGB(255, 210, 70)
	carryLight.Brightness = 3
	carryLight.Range = 14
	carryLight.Enabled = false
	carryLight.Parent = robot

	local dock = nil
	local maze = nil
	local power = nil
	if mission.variant == "python_robot_intro_sp7" then
		dock = PythonRobotDock.Build(model, origin, gridOrigin, PYTHON_GRID, PYTHON_STEP, robot)
	elseif mission.variant == "python_robot_maze_sp8" then
		maze = PythonRobotMaze.Build(model, origin, gridOrigin, PYTHON_GRID, PYTHON_STEP, robot)
	elseif mission.variant == "python_world_control_sp8" then
		power = PythonPowerPlant.Build(model, origin, gridOrigin, PYTHON_GRID, PYTHON_STEP, robot)
	end

	local session = {
		player = player,
		model = model,
		state = state,
		remote = remote,
		mission = mission,
		lesson = lesson,
		accent = accent,
		gridOrigin = gridOrigin,
		robot = robot,
		chip = chip,
		carryLight = carryLight,
		dock = dock,
		maze = maze,
		power = power,
		x = 0,
		y = 0,
		dir = 0,
		carrying = false,
		busy = false,
	}
	pythonSessions[player] = session
	resetPythonState(session)

	if consoleRemote then
		consoleRemote:FireClient(player, {
			kind = "open",
			title = "PYTHON LAB • " .. (mission.name or lesson.topic),
			challenge = variantInfo.challenge .. " Każde move(1) to jedno pole.",
			starter = variantInfo.starter,
			output = "Robot startuje na (0,0), patrzy w prawo. Napisz program i kliknij URUCHOM KOD.",
		})
	end

	local pythonObjective = "ETAP 1/3 • Zaprogramuj robota: CHIP (2,2) → SERWER (4,4)."
	if mission.variant == "python_world_control_sp8" then
		pythonObjective = "ETAP 1/3 • Użyj pętli i uruchom: POMPA → FAN → MOST → RDZEŃ."
	end
	setHud(player, remote, mission.name or lesson.topic, pythonObjective, state.score, 180)
end

local function pythonTurn(session, delta)
	session.dir = (session.dir + delta) % 4
	local tween = TweenService:Create(
		session.robot,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = pythonFacingCFrame(session) }
	)
	tween:Play()
	tween.Completed:Wait()
	if session.dock then
		PythonRobotDock.Command(
			session.dock,
			delta < 0 and "turn_left()\nROBOT OBRÓCIŁ SIĘ W LEWO" or "turn_right()\nROBOT OBRÓCIŁ SIĘ W PRAWO"
		)
	end
	if session.maze then
		PythonRobotMaze.Command(
			session.maze,
			delta < 0 and "turn_left()\nBOT SKRĘCA W LEWO" or "turn_right()\nBOT SKRĘCA W PRAWO"
		)
	end
	if session.power then
		PythonPowerPlant.Command(
			session.power,
			delta < 0 and "turn_left()\nBOT ZMIENIA KIERUNEK" or "turn_right()\nBOT ZMIENIA KIERUNEK"
		)
	end
end

local function pythonMove(session, count)
	local dirs = {
		Vector2.new(1, 0),
		Vector2.new(0, 1),
		Vector2.new(-1, 0),
		Vector2.new(0, -1),
	}
	local dir = dirs[session.dir + 1]

	for _ = 1, count do
		local nx = session.x + dir.X
		local ny = session.y + dir.Y
		if nx < 0 or nx >= PYTHON_GRID or ny < 0 or ny >= PYTHON_GRID then
			return false, string.format("Robot uderzył w granicę planszy przy (%d,%d).", nx, ny)
		end
		if session.maze then
			local allowed, reason = PythonRobotMaze.CanEnter(session.maze, nx, ny)
			if not allowed then
				return false, string.format("Robot nie może wejść na (%d,%d): %s.", nx, ny, reason)
			end
		end

		session.x = nx
		session.y = ny
		local tween = TweenService:Create(
			session.robot,
			TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ CFrame = pythonFacingCFrame(session) }
		)
		tween:Play()
		tween.Completed:Wait()
		if session.dock then
			PythonRobotDock.Step(session.dock, session.x, session.y)
		end
		if session.maze then
			PythonRobotMaze.Step(session.maze, session.x, session.y)
		end
		if session.power then
			local stepOk, stepReason, completed = PythonPowerPlant.Step(session.power, session.x, session.y)
			if not stepOk then
				return false, stepReason
			end
			if completed and not session.state.done then
				session.state.done = true
				session.state.score += 160
				successFlash(
					session.player,
					session.remote,
					"Program uruchomił wszystkie systemy elektrowni. Kod naprawdę zmienił świat."
				)
				setHud(
					session.player,
					session.remote,
					session.mission.name or session.lesson.topic,
					"ETAP 2/3 • Elektrownia online. Przejdź do świecącego rdzenia misji.",
					session.state.score
				)
			end
		end
	end

	return true
end

function MissionEngine.ResetPython(player, consoleRemote)
	local session = pythonSessions[player]
	if not session or not session.model or not session.model.Parent then
		if consoleRemote then
			consoleRemote:FireClient(
				player,
				{ kind = "output", text = "Nie ma aktywnej misji Python Lab.", good = false }
			)
		end
		return
	end
	if session.busy then
		if consoleRemote then
			consoleRemote:FireClient(
				player,
				{ kind = "output", text = "Poczekaj, aż bieżący program się zakończy.", good = false }
			)
		end
		return
	end

	if session.commandYard then
		session.busy = false
		CommandYard.Reset(session.commandYard)
		return
	end

	if session.loopFactory then
		session.busy = false
		LoopFactory.Reset(session.loopFactory, consoleRemote)
		return
	end

	if session.parameterLab then
		session.busy = false
		ParameterLab.Reset(session.parameterLab)
		return
	end

	if session.messageLab then
		session.busy = false
		MessageLab.Reset(session.messageLab)
		return
	end

	resetPythonState(session)
	if consoleRemote then
		consoleRemote:FireClient(player, {
			kind = "output",
			text = "Robot zresetowany: pozycja (0,0), kierunek →, CHIP wrócił na (2,2).",
			good = true,
		})
	end
end

function MissionEngine.ExecutePython(player, source, consoleRemote, missionRemote)
	local session = pythonSessions[player]
	if not session or not session.model or not session.model.Parent then
		consoleRemote:FireClient(
			player,
			{ kind = "output", text = "Najpierw uruchom planszę Python Lab.", good = false }
		)
		return
	end
	if session.busy then
		consoleRemote:FireClient(player, { kind = "output", text = "Program już się wykonuje.", good = false })
		return
	end

	if session.commandYard then
		session.busy = true
		local ok, err = pcall(CommandYard.Execute, session.commandYard, source)
		session.busy = false
		if not ok then
			consoleRemote:FireClient(player, {
				kind = "output",
				text = "Błąd Command Yard: " .. tostring(err),
				good = false,
			})
		end
		return
	end

	if session.loopFactory then
		session.busy = true
		local ok, err = pcall(LoopFactory.Execute, session.loopFactory, source, consoleRemote)
		session.busy = false
		if not ok then
			consoleRemote:FireClient(player, {
				kind = "output",
				text = "Błąd Loop Factory: " .. tostring(err),
				good = false,
			})
		end
		return
	end

	if session.parameterLab then
		session.busy = true
		local ok, err = pcall(ParameterLab.Execute, session.parameterLab, source)
		session.busy = false
		if not ok then
			consoleRemote:FireClient(player, {
				kind = "output",
				text = "Błąd Parameter Lab: " .. tostring(err),
				good = false,
			})
		end
		return
	end

	if session.messageLab then
		session.busy = true
		local ok, err = pcall(MessageLab.Execute, session.messageLab, source)
		session.busy = false
		if not ok then
			consoleRemote:FireClient(player, {
				kind = "output",
				text = "Błąd Message Lab: " .. tostring(err),
				good = false,
			})
		end
		return
	end

	local variantInfo = pythonVariantInfo[session.mission.variant] or pythonVariantInfo.python_robot_intro
	if variantInfo.requireVariable and not source:match("[%a_][%w_]*%s*=%s*%-?%d+") then
		consoleRemote:FireClient(player, {
			kind = "output",
			text = "Ta misja wymaga użycia zmiennej, np. kroki = 2 i później move(kroki).",
			good = false,
		})
		return
	end
	if variantInfo.requireLoop and not source:match("for%s+[%a_][%w_]*%s+in%s+range%s*%(") then
		consoleRemote:FireClient(player, {
			kind = "output",
			text = "Ta misja wymaga użycia pętli: for ... in range(...):",
			good = false,
		})
		return
	end

	local plan, parseError = PythonSubset.Parse(source)
	if not plan then
		if session.dock then
			PythonRobotDock.Fail(session.dock, "Błąd składni: " .. parseError)
		end
		if session.maze then
			PythonRobotMaze.Fail(session.maze, "Błąd składni: " .. parseError)
		end
		if session.power then
			PythonPowerPlant.Fail(session.power, "Błąd składni: " .. parseError)
		end
		consoleRemote:FireClient(player, { kind = "output", text = "Błąd składni: " .. parseError, good = false })
		return
	end

	session.busy = true
	resetPythonState(session)
	session.busy = true

	local outputLines = { string.format("Uruchamiam %d poleceń…", #plan) }
	local ok = true
	local runtimeError = nil

	for _, command in ipairs(plan) do
		if not session.model.Parent or active[player] ~= session.model then
			ok = false
			runtimeError = "Misja została zakończona."
			break
		end

		if command.op == "move" then
			local moved, err = pythonMove(session, command.value)
			if not moved then
				ok = false
				runtimeError = "Linia " .. tostring(command.line) .. ": " .. err
				break
			end
		elseif command.op == "turn_left" then
			pythonTurn(session, -1)
		elseif command.op == "turn_right" then
			pythonTurn(session, 1)
		elseif command.op == "pickup" then
			if session.power then
				ok = false
				runtimeError = "Linia "
					.. tostring(command.line)
					.. ": Power Plant używa ruchu po padach, bez pickup()."
				break
			elseif session.carrying then
				table.insert(outputLines, "pickup(): robot już niesie CHIP.")
			elseif session.x == PYTHON_CHIP.X and session.y == PYTHON_CHIP.Y then
				if session.maze then
					local pickupOk, pickupReason = PythonRobotMaze.CanPickup(session.maze, session.x, session.y)
					if not pickupOk then
						ok = false
						runtimeError = "Linia " .. tostring(command.line) .. ": " .. pickupReason
						break
					end
				end
				session.carrying = true
				session.chip.Transparency = 1
				session.carryLight.Enabled = true
				if session.dock then
					PythonRobotDock.Pickup(session.dock)
				end
				if session.maze then
					PythonRobotMaze.Pickup(session.maze)
				end
				table.insert(outputLines, "pickup(): CHIP zabrany.")
			else
				ok = false
				runtimeError = string.format(
					"Linia %d: pickup() działa tylko na polu CHIP (2,2), a robot jest na (%d,%d).",
					command.line,
					session.x,
					session.y
				)
				break
			end
		elseif command.op == "drop" then
			if session.power then
				ok = false
				runtimeError = "Linia "
					.. tostring(command.line)
					.. ": Power Plant kończy się na padzie RDZEŃ, bez drop()."
				break
			elseif not session.carrying then
				ok = false
				runtimeError = "Linia " .. tostring(command.line) .. ": robot nie ma CHIP-u."
				break
			elseif session.x == PYTHON_SERVER.X and session.y == PYTHON_SERVER.Y then
				session.carrying = false
				session.carryLight.Enabled = false
				session.state.done = true
				session.state.score += 160
				if session.dock then
					PythonRobotDock.Complete(session.dock)
				end
				if session.maze then
					PythonRobotMaze.Complete(session.maze)
				end
				table.insert(outputLines, "drop(): CHIP dostarczony do SERWERA!")
				successFlash(
					player,
					missionRemote,
					"Program działa! CHIP trafił do serwera. Teraz aktywuj rdzeń misji."
				)
				setHud(
					player,
					missionRemote,
					session.mission.name or session.lesson.topic,
					"ETAP 2/3 • Program zaliczony. Przejdź do świecącego rdzenia.",
					session.state.score
				)
			else
				ok = false
				runtimeError = string.format(
					"Linia %d: drop() musi zostać wykonane na SERWERZE (4,4), a robot jest na (%d,%d).",
					command.line,
					session.x,
					session.y
				)
				break
			end
		elseif command.op == "print" then
			table.insert(outputLines, tostring(command.value))
		end
	end

	session.busy = false

	if not ok then
		table.insert(outputLines, runtimeError)
		if session.dock then
			PythonRobotDock.Fail(session.dock, runtimeError)
		end
		if session.maze then
			PythonRobotMaze.Fail(session.maze, runtimeError)
		end
		if session.power then
			PythonPowerPlant.Fail(session.power, runtimeError)
		end
		consoleRemote:FireClient(player, {
			kind = "output",
			text = table.concat(outputLines, "\n"),
			good = false,
		})
		return
	end

	if session.state.done then
		table.insert(outputLines, string.format("SUKCES • robot kończy na (%d,%d).", session.x, session.y))
	else
		table.insert(
			outputLines,
			string.format(
				"Koniec programu • robot: (%d,%d). CHIP nie został jeszcze dostarczony.",
				session.x,
				session.y
			)
		)
	end
	consoleRemote:FireClient(player, {
		kind = "output",
		text = table.concat(outputLines, "\n"),
		good = session.state.done,
	})
end

function MissionEngine.HandlePosterInput(player, payload)
	return PaintStudioText.HandleInput(player, payload)
end

function MissionEngine.HandleTypingInput(player, payload)
	return TypingTerminalRun.HandleInput(player, payload)
end

function MissionEngine.Start(player, lesson, mission, remote)
	TypingTerminalRun.Stop(player)
	remote:FireClient(player, { kind = "typing_close" })
	if pythonSessions[player] then
		local consoleRemote = pythonRemote("PythonConsole")
		if consoleRemote then
			consoleRemote:FireClient(player, { kind = "close" })
		end
		pythonSessions[player] = nil
	end

	local model, origin, kind, dark, accent = baseArena(player, lesson, mission, remote)
	local initialObjective = "ETAP 1/3 • " .. mission.description
	local state = {
		score = 0,
		done = false,
		exitReady = false,
		completed = false,
		started = os.clock(),
		objective = initialObjective,
	}
	local cameraMode = mission.variant == "cloud" and "Cloud" or kind
	local startPosition = origin + Vector3.new(0, 4, -54)
	respawnState[player] = {
		model = model,
		position = startPosition,
		remote = remote,
		cameraMode = cameraMode,
		state = state,
		title = mission.name or lesson.topic,
	}
	bindRespawn(player)
	setHud(player, remote, mission.name or lesson.topic, initialObjective, 0, 180)
	remote:FireClient(player, { kind = "camera", mode = cameraMode })

	if mission.variant == "software" then
		SoftwareTower.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "files" then
		FileWarehouse.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "cloud" then
		CloudSyncStation.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "passwords" then
		CyberDefenseFortress.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "threats" then
		ThreatWaveSOC.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "devices" then
		InventorWorkshop.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "photo_edit_1" then
		PhotoLabOne.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "photo_edit_2" then
		PhotoRestorationLab.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "scratch_loop" then
		ScratchLoopGrid.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "scratch_media" then
		ScratchMiniStage.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "scratch_events" then
		ScratchEventCity.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "scratch_project" then
		ScratchGameJam.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "robot" then
		RobotRescue.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "pseudocode" then
		PseudocodeConveyor.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "charts" then
		DataCity.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "spreadsheet_use" then
		SpreadsheetFactory.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "natural_numbers" then
		NumberFoundry.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "search_algorithm" then
		SearchRace.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "sorting" then
		SortingArena.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "sports_media" then
		SportsNewsroom.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "languages" then
		LanguagePort.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "math_functions" then
		MathEngine.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "conditions" then
		DecisionDrone.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "logic" then
		LogicGateControl.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "sequences" then
		SequenceReactor.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "number_systems" then
		PositionalVault.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "conversion" then
		ConversionMachine.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "linear_sort" then
		RailSort.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "text_algorithms" then
		TextForensics.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "caesar" then
		CaesarCipherVault.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "mail_merge" then
		MailMergeFactory.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "data_import" then
		DataImportDock.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "slides_animation" then
		NatureAnimationLab.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "slides_sound" then
		ProjectionTunnel.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "javablock" then
		JavaBlockLine.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "data_representation" then
		DataDecoderChamber.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "chapter_finale" then
		ChapterFinale.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "sources" then
		NewsroomEvidence.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "paint_shapes" then
		PaintStudioShapes.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "paint_text" then
		PaintStudioText.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "paint_composition" then
		PaintStudioComposition.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "ai_paint_print" then
		AIPaintPrintLab.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "layered_graphics_text" then
		LayeredGraphicsTextLab.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "timeline" then
		TimelineMuseum.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "tech_history" then
		ChronoMuseum.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "digitization" then
		DecisionCity.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "os_troubleshooting" then
		PCEmergencyRoom.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "internet" then
		InternetConstruction.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "network_services" then
		NetworkServiceDistrict.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "html" then
		HTMLConstructionStudio.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "css" then
		CSSStyleStudio.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "website" then
		WebsiteLaunchStudio.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "cyber" then
		RouterDefense.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "search" then
		SearchEscape.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "research" then
		InternetDetective.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "problem_solving" then
		ProblemSolvingFactory.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "typing" then
		TypingTerminalRun.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "graphics_tricks" then
		IllusionStudio.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif mission.variant == "image_transform" then
		ImageTransformChamber.Run(model, origin, player, lesson, mission, remote, state, accent)
	elseif kind == "Decision" then
		decisionGame(model, origin, player, lesson, mission, remote, state, accent)
	elseif kind == "Sort" then
		sortGame(model, origin, player, lesson, mission, remote, state, accent)
	elseif kind == "Collect" then
		collectGame(model, origin, player, lesson, mission, remote, state, accent)
	elseif kind == "Sequence" then
		sequenceGame(model, origin, player, lesson, mission, remote, state, accent)
	elseif kind == "Build" then
		buildGame(model, origin, player, lesson, mission, remote, state, accent)
	elseif kind == "Vault" then
		vaultGame(model, origin, player, lesson, mission, remote, state, accent)
	elseif kind == "Python" then
		pythonGame(model, origin, player, lesson, mission, remote, state, accent)
	else
		huntGame(model, origin, player, lesson, mission, remote, state, accent)
	end
	addFinalCore(model, origin, player, remote, state, accent)
	finishGate(model, origin, player, remote, state)

	local startPad =
		part(model, "StartPad", Vector3.new(14, 1, 14), origin + Vector3.new(0, 1, -54), accent, Enum.Material.Neon)
	label(startPad, "START", Enum.NormalId.Top)
	task.delay(0.25, function()
		if player.Parent then
			teleport(player, startPosition)
			remote:FireClient(player, { kind = "camera", mode = cameraMode })
		end
	end)

	task.spawn(function()
		while player.Parent and active[player] == model and not state.completed and not state.done do
			task.wait(0.15)
		end
		if player.Parent and active[player] == model and state.done and not state.completed then
			successFlash(
				player,
				remote,
				"ETAP 1 UKOŃCZONY. Idź do dużego znacznika RDZEŃ MISJI na końcu planszy i naciśnij E."
			)
			setHud(
				player,
				remote,
				mission.name or lesson.topic,
				"ETAP 2/3 • Idź do oznaczonego RDZENIA MISJI na końcu planszy i naciśnij E.",
				state.score,
				nil
			)
		end
	end)

	task.spawn(function()
		local remaining = 180
		while remaining > 0 and player.Parent and active[player] == model and not state.completed do
			task.wait(1)
			remaining -= 1
			if remaining % 5 == 0 then
				local objective = state.done
						and (state.exitReady and "ETAP 3/3 • Idź do zielonego portalu WYJŚCIE i naciśnij E." or "ETAP 2/3 • Idź do oznaczonego RDZENIA MISJI na końcu planszy i naciśnij E.")
					or state.objective
				setHud(player, remote, mission.name or lesson.topic, objective, state.score, remaining)
			end
		end
		if remaining <= 0 and not state.completed and active[player] == model then
			failFlash(player, remote, "Czas minął — możesz próbować dalej, ale bez premii czasowej.")
		end
	end)
end

function MissionEngine.Stop(player)
	respawnState[player] = nil
	lastHudState[player] = nil
	local consoleRemote = pythonRemote("PythonConsole")
	if consoleRemote then
		consoleRemote:FireClient(player, { kind = "close" })
	end
	pythonSessions[player] = nil
	PaintStudioText.Stop(player)
	TypingTerminalRun.Stop(player)

	if active[player] then
		active[player]:Destroy()
		active[player] = nil
	end
end

Players.PlayerAdded:Connect(bindRespawn)
for _, player in ipairs(Players:GetPlayers()) do
	bindRespawn(player)
end

Players.PlayerRemoving:Connect(function(player)
	MissionEngine.Stop(player)
	if respawnConnections[player] then
		respawnConnections[player]:Disconnect()
		respawnConnections[player] = nil
	end
	slotByUser[player.UserId] = nil
end)

Lighting.Brightness = 2.1
Lighting.Ambient = Color3.fromRGB(92, 98, 112)
Lighting.OutdoorAmbient = Color3.fromRGB(58, 64, 78)
Lighting.ClockTime = 17.8

local bloom = Lighting:FindFirstChild("CER_Bloom") or Instance.new("BloomEffect")
bloom.Name = "CER_Bloom"
bloom.Intensity = 0.18
bloom.Size = 18
bloom.Threshold = 1.45
bloom.Parent = Lighting

local colorFx = Lighting:FindFirstChild("CER_Color") or Instance.new("ColorCorrectionEffect")
colorFx.Name = "CER_Color"
colorFx.Brightness = 0.02
colorFx.Contrast = 0.08
colorFx.Saturation = 0.07
colorFx.TintColor = Color3.fromRGB(238, 241, 248)
colorFx.Parent = Lighting

local atmosphere = Lighting:FindFirstChild("CER_Atmosphere") or Instance.new("Atmosphere")
atmosphere.Name = "CER_Atmosphere"
atmosphere.Density = 0.22
atmosphere.Offset = 0.05
atmosphere.Color = Color3.fromRGB(150, 175, 220)
atmosphere.Decay = Color3.fromRGB(45, 55, 90)
atmosphere.Glare = 0.12
atmosphere.Haze = 1.2
atmosphere.Parent = Lighting

return MissionEngine