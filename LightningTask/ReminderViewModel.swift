//
//  ReminderViewModel.swift
//  LightningTask
//
//  Created by Matthias Tyca on 19.05.26.
//
import EventKit
import Foundation
import FoundationModels


@Observable class ReminderViewModel {
    var reminderStore = EKEventStore()
    var reminderLists: [EKCalendar] = []
    
    var modelAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }
    
    init() {
        Task {
            do {
                try await requestAccess()
                print("Request granted")
                self.reminderLists = fetchLists()
                print("Model avaialble: \(modelAvailable)")
            } catch {
                print("Request denied: \(error)")
            }
        }
    }
    
    func requestAccess() async throws {
        try await reminderStore.requestFullAccessToReminders()
    }
    
    func fetchLists() -> [EKCalendar] {
        let calendars = reminderStore.calendars(for: .reminder)
        return calendars
    }
    
    func createReminder(text: String, listName: String, suggestion: TaskSuggestion?) async {
        let reminder = EKReminder(eventStore: reminderStore)
        reminder.title = text
        
        // Liste setzen
        print("Looking for list: \(listName)")
        print("Available lists: \(reminderLists.map { $0.title })")
        reminder.calendar = reminderLists.first(where: { $0.title == listName })
        ?? reminderStore.defaultCalendarForNewReminders()
        
        // Datum setzen — Time nur, wenn explizit angegeben (sonst date-only Reminder).
        // Bei "nur Uhrzeit, kein Datum" wird heute als Datum ergänzt.
        if let suggestion, !(suggestion.dueDate.isEmpty && suggestion.dueTime.isEmpty) {
            let hasTime = !suggestion.dueTime.isEmpty
            let today = String(ISO8601DateFormatter().string(from: .now).prefix(10))
            let dateString = suggestion.dueDate.isEmpty ? today : suggestion.dueDate

            let formatter = DateFormatter()
            formatter.dateFormat = hasTime ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd"
            let input = hasTime ? "\(dateString) \(suggestion.dueTime)" : dateString
            if let date = formatter.date(from: input) {
                let components: Set<Calendar.Component> = hasTime
                    ? [.year, .month, .day, .hour, .minute]
                    : [.year, .month, .day]
                reminder.dueDateComponents = Calendar.current.dateComponents(components, from: date)
            }
        }
        
        do {
            try reminderStore.save(reminder, commit: true)
        } catch {
            print("Failed to save reminder with text: \(text)")
        }
    }
    
    func relevantLists(for input: String) -> [EKCalendar] {
        let words = input.lowercased().components(separatedBy: .whitespaces)
        
        let scored = reminderLists.map { list -> (EKCalendar, Int) in
            let title = list.title.lowercased()
            let score = words.filter { word in
                word.count > 2 && title.contains(word)
            }.count
            return (list, score)
        }
        
        let matches = scored.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
        
        if matches.isEmpty {
            // Fallback: Inbox + ein paar häufig genutzte
            return reminderLists.filter { ["Inbox", "Privat", "Goals"].contains($0.title) }
        }
        
        // Top-Matches + immer Inbox als Fallback dabei
        var result = matches.prefix(5).map { $0.0 }
        if let inbox = reminderLists.first(where: { $0.title == "Inbox" }),
           !result.contains(where: { $0.calendarIdentifier == inbox.calendarIdentifier }) {
            result.append(inbox)
        }
        return result
    }
    
    func suggestLists(for taskTitle: String) async throws -> TaskSuggestion {
        let model = SystemLanguageModel.default
        let session = LanguageModelSession(model: model)
        let filteredLists = relevantLists(for: taskTitle)
        let listNamesString = filteredLists.map { $0.title }.joined(separator: ", ")
        
        let today = String(ISO8601DateFormatter().string(from: .now).prefix(10)) // Maschinenlesbares Format
        let tomorrow = String(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: 1, to: .now)!).prefix(10))
        print("Today: \(today)")
        let prompt = """
        Das heutige Datum: \(today)

        Du kategorisierst Tasks in Listen und extrahierst Datum und Uhrzeit.

        TOP-REGEL ZEIT: dueTime ist EXAKT der leere String "", außer der User nennt
        eine explizite Uhrzeit ("8 Uhr", "14:30", "halb 9", "morgens"). NIEMALS "00:00"
        als Default — "00:00" bedeutet "Mitternacht" und ist nur erlaubt, wenn der User
        das wirklich so meint. Gleiches Prinzip für dueDate: leer, außer ein konkretes
        Datum wurde genannt. "heute", "jetzt", "bald" zählen NICHT als Datumsangabe.

        TOP-REGEL LISTE: Wenn der User einen Listennamen aus der VERFÜGBARE LISTEN unten
        WÖRTLICH (auch in anderer Groß-/Kleinschreibung) im Task nennt, MUSS genau diese
        Liste an erster Stelle in listNames stehen. Auch wenn der restliche Task generisch
        klingt.

        REGELN:
        - Extrahiere den reinen Task-Titel: ohne Listennamen, ohne Datum, ohne Uhrzeit.
          Auch Verbindungswörter wie "in", "auf", "für" + Listenname werden entfernt.
        - Relative Daten ("morgen", "Freitag", "in 2 Wochen") relativ zu heute auflösen.
        - dueDate IMMER als ISO-Format: "YYYY-MM-DD". Leer wenn kein Datum.
        - dueTime IMMER als "HH:mm". Leer wenn keine Uhrzeit.
        - listNames: nur Werte EXAKT aus der Liste unten — keine Abwandlungen, keine
          Pluralformen, keine Erfindungen.
        - listNames-Auswahl: nur EINE Liste zurückgeben, wenn klar nur eine passt
          (eindeutiger Treffer, z.B. weil der User einen Disambiguator wie "iOS",
          "Electron" oder den Listennamen wörtlich genannt hat).
          Wenn mehrere Listen den gleichen Stamm teilen und kein Disambiguator genannt
          wurde → ALLE plausiblen Kandidaten zurückgeben, spezifischste zuerst,
          allgemeinste zuletzt.
        - Mehrere Tasks durch Komma oder "und" getrennt → mehrere items.
        - Mengenangaben im Titel behalten: "3 Bananen" bleibt "3 Bananen".

        VERFÜGBARE LISTEN (exakt so übernehmen):
        \(listNamesString)

        BEISPIELE:
        "Milch kaufen" → items: ["Milch kaufen"], listNames: ["Einkäufe"], dueDate: "", dueTime: "" ← KEIN Datum, KEINE Uhrzeit
        "Auto putzen morgen" → items: ["Auto putzen"], listNames: ["Privat", "Inbox"], dueDate: "\(tomorrow)", dueTime: "" ← Datum genannt, aber KEINE Uhrzeit → dueTime leer
        "Weitermachen in LightningTask" → items: ["Weitermachen"], listNames: ["LightningTask"], dueDate: "", dueTime: "" ← Listenname wörtlich genannt → muss erste Liste sein
        "Planung in metanoy General morgen 8 Uhr" → items: ["Planung"], listNames: ["metanoy General"], dueDate: "\(tomorrow)", dueTime: "08:00"
        "3 Bananen, 4x Quark" → items: ["3 Bananen", "4x Quark"], listNames: ["Einkäufe"], dueDate: "", dueTime: ""
        "metaLOG ios weitermachen" → items: ["weitermachen"], listNames: ["metaLOG iOS/Mac"], dueDate: "", dueTime: "" ← eindeutig, "ios" passt nur zu einer Liste
        "metalog weitermachen" → items: ["weitermachen"], listNames: ["metaLOG", "metaLOG iOS/Mac", "metaLOG Electron"], dueDate: "", dueTime: "" ← mehrdeutig, kein Disambiguator

        TASK:
        "\(taskTitle)"
        """
        
        let response = try await session.respond(
            to: prompt,
            generating: TaskSuggestion.self
        )
        
        var suggestion = response.content
        print("[suggest] raw model listNames: \(suggestion.listNames)")
        print("[suggest] reminderLists: \(reminderLists.map { $0.title })")
        suggestion.listNames = snapToAvailableLists(suggestion.listNames)
        print("[suggest] after snap: \(suggestion.listNames)")
        // Deterministischer Fallback: Modell ignoriert oft offensichtliche Matches.
        // Token-Scoring fängt das ab und erzwingt die plausiblen Kandidaten vorn,
        // sortiert nach Score (spezifischste zuerst).
        let tokenCandidates = candidateListsByTokens(for: taskTitle).prefix(4)
        print("[suggest] token candidates for '\(taskTitle)': \(Array(tokenCandidates))")
        for candidate in tokenCandidates.reversed() {
            suggestion.listNames.removeAll { $0 == candidate }
            suggestion.listNames.insert(candidate, at: 0)
        }
        // Listennamen aus Items entfernen — nur die wörtlich genannten, damit
        // wir nicht versehentlich Token-Bestandteile rauskürzen.
        let verbatim = verbatimListMatches(in: taskTitle)
        if !verbatim.isEmpty {
            suggestion.items = suggestion.items.map { stripListNames($0, names: verbatim) }
        }
        if !suggestion.listNames.contains("Inbox") {
            suggestion.listNames.append("Inbox")
        }
        return suggestion
    }

    /// Token-Scoring: zerlegt jeden Listennamen in Tokens (split bei Whitespace,
    /// "/", "-", "_") und zählt, wie viele davon im Input vorkommen.
    /// Kandidaten mit Score > 0, sortiert nach Score absteigend, bei Gleichstand
    /// längerer Name zuerst (spezifischer).
    private func candidateListsByTokens(for input: String) -> [String] {
        let inputLower = input.lowercased()
        let separators = CharacterSet(charactersIn: " /-_")
        let scored: [(String, Int)] = reminderLists.map { list in
            let tokens = list.title
                .lowercased()
                .components(separatedBy: separators)
                .filter { $0.count > 2 }
            guard !tokens.isEmpty else { return (list.title, 0) }
            let score = tokens.filter { inputLower.contains($0) }.count
            return (list.title, score)
        }
        return scored
            .filter { $0.1 > 0 }
            .sorted {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                return $0.0.count > $1.0.count
            }
            .map { $0.0 }
    }

    /// Findet Listennamen, die wörtlich (case-insensitive) im Input vorkommen.
    /// Längste Matches zuerst, damit "metaLOG iOS/Mac" vor "metaLOG" gewinnt.
    private func verbatimListMatches(in input: String) -> [String] {
        let inputLower = input.lowercased()
        return reminderLists
            .map { $0.title }
            .filter { !$0.isEmpty && inputLower.contains($0.lowercased()) }
            .sorted { $0.count > $1.count }
    }

    /// Entfernt Listennamen (mit optionalen Verbindungswörtern davor) aus einem String.
    private func stripListNames(_ item: String, names: [String]) -> String {
        var result = item
        for name in names {
            for prefix in ["in ", "auf ", "für ", "fuer ", ""] {
                result = result.replacingOccurrences(
                    of: prefix + name,
                    with: "",
                    options: .caseInsensitive
                )
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Snappt vom Modell zurückgegebene Listennamen auf die tatsächlich existierenden
    /// Reminder-Listen (Hallucination-Schutz: "LightningTasks" → "LightningTask").
    /// Reihenfolge bleibt erhalten, Duplikate werden entfernt, Unbekanntes verworfen.
    private func snapToAvailableLists(_ names: [String]) -> [String] {
        let available = reminderLists.map { $0.title }
        var seen = Set<String>()
        var result: [String] = []

        for name in names {
            guard let canonical = matchListName(name, in: available) else { continue }
            if seen.insert(canonical).inserted {
                result.append(canonical)
            }
        }
        return result
    }

    private func matchListName(_ candidate: String, in available: [String]) -> String? {
        if let exact = available.first(where: { $0 == candidate }) { return exact }

        let lowerCandidate = candidate.lowercased()
        if let caseInsensitive = available.first(where: { $0.lowercased() == lowerCandidate }) {
            return caseInsensitive
        }
        // Substring in beide Richtungen — fängt Plural-/Suffix-Halluzinationen
        if let substring = available.first(where: {
            let lowerAvailable = $0.lowercased()
            return lowerAvailable.contains(lowerCandidate) || lowerCandidate.contains(lowerAvailable)
        }) {
            return substring
        }
        // Fuzzy-Fallback (Levenshtein) — toleriert Tippfehler in den User-Listennamen
        // (z.B. "LightningTask" vom Modell → "LighningTask" in den Reminders).
        let scored = available.map { ($0, levenshtein($0.lowercased(), lowerCandidate)) }
        guard let best = scored.min(by: { $0.1 < $1.1 }) else { return nil }
        let threshold = max(2, lowerCandidate.count / 5)
        return best.1 <= threshold ? best.0 : nil
    }

    private func levenshtein(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }
        var dp = Array(repeating: Array(repeating: 0, count: bChars.count + 1),
                       count: aChars.count + 1)
        for i in 0...aChars.count { dp[i][0] = i }
        for j in 0...bChars.count { dp[0][j] = j }
        for i in 1...aChars.count {
            for j in 1...bChars.count {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                dp[i][j] = min(dp[i - 1][j] + 1,
                               dp[i][j - 1] + 1,
                               dp[i - 1][j - 1] + cost)
            }
        }
        return dp[aChars.count][bChars.count]
    }
}
