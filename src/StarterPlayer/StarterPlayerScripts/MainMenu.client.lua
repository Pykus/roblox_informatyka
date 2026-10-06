local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Curriculum = require(Modules:WaitForChild("Curriculum"))
local MissionRules = require(Modules:WaitForChild("MissionRules"))
local PriorityMissions = require(Modules:WaitForChild("PriorityMissions"))
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local lessonSelected = remotes:WaitForChild("LessonSelected")
local missionInfo = remotes:WaitForChild("MissionInfo")
local posterCommand = remotes:WaitForChild("PosterCommand")

local grades = { "SP4", "SP5", "SP6", "SP7", "SP8", "LO1", "LO2", "LO3" }
local gradeColors = {
	SP4 = Color3.fromRGB(0, 170, 255),
	SP5 = Color3.fromRGB(0, 200, 160),
	SP6 = Color3.fromRGB(90, 200, 80),
	SP7 = Color3.fromRGB(230, 170, 45),
	SP8 = Color3.fromRGB(245, 100, 55),
	LO1 = Color3.fromRGB(210, 70, 150),
	LO2 = Color3.fromRGB(155, 75, 230),
	LO3 = Color3.fromRGB(85, 100, 245),
}
local missionColors = {
	SoftwareSort = Color3.fromRGB(255, 155, 55),
	FileSort = Color3.fromRGB(255, 190, 55),
	CloudAccess = Color3.fromRGB(70, 185, 255),
	CyberTerminal = Color3.fromRGB(255, 80, 95),
	CyberDefense = Color3.fromRGB(255, 70, 90),
	SourceCheck = Color3.fromRGB(255, 110, 170),
	EscapeMission = Color3.fromRGB(255, 95, 160),
	GraphicsLab = Color3.fromRGB(190, 85, 255),
	TechHistory = Color3.fromRGB(245, 175, 70),
	SearchMission = Color3.fromRGB(55, 205, 190),
	AlgorithmPath = Color3.fromRGB(65, 225, 135),
	TypingRush = Color3.fromRGB(105, 210, 255),
	HardwareBuild = Color3.fromRGB(65, 150, 255),
	BlockProgram = Color3.fromRGB(85, 230, 120),
	PresentationLab = Color3.fromRGB(185, 95, 255),
	BinaryVault = Color3.fromRGB(255, 185, 55),
	MixedChallenge = Color3.fromRGB(255, 115, 65),
	RobotSequence = Color3.fromRGB(75, 230, 160),
	CodeRepair = Color3.fromRGB(255, 200, 70),
	PythonLab = Color3.fromRGB(55, 165, 255),
	SpreadsheetLab = Color3.fromRGB(80, 205, 120),
	DataFactory = Color3.fromRGB(55, 210, 165),
	ProjectQuest = Color3.fromRGB(80, 175, 255),
	CipherVault = Color3.fromRGB(245, 145, 55),
	DocumentRepair = Color3.fromRGB(105, 155, 255),
	DigitalLaw = Color3.fromRGB(255, 105, 145),
	NetworkBuilder = Color3.fromRGB(65, 170, 255),
	WebBuilder = Color3.fromRGB(95, 140, 255),
	StyleLab = Color3.fromRGB(210, 90, 255),
}
local selectedGrade = nil
local selectedLessonIndex = nil

local gui = Instance.new("ScreenGui")
gui.Name = "CyberEscapeMenu"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromScale(0.9, 0.84)
main.Position = UDim2.fromScale(0.05, 0.08)
main.BackgroundColor3 = Color3.fromRGB(15, 22, 38)
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = main

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 28, 55)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 18, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 55, 70)),
})
mainGradient.Rotation = 18
mainGradient.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 55)
title.Position = UDim2.fromOffset(15, 10)
title.BackgroundTransparency = 1
title.Text = "CYBER ESCAPE ROOM"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Parent = main

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -30, 0, 30)
subtitle.Position = UDim2.fromOffset(15, 65)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Wybierz klasę, a potem konkretny temat z planu lekcji"
subtitle.TextColor3 = Color3.fromRGB(190, 200, 215)
subtitle.Font = Enum.Font.Gotham
subtitle.TextScaled = true
subtitle.Parent = main

local gradeBar = Instance.new("ScrollingFrame")
gradeBar.Size = UDim2.new(1, -30, 0, 50)
gradeBar.Position = UDim2.fromOffset(15, 105)
gradeBar.BackgroundTransparency = 1
gradeBar.BorderSizePixel = 0
gradeBar.AutomaticCanvasSize = Enum.AutomaticSize.X
gradeBar.CanvasSize = UDim2.new()
gradeBar.ScrollingDirection = Enum.ScrollingDirection.X
gradeBar.ScrollBarThickness = 4
gradeBar.ScrollBarImageColor3 = Color3.fromRGB(100, 145, 210)
gradeBar.Parent = main

local gradeLayout = Instance.new("UIListLayout")
gradeLayout.FillDirection = Enum.FillDirection.Horizontal
gradeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gradeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
gradeLayout.Padding = UDim.new(0, 8)
gradeLayout.Parent = gradeBar

local list = Instance.new("ScrollingFrame")
list.Name = "LessonList"
list.Size = UDim2.new(0.56, -20, 1, -180)
list.Position = UDim2.fromOffset(15, 165)
list.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
list.BorderSizePixel = 0
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ScrollBarThickness = 8
list.ScrollBarImageColor3 = Color3.fromRGB(110, 145, 210)
list.Parent = main

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 14)
listCorner.Parent = list
local listStroke = Instance.new("UIStroke")
listStroke.Color = Color3.fromRGB(80, 105, 155)
listStroke.Transparency = 0.35
listStroke.Thickness = 2
listStroke.Parent = list

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = list

local details = Instance.new("Frame")
details.Size = UDim2.new(0.44, -25, 1, -180)
details.Position = UDim2.new(0.56, 10, 0, 165)
details.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
details.BorderSizePixel = 0
details.Parent = main

local detailsCorner = Instance.new("UICorner")
detailsCorner.CornerRadius = UDim.new(0, 14)
detailsCorner.Parent = details
local detailsStroke = Instance.new("UIStroke")
detailsStroke.Color = Color3.fromRGB(105, 135, 205)
detailsStroke.Transparency = 0.25
detailsStroke.Thickness = 2
detailsStroke.Parent = details

local detailsTitle = Instance.new("TextLabel")
detailsTitle.Size = UDim2.new(1, -24, 0, 80)
detailsTitle.Position = UDim2.fromOffset(12, 12)
detailsTitle.BackgroundTransparency = 1
detailsTitle.Text = "Wybierz temat"
detailsTitle.TextColor3 = Color3.new(1, 1, 1)
detailsTitle.TextWrapped = true
detailsTitle.TextScaled = true
detailsTitle.Font = Enum.Font.GothamBold
detailsTitle.Parent = details

local detailsText = Instance.new("TextLabel")
detailsText.Size = UDim2.new(1, -24, 1, -170)
detailsText.Position = UDim2.fromOffset(12, 100)
detailsText.BackgroundTransparency = 1
detailsText.Text = ""
detailsText.TextColor3 = Color3.fromRGB(205, 215, 230)
detailsText.TextWrapped = true
detailsText.TextXAlignment = Enum.TextXAlignment.Left
detailsText.TextYAlignment = Enum.TextYAlignment.Top
detailsText.Font = Enum.Font.Gotham
detailsText.TextSize = 18
detailsText.Parent = details

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(1, -24, 0, 52)
startButton.Position = UDim2.new(0, 12, 1, -64)
startButton.BackgroundColor3 = Color3.fromRGB(45, 145, 75)
startButton.Text = "START MISJI"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.Font = Enum.Font.GothamBold
startButton.TextScaled = true
startButton.AutoButtonColor = true
startButton.Visible = false
startButton.Parent = details

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 14)
startCorner.Parent = startButton
local startStroke = Instance.new("UIStroke")
startStroke.Color = Color3.fromRGB(160, 255, 190)
startStroke.Transparency = 0.15
startStroke.Thickness = 2
startStroke.Parent = startButton
local startGradient = Instance.new("UIGradient")
startGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 210, 110)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 125, 210)),
})
startGradient.Parent = startButton

local notification = Instance.new("TextLabel")
notification.Name = "MissionNotification"
notification.Size = UDim2.new(0.72, 0, 0, 112)
notification.AnchorPoint = Vector2.new(0.5, 1)
notification.Position = UDim2.new(0.5, 0, 1, -20)
notification.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
notification.BackgroundTransparency = 0.04
notification.TextColor3 = Color3.new(1, 1, 1)
notification.TextWrapped = true
notification.Font = Enum.Font.GothamBold
notification.TextSize = 22
notification.Visible = false
notification.Parent = gui

local notificationConstraint = Instance.new("UITextSizeConstraint")
notificationConstraint.MinTextSize = 16
notificationConstraint.MaxTextSize = 22
notificationConstraint.Parent = notification

local posterModal = Instance.new("Frame")
posterModal.Name = "PosterEditor"
posterModal.AnchorPoint = Vector2.new(0.5, 0.5)
posterModal.Size = UDim2.fromOffset(470, 260)
posterModal.Position = UDim2.fromScale(0.5, 0.5)
posterModal.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
posterModal.BorderSizePixel = 0
posterModal.Visible = false
posterModal.ZIndex = 30
posterModal.Parent = gui

local posterCorner = Instance.new("UICorner")
posterCorner.CornerRadius = UDim.new(0, 18)
posterCorner.Parent = posterModal

local posterStroke = Instance.new("UIStroke")
posterStroke.Color = Color3.fromRGB(225, 80, 190)
posterStroke.Thickness = 3
posterStroke.Transparency = 0.15
posterStroke.Parent = posterModal

local posterEditorTitle = Instance.new("TextLabel")
posterEditorTitle.Size = UDim2.new(1, -30, 0, 52)
posterEditorTitle.Position = UDim2.fromOffset(15, 12)
posterEditorTitle.BackgroundTransparency = 1
posterEditorTitle.Text = "Edytor plakatu"
posterEditorTitle.TextColor3 = Color3.new(1, 1, 1)
posterEditorTitle.TextScaled = true
posterEditorTitle.Font = Enum.Font.GothamBold
posterEditorTitle.ZIndex = 31
posterEditorTitle.Parent = posterModal

local posterEditorHint = Instance.new("TextLabel")
posterEditorHint.Size = UDim2.new(1, -30, 0, 34)
posterEditorHint.Position = UDim2.fromOffset(15, 66)
posterEditorHint.BackgroundTransparency = 1
posterEditorHint.Text = ""
posterEditorHint.TextColor3 = Color3.fromRGB(185, 198, 220)
posterEditorHint.TextScaled = true
posterEditorHint.Font = Enum.Font.Gotham
posterEditorHint.ZIndex = 31
posterEditorHint.Parent = posterModal

local posterBox = Instance.new("TextBox")
posterBox.Size = UDim2.new(1, -40, 0, 58)
posterBox.Position = UDim2.fromOffset(20, 112)
posterBox.BackgroundColor3 = Color3.fromRGB(32, 42, 62)
posterBox.TextColor3 = Color3.new(1, 1, 1)
posterBox.PlaceholderColor3 = Color3.fromRGB(130, 145, 170)
posterBox.TextSize = 22
posterBox.Font = Enum.Font.GothamBold
posterBox.ClearTextOnFocus = false
posterBox.ZIndex = 31
posterBox.Parent = posterModal

local posterBoxCorner = Instance.new("UICorner")
posterBoxCorner.CornerRadius = UDim.new(0, 12)
posterBoxCorner.Parent = posterBox

local posterSubmit = Instance.new("TextButton")
posterSubmit.Size = UDim2.new(0.5, -25, 0, 52)
posterSubmit.Position = UDim2.fromOffset(20, 190)
posterSubmit.BackgroundColor3 = Color3.fromRGB(45, 195, 115)
posterSubmit.Text = "ZASTOSUJ"
posterSubmit.TextColor3 = Color3.new(1, 1, 1)
posterSubmit.TextScaled = true
posterSubmit.Font = Enum.Font.GothamBold
posterSubmit.ZIndex = 31
posterSubmit.Parent = posterModal

local posterCancel = Instance.new("TextButton")
posterCancel.Size = UDim2.new(0.5, -25, 0, 52)
posterCancel.Position = UDim2.new(0.5, 5, 0, 190)
posterCancel.BackgroundColor3 = Color3.fromRGB(75, 82, 100)
posterCancel.Text = "ANULUJ"
posterCancel.TextColor3 = Color3.new(1, 1, 1)
posterCancel.TextScaled = true
posterCancel.Font = Enum.Font.GothamBold
posterCancel.ZIndex = 31
posterCancel.Parent = posterModal

local posterField = nil

local function releaseFocusedTextBox()
	local focused = UserInputService:GetFocusedTextBox()
	if focused then
		focused:ReleaseFocus()
	end
end

local function closePosterEditor()
	posterBox:ReleaseFocus()
	posterModal.Visible = false
end

local function setMenuVisible(visible)
	releaseFocusedTextBox()
	if visible then
		closePosterEditor()
	end
	main.Visible = visible
	gui.DisplayOrder = visible and 100 or 20
end

posterSubmit.Activated:Connect(function()
	if not posterField then
		return
	end
	posterCommand:FireServer({ field = posterField, text = posterBox.Text })
	closePosterEditor()
end)
posterCancel.Activated:Connect(closePosterEditor)

local function clearLessonButtons()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function showLesson(grade, index, lesson)
	local mission = MissionRules.GetForLesson(lesson, grade)
	selectedGrade = grade

	if not mission.available then
		selectedLessonIndex = nil
		detailsTitle.Text = string.format("%s • %02d\nWKRÓTCE", grade, lesson.nr)
		detailsText.Text = lesson.topic
			.. "\n\nTa plansza jest jeszcze w przygotowaniu. Wybierz jeden z tematów oznaczonych jako dostępne."
		startButton.Visible = false
		detailsStroke.Color = Color3.fromRGB(95, 105, 125)
		return
	end

	selectedLessonIndex = index
	local stars = string.rep("★", mission.difficulty) .. string.rep("☆", math.max(0, 3 - mission.difficulty))
	local accent = missionColors[mission.type] or gradeColors[grade] or Color3.fromRGB(70, 160, 255)

	detailsStroke.Color = accent
	detailsTitle.Text = string.format("%s • %02d\n%s", grade, lesson.nr, mission.name)
	detailsText.Text = string.format(
		"%s\n\nCEL\n%s\n\nTRUDNOŚĆ  %s\n\n3 kroki: poznaj cel → wykonaj zadanie → dotrzyj do wyjścia.",
		lesson.topic,
		mission.description,
		stars
	)
	startButton.BackgroundColor3 = accent
	startButton.Visible = true
end

local function populateLessons(grade)
	clearLessonButtons()
	selectedGrade = grade
	selectedLessonIndex = nil
	startButton.Visible = false
	detailsTitle.Text = grade .. " — wybierz temat"
	detailsText.Text = "Lista pochodzi bezpośrednio z centralnego planu realizacji informatyki."

	local data = Curriculum[grade]
	if not data then
		return
	end

	for index, lesson in ipairs(data.lessons) do
		local mission = MissionRules.GetForLesson(lesson, grade)
		local available = PriorityMissions.IsAvailable(grade, lesson.nr)
		local b = Instance.new("TextButton")
		b.Name = string.format("Lesson_%02d", lesson.nr)
		b.Size = UDim2.new(1, -12, 0, available and 66 or 48)
		b.BackgroundColor3 = available
				and (missionColors[mission.type] or gradeColors[grade] or Color3.fromRGB(55, 85, 130))
			or Color3.fromRGB(44, 49, 60)
		b.BackgroundTransparency = available and 0.08 or 0.35
		b.TextColor3 = available and Color3.new(1, 1, 1) or Color3.fromRGB(145, 150, 165)
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.TextWrapped = true
		b.Font = available and Enum.Font.GothamBold or Enum.Font.Gotham
		b.TextSize = available and 16 or 14
		b.Text = available and string.format("  %02d.  %s\n       %s", lesson.nr, mission.name, lesson.topic)
			or string.format("  %02d.  WKRÓTCE — %s", lesson.nr, lesson.topic)
		b.AutoButtonColor = available
		b.Parent = list

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = b

		local stroke = Instance.new("UIStroke")
		stroke.Color = available and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(85, 90, 105)
		stroke.Transparency = available and 0.65 or 0.8
		stroke.Thickness = 1
		stroke.Parent = b

		b.Activated:Connect(function()
			showLesson(grade, index, lesson)
		end)
	end
end

for _, grade in ipairs(grades) do
	local b = Instance.new("TextButton")
	b.Name = "Grade_" .. grade
	b.Size = UDim2.fromOffset(82, 42)
	b.BackgroundColor3 = gradeColors[grade] or Color3.fromRGB(55, 70, 96)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	b.Text = grade
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.Parent = gradeBar
	b.Activated:Connect(function()
		populateLessons(grade)
	end)
end

startButton.Activated:Connect(function()
	if not selectedGrade or not selectedLessonIndex then
		return
	end
	releaseFocusedTextBox()
	lessonSelected:FireServer(selectedGrade, selectedLessonIndex)
	setMenuVisible(false)
	if openButton then
		openButton.Visible = true
	end
end)

local hud = Instance.new("Frame")
hud.Size = UDim2.new(0.46, 0, 0, 174)
hud.Position = UDim2.fromOffset(14, 14)
hud.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
hud.BackgroundTransparency = 0.04
hud.BorderSizePixel = 0
hud.Visible = false
hud.Parent = gui

local hudSize = Instance.new("UISizeConstraint")
hudSize.MinSize = Vector2.new(340, 164)
hudSize.MaxSize = Vector2.new(620, 184)
hudSize.Parent = hud

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 14)
hudCorner.Parent = hud

local hudStroke = Instance.new("UIStroke")
hudStroke.Color = Color3.fromRGB(90, 175, 255)
hudStroke.Transparency = 0.2
hudStroke.Thickness = 2
hudStroke.Parent = hud

local hudTitle = Instance.new("TextLabel")
hudTitle.Size = UDim2.new(1, -24, 0, 32)
hudTitle.Position = UDim2.fromOffset(12, 8)
hudTitle.BackgroundTransparency = 1
hudTitle.TextColor3 = Color3.new(1, 1, 1)
hudTitle.Font = Enum.Font.GothamBold
hudTitle.TextSize = 22
hudTitle.TextTruncate = Enum.TextTruncate.AtEnd
hudTitle.TextXAlignment = Enum.TextXAlignment.Left
hudTitle.Parent = hud

local hudObjective = Instance.new("TextLabel")
hudObjective.Size = UDim2.new(1, -24, 0, 76)
hudObjective.Position = UDim2.fromOffset(12, 42)
hudObjective.BackgroundTransparency = 1
hudObjective.TextColor3 = Color3.fromRGB(230, 238, 250)
hudObjective.TextWrapped = true
hudObjective.TextSize = 20
hudObjective.Font = Enum.Font.GothamMedium
hudObjective.TextXAlignment = Enum.TextXAlignment.Left
hudObjective.TextYAlignment = Enum.TextYAlignment.Top
hudObjective.Parent = hud

local hudObjectiveConstraint = Instance.new("UITextSizeConstraint")
hudObjectiveConstraint.MinTextSize = 16
hudObjectiveConstraint.MaxTextSize = 20
hudObjectiveConstraint.Parent = hudObjective

local hudScore = Instance.new("TextLabel")
hudScore.Size = UDim2.new(1, -24, 0, 22)
hudScore.Position = UDim2.fromOffset(12, 120)
hudScore.BackgroundTransparency = 1
hudScore.TextColor3 = Color3.fromRGB(110, 245, 155)
hudScore.Font = Enum.Font.GothamBold
hudScore.TextSize = 18
hudScore.TextXAlignment = Enum.TextXAlignment.Left
hudScore.Parent = hud

local hudControls = Instance.new("TextLabel")
hudControls.Size = UDim2.new(1, -24, 0, 22)
hudControls.Position = UDim2.fromOffset(12, 145)
hudControls.BackgroundTransparency = 1
hudControls.TextColor3 = Color3.fromRGB(165, 190, 220)
hudControls.Font = Enum.Font.Gotham
hudControls.TextSize = 16
hudControls.TextWrapped = true
hudControls.TextXAlignment = Enum.TextXAlignment.Left
hudControls.TextYAlignment = Enum.TextYAlignment.Top
hudControls.Text = UserInputService.TouchEnabled
		and "STEROWANIE: joystick • przeciągnij ekran = kamera • użyj przycisku interakcji"
	or "STEROWANIE: WASD/strzałki • mysz = kamera • E = interakcja"
hudControls.Parent = hud

local viewportConnection = nil
local openButton = nil

local function applyPlayabilityLayout()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1366, 768)
	local narrow = viewport.X < 720 or viewport.Y < 520
	local menuPortrait = viewport.X < 700 and viewport.Y >= viewport.X * 1.05
	local menuLow = viewport.Y < 520 and not menuPortrait
	local posterWidth = math.min(470, math.max(280, viewport.X - 24))
	posterModal.Size = UDim2.fromOffset(posterWidth, 260)

	if openButton then
		local compactControls = viewport.X < 720 or viewport.Y < 520
		if compactControls then
			local shortPortrait = menuPortrait and viewport.Y < 560
			local buttonTop = menuLow and 12 or (shortPortrait and 210 or 230)
			openButton.AnchorPoint = Vector2.new(1, 0)
			openButton.Size = UDim2.fromOffset(118, 42)
			openButton.Position = UDim2.new(1, -12, 0, buttonTop)
			openButton.Text = "LEKCJE"
		else
			openButton.AnchorPoint = Vector2.new(0, 1)
			openButton.Size = UDim2.fromOffset(190, 44)
			openButton.Position = UDim2.new(0, 14, 1, -14)
			openButton.Text = "WYBIERZ INNĄ LEKCJĘ"
		end
	end

	if menuPortrait then
		main.Size = UDim2.new(1, -16, 1, -16)
		main.Position = UDim2.fromOffset(8, 8)
		title.Size = UDim2.new(1, -24, 0, 42)
		title.Position = UDim2.fromOffset(12, 6)
		subtitle.Size = UDim2.new(1, -24, 0, 28)
		subtitle.Position = UDim2.fromOffset(12, 48)
		gradeBar.Size = UDim2.new(1, -24, 0, 50)
		gradeBar.Position = UDim2.fromOffset(12, 80)
		local contentHeight = math.max(260, viewport.Y - 166)
		local listHeight = math.floor(contentHeight * 0.44)
		list.Size = UDim2.new(1, -24, 0, listHeight)
		list.Position = UDim2.fromOffset(12, 138)
		details.Size = UDim2.new(1, -24, 0, contentHeight - listHeight - 10)
		details.Position = UDim2.fromOffset(12, 148 + listHeight)
		gradeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		gradeLayout.Padding = UDim.new(0, 6)
	elseif menuLow then
		main.Size = UDim2.new(0.96, 0, 0.94, 0)
		main.Position = UDim2.fromScale(0.02, 0.03)
		title.Size = UDim2.new(1, -24, 0, 38)
		title.Position = UDim2.fromOffset(12, 4)
		subtitle.Size = UDim2.new(1, -24, 0, 24)
		subtitle.Position = UDim2.fromOffset(12, 42)
		gradeBar.Size = UDim2.new(1, -24, 0, 44)
		gradeBar.Position = UDim2.fromOffset(12, 70)
		list.Size = UDim2.new(0.56, -18, 1, -128)
		list.Position = UDim2.fromOffset(12, 120)
		details.Size = UDim2.new(0.44, -18, 1, -128)
		details.Position = UDim2.new(0.56, 6, 0, 120)
		gradeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		gradeLayout.Padding = UDim.new(0, 6)
	else
		main.Size = UDim2.fromScale(0.9, 0.84)
		main.Position = UDim2.fromScale(0.05, 0.08)
		title.Size = UDim2.new(1, -30, 0, 55)
		title.Position = UDim2.fromOffset(15, 10)
		subtitle.Size = UDim2.new(1, -30, 0, 30)
		subtitle.Position = UDim2.fromOffset(15, 65)
		gradeBar.Size = UDim2.new(1, -30, 0, 50)
		gradeBar.Position = UDim2.fromOffset(15, 105)
		list.Size = UDim2.new(0.56, -20, 1, -180)
		list.Position = UDim2.fromOffset(15, 165)
		details.Size = UDim2.new(0.44, -25, 1, -180)
		details.Position = UDim2.new(0.56, 10, 0, 165)
		gradeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		gradeLayout.Padding = UDim.new(0, 8)
	end

	for _, child in ipairs(gradeBar:GetChildren()) do
		if child:IsA("TextButton") then
			child.Size = UDim2.fromOffset((menuPortrait or menuLow) and 70 or 82, 42)
		end
	end

	hudControls.Visible = true
	hudObjective.TextScaled = false
	notification.TextScaled = false

	if narrow then
		local width = math.min(620, math.max(240, viewport.X - 24))
		hud.Position = UDim2.fromOffset(12, 12)
		if menuLow then
			width = math.min(500, math.max(240, viewport.X - 154))
			local tinyLow = width < 320
			hud.Size = UDim2.fromOffset(width, 126)
			hudSize.MinSize = Vector2.new(math.min(width, 360), 124)
			hudSize.MaxSize = Vector2.new(width, 128)
			hudTitle.Size = UDim2.new(1, -24, 0, 26)
			hudTitle.Position = UDim2.fromOffset(12, 4)
			hudObjective.Position = UDim2.fromOffset(12, 32)
			hudObjective.TextScaled = true
			if tinyLow then
				hudObjective.Size = UDim2.new(1, -24, 0, 68)
				hudScore.Position = UDim2.fromOffset(12, 103)
				hudControls.Visible = false
			else
				hudObjective.Size = UDim2.new(1, -24, 0, 50)
				hudScore.Position = UDim2.fromOffset(12, 84)
				hudControls.Position = UDim2.fromOffset(12, 107)
				hudControls.Size = UDim2.new(1, -24, 0, 18)
				hudControls.Text = UserInputService.TouchEnabled and "joystick • przeciągnij = kamera • interakcja"
					or "WASD • mysz = kamera • E = akcja"
			end
		elseif menuPortrait and viewport.Y < 560 then
			hud.Size = UDim2.fromOffset(width, 192)
			hudSize.MinSize = Vector2.new(math.min(width, 280), 188)
			hudSize.MaxSize = Vector2.new(width, 194)
			hudTitle.Size = UDim2.new(1, -24, 0, 32)
			hudTitle.Position = UDim2.fromOffset(12, 6)
			hudObjective.Position = UDim2.fromOffset(12, 40)
			hudObjective.Size = UDim2.new(1, -24, 0, 78)
			hudScore.Position = UDim2.fromOffset(12, 120)
			hudControls.Position = UDim2.fromOffset(12, 145)
			hudControls.Size = UDim2.new(1, -24, 0, 40)
			hudControls.Text = UserInputService.TouchEnabled
					and "STEROWANIE: joystick • przeciągnij ekran = kamera • użyj przycisku interakcji"
				or "STEROWANIE: WASD/strzałki • mysz = kamera • E = interakcja"
		else
			hud.Size = UDim2.fromOffset(width, 210)
			hudTitle.Size = UDim2.new(1, -24, 0, 32)
			hudTitle.Position = UDim2.fromOffset(12, 8)
			hudObjective.Position = UDim2.fromOffset(12, 42)
			hudSize.MinSize = Vector2.new(math.min(width, 280), 196)
			hudSize.MaxSize = Vector2.new(width, 220)
			hudObjective.Size = UDim2.new(1, -24, 0, 94)
			hudScore.Position = UDim2.fromOffset(12, 140)
			hudControls.Position = UDim2.fromOffset(12, 164)
			hudControls.Size = UDim2.new(1, -24, 0, 40)
			hudControls.Text = UserInputService.TouchEnabled
					and "STEROWANIE: joystick • przeciągnij ekran = kamera • użyj przycisku interakcji"
				or "STEROWANIE: WASD/strzałki • mysz = kamera • E = interakcja"
		end
		local notificationWidth = math.min(520, math.max(240, viewport.X - 24))
		if menuPortrait then
			local safeBottom = math.min(180, math.max(120, math.floor(viewport.Y * 0.22)))
			notification.Size = UDim2.fromOffset(notificationWidth, 96)
			notification.Position = UDim2.new(0.5, 0, 1, -safeBottom)
		else
			local tinyLowNotice = viewport.Y < 360
			local noticeHeight = tinyLowNotice and 54 or 72
			local safeBottom = tinyLowNotice and 120 or 110
			notification.TextScaled = true
			notification.Size = UDim2.fromOffset(notificationWidth, noticeHeight)
			notification.Position = UDim2.new(0.5, 0, 1, -safeBottom)
		end
	else
		hud.Size = UDim2.new(0.46, 0, 0, 174)
		hud.Position = UDim2.fromOffset(14, 14)
		hudSize.MinSize = Vector2.new(340, 164)
		hudSize.MaxSize = Vector2.new(620, 184)
		hudTitle.Size = UDim2.new(1, -24, 0, 32)
		hudTitle.Position = UDim2.fromOffset(12, 8)
		hudObjective.Position = UDim2.fromOffset(12, 42)
		hudObjective.Size = UDim2.new(1, -24, 0, 76)
		hudScore.Position = UDim2.fromOffset(12, 120)
		hudControls.Position = UDim2.fromOffset(12, 145)
		hudControls.Size = UDim2.new(1, -24, 0, 22)
		hudControls.Text = UserInputService.TouchEnabled
				and "STEROWANIE: joystick • przeciągnij ekran = kamera • użyj przycisku interakcji"
			or "STEROWANIE: WASD/strzałki • mysz = kamera • E = interakcja"
		notification.Size = UDim2.new(0.72, 0, 0, 112)
		notification.Position = UDim2.new(0.5, 0, 1, -20)
	end
end

local function bindViewport()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyPlayabilityLayout)
	end
	applyPlayabilityLayout()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport)
bindViewport()

local activeHudTitle = nil

missionInfo.OnClientEvent:Connect(function(message)
	if type(message) == "table" and message.kind == "poster_input" then
		posterField = message.field
		posterEditorTitle.Text = message.title or "Edytor plakatu"
		posterEditorHint.Text = message.hint or "Wpisz tekst"
		posterBox.PlaceholderText = message.hint or ""
		posterBox.Text = ""
		posterModal.Visible = true
		task.defer(function()
			posterBox:CaptureFocus()
		end)
		return
	end

	if type(message) == "table" and message.kind == "hud" then
		local newTitle = message.title or "Misja"
		local missionChanged = activeHudTitle ~= newTitle
		activeHudTitle = newTitle

		hud.Visible = true
		if openButton then
			openButton.Visible = true
		end
		hudTitle.Text = newTitle
		hudObjective.Text = "CEL: " .. (message.objective or "Wykonaj zadanie na planszy.")
		local timeText = message.timeLeft and ("   Czas: " .. message.timeLeft .. " s") or ""
		hudScore.Text = "Punkty: " .. tostring(message.score or 0) .. timeText

		if missionChanged then
			local helpText = UserInputService.TouchEnabled
					and "CEL jest w lewym górnym rogu. Podejdź do oznaczonych obiektów i użyj przycisku interakcji."
				or "CEL jest w lewym górnym rogu. Podejdź do oznaczonych obiektów. WASD = ruch, mysz = kamera, E = interakcja."
			notification.Text = helpText
			notification.BackgroundColor3 = Color3.fromRGB(20, 65, 105)
			notification.Visible = true
			task.delay(7, function()
				if notification.Text == helpText then
					notification.Visible = false
				end
			end)
		end
		return
	end

	if type(message) == "table" and message.kind == "objective" then
		if message.text then
			hudObjective.Text = "CEL: " .. tostring(message.text)
		end
		if message.score ~= nil then
			hudScore.Text = "Punkty: " .. tostring(message.score)
		end
		return
	end

	if type(message) == "table" and message.kind == "complete" then
		closePosterEditor()
		hud.Visible = false
		if openButton then
			openButton.Visible = false
		end
		activeHudTitle = nil
		local ranking = ""
		if message.rank and message.total then
			ranking = string.format("  Miejsce: %d/%d", message.rank, message.total)
		end
		local podium = {}
		for i, entry in ipairs(message.top or {}) do
			table.insert(podium, string.format("%d. %s — %d", i, entry.name or "Gracz", entry.score or 0))
		end
		local podiumText = #podium > 0 and ("\nTOP 3: " .. table.concat(podium, "   ")) or ""
		notification.Text = string.format(
			"MISJA UKOŃCZONA!  Wynik: %d  Czas: %d s%s%s",
			message.score or 0,
			message.time or 0,
			ranking,
			podiumText
		)
		notification.BackgroundColor3 = Color3.fromRGB(25, 100, 55)
		notification.Visible = true
		main.Visible = true
		return
	end

	if type(message) == "table" and message.kind ~= "message" then
		return
	end

	local text = type(message) == "table" and tostring(message.text or "") or tostring(message)
	if text == "" then
		return
	end
	notification.Text = text
	notification.BackgroundColor3 = (type(message) == "table" and message.good == false) and Color3.fromRGB(125, 30, 35)
		or Color3.fromRGB(20, 75, 60)
	notification.Visible = true
	task.delay(4, function()
		if notification.Text == text then
			notification.Visible = false
		end
	end)
end)

openButton = Instance.new("TextButton")
openButton.Size = UDim2.fromOffset(190, 44)
openButton.Position = UDim2.new(0, 14, 1, -58)
openButton.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
openButton.Text = "WYBIERZ INNĄ LEKCJĘ"
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Font = Enum.Font.GothamBold
openButton.TextScaled = true
openButton.Visible = false
openButton.Parent = gui
applyPlayabilityLayout()
openButton.Activated:Connect(function()
	setMenuVisible(not main.Visible)
end)

populateLessons("SP4")
print("[CER] MainMenu ready")