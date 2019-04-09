//
//  IActualizedCell.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 09/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal protocol IActualizedCell: class {
    func actualizeFrame(width: CGFloat)
}
