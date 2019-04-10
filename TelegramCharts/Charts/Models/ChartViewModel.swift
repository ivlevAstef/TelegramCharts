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

public class ChartViewModel
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
            return ColumnViewModel(name: column.name, values: column.values, color: UIColor(hex: column.color), type: type)
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

    public func toogleVisibleColumn(_ column: ColumnViewModel) -> Bool {
        assert(columns.contains(where: { $0 === column }), "Doen't found polygon line in data")
        if column.isVisible && columns.filter({ $0.isVisible }).count <= 1 {
            return false
        }
        
        column.isVisible.toggle()
        updateListeners.forEach { $0.value?.chartVisibleIsChanged(self) }
        
        return true
    }

    public func updateInterval(_ interval: Interval) {
        self.interval = interval
        updateListeners.forEach { $0.value?.chartIntervalIsChanged(self) }
    }
}

extension UIColor
{
    fileprivate convenience init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }

        if hex.count != 6 {
            self.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            return
        }

        var hexValue: UInt32 = 0
        Scanner(string: hex).scanHexInt32(&hexValue)

        self.init(
            red: CGFloat((hexValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hexValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hexValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
