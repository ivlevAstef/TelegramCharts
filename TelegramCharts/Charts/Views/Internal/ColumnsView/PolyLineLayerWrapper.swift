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
    
    private var oldFromPoints: [CGPoint]?
    private var oldToPoints: [CGPoint]?
    private var oldTime: CFTimeInterval = CACurrentMediaTime()
    private var oldDuration: TimeInterval = 0.0
    
    private var pathLayer: CAShapeLayer?

    internal init() {
    }
    
    internal func fillLayer(_ layer: CAShapeLayer, ui: ColumnUIModel) {
        layer.lineWidth = CGFloat(ui.size)
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.strokeColor = ui.color.cgColor
        layer.fillColor = nil
        layer.opacity = 1.0
    }
    
    internal func update(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        let oldKeys = Set(layer.animationKeys() ?? [])
        
        let newPoints = calculatePoints(ui: ui)
        let newPath = makePath(by: newPoints).cgPath
        
        let t: CGFloat = CGFloat((CACurrentMediaTime() - oldTime) / oldDuration)
        let oldPath: CGPath?
        if let fromPoints = oldFromPoints, let toPoints = oldToPoints, t < 1 {
            let interpolatePoints = interpolate(fromPoints: fromPoints, toPoints: toPoints, t: t)
            oldFromPoints = interpolatePoints
            oldToPoints = newPoints
            
            oldPath = makePath(by: interpolatePoints).cgPath
        } else {
            oldFromPoints = oldToPoints
            oldToPoints = newPoints
            
            oldPath = pathLayer?.path
        }
        oldDuration = (animated && nil != oldPath) ? duration : 0.0
        oldTime = CACurrentMediaTime()
        
        pathLayer?.removeFromSuperlayer()
        
        let newLayer = CAShapeLayer()
        newLayer.path = newPath
        self.fillLayer(newLayer, ui: ui)
        self.pathLayer = newLayer
        self.layer.addSublayer(newLayer)
        
        let newKeys = Set(layer.animationKeys() ?? [])
        for key in newKeys.subtracting(oldKeys) {
            self.layer.removeAnimation(forKey: key)
        }
        
        if animated && nil != oldPath {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animation.fromValue = oldPath
            animation.toValue = newPath
            animation.isRemovedOnCompletion = true
            newLayer.add(animation, forKey: "path")
        }
        
        let newOpacity: Float = ui.isVisible ? 1.0 : 0.0
        if newOpacity != layer.opacity {
            CATransaction.begin()
            CATransaction.setAnimationDuration(animated ? duration : 0.0)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
            layer.opacity = newOpacity
            CATransaction.commit()
        }
    }
    
    private func calculatePoints(ui: ColumnUIModel) -> [CGPoint] {
        let datas = ui.translate(to: layer.bounds)
        var result = [CGPoint](repeating: CGPoint.zero, count: datas.count)
        for i in 0..<datas.count {
            result[i] = datas[i].to
        }
        return result
    }
    
    private func interpolate(fromPoints: [CGPoint], toPoints: [CGPoint], t: CGFloat) -> [CGPoint] {
        let length = min(fromPoints.count, toPoints.count)
        var result = [CGPoint](repeating: CGPoint.zero, count: length)
        for i in 0..<length {
            result[i].x = toPoints[i].x * t + fromPoints[i].x * (1.0 - t)
            result[i].y = toPoints[i].y * t + fromPoints[i].y * (1.0 - t)
        }
        return result
    }
    
    private func makePath(by points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        
        guard let firstPoint = points.first else {
            return path
        }

        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}
