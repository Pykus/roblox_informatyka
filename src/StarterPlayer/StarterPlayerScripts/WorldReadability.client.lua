local MIN_WORLD_TEXT = 18
local MAX_WORLD_TEXT = 46
local MIN_WORLD_BRIGHTNESS = 1.1
local MAX_STROKE_TRANSPARENCY = 0.65

local function isWorldGuiText(object)
	if not (object:IsA("TextLabel") or object:IsA("TextButton")) then
		return false
	end
	return object:FindFirstAncestorWhichIsA("SurfaceGui") ~= nil
		or object:FindFirstAncestorWhichIsA("BillboardGui") ~= nil
end

local function normalizeConstraint(object)
	local keeper = nil
	for _, child in ipairs(object:GetChildren()) do
		if child:IsA("UITextSizeConstraint") then
			if not keeper then
				keeper = child
			else
				keeper.MinTextSize = math.max(keeper.MinTextSize, child.MinTextSize)
				keeper.MaxTextSize = math.max(keeper.MaxTextSize, child.MaxTextSize)
				child:Destroy()
			end
		end
	end

	if not keeper then
		keeper = Instance.new("UITextSizeConstraint")
		keeper.Parent = object
	end

	keeper.MinTextSize = math.max(keeper.MinTextSize, MIN_WORLD_TEXT)
	keeper.MaxTextSize = math.max(keeper.MaxTextSize, MAX_WORLD_TEXT, keeper.MinTextSize)
end

local function improveWorldGui(object)
	if object:IsA("SurfaceGui") or object:IsA("BillboardGui") then
		object.LightInfluence = 0
		object.Brightness = math.max(object.Brightness, MIN_WORLD_BRIGHTNESS)
		return true
	end
	return false
end

local function improveText(object)
	if not isWorldGuiText(object) then
		return
	end

	object.TextWrapped = true
	if object.TextScaled then
		normalizeConstraint(object)
	else
		object.TextSize = math.max(object.TextSize, MIN_WORLD_TEXT)
	end

	local color = object.TextColor3
	local luminance = 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
	object.TextStrokeColor3 = if luminance >= 0.55 then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
	object.TextStrokeTransparency = math.min(object.TextStrokeTransparency, MAX_STROKE_TRANSPARENCY)
end

local function improve(object)
	if improveWorldGui(object) then
		return
	end
	improveText(object)
end

for _, object in ipairs(workspace:GetDescendants()) do
	improve(object)
end

workspace.DescendantAdded:Connect(function(object)
	task.defer(function()
		if not object.Parent then
			return
		end
		if object:IsA("UITextSizeConstraint") then
			local parent = object.Parent
			if parent and (parent:IsA("TextLabel") or parent:IsA("TextButton")) then
				improveText(parent)
			end
			return
		end
		improve(object)
	end)
end)

print("[CER] World readability guard ready")