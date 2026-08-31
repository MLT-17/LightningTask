//
//  AIService.swift
//  LightningTask
//
//  Handles AI-powered task suggestions using Foundation Models
//

import Foundation
import FoundationModels

/// Service responsible for generating AI-powered task suggestions
actor AIService {
    
    // MARK: - Dependencies
    
    private let promptBuilder: AIPromptBuilder
    
    // MARK: - Initialization
    
    init(promptBuilder: AIPromptBuilder = AIPromptBuilder()) {
        self.promptBuilder = promptBuilder
    }
    
    // MARK: - Public Interface
    
    var isModelAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }
    
    /// Generates task suggestions based on input text and available reminder lists
    func suggestTask(
        for taskTitle: String,
        availableLists: [String]
    ) async throws -> TaskSuggestion {
        let model = SystemLanguageModel.default
        let session = LanguageModelSession(model: model)
        
        let listNamesString = availableLists.joined(separator: ", ")
        let today = String(ISO8601DateFormatter().string(from: .now).prefix(10))
        let tomorrow = String(ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: 1, to: .now)!).prefix(10))
        
        let prompt = promptBuilder.buildPrompt(
            taskTitle: taskTitle,
            listNames: listNamesString,
            today: today,
            tomorrow: tomorrow
        )
        
        let response = try await session.respond(
            to: prompt,
            generating: TaskSuggestion.self
        )
        
        var suggestion = response.content
        // Post-processing: set date as today if only time is set
        if !suggestion.dueTime.isEmpty && suggestion.dueDate.isEmpty {
            suggestion.dueDate = today
        }

        
        return suggestion
    }
}
