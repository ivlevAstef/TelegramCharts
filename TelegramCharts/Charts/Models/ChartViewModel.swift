//
//  ChartViewModel.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

public class ChartViewModel
{
    public struct Point
    {
        public let date: Chart.Date
        public let value: Chart.Value
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

    internal private(set) lazy var aabb: Chart.AABB = {
        var minDate: Chart.Date = Chart.Date.max
        var maxDate: Chart.Date = Chart.Date.min
        var minValue: Chart.Value = Chart.Value.max
        var maxValue: Chart.Value = Chart.Value.min
        for point in points {
            minDate = min(minDate, point.date)
            maxDate = max(maxDate, point.date)
            minValue = min(minValue, point.value)
            maxValue = max(maxValue, point.value)
        }

        return Chart.AABB(minDate: minDate, maxDate: maxDate, minValue: minValue, maxValue: maxValue)
    }()

    public init(name: String, points: [Point], color: UIColor) {
        assert(points.count > 0)
        self.name = name
        self.points = points
        self.color = color
    }

    internal func calculateUIPoints(for rect: CGRect) -> [CGPoint] {
        return calculateUIPoints(for: rect, aabb: aabb)
    }

    internal func calculateUIPoints(for rect: CGRect, aabb: Chart.AABB) -> [CGPoint] {
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
