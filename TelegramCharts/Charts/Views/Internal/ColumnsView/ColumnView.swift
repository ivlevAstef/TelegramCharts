//
//  ColumnsView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 08/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal protocol ColumnView: class
{
    init(margins: UIEdgeInsets)
    func update(ui: ColumnUIModel, animated: Bool, duration: TimeInterval)
}
