//
//  SimpleChartView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 20/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

public class SimpleChartView: UIView
{
    private var chartViewModel: ChartViewModel? = nil
    private var visibleAABB: AABB? {
        return chartViewModel?.visibleInIntervalAABB?.copyWithIntellectualPadding(date: 0, value: 0.1)
    }

    private let polygonLinesView: PolygonLinesView = PolygonLinesView()

    public init() {
        super.init(frame: .zero)

        initialize()
    }

    public func setChart(_ chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel

        polygonLinesView.setPolygonLines(chartViewModel.polygonLines)
        polygonLinesView.setLineWidth(1.0)
        polygonLinesView.update(aabb: visibleAABB, animated: false, duration: 0.0)
    }

    private func initialize() {
        configureSubviews()
        makeConstraints()
    }

    private func configureSubviews() {
        polygonLinesView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(polygonLinesView)
    }

    private func makeConstraints() {
        self.polygonLinesView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.polygonLinesView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.polygonLinesView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.polygonLinesView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initialize()
    }
}
