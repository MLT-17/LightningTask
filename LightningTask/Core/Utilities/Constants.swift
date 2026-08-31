//
//  Constants.swift
//  LightningTask
//
//  Created by Matthias Tyca on 21.08.26.
//

import Foundation

// Order matters: empirically verified (see DateParserTests) — don't reorder without re-running tests
let dateFormats = ["dd.MM", "dd.MM.", "dd.MM.yy", "dd.MM.yyyy"]
let timeFormats = ["HH:mm"]
let outputFormatStyle: Date.FormatStyle = .dateTime.day(.twoDigits).month(.twoDigits).year(.defaultDigits).locale(Locale(identifier: "de_DE"))

