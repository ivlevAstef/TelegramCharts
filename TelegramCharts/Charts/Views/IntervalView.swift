//
//  IntervalView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 13/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

private enum Consts
{
    internal static let sliderWidth: CGFloat = 10.0

    internal static let sliderTouchWidth: CGFloat = 20.0
}

public class IntervalView: UIView
{
    public var unvisibleColor: UIColor = UIColor.lightGray.withAlphaComponent(0.3)
    public var borderColor: UIColor = UIColor.gray

    private var chartsViewModel: ChartsViewModel? = nil
    private var chartsVisibleAABB: Chart.AABB? {
        return chartsViewModel?.visibleaabb?.copyWithPadding(date: 0, value: 0.1)
    }
    private var chartLayers: [ChartLayerWrapper] = []

    private var isBeganMovedLeftSlider: Bool = false
    private var isBeganMovedRightSlider: Bool = false
    private var tapOffset: CGFloat = 0.0

    public init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear

        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = false
    }

    public func setCharts(_ charts: ChartsViewModel)
    {
        chartsViewModel = charts
        charts.registerUpdateListener(self)
        
        chartLayers.forEach { $0.layer.removeFromSuperlayer() }
        chartLayers.removeAll()
        for chart in charts.charts {
            let chartLayer = ChartLayerWrapper(chartViewModel: chart)
            chartLayers.append(chartLayer)
            layer.addSublayer(chartLayer.layer)
        }

        updateCharts()
        setNeedsDisplay()
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        if let chartsViewModel = chartsViewModel, let aabb = chartsVisibleAABB
        {
            drawInterval(chartsViewModel: chartsViewModel, aabb: aabb, rect: rect, context: context)
        }
    }
    
    private func updateCharts()
    {
        guard let aabb = chartsVisibleAABB else {
            return
        }
        
        for chartLayer in chartLayers {
            chartLayer.layer.frame = self.bounds
            chartLayer.update(aabb: aabb, animated: true)
        }
    }

    private func drawInterval(chartsViewModel: ChartsViewModel, aabb: Chart.AABB, rect: CGRect, context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        let interval = chartsViewModel.interval

        let leftX = aabb.calculateUIPoint(date: interval.from, value: aabb.minValue, rect: rect).x
        let rightX = aabb.calculateUIPoint(date: interval.to, value: aabb.minValue, rect: rect).x

        let leftRect = CGRect(x: rect.minX, y: rect.minY,
                              width: leftX - rect.minX - Consts.sliderWidth * 0.5, height: rect.height)
        let rightRect = CGRect(x: rightX + Consts.sliderWidth * 0.5, y: rect.minY,
                               width: rect.width - rightX, height: rect.height)

        context.setStrokeColor(UIColor.clear.cgColor)
        context.setLineWidth(0.0)
        context.setFillColor(unvisibleColor.cgColor)

        context.beginPath()
        context.addRects([leftRect, rightRect])
        context.fillPath()

        let leftSlider = CGRect(x: leftX - Consts.sliderWidth * 0.5, y: rect.minY,
                                width: Consts.sliderWidth, height: rect.height)
        let rightSlider = CGRect(x: rightX - Consts.sliderWidth * 0.5, y: rect.minY,
                                 width: Consts.sliderWidth, height: rect.height)

        context.setFillColor(borderColor.cgColor)

        context.beginPath()
        context.addRects([leftSlider, rightSlider])
        context.fillPath()

        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(2.0)

        context.beginPath()
        context.move(to: CGPoint(x: leftX + Consts.sliderWidth * 0.5, y: rect.minY + 1))
        context.addLine(to: CGPoint(x: rightX - Consts.sliderWidth * 0.5, y: rect.minY + 1))
        context.move(to: CGPoint(x: leftX + Consts.sliderWidth * 0.5, y: rect.maxY - 1))
        context.addLine(to: CGPoint(x: rightX - Consts.sliderWidth * 0.5, y: rect.maxY - 1))
        context.strokePath()
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        assert(touches.count <= 1)
        for touch in touches {
            touchProcessor(tapPosition: touch.location(in: self), state: .began)
        }
    }
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        assert(touches.count <= 1)
        for touch in touches {
            touchProcessor(tapPosition: touch.location(in: self), state: .changed)
        }
    }
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        assert(touches.count <= 1)
        for touch in touches {
            touchProcessor(tapPosition: touch.location(in: self), state: .cancelled)
        }
    }
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        assert(touches.count <= 1)
        for touch in touches {
            touchProcessor(tapPosition: touch.location(in: self), state: .ended)
        }
    }

    private func touchProcessor(tapPosition: CGPoint, state: UIGestureRecognizer.State) {
        guard let chartsViewModel = chartsViewModel, let aabb = chartsVisibleAABB else {
            return
        }

        let interval = chartsViewModel.interval
        let rect = self.bounds

        let leftX = aabb.calculateUIPoint(date: interval.from, value: aabb.minValue, rect: rect).x
        let rightX = aabb.calculateUIPoint(date: interval.to, value: aabb.minValue, rect: rect).x

        func updateInterval() {
            if isBeganMovedLeftSlider {
                let newLeftX = min(tapPosition.x - tapOffset, rightX)
                let newFrom = max(aabb.minDate, aabb.calculateDate(x: newLeftX, rect: rect))
                chartsViewModel.updateInterval(ChartsViewModel.Interval(from: newFrom, to: interval.to))
            }
            if isBeganMovedRightSlider {
                let newRightX = max(tapPosition.x - tapOffset, leftX)
                let newTo = min(aabb.maxDate, aabb.calculateDate(x: newRightX, rect: rect))
                chartsViewModel.updateInterval(ChartsViewModel.Interval(from: interval.from, to: newTo))
            }
        }

        switch state {
        case .began:
            let leftDistance = abs(tapPosition.x - leftX)
            let rightDistance = abs(tapPosition.x - rightX)
            var isLeft: Bool = false
            var isRight: Bool = false
            // only if leftX == rightX
            if leftDistance == rightDistance && leftDistance < Consts.sliderTouchWidth * 0.5 {
                isLeft = tapPosition.x <= leftX
                isRight = tapPosition.x > rightX
            } else {
                isLeft = leftDistance < rightDistance && leftDistance < Consts.sliderTouchWidth * 0.5
                isRight = rightDistance < leftDistance && rightDistance < Consts.sliderTouchWidth * 0.5
            }
            
            if isLeft {
                isBeganMovedLeftSlider = true
                tapOffset = tapPosition.x - leftX
            } else if isRight {
                isBeganMovedRightSlider = true
                tapOffset = tapPosition.x - rightX
            }
        case .changed:
            updateInterval()
        case .ended:
            updateInterval()
            fallthrough
        default:
            isBeganMovedLeftSlider = false
            isBeganMovedRightSlider = false
        }
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension IntervalView: ChartsUpdateListener
{
    public func chartsVisibleIsChanged(_ viewModel: ChartsViewModel)
    {
        updateCharts()
        setNeedsDisplay()
    }

    public func chartsIntervalIsChanged(_ viewModel: ChartsViewModel)
    {
        setNeedsDisplay()
    }
}
