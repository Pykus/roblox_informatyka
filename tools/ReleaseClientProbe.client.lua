local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local missionInfo = remotes:WaitForChild("MissionInfo")
local reportRemote = remotes:WaitForChild("ReleaseSmokeClientReport")

local latestHudMessage = nil
local reportScheduled = false
local recoveryProbeDone = false
local recoveryProbeScheduled = false
local cameraReplacementProbeDone = false
local inputRecoveryProbeDone = false
local inputRecoveryProbePassed = false
local inputRecoveryProbeScheduled = false
local constraintRecoveryProbeDone = false
local constraintRecoveryProbePassed = false
local constraintRecoveryProbeScheduled = false

local function isVisible(object)
	if not object or not object:IsA("GuiObject") or not object.Visible then
		return false
	end
	local parent = object.Parent
	while parent and parent ~= playerGui do
		if parent:IsA("GuiObject") and not parent.Visible then
			return false
		end
		if parent:IsA("LayerCollector") and not parent.Enabled then
			return false
		end
		parent = parent.Parent
	end
	return parent == playerGui
end

local function findObjective()
	local gui = playerGui:FindFirstChild("CyberEscapeMenu")
	if not gui then
		return nil
	end
	for _, object in ipairs(gui:GetDescendants()) do
		if object:IsA("TextLabel") and object.Text:sub(1, 4) == "CEL:" and isVisible(object) then
			return object
		end
	end
	return nil
end

local function textConstraintStatus(object, minimum)
	local count = 0
	local limit = nil
	for _, child in ipairs(object:GetChildren()) do
		if child:IsA("UITextSizeConstraint") then
			count += 1
			limit = child
		end
	end
	if count ~= 1 or not limit then
		return false, string.format("%s constraint-count=%d", object:GetFullName(), count)
	end
	if limit.MinTextSize < minimum then
		return false, string.format("%s min=%d", object:GetFullName(), limit.MinTextSize)
	end
	return true, ""
end

local function scaledTextReadable()
	for _, object in ipairs(playerGui:GetDescendants()) do
		if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.TextScaled then
			local ok, problem = textConstraintStatus(object, 16)
			if not ok then
				return false, problem
			end
		end
	end
	return true, ""
end

local function panelVisible(guiName, panelName)
	local gui = playerGui:FindFirstChild(guiName)
	local panel = gui and gui:FindFirstChild(panelName)
	return panel ~= nil and panel:IsA("GuiObject") and panel.Visible
end

local function missionRoot()
	local container = workspace:FindFirstChild("PlayerMissions")
	if container then
		return container:FindFirstChild("Mission_" .. player.UserId)
	end
	return workspace:FindFirstChild("Mission_" .. player.UserId)
end

local function worldGuiTextVisible(object, gui)
	if not gui.Enabled or not object.Visible then
		return false
	end
	if object.AbsoluteSize.X <= 0 or object.AbsoluteSize.Y <= 0 then
		return false
	end
	local parent = object.Parent
	while parent and parent ~= gui do
		if parent:IsA("GuiObject") and not parent.Visible then
			return false
		end
		parent = parent.Parent
	end
	return parent == gui
end

local function worldTextReadable()
	local mission = missionRoot()
	if not mission then
		return false, "mission root missing", 0
	end

	local count = 0
	for _, object in ipairs(mission:GetDescendants()) do
		if (object:IsA("SurfaceGui") or object:IsA("BillboardGui")) and object.Enabled then
			if object.LightInfluence > 0.01 then
				return false, object:GetFullName() .. " light influence", count
			end
			if object.Brightness < 1.09 then
				return false, object:GetFullName() .. " brightness below 1.1", count
			end
		end
		if object:IsA("TextLabel") or object:IsA("TextButton") then
			local gui = object:FindFirstAncestorWhichIsA("SurfaceGui")
				or object:FindFirstAncestorWhichIsA("BillboardGui")
			if gui and worldGuiTextVisible(object, gui) then
				count += 1
				if object.TextScaled then
					local ok, problem = textConstraintStatus(object, 18)
					if not ok then
						return false, problem, count
					end
				elseif object.TextSize < 18 then
					return false, object:GetFullName() .. " fixed below 18", count
				end
				if object.TextStrokeTransparency > 0.66 then
					return false, object:GetFullName() .. " missing contrast stroke", count
				end
				if
					object.TextBounds.X > object.AbsoluteSize.X + 1
					or object.TextBounds.Y > object.AbsoluteSize.Y + 1
				then
					return false,
						string.format(
							"%s text bounds clipped bounds=%.0fx%.0f size=%.0fx%.0f",
							object:GetFullName(),
							object.TextBounds.X,
							object.TextBounds.Y,
							object.AbsoluteSize.X,
							object.AbsoluteSize.Y
						),
						count
				end
			end
		end
	end

	return count > 0, count > 0 and "" or "no world text found", count
end

local function scheduleConstraintRecoveryProbe()
	if constraintRecoveryProbeDone or constraintRecoveryProbeScheduled then
		return
	end
	constraintRecoveryProbeScheduled = true
	task.delay(0.35, function()
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "CER_ConstraintProbe"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui

		local screenLabel = Instance.new("TextLabel")
		screenLabel.Name = "LateScreenConstraintProbe"
		screenLabel.Size = UDim2.fromOffset(180, 40)
		screenLabel.Text = "constraint"
		screenLabel.TextScaled = true
		screenLabel.Parent = screenGui

		local worldPart = Instance.new("Part")
		worldPart.Name = "CER_WorldConstraintProbe"
		worldPart.Anchored = true
		worldPart.CanCollide = false
		worldPart.Transparency = 1
		worldPart.Position = Vector3.new(0, -500, 0)
		worldPart.Parent = workspace

		local surface = Instance.new("SurfaceGui")
		surface.Face = Enum.NormalId.Front
		surface.Parent = worldPart

		local worldLabel = Instance.new("TextLabel")
		worldLabel.Name = "LateWorldConstraintProbe"
		worldLabel.Size = UDim2.fromScale(1, 1)
		worldLabel.Text = "constraint"
		worldLabel.TextScaled = true
		worldLabel.Parent = surface

		task.wait(0.18)

		local lateScreen = Instance.new("UITextSizeConstraint")
		lateScreen.MinTextSize = 4
		lateScreen.MaxTextSize = 12
		lateScreen.Parent = screenLabel

		local lateWorld = Instance.new("UITextSizeConstraint")
		lateWorld.MinTextSize = 4
		lateWorld.MaxTextSize = 12
		lateWorld.Parent = worldLabel

		task.wait(0.4)
		local screenOk = select(1, textConstraintStatus(screenLabel, 16))
		local worldOk = select(1, textConstraintStatus(worldLabel, 18))
		constraintRecoveryProbePassed = screenOk and worldOk and surface.LightInfluence <= 0.01
		constraintRecoveryProbeDone = true

		screenGui:Destroy()
		worldPart:Destroy()
		constraintRecoveryProbeScheduled = false
	end)
end

local function waitForFocusState(textBox, shouldFocus, timeout)
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		local focused = UserInputService:GetFocusedTextBox() == textBox
		if focused == shouldFocus then
			return true
		end
		task.wait()
	end
	return (UserInputService:GetFocusedTextBox() == textBox) == shouldFocus
end

local function scheduleInputRecoveryProbe()
	if inputRecoveryProbeDone or inputRecoveryProbeScheduled then
		return
	end
	inputRecoveryProbeScheduled = true
	task.delay(0.3, function()
		local probeGui = Instance.new("ScreenGui")
		probeGui.Name = "CER_InputFocusProbe"
		probeGui.ResetOnSpawn = false
		probeGui.Parent = playerGui

		local probeBox = Instance.new("TextBox")
		probeBox.Name = "HiddenFocusProbe"
		probeBox.Size = UDim2.fromOffset(120, 32)
		probeBox.Position = UDim2.fromOffset(-1000, -1000)
		probeBox.Text = "focus"
		probeBox.Parent = probeGui
		probeBox:CaptureFocus()

		local captured = waitForFocusState(probeBox, true, 0.6)
		probeBox.Visible = false
		local released = waitForFocusState(probeBox, false, 0.8)
		inputRecoveryProbePassed = captured and released
		inputRecoveryProbeDone = true

		if UserInputService:GetFocusedTextBox() == probeBox then
			probeBox:ReleaseFocus()
		end
		probeGui:Destroy()
		inputRecoveryProbeScheduled = false
	end)
end

local function scheduleCameraRecoveryProbe()
	if recoveryProbeDone or recoveryProbeScheduled then
		return
	end
	recoveryProbeScheduled = true
	task.delay(0.25, function()
		local replacement = Instance.new("Camera")
		replacement.Name = "CER_CameraRecoveryProbe"
		replacement.CameraType = Enum.CameraType.Scriptable
		replacement.FieldOfView = 95
		replacement.Parent = workspace
		workspace.CurrentCamera = replacement
		cameraReplacementProbeDone = workspace.CurrentCamera == replacement
		player.CameraMinZoomDistance = 12
		player.CameraMaxZoomDistance = 48
		recoveryProbeDone = true
		recoveryProbeScheduled = false
	end)
end

local function waitForRecoveryProbes()
	local deadline = os.clock() + 3.0
	while os.clock() < deadline do
		if recoveryProbeDone and inputRecoveryProbeDone and constraintRecoveryProbeDone then
			return
		end
		task.wait(0.05)
	end
end

local function waitForFirstActionGuide()
	local mission = missionRoot()
	if not mission then
		return
	end

	local hasEnabledPrompt = false
	for _, object in ipairs(mission:GetDescendants()) do
		if object:IsA("ProximityPrompt") and object.Enabled then
			hasEnabledPrompt = true
			break
		end
	end
	if not hasEnabledPrompt then
		return
	end

	local deadline = os.clock() + 1.5
	while os.clock() < deadline do
		local guide = playerGui:FindFirstChild("CER_FirstActionGuide", true)
		local beacon = workspace:FindFirstChild("CER_FirstActionBeacon", true)
		if guide and guide:IsA("BillboardGui") and guide.Enabled and beacon and beacon:IsA("BasePart") then
			return
		end
		task.wait(0.05)
	end
end

local function sendReport(message)
	latestHudMessage = message
	scheduleCameraRecoveryProbe()
	scheduleInputRecoveryProbe()
	scheduleConstraintRecoveryProbe()

	if reportScheduled then
		return
	end
	reportScheduled = true

	task.delay(1.1, function()
		waitForRecoveryProbes()
		waitForFirstActionGuide()
		reportScheduled = false
		local currentMessage = latestHudMessage
		if not currentMessage then
			return
		end

		local camera = workspace.CurrentCamera
		local objective = findObjective()
		local objectiveFits = objective ~= nil
			and objective.TextBounds.X <= objective.AbsoluteSize.X + 1
			and objective.TextBounds.Y <= objective.AbsoluteSize.Y + 1
		local readable, problem = scaledTextReadable()
		local worldReadable, worldProblem, worldCount = worldTextReadable()
		local guide = playerGui:FindFirstChild("CER_FirstActionGuide", true)
		local beacon = workspace:FindFirstChild("CER_FirstActionBeacon", true)
		local missionNotification = playerGui:FindFirstChild("MissionNotification", true)
		local focused = UserInputService:GetFocusedTextBox()
		local hiddenFocusedTextBox = focused ~= nil and not isVisible(focused)

		reportRemote:FireServer({
			title = tostring(currentMessage.title or ""),
			cameraCustom = camera ~= nil and camera.CameraType == Enum.CameraType.Custom,
			cameraClassic = player.CameraMode == Enum.CameraMode.Classic,
			cameraMin = player.CameraMinZoomDistance,
			cameraMax = player.CameraMaxZoomDistance,
			cameraFov = camera and camera.FieldOfView or -1,
			cameraSubjectHumanoid = camera ~= nil and camera.CameraSubject ~= nil and camera.CameraSubject:IsA(
				"Humanoid"
			),
			cameraRecoveryProbeDone = recoveryProbeDone,
			cameraReplacementProbeDone = cameraReplacementProbeDone,
			inputRecoveryProbeDone = inputRecoveryProbeDone,
			inputRecoveryProbePassed = inputRecoveryProbePassed,
			constraintRecoveryProbeDone = constraintRecoveryProbeDone,
			constraintRecoveryProbePassed = constraintRecoveryProbePassed,
			hiddenFocusedTextBox = hiddenFocusedTextBox,
			focusedTextBox = focused and focused:GetFullName() or "",
			hudObjectiveVisible = objective ~= nil,
			hudObjectivePrefix = objective ~= nil and objective.Text:sub(1, 4) == "CEL:",
			hudObjectiveTextSize = objective and objective.TextSize or -1,
			hudObjectiveFits = objectiveFits,
			hudObjectiveBoundsX = objective and objective.TextBounds.X or -1,
			hudObjectiveBoundsY = objective and objective.TextBounds.Y or -1,
			hudObjectiveWidth = objective and objective.AbsoluteSize.X or -1,
			hudObjectiveHeight = objective and objective.AbsoluteSize.Y or -1,
			scaledTextReadable = readable,
			scaledTextProblem = problem,
			worldTextReadable = worldReadable,
			worldTextProblem = worldProblem,
			worldTextCount = worldCount,
			firstActionGuideVisible = guide ~= nil and guide:IsA("BillboardGui") and guide.Enabled,
			firstActionBeaconVisible = beacon ~= nil
				and beacon:IsA("BasePart")
				and beacon.Transparency < 0.9
				and not beacon.CanCollide,
			spuriousMissionUpdateVisible = missionNotification ~= nil
				and missionNotification:IsA("TextLabel")
				and missionNotification.Visible
				and missionNotification.Text == "Aktualizacja misji",
			missionNotificationText = missionNotification and missionNotification.Text or "",
			pythonConsoleVisible = panelVisible("PythonConsoleGui", "Panel"),
			typingUiPresent = playerGui:FindFirstChild("TypingTerminalUI") ~= nil,
		})
	end)
end

missionInfo.OnClientEvent:Connect(function(message)
	if type(message) == "table" and message.kind == "hud" then
		sendReport(message)
	end
end)

reportRemote:FireServer({ ready = true })
print("[CER-RELEASE] Client probe ready")