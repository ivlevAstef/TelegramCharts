//
//  StyleProvider.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

extension Style
{
    internal static let dayStyle: Style = Style(
        name: "Day",
        backgroundColor: UIColor(r: 239, g: 239, b: 244),
        mainColor: .white,
        indicatorColor: .gray,
        titleColor: .black,
        subTitleColor: UIColor(r: 109, g: 109, b: 114),
        textColor: .black,
        activeElementColor: UIColor(r: 0, g: 126, b: 229),
        separatorColor: UIColor(r: 200, g: 199, b: 204),
        selectedColor: UIColor(r: 0, g: 0, b: 0, alpha: 0.1),
        statusBarStyle: UIStatusBarStyle.default,
        chartStyle: dayChartStyle
    )

    internal static let darkStyle: Style = Style(
        name: "Night",
        backgroundColor: UIColor(r: 24, g: 34, b: 45),
        mainColor: UIColor(r: 33, g: 47, b: 63),
        indicatorColor: UIColor.white,
        titleColor: .white,
        subTitleColor: UIColor(r: 91, g: 107, b: 127),
        textColor: .white,
        activeElementColor: UIColor(r: 24, g: 145, b: 255),
        separatorColor: UIColor(r: 18, g: 26, b: 36),
        selectedColor: UIColor(r: 255, g: 255, b: 255, alpha: 0.1),
        statusBarStyle: UIStatusBarStyle.lightContent,
        chartStyle: darkChartStyle
    )

    internal static let dayChartStyle: ChartStyle = ChartStyle(
        hintTextColor: UIColor(r: 109, g: 109, b: 114),
        hintBackgroundColor: UIColor(r: 244, g: 244, b: 250),
        textColor: UIColor(r: 152, g: 158, b: 163),
        dotColor: .white,
        linesColor: UIColor.black.withAlphaComponent(0.05),
        focusLineColor: UIColor.black.withAlphaComponent(0.19),
        intervalUnvisibleColor: UIColor(r: 246, g: 248, b: 250, alpha: 0.7),
        intervalBorderColor: UIColor(r: 202, g: 212, b: 222, alpha: 0.88),
        intervalArrowColor: .white
    )    

    internal static let darkChartStyle: ChartStyle = ChartStyle(
        hintTextColor: .white,
        hintBackgroundColor: UIColor(r: 26, g: 40, b: 55),
        textColor: UIColor(r: 93, g: 109, b: 126),
        dotColor: UIColor(r: 33, g: 47, b: 63),
        linesColor: UIColor.black.withAlphaComponent(0.19),
        focusLineColor: UIColor.black.withAlphaComponent(0.42),
        intervalUnvisibleColor: UIColor(r: 29, g: 42, b: 58, alpha: 0.7),
        intervalBorderColor: UIColor(r: 53, g: 70, b: 89, alpha: 0.88),
        intervalArrowColor: .white
    )
}
