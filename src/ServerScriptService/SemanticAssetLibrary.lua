local AssetService = game:GetService("AssetService")
local ServerStorage = game:GetService("ServerStorage")

local SemanticAssetLibrary = {}

local REGISTRY = {
	desktop = { id = 149052427, source = "CreatorStore", maxSize = 10, maxParts = 24 },
	laptop = { id = 5724837940, source = "CreatorStore", maxSize = 8, maxParts = 8 },
	monitor = { id = 9527954034, source = "CreatorStore", maxSize = 7, maxParts = 24 },
	printer = { id = 74826334, source = "CreatorStore", maxSize = 7, maxParts = 40 },
	serverRack = { id = 3169755466, source = "CreatorStore", maxSize = 12, maxParts = 80 },
	switch = { id = 15277794969, source = "CreatorStore", maxSize = 9, maxParts = 40 },
	camera = { id = 5336927726, source = "CreatorStore", maxSize = 7, maxParts = 8 },
	chair = { id = 13438249395, source = "CreatorStore", maxSize = 7, maxParts = 12 },
	shelf = { id = 9923872209, source = "CreatorStore", maxSize = 12, maxParts = 60 },
	keyboard = { id = 2613050297, source = "CreatorStore", maxSize = 5, maxParts = 12 },
	mouse = { id = 9573390781, source = "CreatorStore", maxSize = 3, maxParts = 8 },
	toolbox = { id = 11774413831, source = "CreatorStore", maxSize = 6, maxParts = 8 },
	robot = { id = 60544619, source = "CreatorStore", maxSize = 9, maxParts = 8 },
	drone = { id = 980213529, source = "Roblox", maxSize = 9, maxParts = 16 },
	router = { id = 5684526020, source = "CreatorStore", maxSize = 8, maxParts = 12 },
	tablet = { id = 4829334497, source = "CreatorStore", maxSize = 5, maxParts = 8 },
	desk = { id = 18224914749, source = "CreatorStore", maxSize = 14, maxParts = 24 },
	table = { id = 276390942, source = "CreatorStore", maxSize = 14, maxParts = 24 },
	projector = { id = 2248620472, source = "CreatorStore", maxSize = 7, maxParts = 8 },
	speaker = { id = 13114693172, source = "CreatorStore", maxSize = 7, maxParts = 12 },
	microphone = { id = 15821406579, source = "CreatorStore", maxSize = 6, maxParts = 12 },
	crate = { id = 66229919, source = "CreatorStore", maxSize = 9, maxParts = 16 },
	cabinet = { id = 10500675980, source = "CreatorStore", maxSize = 12, maxParts = 16 },
	phone = { id = 120077519, source = "CreatorStore", maxSize = 4, maxParts = 8 },
	scanner = { id = 9575937282, source = "CreatorStore", maxSize = 8, maxParts = 64 },
	controlConsole = { id = 13715803420, source = "CreatorStore", maxSize = 10, maxParts = 32 },
	computerTerminal = { id = 11790169482, source = "CreatorStore", maxSize = 10, maxParts = 24 },
	projectorScreen = { id = 3339360987, source = "CreatorStore", maxSize = 16, maxParts = 12 },
	toggleSwitch = { id = 10814240092, source = "CreatorStore", maxSize = 4, maxParts = 32 },
	pushButton = { id = 8237529182, source = "CreatorStore", maxSize = 3, maxParts = 12 },
}
local cache = ServerStorage:FindFirstChild("CER_SemanticAssetCache")
if not cache then
	cache = Instance.new("Folder")
	cache.Name = "CER_SemanticAssetCache"
	cache.Parent = ServerStorage
end

local loading = {}
local failures = {}

local function cleanClone(root)
	for _, item in ipairs(root:GetDescendants()) do
		if
			item:IsA("LuaSourceContainer")
			or item:IsA("Sound")
			or item:IsA("ProximityPrompt")
			or item:IsA("ClickDetector")
		then
			item:Destroy()
		elseif item:IsA("BasePart") then
			item.Anchored = true
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			item.Massless = true
		end
	end
end
local function makeGeometryModel(asset)
	local visual = Instance.new("Model")
	visual.Name = "SemanticAsset"
	for _, item in ipairs(asset:GetDescendants()) do
		if item:IsA("BasePart") then
			local clone = item:Clone()
			cleanClone(clone)
			clone.Anchored = true
			clone.CanCollide = false
			clone.CanTouch = false
			clone.CanQuery = false
			clone.Massless = true
			clone.Parent = visual
		end
	end
	if #visual:GetChildren() == 0 then
		visual:Destroy()
		return nil
	end
	return visual
end

local function loadTemplate(key)
	local cached = cache:FindFirstChild(key)
	if cached then
		return cached
	end
	if failures[key] then
		return nil
	end
	while loading[key] do
		task.wait()
		local retry = cache:FindFirstChild(key)
		if retry then
			return retry
		end
		if failures[key] then
			return nil
		end
	end
	local entry = REGISTRY[key]
	if not entry then
		return nil
	end
	loading[key] = true
	local ok, asset = pcall(function()
		return AssetService:LoadAssetAsync(entry.id)
	end)
	loading[key] = nil
	if not ok or not asset then
		failures[key] = tostring(asset)
		warn(string.format("[CER-ASSET] load failed key=%s id=%d reason=%s", key, entry.id, tostring(asset)))
		return nil
	end

	local visual = makeGeometryModel(asset)
	asset:Destroy()
	if not visual then
		failures[key] = "no BasePart geometry"
		return nil
	end
	local partCount = #visual:GetChildren()
	if partCount > (entry.maxParts or 100) then
		failures[key] = string.format("asset too complex: %d parts > %d", partCount, entry.maxParts or 100)
		visual:Destroy()
		warn(
			string.format(
				"[CER-ASSET] rejected key=%s id=%d parts=%d max=%d",
				key,
				entry.id,
				partCount,
				entry.maxParts or 100
			)
		)
		return nil
	end
	visual.Name = key
	visual:SetAttribute("SemanticAssetKey", key)
	visual:SetAttribute("SemanticAssetId", entry.id)
	visual.Parent = cache
	print(string.format("[CER-ASSET] loaded key=%s id=%d parts=%d", key, entry.id, partCount))
	return visual
end
local function fitModel(model, targetCFrame, targetSize, maxSize)
	local _, size = model:GetBoundingBox()
	local biggest = math.max(size.X, size.Y, size.Z)
	if biggest <= 0 then
		return
	end
	local targetMax = math.min(maxSize or 10, math.max(targetSize.X, targetSize.Y, targetSize.Z))
	model:ScaleTo(targetMax / biggest)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottomOffset = boxSize.Y * 0.5
	local targetBottom = targetCFrame.Position.Y - targetSize.Y * 0.5
	local desired = CFrame.new(targetCFrame.Position.X, targetBottom + bottomOffset, targetCFrame.Position.Z)
		* (targetCFrame - targetCFrame.Position)
	model:PivotTo(desired * boxCFrame.Rotation:Inverse())
end

function SemanticAssetLibrary.Place(key, parent, targetCFrame, targetSize, name)
	local entry = REGISTRY[key]
	if not entry then
		return nil, "unknown semantic asset " .. tostring(key)
	end
	local template = loadTemplate(key)
	if not template then
		return nil, failures[key] or "asset unavailable"
	end
	local clone = template:Clone()
	clone.Name = name or ("Asset_" .. key)
	clone:SetAttribute("SemanticAssetKey", key)
	clone:SetAttribute("SemanticAssetId", entry.id)
	clone:SetAttribute("CreatorStoreSource", entry.source)
	clone.Parent = parent
	fitModel(clone, targetCFrame, targetSize, entry.maxSize)
	return clone
end

function SemanticAssetLibrary.Preload(keys)
	for _, key in ipairs(keys) do
		task.spawn(function()
			loadTemplate(key)
		end)
	end
end

function SemanticAssetLibrary.GetRegistry()
	return REGISTRY
end

function SemanticAssetLibrary.GetFailure(key)
	return failures[key]
end

return SemanticAssetLibrary