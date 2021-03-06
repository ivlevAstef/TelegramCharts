//
//  ChartViewModel.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

public protocol ChartUpdateListener: class
{
    func chartVisibleIsChanged(_ viewModel: ChartViewModel)
    func chartIntervalIsChanged(_ viewModel: ChartViewModel)
}

public final class ChartViewModel
{
    public struct Interval
    {
        public static let empty: Interval = Interval(from: 0, to: 0)
        public let from: Chart.Date
        public let to: Chart.Date
    }

    public let name: String
    public let yScaled: Bool
    public let stacked: Bool
    public let percentage: Bool
    
    public let dates: [Chart.Date]
    public let columns: [ColumnViewModel]

    public private(set) var interval: Interval = Interval.empty
    public private(set) var fullInterval: Interval = Interval.empty

    private var updateListeners: [WeakRef<ChartUpdateListener>] = []

    public init(chart: Chart, from: Double = 0.0, to: Double = 1.0) {
        self.dates = chart.dates
        self.columns = chart.columns.map { column in
            let type: ColumnViewModel.ColumnType
            switch column.type {
            case .line: type = .line
            case .area: type = .area
            case .bar: type = .bar
            }
            let color = UIColor(hex: column.color, alpha: 1.0)
            return ColumnViewModel(name: column.name, values: column.values, color: color, type: type)
        }
        self.name = chart.name
        self.yScaled = chart.yScaled
        self.stacked = chart.stacked
        self.percentage = chart.percentage
        
        let minDate = dates[0]
        let maxDate = dates[dates.count - 1]
        let length = Double(maxDate - minDate)
        
        self.interval = Interval(from: minDate + Chart.Date(length * from),
                                 to: minDate + Chart.Date(length * to))
        self.fullInterval = Interval(from: minDate, to: maxDate)
    }

    public func registerUpdateListener(_ listener: ChartUpdateListener) {
        if !updateListeners.contains(where: { $0.value === listener }) {
            updateListeners.append(WeakRef(listener))
        }

        updateListeners.removeAll(where: { $0.value == nil })
    }

    public func unregisterUpdateListener(_ listener: ChartUpdateListener) {
        updateListeners.removeAll(where: { $0.value === listener })
        updateListeners.removeAll(where: { $0.value == nil })
    }

    public func setVisibleColumns(isVisibles: [Bool]) {
        assert(isVisibles.count == columns.count)
        
        // Can't disable all
        if !isVisibles.contains(true) {
            assert(false, "Can't disable all")
            return
        }
        
        for (column, isVisible) in zip(columns, isVisibles) {
            column.isVisible = isVisible
        }
        
        updateListeners.forEach { $0.value?.chartVisibleIsChanged(self) }
    }

    public func updateInterval(_ interval: Interval) {
        self.interval = interval
        updateListeners.forEach { $0.value?.chartIntervalIsChanged(self) }
    }
}
