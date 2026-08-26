//
//  ReminderViewModel.swift
//  LightningTask
//
//  ViewModel for the quick entry panel
//  Coordinates between UI, ReminderService, and AIService
//

import EventKit
import Foundation
import FoundationModels
import os

@Observable class ReminderViewModel {
    
    // MARK: - Dependencies
    
    private let reminderService: ReminderService
    private let aiService: AIService
    
    // MARK: - Logging
    
    private let logger = Logger(subsystem: "de.mlt.LightningTask", category: "ReminderViewModel")
    
    // MARK: - State
    
    /// User input text for the new task
    var todo: String = ""
    
    /// AI-generated suggestion for the current input
    var suggestion: TaskSuggestion?
    
    /// Currently selected list name (nil if none selected)
    var selected: String?
    
    /// Whether an alarm should be created with the reminder
    var alarmEnabled: Bool = true
    
    /// Indicates if a save operation is in progress
    private(set) var isSaving: Bool = false
    
    // MARK: - Computed Properties
    
    var reminderLists: [EKCalendar] {
        reminderService.reminderLists
    }
    
    var modelAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }
    
    // MARK: - Initialization
    
    /// Initializes the ViewModel with injected dependencies
    /// - Parameters:
    ///   - reminderService: Service for managing reminders (defaults to ReminderService())
    ///   - aiService: Service for AI suggestions (defaults to AIService())
    init(
        reminderService: ReminderService = ReminderService(),
        aiService: AIService = AIService()
    ) {
        self.reminderService = reminderService
        self.aiService = aiService
        
        Task {
            do {
                try await reminderService.requestAccess()
                logger.info("✅ Reminder access granted")
                _ = reminderService.fetchLists()
                logger.info("📋 Model available: \(self.modelAvailable)")
            } catch {
                logger.error("❌ Reminder access denied: \(error)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Saves the current task(s) to Reminders
    /// Returns true if successful, false otherwise
    func saveCurrentItems() async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }
        
        let items = suggestion?.items ?? [todo]
        
        var didCompleteSaving = true
        
        for item in items {
            let options = ReminderService.ReminderOptions(
                text: item,
                listName: selected ?? "",
                dueDate: suggestion?.dueDate ?? "",
                dueTime: suggestion?.dueTime ?? "",
                alarmEnabled: alarmEnabled
            )
            do {
                try reminderService.createReminder(options: options)
            } catch {
                logger.error("❌ Failed to save reminder: \(error)")
                didCompleteSaving = false
            }
        }
        return didCompleteSaving
    }
    
    /// Refreshes AI suggestions for the current `todo` text
    /// Debounced (500ms) and respects Task cancellation
    func refreshSuggestion() async {
        guard todo.count > 2, modelAvailable else { return }
        
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        
        do {
            suggestion = try await generateSuggestion(for: todo)
            logger.debug("📅 Raw AI dueDate: '\(self.suggestion?.dueDate ?? "nil")'")  
            selected = suggestion?.listNames.first
            alarmEnabled = true
        } catch {
            logger.warning("⚠️ Failed to generate suggestion: \(error)")
        }
    }
    
    /// Resets the form state after saving
    func reset() {
        suggestion = nil
        todo = ""
        selected = nil
        alarmEnabled = true
    }
    
    // MARK: - Date Handling
    
    private let dateParser = DateParser()
    
    /// Two-way binding for the suggested date
    /// Get: parsed date (or now if none). Set: updates dueDate/dueTime in suggestion
    var selectedDateText: String {
        get { suggestedDateString()}
        set { updateSuggestionDate(newValue) }
        
    }
    
    var selectedTimeText: String {
        get { suggestedTimeString()}
        set { updateSuggestionTime(newValue) }
    }
    
    /// Returns a formatted string for the suggested date/time
    func suggestedDateString() -> String {
        guard let date = parseDateFromSuggestion() else { return "" }
        return dateParser.displayDateString(from: date)
    }
    
    func suggestedTimeString() -> String {
        guard let time = parseTimeFromSuggestion() else { return "" }
        return dateParser.displayTimeString(from: time)
    }
    
    // MARK: - Private Helpers
    
    private func generateSuggestion(for taskTitle: String) async throws -> TaskSuggestion {
        let filteredLists = reminderService.relevantLists(for: taskTitle)
        let listNames = filteredLists.map { $0.title }
        
        var suggestion = try await aiService.suggestTask(
            for: taskTitle,
            availableLists: listNames
        )
        
        logger.debug("🤖 Raw AI listNames: \(suggestion.listNames)")
        
        // Post-process: snap to available lists
        let matcher = ListNameMatcher(availableListNames: reminderLists.map { $0.title })
        suggestion.listNames = matcher.snapToAvailableLists(suggestion.listNames)
        logger.debug("📍 After snap: \(suggestion.listNames)")
        
        // Deterministic fallback: token-based scoring for obvious matches
        let tokenMatcher = TokenBasedListMatcher(listTitles: reminderLists.map { $0.title })
        let tokenCandidates = tokenMatcher.candidateLists(for: taskTitle).prefix(4)
        logger.debug("🎯 Token candidates: \(Array(tokenCandidates))")
        
        for candidate in tokenCandidates.reversed() {
            suggestion.listNames.removeAll { $0 == candidate }
            suggestion.listNames.insert(candidate, at: 0)
        }
        
        // Strip verbatim list names from item titles
        let detector = VerbatimListNameDetector(listTitles: reminderLists.map { $0.title })
        let verbatim = detector.matches(in: taskTitle)
        if !verbatim.isEmpty {
            suggestion.items = suggestion.items.map { detector.stripListNames($0, names: verbatim) }
        }
        
        // Always include system default list as fallback
        let defaultListName = reminderService.defaultList()?.title
        ?? AppConfiguration.shared.fallbackListName
        if !suggestion.listNames.contains(defaultListName) {
            suggestion.listNames.append(defaultListName)
        }
        
        return suggestion
    }
    
    private func parseDateFromSuggestion() -> Date? {
        guard let suggestion = suggestion, !suggestion.dueDate.isEmpty else { return nil }
        
        return dateParser.parseStorageDate(suggestion.dueDate)
    }
    
    private func parseTimeFromSuggestion() -> Date? {
        guard let suggestion = suggestion, !suggestion.dueTime.isEmpty else { return nil }
           return dateParser.parseStorageTime(suggestion.dueTime)
    }
    
    private func updateSuggestionDate(_ newValue: String) {
        guard var suggestion = suggestion else { return }
        
        if newValue == "" {
            suggestion.dueDate = ""
            suggestion.dueTime = ""
            self.suggestion = suggestion
            return
        }
        
        if let date = dateParser.parseDate(newValue, formats: dateFormats) {
            let dateString = dateParser.storageDateString(from: date)
            suggestion.dueDate = dateString
            self.suggestion = suggestion
        }
    }
    
    private func updateSuggestionTime(_ newValue: String) {
        guard var suggestion = suggestion else { return }
        
        if newValue == "" {
            suggestion.dueTime = ""
            self.suggestion = suggestion
            return
        }
        
        if let time = dateParser.parseTime(newValue, formats: timeFormats) {
            let timeString = dateParser.storageTimeString(from: time)
            
            // if no date yet, set to today
            if suggestion.dueDate.isEmpty {
                suggestion.dueDate = dateParser.storageDateString(from: Date.now)
            }
            
            suggestion.dueTime = timeString
            self.suggestion = suggestion
        }
    }
}
