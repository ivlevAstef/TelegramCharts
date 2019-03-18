//
//  AABB.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 17/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

internal struct AABB
{
    internal static let empty: AABB = AABB(minDate: 0, maxDate: 0, minValue: 0, maxValue: 0)
    internal let minDate: PolygonLine.Date
    internal let maxDate: PolygonLine.Date
    internal let minValue: PolygonLine.Value
    internal let maxValue: PolygonLine.Value
    
    internal let dateInterval: PolygonLine.Date
    internal let valueInterval: PolygonLine.Value
    
    internal init(minDate: PolygonLine.Date, maxDate: PolygonLine.Date, minValue: PolygonLine.Value, maxValue: PolygonLine.Value) {
        self.minDate = minDate
        self.maxDate = maxDate
        self.minValue = minValue
        self.maxValue = maxValue
        
        self.dateInterval = maxDate - minDate
        self.valueInterval = maxValue - minValue
    }

    internal func copyWithIntellectualPadding(date datePadding: Double, value valuePadding: Double) -> AABB {
        let aabb = copyWithPadding(date: datePadding, value: valuePadding)
        let minValue = aabb.calculateValueBegin()
        let maxValue = aabb.calculateValueEnd()
        return AABB(minDate: aabb.minDate, maxDate: aabb.maxDate, minValue: minValue, maxValue: maxValue)
    }
    
    internal func copyWithPadding(date datePadding: Double, value valuePadding: Double) -> AABB {
        let minDate = self.minDate - PolygonLine.Date(Double(self.dateInterval) * datePadding)
        let maxDate = self.maxDate + PolygonLine.Date(Double(self.dateInterval) * datePadding)
        let minValue = self.minValue - PolygonLine.Value(Double(self.valueInterval) * valuePadding)
        let maxValue = self.maxValue + PolygonLine.Value(Double(self.valueInterval) * valuePadding)
        return AABB(minDate: minDate, maxDate: maxDate, minValue: minValue, maxValue: maxValue)
    }
    
    internal func calculateUIPoint(date: PolygonLine.Date, value: PolygonLine.Value, rect: CGRect) -> CGPoint {
        let xScale = Double(rect.width) / Double(dateInterval)
        let yScale = Double(rect.height) / Double(valueInterval)
        
        return CGPoint(x: Double(rect.minX) + Double(date - minDate) * xScale,
                       y: Double(rect.maxY) - Double(value - minValue) * yScale)
    }
    
    internal func calculateDate(x: CGFloat, rect: CGRect) -> PolygonLine.Date {
        let xScale = Double(dateInterval) / Double(rect.width)
        return minDate + PolygonLine.Date(Double(x - rect.minX) * xScale)
    }


    private func calculateValueBegin() -> PolygonLine.Value {
        let roundScale = calculateValueRoundScale()
        return minValue - minValue % roundScale
    }

    private func calculateValueEnd() -> PolygonLine.Value {
        let roundScale = calculateValueRoundScale()
        return maxValue + (roundScale - maxValue % roundScale)
    }

    private func calculateValueRoundScale() -> PolygonLine.Value {
        var interval = Double(maxValue - minValue)
        if interval <= 50 {
            return 1
        }

        var scale = 10
        while interval >= 500 {
            interval /= 10
            scale *= 10
        }

        return scale
    }
}
