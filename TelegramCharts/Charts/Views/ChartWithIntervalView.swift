//
//  ChartWithIntervalView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

public class ChartWithIntervalView: UIView
{
    override public var frame: CGRect {
        didSet { updateFrame() }
    }
    
    public var hintClickHandler: ((Chart.Date) -> Void)?
    
    private static let defaultIntervalViewHeight: CGFloat = 40.0

    private let chartView: ChartView
    private let intervalView: IntervalView
    private let intervalViewHeight: CGFloat

    public init(margins: UIEdgeInsets, intervalViewHeight: CGFloat? = nil) {
        self.intervalViewHeight = intervalViewHeight ?? ChartWithIntervalView.defaultIntervalViewHeight
        self.chartView = ChartView(margins: margins)
        self.intervalView = IntervalView(margins: margins)
        super.init(frame: .zero)

        configureSubviews()
    }

    public func setStyle(_ style: ChartStyle) {
        intervalView.setStyle(style)
        chartView.setStyle(style)
    }

    public func setChart(_ chart: ChartViewModel) {
        chartView.setChart(chart)
        intervalView.setChart(chart)
    }

    private func configureSubviews() {
        chartView.translatesAutoresizingMaskIntoConstraints = true
        intervalView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(chartView)
        addSubview(intervalView)
        
        chartView.hintClickHandler = { [weak self] date in
            self?.hintClickHandler?(date)
        }
    }
    
    private func updateFrame() {
        self.chartView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - intervalViewHeight)
        self.intervalView.frame = CGRect(x: 0, y: bounds.height - intervalViewHeight, width: bounds.width, height: intervalViewHeight)
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
