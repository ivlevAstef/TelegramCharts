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
    
    internal private(set) var selectedDate: Chart.Date?
    internal private(set) var ui: ColumnUIModel?
    
    internal let selectorLayer: CALayer = CALayer()
    internal let selectorLayers: [CAShapeLayer]

    private var fromSelectorPointData: ColumnUIModel.UIData?
    private var toSelectorPointData: ColumnUIModel.UIData?
    private var fromPointsData: [ColumnUIModel.UIData] = []
    private var toPointsData: [ColumnUIModel.UIData] = []
    private var fromInterval: ChartViewModel.Interval?
    private var toInterval: ChartViewModel.Interval?
    private var oldTime: CFTimeInterval = CACurrentMediaTime()
    private var oldDuration: TimeInterval = 0.0

    private let pathLayer: CAShapeLayer
    private var oldIsVisible: Bool = true

    private var saveOldPath: CGPath?
    private var saveNewPath: CGPath?
    
    internal init(countSelectorLayers: Int) {
        pathLayer = CAShapeLayer()
        layer.addSublayer(pathLayer)
        
        selectorLayers = (0..<countSelectorLayers).map { _ in CAShapeLayer() }
        selectorLayers.forEach { selectorLayer.addSublayer($0) }
    }
    
    internal func setStyle(_ style: ChartStyle) {
        for layer in selectorLayers {
            layer.strokeColor = nil
            layer.fillColor = nil
            layer.lineWidth = 0
        }
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
    
    internal func drawCurrentState(to context: CGContext) {
        guard let path = saveNewPath, oldIsVisible else {
            return
        }
        
        context.saveGState()
        context.addPath(path)
        fillContext(context)
        context.restoreGState()
    }
    
    internal func drawSelectorState(to context: CGContext) {
        if nil == selectedDate || false == (self.ui?.isVisible ?? false) {
            return
        }
        
        context.saveGState()
        for layer in selectorLayers {
            guard let path = layer.path else {
                continue
            }
            context.saveGState()
            context.addPath(path)
            
            context.setFillColor(layer.fillColor ?? UIColor.clear.cgColor)
            context.setStrokeColor(layer.strokeColor ?? UIColor.clear.cgColor)
            context.setLineWidth(layer.lineWidth)
            if nil != layer.fillColor {
                context.fillPath()
            }
            if nil != layer.strokeColor {
                context.strokePath()
            }
            
            context.restoreGState()
        }
        context.restoreGState()
    }
    
    internal func updateSelector(to position: ColumnUIModel.UIData, animated: Bool, duration: TimeInterval) {
        fatalError("override")
    }
    
    internal func updateSelector(to date: Chart.Date?, animated: Bool, duration: TimeInterval, needUpdateAny: inout Bool) {
        let selectorIsVisible = nil != date && (self.ui?.isVisible ?? false)
        if let ui = self.ui, let date = date, let position = ui.dataTranslate(date: date, to: layer.bounds), selectorIsVisible {
            fromSelectorPointData = nil
            toSelectorPointData = position
            updateSelector(to: position, animated: animated, duration: duration)
        } else {
            fromSelectorPointData = nil
            toSelectorPointData = nil
        }
        
        self.selectedDate = date
        
        confirmSelectorOpacity(animated: animated, duration: duration)
    }

    internal func update(ui: ColumnUIModel, animated: Bool, duration: TimeInterval, t: CGFloat) {
        self.ui = ui
        let interval = updateInterval(ui: ui, t: t)
        updatePoints(ui: ui, t: t, interval: interval, animated: animated, duration: duration)
        updateSelector(ui: ui, t: t)
    }

    internal func confirm(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        confirmOpacity(ui: ui, animated: animated, duration: duration)
        confirmPoints(ui: ui, animated: animated, duration: duration)
        confirmSelector(ui: ui, animated: animated, duration: duration)
        confirmSelectorOpacity(animated: animated, duration: duration)
    }
    
    private func updateSelector(ui: ColumnUIModel, t: CGFloat) {
        guard let date = selectedDate else {
            return
        }
        
        guard let newPointData = ui.dataTranslate(date: date, to: layer.bounds) else {
            assert(false)
            return
        }
        
        if let fromPoint = fromSelectorPointData, let toPoint = toSelectorPointData, t < 1 {
            let interpolatePoint = interpolate(from: fromPoint, to: toPoint, t: t)
            fromSelectorPointData = interpolatePoint
        } else if let toPoint = toSelectorPointData {
            fromSelectorPointData = toPoint
        } else {
            fromSelectorPointData = nil
        }
        toSelectorPointData = newPointData
        
        selectorLayers.forEach { $0.removeAllAnimations() }
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

        pathLayer.removeAllAnimations()
    }
    
    private func confirmSelector(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        guard let toPositionData = toSelectorPointData else {
            return
        }
        
        
        for layer in selectorLayers {
            var oldPath: CGPath? = nil
            if let fromPositionData = fromSelectorPointData {
                updateSelector(to: fromPositionData, animated: false, duration: 0.0) // update path
                oldPath = layer.path
            }
            
            updateSelector(to: toPositionData, animated: false, duration: 0.0) // update path
            
            if animated && nil != oldPath && nil != layer.path {
                let animation = CABasicAnimation(keyPath: "path")
                animation.duration = duration
                animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
                animation.fromValue = oldPath
                animation.toValue = layer.path
                animation.isRemovedOnCompletion = true
                layer.add(animation, forKey: "path")
            }
        }
    }
    
    private func confirmSelectorOpacity(animated: Bool, duration: TimeInterval) {
        let selectorIsVisible = nil != selectedDate && (self.ui?.isVisible ?? false)
        
        if (selectorLayer.opacity < 1 && selectorIsVisible) || (selectorLayer.opacity > 0 && !selectorIsVisible) {
            CATransaction.begin()
            CATransaction.setAnimationDuration(animated ? duration : 0.0)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))
            
            selectorLayer.opacity = selectorIsVisible ? 1.0 : 0.0
            CATransaction.commit()
        }
    }

    private func confirmPoints(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        fillLayer(pathLayer)
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

    private func interpolate(from: ColumnUIModel.UIData, to: ColumnUIModel.UIData, t: CGFloat) -> ColumnUIModel.UIData {
        let vfrom = CGPoint(x: to.from.x * t + from.from.x * (1.0 - t),
                            y: to.from.y * t + from.from.y * (1.0 - t))
        let vto   = CGPoint(x: to.to.x * t + from.to.x * (1.0 - t),
                            y: to.to.y * t + from.to.y * (1.0 - t))
        
        return ColumnUIModel.UIData(from: vfrom,to: vto)
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

