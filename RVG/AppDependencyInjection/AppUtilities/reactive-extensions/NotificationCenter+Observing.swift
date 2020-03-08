import RxSwift

public extension NotificationCenter {
    var appForegroundStream: Observable<Void> {
        return rx.notification(UIApplication.willEnterForegroundNotification).map { _ in () }
    }
    
    var keyboardEvents: Observable<(isHiding: Bool, frame: CGRect)> {
        return Observable.merge(rx.notification(UIResponder.keyboardWillHideNotification),
                                rx.notification(UIResponder.keyboardWillChangeFrameNotification))
            .map { notification in
                let isHiding = notification.name == UIResponder.keyboardWillHideNotification
                // swiftlint:disable:next force_cast
                let frame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
                // userInfo will always be there with UIKeyboardFrameEndUserInfoKey
                return (isHiding, frame)
        }
    }
}
