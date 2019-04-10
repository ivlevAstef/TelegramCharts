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
    internal struct Data
    {
        internal let date: AABB.Date
        internal let from: AABB.Value
        internal let to: AABB.Value
    }
    
    internal let isVisible: Bool
    internal let aabb: AABB
    internal let data: [Data]
    internal let color: UIColor
    internal let size: Double
    
    internal init(isVisible: Bool, aabb: AABB, data: [Data], color: UIColor, size: Double) {
        self.isVisible = isVisible
        self.aabb = aabb
        self.data = data
        self.color = color
        self.size = size
    }
    
    internal func translate(value: AABB.Value, to rect: CGRect) -> CGFloat {
        let yScale = rect.height / CGFloat(aabb.valueInterval)
        let yOffset = rect.maxY + CGFloat(aabb.minValue) * yScale
        
        return yOffset - CGFloat(value) * yScale
    }
    
    internal func translate(data: Data, to rect: CGRect) -> (from: CGPoint, to: CGPoint) {
        let xScale = rect.width / CGFloat(aabb.dateInterval)
        let yScale = rect.height / CGFloat(aabb.valueInterval)
        let xOffset = rect.minX - CGFloat(aabb.minDate) * xScale
        let yOffset = rect.maxY + CGFloat(aabb.minValue) * yScale
        
        var result: (from: CGPoint, to: CGPoint) = (.zero, .zero)
        
        let x = xOffset + CGFloat(data.date) * xScale
        result.from.y = yOffset - CGFloat(data.from) * yScale
        result.to.y = yOffset - CGFloat(data.to) * yScale
        result.from.x = x
        result.to.x = x
        
        return result
    }

    internal func translate(to rect: CGRect) -> [(from: CGPoint, to: CGPoint)] {
        let xScale = rect.width / CGFloat(aabb.dateInterval)
        let yScale = rect.height / CGFloat(aabb.valueInterval)
        let xOffset = rect.minX - CGFloat(aabb.minDate) * xScale
        let yOffset = rect.maxY + CGFloat(aabb.minValue) * yScale

        var result: [(from: CGPoint, to: CGPoint)] = .init(repeating: (.zero, .zero), count: data.count)
        for i in 0..<data.count {
            let x = xOffset + CGFloat(data[i].date) * xScale
            result[i].from.y = yOffset - CGFloat(data[i].from) * yScale
            result[i].to.y = yOffset - CGFloat(data[i].to) * yScale
            result[i].from.x = x
            result[i].to.x = x
        }

        return result
    }
    
    internal func find(by date: Chart.Date) -> Data? {
        for iter in data {
            if iter.date == date {
                return iter
            }
        }
        return nil
    }

}
