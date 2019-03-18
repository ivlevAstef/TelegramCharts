//
//  VerticalAxisView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 18/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

internal class VerticalAxisView: UIView
{
    private var aabb: AABB?

    private let font: UIFont = UIFont.systemFont(ofSize: 12.0)
    private var color: UIColor = .black

    internal init() {
        super.init(frame: .zero)

        backgroundColor = .clear
    }

    internal func setStyle(_ style: ChartStyle) {
        color = style.textColor
    }

    internal func update(aabb: AABB?, animated: Bool) {
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
