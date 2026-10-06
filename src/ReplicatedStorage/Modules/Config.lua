local Config = {}

Config.GameTitle = "Cyber Escape Room"
Config.TotalRooms = 4
Config.StartTimeSeconds = 15 * 60
Config.PointsPerRoom = 100
Config.WrongAnswerPenalty = 15

Config.Rooms = {
    [1] = {
        Title = "Pokój 1: Hasła",
        Question = "Które hasło jest najbezpieczniejsze?",
        Answers = {
            "12345678",
            "qwerty2026",
            "K0t!Lubi_7Ryb#",
            "informatyka"
        },
        Correct = 3,
        Hint = "Dobre hasło jest długie, nieoczywiste i zawiera różne typy znaków."
    },
    [2] = {
        Title = "Pokój 2: Phishing",
        Question = "Co jest najlepszą reakcją na podejrzany e-mail z linkiem do logowania?",
        Answers = {
            "Kliknąć link i sprawdzić",
            "Odpisać z pytaniem, czy to prawda",
            "Wejść na stronę usługi samodzielnie i sprawdzić komunikaty",
            "Przesłać wiadomość wszystkim znajomym"
        },
        Correct = 3,
        Hint = "Nie korzystaj z podejrzanego linku. Otwórz usługę znanym, bezpiecznym adresem."
    },
    [3] = {
        Title = "Pokój 3: Algorytm",
        Question = "Robot ma iść prosto, skręcić w prawo i ponownie iść prosto. Która kolejność jest poprawna?",
        Answers = {
            "PROSTO → PRAWO → PROSTO",
            "PRAWO → PROSTO → LEWO",
            "PROSTO → LEWO → PROSTO",
            "PRAWO → PRAWO → PROSTO"
        },
        Correct = 1,
        Hint = "Czytaj polecenia dokładnie w kolejności wykonania."
    },
    [4] = {
        Title = "Pokój 4: Kod",
        Question = "Co wypisze kod: local x = 3; x = x + 2; print(x)?",
        Answers = {"2", "3", "5", "32"},
        Correct = 3,
        Hint = "Najpierw x ma wartość 3, potem dodajemy 2."
    }
}

return Config