//
//  CPolygonLineViewModel.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

public class PolygonLineViewModel
{
    public struct Point
    {
        public let date: PolygonLine.Date
        public let value: PolygonLine.Value
    }

    public struct Color
    {
        public let r: UInt8
        public let g: UInt8
        public let b: UInt8
    }

    public let name: String
    public let points: [Point]
    public let color: UIColor
    public internal(set) var isVisible: Bool = true

    internal private(set) lazy var aabb: AABB = {
        var minDate: PolygonLine.Date = PolygonLine.Date.max
        var maxDate: PolygonLine.Date = PolygonLine.Date.min
        var minValue: PolygonLine.Value = PolygonLine.Value.max
        var maxValue: PolygonLine.Value = PolygonLine.Value.min
        for point in points {
            minDate = min(minDate, point.date)
            maxDate = max(maxDate, point.date)
            minValue = min(minValue, point.value)
            maxValue = max(maxValue, point.value)
        }

        return AABB(minDate: minDate, maxDate: maxDate, minValue: minValue, maxValue: maxValue)
    }()

    public init(name: String, points: [Point], color: UIColor) {
        assert(points.count > 0)
        self.name = name
        self.points = points
        self.color = color
    }

    internal func calculateAABBInInterval(from: PolygonLine.Date, to: PolygonLine.Date) -> AABB? {
        var minValue: PolygonLine.Value = PolygonLine.Value.max
        var maxValue: PolygonLine.Value = PolygonLine.Value.min

        var hasPoints: Bool = false
        for i in 0..<points.count {
            let point = points[i]
            if from <= point.date && point.date <= to {
                hasPoints = true
                
                minValue = min(minValue, point.value)
                maxValue = max(maxValue, point.value)
                
                if let prevPoint = points[safe: i - 1], prevPoint.date < from {
                    let t = Double(from - prevPoint.date) / Double(point.date - prevPoint.date)
                    let value = prevPoint.value + PolygonLine.Value(t * Double(point.value - prevPoint.value))
                    minValue = min(minValue, value)
                    maxValue = max(maxValue, value)
                }
                if let nextPoint = points[safe: i + 1], nextPoint.date > to {
                    let t = Double(to - point.date) / Double(nextPoint.date - point.date)
                    let value = point.value + PolygonLine.Value(t * Double(nextPoint.value - point.value))
                    minValue = min(minValue, value)
                    maxValue = max(maxValue, value)
                }
            }
        }

        if hasPoints {
            return AABB(minDate: from, maxDate: to, minValue: minValue, maxValue: maxValue)
        }
        
        return nil
    }

    internal func calculateUIPoints(for rect: CGRect) -> [CGPoint] {
        return calculateUIPoints(for: rect, aabb: aabb)
    }

    internal func calculateUIPoints(for rect: CGRect, aabb: AABB) -> [CGPoint] {
        return PolygonLineViewModel.calculateUIPoints(for: points, rect: rect, aabb: aabb)
    }
    
    internal static func calculateUIPoints(for points: [Point], rect: CGRect, aabb: AABB) -> [CGPoint] {
        let xScale = Double(rect.width) / Double(aabb.dateInterval)
        let yScale = Double(rect.height) / Double(aabb.valueInterval)
        
        let xOffset = Double(rect.minX)
        let yOffset = Double(rect.maxY)
        
        return points.map { point in
            CGPoint(x: xOffset + Double(point.date - aabb.minDate) * xScale,
                    y: yOffset - Double(point.value - aabb.minValue) * yScale)
        }
    }
}
