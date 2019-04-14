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
        backgroundColor: .white,
        intervalTextColor: .black,
        hintTextColor: UIColor(r: 109, g: 109, b: 114),
        hintBackgroundColor: UIColor(r: 244, g: 244, b: 250),
        hintBarColor: UIColor(hex: "FFFFFF", alpha: 0.5),
        hintArrowColor: UIColor(hex: "59606D", alpha: 0.3),
        textColor: UIColor(hex: "8E8E93"),
        textShadowColor: UIColor.white.withAlphaComponent(0.75),
        dotColor: .white,
        linesColor: UIColor(hex: "182D3B", alpha: 0.1),
        focusLineColor: UIColor(hex: "182D3B", alpha: 0.2),
        intervalUnvisibleColor: UIColor(hex: "E2EEF9", alpha: 0.6),
        intervalBorderColor: UIColor(hex: "C0D1E1"),
        intervalArrowColor: .white
    )    

    internal static let darkChartStyle: ChartStyle = ChartStyle(
        backgroundColor: UIColor(r: 33, g: 47, b: 63),
        intervalTextColor: .white,
        hintTextColor: .white,
        hintBackgroundColor: UIColor(r: 26, g: 40, b: 55),
        hintBarColor: UIColor(hex: "212F3F", alpha: 0.5),
        hintArrowColor: UIColor(hex: "D2D5D7", alpha: 0.3),
        textColor: UIColor(hex: "8596ab"),
        textShadowColor: UIColor(r: 33, g: 47, b: 63).withAlphaComponent(0.75),
        dotColor: UIColor(r: 33, g: 47, b: 63),
        linesColor: UIColor(hex: "8596AB", alpha: 0.2),
        focusLineColor: UIColor(hex: "BACCE1", alpha: 0.6),
        intervalUnvisibleColor: UIColor(hex: "18222D", alpha: 0.6),
        intervalBorderColor: UIColor(hex: "56626D"),
        intervalArrowColor: .white
    )
}
