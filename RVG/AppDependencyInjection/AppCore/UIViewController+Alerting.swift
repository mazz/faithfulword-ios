import UIKit

public extension UIViewController {
    
    /// Shows a native alert letting user know that feature not available.
    ///
    /// - Parameter reason: specific reason to show user.
    public func showUnimplementedFeaturePrompt(with reason: String? = nil) {
        var message = "This feature is not ready yet, check back soon!"
        if let reason = reason {
            message.append("\n\(reason)")
        }
        let alert = UIAlertController(title: "⚠️ Oops",
                                      message: message,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok",
                                     style: .default)
        alert.addAction(okAction)
        present(alert,
                animated: true,
                completion: nil)
    }
    
    /// Shows an alert based on error.
    /// Uses "⚠️ Oops" as title, and `error.localizedDescription` as message.
    ///
    /// - Parameter error: The error to show the alert for.
    public func showAlert(for error: Error) {
        let alert = UIAlertController(title: "Oops",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok",
                                     style: .default)
        alert.addAction(okAction)
        self.present(alert,
                     animated: true,
                     completion: nil)
    }
    
    /// Shows an info prompt.
    ///
    /// - Parameter title: The alert title to show in the alert view.
    /// - Parameter message: The alert message to show in the alert view.
    public func showInfo(title: String, message: String? = nil, completion: (() -> Swift.Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok",
                                     style: .default)
        alert.addAction(okAction)
        self.present(alert,
                     animated: true,
                     completion: completion)
    }
    
}
