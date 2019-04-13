//
//  ColumnUIModel.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 10/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal struct ColumnUIModel
{
    internal struct UIData
    {
        internal let from: CGPoint
        internal let to: CGPoint
    }

    internal struct Data
    {
        internal let date: AABB.Date
        internal let from: AABB.Value
        internal let to: AABB.Value
        internal let original: ColumnViewModel.Value
    }
    
    internal let isVisible: Bool
    internal let isOpacity: Bool
    internal let aabb: AABB
    internal let data: [Data]
    internal let verticalValues: [AABB.Value]
    internal let color: UIColor
    internal let name: String
    internal let size: Double
    internal let type: ColumnViewModel.ColumnType
    
    internal init(isVisible: Bool, isOpacity: Bool,
                  aabb: AABB, data: [Data], verticalValues: [AABB.Value],
                  color: UIColor, name: String, size: Double, type: ColumnViewModel.ColumnType) {
        self.isVisible = isVisible
        self.isOpacity = isOpacity
        self.aabb = aabb
        self.data = data
        self.verticalValues = verticalValues
        self.color = color
        self.name = name
        self.size = size
        self.type = type
    }
    
    internal func interval(by rect: CGRect, minX: CGFloat, maxX: CGFloat) -> ChartViewModel.Interval {
        let xScale = rect.width / CGFloat(aabb.dateInterval)
        let xOffset = rect.minX - CGFloat(aabb.minDate) * xScale
        
        var minDate = aabb.maxDate
        var maxDate = aabb.minDate
        for i in 0..<data.count {
            let x = xOffset + CGFloat(data[i].date) * xScale
            if minX <= x && x <= maxX {
                minDate = min(minDate, data[i].date)
                maxDate = max(maxDate, data[i].date)
            }
        }
        return ChartViewModel.Interval(from: minDate, to: maxDate)
    }
    
    internal func translate(value: AABB.Value, to rect: CGRect) -> CGFloat {
        let yScale = rect.height / CGFloat(aabb.valueInterval)
        let yOffset = rect.maxY + CGFloat(aabb.minValue) * yScale
        
        return yOffset - CGFloat(value) * yScale
    }
    
    internal func translate(date: Chart.Date, to rect: CGRect) -> CGFloat {
        let xScale = rect.width / CGFloat(aabb.dateInterval)
        let xOffset = rect.minX - CGFloat(aabb.minDate) * xScale
        
        return xOffset + CGFloat(date) * xScale
    }
    
    internal func translate(data: Data, to rect: CGRect) -> UIData {
        let xScale = rect.width / CGFloat(aabb.dateInterval)
        let yScale = rect.height / CGFloat(aabb.valueInterval)
        let xOffset = rect.minX - CGFloat(aabb.minDate) * xScale
        let yOffset = rect.maxY + CGFloat(aabb.minValue) * yScale

        let x = xOffset + CGFloat(data.date) * xScale
        return UIData(from: CGPoint(x: x, y: yOffset - CGFloat(data.from) * yScale),
                      to: CGPoint(x: x, y: yOffset - CGFloat(data.to) * yScale))
    }

    internal func translate(to rect: CGRect) -> [UIData] {
        let xScale = rect.width / CGFloat(aabb.dateInterval)
        let yScale = rect.height / CGFloat(aabb.valueInterval)
        let xOffset = rect.minX - CGFloat(aabb.minDate) * xScale
        let yOffset = rect.maxY + CGFloat(aabb.minValue) * yScale

        var result: [UIData] = []
        for i in 0..<data.count {
            let x = xOffset + CGFloat(data[i].date) * xScale
            result.append(UIData(
                from: CGPoint(x: x, y: yOffset - CGFloat(data[i].from) * yScale),
                to: CGPoint(x: x, y: yOffset - CGFloat(data[i].to) * yScale)
            ))
        }

        return result
    }

    internal func split(uiDatas: [UIData], in interval: ChartViewModel.Interval) -> [UIData] {
        var firstIndex = 0
        var lastIndex = 0
        for i in 0..<data.count {
            if data[i].date < interval.from {
                firstIndex = i
            }
            lastIndex = i

            if interval.to < data[i].date {
                break
            }
        }

        return Array(uiDatas.dropFirst(firstIndex).dropLast(data.count - lastIndex - 1))
    }
    
    internal func find(by date: Chart.Date) -> Data? {
        for iter in data {
            if iter.date == date {
                return iter
            }
        }
        return nil
    }

    internal func index(by date: Chart.Date) -> Int? {
        for i in 0..<data.count {
            if data[i].date == date {
                return i
            }
        }
        return nil
    }

}
