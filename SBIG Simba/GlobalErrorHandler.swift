
import UIKit
 
class GlobalErrorHandler {
    static let shared = GlobalErrorHandler()
    private init() {}
 
    private static weak var instance: GlobalErrorHandler?
 
    func setup() {
        GlobalErrorHandler.instance = self
 
        // Exception handler
        let exceptionHandler: @convention(c) (NSException) -> Void = { exception in
            GlobalErrorHandler.handleException(exception: exception)
        }
        NSSetUncaughtExceptionHandler(exceptionHandler)
 
        // Signal handler
        let signalHandler: @convention(c) (Int32) -> Void = { signal in
            GlobalErrorHandler.handleSignal(signal: signal)
        }
 
        signal(SIGABRT, signalHandler)
        signal(SIGILL, signalHandler)
        signal(SIGSEGV, signalHandler)
        signal(SIGFPE, signalHandler)
        signal(SIGBUS, signalHandler)
        signal(SIGPIPE, signalHandler)
    }
 
    private static func handleException(exception: NSException) {
        let message = """
            ❌ App Error
            Name: \(exception.name)
            Reason: \(exception.reason ?? "Unknown")
            Stack Trace: \(exception.callStackSymbols.joined(separator: "\n"))
            """
        GlobalErrorHandler.instance?.showErrorDialog(message: message)
    }
 
    private static func handleSignal(signal: Int32) {
        let message = """
            ❌ Fatal Error
            Signal: \(signal)
            """
        GlobalErrorHandler.instance?.showErrorDialog(message: message)
    }
 
    private func showErrorDialog(message: String) {
        DispatchQueue.main.async {
            // Get the top most presented view controller
            if let topController = self.getTopPresentedViewController() {
                let alertController = UIAlertController(
                    title: "Unexpected Error",
                    message: message,
                    preferredStyle: .alert
                )
 
                alertController.addAction(UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { _ in
                        exit(0)
                    }
                ))
 
                // Present the alert with animation disabled for reliability
                topController.present(alertController, animated: false)
            } else {
                print("❌ Could not find top view controller to present error dialog.")
            }
        }
    }
 
    private func getTopPresentedViewController() -> UIViewController? {
        // Get the key window's root view controller
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        var topController = keyWindow?.rootViewController
 
        // Traverse the view controller hierarchy to find the topmost presented view controller
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
 
        return topController
    }
}
 
// MARK: - AppDelegate Extension
extension AppDelegate {
    func setupGlobalErrorHandling() {
        GlobalErrorHandler.shared.setup()
    }
}
