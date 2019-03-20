//
//  ChartWithIntervalView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

public class ChartWithIntervalView: UIView
{
    private static let defaultIntervalViewHeight: CGFloat = 40.0

    private let chartView: ChartView = ChartView()
    private let intervalView: IntervalView = IntervalView()

    public init(intervalViewHeight: CGFloat? = nil) {
        super.init(frame: .zero)

        configureSubviews()
        makeConstraints(intervalViewHeight: intervalViewHeight ?? ChartWithIntervalView.defaultIntervalViewHeight)
    }

    public func setStyle(_ style: ChartStyle) {
        intervalView.setStyle(style)
        chartView.setStyle(style)
    }

    public func setChart(_ chart: ChartViewModel) {
        chartView.setChart(chart)
        intervalView.setChart(chart)
    }

    public static func calculateHeight() -> CGFloat {
        return UIScreen.main.bounds.width
    }

    private func configureSubviews() {
        chartView.translatesAutoresizingMaskIntoConstraints = false
        intervalView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartView)
        addSubview(intervalView)
    }

    private func makeConstraints(intervalViewHeight: CGFloat) {
        self.chartView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.chartView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.chartView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true

        self.chartView.bottomAnchor.constraint(equalTo: self.intervalView.topAnchor).isActive = true

        self.intervalView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.intervalView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.intervalView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.intervalView.heightAnchor.constraint(equalToConstant: intervalViewHeight).isActive = true
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configureSubviews()
        makeConstraints(intervalViewHeight: ChartWithIntervalView.defaultIntervalViewHeight)
    }
}
