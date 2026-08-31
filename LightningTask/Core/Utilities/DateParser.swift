//
//  DateParser.swift
//  LightningTask
//
//  Created by Matthias Tyca on 21.08.26.
//
import Foundation

@MainActor
struct DateParser {
    let parser: DateFormatter
    
    init() {
        parser = DateFormatter()
        parser.locale = Locale(identifier: "de_DE") //TODO: Locale auslesen
        parser.defaultDate = Date()
        parser.isLenient = false
    }
    
    // MARK: - Parsing (Text → Date)
    
    func parseDate(_ dateString: String, formats: [String]) -> Date? {
        return parse(dateString, stringFormats: formats)
    }
    
    func parseTime(_ timeString: String, formats: [String]) -> Date? {
        return parse(timeString, stringFormats: formats)
    }
    
    // MARK: - Display (Date → formatted String)
    
    func displayDateString(from date: Date) -> String { format(date, as: "EE, d. MMM") }
    func displayTimeString(from date: Date) -> String { format(date, as: "HH:mm") }
    
    // MARK: - Storage (Date → "yyyy-MM-dd" / "HH:mm", for storing back to TaskSuggestion)
    
    func storageDateString(from date: Date) -> String { format(date, as: "yyyy-MM-dd") }
    func storageTimeString(from date: Date) -> String { format(date, as: "HH:mm") }
    
    // MARK: - Storage to Date/Time
    func parseStorageDate(_ dateString: String) -> Date? {
        parser.dateFormat = "yyyy-MM-dd"
        return parser.date(from: dateString)
    }

    func parseStorageTime(_ timeString: String) -> Date? {
        parser.dateFormat = "HH:mm"
        return parser.date(from: timeString)
    }
    
    // MARK: - Private
    
    private func parse(_ dateOrTimeString: String, stringFormats: [String]) -> Date? {
        for format in stringFormats {
            parser.dateFormat = format
            if let date = parser.date(from: dateOrTimeString) {
                return date
            }
        }
        return nil
    }
    
    private func format(_ date: Date, as dateFormat: String) -> String {
        parser.dateFormat = dateFormat
        return parser.string(from: date)
    }
}
