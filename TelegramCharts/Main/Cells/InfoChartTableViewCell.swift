//
//  InfoChartTableViewCell.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class InfoChartTableViewCell: UITableViewCell, Stylizing
{
    internal let identifier: String = "InfoChartTableViewCell"

    @IBOutlet private var colorView: UIView!
    @IBOutlet private var chartNameLabel: UILabel!

    private var colorViewColor: UIColor?

    internal func applyStyle(_ style: Style) {
        colorView.layer.cornerRadius = 4.0
        backgroundColor = style.mainColor
        chartNameLabel.textColor = style.textColor
        tintColor = style.activeElementColor

        selectedBackgroundView = UIView(frame: .zero)
        selectedBackgroundView?.backgroundColor = style.selectedColor
    }

    internal func setColor(_ color: UIColor) {
        self.colorViewColor = color
        colorView.backgroundColor = color
    }

    internal func setChartName(_ name: String) {
        chartNameLabel.text = name
    }

    internal func setCheckmark(_ enabled: Bool) {
        if enabled {
            self.accessoryType = .checkmark
        } else {
            self.accessoryType = .none
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        colorView.backgroundColor = self.colorViewColor
    }
}
