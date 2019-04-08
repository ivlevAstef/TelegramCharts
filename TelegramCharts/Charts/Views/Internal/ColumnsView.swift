//
//  ColumnsView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 08/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal protocol ColumnsView: class
{
    // 1 - for interval, 2 - for normal
    func setSize(_ size: Double)
    func setColumns(_ columnViewModels: [ColumnViewModel])
    func update(aabb: AABB?, animated: Bool, duration: TimeInterval)
}
