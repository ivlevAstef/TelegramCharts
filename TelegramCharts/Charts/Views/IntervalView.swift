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

    internal static let sliderTouchWidth: CGFloat = 32.0
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
    private var isBeganMovedCenterSlider: Bool = false
    private var tapLeftOffset: CGFloat = 0.0
    private var tapRightOffset: CGFloat = 0.0

    public init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        self.clipsToBounds = true

        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = false
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        gestureRecognizer.minimumPressDuration = 0.0
        self.addGestureRecognizer(gestureRecognizer)
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
    
    @objc
    private func tapGesture(_ recognizer: UIGestureRecognizer) {
        touchProcessor(tapPosition: recognizer.location(in: self), state: recognizer.state)
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
            let newLeftX = min(tapPosition.x - tapLeftOffset, rightX)
            let newRightX = max(tapPosition.x - tapRightOffset, leftX)
            if isBeganMovedLeftSlider {
                let newFrom = max(aabb.minDate, aabb.calculateDate(x: newLeftX, rect: rect))
                chartsViewModel.updateInterval(ChartsViewModel.Interval(from: newFrom, to: interval.to))
            }
            if isBeganMovedRightSlider {
                let newTo = min(aabb.maxDate, aabb.calculateDate(x: newRightX, rect: rect))
                chartsViewModel.updateInterval(ChartsViewModel.Interval(from: interval.from, to: newTo))
            }
            if isBeganMovedCenterSlider {
                var newFrom = aabb.calculateDate(x: newLeftX, rect: rect)
                var newTo = aabb.calculateDate(x: newRightX, rect: rect)
                if newFrom < aabb.minDate {
                    newTo += (aabb.minDate - newFrom)
                    newFrom = aabb.minDate
                }
                if newTo > aabb.maxDate {
                    newFrom -= (newTo - aabb.maxDate)
                    newTo = aabb.maxDate
                }
                chartsViewModel.updateInterval(ChartsViewModel.Interval(from: newFrom, to: newTo))
            }
        }

        switch state {
        case .began:
            let leftDistance = abs(tapPosition.x - leftX)
            let rightDistance = abs(tapPosition.x - rightX)
            // only if leftX == rightX
            if leftDistance == rightDistance && leftDistance < Consts.sliderTouchWidth * 0.5 {
                isBeganMovedLeftSlider = tapPosition.x <= leftX
                isBeganMovedRightSlider = tapPosition.x > rightX
            } else {
                isBeganMovedLeftSlider = leftDistance < rightDistance && leftDistance < Consts.sliderTouchWidth * 0.5
                isBeganMovedRightSlider = rightDistance < leftDistance && rightDistance < Consts.sliderTouchWidth * 0.5
            }
            tapLeftOffset = tapPosition.x - leftX
            tapRightOffset = tapPosition.x - rightX
            
            let notSideSlider = isBeganMovedLeftSlider == false && isBeganMovedRightSlider == false
            isBeganMovedCenterSlider = notSideSlider && leftX < tapPosition.x && tapPosition.x < rightX
        case .changed:
            updateInterval()
        case .ended:
            updateInterval()
            fallthrough
        default:
            isBeganMovedLeftSlider = false
            isBeganMovedRightSlider = false
            isBeganMovedCenterSlider = false
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
