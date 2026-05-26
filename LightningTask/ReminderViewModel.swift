//
//  ReminderViewModel.swift
//  LightningTask
//
//  Created by Matthias Tyca on 19.05.26.
//
import EventKit
import Foundation


@Observable class ReminderViewModel {
    var reminderStore = EKEventStore()
    var reminderLists: [EKCalendar] = []
    
    init() {
        Task {
            do {
                try await requestAccess()
                print("Request granted")
                self.reminderLists = fetchLists()
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
    
    func createReminder(text: String) async {
        let reminder = EKReminder(eventStore: reminderStore)
        reminder.title = text
        reminder.calendar = reminderStore.defaultCalendarForNewReminders()
        do {
           try reminderStore.save(reminder, commit: true)
        } catch {
            print("Failed to save reminder with text: \(text)")
        }
    }
}
