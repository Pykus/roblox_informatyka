local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function isActuallyVisible(textBox)
	if not textBox:IsDescendantOf(playerGui) or not textBox.Visible then
		return false
	end

	local parent = textBox.Parent
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

RunService.Heartbeat:Connect(function()
	local focused = UserInputService:GetFocusedTextBox()
	if focused and not isActuallyVisible(focused) then
		focused:ReleaseFocus()
	end
end)

print("[CER] Hidden TextBox focus guard ready")