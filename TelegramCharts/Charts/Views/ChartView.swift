//
//  ChartView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 13/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

public class ChartView: UIView
{
    private var chartViewModel: ChartViewModel? = nil
    private var visibleAABB: AABB? {
        return chartViewModel?.visibleInIntervalAABB?.copyWithPadding(date: 0, value: 0.1)
    }
    
    private var polygonLinesView: PolygonLinesView = PolygonLinesView()

    public init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = true
        
        polygonLinesView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(polygonLinesView)
        makeConstaints()
    }

    public func setChart(_ chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel
        chartViewModel.registerUpdateListener(self)
        
        polygonLinesView.setPolygonLines(chartViewModel.polygonLines)
        polygonLinesView.update(aabb: visibleAABB, animated: false)
    }
    
    private func makeConstaints() {
        self.polygonLinesView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.polygonLinesView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.polygonLinesView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.polygonLinesView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension ChartView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        polygonLinesView.update(aabb: visibleAABB, animated: true)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        polygonLinesView.update(aabb: visibleAABB, animated: false)
    }
}
