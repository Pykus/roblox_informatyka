local Rules = {}

Rules.Rounds = {
	{ number = 29, expected = "PRIME" },
	{ number = 35, expected = "COMPOSITE" },
	{ number = 42, expected = "COMPOSITE" },
}
Rules.Divisors = { 2, 3, 5, 7 }

function Rules.NewState()
	return {
		round = 1,
		tested = {},
		foundFactor = nil,
		lastTest = nil,
		errors = 0,
		completed = false,
	}
end

function Rules.Current(state)
	return Rules.Rounds[state.round]
end

function Rules.ResetRound(state)
	state.tested = {}
	state.foundFactor = nil
	state.lastTest = nil
end

function Rules.TestDivisor(state, divisor)
	local current = Rules.Current(state)
	if not current then
		return false, "Brak aktywnej liczby."
	end
	if not table.find(Rules.Divisors, divisor) then
		return false, "Skaner nie ma takiego dzielnika."
	end

	local remainder = current.number % divisor
	local quotient = math.floor(current.number / divisor)
	state.tested[divisor] = true
	state.lastTest = {
		divisor = divisor,
		remainder = remainder,
		quotient = quotient,
	}

	if remainder == 0 and divisor > 1 and divisor < current.number then
		state.foundFactor = divisor
	end

	return true, state.lastTest
end

function Rules.RequiredPrimeTests(number)
	local required = {}
	local limit = math.sqrt(number)
	for _, divisor in ipairs(Rules.Divisors) do
		if divisor <= limit then
			table.insert(required, divisor)
		end
	end
	return required
end

function Rules.CanDeclarePrime(state)
	local current = Rules.Current(state)
	if not current or state.foundFactor then
		return false
	end
	for _, divisor in ipairs(Rules.RequiredPrimeTests(current.number)) do
		if not state.tested[divisor] then
			return false
		end
	end
	return true
end

function Rules.MissingPrimeTest(state)
	local current = Rules.Current(state)
	if not current then
		return nil
	end
	for _, divisor in ipairs(Rules.RequiredPrimeTests(current.number)) do
		if not state.tested[divisor] then
			return divisor
		end
	end
	return nil
end

function Rules.Classify(state, classification)
	local current = Rules.Current(state)
	if not current then
		return false, "Brak aktywnej liczby.", false
	end
	if classification ~= "PRIME" and classification ~= "COMPOSITE" then
		return false, "Nieznana klasyfikacja.", false
	end

	if classification == "PRIME" and not Rules.CanDeclarePrime(state) then
		state.errors += 1
		local missing = Rules.MissingPrimeTest(state)
		if state.foundFactor then
			return false, string.format(
				"Masz już dzielnik %d, więc liczba jest złożona.",
				state.foundFactor
			), false
		end
		return false, string.format(
			"Za wcześnie. Sprawdź jeszcze %% %d.",
			missing or 2
		), false
	end

	if classification == "COMPOSITE" and not state.foundFactor then
		state.errors += 1
		return false, "Najpierw znajdź dzielnik z resztą 0.", false
	end

	if classification ~= current.expected then
		state.errors += 1
		return false, "Wniosek nie zgadza się z wynikami skanera.", false
	end

	local finishedNumber = current.number
	state.round += 1
	local completed = state.round > #Rules.Rounds
	if completed then
		state.completed = true
	else
		Rules.ResetRound(state)
	end
	return true, finishedNumber, completed
end

function Rules.Progress(state)
	return math.min(state.round - 1, #Rules.Rounds)
end

return Rules