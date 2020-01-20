//
//  SwiftCSVParser.swift
//  Pods
//
//  Created by DươngPQ on 1/10/20.
//

import Foundation

/**
Type for CSV field handle closure.

- Parameters:
   - field: text cell.
   - row: row index (from 0).
   - column: column index (from 0).

- Returns: `true` to continue reading.
*/
public typealias CSVFieldHandleType = (_ field: String, _ row: Int, _ column: Int) -> Bool
/**
Type for CSV line handle closure.

 - Parameters:
   - row: last row index (from 0).

 - Returns: `true` to continue reading.
 */
public typealias CSVLineHandleType = (_ row: Int) -> Bool

public let kCRLF = "\r\n"
public let kLF = "\n"

public let CSVParserErrorDomain = "CSVErrorDomain"
public enum CSVParserError: Int {
    case invalidLineDelimiter = 1
    case unexpectedCharacter = 2
}

private extension Character.UnicodeScalarView {

    subscript(index: Int) -> Element {
        return self[self.index(self.startIndex, offsetBy: index)]
    }

}

private func isCharAfterClosingQuoteBelongToLineDelimiter(char: Character, lineDelimiter: String) -> Bool {
    if char.unicodeScalars.count < lineDelimiter.unicodeScalars.count {
        for (index, value) in char.unicodeScalars.enumerated() where value.value != lineDelimiter.unicodeScalars[index].value {
            return false
        }
        return true
    }
    return false
}

/**
 Read & parse CSV UTF-8 file, using `readUTF-8` which reads file character by character. May throw error.
 This function runs in current thread & non-escaping.

 - Parameters:
   - path: Path to text file.
   - bufferSize: Buffer size (byte) to load data from file.
   - fieldDelimiter: Character separates fields (default as standard is ',').
   - lineDelimiter: Character seperates row (line) (defautl as standard is CRLF).
   - fieldHandle: Closure to handle read field (cell). Return `false` to stop reading (other way: return `true` to continue reading).
   - lineHandle: Closure to handle the end of line. Return `false` to stop reading (other way: return `true` to continue reading).
*/
public func readCSVUtf8(path: String, bufferSize: Int = 1024, fieldDelimiter: Character = ",", lineDelimiter: String = kCRLF, fieldHandle: CSVFieldHandleType, lineHandle: CSVLineHandleType) throws {
    var lastCharacter: Character?
    var isQuoted = false
    var isQuoteClosed = false
    var currentField = ""
    var row = 0
    var column = 0
    var charIndex = 0
    var lineIndex = 0
    var error: NSError?
    try readUtf8(path: path, handle: { (char, _) -> Bool in
        var curIsQuoteClosed = false
        if char == fieldDelimiter {
            if isQuoted {
                currentField.append(char)
            } else { // end of field
                if !fieldHandle(currentField, row, column) {
                    return false
                }
                currentField = ""
                column += 1
            }
        } else if char == "\"" {
            if isQuoted { // quoted context, close quoting
                isQuoted = false
                curIsQuoteClosed = true
            } else if currentField.count == 0 { // not quoted, open quoting
                isQuoted = true
            } else if lastCharacter == "\"" { // last char is ", so this is escaping ", reopen quoting
                isQuoted = true
                currentField.append("\"")
            } else { // opening quote should be the first character of current field
                error = NSError(domain: CSVParserErrorDomain,
                                code: CSVParserError.unexpectedCharacter.rawValue,
                                userInfo: [NSLocalizedDescriptionKey: "Unexpected character '\(char)' at \(charIndex) on line \(lineIndex)."])
                return false
            }
        } else if isQuoteClosed && !isCharAfterClosingQuoteBelongToLineDelimiter(char: char, lineDelimiter: lineDelimiter) { // closing quote should be followed by field delimiter (or " for escaping) or new row
            error = NSError(domain: CSVParserErrorDomain,
                            code: CSVParserError.unexpectedCharacter.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: "Unexpected character '\(char)' at \(charIndex) on line \(lineIndex)."])
            return false
        } else {
            currentField.append(char)
            if !isQuoted && currentField.hasSuffix(lineDelimiter) { // end of line
                // end of line (record)
                currentField = String(currentField[..<currentField.index(currentField.endIndex, offsetBy: -lineDelimiter.count)])
                if !fieldHandle(currentField, row, column) {
                    return false
                }
                if !lineHandle(row) {
                    return false
                }
                currentField = ""
                charIndex = 0
                column = 0
                row += 1
            }
        }
        lastCharacter = char
        if char == "\n" {
            lineIndex += 1
            charIndex = 0
        } else {
            charIndex += 1
        }
        isQuoteClosed = curIsQuoteClosed
        return true
    })
    if let err = error {
        throw err
    }
    if currentField.count > 0 {
        _ = fieldHandle(currentField, row, column)
    }
}
