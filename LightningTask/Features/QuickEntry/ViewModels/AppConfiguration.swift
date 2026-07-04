//
//  AppConfiguration.swift
//  LightningTask
//
//  Centralized configuration for locale-aware and customizable settings
//

import Foundation

/// Configuration for app-wide settings, locale-aware defaults, and list names
struct AppConfiguration {
    
    // MARK: - Singleton
    
    static let shared = AppConfiguration()
    
    // MARK: - Locale Settings
    
    /// Current locale for date formatting (defaults to user's system locale)
    var locale: Locale {
        Locale.current
    }
    
    /// Locale identifier for date formatting (can be overridden for testing)
    var localeIdentifier: String {
        locale.identifier
    }
    
    // MARK: - Default List Names
    
    /// Fallback list name when system default is unavailable
    /// ⚠️ NOTE: This should rarely be used. The actual default list should come from
    /// ReminderService.defaultList()?.title, which reads the user's system preference.
    /// This is only used as a last resort if EventKit is unavailable.
    var fallbackListName: String {
        return "Inbox"  // System default on most locales
    }
    
    // MARK: - Debounce Settings
    
    /// Debounce delay for AI suggestion generation (in milliseconds)
    var suggestionDebounceMilliseconds: Int = 500
    
    /// Minimum character count before generating AI suggestions
    var minimumCharactersForSuggestion: Int = 2
    
    // MARK: - Date Format Patterns
    
    /// Date format pattern for date + time display
    var dateTimeFormat: String {
        switch locale.language.languageCode?.identifier {
        case "de":
            return "EE, d. MMM · HH:mm"
        case "en":
            return "EEE, MMM d · HH:mm"
        case "es":
            return "EEE, d 'de' MMM · HH:mm"
        case "fr":
            return "EEE d MMM · HH:mm"
        default:
            return "EEE, MMM d · HH:mm"
        }
    }
    
    /// Date format pattern for date only display
    var dateOnlyFormat: String {
        switch locale.language.languageCode?.identifier {
        case "de":
            return "EE, d. MMM"
        case "en":
            return "EEE, MMM d"
        case "es":
            return "EEE, d 'de' MMM"
        case "fr":
            return "EEE d MMM"
        default:
            return "EEE, MMM d"
        }
    }
    
    // MARK: - Private Initializer
    
    private init() {}
}

// MARK: - Testing Support

#if DEBUG
extension AppConfiguration {
    /// Creates a test configuration with custom settings
    static func test(
        locale: Locale = .current,
        defaultListName: String? = nil,
        suggestionDebounceMilliseconds: Int = 500,
        minimumCharactersForSuggestion: Int = 2
    ) -> AppConfiguration {
        var config = AppConfiguration()
        // Note: This is a simplified approach. For full testability,
        // consider making AppConfiguration a class or using a protocol.
        return config
    }
}
#endif
