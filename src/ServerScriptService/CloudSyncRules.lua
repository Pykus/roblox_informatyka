local CloudSyncRules = {}

CloudSyncRules.Devices = {
	{
		id = "LAPTOP",
		label = "LAPTOP • prezentacja v3",
		version = 3,
	},
	{
		id = "TABLET",
		label = "TABLET • prezentacja v1",
		version = 1,
	},
}

CloudSyncRules.ShareModes = {
	{ id = "PUBLIC", label = "LINK PUBLICZNY DLA KAŻDEGO", safe = false },
	{ id = "PEOPLE", label = "TYLKO WSKAZANE OSOBY", safe = true },
	{ id = "PASSWORD_NAME", label = "HASŁO W NAZWIE PLIKU", safe = false },
}

function CloudSyncRules.NewestDevice()
	local best = CloudSyncRules.Devices[1]
	for _, device in ipairs(CloudSyncRules.Devices) do
		if device.version > best.version then
			best = device
		end
	end
	return best
end

function CloudSyncRules.CanUpload(deviceId)
	local newest = CloudSyncRules.NewestDevice()
	return newest ~= nil and deviceId == newest.id
end

function CloudSyncRules.CanDownload(cloudVersion, deviceVersion)
	return cloudVersion ~= nil and cloudVersion > deviceVersion
end

function CloudSyncRules.IsSafeShare(modeId)
	for _, mode in ipairs(CloudSyncRules.ShareModes) do
		if mode.id == modeId then
			return mode.safe
		end
	end
	return false
end

return CloudSyncRules