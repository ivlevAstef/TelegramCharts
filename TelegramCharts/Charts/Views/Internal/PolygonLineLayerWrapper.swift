//
//  PolygonLineLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 14/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal final class PolygonLineLayerWrapper
{
    internal let layer: CAShapeLayer = CAShapeLayer()
    private let polygonLineViewModel: PolygonLineViewModel

    private let pathIndexCounter: IndexCounter = IndexCounter()
    private let opacityIndexCounter: IndexCounter = IndexCounter()

    internal init(polygonLineViewModel: PolygonLineViewModel) {
        self.polygonLineViewModel = polygonLineViewModel
        
        layer.lineWidth = 1.0
        layer.lineCap = .butt
        layer.strokeColor = polygonLineViewModel.color.cgColor
        layer.fillColor = nil
    }
    
    internal func update(aabb: AABB, animatedPath: Bool, animatedOpacity: Bool, duration: TimeInterval) {
        let newPath = makePath(aabb: aabb)

        if animatedPath && nil != layer.path {
            let animation = CASaveStateAnimation(keyPath: "path")
            animation.duration = duration
            animation.toValue = newPath.cgPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.fillMode = .both
            animation.startAnimation(on: layer, indexCounter: pathIndexCounter)
        } else {
            layer.path = newPath.cgPath
        }
        
        let newOpacity: Float = polygonLineViewModel.isVisible ? 1.0 : 0.0
        if animatedOpacity {
            let animation = CASaveStateAnimation(keyPath: "opacity")
            animation.duration = duration
            animation.toValue = newOpacity
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.fillMode = .both
            animation.startAnimation(on: layer, indexCounter: opacityIndexCounter)
        } else {
            layer.opacity = newOpacity
        }
    }
    
    private func makePath(aabb: AABB) -> UIBezierPath {
        var uiPoints = polygonLineViewModel.calculateUIPoints(for: layer.bounds, aabb: aabb)
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

private class IndexCounter
{
    private var counter: Int64 = 0
    private var lastExecuted: Int64 = 0

    func next() -> Int64 {
        counter += 1
        return counter
    }

    func finished(_ number: Int64) -> Bool {
        if lastExecuted < number {
            lastExecuted = number
            return true
        }
        return false
    }
}

private class CASaveStateAnimation: CABasicAnimation, CAAnimationDelegate
{
    private var uniqueIndex: Int64!
    private var indexCounter: IndexCounter!
    private var uniqueKey: String { return "\(keyPath!)\(uniqueIndex!)"}
    
    private weak var parentLayer: CALayer?
    private var selfRetain: CASaveStateAnimation?

    internal func startAnimation(on layer: CALayer, indexCounter: IndexCounter) {
        self.indexCounter = indexCounter
        self.uniqueIndex = indexCounter.next()

        parentLayer = layer
        isRemovedOnCompletion = false
        delegate = self
        layer.add(self, forKey: uniqueKey)
    }
    
    @objc
    func animationDidStart(_ anim: CAAnimation) {
        selfRetain = self
    }
    
    @objc
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if indexCounter.finished(uniqueIndex) {
            parentLayer?.setValue(toValue, forKey: keyPath!)
        }
        selfRetain = nil
        parentLayer?.removeAnimation(forKey: uniqueKey)
    }
}
