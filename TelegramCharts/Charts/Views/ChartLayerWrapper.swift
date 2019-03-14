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

        layer.removeAllAnimations()
        
        if animated && nil != layer.path {
            let animation = CASaveStateAnimation(keyPath: "path")
            animation.duration = 0.25
            animation.toValue = newPath.cgPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animation.fillMode = .both
            animation.startAnimation(on: layer)
        } else {
            layer.path = newPath.cgPath
        }
        
        let newOpacity: Float = chartViewModel.isVisible ? 1.0 : 0.0
        if animated {
            let animation = CASaveStateAnimation(keyPath: "opacity")
            animation.duration = 0.25
            animation.toValue = newOpacity
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animation.fillMode = .both
            animation.startAnimation(on: layer)
        } else {
            layer.opacity = newOpacity
        }
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

private class CASaveStateAnimation: CABasicAnimation, CAAnimationDelegate {
    private weak var parentLayer: CALayer?
    private var selfRetain: CASaveStateAnimation?
    
    internal func startAnimation(on layer: CALayer) {
        parentLayer = layer
        
        delegate = self
        layer.add(self, forKey: nil)
    }
    
    @objc
    func animationDidStart(_ anim: CAAnimation) {
        selfRetain = self
    }
    
    @objc
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        selfRetain = nil
        parentLayer?.setValue(toValue, forKey: keyPath!)
    }
}
