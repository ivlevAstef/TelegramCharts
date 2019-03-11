//
//  SwitchStyleModeTableViewCell.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class SwitchStyleModeTableViewCell: UITableViewCell, Stylizing
{
    internal let identifier: String = "SwitchStyleModeTableViewCell"

    internal var tapCallback: (() -> Void)?

    @IBOutlet private var switchButton: UIButton!

    internal func applyStyle(_ style: Style) {
        backgroundColor = style.mainColor
        switchButton.setTitleColor(style.activeElementColor, for: .normal)
    }

    internal func setText(_ text: String) {
        switchButton.setTitle(text, for: .normal)
    }

    @IBAction private func switchButtonTapped(_ sender: Any) {
        tapCallback?()
    }
}

