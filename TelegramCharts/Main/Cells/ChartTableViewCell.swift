//
//  ChartTableViewCell.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class ChartTableViewCell: UITableViewCell, Stylizing
{
    internal let identifier: String = "ChartTableViewCell"

    @IBOutlet private var chartView: ChartWithIntervalView!

    internal func applyStyle(_ style: Style) {
        backgroundColor = style.mainColor
        chartView.backgroundColor = style.mainColor

        chartView.setStyle(style.chartStyle)
    }

    internal func setChart(_ chartViewModel: ChartViewModel) {
        chartView.layoutIfNeeded()
        chartView.setChart(chartViewModel)
    }

    internal static func calculateHeight() -> CGFloat {
        return ChartWithIntervalView.calculateHeight()
    }
}
