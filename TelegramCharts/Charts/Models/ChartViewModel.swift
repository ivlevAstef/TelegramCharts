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
        public let from: Column.Date
        public let to: Column.Date
    }

    public let name: String
    public let yScaled: Bool
    public let stacked: Bool
    public let percentage: Bool
    
    public private(set) var columns: [ColumnViewModel]
    public var visibleColumns: [ColumnViewModel] {
        return columns.filter { $0.isVisible }
    }

    public private(set) var interval: Interval = Interval.empty
    public private(set) var fullInterval: Interval = Interval.empty

    internal private(set) var visibleAABB: AABB? = nil
    internal private(set) var visibleInIntervalAABB: AABB? = nil

    private var updateListeners: [WeakRef<ChartUpdateListener>] = []

    public init(chart: Chart, from: Double = 0.0, to: Double = 1.0) {
        self.columns = chart.columns.map { column in
            let dates = column.points.map { $0.date }
            let values = column.points.map { $0.value }
            let type: ColumnViewModel.ColumnType
            switch column.type {
            case .line: type = .line
            case .area: type = .area
            case .bar: type = .bar
            }
            return ColumnViewModel(name: column.name, dates: dates, values: values, color: UIColor(hex: column.color), type: type)
        }
        self.name = chart.name
        self.yScaled = chart.yScaled
        self.stacked = chart.stacked
        self.percentage = chart.percentage

        updateDataWithoutInterval()
        if let aabb = calculateAABB(for: columns) {
            let length = Double(aabb.maxDate - aabb.minDate)
            self.interval = Interval(from: aabb.minDate + Column.Date(length * from),
                                     to: aabb.minDate + Column.Date(length * to))
                
            self.fullInterval = Interval(from: aabb.minDate, to: aabb.maxDate)
            
            updateDataWithInterval()
        } else {
            assertionFailure("Can't make AABB for polygon lines...")
        }
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
        update()
        updateListeners.forEach { $0.value?.chartVisibleIsChanged(self) }
        
        return true
    }

    public func updateInterval(_ interval: Interval) {
        self.interval = interval
        update()
        updateListeners.forEach { $0.value?.chartIntervalIsChanged(self) }
    }
    
    private func updateDataWithoutInterval() {
        for column in columns {
            column.update(pairs: column.values.map { ColumnViewModel.Pair(from: AABB.Value($0), to: AABB.Value($0)) })
        }
        
        visibleAABB = calculateAABB(for: visibleColumns)
    }
    private func updateDataWithInterval() {
        visibleInIntervalAABB = calculateAABBInInterval(for: visibleColumns, from: interval.from, to: interval.to)
    }
    
    private func update() {
        updateDataWithoutInterval()
        updateDataWithInterval()
    }

    private func calculateAABB(for columns: [ColumnViewModel]) -> AABB? {
        let aabbs = columns.map { $0.aabb }
        let minDate = aabbs.map { $0.minDate }.min()
        let maxDate = aabbs.map { $0.maxDate }.max()
        let minValue = aabbs.map { $0.minValue }.min()
        let maxValue = aabbs.map { $0.maxValue }.max()

        if let minDate = minDate, let maxDate = maxDate,
            let minValue = minValue, let maxValue = maxValue
        {
            return AABB(id: nil, minDate: minDate, maxDate: maxDate, minValue: minValue, maxValue: maxValue, childs: aabbs)
        }

        return nil
    }

    private func calculateAABBInInterval(for columns: [ColumnViewModel], from: Column.Date, to: Column.Date) -> AABB? {
        let aabbs = columns.compactMap { $0.calculateAABBInInterval(from: from, to: to) }

        let minValue = aabbs.map { $0.minValue }.min()
        let maxValue = aabbs.map { $0.maxValue }.max()

        if let minValue = minValue, let maxValue = maxValue
        {
            return AABB(id: nil, minDate: from, maxDate: to, minValue: minValue, maxValue: maxValue, childs: aabbs)
        }

        return nil
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
