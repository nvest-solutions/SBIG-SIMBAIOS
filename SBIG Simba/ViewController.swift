//
//  ViewController.swift
//  SBIG Simba
//
//  Created by Apple on 25/01/24.
//
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate{

    var webView: WKWebView!
    var activityIndicator: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Creating WKWebView
        webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.configuration.preferences.javaScriptEnabled = true
        view.addSubview(webView)
 
        if #available(macOS 13.3, iOS 16.4, tvOS 16.4, *) {
            webView.isInspectable = true
        }
        // Creating and configure loading indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = UIColor.blue
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        // Load WebView content
        loadWebView()
        
        // Set scroll view delegate
        webView.scrollView.delegate = self
        
    }

    func loadWebView() {
        if let url = URL(string: "https://dipuat.sbigen.in/Login/LoginSBI") {
            let request = URLRequest(url: url)

                // Load WebView content on the main thread
            DispatchQueue.main.async {
                    // Show loading indicator on the main thread
                   self.activityIndicator.startAnimating()

                    // Load WebView content
                    self.webView.load(request)
                }
            
            }
        }


    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("WebView did start loading")
    }


    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView did finish loading")

        // Hide loading indicator when WebView finishes loading
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView did fail with error: \(error.localizedDescription)")

        // Hide loading indicator on error
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
}
extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}
