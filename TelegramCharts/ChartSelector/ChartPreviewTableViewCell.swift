//
//  ChartPreviewTableViewCell.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 20/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//


import UIKit

internal class ChartPreviewTableViewCell: UITableViewCell, Stylizing
{
    internal let identifier: String = "ChartPreviewTableViewCell"

    @IBOutlet private var chartView: SimpleChartView!
    @IBOutlet private var chartName: UILabel!

    private var colorViewColor: UIColor?
    private var selectedColorViewColor: UIColor?

    internal func applyStyle(_ style: Style) {
        backgroundColor = style.mainColor

        chartName.textColor = style.textColor

        chartView.backgroundColor = UIColor.clear
        chartView.layer.borderColor = style.backgroundColor.cgColor
        chartView.layer.borderWidth = 1.0

        selectedColorViewColor = style.selectedColor

        selectedBackgroundView = UIView(frame: .zero)
        selectedBackgroundView?.backgroundColor = .clear
    }

    internal func setName(_ name: String) {
        chartName.text = name
    }

    internal func setChart(_ chartViewModel: ChartViewModel) {
        chartView.layoutIfNeeded()
        chartView.setChart(chartViewModel)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        UIView.animate(withDuration: 0.1, delay: 0.2, animations: { [weak self, selectedColorViewColor] in
            if highlighted {
                self?.selectedBackgroundView?.backgroundColor = selectedColorViewColor
            } else {
                self?.selectedBackgroundView?.backgroundColor = .clear
            }
        })
    }
}

