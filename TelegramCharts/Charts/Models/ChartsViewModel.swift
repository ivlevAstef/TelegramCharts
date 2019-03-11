//
//  ChartsViewModel.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

public class ChartsViewModel
{
    private static let zeroDate = Date(timeIntervalSince1970: 0)
    public struct Interval
    {
        let from: Date
        let to: Date
    }

    public private(set) var charts: [ChartViewModel]
    public private(set) var interval: Interval = Interval(from: ChartsViewModel.zeroDate, to: ChartsViewModel.zeroDate)
    public var fullInterval: Interval? {
        let dates = charts.flatMap { $0.points.compactMap { $0.date } }
        if let min = dates.min(), let max = dates.max() {
            return Interval(from: min, to: max)
        }
        return nil
    }

    internal var updateCallback: ((_ viewModel: ChartsViewModel) -> Void)?

    public init(charts: [Chart]) {
        self.charts = charts.map { chart in
            let points = chart.points.map { ChartViewModel.Point(date: $0.date, value: $0.value) }
            return ChartViewModel(name: chart.name, points: points, color: UIColor(hex: chart.color))
        }
    }

    public func enableChart(_ chart: ChartViewModel) {
        chart.isEnabled = true
        dataChanged()
        assert(charts.contains(where: { $0 === chart }), "Doen't found chart in data")
    }

    public func disableChart(_ chart: ChartViewModel) {
        chart.isEnabled = false
        dataChanged()
        assert(charts.contains(where: { $0 === chart }), "Doen't found chart in data")
    }

    public func updateInterval(_ interval: Interval) {
        self.interval = interval
        self.dataChanged()
    }

    private func dataChanged() {
        updateCallback?(self)
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
