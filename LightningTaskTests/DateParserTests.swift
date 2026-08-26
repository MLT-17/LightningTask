//
//  LightningTaskTests.swift
//  LightningTaskTests
//
//  Created by Matthias Tyca on 13.05.26.
//
import Foundation
import Testing
@testable import LightningTask

enum ParserError: Error {
    case noDate
}

@MainActor
struct DateParserTests {

    @Test func parseDateWithoutYear() async throws {
        let parser = DateParser()
        
        // format dd.mm
        let dateString = "14.05"
        guard let parsedDate = parser.parseDate(dateString, formats: dateFormats) else {
            throw ParserError.noDate
        }
        let parsedDateString = parsedDate.formatted(outputFormatStyle)
       
        #expect(parsedDateString == "14.05.2026")
        
      
    }
    
    @Test func parseDateWithoutYearEndingWithDot() async throws {
        let parser = DateParser()
        
        let dateStringWithDot = "14.05."
        guard let parsedDate = parser.parseDate(dateStringWithDot, formats: dateFormats) else {
            throw ParserError.noDate
        }
        let parsedDateString = parsedDate.formatted(outputFormatStyle)
        
        #expect(parsedDateString == "14.05.2026")
    }
    
    @Test func parseDateWithYearShort() async throws {
        let parser = DateParser()
        
        let dateStringWithYearShort = "14.05.26"
        guard let parsedDate = parser.parseDate(dateStringWithYearShort, formats: dateFormats) else {
            throw ParserError.noDate
        }
        let parsedDateString = parsedDate.formatted(outputFormatStyle)
        print(parsedDateString)
        #expect(parsedDateString == "14.05.2026")
    }
    
    @Test func parseDateWithYearLong() async throws {
        let parser = DateParser()
        
        let dateStringWithYearLong = "14.05.2026"
        guard let parsedDate = parser.parseDate(dateStringWithYearLong, formats: dateFormats) else {
            throw ParserError.noDate
        }
        let parsedDateString = parsedDate.formatted(outputFormatStyle)
        
        #expect(parsedDateString == "14.05.2026")
    }

}
