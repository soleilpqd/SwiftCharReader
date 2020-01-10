//
//  CharacterReader.swift
//  Pods-SwiftCharReader_Example
//
//  Created by DươngPQ on 1/9/20.
//

import Foundation

/// Character Reader Error
public enum CharacterReaderError: Error {
    /// Fail to open given file
    case failReading
    /// Unexpected EOF
    case unexpectedEOF
    /// Invalid UTF-8 data (found byte with unknow prefix bits)
    case corruptedData
}

/// Type for character reader handle closure: (read character, byte count of this character) -> `true` to continue reading
public typealias CharacterReaderHandleType = (Character, Int) -> Bool
/// Type for segment reader handle closure: (read segment, byte count of given segment, index of given segment) -> `true` to continue reading
public typealias SegmentReaderHandleType = (String, Int, Int) -> Bool

public let kUtf8SingleBytePrefix: UInt8    = 0b00000000
public let kUtf8SingleByteFilter: UInt8    = 0b10000000
public let kUtf8ComponentBytePrefix: UInt8 = 0b10000000
public let kUtf8ComponentByteFilter: UInt8 = 0b11000000
public let kUtf8TwoBytesPrefix: UInt8      = 0b11000000
public let kUtf8TwoBytesFilter: UInt8      = 0b11100000
public let kUtf8ThreeBytesPrefix: UInt8    = 0b11100000
public let kUtf8ThreeBytesFilter: UInt8    = 0b11110000
public let kUtf8FourBytesPrefix: UInt8     = 0b11110000
public let kUtf8FourBytesFilter: UInt8     = 0b11111000

/**
 Decode string from UTF-8 text data. Throw error if found invalid bytes in data.

 - Parameters:
    - data: UTF-8 text data.
    - handle: Closure to handle read character. Return `false` to stop reading.

 - Returns:
    - Result status: `false` if `handle` returned `false` (stop reading).
    - Data's not processed.
 */
public func decodeUtf8(data: Data, handle: CharacterReaderHandleType) throws -> (Bool, Data?) {
    var curCharData = [UInt8]()
    var expectedBCount = 0
    func processChar(byteIndex: Int, char: Character, charLen: Int, handle: CharacterReaderHandleType) -> (Bool, Data?) {
        var resultData: Data?
        let resultStatus = handle(char, charLen)
        if !resultStatus && byteIndex < data.count - 1 {
            resultData = Data(data[(byteIndex + 1)...])
        }
        return (resultStatus, resultData)
    }
    for (index, byte) in data.enumerated() {
        if curCharData.count == 0 {
            if (byte & kUtf8SingleByteFilter) == kUtf8SingleBytePrefix {
                expectedBCount = 0
                let char = Character(Unicode.Scalar(byte))
                let result = processChar(byteIndex: index, char: char, charLen: 1, handle: handle)
                if !result.0 {
                    return result
                }
            } else if (byte & kUtf8TwoBytesFilter) == kUtf8TwoBytesPrefix {
                expectedBCount = 2
                curCharData.append(byte)
            } else if (byte & kUtf8ThreeBytesFilter) == kUtf8ThreeBytesPrefix {
                expectedBCount = 3
                curCharData.append(byte)
            } else if (byte & kUtf8FourBytesFilter) == kUtf8FourBytesPrefix {
                expectedBCount = 4
                curCharData.append(byte)
            } else {
                throw CharacterReaderError.corruptedData
            }
        } else {
            if (byte & kUtf8ComponentByteFilter) == kUtf8ComponentBytePrefix {
                curCharData.append(byte)
                var charCode: Unicode.Scalar?
                if curCharData.count == expectedBCount {
                    switch expectedBCount {
                    case 2:
                        let binary: UInt16 = ((UInt16(curCharData[0]) << 6) & 0b0000011111000000) |
                            (UInt16(curCharData[1]) & 0b0000000000111111)
                        charCode = Unicode.Scalar(binary)
                    case 3:
                        let binary: UInt16 = ((UInt16(curCharData[0]) << 12) & 0b1111000000000000) |
                            ((UInt16(curCharData[1]) << 6) & 0b0000111111000000) |
                            (UInt16(curCharData[2]) & 0b0000000000111111)
                        charCode = Unicode.Scalar(binary)
                    case 4:
                        let binary: UInt32 = ((UInt32(curCharData[0]) << 18) & 0x001C0000) |
                            ((UInt32(curCharData[1]) << 12) & 0x0003F000) |
                            ((UInt32(curCharData[2]) << 6) & 0x00000FC0) |
                            (UInt32(curCharData[3]) & 0x0000003F)
                        charCode = Unicode.Scalar(binary)
                    default:
                        break
                    }
                    if let value = charCode {
                        let char = Character(value)
                        let result = processChar(byteIndex: index, char: char, charLen: expectedBCount, handle: handle)
                        if !result.0 {
                            return result
                        }
                    } else {
                        throw CharacterReaderError.corruptedData
                    }
                    curCharData.removeAll()
                }
            } else {
                throw CharacterReaderError.corruptedData
            }
         }
    }
    if curCharData.count > 0 {
        return (true, Data(curCharData))
    }
    return (true, nil)
}

/**
 Read UTF-8 text file, character by character. May throw error.
 This function runs in current thread & non-escaping.

 - Parameters:
   - path: Path to text file.
   - bufferSize: Buffer size (byte) to load data from file.
   - handle: Closure to handle read character. Return `false` to stop reading (other way: return `true` to continue reading).
*/
public func readUtf8(path: String, bufferSize: Int = 1024, handle: CharacterReaderHandleType) throws {
    guard let fileHandle = FileHandle(forReadingAtPath: path) else {
        throw CharacterReaderError.failReading
    }
    defer {
        fileHandle.closeFile()
    }
    var preData: Data?
    while true {
        var data = fileHandle.readData(ofLength: bufferSize)
        if data.count == 0 {
            break
        }
        if let preDat = preData {
            data = preDat + data
        }
        let result = try decodeUtf8(data: data, handle: handle)
        if result.0 {
            preData = result.1
        } else {
            preData = nil
            break
        }
    }
    if preData != nil {
        throw CharacterReaderError.unexpectedEOF
    }
}


/**
 Read UTF-8 text file character by character, notify when found given delimiter. May throw error.
 This function runs in current thread & non-escaping.
 Last line may not contain delimiter.

 - Parameters:
   - path: Path to text file.
   - bufferSize: Buffer size (byte) to load data from file.
   - delimiter: string to break the segment.
   - handle: Closure to handle read segment of text. Return `false` to stop reading (other way: return `true` to continue reading).
 */
public func readUtf8(path: String, bufferSize: Int = 1024, delimiter: String, handle: SegmentReaderHandleType) throws {
    var curSegment = ""
    var curSegCount = 0
    var curSegIndex = 0
    try readUtf8(path: path, bufferSize: bufferSize, handle: { (char, count) -> Bool in
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
    })
    if curSegment.count > 0 {
        _ = handle(curSegment, curSegCount, curSegIndex)
    }
}
