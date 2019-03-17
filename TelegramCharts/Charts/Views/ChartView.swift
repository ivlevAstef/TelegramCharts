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
    private var chartLayerWrapper: ChartLayerWrapper = ChartLayerWrapper()
    
    private var visibleAABB: AABB? {
        return chartViewModel?.visibleInIntervalAABB?.copyWithPadding(date: 0, value: 0.1)
    }

    public init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = true
        
        chartLayerWrapper.setParentLayer(layer)
    }

    public func setChart(_ chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel
        chartViewModel.registerUpdateListener(self)
        
        chartLayerWrapper.setChart(chartViewModel)
        chartLayerWrapper.update(aabb: visibleAABB, animated: false)
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension ChartView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        chartLayerWrapper.update(aabb: visibleAABB, animated: true)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        chartLayerWrapper.update(aabb: visibleAABB, animated: false)
    }
}
