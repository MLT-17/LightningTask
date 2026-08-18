//
//  AIPromptBuilder.swift
//  LightningTask
//
//  Locale-aware prompt builder for AI task suggestions
//

import Foundation

/// Builds locale-aware prompts for AI task suggestion generation
struct AIPromptBuilder {
    
    let locale: Locale
    
    init(locale: Locale = AppConfiguration.shared.locale) {
        self.locale = locale
    }
    
    /// Builds a prompt for task suggestion based on the current locale
    func buildPrompt(
        taskTitle: String,
        listNames: String,
        today: String,
        tomorrow: String
    ) -> String {
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        
        switch languageCode {
        case "de":
            return buildGermanPrompt(
                taskTitle: taskTitle,
                listNames: listNames,
                today: today,
                tomorrow: tomorrow
            )
        default:
            return buildEnglishPrompt(
                taskTitle: taskTitle,
                listNames: listNames,
                today: today,
                tomorrow: tomorrow
            )
        }
    }
    
    // MARK: - German Prompt
    
    private func buildGermanPrompt(
        taskTitle: String,
        listNames: String,
        today: String,
        tomorrow: String
    ) -> String {
        """
        Das heutige Datum: \(today)
        
        Du kategorisierst Tasks in Listen und extrahierst Datum und Uhrzeit.
        
        TOP-REGEL ZEIT: 
        - dueTime ist EXAKT der leere String "", außer der User nennt eine explizite 
          Uhrzeit ("8 Uhr", "14:30", "halb 9", "morgens"). NIEMALS "00:00" als Default.
        - dueDate ist EXAKT der leere String "", außer der User nennt ein explizites 
          Datum ("morgen", "Freitag", "15. August").
        - WICHTIG: Wenn dueTime gesetzt ist (nicht leer) aber dueDate leer wäre, 
          dann MUSS dueDate auf \(today) gesetzt werden. Eine Uhrzeit ohne Datum 
          bedeutet immer heute.
        
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
        \(listNames)
        
        BEISPIELE:
        "Milch kaufen" → items: ["Milch kaufen"], listNames: ["Einkäufe"], dueDate: "", dueTime: "" ← KEIN Datum, KEINE Uhrzeit
        "Auto putzen morgen" → items: ["Auto putzen"], listNames: ["Privat", "Inbox"], dueDate: "\(tomorrow)", dueTime: "" ← Datum genannt, aber KEINE Uhrzeit → dueTime leer
        "Weitermachen in LightningTask" → items: ["Weitermachen"], listNames: ["LightningTask"], dueDate: "", dueTime: "" ← Listenname wörtlich genannt → muss erste Liste sein
        "Planung in metanoy General morgen 8 Uhr" → items: ["Planung"], listNames: ["metanoy General"], dueDate: "\(tomorrow)", dueTime: "08:00"
        "3 Bananen, 4x Quark" → items: ["3 Bananen", "4x Quark"], listNames: ["Einkäufe"], dueDate: "", dueTime: ""
        "metaLOG ios weitermachen" → items: ["weitermachen"], listNames: ["metaLOG iOS/Mac"], dueDate: "", dueTime: "" ← eindeutig, "ios" passt nur zu einer Liste
        "metalog weitermachen" → items: ["weitermachen"], listNames: ["metaLOG", "metaLOG iOS/Mac", "metaLOG Electron"], dueDate: "", dueTime: "" ← mehrdeutig, kein Disambiguator
        "Einkaufen 12:00" → items: ["Einkaufen"], listNames: ["Einkäufe"], dueDate: "\(today)", dueTime: "12:00" ← Nur Uhrzeit genannt → Datum automatisch heute
        
        TASK:
        "\(taskTitle)"
        """
    }
    
    // MARK: - English Prompt
    
    private func buildEnglishPrompt(
        taskTitle: String,
        listNames: String,
        today: String,
        tomorrow: String
    ) -> String {
        """
        Today's date: \(today)
        
        You categorize tasks into lists and extract date and time information.
        
        TOP RULE TIME: dueTime is EXACTLY the empty string "", unless the user specifies
        an explicit time ("8am", "14:30", "half past 9", "morning"). NEVER use "00:00"
        as a default — "00:00" means "midnight" and is only allowed if the user really
        means that. Same principle for dueDate: empty, unless a concrete date was mentioned.
        "today", "now", "soon" do NOT count as date specifications.
        EXCEPTION: If a time is mentioned (dueTime not empty) but NO date was mentioned,
        then set dueDate to \(today). A time without a date always means today.
        
        TOP RULE LIST: If the user mentions a list name from AVAILABLE LISTS below
        VERBATIM (even with different capitalization) in the task, that exact list MUST
        be first in listNames. Even if the rest of the task sounds generic.
        
        RULES:
        - Extract the pure task title: without list names, without date, without time.
          Also remove connecting words like "in", "on", "for" + list name.
        - Resolve relative dates ("tomorrow", "Friday", "in 2 weeks") relative to today.
        - dueDate ALWAYS in ISO format: "YYYY-MM-DD". Empty if no date.
        - dueTime ALWAYS as "HH:mm". Empty if no time.
        - listNames: only values EXACTLY from the list below — no variations, no
          plural forms, no inventions.
        - listNames selection: return only ONE list if clearly only one fits
          (unambiguous match, e.g., because the user used a disambiguator like "iOS",
          "Electron" or the list name verbatim).
          If multiple lists share the same stem and no disambiguator was mentioned
          → return ALL plausible candidates, most specific first, most general last.
        - Multiple tasks separated by comma or "and" → multiple items.
        - Keep quantity specifications in title: "3 bananas" stays "3 bananas".
        
        AVAILABLE LISTS (use exactly as shown):
        \(listNames)
        
        EXAMPLES:
        "Buy milk" → items: ["Buy milk"], listNames: ["Shopping"], dueDate: "", dueTime: "" ← NO date, NO time
        "Wash car tomorrow" → items: ["Wash car"], listNames: ["Personal", "Inbox"], dueDate: "\(tomorrow)", dueTime: "" ← Date mentioned, but NO time → dueTime empty
        "Continue in LightningTask" → items: ["Continue"], listNames: ["LightningTask"], dueDate: "", dueTime: "" ← List name mentioned verbatim → must be first list
        "Planning in metanoy General tomorrow 8am" → items: ["Planning"], listNames: ["metanoy General"], dueDate: "\(tomorrow)", dueTime: "08:00"
        "3 bananas, 4x yogurt" → items: ["3 bananas", "4x yogurt"], listNames: ["Shopping"], dueDate: "", dueTime: ""
        "Shopping 12:00" → items: ["Shopping"], listNames: ["Shopping"], dueDate: "\(today)", dueTime: "12:00" ← Only time mentioned → date is today
        
        TASK:
        "\(taskTitle)"
        """
    }
}
