//
//  WebViewController.swift
//  SwiftCharReader_Example
//
//  Created by DươngPQ on 1/16/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {

    @IBOutlet private weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let documentPathUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let targetUrl = documentPathUrl.appendingPathComponent("sample.html")
            if FileManager.default.fileExists(atPath: targetUrl.path) {
                webView.loadRequest(URLRequest(url: targetUrl))
            }
        }
    }

    @IBAction private func closeButtonOnTap(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
