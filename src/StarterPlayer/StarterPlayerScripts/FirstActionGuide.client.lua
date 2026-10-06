local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local missionInfo = ReplicatedStorage:WaitForChild("GameRemotes"):WaitForChild("MissionInfo")

local MAX_GUIDE_DISTANCE = 120
local GUIDE_LIFETIME = 20
local RETRY_COUNT = 30
local RETRY_DELAY = 0.15

local activeMissionTitle = nil
local activeMissionRoot = nil
local guideToken = 0
local highlight = nil
local billboard = nil
local beacon = nil
local beaconTween = nil
local guidedPrompt = nil
local guideFinishedForMission = false
local missionDescendantConnection = nil
local missionContainerConnection = nil
local promptEnabledConnections = {}
local promptSemanticConnections = {}
local disconnectMissionWatchers

local function clearGuide()
	guidedPrompt = nil
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
	if billboard then
		billboard:Destroy()
		billboard = nil
	end
	if beaconTween then
		beaconTween:Cancel()
		beaconTween = nil
	end
	if beacon then
		beacon:Destroy()
		beacon = nil
	end
end

local function rootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function missionRoot()
	local container = workspace:FindFirstChild("PlayerMissions")
	if container then
		return container:FindFirstChild("Mission_" .. player.UserId)
	end
	return workspace:FindFirstChild("Mission_" .. player.UserId)
end

local function preferredMissionRoot()
	if activeMissionRoot and activeMissionRoot.Parent then
		return activeMissionRoot
	end
	return missionRoot()
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

local function semanticVisual(part)
	if not part or not part:GetAttribute("SemanticAssetId") or part:GetAttribute("SemanticAssetFallback") ~= false then
		return nil
	end
	local mission = preferredMissionRoot()
	if not mission then
		return nil
	end
	return mission:FindFirstChild("Semantic_" .. part.Name)
end

local function hasVisiblePromptAnchor(part)
	if not part then
		return false
	end
	if part.Transparency < 1 then
		return true
	end
	return semanticVisual(part) ~= nil
end

local function isUsable(prompt)
	if not prompt:IsA("ProximityPrompt") or not prompt.Enabled then
		return false
	end
	if not prompt:IsDescendantOf(workspace) then
		return false
	end
	return hasVisiblePromptAnchor(promptPart(prompt))
end

local function nearestPrompt()
	local root = rootPart()
	local mission = preferredMissionRoot()
	if not root or not mission then
		return nil
	end

	local bestPrompt = nil
	local bestDistance = MAX_GUIDE_DISTANCE
	for _, object in ipairs(mission:GetDescendants()) do
		if object:IsA("ProximityPrompt") and isUsable(object) then
			local part = promptPart(object)
			local distance = (part.Position - root.Position).Magnitude
			if distance < bestDistance then
				bestPrompt = object
				bestDistance = distance
			end
		end
	end
	return bestPrompt
end

local function guideText(prompt)
	local action = prompt.ActionText ~= "" and prompt.ActionText or "INTERAKCJA"
	local objectText = prompt.ObjectText
	if objectText ~= "" then
		return string.format("▼  ZACZNIJ TUTAJ\n%s • %s", action, objectText)
	end
	return string.format("▼  ZACZNIJ TUTAJ\n%s", action)
end

local function showGuide(prompt, token)
	if token ~= guideToken or not prompt or not prompt.Parent then
		return
	end

	local part = promptPart(prompt)
	if not part then
		return
	end

	clearGuide()
	guidedPrompt = prompt

	local visual = semanticVisual(part)
	highlight = Instance.new("Highlight")
	highlight.Name = "CER_FirstActionHighlight"
	highlight.Adornee = visual or part
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.fromRGB(75, 190, 255)
	highlight.FillTransparency = 0.72
	highlight.OutlineColor = Color3.fromRGB(245, 252, 255)
	highlight.OutlineTransparency = 0
	highlight.Parent = visual or part

	beacon = Instance.new("Part")
	beacon.Name = "CER_FirstActionBeacon"
	beacon.Anchored = true
	beacon.CanCollide = false
	beacon.CanQuery = false
	beacon.CanTouch = false
	beacon.CastShadow = false
	beacon.Material = Enum.Material.Neon
	beacon.Color = Color3.fromRGB(75, 190, 255)
	beacon.Size = Vector3.new(0.7, 16, 0.7)
	beacon.Transparency = 0.38
	beacon.CFrame = CFrame.new(part.Position + Vector3.new(0, math.max(9, part.Size.Y * 0.5 + 8), 0))
	beacon.Parent = workspace

	local beaconLight = Instance.new("PointLight")
	beaconLight.Color = beacon.Color
	beaconLight.Brightness = 2
	beaconLight.Range = 12
	beaconLight.Shadows = false
	beaconLight.Parent = beacon

	beaconTween = TweenService:Create(
		beacon,
		TweenInfo.new(0.72, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.68, Size = Vector3.new(1.05, 16, 1.05) }
	)
	beaconTween:Play()

	billboard = Instance.new("BillboardGui")
	billboard.Name = "CER_FirstActionGuide"
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = MAX_GUIDE_DISTANCE + 20
	billboard.Size = UDim2.fromOffset(260, 76)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, math.max(4, part.Size.Y * 0.65 + 2), 0)
	billboard.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("TextLabel")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(8, 28, 48)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.TextColor3 = Color3.fromRGB(245, 252, 255)
	panel.Text = guideText(prompt)
	panel.TextWrapped = true
	panel.TextScaled = true
	panel.Font = Enum.Font.GothamBold
	panel.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 200, 255)
	stroke.Thickness = 2
	stroke.Parent = panel

	local sizeConstraint = Instance.new("UITextSizeConstraint")
	sizeConstraint.MinTextSize = 16
	sizeConstraint.MaxTextSize = 24
	sizeConstraint.Parent = panel

	task.delay(GUIDE_LIFETIME, function()
		if token == guideToken then
			guideFinishedForMission = true
			disconnectMissionWatchers()
			clearGuide()
		end
	end)
end

disconnectMissionWatchers = function()
	if missionDescendantConnection then
		missionDescendantConnection:Disconnect()
		missionDescendantConnection = nil
	end
	for prompt, connection in pairs(promptEnabledConnections) do
		connection:Disconnect()
		promptEnabledConnections[prompt] = nil
	end
	for prompt, connection in pairs(promptSemanticConnections) do
		connection:Disconnect()
		promptSemanticConnections[prompt] = nil
	end
end

local function tryShowNearestGuide(token)
	if token ~= guideToken or not activeMissionTitle or guideFinishedForMission then
		return false
	end
	if guidedPrompt and isUsable(guidedPrompt) then
		return true
	end
	local prompt = nearestPrompt()
	if not prompt then
		return false
	end
	showGuide(prompt, token)
	return guidedPrompt ~= nil
end

local function recoverGuideForPrompt(prompt)
	if not activeMissionTitle or guidedPrompt or guideFinishedForMission then
		return
	end
	local mission = preferredMissionRoot()
	if not mission or not prompt:IsDescendantOf(mission) then
		return
	end
	task.defer(function()
		if activeMissionTitle and not guidedPrompt and not guideFinishedForMission and prompt.Parent then
			tryShowNearestGuide(guideToken)
		end
	end)
end

local function watchPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or promptEnabledConnections[prompt] then
		return
	end
	recoverGuideForPrompt(prompt)
	promptEnabledConnections[prompt] = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
		if prompt.Enabled then
			recoverGuideForPrompt(prompt)
		end
	end)
	local part = promptPart(prompt)
	if part then
		promptSemanticConnections[prompt] = part:GetAttributeChangedSignal("SemanticAssetId"):Connect(function()
			if prompt.Enabled then
				recoverGuideForPrompt(prompt)
			end
		end)
	end
end

local function watchMissionPrompts(mission)
	disconnectMissionWatchers()
	if not mission then
		return
	end
	for _, object in ipairs(mission:GetDescendants()) do
		if object:IsA("ProximityPrompt") then
			watchPrompt(object)
		end
	end
	missionDescendantConnection = mission.DescendantAdded:Connect(function(object)
		if object:IsA("ProximityPrompt") then
			watchPrompt(object)
		end
	end)
end

local function beginGuide(title)
	guideToken += 1
	local token = guideToken
	guideFinishedForMission = false
	clearGuide()
	watchMissionPrompts(preferredMissionRoot())

	task.spawn(function()
		for _ = 1, RETRY_COUNT do
			if token ~= guideToken or activeMissionTitle ~= title or guideFinishedForMission then
				return
			end
			if tryShowNearestGuide(token) then
				return
			end
			task.wait(RETRY_DELAY)
		end
	end)
end

local missionName = "Mission_" .. player.UserId

local function handleMissionRootAdded(root)
	if root.Name ~= missionName then
		return
	end
	task.defer(function()
		if activeMissionTitle and root.Parent and activeMissionRoot ~= root then
			activeMissionRoot = root
			beginGuide(activeMissionTitle)
		end
	end)
end

local function bindMissionContainer(container)
	if missionContainerConnection then
		missionContainerConnection:Disconnect()
		missionContainerConnection = nil
	end
	missionContainerConnection = container.ChildAdded:Connect(handleMissionRootAdded)
end

local existingMissionContainer = workspace:FindFirstChild("PlayerMissions")
if existingMissionContainer then
	bindMissionContainer(existingMissionContainer)
end

workspace.ChildAdded:Connect(function(child)
	if child.Name == "PlayerMissions" then
		bindMissionContainer(child)
	elseif child.Name == missionName then
		handleMissionRootAdded(child)
	end
end)

missionInfo.OnClientEvent:Connect(function(message)
	if type(message) ~= "table" then
		return
	end

	if message.kind == "hud" then
		local title = message.title or "Misja"
		local root = missionRoot()
		if activeMissionTitle ~= title or activeMissionRoot ~= root then
			activeMissionTitle = title
			activeMissionRoot = root
			beginGuide(title)
		end
	elseif message.kind == "camera" then
		local root = missionRoot()
		if activeMissionTitle and root and activeMissionRoot ~= root then
			activeMissionRoot = root
			beginGuide(activeMissionTitle)
		end
	elseif message.kind == "complete" then
		activeMissionTitle = nil
		activeMissionRoot = nil
		guideFinishedForMission = true
		guideToken += 1
		disconnectMissionWatchers()
		clearGuide()
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer and triggeringPlayer ~= player then
		return
	end
	if prompt == guidedPrompt then
		guideToken += 1
		guideFinishedForMission = true
		disconnectMissionWatchers()
		clearGuide()
	end
end)

player.CharacterAdded:Connect(function()
	guideToken += 1
	clearGuide()
	if activeMissionTitle then
		activeMissionRoot = missionRoot()
		beginGuide(activeMissionTitle)
	end
end)

print("[CER] First action guide ready")