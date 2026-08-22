//
//  TutorialStep.swift
//  TravelDate
//
//  Created by Dev CodingZone on 20/08/26.
//

import UIKit

struct TutorialStep {

    let title: String
    let message: String

    /// The view that should be highlighted.
    weak var targetView: UIView?

    /// Optional custom frame if you don't want to highlight a view.
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
