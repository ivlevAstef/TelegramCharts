//
//  ChartsTableViewCell.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class ChartsTableViewCell: UITableViewCell, Stylizing
{
    internal let identifier: String = "ChartsTableViewCell"

    @IBOutlet private var chartsView: ChartsView!
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!

    internal func applyStyle(_ style: Style) {
        backgroundColor = style.mainColor
        chartsView.backgroundColor = style.mainColor
        loadingIndicator.color = style.indicatorColor
    }

    internal func setCharts(_ charts: ChartsViewModel)
    {
        loadingIndicator.stopAnimating()
    }

    internal static func calculateHeight() -> CGFloat {
        return UIScreen.main.bounds.width
    }
}
