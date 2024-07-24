//
//  ViewController.swift
//  SBIG Simba
//
//  Created by Apple on 25/01/24.
//
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {

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
//            webView.isInspectable = true
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
        if let url = URL(string: "https://dipuat.sbigeneral.in/Login/LoginSBI") {
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
   
  
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if #available(iOS 14.5, *) {
            if navigationAction.shouldPerformDownload {
                decisionHandler(.download, preferences)
            } else {
                decisionHandler(.allow, preferences)
            }
        } else {
            // Fallback on earlier versions
            // navigationAction.shouldPerformDownload
        }
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if navigationResponse.canShowMIMEType {
            debugPrint("found")
            decisionHandler(.allow)
        } else {
            let url = navigationResponse.response.url
            var documentUrl: URL?
            if #available(iOS 16.0, *) {
                documentUrl = url?.appending(path: navigationResponse.response.suggestedFilename ?? "LK")
            } else {
                // Fallback on earlier versions
                documentUrl = url?.appendingPathComponent(navigationResponse.response.suggestedFilename!)
            }
            loadAndDisplayDocumentFrom(url: documentUrl!)
            decisionHandler(.cancel)
        }
    }
    
    private func loadAndDisplayDocumentFrom(url downloadUrl : URL) {
        let localFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(downloadUrl.lastPathComponent)
        
        URLSession.shared.dataTask(with: downloadUrl) { data, response, err in
            guard let data = data, err == nil else {
                debugPrint("Error while downloading document from url=\(downloadUrl.absoluteString): \(err.debugDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                debugPrint("Download http status=\(httpResponse.statusCode)")
            }
            
            // write the downloaded data to a temporary folder
            do {
                try data.write(to: localFileURL, options: .atomic)   // atomic option overwrites it if needed
                debugPrint("Stored document from url=\(downloadUrl.absoluteString) in folder=\(localFileURL.absoluteString)")
                
                DispatchQueue.main.async {
                    // localFileURL
                    // here is where your file
                    
                }
            } catch {
                debugPrint(error)
                return
            }
        }.resume()
    }
 

    /*
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if #available(iOS 14.5, *) {
            if navigationAction.shouldPerformDownload {
                decisionHandler(.download, preferences)
            } else {
                decisionHandler(.allow, preferences)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
}

@available(iOS 14.5, *)
extension ViewController: WKDownloadDelegate {
   
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
        let url = // the URL where you want to save the file, optionally appending `suggestedFileName`
           completionHandler(url)
    }
    
    
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self// your `WKDownloadDelegate`
    }
        
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self// your `WKDownloadDelegate`
    }

    */
}


extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}


