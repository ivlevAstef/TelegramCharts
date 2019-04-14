//
//  ChartStyle.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 13/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

public struct ChartStyle {
    public let intervalTextColor: UIColor
    
    public let hintTextColor: UIColor
    public let hintBackgroundColor: UIColor
    public let hintBarColor: UIColor
    public let hintArrowColor: UIColor

    public let textColor: UIColor
    public let textShadowColor: UIColor

    public let dotColor: UIColor
    public let linesColor: UIColor
    public let focusLineColor: UIColor

    public let intervalUnvisibleColor: UIColor
    public let intervalBorderColor: UIColor
    public let intervalArrowColor: UIColor

    public init(intervalTextColor: UIColor,
                hintTextColor: UIColor,
                hintBackgroundColor: UIColor,
                hintBarColor: UIColor,
                hintArrowColor: UIColor,
                textColor: UIColor,
                textShadowColor: UIColor,
                dotColor: UIColor,
                linesColor: UIColor,
                focusLineColor: UIColor,
                intervalUnvisibleColor: UIColor,
                intervalBorderColor: UIColor,
                intervalArrowColor: UIColor)
    {
        self.intervalTextColor = intervalTextColor
        self.hintTextColor = hintTextColor
        self.hintBackgroundColor = hintBackgroundColor
        self.hintBarColor = hintBarColor
        self.hintArrowColor = hintArrowColor
        self.textColor = textColor
        self.textShadowColor = textShadowColor
        self.dotColor = dotColor
        self.linesColor = linesColor
        self.focusLineColor = focusLineColor
        self.intervalUnvisibleColor = intervalUnvisibleColor
        self.intervalBorderColor = intervalBorderColor
        self.intervalArrowColor = intervalArrowColor
    }

}
