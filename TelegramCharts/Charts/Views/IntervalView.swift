//
//  IntervalView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 13/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
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
        return chartViewModel?.visibleaabb?.copyWithIntellectualPadding(date: 0, value: Configs.padding)
    }

    private var isBeganMovedLeftSlider: Bool = false
    private var isBeganMovedRightSlider: Bool = false
    private var isBeganMovedCenterSlider: Bool = false
    private var tapLeftOffset: CGFloat = 0.0
    private var tapRightOffset: CGFloat = 0.0

    public init() {
        super.init(frame: .zero)

        initialize()
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

        intervalDrawableView.update(chartViewModel: chartViewModel, aabb: aabb, polyRect: polygonLinesView.frame,
                                    animated: false, duration: 0.0)
    }

    private func initialize() {
        self.clipsToBounds = true

        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = false

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        gestureRecognizer.minimumPressDuration = Configs.minimumPressDuration
        self.addGestureRecognizer(gestureRecognizer)

        polygonLinesView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(polygonLinesView)

        intervalDrawableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(intervalDrawableView)

        makeConstraints()
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

        initialize()
    }
}

extension IntervalView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        let aabb = visibleAABB
        polygonLinesView.update(aabb: visibleAABB, animated: true, duration: Configs.visibleChangeDuration)
        intervalDrawableView.update(chartViewModel: chartViewModel, aabb: aabb, polyRect: polygonLinesView.frame,
                                    animated: true, duration: Configs.visibleChangeDuration)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        let aabb = visibleAABB
        intervalDrawableView.update(chartViewModel: chartViewModel, aabb: aabb, polyRect: polygonLinesView.frame,
                                    animated: false, duration: 0)
    }
}

private class IntervalDrawableView: UIView
{
    private var arrowColor: UIColor = UIColor.white

    private let unvisibleLeftView: UIView = UIView(frame: .zero)
    private let unvisibleRightView: UIView = UIView(frame: .zero)
    private let leftSliderView: UIView = UIView(frame: .zero)
    private let rightSliderView: UIView = UIView(frame: .zero)
    private let topBorderView: UIView = UIView(frame: .zero)
    private let bottomBorderView: UIView = UIView(frame: .zero)
    private let leftArrow: UIImageView = UIImageView(image: makeArrow(reverse: false))
    private let rightArrow: UIImageView = UIImageView(image: makeArrow(reverse: true))

    internal init() {
        super.init(frame: .zero)

        configureViews()
    }

    internal func setStyle(_ style: ChartStyle) {
        unvisibleLeftView.backgroundColor = style.intervalUnvisibleColor
        unvisibleRightView.backgroundColor = style.intervalUnvisibleColor
        leftSliderView.backgroundColor = style.intervalBorderColor
        rightSliderView.backgroundColor = style.intervalBorderColor
        topBorderView.backgroundColor = style.intervalBorderColor
        bottomBorderView.backgroundColor = style.intervalBorderColor
        leftArrow.tintColor = style.intervalArrowColor
        rightArrow.tintColor = style.intervalArrowColor
    }

    internal func update(chartViewModel: ChartViewModel?, aabb: AABB?, polyRect: CGRect,
                         animated: Bool, duration: TimeInterval)
    {
        guard let chartViewModel = chartViewModel, let aabb = aabb else {
            hide(animated: animated, duration: duration)
            return
        }

        show(animated: animated, duration: duration)

        let interval = chartViewModel.interval
        let leftX = aabb.calculateUIPoint(date: interval.from, value: aabb.minValue, rect: polyRect).x
        let rightX = aabb.calculateUIPoint(date: interval.to, value: aabb.minValue, rect: polyRect).x
        
        let cornerRadii = CGSize(width: 2, height: 2)

        let unvisibleRect = CGRect(x: bounds.origin.x, y: bounds.origin.y + Consts.verticalPadding,
                                   width: bounds.width, height: bounds.height - 2 * Consts.verticalPadding)

        unvisibleLeftView.frame = CGRect(x: unvisibleRect.minX, y: unvisibleRect.minY,
                                         width: leftX - unvisibleRect.minX - Consts.sliderWidth, height: unvisibleRect.height)
        unvisibleRightView.frame = CGRect(x: rightX, y: unvisibleRect.minY,
                                          width: unvisibleRect.width - rightX, height: unvisibleRect.height)
        
        leftSliderView.frame = CGRect(x: leftX - Consts.sliderWidth, y: bounds.minY,
                                      width: Consts.sliderWidth, height: bounds.height)
        let leftMask = CAShapeLayer()
        leftMask.path = UIBezierPath(roundedRect: leftSliderView.bounds, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: cornerRadii).cgPath
        leftSliderView.layer.mask = leftMask
        
        rightSliderView.frame = CGRect(x: rightX, y: bounds.minY,
                                       width: Consts.sliderWidth, height: bounds.height)
        let rightMask = CAShapeLayer()
        rightMask.path = UIBezierPath(roundedRect: rightSliderView.bounds, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: cornerRadii).cgPath
        rightSliderView.layer.mask = rightMask

        topBorderView.frame = CGRect(x: leftX, y: bounds.minY,
                                     width: rightX - leftX, height: 2)

        bottomBorderView.frame = CGRect(x: leftX, y: bounds.maxY - 2,
                                        width: rightX - leftX, height: 2)

        leftArrow.center = leftSliderView.center
        rightArrow.center = rightSliderView.center
    }

    private func configureViews()
    {
        addSubview(unvisibleLeftView)
        addSubview(unvisibleRightView)
        addSubview(leftSliderView)
        addSubview(rightSliderView)
        addSubview(topBorderView)
        addSubview(bottomBorderView)
        addSubview(leftArrow)
        addSubview(rightArrow)
    }
    
    private func show(animated: Bool, duration: TimeInterval) {
        UIView.animateIf(animated, duration: duration, animations: { [weak self] in
            self?.alpha = 1.0
        })
    }

    private func hide(animated: Bool, duration: TimeInterval) {
        UIView.animateIf(animated, duration: duration, animations: { [weak self] in
            self?.alpha = 0.0
        })
    }

    private static func makeArrow(reverse: Bool) -> UIImage? {
        guard let image = drawArrow() else {
            return nil
        }

        if let cgImage = image.cgImage, reverse {
            let reverseImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImage.Orientation.upMirrored)
            return reverseImage.withRenderingMode(.alwaysTemplate)
        }

        return image.withRenderingMode(.alwaysTemplate)
    }

    private static func drawArrow() -> UIImage? {
        let centerArrowX: CGFloat = 3
        let edgeArrowX: CGFloat = 6
        let arrowHeight: CGFloat = 10

        UIGraphicsBeginImageContext(CGSize(width: Consts.sliderWidth, height: arrowHeight))

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.0)
        context.setLineCap(.round)

        context.beginPath()
        context.move(to: CGPoint(x: edgeArrowX, y: 0))
        context.addLine(to: CGPoint(x: centerArrowX, y: arrowHeight * 0.5))
        context.addLine(to: CGPoint(x: edgeArrowX, y: arrowHeight))
        context.strokePath()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
