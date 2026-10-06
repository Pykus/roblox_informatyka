local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MIN_SCREEN_TEXT = 16
local MAX_SCREEN_TEXT = 42

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

	keeper.MinTextSize = math.max(keeper.MinTextSize, MIN_SCREEN_TEXT)
	keeper.MaxTextSize = math.max(keeper.MaxTextSize, MAX_SCREEN_TEXT, keeper.MinTextSize)
end

local function improve(object)
	if not (object:IsA("TextLabel") or object:IsA("TextButton")) then
		return
	end
	if not object.TextScaled then
		return
	end

	normalizeConstraint(object)
end

for _, object in ipairs(playerGui:GetDescendants()) do
	improve(object)
end

playerGui.DescendantAdded:Connect(function(object)
	task.defer(function()
		if not object.Parent then
			return
		end
		if object:IsA("UITextSizeConstraint") then
			local parent = object.Parent
			if parent and (parent:IsA("TextLabel") or parent:IsA("TextButton")) then
				improve(parent)
			end
			return
		end
		improve(object)
	end)
end)

print("[CER] Screen readability guard ready")