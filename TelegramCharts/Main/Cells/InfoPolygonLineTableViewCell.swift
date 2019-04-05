//
//  InfoPolygonLineTableViewCell.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal class InfoPolygonLineTableViewCell: UITableViewCell, Stylizing
{
    internal let identifier: String = "InfoPolygonLineTableViewCell"

    @IBOutlet private var colorView: UIView!
    @IBOutlet private var nameLabel: UILabel!

    @IBOutlet private var separatorView: UIView!
    @IBOutlet private var separatorViewHeightConstraint: NSLayoutConstraint!

    private var colorViewColor: UIColor?
    private var separatorViewColor: UIColor?
    private var selectedColorViewColor: UIColor?

    internal func applyStyle(_ style: Style) {
        colorView.layer.cornerRadius = 4.0
        backgroundColor = style.mainColor
        nameLabel.textColor = style.textColor
        tintColor = style.activeElementColor

        separatorView.backgroundColor = style.separatorColor
        separatorViewColor = style.separatorColor

        selectedColorViewColor = style.selectedColor

        selectedBackgroundView = UIView(frame: .zero)

        separatorViewHeightConstraint.constant = 0.5
    }

    internal func setEnabledSeparator(isEnabled: Bool) {
        separatorView.isHidden = !isEnabled
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
        separatorView.backgroundColor = self.separatorViewColor

        updateSelectedBackgroundColor(highlighted: !highlighted)
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.updateSelectedBackgroundColor(highlighted: highlighted)
        })
    }

    private func updateSelectedBackgroundColor(highlighted: Bool) {
        if highlighted {
            self.selectedBackgroundView?.backgroundColor = selectedColorViewColor
        } else {
            self.selectedBackgroundView?.backgroundColor = .clear
        }
    }
}
