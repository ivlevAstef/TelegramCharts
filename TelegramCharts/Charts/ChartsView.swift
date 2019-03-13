//
//  ChartsView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 13/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

public class ChartsView: UIView
{
    public init() {
        super.init(frame: .zero)

        self.backgroundColor = .blue
    }

    public func setCharts(_ charts: ChartsViewModel)
    {

    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
