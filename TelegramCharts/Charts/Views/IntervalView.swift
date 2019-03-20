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

    internal static let verticalPadding: CGFloat = 2.0
    internal static let padding: CGFloat = 8.0
}

public class IntervalView: UIView
{
    private var chartViewModel: ChartViewModel? = nil
    private var polygonLinesView: PolygonLinesView = PolygonLinesView()
    private var intervalDrawableView: IntervalDrawableView = IntervalDrawableView()
    
    private var visibleAABB: AABB? {
        return chartViewModel?.visibleaabb?.copyWithIntellectualPadding(date: 0, value: 0.1)
    }

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
        
        polygonLinesView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(polygonLinesView)

        intervalDrawableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(intervalDrawableView)

        makeConstraints()
    }
    
    public func setStyle(_ style: ChartStyle) {
        intervalDrawableView.setStyle(style)
    }

    public func setChart(_ chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel
        chartViewModel.registerUpdateListener(self)

        let aabb = visibleAABB
        
        polygonLinesView.setPolygonLines(chartViewModel.polygonLines)
        polygonLinesView.setLineWidth(1.0)
        polygonLinesView.update(aabb: aabb, animated: false, duration: 0.0)

        intervalDrawableView.update(chartViewModel: chartViewModel, aabb: aabb, polyRect: polygonLinesView.frame)
    }
    
    private func makeConstraints() {
        self.polygonLinesView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.polygonLinesView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: Consts.padding).isActive = true
        self.polygonLinesView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -Consts.padding).isActive = true
        self.polygonLinesView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        self.intervalDrawableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.intervalDrawableView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.intervalDrawableView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.intervalDrawableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    @objc
    private func tapGesture(_ recognizer: UIGestureRecognizer) {
        touchProcessor(tapPosition: recognizer.location(in: self), state: recognizer.state)
    }

    private func touchProcessor(tapPosition: CGPoint, state: UIGestureRecognizer.State) {
        guard let chartViewModel = chartViewModel, let aabb = visibleAABB else {
            return
        }

        let interval = chartViewModel.interval
        let rect = polygonLinesView.frame

        let leftX = aabb.calculateUIPoint(date: interval.from, value: aabb.minValue, rect: rect).x - Consts.sliderWidth * 0.5
        let rightX = aabb.calculateUIPoint(date: interval.to, value: aabb.minValue, rect: rect).x + Consts.sliderWidth * 0.5

        func updateInterval() {
            let newLeftX = min(tapPosition.x - tapLeftOffset, rightX - Consts.sliderWidth)
            let newRightX = max(tapPosition.x - tapRightOffset, leftX + Consts.sliderWidth)

            if isBeganMovedLeftSlider {
                let newFrom = max(aabb.minDate, aabb.calculateDate(x: newLeftX, rect: rect))
                chartViewModel.updateInterval(ChartViewModel.Interval(from: newFrom, to: interval.to))
            }
            if isBeganMovedRightSlider {
                let newTo = min(aabb.maxDate, aabb.calculateDate(x: newRightX, rect: rect))
                chartViewModel.updateInterval(ChartViewModel.Interval(from: interval.from, to: newTo))
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
                chartViewModel.updateInterval(ChartViewModel.Interval(from: newFrom, to: newTo))
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
            tapLeftOffset = tapPosition.x - leftX - Consts.sliderWidth * 0.5
            tapRightOffset = tapPosition.x - rightX + Consts.sliderWidth * 0.5
            
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

extension IntervalView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        let aabb = visibleAABB
        polygonLinesView.update(aabb: visibleAABB, animated: true, duration: Configs.visibleChangeDuration)
        intervalDrawableView.update(chartViewModel: chartViewModel, aabb: aabb, polyRect: polygonLinesView.frame)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        let aabb = visibleAABB
        intervalDrawableView.update(chartViewModel: chartViewModel, aabb: aabb, polyRect: polygonLinesView.frame)
    }
}

private class IntervalDrawableView: UIView
{
    private var unvisibleColor: UIColor = UIColor.lightGray.withAlphaComponent(0.3)
    private var borderColor: UIColor = UIColor.gray
    private var arrowColor: UIColor = UIColor.white

    private var chartViewModel: ChartViewModel? = nil
    private var aabb: AABB? = nil
    private var polyRect: CGRect = .zero

    internal init() {
        super.init(frame: .zero)

        self.backgroundColor = .clear
        self.clipsToBounds = true
    }

    internal func setStyle(_ style: ChartStyle) {
        unvisibleColor = style.intervalUnvisibleColor
        borderColor = style.intervalBorderColor
        // TODO: arrowColor
    }

    internal func update(chartViewModel: ChartViewModel?, aabb: AABB?, polyRect: CGRect) {
        self.chartViewModel = chartViewModel
        self.aabb = aabb
        self.polyRect = polyRect

        setNeedsDisplay()
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        drawInterval(rect: rect, context: context)
    }

    private func drawInterval(rect: CGRect, context: CGContext) {
        guard let chartViewModel = chartViewModel, let aabb = aabb else
        {
            return
        }

        context.saveGState()
        defer { context.restoreGState() }

        let interval = chartViewModel.interval

        let leftX = aabb.calculateUIPoint(date: interval.from, value: aabb.minValue, rect: polyRect).x
        let rightX = aabb.calculateUIPoint(date: interval.to, value: aabb.minValue, rect: polyRect).x

        // unvisible zone
        let unvisibleRect = CGRect(x: rect.origin.x, y: rect.origin.y + Consts.verticalPadding,
                                   width: rect.width, height: rect.height - 2 * Consts.verticalPadding)
        let leftRect = CGRect(x: unvisibleRect.minX, y: unvisibleRect.minY,
                              width: leftX - unvisibleRect.minX - Consts.sliderWidth, height: unvisibleRect.height)
        let rightRect = CGRect(x: rightX, y: unvisibleRect.minY,
                               width: unvisibleRect.width - rightX, height: unvisibleRect.height)

        context.setStrokeColor(UIColor.clear.cgColor)
        context.setLineWidth(0.0)
        context.setFillColor(unvisibleColor.cgColor)

        context.beginPath()
        context.addRects([leftRect, rightRect])
        context.fillPath()

        // Sliders
        let leftSlider = CGRect(x: leftX - Consts.sliderWidth, y: rect.minY,
                                width: Consts.sliderWidth, height: rect.height)
        let rightSlider = CGRect(x: rightX, y: rect.minY,
                                 width: Consts.sliderWidth, height: rect.height)

        context.setFillColor(borderColor.cgColor)

        context.beginPath()
        context.addRects([leftSlider, rightSlider])
        context.fillPath()

        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(2.0)

        context.beginPath()
        context.move(to: CGPoint(x: leftX, y: rect.minY + 1))
        context.addLine(to: CGPoint(x: rightX, y: rect.minY + 1))
        context.move(to: CGPoint(x: leftX, y: rect.maxY - 1))
        context.addLine(to: CGPoint(x: rightX, y: rect.maxY - 1))
        context.strokePath()

        // Arrow
        context.setStrokeColor(arrowColor.cgColor)
        context.setLineWidth(2.0)
        context.setLineCap(.round)

        let centerArrowX: CGFloat = 3
        let edgeArrowX: CGFloat = 6
        let centerArrowY: CGFloat = rect.minY + (rect.maxY - rect.minY) * 0.5
        let arrowHeight: CGFloat = 5

        context.beginPath()
        context.move(to: CGPoint(x: leftX - Consts.sliderWidth + edgeArrowX, y: centerArrowY - arrowHeight))
        context.addLine(to: CGPoint(x: leftX - Consts.sliderWidth + centerArrowX, y: centerArrowY))
        context.addLine(to: CGPoint(x: leftX - Consts.sliderWidth + edgeArrowX, y: centerArrowY + arrowHeight))
        context.strokePath()

        context.beginPath()
        context.move(to: CGPoint(x: rightX + Consts.sliderWidth - edgeArrowX, y: centerArrowY - arrowHeight))
        context.addLine(to: CGPoint(x: rightX + Consts.sliderWidth - centerArrowX, y: centerArrowY))
        context.addLine(to: CGPoint(x: rightX + Consts.sliderWidth - edgeArrowX, y: centerArrowY + arrowHeight))
        context.strokePath()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
