//
//  AABB.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 17/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal struct AABB: Hashable
{
    internal typealias Date = Chart.Date
    internal typealias Value = Double
    
    internal static let empty: AABB = AABB(minDate: 0, maxDate: 0, minValue: 0, maxValue: 0)
    internal let minDate: Date
    internal let maxDate: Date
    internal let minValue: Value
    internal let maxValue: Value
    
    internal let dateInterval: Date
    internal let valueInterval: Value
    
    internal init(minDate: Date, maxDate: Date, minValue: Value, maxValue: Value) {
        self.minDate = minDate
        self.maxDate = maxDate
        self.minValue = minValue
        self.maxValue = maxValue
        
        self.dateInterval = maxDate - minDate
        self.valueInterval = maxValue - minValue
    }
    
    internal static func ==(lhs: AABB, rhs: AABB) -> Bool {
        return lhs.minDate == rhs.minDate && lhs.maxDate == rhs.maxDate &&
               abs(lhs.minValue - rhs.minValue) < 1.0e-3 && abs(lhs.maxValue - rhs.maxValue) < 1.0e-3
    }
    
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(minDate)
        hasher.combine(maxDate)
        hasher.combine(minValue)
        hasher.combine(maxValue)
    }
}
