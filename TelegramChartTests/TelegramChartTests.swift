//
//  TelegramChartTests.swift
//  TelegramChartTests
//
//  Created by Ивлев Александр on 14/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import XCTest
@testable import TelegramChart

class TelegramChartTests: XCTestCase {

    private var charts: [Chart] = []

    override func setUp() {
        ChartProvider().getCharts { charts in
            self.charts = charts
        }
    }

    func testResizePerformance() {
        let chartView = ChartWithIntervalView(margins: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        let size = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        var rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        chartView.frame = rect
        chartView.setStyle(Style.dayChartStyle)
        chartView.setChart(ChartViewModel(chart: charts[3], from: 0.25, to: 1.0))

        self.measure {
            var sign: CGFloat = -1
            for i in 0..<60 {
                chartView.frame = rect
                if 0 == i % 30 {
                    sign = -sign
                }
                rect.size.width += sign
            }
        }
    }

    func testIntervalPerformance() {
        let chartView = ChartView(margins: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        let size = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        chartView.frame = rect

        let viewModel = ChartViewModel(chart: charts[3], from: 0.25, to: 1.0)
        chartView.setStyle(Style.dayChartStyle)


        chartView.setChart(viewModel)

        let b = viewModel.interval

        self.measure {
            var sign: Int = -1
            for i in 0..<120 {
                if 0 == i % 50 {
                    sign = -sign
                }
                let interval = ChartViewModel.Interval(from: b.from, to: b.to + Chart.Date(sign * i * 100000))
                viewModel.updateInterval(interval)
                chartView.chartIntervalIsChanged(viewModel)
            }
        }
    }

    func testVisiblePerformance() {
        let chartView = ChartView(margins: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        let size = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        chartView.frame = rect

        let viewModel = ChartViewModel(chart: charts[3], from: 0.0, to: 1.0)
        chartView.setStyle(Style.dayChartStyle)


        chartView.setChart(viewModel)

        self.measure {
            var isVisible: Bool = false
            for _ in 0..<120 {
                isVisible = !isVisible
                let isVisibles = viewModel.columns.map { _ in isVisible }

                viewModel.setVisibleColumns(isVisibles: isVisibles)
                chartView.chartVisibleIsChanged(viewModel)
            }
        }
    }

}
