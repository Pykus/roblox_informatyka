local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("GameRemotes"):WaitForChild("MissionInfo")
local camera = workspace.CurrentCamera

local DEFAULT_FOV = 70
local MIN_ZOOM = 5
local MAX_ZOOM = 16
local HEALTH_CHECK_INTERVAL = 0.5
local INTRO_DURATION = 0.85
local INTRO_DISTANCE = 88
local INTRO_HEIGHT = 46

local missionActive = false
local healthElapsed = 0
local overviewActive = false
local overviewToken = 0
local lastOverviewRoot = nil

local function applyPlayableCamera()
	if not camera then
		return
	end

	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = MIN_ZOOM
	player.CameraMaxZoomDistance = MAX_ZOOM
	camera.FieldOfView = DEFAULT_FOV
	camera.CameraType = Enum.CameraType.Custom

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function currentMissionRoot()
	local missions = workspace:FindFirstChild("PlayerMissions")
	return missions and missions:FindFirstChild("Mission_" .. player.UserId) or nil
end

local function finishOverview()
	if not overviewActive then
		return
	end
	overviewActive = false
	overviewToken += 1
	applyPlayableCamera()
end

local function startOverview()
	local root = currentMissionRoot()
	if not root or root == lastOverviewRoot or not camera then
		applyPlayableCamera()
		return
	end

	lastOverviewRoot = root
	overviewToken += 1
	local token = overviewToken
	overviewActive = true

	local boxCFrame, boxSize = root:GetBoundingBox()
	local center = boxCFrame.Position + Vector3.new(0, 4, 0)
	local span = math.max(boxSize.X, boxSize.Z)
	local distance = math.max(INTRO_DISTANCE, span * 0.72)
	local eye = center + Vector3.new(distance * 0.72, INTRO_HEIGHT, -distance)

	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = MIN_ZOOM
	player.CameraMaxZoomDistance = MAX_ZOOM
	camera.FieldOfView = DEFAULT_FOV
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(eye, center)

	task.delay(INTRO_DURATION, function()
		if overviewActive and token == overviewToken then
			finishOverview()
		end
	end)
end

local function cameraNeedsRepair()
	if overviewActive then
		return false
	end
	if not camera then
		return true
	end
	if player.CameraMode ~= Enum.CameraMode.Classic then
		return true
	end
	if math.abs(player.CameraMinZoomDistance - MIN_ZOOM) > 0.01 then
		return true
	end
	if math.abs(player.CameraMaxZoomDistance - MAX_ZOOM) > 0.01 then
		return true
	end
	if math.abs(camera.FieldOfView - DEFAULT_FOV) > 0.1 then
		return true
	end
	if camera.CameraType ~= Enum.CameraType.Custom then
		return true
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and camera.CameraSubject ~= humanoid
end

local function refreshCamera()
	task.defer(function()
		applyPlayableCamera()
		task.wait(0.1)
		applyPlayableCamera()
	end)
end

remote.OnClientEvent:Connect(function(message)
	if type(message) ~= "table" then
		return
	end

	if message.kind == "camera" then
		missionActive = true
		task.defer(startOverview)
	elseif message.kind == "hud" then
		missionActive = true
		if not overviewActive then
			refreshCamera()
		end
	elseif message.kind == "complete" then
		missionActive = false
		finishOverview()
		refreshCamera()
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if not overviewActive then
		return
	end
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.Keyboard
		or input.UserInputType == Enum.UserInputType.Gamepad1
	then
		finishOverview()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not overviewActive then
		return
	end
	if
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.MouseWheel
		or input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.Gamepad1
	then
		finishOverview()
	end
end)

player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid", 5)
	refreshCamera()
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
	if overviewActive then
		finishOverview()
	else
		refreshCamera()
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	if not missionActive then
		return
	end
	healthElapsed += deltaTime
	if healthElapsed < HEALTH_CHECK_INTERVAL then
		return
	end
	healthElapsed = 0
	if cameraNeedsRepair() then
		applyPlayableCamera()
	end
end)

refreshCamera()
print("[CER] Playable mission camera ready")