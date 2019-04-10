//
//  ColumnViewLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 10/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class ColumnViewLayerWrapper
{
    internal let layer: CALayer = CALayer()
    internal var minX: CGFloat = 0
    internal var maxX: CGFloat = 0
    
    internal var prevOldUI: ColumnUIModel?
    internal var oldUI: ColumnUIModel?
    internal var oldTime: CFTimeInterval = CACurrentMediaTime()
    internal var oldDuration: TimeInterval = 0.0
    
    private var oldIsVisible: Bool = true
    
    internal init() {
    }
    
    internal func update(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        if oldIsVisible != ui.isVisible && ui.isOpacity {
            CATransaction.begin()
            CATransaction.setAnimationDuration(animated ? duration : 0.0)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
            
            layer.opacity = ui.isVisible ? 1.0 : 0.0
            CATransaction.commit()
        }
        oldIsVisible = ui.isVisible
    }
    
    internal func calculateInterval(for uis: [ColumnUIModel]) -> ChartViewModel.Interval {
        var minDate = Chart.Date.max
        var maxDate = Chart.Date.min
        
        for ui in uis {
            let interval = ui.interval(by: layer.bounds, minX: minX, maxX: maxX)
            minDate = min(minDate, interval.from)
            maxDate = max(maxDate, interval.to)
        }
        
        return ChartViewModel.Interval(from: minDate, to: maxDate)
    }
    
    
    internal func interpolate(fromPoints: [CGPoint], toPoints: [CGPoint], t: CGFloat) -> [CGPoint] {
        let length = min(fromPoints.count, toPoints.count)
        var result = [CGPoint](repeating: CGPoint.zero, count: length)
        for i in 0..<length {
            result[i].x = toPoints[i].x * t + fromPoints[i].x * (1.0 - t)
            result[i].y = toPoints[i].y * t + fromPoints[i].y * (1.0 - t)
        }
        return result
    }
}

