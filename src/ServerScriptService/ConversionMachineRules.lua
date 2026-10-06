local ConversionMachineRules = {}

ConversionMachineRules.BinarySource = 58
ConversionMachineRules.HexQuotientTarget = 3
ConversionMachineRules.HexRemainderTarget = 10
ConversionMachineRules.ReverseHigh = 2
ConversionMachineRules.ReverseLowTarget = 13

function ConversionMachineRules.NewState()
	return {
		stage = 1,
		errors = 0,
		binaryCurrent = ConversionMachineRules.BinarySource,
		selectedRemainder = nil,
		remainders = {},
		hexQuotient = 2,
		hexRemainder = 9,
		reverseLow = 12,
		completed = false,
	}
end

function ConversionMachineRules.SelectRemainder(state, remainder)
	if state.stage ~= 1 then
		return false, "Dzielarka BIN nie jest teraz aktywna."
	end
	if remainder ~= 0 and remainder ~= 1 then
		return false, "Reszta przy dzieleniu przez 2 może być tylko 0 albo 1."
	end
	state.selectedRemainder = remainder
	return true, remainder
end

function ConversionMachineRules.BinaryStep(state)
	if state.stage ~= 1 then
		return false, { message = "Dzielarka BIN jest już zakończona." }
	end
	if state.binaryCurrent <= 0 then
		return false, { message = "Nie ma już liczby do dzielenia." }
	end
	if state.selectedRemainder == nil then
		return false, { message = "Najpierw wybierz resztę 0 lub 1." }
	end

	local before = state.binaryCurrent
	local expectedRemainder = before % 2
	local quotient = math.floor(before / 2)
	local chosenRemainder = state.selectedRemainder
	if chosenRemainder ~= expectedRemainder then
		state.errors += 1
		state.selectedRemainder = nil
		return false,
			{
				before = before,
				expectedRemainder = expectedRemainder,
				message = string.format(
					"DEBUG DZIELENIA • %d : 2 daje resztę %d, nie %d.",
					before,
					expectedRemainder,
					chosenRemainder
				),
			}
	end

	table.insert(state.remainders, expectedRemainder)
	state.binaryCurrent = quotient
	state.selectedRemainder = nil
	local finished = quotient == 0
	if finished then
		state.stage = 2
	end
	return true,
		{
			before = before,
			quotient = quotient,
			remainder = expectedRemainder,
			step = #state.remainders,
			finished = finished,
			message = string.format("%d : 2 = %d reszty %d.", before, quotient, expectedRemainder),
		}
end

function ConversionMachineRules.BinaryText(state)
	local out = {}
	for index = #state.remainders, 1, -1 do
		table.insert(out, tostring(state.remainders[index]))
	end
	return table.concat(out)
end

function ConversionMachineRules.AdjustHex(state, key, delta)
	if state.stage ~= 2 then
		return false, "Dzielarka HEX nie jest teraz aktywna."
	end
	if key == "quotient" then
		state.hexQuotient = math.clamp(state.hexQuotient + delta, 0, 9)
		return true, state.hexQuotient
	elseif key == "remainder" then
		state.hexRemainder = math.clamp(state.hexRemainder + delta, 0, 15)
		return true, state.hexRemainder
	end
	return false, "Nieznany parametr dzielenia przez 16."
end

function ConversionMachineRules.ValidateHex(state)
	if state.stage ~= 2 then
		return false, { message = "Dzielarka HEX nie jest teraz aktywna." }
	end
	local value = state.hexQuotient * 16 + state.hexRemainder
	if
		state.hexQuotient ~= ConversionMachineRules.HexQuotientTarget
		or state.hexRemainder ~= ConversionMachineRules.HexRemainderTarget
	then
		state.errors += 1
		return false,
			{
				value = value,
				message = string.format(
					"DEBUG HEX • %d×16 + %d = %d, a wejście ma wartość 58.",
					state.hexQuotient,
					state.hexRemainder,
					value
				),
			}
	end
	state.stage = 3
	return true, {
		value = value,
		hex = "3A",
		message = "58 : 16 = 3 reszty 10(A), więc 58₁₀ = 3A₁₆.",
	}
end

function ConversionMachineRules.AdjustReverseLow(state, delta)
	if state.stage ~= 3 or state.completed then
		return false, "Weryfikator HEX→DEC nie jest teraz aktywny."
	end
	state.reverseLow = math.clamp(state.reverseLow + delta, 0, 15)
	return true, state.reverseLow
end

function ConversionMachineRules.ReverseValue(state)
	return ConversionMachineRules.ReverseHigh * 16 + state.reverseLow
end

function ConversionMachineRules.ValidateReverse(state)
	if state.stage ~= 3 or state.completed then
		return false, { message = "Weryfikator HEX→DEC nie jest teraz aktywny." }
	end
	local value = ConversionMachineRules.ReverseValue(state)
	if state.reverseLow ~= ConversionMachineRules.ReverseLowTarget then
		state.errors += 1
		return false,
			{
				value = value,
				message = string.format(
					"DEBUG POWROTU • 2×16 + %d = %d. Cyfra D oznacza 13.",
					state.reverseLow,
					value
				),
			}
	end
	state.completed = true
	return true, {
		value = value,
		message = "2D₁₆ = 2×16 + 13 = 45₁₀. Konwersja zwrotna poprawna.",
	}
end

function ConversionMachineRules.Efficiency(state)
	return math.max(40, 100 - state.errors * 10)
end

return ConversionMachineRules