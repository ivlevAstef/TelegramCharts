//
//  ChartStyle.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 13/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

public struct ChartStyle {
    public let hintTextColor: UIColor
    public let hintBackgroundColor: UIColor

    public let textColor: UIColor

    public let dotColor: UIColor
    public let linesColor: UIColor
    public let focusLineColor: UIColor

    public let intervalUnvisibleColor: UIColor
    public let intervalBorderColor: UIColor
    public let intervalArrowColor: UIColor

    public init(hintTextColor: UIColor,
                hintBackgroundColor: UIColor,
                textColor: UIColor,
                dotColor: UIColor,
                linesColor: UIColor,
                focusLineColor: UIColor,
                intervalUnvisibleColor: UIColor,
                intervalBorderColor: UIColor,
                intervalArrowColor: UIColor)
    {
        self.hintTextColor = hintTextColor
        self.hintBackgroundColor = hintBackgroundColor
        self.textColor = textColor
        self.dotColor = dotColor
        self.linesColor = linesColor
        self.focusLineColor = focusLineColor
        self.intervalUnvisibleColor = intervalUnvisibleColor
        self.intervalBorderColor = intervalBorderColor
        self.intervalArrowColor = intervalArrowColor
    }

}
