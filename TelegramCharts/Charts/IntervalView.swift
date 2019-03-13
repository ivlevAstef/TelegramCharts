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

    private var isBeganMovedLeftSlider: Bool = false
    private var isBeganMovedRightSlider: Bool = false
    private var tapOffset: CGFloat = 0.0

    public init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear

        self.isUserInteractionEnabled = true
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(gesture(_:)))
        gestureRecognizer.minimumPressDuration = 0.0
        self.addGestureRecognizer(gestureRecognizer)
    }

    public func setCharts(_ charts: ChartsViewModel)
    {
        chartsViewModel = charts
        charts.registerUpdateListener(self)

        setNeedsDisplay()
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        if let chartsViewModel = chartsViewModel, let aabb = chartsVisibleAABB
        {
            drawCharts(chartsViewModel: chartsViewModel, aabb: aabb, rect: rect, context: context)
            drawInterval(chartsViewModel: chartsViewModel, aabb: aabb, rect: rect, context: context)
        }
    }

    private func drawCharts(chartsViewModel: ChartsViewModel, aabb: Chart.AABB, rect: CGRect, context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        context.setLineCap(.butt)
        context.setLineWidth(1.0)

        for chart in chartsViewModel.visibleCharts {
            let points = chart.calculateUIPoints(for: rect, aabb: aabb)

            context.setStrokeColor(chart.color.cgColor)
            context.beginPath()
            context.addLines(between: points)
            context.strokePath()
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
    private func gesture(_ recognizer: UIGestureRecognizer) {
        guard let chartsViewModel = chartsViewModel, let aabb = chartsVisibleAABB else {
            return
        }

        let interval = chartsViewModel.interval
        let rect = self.bounds

        let leftX = aabb.calculateUIPoint(date: interval.from, value: aabb.minValue, rect: rect).x
        let rightX = aabb.calculateUIPoint(date: interval.to, value: aabb.minValue, rect: rect).x

        let leftSlider = CGRect(x: leftX - Consts.sliderTouchWidth * 0.5, y: rect.minY,
                                width: Consts.sliderTouchWidth, height: rect.height)
        let rightSlider = CGRect(x: rightX - Consts.sliderTouchWidth * 0.5, y: rect.minY,
                                 width: Consts.sliderTouchWidth, height: rect.height)

        let tapPosition = recognizer.location(in: self)

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

        switch recognizer.state {
        case .began:
            if leftSlider.contains(tapPosition) {
                isBeganMovedLeftSlider = true
                tapOffset = tapPosition.x - leftX
            } else if rightSlider.contains(tapPosition) { // Move both sliders - not good idea
                isBeganMovedRightSlider = true
                tapOffset = tapPosition.x - rightX
            }
        case .changed:
            updateInterval()
        case .ended:
            updateInterval()
            fallthrough
        case .cancelled, .failed, .possible:
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
        setNeedsDisplay()
    }

    public func chartsIntervalIsChanged(_ viewModel: ChartsViewModel)
    {
        setNeedsDisplay()
    }
}
