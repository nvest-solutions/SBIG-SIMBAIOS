//
//  File.swift
//  SBIG Simba
//
//  Created by abhilash on 24/10/24.
//

import Foundation
import CryptoKit


class SSLPinningDelegate: NSObject, URLSessionDelegate {

//    func sha256(data: Data) -> String {
//        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
//        data.withUnsafeBytes {
//            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
//
//        }
//        return hash.map { String(format: "%02x", $0) }.joined()
//    }
    
    func sha256(data: Data) -> String {
        let hashedData = SHA256.hash(data: data)
        let hashedString = hashedData.map { String(format: "%02hhx", $0) }.joined()
        return hashedString
    }
    
    
    
//    func sha256(data : Data) -> String {
//        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
//        data.withUnsafeBytes {
//            _ = CC_SHA256($0, CC_LONG(data.count), &hash)
//        }
//        return hash.map { String(format: "%02x", $0) }.joined()
//    }

    func publicKeyFromCertificate(certFileName: String) -> SecKey? {
        guard let certPath = Bundle.main.path(forResource: certFileName, ofType: "cer"),
              let certData = NSData(contentsOfFile: certPath) else {
            return nil
        }
        let options: [String: Any] = [kSecImportExportPassphrase as String: ""]
        var items: CFArray?
     
        let status = SecPKCS12Import(certData, options as CFDictionary, &items)
        guard status == errSecSuccess, let array = items as? [[String: Any]], let firstItem = array.first else {
            return nil
        }
        // Use forced cast
        let cert = firstItem[kSecImportItemCertChain as String] as! [SecCertificate]
        let publicKey = SecCertificateCopyKey(cert.first!)
        return publicKey
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
          if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
              if let serverTrust = challenge.protectionSpace.serverTrust,
                 let cert = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                  let remoteCertificateData = SecCertificateCopyData(cert) as Data
                  // Print SHA-256 of the remote certificate
                  let remoteHash = sha256(data: remoteCertificateData)
                  print("Remote Certificate SHA-256: \(remoteHash)")
                  // Load the pinned certificate
                  if let localCertificate = Bundle.main.path(forResource: "sbi_general", ofType: "crt"),
                     let localCertificateData = try? Data(contentsOf: URL(fileURLWithPath: localCertificate)) {
                      // Print SHA-256 of the local (pinned) certificate
                      let localHash = sha256(data: localCertificateData)
                      print("Local Certificate SHA-256: \(localHash)")
                      // Compare the hashes
                      if remoteCertificateData == localCertificateData {
                          // Certificates match, use credential
                          let credential = URLCredential(trust: serverTrust)
                          completionHandler(.useCredential, credential)
                          return
                      }
                      else {
                          
                          print("Server certificate hash mismatch!")
                      }
                  }
              }
          }
          completionHandler(.performDefaultHandling, nil)
      }
 
}

