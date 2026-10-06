local CaesarCipherRules = {}

CaesarCipherRules.Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
CaesarCipherRules.ExpectedShift = 3
CaesarCipherRules.CipherText = "KHOOR"
CaesarCipherRules.PlainText = "HELLO"
CaesarCipherRules.WrapPlain = "XYZ"
CaesarCipherRules.WrapCipher = "ABC"

local function normalizeShift(shift)
	return ((shift % 26) + 26) % 26
end

function CaesarCipherRules.ShiftChar(char, shift)
	local byte = string.byte(string.upper(char))
	if not byte or byte < 65 or byte > 90 then
		return char
	end
	local zero = byte - 65
	return string.char(65 + normalizeShift(zero + shift))
end

function CaesarCipherRules.Transform(text, shift)
	local out = {}
	for i = 1, #text do
		table.insert(out, CaesarCipherRules.ShiftChar(text:sub(i, i), shift))
	end
	return table.concat(out)
end

function CaesarCipherRules.Encode(text, shift)
	return CaesarCipherRules.Transform(text, shift)
end

function CaesarCipherRules.Decode(text, shift)
	return CaesarCipherRules.Transform(text, -shift)
end

function CaesarCipherRules.NewState()
	return {
		stage = 1,
		shift = 0,
		mode = "ENCODE",
		errors = 0,
		completed = false,
	}
end

function CaesarCipherRules.ChangeShift(state, delta)
	if state.stage ~= 1 then
		return false, "Pierścień przesunięcia jest już zablokowany."
	end
	state.shift = normalizeShift(state.shift + delta)
	return true,
		string.format(
			"Przesunięcie = +%d • A → %s • X → %s",
			state.shift,
			CaesarCipherRules.ShiftChar("A", state.shift),
			CaesarCipherRules.ShiftChar("X", state.shift)
		)
end

function CaesarCipherRules.LockShift(state)
	if state.stage ~= 1 then
		return false, "Pierścień jest już zablokowany."
	end
	if state.shift ~= CaesarCipherRules.ExpectedShift then
		state.errors += 1
		return false,
			string.format(
				"DEBUG PIERŚCIENIA • masz +%d: A → %s. Cel +3 wymaga A → D.",
				state.shift,
				CaesarCipherRules.ShiftChar("A", state.shift)
			)
	end
	state.stage = 2
	state.mode = "ENCODE"
	return true, "Pierścień zablokowany na +3. Teraz odszyfruj KHOOR."
end

function CaesarCipherRules.ToggleMode(state)
	if state.stage < 2 or state.completed then
		return false, "Tryb szyfratora nie jest teraz aktywny."
	end
	state.mode = state.mode == "ENCODE" and "DECODE" or "ENCODE"
	return true, state.mode
end

function CaesarCipherRules.Preview(state)
	if state.stage == 2 then
		if state.mode == "DECODE" then
			return CaesarCipherRules.Decode(CaesarCipherRules.CipherText, state.shift)
		end
		return CaesarCipherRules.Encode(CaesarCipherRules.CipherText, state.shift)
	elseif state.stage == 3 then
		if state.mode == "ENCODE" then
			return CaesarCipherRules.Encode(CaesarCipherRules.WrapPlain, state.shift)
		end
		return CaesarCipherRules.Decode(CaesarCipherRules.WrapPlain, state.shift)
	end
	return ""
end

function CaesarCipherRules.Run(state)
	if state.stage == 1 then
		return false, "Najpierw ustaw i zablokuj pierścień na +3.", ""
	end
	if state.completed then
		return false, "Sejf jest już otwarty.", ""
	end

	if state.stage == 2 then
		local preview = CaesarCipherRules.Preview(state)
		if state.mode ~= "DECODE" then
			state.errors += 1
			return false,
				string.format(
					"DEBUG KIERUNKU • KHOOR trzeba ODSZYFROWAĆ (-3), a tryb %s daje %s.",
					state.mode,
					preview
				),
				preview
		end
		if preview ~= CaesarCipherRules.PlainText then
			state.errors += 1
			return false,
				string.format("DEBUG TEKSTU • otrzymano %s, oczekiwano %s.", preview, CaesarCipherRules.PlainText),
				preview
		end
		state.stage = 3
		state.mode = "DECODE"
		return true, "KHOOR → HELLO. Ostatni etap: zaszyfruj XYZ z zawijaniem alfabetu.", preview
	end

	local preview = CaesarCipherRules.Preview(state)
	if state.mode ~= "ENCODE" then
		state.errors += 1
		return false,
			string.format("DEBUG KIERUNKU • XYZ trzeba SZYFROWAĆ (+3), a tryb %s daje %s.", state.mode, preview),
			preview
	end
	if preview ~= CaesarCipherRules.WrapCipher then
		state.errors += 1
		return false, string.format("DEBUG ZAWIJANIA • +3 musi dać XYZ → ABC, otrzymano %s.", preview), preview
	end

	state.completed = true
	return true, "XYZ +3 → ABC. Zawijanie Z→C działa — sejf otwarty.", preview
end

function CaesarCipherRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

return CaesarCipherRules