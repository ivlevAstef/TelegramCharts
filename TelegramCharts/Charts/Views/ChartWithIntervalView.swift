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

    private let noData: UILabel = UILabel(frame: .zero)
    private let chartView: ChartView = ChartView()
    private let intervalView: IntervalView = IntervalView()

    public init(intervalViewHeight: CGFloat? = nil) {
        super.init(frame: .zero)

        initialize(intervalViewHeight: intervalViewHeight)
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

    public static func calculateHeight() -> CGFloat {
        return UIScreen.main.bounds.width
    }

    private func initialize(intervalViewHeight: CGFloat?)
    {
        configureSubviews()
        makeConstraints(intervalViewHeight: intervalViewHeight ?? ChartWithIntervalView.defaultIntervalViewHeight)
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

    private func makeConstraints(intervalViewHeight: CGFloat) {
        self.chartView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.chartView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.chartView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true

        self.chartView.bottomAnchor.constraint(equalTo: self.intervalView.topAnchor).isActive = true

        self.intervalView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.intervalView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.intervalView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.intervalView.heightAnchor.constraint(equalToConstant: intervalViewHeight).isActive = true

        self.noData.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.noData.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    private func configureNoDataLabel(viewModel: ChartViewModel, animated: Bool) {
        let hasVisiblePolyline = viewModel.polygonLines.contains(where: { $0.isVisible })
        
        UIView.animateIf(animated, duration: Configs.visibleChangeDuration, animations: { [weak self] in
            self?.noData.alpha = hasVisiblePolyline ? 0.0 : 1.0
        })
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initialize(intervalViewHeight: nil)
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
