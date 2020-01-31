//
//  CharacterReader.swift
//  Pods
//
//  Created by DươngPQ on 1/30/20.
//

import Foundation

public enum CharacterReaderEncoding {
    case utf8
    case utf16be
    case utf16le
}

/// Character Reader Error
public enum CharacterReaderError: Error {
    /// Fail to open given file
    case failReading
    /// Unexpected EOF
    case unexpectedEOF
    /// Invalid UTF-8 data (found byte with unknow prefix bits)
    case corruptedData
}

/**
 Type for character reader handle closure.

 - Parameters:
   - char: Read character.
   - count: Length in byte of given character.

 - Returns: `true` to continue reading.
 */
public typealias CharacterReaderHandleType = (_ char: Character, _ count: Int) -> Bool
/**
 Type for segment reader handle closure.

 - Parameters:
   - segment: Read segment of text.
   - count: Length in byte of given text segment.
   - index: index of given text segment.

 - Returns: `true` to continue reading.
 */
public typealias SegmentReaderHandleType = (_ segment: String, _ count: Int, _ index: Int) -> Bool

/**
 Read text file character by character, notify when found given delimiter. May throw error.
 This function runs in current thread & non-escaping.
 Last line may not contain delimiter.

 - Parameters:
   - path: Path to text file.
   - bufferSize: Buffer size (byte) to load data from file. Default 4KB.
   - delimiter: string to break the segment.
   - handle: Closure to handle read segment of text. Return `false` to stop reading (other way: return `true` to continue reading).
 */
public func readSegments(path: String, delimiter: String, encoding: CharacterReaderEncoding = .utf8, bufferSize: Int = 4096, handle: SegmentReaderHandleType) throws {
    var curSegment = ""
    var curSegCount = 0
    var curSegIndex = 0
    let charHandle: CharacterReaderHandleType = { (char, count) -> Bool in
        curSegment.append(char)
        curSegCount += count
        if curSegment.hasSuffix(delimiter) {
            let result = handle(curSegment, curSegCount, curSegIndex)
            curSegment = ""
            curSegCount = 0
            curSegIndex += 1
            return result
        }
        return true
    }
    switch encoding {
    case .utf8:
        try readUtf8(path: path, bufferSize: bufferSize, handle: charHandle)
    case.utf16be:
        try readUtf16be(path: path, bufferSize: bufferSize, handle: charHandle)
    case .utf16le:
        try readUtf16le(path: path, bufferSize: bufferSize, handle: charHandle)
    }
    if curSegment.count > 0 {
        _ = handle(curSegment, curSegCount, curSegIndex)
    }
}
