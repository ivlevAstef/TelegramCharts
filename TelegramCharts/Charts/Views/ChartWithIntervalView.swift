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
    
    private static let defaultIntervalViewHeight: CGFloat = 40.0

    private let noData: UILabel = UILabel(frame: .zero)
    private let chartView: ChartView = ChartView()
    private let intervalView: IntervalView = IntervalView()
    private let intervalViewHeight: CGFloat

    public init(intervalViewHeight: CGFloat? = nil) {
        self.intervalViewHeight = intervalViewHeight ?? ChartWithIntervalView.defaultIntervalViewHeight
        super.init(frame: .zero)

        configureSubviews()
    }

    public func setStyle(_ style: ChartStyle) {
        noData.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        noData.textColor = style.textColor

        intervalView.setStyle(style)
        chartView.setStyle(style)
    }

    public func setChart(_ chart: ChartViewModel) {
        chart.registerUpdateListener(self)

        chartView.setChart(chart)
        intervalView.setChart(chart)
        
        configureNoDataLabel(viewModel: chart, animated: false)
    }

    private func configureSubviews() {
        chartView.translatesAutoresizingMaskIntoConstraints = false
        intervalView.translatesAutoresizingMaskIntoConstraints = false
        noData.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartView)
        addSubview(intervalView)
        addSubview(noData)

        noData.text = "Select at least one column"
        noData.alpha = 0.0
    }
    
    private func updateFrame() {
        self.chartView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - intervalViewHeight)
        self.intervalView.frame = CGRect(x: 0, y: bounds.height - intervalViewHeight, width: bounds.width, height: intervalViewHeight)
        self.noData.center = center
    }
    
    private func configureNoDataLabel(viewModel: ChartViewModel, animated: Bool) {
        let hasVisiblePolyline = viewModel.columns.contains(where: { $0.isVisible })
        
        UIView.animateIf(animated, duration: Configs.visibleChangeDuration, animations: { [weak self] in
            self?.noData.alpha = hasVisiblePolyline ? 0.0 : 1.0
        })
    }

    internal required init?(coder aDecoder: NSCoder) {
        self.intervalViewHeight = ChartWithIntervalView.defaultIntervalViewHeight
        super.init(coder: aDecoder)

        configureSubviews()
    }
}

extension ChartWithIntervalView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        configureNoDataLabel(viewModel: viewModel, animated: true)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
    }
}
