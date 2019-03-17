//
//  ChartViewModel.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
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
        let from: PolygonLine.Date
        let to: PolygonLine.Date
    }

    public private(set) var polygonLines: [PolygonLineViewModel]
    public var visiblePolygonLines: [PolygonLineViewModel] {
        return polygonLines.filter { $0.isVisible }
    }

    public private(set) var interval: Interval = Interval(from: 0, to: 0)

    internal private(set) lazy var aabb: AABB? = {
        return calculateAABB(for: polygonLines)
    }()
    internal var visibleaabb: AABB? {
        return calculateAABB(for: visiblePolygonLines)
    }
    internal var visibleInIntervalAABB: AABB? {
        return calculateAABBInInterval(for: visiblePolygonLines, from: interval.from, to: interval.to)
    }

    private var updateListeners: [WeakRef<ChartUpdateListener>] = []

    public init(polygonLines: [PolygonLine]) {
        self.polygonLines = polygonLines.map { polygonLine in
            let points = polygonLine.points.map { PolygonLineViewModel.Point(date: $0.date, value: $0.value) }
            return PolygonLineViewModel(name: polygonLine.name, points: points, color: UIColor(hex: polygonLine.color))
        }

        if let aabb = self.aabb {
            self.interval = Interval(from: aabb.minDate, to: aabb.maxDate)
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

    public func toogleVisiblePolygonLine(_ polygonLine: PolygonLineViewModel) {
        assert(polygonLines.contains(where: { $0 === polygonLine }), "Doen't found polygon line in data")
        polygonLine.isVisible.toggle()
        updateListeners.forEach { $0.value?.chartVisibleIsChanged(self) }
    }

    public func enablePolygonLine(_ polygonLine: PolygonLineViewModel) {
        assert(polygonLines.contains(where: { $0 === polygonLine }), "Doen't found polygon line in data")
        polygonLine.isVisible = true
        updateListeners.forEach { $0.value?.chartVisibleIsChanged(self) }
    }

    public func disablePolygonLine(_ polygonLine: PolygonLineViewModel) {
        assert(polygonLines.contains(where: { $0 === polygonLine }), "Doen't found polygon line in data")
        polygonLine.isVisible = false
        updateListeners.forEach { $0.value?.chartVisibleIsChanged(self) }
    }

    public func updateInterval(_ interval: Interval) {
        self.interval = interval
        updateListeners.forEach { $0.value?.chartIntervalIsChanged(self) }
    }

    private func calculateAABB(for polygonLines: [PolygonLineViewModel]) -> AABB? {
        let minDate = polygonLines.map { $0.aabb.minDate }.min()
        let maxDate = polygonLines.map { $0.aabb.maxDate }.max()
        let minValue = polygonLines.map { $0.aabb.minValue }.min()
        let maxValue = polygonLines.map { $0.aabb.maxValue }.max()

        if let minDate = minDate, let maxDate = maxDate,
            let minValue = minValue, let maxValue = maxValue
        {
            return AABB(minDate: minDate, maxDate: maxDate, minValue: minValue, maxValue: maxValue)
        }

        return nil
    }

    private func calculateAABBInInterval(for polygonLines: [PolygonLineViewModel], from: PolygonLine.Date, to: PolygonLine.Date) -> AABB? {
        let aabbs = polygonLines.compactMap { $0.calculateAABBInInterval(from: from, to: to) }

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
