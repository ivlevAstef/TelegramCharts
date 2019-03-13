//
//  Charts+AABB.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 13/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

extension Chart.AABB
{

    internal func copyWithPadding(date datePadding: Double, value valuePadding: Double) -> Chart.AABB {
        let minDate = self.minDate - Chart.Date(Double(self.dateInterval) * datePadding)
        let maxDate = self.maxDate + Chart.Date(Double(self.dateInterval) * datePadding)
        let minValue = self.minValue - Chart.Value(Double(self.valueInterval) * valuePadding)
        let maxValue = self.maxValue + Chart.Value(Double(self.valueInterval) * valuePadding)
        return Chart.AABB(minDate: minDate, maxDate: maxDate, minValue: minValue, maxValue: maxValue)
    }

    internal func calculateUIPoint(date: Chart.Date, value: Chart.Value, rect: CGRect) -> CGPoint {
        let xScale = Double(rect.width) / Double(dateInterval)
        let yScale = Double(rect.height) / Double(valueInterval)

        return CGPoint(x: Double(rect.minX) + Double(date - minDate) * xScale,
                       y: Double(rect.maxY) - Double(value - minValue) * yScale)
    }

    internal func calculateDate(x: CGFloat, rect: CGRect) -> Chart.Date {
        let xScale = Double(dateInterval) / Double(rect.width)
        return minDate + Chart.Date(Double(x - rect.minX) * xScale)
    }
}


