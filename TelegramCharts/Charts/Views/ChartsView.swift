//
//  ChartsView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 13/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

public class ChartsView: UIView
{
    private var chartsViewModel: ChartsViewModel? = nil
    private var chartsLayerWrapper: ChartsLayerWrapper = ChartsLayerWrapper()
    
    private var visibleAABB: Chart.AABB? {
        return chartsViewModel?.visibleInIntervalAABB?.copyWithPadding(date: 0, value: 0.1)
    }

    public init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = true
        
        chartsLayerWrapper.setParentLayer(layer)
    }

    public func setCharts(_ charts: ChartsViewModel) {
        chartsViewModel = charts
        charts.registerUpdateListener(self)
        
        chartsLayerWrapper.setCharts(charts)
        chartsLayerWrapper.updateCharts(aabb: visibleAABB, animated: false)
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension ChartsView: ChartsUpdateListener
{
    public func chartsVisibleIsChanged(_ viewModel: ChartsViewModel) {
        chartsLayerWrapper.updateCharts(aabb: visibleAABB, animated: true)
    }

    public func chartsIntervalIsChanged(_ viewModel: ChartsViewModel) {
        chartsLayerWrapper.updateCharts(aabb: visibleAABB, animated: false)
    }
}
