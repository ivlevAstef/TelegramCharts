//
//  InfoPolygonLineTableViewCell.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class InfoPolygonLineTableViewCell: UITableViewCell, Stylizing
{
    internal let identifier: String = "InfoPolygonLineTableViewCell"

    @IBOutlet private var colorView: UIView!
    @IBOutlet private var nameLabel: UILabel!

    private var colorViewColor: UIColor?
    private var selectedColorViewColor: UIColor?

    internal func applyStyle(_ style: Style) {
        colorView.layer.cornerRadius = 4.0
        backgroundColor = style.mainColor
        nameLabel.textColor = style.textColor
        tintColor = style.activeElementColor

        selectedColorViewColor = style.selectedColor
        selectedBackgroundView = UIView(frame: .zero)
        selectedBackgroundView?.backgroundColor = .clear
    }

    internal func setColor(_ color: UIColor) {
        self.colorViewColor = color
        colorView.backgroundColor = color
    }

    internal func setName(_ name: String) {
        nameLabel.text = name
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

        UIView.animate(withDuration: 0.1, delay: 0.2, animations: {
            if highlighted {
                self.selectedBackgroundView?.backgroundColor = self.selectedColorViewColor
            } else {
                self.selectedBackgroundView?.backgroundColor = .clear
            }
        })
    }
}
