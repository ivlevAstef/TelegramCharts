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
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!

    internal func applyStyle(_ style: Style) {
        backgroundColor = style.mainColor
        chartView.backgroundColor = style.mainColor
        loadingIndicator.color = style.indicatorColor

        chartView.setStyle(style.chartStyle)
    }

    internal func setChart(_ chartViewModel: ChartViewModel) {
        loadingIndicator.stopAnimating()
        chartView.setChart(chartViewModel)
    }

    internal static func calculateHeight() -> CGFloat {
        return ChartWithIntervalView.calculateHeight()
    }
}
