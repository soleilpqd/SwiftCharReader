//
//  ViewController.swift
//  SwiftCharReader
//
//  Created by soleilpqd@gmail.com on 01/09/2020.
//  Copyright (c) 2020 soleilpqd@gmail.com. All rights reserved.
//

import UIKit
import SwiftCharReader

final class ViewController: UIViewController {

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

}

