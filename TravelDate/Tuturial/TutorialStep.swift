import UIKit

struct TutorialStep {

    let title: String
    let message: String

    weak var targetView: UIView?

    let customFrame: CGRect?

    init(
        title: String,
        message: String,
        targetView: UIView? = nil,
        customFrame: CGRect? = nil
    ) {
        self.title = title
        self.message = message
        self.targetView = targetView
        self.customFrame = customFrame
    }
}
