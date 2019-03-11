//
//  StyleProvider.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

extension Style
{
    internal static let dayStyle: Style = Style(
        name: "Day",
        backgroundColor: UIColor(r: 239, g: 239, b: 244),
        mainColor: UIColor(r: 254, g: 254, b: 254),
        indicatorColor: .gray,
        titleColor: .black,
        subTitleColor: UIColor(r: 109, g: 109, b: 114),
        textColor: .black,
        secondaryTextColor: UIColor(r: 152, g: 158, b: 164),
        activeElementColor: UIColor(r: 34, g: 126, b: 229),
        separatorColor: UIColor(r: 200, g: 199, b: 204),
        selectedColor: UIColor(r: 0, g: 0, b: 0, alpha: 0.15)
    )

    internal static let darkStyle: Style = Style(
        name: "Night",
        backgroundColor: UIColor(r: 24, g: 34, b: 45),
        mainColor: UIColor(r: 33, g: 47, b: 63),
        indicatorColor: .white,
        titleColor: .white,
        subTitleColor: UIColor(r: 93, g: 109, b: 126),
        textColor: .white,
        secondaryTextColor: UIColor(r: 93, g: 109, b: 126),
        activeElementColor: UIColor(r: 41, g: 145, b: 255),
        separatorColor: UIColor(r: 18, g: 26, b: 36),
        selectedColor: UIColor(r: 255, g: 255, b: 255, alpha: 0.15)
    )

    internal func next() -> Style {
        switch self.name {
        case "Day":
            return Style.darkStyle
        case "Night":
            return Style.dayStyle
        default:
            assertionFailure("Incorrect style name. Check code")
            return Style.dayStyle
        }
    }
}
