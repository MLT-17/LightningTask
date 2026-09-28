//
//  DateConstants.swift
//  LightningTask
//
//  Created by Matthias Tyca on 21.08.26.
//

import Foundation

enum DateConstants {
    // Order matters: empirically verified (see DateParserTests) — don't reorder without re-running tests
    static let dateFormats = ["dd.MM", "dd.MM.", "dd.MM.yy", "dd.MM.yyyy"]
    static let timeFormats = ["HH:mm"]
}
