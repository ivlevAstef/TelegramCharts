//
//  StyleController.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 20/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal class StyleController {
    internal private(set) static var currentStyle: Style = Style.dayStyle

    internal static func next() {
        currentStyle = nextStyle
    }
    
    internal static var nextStyle: Style {
        switch currentStyle.name {
        case "Day":
            return Style.darkStyle
        case "Night":
            return Style.dayStyle
        default:
            assertionFailure("Incorrect style name. Check code")
            return Style.dayStyle
        }
    }

    static func recursiveApplyStyle(on view: UIView, style: Style) {
        (view as? Stylizing)?.applyStyle(style)

        for subview in view.subviews {
            recursiveApplyStyle(on: subview, style: style)
        }
    }

}
