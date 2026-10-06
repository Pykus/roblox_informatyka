local CyberDefenseRules = {}

CyberDefenseRules.PasswordCells = {
	{
		id = "LONG",
		label = "DŁUGIE HASŁO",
		safe = true,
		why = "Długość mocno zwiększa liczbę możliwych kombinacji.",
	},
	{
		id = "UNIQUE",
		label = "UNIKALNE DLA KONTA",
		safe = true,
		why = "Wyciek jednego hasła nie otworzy innych kont.",
	},
	{
		id = "MANAGER",
		label = "MENEDŻER HASEŁ",
		safe = true,
		why = "Pozwala używać różnych długich haseł bez zapamiętywania każdego.",
	},
	{
		id = "123456",
		label = "123456",
		safe = false,
		why = "To jedno z pierwszych haseł sprawdzanych przez atakujących.",
	},
	{ id = "NAMEYEAR", label = "IMIĘ + ROK", safe = false, why = "Dane o osobie bywają łatwe do odgadnięcia." },
	{ id = "REUSE", label = "TO SAMO WSZĘDZIE", safe = false, why = "Jeden wyciek może wtedy otworzyć wiele kont." },
}

CyberDefenseRules.Messages = {
	{
		id = "RESET",
		label = "PILNE! Konto zostanie usunięte. Zaloguj się przez skrócony link: bit.ly/...",
		verdict = "BLOCK",
		why = "Presja czasu i obcy skrócony link to silne sygnały phishingu.",
	},
	{
		id = "SCHOOL",
		label = "Informacja w oficjalnej aplikacji: sprawdź plan zajęć. Brak linku i prośby o hasło.",
		verdict = "ALLOW",
		why = "Komunikat nie wyłudza danych i kieruje do znanego kanału.",
	},
	{
		id = "PRIZE",
		label = "Wygrałeś telefon! Podaj hasło i kod MFA, aby odebrać nagrodę.",
		verdict = "BLOCK",
		why = "Nikt wiarygodny nie powinien prosić o hasło ani kod MFA.",
	},
}

function CyberDefenseRules.IsPasswordCellSafe(id)
	for _, cell in ipairs(CyberDefenseRules.PasswordCells) do
		if cell.id == id then
			return cell.safe, cell.why
		end
	end
	return false, "Nieznany moduł."
end

function CyberDefenseRules.MessageVerdict(id)
	for _, item in ipairs(CyberDefenseRules.Messages) do
		if item.id == id then
			return item.verdict, item.why
		end
	end
	return nil, "Nieznana wiadomość."
end

function CyberDefenseRules.IsMessageDecisionCorrect(id, decision)
	local expected = CyberDefenseRules.MessageVerdict(id)
	return expected ~= nil and expected == decision
end

return CyberDefenseRules