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
