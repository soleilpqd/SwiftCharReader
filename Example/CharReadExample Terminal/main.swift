//
//  main.swift
//  CharReadExample
//
//  Created by DươngPQ on 1/10/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation

let path: String

if CommandLine.argc > 1 {
    path = CommandLine.arguments[1]
} else {
    path = ""
    print("Usage: CharReadExample <path to text file>")
    exit(0)
}

do {
    var charCount = 0
    var byteCount = 0
    print("BEGIN Char by char:", path)
    try readUtf8(path: path, handle: { (char, count) -> Bool in
        charCount += 1
        byteCount += count
        print(char, separator: "", terminator: "")
        return true
    })
    print("\n => Chars: \(charCount); Bytes: \(byteCount)")
} catch let err {
    print(err)
}

do {
    var lineCount = 0
    var byteCount = 0
    print("BEGIN Line by line:", path)
    try readUtf8(path: path, delimiter: "\n", handle: { (line, count, index) -> Bool in
        lineCount += 1
        byteCount += count
        print(String(format: "%02d %@", index, line), separator: "", terminator: "")
        return true
    })
    print("\n => Lines: \(lineCount); Bytes: \(byteCount)")
} catch let err {
    print(err)
}
