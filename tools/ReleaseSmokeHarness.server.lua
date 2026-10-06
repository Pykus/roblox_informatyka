local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Curriculum = require(Modules:WaitForChild("Curriculum"))
local MissionRules = require(Modules:WaitForChild("MissionRules"))
local MissionEngine = require(script.Parent:WaitForChild("MissionEngine"))
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local missionInfo = remotes:WaitForChild("MissionInfo")

local clientReportRemote = remotes:FindFirstChild("ReleaseSmokeClientReport")
if not clientReportRemote then
	clientReportRemote = Instance.new("RemoteEvent")
	clientReportRemote.Name = "ReleaseSmokeClientReport"
	clientReportRemote.Parent = remotes
end

local clientReports = {}
clientReportRemote.OnServerEvent:Connect(function(player, payload)
	if type(payload) == "table" then
		clientReports[player] = payload
	end
end)

local RELEASE_BUILD_ID = "__RELEASE_BUILD_ID__"
local MAX_FIRST_ACTION_DISTANCE = 80
local MIN_PROMPT_ACTIVATION_DISTANCE = 8
local MIN_WALK_SPEED = 8
local GROUND_PROBE_DISTANCE = 16
local MAX_RESPAWN_DISTANCE = 8

local MATRIX = {
	{ "SP4", 3, "Software Tower", true },
	{ "SP4", 4, "File Warehouse", true },
	{ "SP4", 5, "Cloud Sync", true },
	{ "SP4", 6, "Cyber Defense", true },
	{ "SP4", 7, "Newsroom Evidence", true },
	{ "SP4", 8, "Paint Shapes", true },
	{ "SP5", 3, "Timeline Museum", true },
	{ "SP5", 5, "Search Escape", true },
	{ "SP5", 7, "Problem Factory", true },
	{ "SP5", 8, "Typing Run", true },
	{ "SP6", 4, "Inventor Workshop", true },
	{ "SP6", 5, "PhotoLab", true },
	{ "SP6", 7, "Scratch Loop Grid", true },
	{ "SP6", 9, "Animation Lab", true },
	{ "SP7", 5, "Cyber Escape Finale", true },
	{ "SP7", 8, "Robot Rescue", true },
	{ "SP7", 10, "Python Lab", false },
	{ "SP8", 4, "Spreadsheet Factory", true },
	{ "SP8", 5, "Python Robot Maze", false },
	{ "SP8", 6, "Python Power Plant", false },
	{ "SP8", 7, "Number Foundry", true },
	{ "SP8", 8, "Search Race", true },
	{ "SP8", 9, "Sorting Arena", true },
	{ "SP8", 10, "Sports Newsroom", true },
	{ "LO1", 3, "Language Port", true },
	{ "LO1", 4, "Python Command Yard", false },
	{ "LO1", 5, "Parameter Lab", false },
	{ "LO1", 6, "Math Engine", true },
	{ "LO1", 7, "Decision Drone", true },
	{ "LO1", 8, "Logic Gate Control", true },
	{ "LO1", 9, "Loop Factory", false },
	{ "LO1", 10, "Sequence Reactor", true },
	{ "LO2", 3, "Vault 2/10/16", true },
	{ "LO2", 4, "Conversion Machine", true },
	{ "LO2", 5, "Rail Sort", true },
	{ "LO2", 6, "Message Lab", false },
	{ "LO2", 7, "Forensic Text Scanner", true },
	{ "LO2", 8, "Cipher Ring Vault", true },
	{ "LO2", 9, "Mail Merge Factory", true },
	{ "LO2", 10, "Data Import Dock", true },
	{ "LO3", 3, "Chrono Museum", true },
	{ "LO3", 4, "Decision City", true },
	{ "LO3", 5, "PC Emergency Room", true },
	{ "LO3", 6, "Internet Construction Yard", true },
	{ "LO3", 7, "Network Service District", true },
	{ "LO3", 8, "HTML Construction Studio", true },
	{ "LO3", 9, "CSS Style Reactor", true },
	{ "LO3", 10, "Launch Day Website", true },
}

local function currentModel(player)
	local container = workspace:FindFirstChild("PlayerMissions")
	if container then
		return container:FindFirstChild("Mission_" .. player.UserId)
	end
	return workspace:FindFirstChild("Mission_" .. player.UserId)
end

local function promptPart(prompt)
	local parent = prompt.Parent
	if parent and parent:IsA("BasePart") then
		return parent
	end
	if parent and parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then
		return parent.Parent
	end
	return prompt:FindFirstAncestorWhichIsA("BasePart")
end

local function promptHasVisibleAnchor(part)
	if not part then
		return false
	end
	if part.Transparency < 1 then
		return true
	end
	return part:GetAttribute("SemanticAssetId") ~= nil and part:GetAttribute("SemanticAssetFallback") == false
end

local function enabledMissionPrompts(model)
	local prompts = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Enabled then
			local part = promptPart(descendant)
			if promptHasVisibleAnchor(part) then
				table.insert(prompts, descendant)
			end
		end
	end
	return prompts
end

local function waitForPlayableCharacter(player)
	for _ = 1, 80 do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			if humanoid and root and root:IsA("BasePart") then
				return character, humanoid, root
			end
		end
		task.wait(0.1)
	end
	return nil, nil, nil
end

local function playableSpawn(player, grade, lessonNo)
	local character, humanoid, root = waitForPlayableCharacter(player)
	assert(character, string.format("[CER-RELEASE] no character %s/%02d after bounded wait", grade, lessonNo))
	assert(humanoid, string.format("[CER-RELEASE] no Humanoid %s/%02d after bounded wait", grade, lessonNo))
	assert(
		root and root:IsA("BasePart"),
		string.format("[CER-RELEASE] no HumanoidRootPart %s/%02d after bounded wait", grade, lessonNo)
	)
	assert(humanoid.Health > 0, string.format("[CER-RELEASE] dead Humanoid at start %s/%02d", grade, lessonNo))
	assert(
		humanoid.WalkSpeed >= MIN_WALK_SPEED,
		string.format(
			"[CER-RELEASE] WalkSpeed too low %s/%02d speed=%.1f min=%d",
			grade,
			lessonNo,
			humanoid.WalkSpeed,
			MIN_WALK_SPEED
		)
	)
	assert(not root.Anchored, string.format("[CER-RELEASE] HumanoidRootPart anchored %s/%02d", grade, lessonNo))

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = false
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -GROUND_PROBE_DISTANCE, 0), params)
	assert(hit, string.format("[CER-RELEASE] no ground below spawn %s/%02d", grade, lessonNo))
	local ground = hit.Instance
	local groundCollidable = ground:IsA("Terrain") or (ground:IsA("BasePart") and ground.CanCollide)
	assert(
		groundCollidable,
		string.format(
			"[CER-RELEASE] non-collidable ground below spawn %s/%02d object=%s",
			grade,
			lessonNo,
			ground:GetFullName()
		)
	)

	return humanoid.WalkSpeed, (root.Position - hit.Position).Magnitude
end

local function nearestEnabledPrompt(player, model)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil, math.huge
	end

	local nearest = nil
	local nearestDistance = math.huge
	for _, candidate in ipairs(enabledMissionPrompts(model)) do
		local part = promptPart(candidate)
		if part then
			local distance = (part.Position - root.Position).Magnitude
			if distance < nearestDistance then
				nearest = candidate
				nearestDistance = distance
			end
		end
	end
	return nearest, nearestDistance
end

local function findPrompt(model, objectText, parentName)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.ObjectText == objectText then
			local parent = descendant.Parent
			if not parentName or (parent and parent.Name == parentName) then
				return descendant
			end
		end
	end
	return nil
end

local function waitForClientReady(player)
	for _ = 1, 40 do
		local report = clientReports[player]
		if report and report.ready == true then
			return true
		end
		task.wait(0.1)
	end
	return false
end

local function waitForClientReport(player)
	for _ = 1, 60 do
		local report = clientReports[player]
		if report and report.ready ~= true then
			return report
		end
		task.wait(0.1)
	end
	return nil
end

local function waitForModel(player)
	for _ = 1, 30 do
		local model = currentModel(player)
		if model then
			return model
		end
		task.wait(0.1)
	end
	return nil
end

local function waitForCharacterReplacement(player, previousCharacter)
	for _ = 1, 60 do
		local character = player.Character
		if character and character ~= previousCharacter then
			return character
		end
		task.wait(0.1)
	end
	return nil
end

local function runCase(player, case, index)
	local grade, lessonNo, label, expectPrompt = table.unpack(case)
	local gradeData = Curriculum[grade]
	assert(gradeData, "[CER-RELEASE] missing grade " .. grade)

	local lesson = gradeData.lessons[lessonNo]
	assert(lesson, string.format("[CER-RELEASE] missing lesson %s/%02d", grade, lessonNo))

	local mission = MissionRules.GetForLesson(lesson, grade)
	assert(mission and mission.available, string.format("[CER-RELEASE] unavailable %s/%02d", grade, lessonNo))

	player:SetAttribute("SelectedGrade", grade)
	player:SetAttribute("SelectedLesson", lessonNo)
	player:SetAttribute("SelectedTopic", lesson.topic)
	player:SetAttribute("MissionType", mission.type)
	clientReports[player] = nil

	MissionEngine.Start(player, lesson, mission, missionInfo)
	local model = waitForModel(player)
	assert(model, string.format("[CER-RELEASE] no mission model %s/%02d", grade, lessonNo))

	task.wait(0.35)

	local walkSpeed, groundDistance = playableSpawn(player, grade, lessonNo)

	local clientReport = waitForClientReport(player)
	assert(clientReport, string.format("[CER-RELEASE] no client probe report %s/%02d", grade, lessonNo))
	assert(clientReport.cameraCustom, string.format("[CER-RELEASE] camera not Custom %s/%02d", grade, lessonNo))
	assert(clientReport.cameraClassic, string.format("[CER-RELEASE] camera mode not Classic %s/%02d", grade, lessonNo))
	assert(
		math.abs((clientReport.cameraMin or -999) - 5) <= 0.05
			and math.abs((clientReport.cameraMax or -999) - 16) <= 0.05,
		string.format(
			"[CER-RELEASE] zoom mismatch %s/%02d min=%s max=%s",
			grade,
			lessonNo,
			tostring(clientReport.cameraMin),
			tostring(clientReport.cameraMax)
		)
	)
	assert(
		math.abs((clientReport.cameraFov or -999) - 70) <= 0.5,
		string.format("[CER-RELEASE] FOV mismatch %s/%02d fov=%s", grade, lessonNo, tostring(clientReport.cameraFov))
	)
	assert(
		clientReport.cameraSubjectHumanoid,
		string.format("[CER-RELEASE] camera subject not Humanoid %s/%02d", grade, lessonNo)
	)
	if index == 1 then
		assert(clientReport.cameraRecoveryProbeDone, "[CER-RELEASE] camera recovery sabotage probe did not run")
		assert(clientReport.cameraReplacementProbeDone, "[CER-RELEASE] CurrentCamera replacement probe did not run")
		assert(clientReport.inputRecoveryProbeDone, "[CER-RELEASE] hidden TextBox focus probe did not run")
		assert(clientReport.inputRecoveryProbePassed, "[CER-RELEASE] hidden TextBox focus was not released")
		assert(clientReport.constraintRecoveryProbeDone, "[CER-RELEASE] late text constraint probe did not run")
	end
	assert(clientReport.constraintRecoveryProbePassed, "[CER-RELEASE] text constraint dedupe/recovery failed")
	assert(
		not clientReport.hiddenFocusedTextBox,
		string.format(
			"[CER-RELEASE] hidden TextBox still focused %s/%02d object=%s",
			grade,
			lessonNo,
			tostring(clientReport.focusedTextBox)
		)
	)
	assert(
		not clientReport.spuriousMissionUpdateVisible,
		string.format(
			"[CER-RELEASE] spurious mission update toast visible %s/%02d text=%s",
			grade,
			lessonNo,
			tostring(clientReport.missionNotificationText)
		)
	)
	assert(
		clientReport.hudObjectiveVisible and clientReport.hudObjectivePrefix,
		string.format("[CER-RELEASE] CEL HUD missing/hidden %s/%02d", grade, lessonNo)
	)
	assert(
		(clientReport.hudObjectiveTextSize or 0) >= 20,
		string.format(
			"[CER-RELEASE] CEL base text too small %s/%02d size=%s",
			grade,
			lessonNo,
			tostring(clientReport.hudObjectiveTextSize)
		)
	)
	assert(
		clientReport.hudObjectiveFits,
		string.format(
			"[CER-RELEASE] CEL clipped %s/%02d bounds=%.1fx%.1f box=%.1fx%.1f",
			grade,
			lessonNo,
			clientReport.hudObjectiveBoundsX or -1,
			clientReport.hudObjectiveBoundsY or -1,
			clientReport.hudObjectiveWidth or -1,
			clientReport.hudObjectiveHeight or -1
		)
	)
	assert(
		clientReport.scaledTextReadable,
		string.format(
			"[CER-RELEASE] scaled ScreenGui text below 16 %s/%02d object=%s",
			grade,
			lessonNo,
			tostring(clientReport.scaledTextProblem)
		)
	)
	assert(
		clientReport.worldTextReadable and (clientReport.worldTextCount or 0) > 0,
		string.format(
			"[CER-RELEASE] world text unreadable %s/%02d object=%s",
			grade,
			lessonNo,
			tostring(clientReport.worldTextProblem)
		)
	)
	if expectPrompt then
		assert(
			clientReport.firstActionGuideVisible,
			string.format("[CER-RELEASE] First Action Guide not visible %s/%02d", grade, lessonNo)
		)
		assert(
			clientReport.firstActionBeaconVisible,
			string.format("[CER-RELEASE] First Action beacon not visible %s/%02d", grade, lessonNo)
		)
	end
	if
		(grade == "SP7" and lessonNo == 10)
		or (grade == "SP8" and (lessonNo == 5 or lessonNo == 6))
		or (grade == "LO1" and lessonNo == 9)
	then
		assert(
			clientReport.pythonConsoleVisible,
			string.format("[CER-RELEASE] Python Console not visible on %s/%02d", grade, lessonNo)
		)
	end
	if grade == "SP5" and lessonNo == 8 then
		assert(clientReport.typingUiPresent, "[CER-RELEASE] TypingTerminalUI missing on SP5/08")
	end

	local variant = model:GetAttribute("MissionVariant")
	assert(
		variant == (mission.variant or "legacy"),
		string.format(
			"[CER-RELEASE] variant mismatch %s/%02d expected=%s got=%s",
			grade,
			lessonNo,
			tostring(mission.variant),
			tostring(variant)
		)
	)

	local corePrompt = findPrompt(model, "RDZEŃ MISJI • ETAP 2/3", "MissionCore")
	assert(corePrompt, string.format("[CER-RELEASE] missing core prompt %s/%02d", grade, lessonNo))
	assert(not corePrompt.Enabled, string.format("[CER-RELEASE] core active too early %s/%02d", grade, lessonNo))

	local exitPrompt = findPrompt(model, "WYJŚCIE", "ExitGate")
	assert(exitPrompt, string.format("[CER-RELEASE] missing exit prompt %s/%02d", grade, lessonNo))
	assert(not exitPrompt.Enabled, string.format("[CER-RELEASE] exit active too early %s/%02d", grade, lessonNo))

	local descendants = #model:GetDescendants()
	assert(
		descendants >= 20,
		string.format("[CER-RELEASE] suspiciously empty world %s/%02d descendants=%d", grade, lessonNo, descendants)
	)

	for _ = 1, 20 do
		if model:GetAttribute("SemanticDecorationScanned") then
			break
		end
		task.wait(0.05)
	end
	assert(
		model:GetAttribute("SemanticDecorationScanned"),
		string.format("[CER-RELEASE] semantic decorator did not scan %s/%02d", grade, lessonNo)
	)

	local semanticCandidates = 0
	local semanticLoaded = 0
	local semanticFallbacks = 0
	for _ = 1, 30 do
		semanticCandidates = 0
		semanticLoaded = 0
		semanticFallbacks = 0
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("SemanticDecorated") then
				semanticCandidates += 1
				if descendant:GetAttribute("SemanticAssetFallback") then
					semanticFallbacks += 1
				elseif descendant:GetAttribute("SemanticAssetId") then
					semanticLoaded += 1
				end
			end
		end
		if semanticLoaded + semanticFallbacks == semanticCandidates then
			break
		end
		task.wait(0.1)
	end
	assert(
		semanticFallbacks == 0,
		string.format("[CER-RELEASE] semantic asset fallback %s/%02d count=%d", grade, lessonNo, semanticFallbacks)
	)
	assert(
		semanticLoaded == semanticCandidates,
		string.format(
			"[CER-RELEASE] semantic asset unresolved %s/%02d loaded=%d candidates=%d",
			grade,
			lessonNo,
			semanticLoaded,
			semanticCandidates
		)
	)
	if grade == "SP4" and lessonNo == 3 then
		assert(
			semanticLoaded >= 11,
			string.format("[CER-RELEASE] SP4/03 expected >=11 semantic tower assets, got %d", semanticLoaded)
		)
		for index = 1, 4 do
			assert(
				model:FindFirstChild("Semantic_SoftwareModule" .. index),
				string.format("[CER-RELEASE] SP4/03 semantic software module %d missing", index)
			)
		end
		local softwareExpected = {
			"Semantic_BootTowerScreen",
			"Semantic_SoftwareGraphicsDesktop",
			"Semantic_SoftwareTeamTablet",
			"Semantic_SoftwareSystemInstallControl_1",
			"Semantic_SoftwareSystemInstallControl_2",
			"Semantic_SoftwareAppInstallControl_1",
			"Semantic_SoftwareAppInstallControl_2",
		}
		for _, semanticName in ipairs(softwareExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP4/03 semantic tower asset missing %s", semanticName)
			)
		end
	elseif grade == "SP4" and lessonNo == 4 then
		assert(
			semanticLoaded >= 11,
			string.format("[CER-RELEASE] SP4/04 expected >=11 semantic warehouse assets, got %d", semanticLoaded)
		)
		for index = 1, 5 do
			assert(
				model:FindFirstChild("Semantic_DataPackage" .. index),
				string.format("[CER-RELEASE] SP4/04 semantic moving package missing %d", index)
			)
		end
		assert(
			model:FindFirstChild("Semantic_ExtensionScanner"),
			"[CER-RELEASE] SP4/04 semantic extension scanner missing"
		)
		assert(model:FindFirstChild("Semantic_ScannerPanel"), "[CER-RELEASE] SP4/04 semantic scanner panel missing")
		for index = 1, 4 do
			assert(
				model:FindFirstChild("Semantic_WarehouseFolderCabinet_" .. index),
				string.format("[CER-RELEASE] SP4/04 semantic folder cabinet missing %d", index)
			)
		end
	elseif grade == "SP4" and lessonNo == 5 then
		assert(
			semanticLoaded >= 9,
			string.format("[CER-RELEASE] SP4/05 expected >=9 semantic cloud controls, got %d", semanticLoaded)
		)
		local cloudExpected = {
			"Semantic_LAPTOPShell",
			"Semantic_TABLETShell",
			"Semantic_CloudUploadControl_LAPTOP",
			"Semantic_CloudUploadControl_TABLET",
			"Semantic_CloudDownloadControl_LAPTOP",
			"Semantic_CloudDownloadControl_TABLET",
			"Semantic_CloudShareControl_PUBLIC",
			"Semantic_CloudShareControl_PASSWORD_NAME",
			"Semantic_CloudShareControl_PEOPLE",
		}
		for _, semanticName in ipairs(cloudExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP4/05 semantic cloud asset missing %s", semanticName)
			)
		end
	elseif grade == "SP4" and lessonNo == 6 then
		assert(
			semanticLoaded >= 20,
			string.format(
				"[CER-RELEASE] SP4/06 expected >=20 semantic cyber-defense controls/hardware, got %d",
				semanticLoaded
			)
		)
		local cyberExpected = {
			"Semantic_CyberShieldArmLever",
			"Semantic_MessageScanner",
			"Semantic_CyberPasswordControl_LONG",
			"Semantic_CyberPasswordControl_UNIQUE",
			"Semantic_CyberPasswordControl_MANAGER",
			"Semantic_CyberPasswordControl_123456",
			"Semantic_CyberPasswordControl_NAMEYEAR",
			"Semantic_CyberPasswordControl_REUSE",
			"Semantic_CyberMessageControl_Block",
			"Semantic_CyberMessageControl_Allow",
			"Semantic_CyberMFAKeyControl",
			"Semantic_CyberMFALockConsole",
			"Semantic_CyberShieldStatusMonitor",
			"Semantic_CyberShieldGeneratorConsole",
			"Semantic_CyberAttackStatusMonitor",
			"Semantic_CyberSOCDesk",
			"Semantic_CyberSOCKeyboard",
			"Semantic_CyberSOCMouse",
			"Semantic_CyberPhishingTerminal",
			"Semantic_CyberMFAServiceRack",
		}
		for _, semanticName in ipairs(cyberExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP4/06 semantic cyber-defense asset missing %s", semanticName)
			)
		end
	elseif grade == "SP4" and lessonNo == 7 then
		assert(
			semanticLoaded >= 4,
			string.format("[CER-RELEASE] SP4/07 expected >=4 semantic newsroom assets, got %d", semanticLoaded)
		)
		assert(
			model:FindFirstChild("Semantic_NewsroomFieldCamera"),
			"[CER-RELEASE] SP4/07 semantic field camera missing"
		)
		assert(model:FindFirstChild("Semantic_NewsroomEditorDesk"), "[CER-RELEASE] SP4/07 semantic editor desk missing")
		assert(
			model:FindFirstChild("Semantic_NewsroomEditorMonitor"),
			"[CER-RELEASE] SP4/07 semantic editor monitor missing"
		)
		assert(
			model:FindFirstChild("Semantic_NewsroomSourceScanner"),
			"[CER-RELEASE] SP4/07 semantic source scanner missing"
		)
	elseif grade == "SP4" and lessonNo == 8 then
		assert(
			semanticLoaded >= 4,
			string.format("[CER-RELEASE] SP4/08 expected >=4 semantic paint-studio assets, got %d", semanticLoaded)
		)
		assert(
			model:FindFirstChild("Semantic_PaintStudioOperatorDesk"),
			"[CER-RELEASE] SP4/08 semantic operator desk missing"
		)
		assert(
			model:FindFirstChild("Semantic_PaintStudioPreviewMonitor"),
			"[CER-RELEASE] SP4/08 semantic preview monitor missing"
		)
		assert(model:FindFirstChild("Semantic_PaintStudioKeyboard"), "[CER-RELEASE] SP4/08 semantic keyboard missing")
		assert(model:FindFirstChild("Semantic_PaintStudioMouse"), "[CER-RELEASE] SP4/08 semantic mouse missing")
	elseif grade == "SP5" and lessonNo == 3 then
		assert(
			semanticLoaded >= 11,
			string.format("[CER-RELEASE] SP5/03 expected >=11 semantic museum assets, got %d", semanticLoaded)
		)
		local timelineExpected = {
			"Semantic_TimelineEntryScanner",
			"Semantic_TimelineArtifact_ENIAC",
			"Semantic_TimelineArtifact_PC",
			"Semantic_TimelineArtifact_PHONE",
			"Semantic_TimelineEraDisplay_1946",
			"Semantic_TimelineEraDisplay_1981",
			"Semantic_TimelineEraDisplay_2007",
			"Semantic_TimelineDepotShelf",
			"Semantic_TimelineArchiveCabinet_Left",
			"Semantic_TimelineArchiveCabinet_Right",
			"Semantic_ArchiveConsole",
		}
		for _, semanticName in ipairs(timelineExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP5/03 semantic museum asset missing %s", semanticName)
			)
		end
	elseif grade == "SP5" and lessonNo == 5 then
		assert(
			semanticLoaded >= 24,
			string.format("[CER-RELEASE] SP5/05 expected >=24 semantic search controls, got %d", semanticLoaded)
		)
		for stage = 1, 3 do
			assert(
				model:FindFirstChild("Semantic_SearchTerminal_" .. stage),
				string.format("[CER-RELEASE] SP5/05 semantic terminal %d missing", stage)
			)
			for tokenIndex = 1, 4 do
				assert(
					model:FindFirstChild(string.format("Semantic_SearchTokenControl_%d_%d", stage, tokenIndex)),
					string.format("[CER-RELEASE] SP5/05 token control missing stage=%d token=%d", stage, tokenIndex)
				)
			end
			assert(
				model:FindFirstChild("Semantic_SearchQuoteControl_" .. stage),
				string.format("[CER-RELEASE] SP5/05 quote control missing stage=%d", stage)
			)
			assert(
				model:FindFirstChild("Semantic_SearchPdfControl_" .. stage),
				string.format("[CER-RELEASE] SP5/05 PDF control missing stage=%d", stage)
			)
			assert(
				model:FindFirstChild("Semantic_SearchRunControl_" .. stage),
				string.format("[CER-RELEASE] SP5/05 run control missing stage=%d", stage)
			)
		end
	elseif grade == "SP5" and lessonNo == 7 then
		assert(
			semanticLoaded >= 15,
			string.format("[CER-RELEASE] SP5/07 expected >=15 semantic problem-solving assets, got %d", semanticLoaded)
		)
		local problemExpected = {
			"Semantic_ConveyorCrate",
			"Semantic_DiagnosticConsole",
			"Semantic_LoadTestConsole",
			"Semantic_ProblemLoadTestControl",
			"Semantic_ProblemEntryConsole",
			"Semantic_ProblemInstructionBoard",
		}
		for _, probeId in ipairs({ "SENSOR", "MOTOR", "CABLE" }) do
			table.insert(problemExpected, "Semantic_ProblemMeasureControl_" .. probeId)
			table.insert(problemExpected, "Semantic_ProblemDiagnosisControl_" .. probeId)
		end
		for _, repairId in ipairs({ "STOP", "CONNECT", "POWER" }) do
			table.insert(problemExpected, "Semantic_ProblemRepairControl_" .. repairId)
		end
		for _, semanticName in ipairs(problemExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP5/07 semantic problem-solving asset missing %s", semanticName)
			)
		end
	elseif grade == "SP5" and lessonNo == 8 then
		assert(
			semanticLoaded >= 8,
			string.format("[CER-RELEASE] SP5/08 expected >=8 semantic typing assets, got %d", semanticLoaded)
		)
		local typingExpected = {
			"Semantic_TypingTerminal",
			"Semantic_TypingCourierBody",
			"Semantic_DataCrate",
			"Semantic_FileCrate",
			"Semantic_TypingOperatorDesk",
			"Semantic_TypingTerminalKeyboard",
			"Semantic_TypingTerminalMouse",
			"Semantic_TypingAccuracyMonitor",
		}
		for _, semanticName in ipairs(typingExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP5/08 semantic typing asset missing %s", semanticName)
			)
		end
	elseif grade == "SP6" and lessonNo == 4 then
		assert(
			semanticLoaded >= 16,
			string.format("[CER-RELEASE] SP6/04 expected >=16 semantic inventor controls, got %d", semanticLoaded)
		)
		local inventorExpected = {
			"Semantic_InventorComponentRack",
			"Semantic_InventorTestConsole",
			"Semantic_InventorEntryConsole",
			"Semantic_InventorInstructionBoard",
			"Semantic_InventorModuleControl_MOTION_SENSOR",
			"Semantic_InventorModuleControl_CONTROLLER",
			"Semantic_InventorModuleControl_MOTOR",
			"Semantic_InventorModuleControl_BATTERY",
			"Semantic_InventorModuleControl_STORAGE",
			"Semantic_InventorModuleControl_ANTENNA",
			"Semantic_InventorSlotControl_INPUT",
			"Semantic_InventorSlotControl_PROCESSOR",
			"Semantic_InventorSlotControl_OUTPUT",
			"Semantic_InventorCableControl_INPUT_PROCESSOR",
			"Semantic_InventorCableControl_INPUT_OUTPUT",
			"Semantic_InventorCableControl_PROCESSOR_OUTPUT",
		}
		for _, semanticName in ipairs(inventorExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP6/04 semantic inventor asset missing %s", semanticName)
			)
		end
	elseif grade == "SP6" and lessonNo == 5 then
		assert(
			semanticLoaded >= 11,
			string.format("[CER-RELEASE] SP6/05 expected >=11 semantic photo-lab assets, got %d", semanticLoaded)
		)
		local photoExpected = {
			"Semantic_PhotoCameraBody",
			"Semantic_PhotoPrinter",
			"Semantic_PhotoEntryConsole",
			"Semantic_PhotoInstructionBoard",
			"Semantic_PhotoOrientationControl",
			"Semantic_PhotoPanLeft",
			"Semantic_PhotoPanRight",
			"Semantic_PhotoDarker",
			"Semantic_PhotoBrighter",
			"Semantic_PhotoContrastDial",
			"Semantic_PhotoShutter",
		}
		for _, semanticName in ipairs(photoExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP6/05 semantic photo asset missing %s", semanticName)
			)
		end
	elseif grade == "SP6" and lessonNo == 7 then
		assert(
			semanticLoaded >= 17,
			string.format("[CER-RELEASE] SP6/07 expected >=17 semantic scratch-loop assets, got %d", semanticLoaded)
		)
		local scratchLoopExpected = {
			"Semantic_ScratchLoopRobot",
			"Semantic_ScratchProgramRack",
			"Semantic_ScratchXConsole",
			"Semantic_ScratchYConsole",
			"Semantic_ScratchRunConsole",
			"Semantic_ScratchVariableBoard",
			"Semantic_ScratchLoopStatusBoard",
			"Semantic_ScratchLoopStartControl",
			"Semantic_ScratchLoopRunControl",
			"Semantic_ScratchLoopDebugMonitor",
			"Semantic_ScratchLoopOperatorDesk",
			"Semantic_ScratchLoopOperatorKeyboard",
			"Semantic_ScratchLoopOperatorMouse",
			"Semantic_ScratchLoopXControl_Minus",
			"Semantic_ScratchLoopXControl_Plus",
			"Semantic_ScratchLoopYControl_Minus",
			"Semantic_ScratchLoopYControl_Plus",
		}
		for _, semanticName in ipairs(scratchLoopExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP6/07 semantic scratch-loop asset missing %s", semanticName)
			)
		end
	elseif grade == "SP6" and lessonNo == 9 then
		assert(
			semanticLoaded >= 9,
			string.format("[CER-RELEASE] SP6/09 expected >=9 semantic animation controls, got %d", semanticLoaded)
		)
		for _, objectId in ipairs({ "CLOUD", "RAIN", "SUN" }) do
			assert(
				model:FindFirstChild("Semantic_AnimationPathControl_" .. objectId),
				string.format("[CER-RELEASE] SP6/09 path control missing %s", objectId)
			)
			assert(
				model:FindFirstChild("Semantic_AnimationTriggerControl_" .. objectId),
				string.format("[CER-RELEASE] SP6/09 trigger control missing %s", objectId)
			)
		end
		for _, semanticName in ipairs({
			"Semantic_AnimationPathTestConsole",
			"Semantic_AnimationTriggerTestConsole",
			"Semantic_AnimationFinalConsole",
		}) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP6/09 animation console missing %s", semanticName)
			)
		end
	elseif grade == "SP8" and lessonNo == 4 then
		assert(
			semanticLoaded >= 18,
			string.format("[CER-RELEASE] SP8/04 expected >=18 semantic spreadsheet controls, got %d", semanticLoaded)
		)
		local spreadsheetExpected = {
			"Semantic_SpreadsheetEntryConsole",
			"Semantic_SpreadsheetInstructionBoard",
			"Semantic_FormulaRepairDesk",
			"Semantic_SpreadsheetRunConsole",
			"Semantic_SpreadsheetQuantityConsole",
			"Semantic_SpreadsheetSyncConsole",
			"Semantic_SpreadsheetRunControl",
			"Semantic_SpreadsheetQtyMinusControl",
			"Semantic_SpreadsheetQtyPlusControl",
			"Semantic_SpreadsheetSyncControl",
		}
		for _, cell in ipairs({ "D2", "D3", "D4", "D5" }) do
			for optionIndex = 1, 2 do
				table.insert(
					spreadsheetExpected,
					string.format("Semantic_SpreadsheetFormulaControl_%s_%d", cell, optionIndex)
				)
			end
		end
		for _, semanticName in ipairs(spreadsheetExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP8/04 semantic spreadsheet asset missing %s", semanticName)
			)
		end
	elseif grade == "SP8" and lessonNo == 7 then
		assert(
			semanticLoaded >= 9,
			string.format("[CER-RELEASE] SP8/07 expected >=9 semantic number-foundry assets, got %d", semanticLoaded)
		)
		local numberExpected = {
			"Semantic_NumberFoundryEntryConsole",
			"Semantic_NumberFoundryInstructionBoard",
			"Semantic_NumberModuloScanner",
			"Semantic_NumberDivisorControl_2",
			"Semantic_NumberDivisorControl_3",
			"Semantic_NumberDivisorControl_5",
			"Semantic_NumberDivisorControl_7",
			"Semantic_NumberClassifyControl_Prime",
			"Semantic_NumberClassifyControl_Composite",
		}
		for _, semanticName in ipairs(numberExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP8/07 semantic number-foundry asset missing %s", semanticName)
			)
		end
	elseif grade == "SP8" and lessonNo == 8 then
		assert(
			semanticLoaded >= 29,
			string.format("[CER-RELEASE] SP8/08 expected >=29 semantic search-race assets, got %d", semanticLoaded)
		)
		local searchRaceExpected = {
			"Semantic_SearchRaceEntryConsole",
			"Semantic_SearchRaceInstructionBoard",
			"Semantic_LinearSearchBot",
			"Semantic_BinarySearchBot",
		}
		for shelfIndex = 1, 12 do
			table.insert(searchRaceExpected, "Semantic_SearchLinearShelf_" .. shelfIndex)
			table.insert(searchRaceExpected, "Semantic_SearchBinaryShelf_" .. shelfIndex)
		end
		for _, semanticName in ipairs(searchRaceExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP8/08 semantic search-race asset missing %s", semanticName)
			)
		end
	elseif grade == "SP8" and lessonNo == 9 then
		assert(
			semanticLoaded >= 14,
			string.format("[CER-RELEASE] SP8/09 expected >=14 semantic sorting assets, got %d", semanticLoaded)
		)
		local sortingExpected = {
			"Semantic_SortingCalibrationConsole",
			"Semantic_SortingInstructionBoard",
			"Semantic_SortingScannerTop",
			"Semantic_SortingDecisionKeepControl",
			"Semantic_SortingDecisionSwapControl",
			"Semantic_SortingSpeedControl",
			"Semantic_SortingProductionControl",
			"Semantic_SortingSpeedConsole",
			"Semantic_SortingProductionConsole",
		}
		for packageIndex = 1, 5 do
			table.insert(sortingExpected, "Semantic_SorterPackage_" .. packageIndex)
		end
		for _, semanticName in ipairs(sortingExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP8/09 semantic sorting asset missing %s", semanticName)
			)
		end
	elseif grade == "SP8" and lessonNo == 10 then
		assert(
			semanticLoaded >= 14,
			string.format("[CER-RELEASE] SP8/10 expected >=14 semantic sports-news controls, got %d", semanticLoaded)
		)
		for _, factId in ipairs({ "SCORE", "SHOTS", "POSSESSION", "FOULS" }) do
			assert(
				model:FindFirstChild("Semantic_SportsFactScanControl_" .. factId),
				string.format("[CER-RELEASE] SP8/10 fact scan control missing %s", factId)
			)
		end
		for _, controlId in ipairs({ "HomeMinus", "HomePlus", "AwayMinus", "AwayPlus" }) do
			assert(
				model:FindFirstChild("Semantic_SportsChartControl_" .. controlId),
				string.format("[CER-RELEASE] SP8/10 chart control missing %s", controlId)
			)
		end
		assert(
			model:FindFirstChild("Semantic_SportsChartValidateControl"),
			"[CER-RELEASE] SP8/10 chart validate console missing"
		)
		for _, direction in ipairs({ "Left", "Right" }) do
			assert(
				model:FindFirstChild("Semantic_SportsCameraControl_" .. direction),
				string.format("[CER-RELEASE] SP8/10 camera control missing %s", direction)
			)
		end
		assert(
			model:FindFirstChild("Semantic_SportsPhotoCaptureControl"),
			"[CER-RELEASE] SP8/10 photo capture control missing"
		)
		assert(model:FindFirstChild("Semantic_SportsCameraDrone"), "[CER-RELEASE] SP8/10 camera drone missing")
		assert(model:FindFirstChild("Semantic_SportsBroadcastDesk"), "[CER-RELEASE] SP8/10 broadcast desk missing")
	elseif grade == "SP7" and lessonNo == 5 then
		assert(
			semanticLoaded >= 20,
			string.format("[CER-RELEASE] SP7/05 expected >=20 semantic finale controls, got %d", semanticLoaded)
		)
		assert(
			model:FindFirstChild("Semantic_ChapterEntryScanner"),
			"[CER-RELEASE] SP7/05 semantic entry scanner missing"
		)
		assert(
			model:FindFirstChild("Semantic_ChapterInstructionBoard"),
			"[CER-RELEASE] SP7/05 semantic instruction monitor missing"
		)
		assert(
			model:FindFirstChild("Semantic_ChapterAlgorithmConsole"),
			"[CER-RELEASE] SP7/05 semantic algorithm console missing"
		)
		assert(
			model:FindFirstChild("Semantic_ChapterDataScanner"),
			"[CER-RELEASE] SP7/05 semantic data scanner missing"
		)
		assert(
			model:FindFirstChild("Semantic_ChapterSecurityTerminal"),
			"[CER-RELEASE] SP7/05 semantic security terminal missing"
		)
		for index = 1, 4 do
			assert(
				model:FindFirstChild("Semantic_ChapterAlgorithmButton_" .. index),
				string.format("[CER-RELEASE] SP7/05 semantic algorithm button %d missing", index)
			)
		end
		for index = 1, 8 do
			assert(
				model:FindFirstChild("Semantic_ChapterBitSwitch_" .. index),
				string.format("[CER-RELEASE] SP7/05 semantic bit switch %d missing", index)
			)
		end
		for index = 1, 3 do
			assert(
				model:FindFirstChild("Semantic_ChapterSecurityButton_" .. index),
				string.format("[CER-RELEASE] SP7/05 semantic security button %d missing", index)
			)
		end
	elseif grade == "LO1" and lessonNo == 3 then
		assert(
			semanticLoaded >= 10,
			string.format("[CER-RELEASE] LO1/03 expected >=10 semantic language-port assets, got %d", semanticLoaded)
		)
		for _, projectId in ipairs({ "DATA", "WEB", "DEVICE", "GAME" }) do
			assert(
				model:FindFirstChild("Semantic_LanguageCargo_" .. projectId),
				string.format("[CER-RELEASE] LO1/03 semantic cargo missing %s", projectId)
			)
		end
		for _, languageId in ipairs({ "PYTHON", "JAVASCRIPT", "C", "CSHARP" }) do
			assert(
				model:FindFirstChild("Semantic_LanguageDockControl_" .. languageId),
				string.format("[CER-RELEASE] LO1/03 semantic dock control missing %s", languageId)
			)
		end
		assert(
			model:FindFirstChild("Semantic_LanguagePortScannerBase"),
			"[CER-RELEASE] LO1/03 semantic manifest scanner missing"
		)
		assert(
			model:FindFirstChild("Semantic_LanguagePortLaunchConsole"),
			"[CER-RELEASE] LO1/03 semantic launch console missing"
		)
	elseif grade == "LO1" and lessonNo == 4 then
		assert(
			semanticLoaded >= 9,
			string.format("[CER-RELEASE] LO1/04 expected >=9 semantic command-yard assets, got %d", semanticLoaded)
		)
		local commandExpected = {
			"Semantic_MissionTerminal",
			"Semantic_RescueRobot",
			"Semantic_CommandYardRobot",
			"Semantic_CommandYardCart",
			"Semantic_CommandYardOperatorDesk",
			"Semantic_CommandYardKeyboard",
			"Semantic_CommandYardMouse",
			"Semantic_CommandYardSignalMonitor",
			"Semantic_CommandYardToolbox",
		}
		for _, semanticName in ipairs(commandExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO1/04 semantic command-yard asset missing %s", semanticName)
			)
		end
	elseif grade == "LO1" and lessonNo == 5 then
		assert(
			semanticLoaded >= 7,
			string.format("[CER-RELEASE] LO1/05 expected >=7 semantic parameter-lab assets, got %d", semanticLoaded)
		)
		local parameterExpected = {
			"Semantic_ParameterControlConsole",
			"Semantic_ParameterMonitor",
			"Semantic_ParameterAutomationRack",
			"Semantic_ParameterRobot",
			"Semantic_ParameterLiftCargo",
			"Semantic_ParameterPistonCargo_Left",
			"Semantic_ParameterPistonCargo_Right",
		}
		for _, semanticName in ipairs(parameterExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO1/05 semantic parameter asset missing %s", semanticName)
			)
		end
	elseif grade == "LO1" and lessonNo == 6 then
		assert(
			semanticLoaded >= 12,
			string.format(
				"[CER-RELEASE] LO1/06 expected >=12 semantic math-engine controls/hardware, got %d",
				semanticLoaded
			)
		)
		for _, semanticName in ipairs({
			"Semantic_MathCalibrationConsole",
			"Semantic_MathFunctionControl_SQRT",
			"Semantic_MathFunctionControl_FLOOR",
			"Semantic_MathFunctionControl_CEIL",
			"Semantic_MathEngineLaunchConsole",
			"Semantic_MathEngineStatus",
			"Semantic_MathEngineResult",
			"Semantic_MathEngineExplanation",
			"Semantic_MathOperatorDesk",
			"Semantic_MathOperatorKeyboard",
			"Semantic_MathOperatorMouse",
			"Semantic_MathEngineCoreRack",
		}) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO1/06 semantic math asset missing %s", semanticName)
			)
		end
	elseif grade == "LO1" and lessonNo == 7 then
		assert(
			semanticLoaded >= 11,
			string.format("[CER-RELEASE] LO1/07 expected >=11 semantic decision-drone assets, got %d", semanticLoaded)
		)
		assert(model:FindFirstChild("Semantic_DecisionDronePowerConsole"), "[CER-RELEASE] LO1/07 power console missing")
		assert(
			model:FindFirstChild("Semantic_DecisionDroneInstructionBoard"),
			"[CER-RELEASE] LO1/07 instruction board missing"
		)
		for _, operatorId in ipairs({ "LT", "LE", "GT" }) do
			assert(
				model:FindFirstChild("Semantic_DecisionOperatorControl_" .. operatorId),
				string.format("[CER-RELEASE] LO1/07 semantic operator control missing %s", operatorId)
			)
		end
		for _, threshold in ipairs({ 2, 30, 50 }) do
			assert(
				model:FindFirstChild("Semantic_DecisionThresholdControl_" .. tostring(threshold)),
				string.format("[CER-RELEASE] LO1/07 semantic threshold control missing %d", threshold)
			)
		end
		assert(model:FindFirstChild("Semantic_DecisionDroneBody"), "[CER-RELEASE] LO1/07 semantic drone missing")
		assert(
			model:FindFirstChild("Semantic_DecisionDroneTestConsole"),
			"[CER-RELEASE] LO1/07 semantic test console missing"
		)
		assert(
			model:FindFirstChild("Semantic_DecisionDroneLaunchConsole"),
			"[CER-RELEASE] LO1/07 semantic launch console missing"
		)
	elseif grade == "LO2" and lessonNo == 3 then
		assert(
			semanticLoaded >= 19,
			string.format("[CER-RELEASE] LO2/03 expected >=19 semantic vault controls, got %d", semanticLoaded)
		)
		assert(model:FindFirstChild("Semantic_VaultEntryConsole"), "[CER-RELEASE] LO2/03 entry console missing")
		assert(model:FindFirstChild("Semantic_VaultInstructionBoard"), "[CER-RELEASE] LO2/03 instruction board missing")
		for index = 1, 6 do
			assert(
				model:FindFirstChild("Semantic_VaultBinarySwitch_" .. index),
				string.format("[CER-RELEASE] LO2/03 semantic binary switch %d missing", index)
			)
		end
		for _, key in ipairs({ "tens", "ones" }) do
			for _, suffix in ipairs({ "minus", "plus" }) do
				local semanticName = "Semantic_VaultDecimalAdjustControl_" .. key .. "_" .. suffix
				assert(
					model:FindFirstChild(semanticName),
					string.format("[CER-RELEASE] LO2/03 decimal control missing %s", semanticName)
				)
			end
		end
		for _, key in ipairs({ "high", "low" }) do
			for _, suffix in ipairs({ "minus", "plus" }) do
				local semanticName = "Semantic_VaultHexAdjustControl_" .. key .. "_" .. suffix
				assert(
					model:FindFirstChild(semanticName),
					string.format("[CER-RELEASE] LO2/03 hex control missing %s", semanticName)
				)
			end
		end
		for _, stageId in ipairs({ "BIN", "DEC", "HEX" }) do
			assert(
				model:FindFirstChild("Semantic_VaultValidateControl_" .. stageId),
				string.format("[CER-RELEASE] LO2/03 validate control missing %s", stageId)
			)
		end
	elseif grade == "LO2" and lessonNo == 4 then
		assert(
			semanticLoaded >= 14,
			string.format("[CER-RELEASE] LO2/04 expected >=14 semantic conversion controls, got %d", semanticLoaded)
		)
		local conversionExpected = {
			"Semantic_BinaryConversionConsole",
			"Semantic_HexConversionConsole",
			"Semantic_ReverseConversionConsole",
			"Semantic_BinaryRemainder0",
			"Semantic_BinaryRemainder1",
			"Semantic_BinaryDivisionCrank",
			"Semantic_HexConversionValidate",
			"Semantic_ReverseHexMinus",
			"Semantic_ReverseHexPlus",
			"Semantic_ReverseConversionValidate",
		}
		for _, key in ipairs({ "quotient", "remainder" }) do
			for _, suffix in ipairs({ "Minus", "Plus" }) do
				table.insert(conversionExpected, "Semantic_HexAdjust_" .. key .. "_" .. suffix)
			end
		end
		for _, semanticName in ipairs(conversionExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO2/04 semantic conversion asset missing %s", semanticName)
			)
		end
	elseif grade == "LO2" and lessonNo == 5 then
		assert(
			semanticLoaded >= 15,
			string.format("[CER-RELEASE] LO2/05 expected >=15 semantic rail controls/hardware, got %d", semanticLoaded)
		)
		assert(model:FindFirstChild("Semantic_RailManifestScanner"), "[CER-RELEASE] LO2/05 manifest scanner missing")
		assert(model:FindFirstChild("Semantic_RailDispatchConsole"), "[CER-RELEASE] LO2/05 dispatch console missing")
		assert(model:FindFirstChild("Semantic_RailStageSwitch"), "[CER-RELEASE] LO2/05 stage switch missing")
		for index = 1, 4 do
			assert(
				model:FindFirstChild("Semantic_RailSwapControl_" .. index),
				string.format("[CER-RELEASE] LO2/05 semantic swap control %d missing", index)
			)
		end
		for _, semanticName in ipairs({
			"Semantic_RailSortOrderBoard",
			"Semantic_RailSortCostBoard",
			"Semantic_RailSortStatusBoard",
			"Semantic_RailSortOperatorDesk",
			"Semantic_RailSortOperatorKeyboard",
			"Semantic_RailSortOperatorMouse",
			"Semantic_RailSortStageMonitor",
			"Semantic_RailSortDepartureMonitor",
		}) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO2/05 semantic rail hardware missing %s", semanticName)
			)
		end
	elseif grade == "LO2" and lessonNo == 6 then
		assert(
			semanticLoaded >= 10,
			string.format(
				"[CER-RELEASE] LO2/06 expected >=10 semantic message-lab stations/hardware, got %d",
				semanticLoaded
			)
		)
		for _, semanticName in ipairs({
			"Semantic_MessageCleanScanner",
			"Semantic_MessageReplaceConsole",
			"Semantic_MessageSliceScanner",
			"Semantic_MessagePreviewMonitor",
			"Semantic_MessageOperatorDesk",
			"Semantic_MessageOperatorKeyboard",
			"Semantic_MessageOperatorMouse",
			"Semantic_MessageStageMonitor",
			"Semantic_MessagePipelineRack",
			"Semantic_MessageArchiveMonitor",
		}) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO2/06 semantic message asset missing %s", semanticName)
			)
		end
	elseif grade == "LO2" and lessonNo == 7 then
		assert(
			semanticLoaded >= 10,
			string.format("[CER-RELEASE] LO2/07 expected >=10 semantic forensic controls, got %d", semanticLoaded)
		)
		local forensicExpected = {
			"Semantic_ForensicPatternScanner",
			"Semantic_ForensicPatternControl_Left",
			"Semantic_ForensicPatternControl_Right",
			"Semantic_ForensicPatternControl_Check",
			"Semantic_ForensicCountMonitor",
			"Semantic_ForensicCountControl_Match",
			"Semantic_ForensicCountControl_Skip",
			"Semantic_ForensicPalindromeTerminal",
			"Semantic_ForensicPalindromeControl_Equal",
			"Semantic_ForensicPalindromeControl_Different",
		}
		for _, semanticName in ipairs(forensicExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO2/07 semantic asset missing %s", semanticName)
			)
		end
	elseif grade == "LO2" and lessonNo == 8 then
		assert(
			semanticLoaded >= 14,
			string.format(
				"[CER-RELEASE] LO2/08 expected >=14 semantic cipher controls/hardware, got %d",
				semanticLoaded
			)
		)
		local caesarExpected = {
			"Semantic_CaesarEntryConsole",
			"Semantic_CaesarInstructionBoard",
			"Semantic_CaesarShiftControl_Minus",
			"Semantic_CaesarShiftControl_Plus",
			"Semantic_CaesarShiftControl_Lock",
			"Semantic_CaesarRotorTerminal",
			"Semantic_CaesarModeControl_Toggle",
			"Semantic_CaesarRunControl_Execute",
			"Semantic_CaesarShiftReadoutMonitor",
			"Semantic_CaesarRingMechanismConsole",
			"Semantic_CaesarModeStatusMonitor",
			"Semantic_CaesarRotorDriveRack",
			"Semantic_CaesarVaultStatusMonitor",
			"Semantic_CaesarVaultLockConsole",
		}
		for _, semanticName in ipairs(caesarExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO2/08 semantic asset missing %s", semanticName)
			)
		end
	elseif grade == "LO2" and lessonNo == 9 then
		assert(
			semanticLoaded >= 10,
			string.format("[CER-RELEASE] LO2/09 expected >=10 semantic mail-merge assets, got %d", semanticLoaded)
		)
		assert(
			model:FindFirstChild("Semantic_MailMergeIntakeCrate"),
			"[CER-RELEASE] LO2/09 semantic intake crate missing"
		)
		for index = 1, 3 do
			assert(
				model:FindFirstChild("Semantic_MailMergeMappingControl_" .. index),
				string.format("[CER-RELEASE] LO2/09 mapping control %d missing", index)
			)
			assert(
				model:FindFirstChild("Semantic_MailMergePreviewControl_" .. index),
				string.format("[CER-RELEASE] LO2/09 preview control %d missing", index)
			)
		end
		assert(
			model:FindFirstChild("Semantic_MailMergePrintControl"),
			"[CER-RELEASE] LO2/09 semantic print control missing"
		)
		assert(
			model:FindFirstChild("Semantic_MailMergeMappingConsole"),
			"[CER-RELEASE] LO2/09 semantic mapping console missing"
		)
		assert(model:FindFirstChild("Semantic_MailMergePrinter"), "[CER-RELEASE] LO2/09 semantic printer missing")
	elseif grade == "LO2" and lessonNo == 10 then
		assert(
			semanticLoaded >= 9,
			string.format("[CER-RELEASE] LO2/10 expected >=9 semantic import controls, got %d", semanticLoaded)
		)
		local dataImportExpected = {
			"Semantic_DataDockEntryConsole",
			"Semantic_DataDockInstructionBoard",
			"Semantic_DataDockSeparatorControl",
			"Semantic_DataDockHeaderControl",
			"Semantic_DataDockImportScanner",
			"Semantic_DataDockTypeControl_1",
			"Semantic_DataDockTypeControl_2",
			"Semantic_DataDockTypeControl_3",
			"Semantic_DataDockTypeValidateConsole",
		}
		for _, semanticName in ipairs(dataImportExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO2/10 semantic asset missing %s", semanticName)
			)
		end
	elseif grade == "LO3" and lessonNo == 3 then
		assert(
			semanticLoaded >= 15,
			string.format("[CER-RELEASE] LO3/03 expected >=15 semantic chrono controls, got %d", semanticLoaded)
		)
		assert(
			model:FindFirstChild("Semantic_ChronoTimeSyncConsole"),
			"[CER-RELEASE] LO3/03 semantic time-sync console missing"
		)
		assert(
			model:FindFirstChild("Semantic_ChronoInstructionBoard"),
			"[CER-RELEASE] LO3/03 semantic instruction monitor missing"
		)
		local chronoIds = { "TRANSISTOR", "ARPANET", "MICROCHIP", "WWW" }
		for _, chronoId in ipairs(chronoIds) do
			assert(
				model:FindFirstChild("Semantic_ChronoDialControl_" .. chronoId),
				string.format("[CER-RELEASE] LO3/03 dial control missing %s", chronoId)
			)
			assert(
				model:FindFirstChild("Semantic_ChronoStabilizeControl_" .. chronoId),
				string.format("[CER-RELEASE] LO3/03 stabilize control missing %s", chronoId)
			)
			assert(
				model:FindFirstChild("Semantic_ChronoScanControl_" .. chronoId),
				string.format("[CER-RELEASE] LO3/03 scan control missing %s", chronoId)
			)
		end
		assert(model:FindFirstChild("Semantic_ChronoSyncConsole"), "[CER-RELEASE] LO3/03 sync console missing")
	elseif grade == "LO3" and lessonNo == 4 then
		assert(
			semanticLoaded >= 17,
			string.format("[CER-RELEASE] LO3/04 expected >=17 semantic decision controls, got %d", semanticLoaded)
		)
		assert(
			model:FindFirstChild("Semantic_DecisionCityPlanningConsole"),
			"[CER-RELEASE] LO3/04 semantic planning console missing"
		)
		for _, districtId in ipairs({ "SCHOOL", "OFFICE", "SHOP", "HEALTH" }) do
			for _, profileId in ipairs({ "CLOUD", "LOCAL", "HYBRID" }) do
				local semanticName = "Semantic_DecisionProfileControl_" .. districtId .. "_" .. profileId
				assert(
					model:FindFirstChild(semanticName),
					string.format("[CER-RELEASE] LO3/04 semantic decision control missing %s", semanticName)
				)
			end
			assert(
				model:FindFirstChild("Semantic_DecisionValidateControl_" .. districtId),
				string.format("[CER-RELEASE] LO3/04 semantic validate control missing %s", districtId)
			)
		end
	elseif grade == "LO3" and lessonNo == 5 then
		assert(
			semanticLoaded >= 21,
			string.format("[CER-RELEASE] LO3/05 expected >=21 semantic PC-clinic assets, got %d", semanticLoaded)
		)
		assert(
			model:FindFirstChild("Semantic_PCEmergencyCheckIn"),
			"[CER-RELEASE] LO3/05 semantic check-in scanner missing"
		)
		assert(
			model:FindFirstChild("Semantic_PCEmergencyInstructionBoard"),
			"[CER-RELEASE] LO3/05 semantic instruction monitor missing"
		)
		for _, patientId in ipairs({ "CPU", "DISK", "DRIVER" }) do
			for _, prefix in ipairs({
				"Semantic_PCEmergencyPC_",
				"Semantic_PCEmergencyDesk_",
				"Semantic_PCEmergencyScanner_",
				"Semantic_PCEmergencyRepairConsole_",
				"Semantic_PCEmergencyVerify_",
			}) do
				local semanticName = prefix .. patientId
				assert(
					model:FindFirstChild(semanticName),
					string.format("[CER-RELEASE] LO3/05 semantic clinic asset missing %s", semanticName)
				)
			end
		end
		for _, toolId in ipairs({ "TASK_MANAGER", "CLEANUP", "ROLLBACK" }) do
			assert(
				model:FindFirstChild("Semantic_PCEmergencyTool_" .. toolId),
				string.format("[CER-RELEASE] LO3/05 semantic tool missing %s", toolId)
			)
		end
	elseif grade == "LO3" and lessonNo == 6 then
		assert(
			semanticLoaded >= 7,
			string.format("[CER-RELEASE] LO3/06 expected >=7 semantic internet-yard assets, got %d", semanticLoaded)
		)
		assert(
			model:FindFirstChild("Semantic_InternetSiteCheck"),
			"[CER-RELEASE] LO3/06 semantic site-check console missing"
		)
		assert(
			model:FindFirstChild("Semantic_InternetInstructionBoard"),
			"[CER-RELEASE] LO3/06 semantic instruction monitor missing"
		)
	elseif grade == "LO3" and lessonNo == 7 then
		assert(
			semanticLoaded >= 12,
			string.format("[CER-RELEASE] LO3/07 expected >=12 semantic service-district assets, got %d", semanticLoaded)
		)
		for _, semanticName in ipairs({
			"Semantic_ServiceRequestScanner",
			"Semantic_ServiceDispatchConsole",
			"Semantic_ServiceRequestBoard",
			"Semantic_ServiceBackboneHub",
			"Semantic_ServiceDNSTower",
			"Semantic_ServiceDNSResult",
			"Semantic_ServiceWebServerRack",
			"Semantic_ServiceWebResult",
			"Semantic_ServiceMailPrinter",
			"Semantic_ServiceMailResult",
			"Semantic_ServiceCloudServerRack",
			"Semantic_ServiceCloudResult",
		}) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO3/07 semantic service asset missing %s", semanticName)
			)
		end
	elseif grade == "LO3" and lessonNo == 8 then
		assert(
			semanticLoaded >= 14,
			string.format("[CER-RELEASE] LO3/08 expected >=14 semantic HTML studio assets, got %d", semanticLoaded)
		)
		local htmlAmbient = {
			"Semantic_HTMLDeveloperDesk",
			"Semantic_HTMLDeveloperLaptop",
			"Semantic_HTMLDeveloperMouse",
			"Semantic_HTMLDeveloperChair",
		}
		for _, semanticName in ipairs(htmlAmbient) do
			assert(model:FindFirstChild(semanticName), "[CER-RELEASE] LO3/08 ambient asset missing " .. semanticName)
		end
		for _, tagId in ipairs({ "html", "head", "body", "h1", "p", "a" }) do
			assert(
				model:FindFirstChild("Semantic_HTMLTagControl_" .. tagId),
				string.format("[CER-RELEASE] LO3/08 tag control missing %s", tagId)
			)
		end
		for _, attributeId in ipairs({ "href", "src", "class" }) do
			assert(
				model:FindFirstChild("Semantic_HTMLAttributeControl_" .. attributeId),
				string.format("[CER-RELEASE] LO3/08 attribute control missing %s", attributeId)
			)
		end
		assert(model:FindFirstChild("Semantic_HTMLValidatorControl"), "[CER-RELEASE] LO3/08 validator control missing")
	elseif grade == "LO3" and lessonNo == 9 then
		assert(
			semanticLoaded >= 16,
			string.format("[CER-RELEASE] LO3/09 expected >=16 semantic CSS controls, got %d", semanticLoaded)
		)
		local cssExpected = {
			"Semantic_CSSStyleControl_color_contrast",
			"Semantic_CSSStyleControl_color_low_contrast",
			"Semantic_CSSStyleControl_color_alarm",
			"Semantic_CSSStyleControl_spacing_comfortable",
			"Semantic_CSSStyleControl_spacing_cramped",
			"Semantic_CSSStyleControl_spacing_huge",
			"Semantic_CSSStyleControl_font_readable",
			"Semantic_CSSStyleControl_font_tiny",
			"Semantic_CSSStyleControl_font_decorative",
			"Semantic_CSSStyleControl_border_soft",
			"Semantic_CSSStyleControl_border_none",
			"Semantic_CSSStyleControl_border_heavy",
			"Semantic_CSSStyleControl_layout_flex",
			"Semantic_CSSStyleControl_layout_stacked_bad",
			"Semantic_CSSStyleControl_layout_absolute",
			"Semantic_CSSAuditConsole",
		}
		for _, semanticName in ipairs(cssExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO3/09 semantic CSS control missing %s", semanticName)
			)
		end
	elseif grade == "LO3" and lessonNo == 10 then
		assert(
			semanticLoaded >= 13,
			string.format("[CER-RELEASE] LO3/10 expected >=13 semantic launch controls, got %d", semanticLoaded)
		)
		local launchExpected = {
			"Semantic_LaunchTemplateControl_portfolio",
			"Semantic_LaunchTemplateControl_event",
			"Semantic_LaunchTemplateControl_club",
			"Semantic_LaunchSectionControl_hero",
			"Semantic_LaunchSectionControl_about",
			"Semantic_LaunchSectionControl_contact",
			"Semantic_LaunchStyleControl_coherent",
			"Semantic_LaunchStyleControl_low_contrast",
			"Semantic_LaunchStyleControl_chaos",
			"Semantic_LaunchCTAControl_contact",
			"Semantic_LaunchCTAControl_dead",
			"Semantic_LaunchCTAControl_wrong",
			"Semantic_LaunchConsole",
		}
		for _, semanticName in ipairs(launchExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO3/10 semantic launch control missing %s", semanticName)
			)
		end
	elseif grade == "SP7" and lessonNo == 10 then
		assert(
			semanticLoaded >= 10,
			string.format("[CER-RELEASE] SP7/10 expected >=10 semantic assets, got %d", semanticLoaded)
		)
		local dockExpected = {
			"Semantic_PythonDockRobot",
			"Semantic_PythonDockServerTower",
			"Semantic_PythonDockControlConsole",
			"Semantic_PythonDockStatus",
			"Semantic_PythonDockChipCargo",
			"Semantic_PythonCommandTower_1",
			"Semantic_PythonCommandTower_2",
			"Semantic_PythonCommandTower_3",
			"Semantic_PythonCommandTower_4",
			"Semantic_PythonCommandTower_5",
		}
		for _, semanticName in ipairs(dockExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP7/10 semantic dock asset missing %s", semanticName)
			)
		end
	elseif grade == "SP8" and lessonNo == 5 then
		assert(
			semanticLoaded >= 10,
			string.format("[CER-RELEASE] SP8/05 expected >=10 semantic assets, got %d", semanticLoaded)
		)
		local mazeExpected = {
			"Semantic_PythonMazeRobot",
			"Semantic_PythonMazeServerTower",
			"Semantic_PythonMazeControlConsole",
			"Semantic_PythonMazeStatus",
			"Semantic_PythonMazeSensor",
			"Semantic_PythonMazeChipCargo",
			"Semantic_PythonLaserPost_1_0",
			"Semantic_PythonLaserPost_1_1",
			"Semantic_PythonLaserPost_3_2",
			"Semantic_PythonLaserPost_3_3",
		}
		for _, semanticName in ipairs(mazeExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP8/05 semantic maze asset missing %s", semanticName)
			)
		end
	elseif grade == "SP8" and lessonNo == 6 then
		assert(
			semanticLoaded >= 10,
			string.format("[CER-RELEASE] SP8/06 expected >=10 semantic assets, got %d", semanticLoaded)
		)
		local powerExpected = {
			"Semantic_PythonPowerRobot",
			"Semantic_PythonPowerControlConsole",
			"Semantic_PythonRack",
			"Semantic_PythonPowerStatusMonitor",
			"Semantic_PythonPowerCoreRack",
			"Semantic_PythonPowerTurbineConsole",
			"Semantic_PythonPowerSystemConsole_PUMP",
			"Semantic_PythonPowerSystemConsole_FAN",
			"Semantic_PythonPowerSystemConsole_BRIDGE",
			"Semantic_PythonPowerSystemConsole_CORE",
		}
		for _, semanticName in ipairs(powerExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] SP8/06 semantic power asset missing %s", semanticName)
			)
		end
	elseif grade == "LO1" and lessonNo == 8 then
		assert(
			semanticLoaded >= 17,
			string.format("[CER-RELEASE] LO1/08 expected >=17 semantic logic assets, got %d", semanticLoaded)
		)
		local logicExpected = {
			"Semantic_LogicPowerLever",
			"Semantic_LogicInstructionBoard",
			"Semantic_LogicSwitch_AND_A",
			"Semantic_LogicSwitch_AND_B",
			"Semantic_LogicSwitch_OR_A",
			"Semantic_LogicSwitch_OR_B",
			"Semantic_LogicSwitch_NOT_A",
			"Semantic_LogicGateHardware_AND",
			"Semantic_LogicGateHardware_OR",
			"Semantic_LogicGateHardware_NOT",
			"Semantic_LogicOutputMonitor_AND",
			"Semantic_LogicOutputMonitor_OR",
			"Semantic_LogicOutputMonitor_NOT",
			"Semantic_LogicTestControl_AND",
			"Semantic_LogicTestControl_OR",
			"Semantic_LogicTestControl_NOT",
			"Semantic_LogicCoreRack",
		}
		for _, semanticName in ipairs(logicExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO1/08 semantic logic asset missing %s", semanticName)
			)
		end
	elseif grade == "LO1" and lessonNo == 9 then
		assert(
			semanticLoaded >= 11,
			string.format("[CER-RELEASE] LO1/09 expected >=11 semantic factory assets, got %d", semanticLoaded)
		)
		local loopExpected = {
			"Semantic_LoopFactoryControlConsole",
			"Semantic_LoopFactoryAutomationRack",
			"Semantic_LoopFactoryShippingCrate",
			"Semantic_LoopFactoryStamper",
			"Semantic_LoopFactoryScannerTop",
		}
		for packageIndex = 1, 6 do
			table.insert(loopExpected, "Semantic_LoopFactoryPackage_" .. packageIndex)
		end
		for _, semanticName in ipairs(loopExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO1/09 semantic factory asset missing %s", semanticName)
			)
		end
	elseif grade == "LO1" and lessonNo == 10 then
		assert(
			semanticLoaded >= 24,
			string.format("[CER-RELEASE] LO1/10 expected >=24 semantic assets, got %d", semanticLoaded)
		)
		local sequenceExpected = {
			"Semantic_SequenceRepairScanner",
			"Semantic_SequenceGeneratorControlConsole",
			"Semantic_SequenceReactorOverviewScreen",
			"Semantic_SequenceRuleMinus",
			"Semantic_SequenceRulePlus",
			"Semantic_SequenceNextLever",
			"Semantic_SequenceRepairMinus",
			"Semantic_SequenceRepairPlus",
			"Semantic_SequenceRepairTest",
			"Semantic_SequenceGenerator_start",
			"Semantic_SequenceGenerator_step",
			"Semantic_SequenceGenerator_count",
			"Semantic_SequenceGenerateButton",
		}
		for index = 1, 5 do
			table.insert(sequenceExpected, "Semantic_SequenceRepairScanControl_" .. index)
		end
		for _, key in ipairs({ "start", "step", "count" }) do
			table.insert(sequenceExpected, "Semantic_SequenceGeneratorMinus_" .. key)
			table.insert(sequenceExpected, "Semantic_SequenceGeneratorPlus_" .. key)
		end
		for _, semanticName in ipairs(sequenceExpected) do
			assert(
				model:FindFirstChild(semanticName),
				string.format("[CER-RELEASE] LO1/10 semantic sequence asset missing %s", semanticName)
			)
		end
	end

	local prompts = enabledMissionPrompts(model)
	local promptCount = #prompts
	for _, missionPrompt in ipairs(prompts) do
		assert(
			not missionPrompt.RequiresLineOfSight,
			string.format(
				"[CER-RELEASE] active prompt requires line of sight %s/%02d object=%s",
				grade,
				lessonNo,
				missionPrompt.ObjectText
			)
		)
	end
	local firstActionDistance = -1
	if expectPrompt then
		assert(promptCount >= 1, string.format("[CER-RELEASE] no initial enabled interaction %s/%02d", grade, lessonNo))
		local firstPrompt, distance = nearestEnabledPrompt(player, model)
		assert(firstPrompt, string.format("[CER-RELEASE] no reachable initial prompt %s/%02d", grade, lessonNo))
		firstActionDistance = distance
		if grade == "LO3" and lessonNo == 7 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO3/07 entry scanner too far %.1f studs", distance))
		elseif grade == "LO3" and lessonNo == 3 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO3/03 time-sync console too far %.1f studs", distance))
		elseif grade == "SP7" and lessonNo == 5 then
			assert(distance <= 24, string.format("[CER-RELEASE] SP7/05 entry scanner too far %.1f studs", distance))
		elseif grade == "SP4" and lessonNo == 6 then
			assert(distance <= 24, string.format("[CER-RELEASE] SP4/06 shield arm lever too far %.1f studs", distance))
		elseif grade == "SP4" and lessonNo == 7 then
			assert(
				promptCount == 1,
				string.format("[CER-RELEASE] SP4/07 expected one initial SOURCE prompt, got %d", promptCount)
			)
			assert(distance <= 24, string.format("[CER-RELEASE] SP4/07 source evidence too far %.1f studs", distance))
		elseif grade == "SP8" and lessonNo == 4 then
			assert(distance <= 24, string.format("[CER-RELEASE] SP8/04 entry console too far %.1f studs", distance))
		elseif grade == "SP8" and lessonNo == 7 then
			assert(distance <= 24, string.format("[CER-RELEASE] SP8/07 entry console too far %.1f studs", distance))
		elseif grade == "SP8" and lessonNo == 8 then
			assert(
				promptCount == 1,
				string.format(
					"[CER-RELEASE] SP8/08 expected one initial START WYSZUKIWANIA prompt, got %d",
					promptCount
				)
			)
			assert(distance <= 24, string.format("[CER-RELEASE] SP8/08 entry console too far %.1f studs", distance))
		elseif grade == "SP8" and lessonNo == 9 then
			assert(
				distance <= 24,
				string.format("[CER-RELEASE] SP8/09 calibration console too far %.1f studs", distance)
			)
		elseif grade == "SP4" and lessonNo == 5 then
			assert(distance <= 24, string.format("[CER-RELEASE] SP4/05 laptop upload too far %.1f studs", distance))
		elseif grade == "SP5" and lessonNo == 3 then
			assert(distance <= 24, string.format("[CER-RELEASE] SP5/03 ticket scanner too far %.1f studs", distance))
		elseif grade == "SP5" and lessonNo == 7 then
			assert(
				promptCount == 1,
				string.format("[CER-RELEASE] SP5/07 expected one initial START DIAGNOZY prompt, got %d", promptCount)
			)
			assert(distance <= 24, string.format("[CER-RELEASE] SP5/07 entry console too far %.1f studs", distance))
		elseif grade == "SP6" and lessonNo == 4 then
			assert(
				promptCount == 1,
				string.format("[CER-RELEASE] SP6/04 expected one initial START MONTAŻU prompt, got %d", promptCount)
			)
			assert(distance <= 24, string.format("[CER-RELEASE] SP6/04 entry console too far %.1f studs", distance))
		elseif grade == "SP6" and lessonNo == 5 then
			assert(
				promptCount == 1,
				string.format("[CER-RELEASE] SP6/05 expected one initial START SESJI prompt, got %d", promptCount)
			)
			assert(distance <= 24, string.format("[CER-RELEASE] SP6/05 entry console too far %.1f studs", distance))
		elseif grade == "LO2" and lessonNo == 3 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO2/03 entry console too far %.1f studs", distance))
		elseif grade == "LO2" and lessonNo == 5 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO2/05 manifest scanner too far %.1f studs", distance))
		elseif grade == "LO2" and lessonNo == 8 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO2/08 entry console too far %.1f studs", distance))
		elseif grade == "LO2" and lessonNo == 9 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO2/09 intake crate too far %.1f studs", distance))
		elseif grade == "LO2" and lessonNo == 10 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO2/10 intake console too far %.1f studs", distance))
		elseif grade == "SP6" and lessonNo == 7 then
			assert(distance <= 24, string.format("[CER-RELEASE] SP6/07 start program too far %.1f studs", distance))
		elseif grade == "LO1" and lessonNo == 3 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO1/03 manifest scanner too far %.1f studs", distance))
		elseif grade == "LO1" and lessonNo == 6 then
			assert(
				distance <= 24,
				string.format("[CER-RELEASE] LO1/06 calibration console too far %.1f studs", distance)
			)
		elseif grade == "LO1" and lessonNo == 7 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO1/07 power console too far %.1f studs", distance))
		elseif grade == "LO1" and lessonNo == 8 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO1/08 power lever too far %.1f studs", distance))
		elseif grade == "LO1" and lessonNo == 10 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO1/10 tutorial controls too far %.1f studs", distance))
		elseif grade == "LO3" and lessonNo == 4 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO3/04 planning console too far %.1f studs", distance))
		elseif grade == "LO3" and lessonNo == 5 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO3/05 check-in too far %.1f studs", distance))
		elseif grade == "LO3" and lessonNo == 6 then
			assert(distance <= 24, string.format("[CER-RELEASE] LO3/06 site-check too far %.1f studs", distance))
		end
		assert(
			distance <= MAX_FIRST_ACTION_DISTANCE,
			string.format(
				"[CER-RELEASE] first action too far %s/%02d distance=%.1f max=%d",
				grade,
				lessonNo,
				distance,
				MAX_FIRST_ACTION_DISTANCE
			)
		)
		assert(
			firstPrompt.MaxActivationDistance >= MIN_PROMPT_ACTIVATION_DISTANCE,
			string.format(
				"[CER-RELEASE] first prompt activation too short %s/%02d activation=%.1f min=%d",
				grade,
				lessonNo,
				firstPrompt.MaxActivationDistance,
				MIN_PROMPT_ACTIVATION_DISTANCE
			)
		)
		assert(
			firstPrompt.ActionText ~= "" and firstPrompt.ObjectText ~= "",
			string.format("[CER-RELEASE] first prompt missing action/object text %s/%02d", grade, lessonNo)
		)
	end

	if index == 1 then
		local originalModel = model
		clientReports[player] = nil
		MissionEngine.Start(player, lesson, mission, missionInfo)
		local restartedModel = waitForModel(player)
		assert(
			restartedModel and restartedModel ~= originalModel,
			"[CER-RELEASE] same-title restart did not replace mission model"
		)
		task.wait(0.35)
		local restartReport = waitForClientReport(player)
		assert(restartReport, "[CER-RELEASE] no client report after same-title restart")
		assert(
			restartReport.firstActionGuideVisible,
			"[CER-RELEASE] First Action Guide missing after same-title restart"
		)
		assert(
			restartReport.firstActionBeaconVisible,
			"[CER-RELEASE] First Action beacon missing after same-title restart"
		)
		print("[CER-RELEASE] RESTART_GUIDE_OK SP4/03")

		clientReports[player] = nil
		local previousCharacter = player.Character
		player:LoadCharacter()
		local respawnedCharacter = waitForCharacterReplacement(player, previousCharacter)
		assert(respawnedCharacter, "[CER-RELEASE] character did not respawn")
		local respawnedRoot = respawnedCharacter:WaitForChild("HumanoidRootPart", 8)
		local respawnedHumanoid = respawnedCharacter:WaitForChild("Humanoid", 8)
		assert(
			respawnedRoot and respawnedHumanoid and respawnedHumanoid.Health > 0,
			"[CER-RELEASE] invalid respawned character"
		)
		task.wait(0.45)

		assert(currentModel(player) == restartedModel, "[CER-RELEASE] mission model lost across respawn")
		local restartPad = restartedModel:FindFirstChild("StartPad", true)
		assert(restartPad and restartPad:IsA("BasePart"), "[CER-RELEASE] StartPad missing after respawn")
		local respawnDistance = (respawnedRoot.Position - (restartPad.Position + Vector3.new(0, 3, 0))).Magnitude
		assert(
			respawnDistance <= MAX_RESPAWN_DISTANCE,
			string.format(
				"[CER-RELEASE] respawn outside mission start distance=%.1f max=%d",
				respawnDistance,
				MAX_RESPAWN_DISTANCE
			)
		)

		local respawnReport = waitForClientReport(player)
		assert(respawnReport, "[CER-RELEASE] no client report after respawn")
		assert(
			respawnReport.cameraCustom and respawnReport.cameraClassic,
			"[CER-RELEASE] camera not restored after respawn"
		)
		assert(
			respawnReport.hudObjectiveVisible and respawnReport.hudObjectivePrefix,
			"[CER-RELEASE] CEL HUD not restored after respawn"
		)
		assert(respawnReport.hudObjectiveFits, "[CER-RELEASE] CEL clipped after respawn")
		assert(respawnReport.firstActionGuideVisible, "[CER-RELEASE] First Action Guide missing after respawn")
		assert(respawnReport.firstActionBeaconVisible, "[CER-RELEASE] First Action beacon missing after respawn")
		assert(not respawnReport.hiddenFocusedTextBox, "[CER-RELEASE] hidden TextBox focused after respawn")
		print(string.format("[CER-RELEASE] RESPAWN_OK SP4/03 distance=%.1f", respawnDistance))
	end

	print(
		string.format(
			"[CER-RELEASE] PASS %02d/%02d %s/%02d %s variant=%s prompts=%d first=%.1f client=1 input=1 constraints=1 world=%d walk=%.1f ground=%.1f semantic=%d/%d descendants=%d",
			index,
			#MATRIX,
			grade,
			lessonNo,
			label,
			tostring(variant),
			promptCount,
			firstActionDistance,
			clientReport.worldTextCount,
			walkSpeed,
			groundDistance,
			semanticLoaded,
			semanticCandidates,
			descendants
		)
	)
end

local function run(player)
	task.wait(0.5)
	assert(waitForClientReady(player), "[CER-RELEASE] client probe did not become ready")
	print("[CER-RELEASE] BUILD_ID " .. RELEASE_BUILD_ID)
	print(string.format("[CER-RELEASE] START representative matrix families=%d", #MATRIX))

	for index, case in ipairs(MATRIX) do
		local ok, err = pcall(runCase, player, case, index)
		if not ok then
			warn(string.format("[CER-RELEASE] FAIL %02d/%02d %s", index, #MATRIX, tostring(err)))
			error(err)
		end
		task.wait(0.15)
	end

	MissionEngine.Stop(player)
	print(string.format("[CER-RELEASE] ALL_OK families=%d", #MATRIX))
	print("[CER-RELEASE] MANUAL_GATE camera rotation + zoom 5-16 + HUD/CEL + world text + First Action Guide/beacon")
end

Players.PlayerAdded:Connect(function(player)
	task.defer(run, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(run, player)
end