//
//  ViewController.swift
//  SwiftCharReader
//
//  Created by soleilpqd@gmail.com on 01/09/2020.
//  Copyright (c) 2020 soleilpqd@gmail.com. All rights reserved.
//

import UIKit
import SwiftCharReader

class ViewController: UIViewController {

    override func viewDidLoad(){
        super.viewDidLoad()
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

}

