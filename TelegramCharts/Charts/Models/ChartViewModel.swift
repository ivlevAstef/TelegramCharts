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

    public private(set) var columns: [ColumnViewModel]
    public var visibleColumns: [ColumnViewModel] {
        return columns.filter { $0.isVisible }
    }

    public private(set) var interval: Interval = Interval.empty
    public private(set) var fullInterval: Interval = Interval.empty

    internal private(set) lazy var aabb: AABB? = {
        return calculateAABB(for: columns)
    }()
    internal var visibleaabb: AABB? {
        return calculateAABB(for: visibleColumns)
    }
    internal var visibleInIntervalAABB: AABB? {
        return calculateAABBInInterval(for: visibleColumns, from: interval.from, to: interval.to)
    }

    private var updateListeners: [WeakRef<ChartUpdateListener>] = []

    public init(columns: [Column], from: Double = 0.0, to: Double = 1.0) {
        self.columns = columns.map { column in
            let points = column.points.map { ColumnViewModel.Point(date: $0.date, value: $0.value) }
            return ColumnViewModel(name: column.name, points: points, color: UIColor(hex: column.color))
        }

        if let aabb = self.aabb {
            let length = Double(aabb.maxDate - aabb.minDate)
            self.interval = Interval(from: aabb.minDate + Column.Date(length * from),
                                     to: aabb.minDate + Column.Date(length * to))
                
            self.fullInterval = Interval(from: aabb.minDate, to: aabb.maxDate)
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

    public func toogleVisibleColumn(_ column: ColumnViewModel) {
        assert(columns.contains(where: { $0 === column }), "Doen't found polygon line in data")
        column.isVisible.toggle()
        updateListeners.forEach { $0.value?.chartVisibleIsChanged(self) }
    }

    public func enableColumn(_ column: ColumnViewModel) {
        assert(columns.contains(where: { $0 === column }), "Doen't found polygon line in data")
        column.isVisible = true
        updateListeners.forEach { $0.value?.chartVisibleIsChanged(self) }
    }

    public func disableColumn(_ column: ColumnViewModel) {
        assert(columns.contains(where: { $0 === column }), "Doen't found polygon line in data")
        column.isVisible = false
        updateListeners.forEach { $0.value?.chartVisibleIsChanged(self) }
    }

    public func updateInterval(_ interval: Interval) {
        self.interval = interval
        updateListeners.forEach { $0.value?.chartIntervalIsChanged(self) }
    }

    private func calculateAABB(for columns: [ColumnViewModel]) -> AABB? {
        let minDate = columns.map { $0.aabb.minDate }.min()
        let maxDate = columns.map { $0.aabb.maxDate }.max()
        let minValue = columns.map { $0.aabb.minValue }.min()
        let maxValue = columns.map { $0.aabb.maxValue }.max()

        if let minDate = minDate, let maxDate = maxDate,
            let minValue = minValue, let maxValue = maxValue
        {
            return AABB(minDate: minDate, maxDate: maxDate, minValue: minValue, maxValue: maxValue)
        }

        return nil
    }

    private func calculateAABBInInterval(for columns: [ColumnViewModel], from: Column.Date, to: Column.Date) -> AABB? {
        let aabbs = columns.compactMap { $0.calculateAABBInInterval(from: from, to: to) }

        let minValue = aabbs.map { $0.minValue }.min()
        let maxValue = aabbs.map { $0.maxValue }.max()

        if let minValue = minValue, let maxValue = maxValue
        {
            return AABB(minDate: from, maxDate: to, minValue: minValue, maxValue: maxValue)
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
