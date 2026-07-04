//
//  TaskSuggestion.swift
//  LightningTask
//
//  Model for AI-generated task suggestions
//

import Foundation
import FoundationModels

/// AI-generated suggestion for a task created from user input
/// Conforms to @Generable to work with Foundation Models structured generation
@Generable
struct TaskSuggestion {
    /// The pure task title(s), without list names, dates, or times
    /// Multiple items when input contains comma-separated or "and"-connected tasks
    var items: [String]
    
    /// Suggested reminder lists, ordered by relevance (most specific first)
    var listNames: [String]
    
    /// Due date in ISO format (YYYY-MM-DD), empty string if no date mentioned
    var dueDate: String
    
    /// Due time in 24-hour format (HH:mm), empty string if no time mentioned
    var dueTime: String
}
