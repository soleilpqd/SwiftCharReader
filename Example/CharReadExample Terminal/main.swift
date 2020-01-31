//
//  main.swift
//  CharReadExample
//
//  Created by DươngPQ on 1/10/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation

private func printError(_ error: Error) {
    let printer = FileHandle.standardError
    if let data = "ERROR: \(error)".data(using: .utf8) {
        printer.write(data)
    }
}

if CommandLine.argc <= 1 {
    print("Usage: CharReadExample <path to text file/csv file>")
    exit(0)
}

private func demoReadUtf8(_ path: String) {
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
        printError(err)
    }

    do {
        var lineCount = 0
        var byteCount = 0
        print("BEGIN Line by line:", path)
        try readSegments(path: path, delimiter: "\n", handle: { (line, count, index) -> Bool in
            lineCount += 1
            byteCount += count
            print(String(format: "%02d %@", index, line), separator: "", terminator: "")
            return true
        })
        print("\n => Lines: \(lineCount); Bytes: \(byteCount)")
    } catch let err {
        printError(err)
    }
}

private func formatHTML(_ str: String?) -> String {
    if let s = str {
        var result = ""
        let escapes: [Character: String] = ["\n": "<br/>", "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;"]
        for char in s {
            if let target = escapes[char] {
                result += target
            } else {
                result.append(char)
            }
        }
        return result
    }
    return ""
}

private func demoParseCSV(_ path: String) {
    if let targetPath = ((path as NSString).deletingPathExtension as NSString).appendingPathExtension("html") {
        print("WRITE TO:", targetPath)
        do {
            try """
<html>
<head>
    <meta charset="UTF-8"/>
    <style>
    table, th, td {
        border: 1px solid black;
        border-collapse: collapse;
    }
    body {
        font-family: sans-serif;
    }
    </style>
</head>
<body>
    <table style="width:100%">

""".write(toFile: targetPath, atomically: true, encoding: .utf8)
            guard let writter = FileHandle(forUpdatingAtPath: targetPath) else { return }
            defer {
                if let data = """
                        </table>
                    </body>
                    </html>

                    """.data(using: .utf8) {
                    writter.write(data)
                }
                writter.closeFile()
            }
            writter.seekToEndOfFile()
            print("BEGIN:", path)
            if let data = """
                    <tr>

                """.data(using: .utf8) {
                writter.write(data)
            }
            // sample.csv edited by XCode so new line is LF (not CRLF as standard)
            try readCSV(path: path, lineDelimiter: kLF, fieldHandle: { (field, row, column) -> Bool in
                print("\(row):\(column); ", separator: "", terminator: "")
                let content = formatHTML(field)
                let tag = row == 0 ? "th" : "td"
                if let data = """
                    <\(tag)>\(content)</\(tag)>

                    """.data(using: .utf8) {
                    writter.write(data)
                }
                return true
            }, lineHandle: { (row) -> Bool in
                print(" End of row \(row)")
                if let data = """
                            </tr>

                        """.data(using: .utf8) {
                    writter.write(data)
                }
                return true
            })
        } catch let err {
            printError(err)
            return
        }
    }
    print("DONE")
}

for (index, arg) in CommandLine.arguments.enumerated() where index > 0 {
    switch (arg as NSString).pathExtension.lowercased() {
    case "txt":
        demoReadUtf8(arg)
    case "csv":
        demoParseCSV(arg)
    default:
        break
    }
}
