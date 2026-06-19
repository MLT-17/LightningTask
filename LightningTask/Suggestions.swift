//
//  Suggestions.swift
//  LightningTask
//
//  Created by Matthias Tyca on 26.05.26.
//

import Foundation
import FoundationModels

@Generable
struct TaskSuggestion {
    //@Guide(description: "Der/Die reine/n Task-Titel. Listenname, Datum und Uhrzeit dürfen nicht enthalten sein. Nur die eigentliche Aufgabe/n. Bei mehreren Items aufgeteilt")
    var items: [String]
    //@Guide(description: "Passende Listen absteigend nach Relevanz, spezifischste zuerst")
    var listNames: [String]
    //@Guide(description: "Datum im Format YYYY-MM-DD falls in Task genannt, sonst leerer String")
    var dueDate: String
    //@Guide(description: "Uhrzeit im Format HH:mm falls in Task genannt, sonst leerer String")
    var dueTime: String
}
