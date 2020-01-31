//
//  CharacterReader.swift
//  Pods-SwiftCharReader_Example
//
//  Created by DươngPQ on 1/9/20.
//

import Foundation

public func makeWordFromBigEndianBytes(_ byte1: UInt8, _ byte2: UInt8) -> UInt16 {
    return (UInt16(byte1) << 8) | UInt16(byte2)
}

public func makeWordFromLittleEndianBytes(_ byte1: UInt8, _ byte2: UInt8) -> UInt16 {
    return makeWordFromBigEndianBytes(byte2, byte1)
}
/**
 Check 2 UTF-16 BigEndian bytes range.

 - returns:
   - nil if 2 given bytes are surrogate pair.
   - code point if 2 given bytes are corresponding code
 */
private func checkUtf16beCodeRange(byte1: UInt8, byte2: UInt8) -> UInt16? {
    let value = makeWordFromBigEndianBytes(byte1, byte2)
    switch value {
    case 0x0000...0xD7FF, 0xE000...0xFFFF:
        return value
    case 0xD800...0xDFFF:
        return nil
    default:
        break
    }
    return value // not reachable
}

/**
 Check 2 UTF-16 LittleEndian bytes range.

 - returns:
   - nil if 2 given bytes are surrogate pair.
   - code point if 2 given bytes are corresponding code
 */
private func checkUtf16leCodeRange(byte1: UInt8, byte2: UInt8) -> UInt16? {
    return checkUtf16beCodeRange(byte1: byte2, byte2: byte1)
}

private func decodeUtf16(data: Data, isBigEndian: Bool, handle: CharacterReaderHandleType) throws -> (Bool, Data?) {
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
        curCharData.append(byte)
        switch curCharData.count {
        case 2:
            if let code = isBigEndian ? checkUtf16beCodeRange(byte1: curCharData[0], byte2: curCharData[1]) : checkUtf16leCodeRange(byte1: curCharData[0], byte2: curCharData[1]) {
                if let charCode = Unicode.Scalar(code) {
                    let char = Character(charCode)
                    let result = processChar(byteIndex: index, char: char, charLen: 2, handle: handle)
                    if !result.0 {
                        return result
                    }
                } else {
                    throw CharacterReaderError.corruptedData
                }
                curCharData.removeAll()
            }
        case 4:
            var highSurrogate = isBigEndian ? makeWordFromBigEndianBytes(curCharData[0], curCharData[1]) : makeWordFromLittleEndianBytes(curCharData[0], curCharData[1])
            if highSurrogate >= 0xD800 {
                highSurrogate -= 0xD800
            } else {
                throw CharacterReaderError.corruptedData
            }
            let tmp = UInt64(highSurrogate) * 0x0400
            if tmp > UInt16.max {
                throw CharacterReaderError.corruptedData
            }
            highSurrogate = UInt16(tmp)
            var lowSurrogate = isBigEndian ? makeWordFromBigEndianBytes(curCharData[2], curCharData[3]) : makeWordFromLittleEndianBytes(curCharData[2], curCharData[3])
            if lowSurrogate >= 0xDC00 {
                lowSurrogate -= 0xDC00
            } else {
                throw CharacterReaderError.corruptedData
            }
            let code = UInt32(highSurrogate) + UInt32(lowSurrogate) + 0x10000
            if let charCode = Unicode.Scalar(code) {
                let char = Character(charCode)
                let result = processChar(byteIndex: index, char: char, charLen: 2, handle: handle)
                if !result.0 {
                    return result
                }
            } else {
                throw CharacterReaderError.corruptedData
            }
            curCharData.removeAll()
        default:
            break
        }
    }
    if curCharData.count > 0 {
        return (true, Data(curCharData))
    }
    return (true, nil)
}

/**
 Decode string from UTF-16 BigEndian text data. Throw error if found invalid bytes in data.

 - Parameters:
   - data: UTF-16 BigEndian text data.
   - handle: Closure to handle read character. Return `false` to stop reading.

 - Returns:
   - Result status: `false` if `handle` returned `false` (stop reading).
   - Data's not processed.
 */
public func decodeUtf16be(data: Data, handle: CharacterReaderHandleType) throws -> (Bool, Data?) {
    return try decodeUtf16(data: data, isBigEndian: true, handle: handle)
}

/**
 Decode string from UTF-16 LittleEndian text data. Throw error if found invalid bytes in data.

 - Parameters:
   - data: UTF-16 LittleEndian text data.
   - handle: Closure to handle read character. Return `false` to stop reading.

 - Returns:
   - Result status: `false` if `handle` returned `false` (stop reading).
   - Data's not processed.
 */
public func decodeUtf16le(data: Data, handle: CharacterReaderHandleType) throws -> (Bool, Data?) {
    return try decodeUtf16(data: data, isBigEndian: false, handle: handle)
}

private func readUtf16(path: String, bufferSize: Int, isBigEndian: Bool, handle: CharacterReaderHandleType) throws {
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
        let result = try decodeUtf16(data: data, isBigEndian: isBigEndian, handle: handle)
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
 Read UTF-16 BigEndian text file, character by character. May throw error.
 This function runs in current thread & non-escaping.

 - Parameters:
   - path: Path to text file.
   - bufferSize: Buffer size (byte) to load data from file. Default 4KB.
   - handle: Closure to handle read character. Return `false` to stop reading (other way: return `true` to continue reading).
 */
public func readUtf16be(path: String, bufferSize: Int = 4096, handle: CharacterReaderHandleType) throws {
    try readUtf16(path: path, bufferSize: bufferSize, isBigEndian: true, handle: handle)
}

/**
 Read UTF-16 LittleEndian text file, character by character. May throw error.
 This function runs in current thread & non-escaping.

 - Parameters:
   - path: Path to text file.
   - bufferSize: Buffer size (byte) to load data from file. Default 4KB.
   - handle: Closure to handle read character. Return `false` to stop reading (other way: return `true` to continue reading).
 */
public func readUtf16le(path: String, bufferSize: Int = 4096, handle: CharacterReaderHandleType) throws {
    try readUtf16(path: path, bufferSize: bufferSize, isBigEndian: false, handle: handle)
}
