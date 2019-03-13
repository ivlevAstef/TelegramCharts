//
//  ChartsViewModel.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

public protocol ChartsUpdateListener: class
{
    func chartsVisibleIsChanged(_ viewModel: ChartsViewModel)
    func chartsIntervalIsChanged(_ viewModel: ChartsViewModel)
}

public class ChartsViewModel
{
    public struct Interval
    {
        let from: Chart.Date
        let to: Chart.Date
    }

    public private(set) var charts: [ChartViewModel]
    public var visibleCharts: [ChartViewModel] {
        return charts.filter { $0.isVisible }
    }

    public private(set) var interval: Interval = Interval(from: 0, to: 0)

    internal private(set) lazy var aabb: Chart.AABB? = {
        return calculateAABB(for: charts)
    }()
    internal var visibleaabb: Chart.AABB? {
        return calculateAABB(for: visibleCharts)
    }
    internal var visibleInIntervalAABB: Chart.AABB? {
        return calculateAABBInInterval(for: visibleCharts, from: interval.from, to: interval.to)
    }

    private var updateListeners: [WeakRef<ChartsUpdateListener>] = []

    public init(charts: [Chart]) {
        self.charts = charts.map { chart in
            let points = chart.points.map { ChartViewModel.Point(date: $0.date, value: $0.value) }
            return ChartViewModel(name: chart.name, points: points, color: UIColor(hex: chart.color))
        }

        if let aabb = self.aabb {
            self.interval = Interval(from: aabb.minDate, to: aabb.maxDate)
        }
    }

    public func registerUpdateListener(_ listener: ChartsUpdateListener)
    {
        if !updateListeners.contains(where: { $0.value === listener }) {
            updateListeners.append(WeakRef(listener))
        }

        updateListeners.removeAll(where: { $0.value == nil })
    }

    public func unregisterUpdateListener(_ listener: ChartsUpdateListener)
    {
        updateListeners.removeAll(where: { $0.value === listener })
        updateListeners.removeAll(where: { $0.value == nil })
    }

    public func toogleChart(_ chart: ChartViewModel) {
        assert(charts.contains(where: { $0 === chart }), "Doen't found chart in data")
        chart.isVisible.toggle()
        updateListeners.forEach { $0.value?.chartsVisibleIsChanged(self) }
    }

    public func enableChart(_ chart: ChartViewModel) {
        assert(charts.contains(where: { $0 === chart }), "Doen't found chart in data")
        chart.isVisible = true
        updateListeners.forEach { $0.value?.chartsVisibleIsChanged(self) }
    }

    public func disableChart(_ chart: ChartViewModel) {
        assert(charts.contains(where: { $0 === chart }), "Doen't found chart in data")
        chart.isVisible = false
        updateListeners.forEach { $0.value?.chartsVisibleIsChanged(self) }
    }

    public func updateInterval(_ interval: Interval) {
        self.interval = interval
        updateListeners.forEach { $0.value?.chartsIntervalIsChanged(self) }
    }

    private func calculateAABB(for charts: [ChartViewModel]) -> Chart.AABB? {
        let minDate = charts.map { $0.aabb.minDate }.min()
        let maxDate = charts.map { $0.aabb.maxDate }.max()
        let minValue = charts.map { $0.aabb.minValue }.min()
        let maxValue = charts.map { $0.aabb.maxValue }.max()

        if let minDate = minDate, let maxDate = maxDate,
            let minValue = minValue, let maxValue = maxValue
        {
            return Chart.AABB(minDate: minDate, maxDate: maxDate, minValue: minValue, maxValue: maxValue)
        }

        return nil
    }

    private func calculateAABBInInterval(for charts: [ChartViewModel], from: Chart.Date, to: Chart.Date) -> Chart.AABB? {
        let aabbs = charts.compactMap { $0.calculateAABBInInterval(from: from, to: to) }

        let minValue = aabbs.map { $0.minValue }.min()
        let maxValue = aabbs.map { $0.maxValue }.max()

        if let minValue = minValue, let maxValue = maxValue
        {
            return Chart.AABB(minDate: from, maxDate: to, minValue: minValue, maxValue: maxValue)
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
