//
//  Chart.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation

public struct Chart
{
    public typealias Date = Int64
    public typealias Value = Int

    public struct Point
    {
        public let date: Date
        public let value: Value
    }

    public let name: String
    public let points: [Point]
    public let color: String

    internal struct AABB
    {
        internal let minDate: Chart.Date
        internal let maxDate: Chart.Date
        internal let minValue: Chart.Value
        internal let maxValue: Chart.Value

        internal let dateInterval: Chart.Date
        internal let valueInterval: Chart.Value

        internal init(minDate: Chart.Date, maxDate: Chart.Date, minValue: Chart.Value, maxValue: Chart.Value) {
            self.minDate = minDate
            self.maxDate = maxDate
            self.minValue = minValue
            self.maxValue = maxValue

            self.dateInterval = maxDate - minDate
            self.valueInterval = maxValue - minValue
        }
    }
}
