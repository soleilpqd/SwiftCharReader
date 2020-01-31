//
//  ViewController.swift
//  CharReadMac
//
//  Created by DươngPQ on 1/10/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Cocoa
//import SwiftCharReader
import SwiftCSVParser

final class ViewController: NSViewController {

    @IBAction private func charByCharButtonOnTap(_ sender: NSButton) {
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

    @IBAction private func lineByLineButtonOnTap(_ sender: NSButton) {
        if let path = Bundle.main.path(forResource: "sample", ofType: "txt") {
            print("BEGIN:", path)
            var lineCount = 0
            var byteCount = 0
            do {
                try readSegments(path: path, delimiter: "\n", handle: { (line, count, index) -> Bool in
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

    @IBAction private func parseCSVButtonOnTap(_ sender: NSButton) {
        let sourceData = getOpeningPath(allowedFileTypes: ["csv"])
        guard let source = sourceData.0, let newlineType = sourceData.1 else {
            return
        }
        guard var target = getSavingPath(allowedFileTypes: ["html", "htm"]) else {
            return
        }
        if target.pathExtension.count == 0 {
            target.appendPathExtension("html")
        }
        do {
            try csvToHtml(source: source, sourceType: newlineType, target: target)
            NSWorkspace.shared.open(target)
        } catch let err {
            let alert = NSAlert(error: err)
            alert.runModal()
        }
    }

    private func getOpeningPath(allowedFileTypes: [String]) -> (URL?, String?) {
        let panel = NSOpenPanel()
        panel.title = "Open"
        panel.allowedFileTypes = allowedFileTypes
        panel.allowsOtherFileTypes = false
        panel.canCreateDirectories = true
        panel.canChooseFiles = true
        panel.isAccessoryViewDisclosed = false
        let dropButton = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 100, height: 32))
        dropButton.addItems(withTitles: ["CRLF", "LF"])
        dropButton.selectItem(at: 0)
        panel.accessoryView = dropButton
        panel.canChooseDirectories = true
        if panel.runModal() == NSApplication.ModalResponse.OK {
            return (panel.url, dropButton.selectedItem?.title)
        }
        return (nil, nil)
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

    private func getSavingPath(allowedFileTypes: [String]) -> URL? {
        let panel = NSSavePanel()
        panel.title = "Save to ..."
        panel.allowsOtherFileTypes = false
        panel.allowedFileTypes = allowedFileTypes
        panel.canCreateDirectories = true
        if panel.runModal() == NSApplication.ModalResponse.OK {
            return panel.url
        }
        return nil
    }

    private func csvToHtml(source: URL, sourceType: String, target: URL) throws {
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

""".write(to: target, atomically: true, encoding: .utf8)
        let writter = try FileHandle(forUpdating: target)
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
        if let data = """
                    <tr>

                """.data(using: .utf8) {
            writter.write(data)
        }
        try readCSV(path: source.path, lineDelimiter: sourceType == "LF" ? kLF : kCRLF, fieldHandle: { (field, row, column) -> Bool in
            Swift.print("\(row):\(column); ", separator: "", terminator: "")
            let content = formatHTML(field)
            let tag = row == 0 ? "th" : "td"
            if let data = """
                <\(tag)>\(content)</\(tag)>

                """.data(using: .utf8) {
                writter.write(data)
            }
            return true
        }, lineHandle: { (row) -> Bool in
            Swift.print(" End of row \(row)")
            if let data = """
                            </tr>

                        """.data(using: .utf8) {
                writter.write(data)
            }
            return true
        })
    }

    @IBAction private func utf16beCharByCharButtonOnTap(_ sender: NSButton) {
        let operationQueue = OperationQueue()
        if let path = Bundle.main.path(forResource: "sample-utf16be", ofType: "txt") {
            print("BEGIN:", path)
            operationQueue.addOperation {
                var charCount = 0
                var byteCount = 0
                do {
                    try readUtf16be(path: path) { (char, charLen) -> Bool in
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

    @IBAction private func utf16beLineByLineButtonOnTap(_ sender: NSButton) {
        if let path = Bundle.main.path(forResource: "sample-utf16be", ofType: "txt") {
            print("BEGIN:", path)
            var lineCount = 0
            var byteCount = 0
            do {
                try readSegments(path: path, delimiter: "\n", encoding: .utf16be, handle: { (line, count, index) -> Bool in
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

    @IBAction private func utf16leCharByCharButtonOnTap(_ sender: NSButton) {
        let operationQueue = OperationQueue()
        if let path = Bundle.main.path(forResource: "sample-utf16le", ofType: "txt") {
            print("BEGIN:", path)
            operationQueue.addOperation {
                var charCount = 0
                var byteCount = 0
                do {
                    try readUtf16le(path: path) { (char, charLen) -> Bool in
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

    @IBAction private func utf16leLineByLineButtonOnTap(_ sender: NSButton) {
        if let path = Bundle.main.path(forResource: "sample-utf16le", ofType: "txt") {
            print("BEGIN:", path)
            var lineCount = 0
            var byteCount = 0
            do {
                try readSegments(path: path, delimiter: "\n", encoding: .utf16le, handle: { (line, count, index) -> Bool in
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

}
