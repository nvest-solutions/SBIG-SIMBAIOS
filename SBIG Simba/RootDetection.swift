import Foundation
import UIKit
 
class JailbreakDetection {
    // Suspicious system and app paths to check
    private static var suspiciousAppandSystemPaths: [String] {
        return [
            "/usr/sbin/frida-server",
            "/etc/apt/sources.list.d/electra.list",
            "/etc/apt/sources.list.d/sileo.sources",
            "/.bootstrapped_electra",
            "/usr/lib/libjailbreak.dylib",
            "/jb/lzma",
            "/.cydia_no_stash",
            "/.installed_unc0ver",
            "/jb/offsets.plist",
            "/usr/share/jailbreak/injectme.plist",
            "/etc/apt/undecimus/undecimus.list",
            "/var/lib/dpkg/info/mobilesubstrate.md5sums",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/jb/jailbreakd.plist",
            "/jb/amfid_payload.dylib",
            "/jb/libjailbreak.dylib",
            "/usr/libexec/cydia/firmware.sh",
            "/var/lib/cydia",
            "/etc/apt",
            "/private/var/lib/apt",
            "/private/var/Users/",
            "/var/log/apt",
            "/Applications/Cydia.app",
            "/private/var/stash",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/cache/apt/",
            "/private/var/log/syslog",
            "/private/var/tmp/cydia.log",
            "/Applications/Icy.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/blackra1n.app",
            "/Applications/SBSettings.app",
            "/Applications/FakeCarrier.app",
            "/Applications/WinterBoard.app",
            "/Applications/IntelliScreen.app",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/CydiaSubstrate.dylib",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist"
        ]
    }
    // Main method to check if the device is jailbroken
    static func isDeviceJailbroken() -> Bool {
        // Check for suspicious paths
        for path in suspiciousAppandSystemPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("Jailbreak file found at path: \(path)")
                return true
            }
        }
 
        // Combine all detection checks
        return canWriteToRestrictedDirectory() ||
               canOpenCydiaURL() ||
               isParentProcessIDOne() ||
               checkDYLD() ||
               isFridaRunning()
    }
 
    // Method to check write access in restricted directories
    private static func canWriteToRestrictedDirectory() -> Bool {
        let pathToFileInRestrictedDirectory = "/private/jailbreak_test.txt"
        do {
            try "This is a test.".write(toFile: pathToFileInRestrictedDirectory, atomically: true, encoding: .utf8)
            // If writing succeeds, try to delete the file
            try FileManager.default.removeItem(atPath: pathToFileInRestrictedDirectory)
            return true // File write/delete succeeded in a restricted directory
        } catch {
            return false // File write/delete failed as expected
        }
    }
 
    // Method to check if the app can open the Cydia URL scheme
    private static func canOpenCydiaURL() -> Bool {
        if let url = URL(string: "cydia://package/com.example.package"), UIApplication.shared.canOpenURL(url) {
            return true
        }
        return false
    }
 
    // Method to check if the parent process ID is 1
    private static func isParentProcessIDOne() -> Bool {
        return getppid() == 1
    }
 
    // Method to check for suspicious DYLD libraries
    private static func checkDYLD() -> Bool {
        let suspiciousLibraries = [
            "FridaGadget",
            "frida",
            "cynject",
            "libcycript"
        ]
        for libraryIndex in 0..<_dyld_image_count() {
            guard let loadedLibrary = String(validatingUTF8: _dyld_get_image_name(libraryIndex)) else { continue }
            for suspiciousLibrary in suspiciousLibraries {
                if loadedLibrary.lowercased().contains(suspiciousLibrary.lowercased()) {
                    return true
                }
            }
        }
        return false
    }
 
    // Method to check if Frida is running
    private static func isFridaRunning() -> Bool {
        func swapBytesIfNeeded(port: in_port_t) -> in_port_t {
            let littleEndian = Int(OSHostByteOrder()) == OSLittleEndian
            return littleEndian ? _OSSwapInt16(port) : port
        }
 
        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_addr.s_addr = inet_addr("127.0.0.1")
        serverAddress.sin_port = swapBytesIfNeeded(port: in_port_t(27042))
        let sock = socket(AF_INET, SOCK_STREAM, 0)
 
        let result = withUnsafePointer(to: &serverAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.stride))
            }
        }
        close(sock) // Close the socket
        return result != -1
    }
}
