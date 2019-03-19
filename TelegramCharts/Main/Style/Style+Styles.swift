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
        selectedColor: UIColor(r: 0, g: 0, b: 0, alpha: 0.15),
        chartsStyle: ChartStyle(accentTextColor: UIColor(r: 109, g: 109, b: 114),
                                textColor: UIColor(r: 109, g: 109, b: 114),
                                backgroundColor: UIColor(r: 239, g: 239, b: 244),
                                popupBackgroundColor: UIColor(r: 239, g: 239, b: 244),
                                linesColor: UIColor(r: 142, g: 142, b: 147).withAlphaComponent(0.5),
                                focusLineColor: UIColor(r: 203, g: 206, b: 207),
                                intervalUnvisibleColor: UIColor(r: 216, g: 228, b: 229).withAlphaComponent(0.5),
                                intervalBorderColor: UIColor(r: 182, g: 192, b: 202).withAlphaComponent(0.8))
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
        selectedColor: UIColor(r: 255, g: 255, b: 255, alpha: 0.15),
        chartsStyle: ChartStyle(accentTextColor: UIColor(r: 93, g: 109, b: 126),
                                textColor: UIColor(r: 93, g: 109, b: 126),
                                backgroundColor: UIColor(r: 24, g: 34, b: 45),
                                popupBackgroundColor: UIColor(r: 24, g: 34, b: 45),
                                linesColor: UIColor(r: 5, g: 16, b: 42).withAlphaComponent(0.5),
                                focusLineColor: UIColor(r: 19, g: 27, b: 36),
                                intervalUnvisibleColor: UIColor(r: 51, g: 62, b: 78).withAlphaComponent(0.5),
                                intervalBorderColor: UIColor(r: 73, g: 90, b: 109).withAlphaComponent(0.8))
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

// темная тема:
// internal static let darkStyle: Style = Style(
//     name: "Night",
//     backgroundColor: UIColor(r: 24, g: 34, b: 45),
//     mainColor: UIColor(r: 33, g: 47, b: 63),
//     indicatorColor: .white, // что это?
//     titleColor: .white,
//     subTitleColor: UIColor(r: 91, g: 107, b: 127),
//     textColor: .white,
//     secondaryTextColor: UIColor(r: 93, g: 109, b: 126), // а нужен ли?
//     activeElementColor: UIColor(r: 24, g: 145, b: 255),
//     separatorColor: UIColor(r: 18, g: 26, b: 36),
//     selectedColor: UIColor(r: 255, g: 255, b: 255, alpha: 0.15),
//     chartsStyle: ChartStyle(hintTextColor: .white,
//     						hintBackgroundColor: UIColor(r: 26, g: 40, b: 55),
//                             textColor: UIColor(r: 93, g: 109, b: 126),
//                             dotColor: UIColor(r: 33, g: 47, b: 63),
//                             linesColor: .black.withAlphaComponent(0.19),
//                             focusLineColor: .black.withAlphaComponent(0.42),

//                             intervalUnvisibleColor: UIColor(r: 29, g: 42, b: 58).withAlphaComponent(0.7),
//                             intervalBorderColor: UIColor(r: 53, g: 70, b: 89).withAlphaComponent(0.88))
// )

// светлая тема:
// internal static let dayStyle: Style = Style(
//     name: "Day",
//     backgroundColor: UIColor(r: 239, g: 239, b: 244),
//     mainColor: .white,
//     indicatorColor: .gray, // что это?
//     titleColor: .black,
//     subTitleColor: UIColor(r: 109, g: 109, b: 114),
//     textColor: .black,
//     secondaryTextColor: UIColor(r: 152, g: 158, b: 164), // а нужен ли?
//     activeElementColor: UIColor(r: 0, g: 126, b: 229),
//     separatorColor: UIColor(r: 200, g: 199, b: 204),
//     selectedColor: UIColor(r: 0, g: 0, b: 0, alpha: 0.15),
//     chartsStyle: ChartStyle(hintTextColor: .white,
//     						hintBackgroundColor: UIColor(r: 109, g: 109, b: 114),
//                             textColor: UIColor(r: 152, g: 158, b: 163),
//                             dotColor: .white,
//                             linesColor: .black.withAlphaComponent(0.05),
//                             focusLineColor: .black.withAlphaComponent(0.19),

//                             intervalUnvisibleColor: UIColor(r: 246, g: 248, b: 250).withAlphaComponent(0.7),
//                             intervalBorderColor: UIColor(r: 202, g: 212, b: 222).withAlphaComponent(0.88))
// )
