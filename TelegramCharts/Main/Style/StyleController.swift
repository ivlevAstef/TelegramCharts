//
//  StyleController.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 20/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class StyleController {
    internal static var currentStyle: Style = Style.dayStyle


    static func recursiveApplyStyle(on view: UIView, style: Style) {
        (view as? Stylizing)?.applyStyle(style)

        for subview in view.subviews {
            recursiveApplyStyle(on: subview, style: style)
        }
    }

}
