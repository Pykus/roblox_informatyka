local FileWarehouseRules = {}

FileWarehouseRules.Bins = { "DOKUMENTY", "OBRAZY", "DANE", "KWARANTANNA" }

FileWarehouseRules.Packages = {
	{ name = "plan.docx", category = "DOKUMENTY", extension = ".docx", hint = "dokument tekstowy", danger = false },
	{ name = "logo.png", category = "OBRAZY", extension = ".png", hint = "obraz rastrowy", danger = false },
	{ name = "wyniki.csv", category = "DANE", extension = ".csv", hint = "dane tabelaryczne", danger = false },
	{
		name = "wakacje.jpg.exe",
		category = "KWARANTANNA",
		extension = ".exe",
		hint = "podwojne rozszerzenie: to program, nie zdjecie",
		danger = true,
	},
	{ name = "opis.txt", category = "DOKUMENTY", extension = ".txt", hint = "zwykly plik tekstowy", danger = false },
}

local function findPackage(name)
	for _, package in ipairs(FileWarehouseRules.Packages) do
		if package.name == name then
			return package
		end
	end
	return nil
end

function FileWarehouseRules.Scan(name)
	local package = findPackage(name)
	if not package then
		return nil, "nieznana paczka"
	end
	return {
		extension = package.extension,
		hint = package.hint,
		danger = package.danger,
	}
end

function FileWarehouseRules.Route(name, binName)
	local package = findPackage(name)
	if not package then
		return false, nil, false
	end
	return package.category == binName, package.category, package.danger
end

return FileWarehouseRules