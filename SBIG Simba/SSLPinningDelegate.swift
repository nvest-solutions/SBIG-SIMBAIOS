//
//  File.swift
//  SBIG Simba
//
//  Created by abhilash on 24/10/24.
//

import Foundation
import CryptoKit


class SSLPinningDelegate: NSObject, URLSessionDelegate {
    
    private func loadCertificate() -> SecCertificate? {
            guard let certPath = Bundle.main.path(forResource: "sbigeneral", ofType: "cer"),
                  let certData = NSData(contentsOfFile: certPath) else {
                print("Certificate not found in app bundle.")
                return nil
            }
     
            // Create a certificate from the data
            guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
                print("Failed to create certificate from data.")
                return nil
            }
     
            return certificate
        }
        // URLSession delegate method to handle server trust challenge
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
                  let serverTrust = challenge.protectionSpace.serverTrust else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
     
            // Load the local certificate
            guard let localCertificate = loadCertificate() else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            // Set policies for evaluation
            let policies = [SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)]
            SecTrustSetPolicies(serverTrust, policies as CFTypeRef)
     
            // Compare server's certificate with the pinned certificate
            let serverCertificateCount = SecTrustGetCertificateCount(serverTrust)
            for index in 0..<serverCertificateCount {
                if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, index) {
                    // Compare the server certificate with the local certificate
                    if localCertificate == serverCertificate {
                        let credential = URLCredential(trust: serverTrust)
                        completionHandler(.useCredential, credential)
                        return
                    }
                }
            }
     
            // If no match is found, cancel the connection
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    
}

