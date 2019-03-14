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
    private var chartsVisibleAABB: Chart.AABB? {
        return chartsViewModel?.visibleInIntervalAABB?.copyWithPadding(date: 0, value: 0.1)
    }
    private var chartLayers: [ChartLayerWrapper] = []

    public init() {
        super.init(frame: .zero)

        self.backgroundColor = .clear
        self.clipsToBounds = true
    }

    public func setCharts(_ charts: ChartsViewModel)
    {
        chartsViewModel = charts
        charts.registerUpdateListener(self)

        chartLayers.forEach { $0.layer.removeFromSuperlayer() }
        chartLayers.removeAll()
        for chart in charts.charts {
            let chartLayer = ChartLayerWrapper(chartViewModel: chart)
            chartLayers.append(chartLayer)
            layer.addSublayer(chartLayer.layer)
        }

        updateCharts()
    }

    private func updateCharts()
    {
        guard let aabb = chartsVisibleAABB else {
            return
        }
        
        for chartLayer in chartLayers {
            chartLayer.layer.frame = self.bounds
            chartLayer.update(aabb: aabb, animated: true)
        }
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

extension ChartsView: ChartsUpdateListener
{
    public func chartsVisibleIsChanged(_ viewModel: ChartsViewModel)
    {
        //updateCharts()
    }

    public func chartsIntervalIsChanged(_ viewModel: ChartsViewModel)
    {
        //updateCharts()
    }
}
