//
//  ViewController.swift
//  SwiftCharReader
//
//  Created by soleilpqd@gmail.com on 01/09/2020.
//  Copyright (c) 2020 soleilpqd@gmail.com. All rights reserved.
//

import UIKit
//import SwiftCharReader
import SwiftCSVParser

final class ViewController: UIViewController {

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

    @IBAction private func charByCharButtonOnTap(_ sender: UIButton) {
        // `readUt8` runs in current thread & non-escaping.
        // This demo executes `readUt8` in a separated thread (using operation queue), print read character on main thread.
        let operationQueue = OperationQueue()
        if let path = Bundle.main.path(forResource: "sample", ofType: "txt") {
            print("BEGIN:", path)
            operationQueue.addOperation {
                var charCount = 0
                var byteCount = 0
                do {
                    try readUtf8(path: path) { (char, charLen) -> Bool in
                        charCount += 1
                        byteCount += charLen
                        DispatchQueue.main.async {
                            print(char, separator: "", terminator: "")
                        }
                        return true
                    }
                } catch let err {
                    DispatchQueue.main.async {
                        print(err)
                    }
                }
                DispatchQueue.main.async {
                    print("\n => Chars: \(charCount); Bytes: \(byteCount)")
                }
            }
        }
    }

    @IBAction private func lineByLineButtonOnTap(_ sender: UIButton) {
        if let path = Bundle.main.path(forResource: "sample", ofType: "txt") {
            print("BEGIN:", path)
            var lineCount = 0
            var byteCount = 0
            do {
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
        }
    }

    @IBAction private func csvButtonOnTap(_ sender: UIButton) {
        if let path = Bundle.main.path(forResource: "sample", ofType: "csv"),
            let documentPathUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let targetUrl = documentPathUrl.appendingPathComponent("sample.html")
            print("WRITE TO:", targetUrl)
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

""".write(to: targetUrl, atomically: true, encoding: .utf8)
                let writter = try FileHandle(forUpdating: targetUrl)
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
                try readCSVUtf8(path: path, lineDelimiter: kLF, fieldHandle: { (field, row, column) -> Bool in
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
                print("\n", err)
                return
            }
        }
        print("DONE")
        performSegue(withIdentifier: "WebSegue", sender: nil)
    }

}

