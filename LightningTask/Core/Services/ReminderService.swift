//
//  ReminderService.swift
//  LightningTask
//
//  Handles all EventKit interactions for reminders
//

import EventKit
import Foundation
import os

/// Service responsible for managing reminders through EventKit
@Observable class ReminderService {
    private let store = EKEventStore()
    private(set) var reminderLists: [EKCalendar] = []
    
    // MARK: - Logging
    
    private let logger = Logger(subsystem: "com.yourcompany.LightningTask", category: "ReminderService")
    
    // MARK: - Static Date Formatters
    // ✅ Reuse formatters instead of creating new instances every time
    
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Authorization
    
    func requestAccess() async throws {
        try await store.requestFullAccessToReminders()
    }
    
    // MARK: - List Management
    
    func fetchLists() -> [EKCalendar] {
        let calendars = store.calendars(for: .reminder)
        reminderLists = calendars
        return calendars
    }
    
    func defaultList() -> EKCalendar? {
        return store.defaultCalendarForNewReminders()
    }
    
    // MARK: - Reminder Creation
    
    struct ReminderOptions {
        let text: String
        let listName: String
        let dueDate: String
        let dueTime: String
        let alarmEnabled: Bool
        
        init(text: String, listName: String, dueDate: String = "", dueTime: String = "", alarmEnabled: Bool = true) {
            self.text = text
            self.listName = listName
            self.dueDate = dueDate
            self.dueTime = dueTime
            self.alarmEnabled = alarmEnabled
        }
    }
    
    func createReminder(options: ReminderOptions) throws {
        let reminder = EKReminder(eventStore: store)
        reminder.title = options.text
        
        // Set the reminder list
        logger.debug("\(String(localized: "looking_for_list")): \(options.listName)")
        logger.debug("\(String(localized: "available_lists")): \(self.reminderLists.map { $0.title })")
        reminder.calendar = reminderLists.first(where: { $0.title == options.listName })
            ?? store.defaultCalendarForNewReminders()
        
        // Set date — time only if explicitly provided (otherwise date-only reminder)
        // If only time is provided without date, today is used as the date
        if !(options.dueDate.isEmpty && options.dueTime.isEmpty) {
            let hasTime = !options.dueTime.isEmpty
            let today = Date.now.formatted(.iso8601.year().month().day())
            let dateString = options.dueDate.isEmpty ? today : options.dueDate
            
            // ✅ Use static formatters instead of creating new instances
            let formatter = hasTime ? Self.dateTimeFormatter : Self.dateOnlyFormatter
            let input = hasTime ? "\(dateString) \(options.dueTime)" : dateString
            if let date = formatter.date(from: input) {
                let components: Set<Calendar.Component> = hasTime
                    ? [.year, .month, .day, .hour, .minute]
                    : [.year, .month, .day]
                reminder.dueDateComponents = Calendar.current.dateComponents(components, from: date)
                
                if options.alarmEnabled {
                    let alarm = EKAlarm(relativeOffset: 0)
                    reminder.addAlarm(alarm)
                }
            }
        }
        
        do {
            logger.debug("\(String(localized: "alarms")): \(reminder.alarms ?? [])")
            // ✅ store.save is synchronous, no await needed
            try store.save(reminder, commit: true)
        } catch {
            logger.error("\(String(localized: "failed_to_save_reminder")): \(options.text)")
            throw error
        }
    }
    
    // MARK: - List Filtering
    
    /// Returns reminder lists relevant to the given input text
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
            // Fallback: include default list and a few most recently used ones
            var fallbackLists: [EKCalendar] = []
            if let defaultList = store.defaultCalendarForNewReminders() {
                fallbackLists.append(defaultList)
            }
            // Add first few lists as additional fallbacks (most likely to be used)
            fallbackLists.append(contentsOf: reminderLists.prefix(3))
            return Array(Set(fallbackLists)) // Remove duplicates
        }
        
        // Top-Matches + immer Inbox als Fallback dabei
        var result = matches.prefix(5).map { $0.0 }
        let standardListTitle: String = store.defaultCalendarForNewReminders()?.title ?? ""
        if let defaultList = reminderLists.first(where: { $0.title == standardListTitle }),
           !result.contains(where: { $0.calendarIdentifier == defaultList.calendarIdentifier }) {
            result.append(defaultList)
        }
        return result
    }
}
