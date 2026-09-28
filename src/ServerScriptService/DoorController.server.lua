local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local TAG = "InteractiveDoor"
local attached = setmetatable({}, { __mode = "k" })

local function numberAttribute(model, name, defaultValue, minimum)
	local value = model:GetAttribute(name)
	if typeof(value) ~= "number" then
		return defaultValue
	end
	if value < minimum then
		return minimum
	end
	return value
end

local function findDoorParts(model)
	local door = model:FindFirstChild("Door")
	local button = model:FindFirstChild("Button")

	if not door or not door:IsA("BasePart") then
		return nil, nil, nil, "missing BasePart named Door"
	end
	if not button or not button:IsA("BasePart") then
		return nil, nil, nil, "missing BasePart named Button"
	end

	local clickDetector = button:FindFirstChildOfClass("ClickDetector")
	if not clickDetector then
		return nil, nil, nil, "Button has no ClickDetector"
	end

	return door, button, clickDetector, nil
end
local function attach(model)
	if attached[model] then
		return
	end
	if not model:IsA("Model") then
		warn(string.format("%s tag is only supported on Models", TAG))
		return
	end

	local door, _, clickDetector, validationError = findDoorParts(model)
	if validationError then
		warn(string.format("InteractiveDoor %s: %s", model:GetFullName(), validationError))
		return
	end

	local openDistance = numberAttribute(model, "OpenDistance", 6, 0)
	local openTime = numberAttribute(model, "OpenTime", 0.8, 0.05)
	local autoCloseDelay = numberAttribute(model, "AutoCloseDelay", 3, 0)

	local closedCFrame = door.CFrame
	local openCFrame = closedCFrame * CFrame.new(openDistance, 0, 0)
	local tweenInfo = TweenInfo.new(
		openTime,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)

	local busy = false
	local isOpen = false
	local generation = 0
	local function moveDoor(open)
		if busy or isOpen == open then
			return
		end

		busy = true
		generation += 1
		local thisGeneration = generation
		local target = open and openCFrame or closedCFrame
		local tween = TweenService:Create(door, tweenInfo, { CFrame = target })

		tween:Play()
		tween.Completed:Wait()

		if thisGeneration ~= generation then
			return
		end

		isOpen = open
		busy = false

		if open and autoCloseDelay > 0 then
			task.delay(autoCloseDelay, function()
				if not model.Parent then
					return
				end
				if generation ~= thisGeneration then
					return
				end
				if isOpen and not busy then
					moveDoor(false)
				end
			end)
		end
	end
	clickDetector.MouseClick:Connect(function()
		if busy then
			return
		end
		moveDoor(not isOpen)
	end)

	attached[model] = true
end

for _, instance in CollectionService:GetTagged(TAG) do
	attach(instance)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(attach)
