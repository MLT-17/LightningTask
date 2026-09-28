//
//  QuickEntryError.swift
//  LightningTask
//
//  Created by Matthias Tyca on 24.09.26.
//

import Foundation

enum QuickEntryError: Error, Equatable {
    case modelUnavailable
    case suggestionFailed
    case permissionDenied
    case saveFailed

    var message: String {
            switch self {
            case .modelUnavailable: String(localized: "error_model_unavailable")
            case .suggestionFailed: String(localized: "error_suggestion_failed")
            case .permissionDenied: String(localized: "error_permission_denied")
            case .saveFailed: String(localized: "error_save_failed")
            }
        }
}
