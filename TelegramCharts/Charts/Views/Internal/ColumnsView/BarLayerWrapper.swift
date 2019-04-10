//
//  BarLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 10/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//


import UIKit

internal final class BarLayerWrapper: ColumnViewLayerWrapper
{
    private var pathLayer: CAShapeLayer?
    
    internal func fillLayer(_ layer: CAShapeLayer, ui: ColumnUIModel) {
        layer.lineWidth = 0
        layer.lineCap = .butt
        layer.lineJoin = .miter
        layer.strokeColor = nil
        layer.fillColor = ui.color.cgColor
        layer.opacity = 1.0
    }
    
    internal override func update(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        let oldKeys = Set(layer.animationKeys() ?? [])
        
        let interval = calculateInterval(for: [ui, oldUI, prevOldUI].compactMap { $0 })
        let t: CGFloat = CGFloat((CACurrentMediaTime() - oldTime) / oldDuration)
        
        prevOldUI = t < 1 ? prevOldUI : nil // optimize
        
        let prevOldPoints = prevOldUI.flatMap { calculatePoints(ui: $0, interval: interval) }
        let oldPoints = oldUI.flatMap { calculatePoints(ui: $0, interval: interval) }
        let newPoints = calculatePoints(ui: ui, interval: interval)
        let newPath = makePath(by: newPoints).cgPath
        
        let oldPath: CGPath?
        if let fromPoints = prevOldPoints, let toPoints = oldPoints {
            let interpolatePoints = interpolate(fromPoints: fromPoints, toPoints: toPoints, t: t)
            oldPath = makePath(by: interpolatePoints).cgPath
        } else if let toPoints = oldPoints {
            oldPath = makePath(by: toPoints).cgPath
        } else {
            oldPath = nil
        }
        oldDuration = (animated && nil != oldPath) ? duration : 0.0
        oldTime = CACurrentMediaTime()
        prevOldUI = oldUI
        oldUI = ui
        
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
        
        super.update(ui: ui, animated: animated, duration: duration)
    }
    
    private func calculatePoints(ui: ColumnUIModel, interval: ChartViewModel.Interval) -> [CGPoint] {
        let datas = ui.splitTranslate(to: layer.bounds, in: interval)
        let step = (datas[1].from.x - datas[0].from.x) / 2
        
        var result = [CGPoint](repeating: CGPoint.zero, count: 4 * datas.count)
        for i in 0..<datas.count {
            result[2 * i] = CGPoint(x: datas[i].from.x - step, y: datas[i].from.y)
            result[2 * i + 1] = CGPoint(x: datas[i].from.x + step, y: datas[i].from.y)
        }
        for i in 0..<datas.count {
            result[result.count - 2 * i - 1] = CGPoint(x: datas[i].to.x - step, y: datas[i].to.y)
            result[result.count - 2 * i - 2] = CGPoint(x: datas[i].to.x + step, y: datas[i].to.y)
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

