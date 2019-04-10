//
//  CColumnViewModel.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

public class ColumnViewModel
{
    public typealias Value = Column.Value
    public typealias Date = Column.Date
    
    internal struct Pair
    {
        public let from: AABB.Value
        public let to: AABB.Value
    }

    public struct Color
    {
        public let r: UInt8
        public let g: UInt8
        public let b: UInt8
    }
    
    public enum ColumnType {
        case line
        case bar
        case area
    }

    public let name: String
    public let dates: [Date]
    public let values: [Value]
    public let color: UIColor
    public let type: ColumnType
    
    public internal(set) var isVisible: Bool = true

    internal let id: UUID = UUID()
    internal private(set) var aabb: AABB = AABB.empty
    internal private(set) var pairs: [Pair] = []

    public init(name: String, dates: [Column.Date], values: [Value], color: UIColor, type: ColumnType) {
        assert(dates.count > 0 && values.count > 0 && dates.count == values.count)
        self.name = name
        self.dates = dates
        self.values = values
        self.color = color
        self.type = type
    }
    
    internal func update(pairs: [Pair]) {
        self.pairs = pairs
        
        var minDate: Date = Date.max
        var maxDate: Date = Date.min
        var minValue: AABB.Value = AABB.Value.greatestFiniteMagnitude
        var maxValue: AABB.Value = -AABB.Value.greatestFiniteMagnitude
        for date in dates {
            minDate = min(minDate, date)
            maxDate = max(maxDate, date)
        }
        for value in pairs {
            minValue = min(minValue, min(value.from, value.to))
            maxValue = max(maxValue, max(value.from, value.to))
        }
        
        self.aabb = AABB(id: id, minDate: minDate, maxDate: maxDate, minValue: minValue, maxValue: maxValue, childs: [])
    }

    internal func getPoint(by date: Date) -> (date: Date, pair: Pair) {
        for i in 1..<dates.count {
            if date <= dates[i] {
                if (date - dates[i-1]) < (dates[i] - date) {
                    return (dates[i-1], pairs[i-1])
                }
                return (dates[i], pairs[i])
            }
        }
        // uncritical
        return (dates.last!, pairs.last!)
    }

    internal func calculateAABBInInterval(from: Date, to: Date) -> AABB? {
        var minValue: AABB.Value = AABB.Value.greatestFiniteMagnitude
        var maxValue: AABB.Value = -AABB.Value.greatestFiniteMagnitude

        var hasPoints: Bool = false
        for i in 0..<dates.count {
            if from <= dates[safe: i + 1, default: i] && dates[safe: i - 1, default: i] <= to {
                hasPoints = true
                
                let value = pairs[i]
                minValue = min(minValue, min(value.from, value.to))
                maxValue = max(maxValue, max(value.from, value.to))

//                if let prevPoint = points[safe: i - 1], prevPoint.date < from {
//                    let t = Double(from - prevPoint.date) / Double(point.date - prevPoint.date)
//                    let value = prevPoint.value + Column.Value(t * Double(point.value - prevPoint.value))
//                    minValue = min(minValue, value)
//                    maxValue = max(maxValue, value)
//                }
//                if let nextPoint = points[safe: i + 1], nextPoint.date > to {
//                    let t = Double(to - point.date) / Double(nextPoint.date - point.date)
//                    let value = point.value + Column.Value(t * Double(nextPoint.value - point.value))
//                    minValue = min(minValue, value)
//                    maxValue = max(maxValue, value)
//                }

            }
        }

        if hasPoints {
            return AABB(id: id, minDate: from, maxDate: to, minValue: minValue, maxValue: maxValue, childs: [])
        }
        
        return nil
    }

    @inline(__always)
    internal func calculateUIPoints(for rect: CGRect) -> [(from: CGPoint, to: CGPoint)] {
        return ColumnViewModel.calculateUIPoints(for: dates, and: pairs, rect: rect, aabb: aabb)
    }

    @inline(__always)
    internal func calculateUIPoints(for rect: CGRect, aabb: AABB) -> [(from: CGPoint, to: CGPoint)] {
        return ColumnViewModel.calculateUIPoints(for: dates, and: pairs, rect: rect, aabb: aabb)
    }
    
    internal static func calculateUIPoints(for dates: [Date], and pairs: [Pair], rect: CGRect, aabb: AABB) -> [(from: CGPoint, to: CGPoint)] {
        assert(dates.count == pairs.count)
        let xScale = rect.width / CGFloat(aabb.dateInterval)
        let yScale = rect.height / CGFloat(aabb.valueInterval)
        let xOffset = rect.minX - CGFloat(aabb.minDate) * xScale
        let yOffset = rect.maxY + CGFloat(aabb.minValue) * yScale
        
        var result: [(from: CGPoint, to: CGPoint)] = .init(repeating: (.zero, .zero), count: dates.count)
        for i in 0..<dates.count {
            let x = xOffset + CGFloat(dates[i]) * xScale
            result[i].from.y = yOffset - CGFloat(pairs[i].from) * yScale
            result[i].to.y = yOffset - CGFloat(pairs[i].to) * yScale
            result[i].from.x = x
            result[i].to.x = x
        }
        
        return result
    }
}
