import Foundation

let parser = DateParser()

// Beispielaufruf:
let input = "24.08."

if let parsedDate = parser.parseDate(input, formats: dateFormats) {
    print("Erfolgreich geparst: \(parsedDate.formatted(date: .abbreviated, time: .omitted))")
} else {
    print("Kein passendes Format gefunden.")
}

let timeInput = "18:00"

if let parsedTime = parser.parseTime(timeInput, formats: timeFormats) {
    print("Erfolgreich geparst: \(parsedTime.formatted(date: .omitted, time: .shortened))")
} else {
    print("Kein passendes Format gefunden.")
}

