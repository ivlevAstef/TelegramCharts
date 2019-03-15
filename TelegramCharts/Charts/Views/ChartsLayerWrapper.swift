//
//  ChartsLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 15/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

internal final class ChartsLayerWrapper
{
    internal var visibleAABB: Chart.AABB {
        return chartsViewModel?.visibleaabb?.copyWithPadding(date: 0, value: 0.1) ?? Chart.AABB.empty
    }
    
    private var chartsViewModel: ChartsViewModel? = nil
    private var chartLayers: [ChartLayerWrapper] = []
    private weak var parentLayer: CALayer?
    
    internal init() {
    }
    
    internal func setParentLayer(_ layer: CALayer) {
        parentLayer = layer
        
        chartLayers.forEach { $0.layer.removeFromSuperlayer() }
        for chartLayer in chartLayers {
            chartLayer.layer.frame = layer.bounds
            layer.addSublayer(chartLayer.layer)
        }
    }
    
    internal func setCharts(_ charts: ChartsViewModel) {
        chartsViewModel = charts
        
        chartLayers.forEach { $0.layer.removeFromSuperlayer() }
        chartLayers.removeAll()
        for chart in charts.charts {
            let chartLayer = ChartLayerWrapper(chartViewModel: chart)
            chartLayers.append(chartLayer)
        }
        
        if let layer = parentLayer {
            setParentLayer(layer)
        }
    }
    
    internal func updateCharts(aabb: Chart.AABB?, animated: Bool) {
        let aabb = aabb ?? Chart.AABB.empty
        for chartLayer in chartLayers {
            chartLayer.update(aabb: aabb, animated: animated)
        }
    }
}
