//
//  ChartLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 14/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

internal final class ChartLayerWrapper
{
    internal let layer: CAShapeLayer = CAShapeLayer()
    private let chartViewModel: ChartViewModel

    internal init(chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel
        
        layer.lineWidth = 1.0
        layer.lineCap = .butt
        layer.strokeColor = chartViewModel.color.cgColor
        layer.fillColor = nil
    }
    
    internal func update(aabb: Chart.AABB, animated: Bool) {
        let newPath = makePath(aabb: aabb)
        
        if animated && nil != layer.path {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = 5.25
            animation.toValue = newPath.cgPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animation.fillMode = .forwards
            layer.add(animation, forKey: "path")
        } else {
            layer.path = newPath.cgPath
        }
        
        let animation = CABasicAnimation(keyPath: "strokeColor")
        animation.duration = animated ? 5.25 : 0.01
        animation.toValue = (chartViewModel.isVisible ? chartViewModel.color : UIColor.clear).cgColor
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(animation, forKey: "strokeColor")
    }
    
    private func makePath(aabb: Chart.AABB) -> UIBezierPath
    {
        var uiPoints = chartViewModel.calculateUIPoints(for: layer.bounds, aabb: aabb)
        let path = UIBezierPath()
        
        if uiPoints.isEmpty {
            return path
        }
        
        path.move(to: uiPoints.removeFirst())
        for point in uiPoints {
            path.addLine(to: point)
        }
        
        return path
    }
}
