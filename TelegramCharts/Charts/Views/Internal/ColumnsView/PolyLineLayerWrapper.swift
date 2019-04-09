//
//  PolyLineLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 14/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal final class PolyLineLayerWrapper
{
    internal let layer: CALayer = CALayer()
    internal var lineWidth: CGFloat = 1.0
    
    private var pathLayer: CAShapeLayer?
    private let columnViewModel: ColumnViewModel
    
    private var isFirst: Bool = true

    internal init(columnViewModel: ColumnViewModel) {
        self.columnViewModel = columnViewModel
    }
    
    internal func fillLayer(_ layer: CAShapeLayer) {
        layer.lineWidth = lineWidth
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.strokeColor = columnViewModel.color.cgColor
        layer.fillColor = nil
        layer.opacity = 1.0
    }
    
    internal func update(aabb: AABB, animatedPath: Bool, animatedOpacity: Bool, duration: TimeInterval) {
        let oldKeys = Set(layer.animationKeys() ?? [])
        
        let newPath = makePath(aabb: aabb)
        let oldPath = pathLayer?.presentation()?.path ?? pathLayer?.path
        
        pathLayer?.removeFromSuperlayer()
        
        let newLayer = CAShapeLayer()
        newLayer.path = newPath.cgPath
        self.fillLayer(newLayer)
        self.pathLayer = newLayer
        self.layer.addSublayer(newLayer)
        
        let newKeys = Set(layer.animationKeys() ?? [])
        for key in newKeys.subtracting(oldKeys) {
            self.layer.removeAnimation(forKey: key)
        }
        
        if animatedPath && nil != oldPath {
            let animation = CABasicAnimation(keyPath: "path")
            animation.beginTime = CACurrentMediaTime()
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animation.fromValue = oldPath
            animation.toValue = newPath.cgPath
            animation.isRemovedOnCompletion = true
            newLayer.add(animation, forKey: "path")
        }
        
        let newOpacity: Float = columnViewModel.isVisible ? 1.0 : 0.0
        if newOpacity != layer.opacity {
            CATransaction.begin()
            CATransaction.setAnimationDuration(animatedOpacity ? duration: 0.0)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
            layer.opacity = newOpacity
            CATransaction.commit()
        }
    }
    
    private func makePath(aabb: AABB) -> UIBezierPath {
        var uiPoints = columnViewModel.calculateUIPoints(for: layer.bounds, aabb: aabb)
        let path = UIBezierPath()
        
        if uiPoints.isEmpty {
            return path
        }

        var lastPoint = uiPoints.removeFirst()

        path.move(to: lastPoint)
        for point in uiPoints {
            path.addLine(to: point)
            lastPoint = point
        }
        
        return path
    }
}
