//
//  ViewController.swift
//  SBIG Simba
//
//  Created by Apple on 25/01/24.
//
//

import UIKit
import WebKit
import LocalAuthentication
		
class ViewController: UIViewController, WKNavigationDelegate ,WKScriptMessageHandler,
                        UNUserNotificationCenterDelegate
{

    var webView: WKWebView!
    var activityIndicator: UIActivityIndicatorView!
    var fileMimeType: String = ""
    let websiteURL="https://dip.sbigeneral.in/Login/loginSBI"//prod
    
   // let websiteURL = "http://13.234.16.249:1027/capture.html"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        let webConfiguration = WKWebViewConfiguration()
        
        webConfiguration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.websiteDataStore = WKWebsiteDataStore.default()
        // Creating WKWebView
        webView = WKWebView(frame: view.bounds,configuration: webConfiguration)
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
        webView.configuration.userContentController.add(self, name: "blobConverterCallback")
        
        // Usage
        
        verifySLLPinning()
        
        checkIfJailBreak()
        
       
        
        
    }
    
    
    private func showNotificationDeniedAlert() {

        let alert = UIAlertController(

            title: "Notifications Disabled",

            message: "Please enable notifications in Settings to receive file download alerts.",

            preferredStyle: .alert

        )

        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in

            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {

                UIApplication.shared.open(settingsURL)

            }

        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel){ _ in
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            }

        })

        present(alert, animated: true)

    }
 

    func loadWebView() {

        if let url = URL(string: websiteURL) {
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
        	
      
        // Hide loading indicator when WebView finishes loading
        
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()

            print("WebView did finish loading")
                        
          
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        print("Notification permission granted")
                    } else {
                        print("Notification permission denied")
                        self.showNotificationDeniedAlert()
                    }
                }
            }

        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView did fail with error: \(error.localizedDescription)")

        // Hide loading indicator on error
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
   

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
	        if let url = navigationAction.request.url {
            if url.absoluteString.starts(with: "blob:") {

                getBase64StringFromBlobUrl(blobUrl: url.absoluteString, mimeType: "application/pdf")
                decisionHandler(.cancel)  // Cancel the navigation
                return
            }
        
        if url.absoluteString.starts(with: "data:") {

                handleBase64Data(url.absoluteString)
            
                decisionHandler(.cancel)  // Cancel the navigation
                return
            }
        }
        decisionHandler(.allow)  // Allow other navigations
    }
    
    func getBase64StringFromBlobUrl(blobUrl: String, mimeType: String) {
        
        let script = """

              javascript:
                  var xhr = new XMLHttpRequest();
                  xhr.open('GET', '" + blobUrl + "', true);
                  xhr.setRequestHeader('Content-type', '" + mimeType + ";charset=UTF-8');
                  xhr.responseType = 'blob';
                  xhr.onload = function(e) {
                      if (this.status == 200) {
                          try {
                              var blobFile = this.response;
                              var reader = new FileReader();
                              reader.readAsDataURL(blobFile);
                              reader.onloadend = function() {
                                  base64data = reader.result;
                                  webkit.messageHandlers.blobConverterCallback.postMessage(base64data);
                              }
                          } catch(readerError) {
                              webkit.messageHandlers.blobConverterCallback.postMessage('error: ' + readerError.toString());
                          }
                      } else {
              webkit.messageHandlers.blobConverterCallback.postMessage('error: HTTP status ' + this.status + ' for URL ' + this.responseURL);
                      }
                  };
                  xhr.onerror = function() {
                      webkit.messageHandlers.blobConverterCallback.postMessage('error: XHR error');
                  };
                  xhr.send();
              """

       
            webView.evaluateJavaScript(script) { (_, error) in
                if let error = error {
                    print("Error evaluating JavaScript: \(error)")
                }
            }
    }
    
    func  verifySLLPinning(){
    
        
        let sessionDelegate = SSLPinningDelegate()
        let session = URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: nil)
         
        // Example of making a network request
        if let url = URL(string:websiteURL) {
            let task = session.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Failed to feth data: \(error)")
//                    DispatchQueue.main.asyncAfter(deadline: .now()) {
//                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
//                    }
                    return
                }
                if let response = response as? HTTPURLResponse {
                    print("Response status code: \(response.statusCode)")
                }
                if let data = data {
                    print("Data received: \(data)")
                }
            }
            task.resume()
        }
         
        
        
        
        
    }
    func checkIfJailBreak() {
    
     DispatchQueue.global(qos: .background).async {
            // Perform jailbreak detection in the background
            let isJailbroken = JailbreakDetection.isDeviceJailbroken()
            // Update UI or perform actions on the main thread
            DispatchQueue.main.async {
                if isJailbroken {
                    print("Device is jailbroken.")
//                    DispatchQueue.main.asyncAfter(deadline: .now()) {
//                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
//                    }
                } else {
                    print("Device is not jailbroken.")
                }
            }
        }
    }

    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
           if message.name == "blobConverterCallback" {
               print("base64 \(message.body)")

               if let base64String = message.body as? String {
                   // Handle the base64 data here
                   handleBase64Data(base64String)
               }
           }
       }
    
    func handleBase64Data(_ base64String: String) {
        
        var newBase64 = base64String.replacingOccurrences(of: "\n", with: "")
        var fileExtension: String = "pdf"
        if let ext = getFileExtension(fromBase64String: newBase64) {
            print("The file extension is: \(ext)")
            fileExtension = ext
            newBase64 = newBase64.replacingOccurrences(of: "data:application/\(ext);base64,", with: "")
        } else {
            print("Could not determine the file extension.")
        }
        
        if let data = Data(base64Encoded: newBase64) {
            // Create a temporary file for the user to save
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = formatter.string(from: now)
            let fileName = "\(timestamp)_.\(fileExtension)"
            let tempFilePath = temporaryDirectory.appendingPathComponent(fileName)
            do {
                try data.write(to: tempFilePath)
                print("File temporarily saved to: \(tempFilePath)")
                // Present UIDocumentPickerViewController to allow the user to save the file
                if #available(iOS 14.0, *) {
                    // Present UIDocumentPickerViewController for iOS 14.0 and above
                    let documentPicker = UIDocumentPickerViewController(forExporting: [tempFilePath], asCopy: true)
                    documentPicker.delegate = self
                    documentPicker.modalPresentationStyle = .formSheet
                    DispatchQueue.main.async {
                        self.present(documentPicker, animated: true, completion: nil)
                    }
                } else {
                    // Fallback for iOS versions below 14.0
                    let documentPicker = UIDocumentPickerViewController(url: tempFilePath, in: .exportToService)
                    documentPicker.delegate = self
                    documentPicker.modalPresentationStyle = .formSheet
                    DispatchQueue.main.async {
                        self.present(documentPicker, animated: true, completion: nil)
                    }
                }
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }
    
    
       
//       func handleBase64Data(_ base64String: String) {
//           
//
//           var newBase64=base64String.replacingOccurrences(of: "\n", with:"")
//           var fileExtension: String="pdf"
//           
//           if let ext = getFileExtension(fromBase64String: newBase64) {
//               print("The file extension is: \(ext)")
//               fileExtension = ext
//               newBase64 = newBase64.replacingOccurrences(of: "data:application/\(ext);base64,", with: "")
//           } else {
//               print("Could not determine the file extension.")
//           }
//
//               
//           if let data = Data(base64Encoded: newBase64) {
//                   // Save the data to a file
//                   let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//               
//               let now = Date()
//
//               let formatter = DateFormatter()
//               formatter.dateFormat = "yyyyMMdd_HHmmss"
//               let timestamp = formatter.string(from: now)
//               
//                   let filePath = documentsPath.appendingPathComponent("\(timestamp)_.\(fileExtension)")
//                   
//                   do {
//                       try data.write(to: filePath)
//                       print("File saved to: \(filePath)")
//                       
//                       DispatchQueue.main.async {
//                           self.showNotification(filePath: filePath)
//                       }
//
//                   } catch {
//                       print("Error saving file: \(error)")
//                   }
//               }
//       }
//        
    
   
    func showNotification(filePath: URL) {
        let content = UNMutableNotificationContent()
          content.title = "File downloaded"
          content.body = "Tap to open PDF"
        
          content.sound = UNNotificationSound.default
          content.userInfo = ["filePath": filePath.path]
          
          // Set categoryIdentifier for the notification
          content.categoryIdentifier = "persistentNotification"
        let openAction = UNNotificationAction(
                    identifier: "openFile",
                    title: "Open",
                    options: .foreground
                )
                // Create the category with the open action
                let category = UNNotificationCategory(
                    identifier: "persistentNotification",
                    actions: [openAction],
                    intentIdentifiers: [],
                    options: .customDismissAction
                )
          

        // Register the category
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.setNotificationCategories([category])
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )
                notificationCenter.add(request) { error in
                    if let error = error {
                        print("Error showing notification: \(error)")
                    }
                }
    }
    
    // Handle notification when app is in foreground
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .sound])
            } else {         // For iOS 13 and earlier
                completionHandler([.alert, .sound])
            }
             
        }
        // Handle notification response
    
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            // Get the file path from userInfo
            if let filePath = response.notification.request.content.userInfo["filePath"] as? String {
                let fileURL = URL(fileURLWithPath: filePath)
                // Open the file
                openFile(at: fileURL)
            }
            completionHandler()
        }
    
        func openFile(at fileURL: URL) {
            // Check if the file exists
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("File doesn't exist at path: \(fileURL.path)")
                return
            }
            // Create and present document interaction controller
            let documentInteractionController = UIDocumentInteractionController(url: fileURL)
            documentInteractionController.delegate = self
            documentInteractionController.presentPreview(animated: true)
        }

    func getFileExtension(fromBase64String base64String: String) -> String? {
        // Check if the Base64 string contains a data URL prefix
        if let dataPrefixRange = base64String.range(of: "data:") {
            // Extract the MIME type
            let prefix = base64String[..<dataPrefixRange.upperBound]
            if let semicolonRange = base64String.range(of: ";", range: dataPrefixRange.upperBound..<base64String.endIndex) {
                let mimeType = base64String[dataPrefixRange.upperBound..<semicolonRange.lowerBound]
                
                // Map MIME type to file extension
                switch mimeType {
                case "image/jpeg": return "jpg"
                case "image/png": return "png"
                case "image/gif": return "gif"
                case "image/tiff": return "tiff"
                case "image/webp": return "webp"
                case "application/pdf": return "pdf"
                case "text/plain": return "txt"
                case "text/html": return "html"
                case "application/json": return "json"
                default: return "pdf"
                }
            }
        }
        return nil
    }

    
}


extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}


// Implement the UIDocumentPickerDelegate to handle success and errors

extension ViewController: UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [	URL]) {
        if let savedFileURL = urls.first {
            print("File successfully saved at: \(savedFileURL)")
            showNotification(filePath: savedFileURL)
            // Assuming showNotification will later call a method to preview the document
        }
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled.")
    }
 
    // Required delegate method for UIDocumentInteractionControllerDelegate
    func documentInteractionControllerViewControllerForPreview(
            _ controller: UIDocumentInteractionController
        ) -> UIViewController {
            return self
        }
    // Method to preview the document
    func previewDocument(at url: URL) {
        let documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController.delegate = self  // Set the delegate
        documentInteractionController.presentPreview(animated: true)
    }
}
