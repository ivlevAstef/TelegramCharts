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

    internal private(set) var color: UIColor?
    internal private(set) var size: Double = 1.0

    private var fromPointsData: [ColumnUIModel.UIData] = []
    private var toPointsData: [ColumnUIModel.UIData] = []
    private var fromInterval: ChartViewModel.Interval?
    private var toInterval: ChartViewModel.Interval?
    private var oldTime: CFTimeInterval = CACurrentMediaTime()
    private var oldDuration: TimeInterval = 0.0

    private var pathLayer: CAShapeLayer
    private var oldIsVisible: Bool = true

    private var saveOldPath: CGPath?
    private var saveNewPath: CGPath?
    
    internal init() {
        pathLayer = CAShapeLayer()
        layer.addSublayer(pathLayer)
    }

    internal func fillLayer(_ layer: CAShapeLayer) {
        fatalError("override")
    }

    internal func fillContext(_ context: CGContext) {
        fatalError("override")
    }

    internal func makePath(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> UIBezierPath
    {
        fatalError("override")
    }

    internal func update(ui: ColumnUIModel, animated: Bool, duration: TimeInterval, t: CGFloat) {
        self.color = ui.color
        self.size = ui.size
        let interval = updateInterval(ui: ui, t: t)
        updatePoints(ui: ui, t: t, interval: interval, animated: animated, duration: duration)
    }

    internal func confirm(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        confirmOpacity(ui: ui, animated: animated, duration: duration)
        confirmPoints(ui: ui, animated: animated, duration: duration)
    }

    internal func drawCurrentState(to context: CGContext) {
        if let path = saveNewPath {
            context.saveGState()
            context.addPath(path)
            fillContext(context)
            context.restoreGState()
        }
    }

    private func updateInterval(ui: ColumnUIModel, t: CGFloat) -> ChartViewModel.Interval {
        let newInterval = ui.interval(by: layer.bounds, minX: minX, maxX: maxX)

        if let fromInterval = fromInterval, let toInterval = toInterval, t < 1 {
            let interpolateInterval = interpolate(from: fromInterval, to: toInterval, t: t)
            self.fromInterval = interpolateInterval
            self.toInterval = newInterval

            return expand(from: interpolateInterval, to: newInterval)
        } else if let toInterval = toInterval {
            self.fromInterval = toInterval
            self.toInterval = newInterval

            return expand(from: toInterval, to: newInterval)
        }

        fromInterval = nil
        toInterval = newInterval

        return newInterval
    }

    private func updatePoints(ui: ColumnUIModel, t: CGFloat, interval: ChartViewModel.Interval,
                              animated: Bool, duration: TimeInterval)
    {
        let newPointsData = ui.translate(to: layer.bounds)

        if fromPointsData.count > 0 && toPointsData.count > 0 && t < 1 {
            let interpolatePoints = interpolate(from: fromPointsData, to: toPointsData, t: t)
            saveOldPath = makePath(ui: ui, points: interpolatePoints, interval: interval).cgPath
            fromPointsData = interpolatePoints
        } else if toPointsData.count > 0 {
            saveOldPath = makePath(ui: ui, points: toPointsData, interval: interval).cgPath
            fromPointsData = toPointsData
        } else {
            saveOldPath = nil
            fromPointsData = []
        }
        toPointsData = newPointsData
        saveNewPath = makePath(ui: ui, points: newPointsData, interval: interval).cgPath

        fillLayer(pathLayer)
        pathLayer.removeAllAnimations()
    }

    private func confirmPoints(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        pathLayer.path = saveNewPath

        if animated && nil != saveOldPath && nil != saveNewPath {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animation.fromValue = saveOldPath
            animation.toValue = saveNewPath
            animation.isRemovedOnCompletion = true
            pathLayer.add(animation, forKey: "path")
        }
    }

    private func confirmOpacity(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        if oldIsVisible != ui.isVisible && ui.isOpacity {
            CATransaction.begin()
            CATransaction.setAnimationDuration(animated ? duration : 0.0)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))

            layer.opacity = ui.isVisible ? 1.0 : 0.0
            CATransaction.commit()
        }
        oldIsVisible = ui.isVisible
    }
    
    private func calculateInterval(for uis: [ColumnUIModel]) -> ChartViewModel.Interval {
        var minDate = Chart.Date.max
        var maxDate = Chart.Date.min
        
        for ui in uis {
            let interval = ui.interval(by: layer.bounds, minX: minX, maxX: maxX)
            minDate = min(minDate, interval.from)
            maxDate = max(maxDate, interval.to)
        }
        
        return ChartViewModel.Interval(from: minDate, to: maxDate)
    }

    private func expand(from: ChartViewModel.Interval, to: ChartViewModel.Interval) ->  ChartViewModel.Interval {
        return ChartViewModel.Interval(from: min(from.from, to.from), to: max(from.to, to.to))
    }

    private func interpolate(from: ChartViewModel.Interval, to: ChartViewModel.Interval, t: CGFloat) ->  ChartViewModel.Interval
    {
        // :D
        return ChartViewModel.Interval(from: AABB.Date(CGFloat(to.from) * t + CGFloat(from.from) * (1.0 - t)),
                                       to: AABB.Date(CGFloat(to.to) * t + CGFloat(from.to) * (1.0 - t)))
    }
    
    private func interpolate(from: [ColumnUIModel.UIData], to: [ColumnUIModel.UIData], t: CGFloat) -> [ColumnUIModel.UIData] {
        let length = min(from.count, to.count)

        var result: [ColumnUIModel.UIData] = []
        for i in 0..<length {
            let vfrom = CGPoint(x: to[i].from.x * t + from[i].from.x * (1.0 - t),
                                y: to[i].from.y * t + from[i].from.y * (1.0 - t))
            let vto   = CGPoint(x: to[i].to.x * t + from[i].to.x * (1.0 - t),
                                y: to[i].to.y * t + from[i].to.y * (1.0 - t))

            result.append(ColumnUIModel.UIData(from: vfrom,to: vto))
        }
        return result
    }
}

