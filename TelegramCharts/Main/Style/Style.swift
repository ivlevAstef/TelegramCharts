//
//  Style.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal struct Style
{
    // It's not ideally, but works and easy :)
    internal let name: String

    internal let backgroundColor: UIColor
    internal let mainColor: UIColor
    internal let indicatorColor: UIColor

    internal let titleColor: UIColor
    internal let subTitleColor: UIColor
    internal let textColor: UIColor
    internal let activeElementColor: UIColor
    internal let separatorColor: UIColor
    internal let selectedColor: UIColor

    internal let statusBarStyle: UIStatusBarStyle

    internal let chartStyle: ChartStyle
}
