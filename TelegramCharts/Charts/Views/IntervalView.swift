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
    internal static let sliderWidth: CGFloat = 12.0

    internal static let sliderTouchWidth: CGFloat = 32.0
    internal static let minSliderIntervalWidth: CGFloat = 20.0
    
    internal static let cornerRadius: CGFloat = 6.0

    internal static let verticalPadding: CGFloat = 2.0
    internal static let padding: CGFloat = 0.0
}

public class IntervalView: UIView
{
    override public var frame: CGRect {
        didSet { updateFrame() }
    }
    
    private let margins: UIEdgeInsets
    private var viewModel: ChartViewModel? = nil
    private var ui: ChartUIModel? = nil
    private var columnsView: ColumnsView = ColumnsView()
    private var columnsViewRect: CGRect = .zero
    private var intervalDrawableView: IntervalDrawableView = IntervalDrawableView()

    private var isBeganMovedLeftSlider: Bool = false
    private var isBeganMovedRightSlider: Bool = false
    private var isBeganMovedCenterSlider: Bool = false
    private var tapLeftOffset: CGFloat = 0.0
    private var tapRightOffset: CGFloat = 0.0

    public init(margins: UIEdgeInsets) {
        self.margins = margins
        super.init(frame: .zero)

        initialize()
    }
    
    public func setStyle(_ style: ChartStyle) {
        intervalDrawableView.setStyle(style)
    }

    public func setChart(_ chartViewModel: ChartViewModel) {
        chartViewModel.registerUpdateListener(self)

        columnsView.premake(margins: .zero, types: chartViewModel.columns.map { $0.type })

        self.viewModel = chartViewModel
        self.ui = ChartUIModel(viewModel: chartViewModel, fully: true, size: 1.0)
        update()
    }
    
    private func update() {
        guard let ui = self.ui else {
            return
        }
        
        columnsView.update(ui: ui, animated: false, duration: 0.0)
        intervalDrawableView.update(ui: ui, polyRect: columnsViewRect, animated: false, duration: 0.0)
    }

    private func initialize() {
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = false

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        gestureRecognizer.minimumPressDuration = Configs.minimumPressDuration
        self.addGestureRecognizer(gestureRecognizer)

        columnsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(columnsView)

        intervalDrawableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(intervalDrawableView)
    }
    
    private func updateFrame() {
        columnsViewRect = CGRect(x: Consts.padding + margins.left,
                                 y: Consts.verticalPadding + margins.top,
                                 width: bounds.width - 2 * Consts.padding - margins.left - margins.right,
                                 height: bounds.height - 2 * Consts.verticalPadding - margins.top - margins.bottom)

        columnsView.frame = columnsViewRect
        columnsView.setCornerRadius(Consts.cornerRadius)
        
        self.intervalDrawableView.frame = CGRect(x: Consts.padding + margins.left,
                                                 y: margins.top,
                                                 width: bounds.width - 2 * Consts.padding - margins.left - margins.right,
                                                 height: bounds.height - margins.top - margins.bottom)
        
        
        update()
    }

    @objc
    private func tapGesture(_ recognizer: UIGestureRecognizer) {
        touchProcessor(tapPosition: recognizer.location(in: self), state: recognizer.state)
    }

    private func touchProcessor(tapPosition: CGPoint, state: UIGestureRecognizer.State) {
        guard let ui = self.ui, let viewModel = self.viewModel else {
            return
        }

        let interval = ui.interval
        let rect = columnsViewRect

        let leftX = ui.translate(date: interval.from, to: rect)
        let rightX = ui.translate(date: interval.to, to: rect)

        func updateInterval() {
            let bWidth = Consts.minSliderIntervalWidth + 2 * Consts.sliderWidth

            if isBeganMovedLeftSlider {
                let newLeftX = min(tapPosition.x - tapLeftOffset, rightX - bWidth)
                let newFrom = max(ui.aabb.minDate, ui.translate(x: newLeftX, from: rect))
                viewModel.updateInterval(ChartViewModel.Interval(from: newFrom, to: interval.to))
            }
            if isBeganMovedRightSlider {
                let newRightX = max(tapPosition.x - tapRightOffset, leftX + bWidth)
                let newTo = min(ui.aabb.maxDate, ui.translate(x: newRightX, from: rect))
                viewModel.updateInterval(ChartViewModel.Interval(from: interval.from, to: newTo))
            }
            if isBeganMovedCenterSlider {
                let newLeftX = tapPosition.x - tapLeftOffset
                let newRightX = tapPosition.x - tapRightOffset
                
                let distance = interval.to - interval.from
                var newFrom = ui.translate(x: newLeftX, from: rect)
                var newTo = ui.translate(x: newRightX, from: rect)
                if newFrom <= ui.aabb.minDate {
                    newTo = ui.aabb.minDate + distance
                    newFrom = ui.aabb.minDate
                }
                if newTo >= ui.aabb.maxDate {
                    newFrom = ui.aabb.maxDate - distance
                    newTo = ui.aabb.maxDate
                }
                viewModel.updateInterval(ChartViewModel.Interval(from: newFrom, to: newTo))
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
        fatalError()
    }
}

extension IntervalView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        let ui = ChartUIModel(viewModel: viewModel, fully: true, size: 1.0)
        self.ui = ui
        
        columnsView.update(ui: ui, animated: true, duration: Configs.visibleChangeDuration)
        intervalDrawableView.update(ui: ui, polyRect: columnsViewRect, animated: true, duration: Configs.visibleChangeDuration)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        let ui = ChartUIModel(viewModel: viewModel, fully: true, size: 1.0)
        self.ui = ui
        
        intervalDrawableView.update(ui: ui, polyRect: columnsViewRect, animated: false, duration: 0)
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

    internal func update(ui: ChartUIModel, polyRect: CGRect, animated: Bool, duration: TimeInterval)
    {
        let polyRect = CGRect(origin: .zero, size: polyRect.size)

        let interval = ui.interval
        let leftX = ui.translate(date: interval.from, to: polyRect)
        let rightX = ui.translate(date: interval.to, to: polyRect)
        
        let cornerRadii = CGSize(width: Consts.cornerRadius, height: Consts.cornerRadius)

        let unvisibleRect = CGRect(x: bounds.origin.x, y: bounds.origin.y + Consts.verticalPadding,
                                   width: bounds.width, height: bounds.height - 2 * Consts.verticalPadding)

        unvisibleLeftView.frame = CGRect(x: unvisibleRect.minX, y: unvisibleRect.minY,
                                         width: leftX - unvisibleRect.minX + Consts.sliderWidth, height: unvisibleRect.height)
        let unvisibleLeftMask = CAShapeLayer()
        unvisibleLeftMask.path = UIBezierPath(roundedRect: unvisibleLeftView.bounds, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: cornerRadii).cgPath
        unvisibleLeftView.layer.mask = unvisibleLeftMask
        
        unvisibleRightView.frame = CGRect(x: rightX - Consts.sliderWidth, y: unvisibleRect.minY,
                                          width: unvisibleRect.width - rightX + Consts.sliderWidth, height: unvisibleRect.height)
        let unvisibleRightMask = CAShapeLayer()
        unvisibleRightMask.path = UIBezierPath(roundedRect: unvisibleRightView.bounds, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: cornerRadii).cgPath
        unvisibleRightView.layer.mask = unvisibleRightMask
        
        leftSliderView.frame = CGRect(x: leftX, y: bounds.minY,
                                      width: Consts.sliderWidth, height: bounds.height)
        let leftMask = CAShapeLayer()
        leftMask.path = UIBezierPath(roundedRect: leftSliderView.bounds, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: cornerRadii).cgPath
        leftSliderView.layer.mask = leftMask
        
        rightSliderView.frame = CGRect(x: rightX - Consts.sliderWidth, y: bounds.minY,
                                       width: Consts.sliderWidth, height: bounds.height)
        let rightMask = CAShapeLayer()
        rightMask.path = UIBezierPath(roundedRect: rightSliderView.bounds, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: cornerRadii).cgPath
        rightSliderView.layer.mask = rightMask

        topBorderView.frame = CGRect(x: leftX + Consts.sliderWidth - 0.5, y: bounds.minY,
                                     width: rightX - leftX - 2 * Consts.sliderWidth + 0.5, height: 2)

        bottomBorderView.frame = CGRect(x: leftX + Consts.sliderWidth - 0.5, y: bounds.maxY - 2,
                                        width: rightX - leftX - 2 * Consts.sliderWidth + 0.5, height: 2)

        leftArrow.center = leftSliderView.center
        rightArrow.center = rightSliderView.center
    }

    private func configureViews() {
        unvisibleLeftView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(unvisibleLeftView)
        unvisibleRightView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(unvisibleRightView)
        leftSliderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftSliderView)
        rightSliderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightSliderView)
        topBorderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topBorderView)
        bottomBorderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomBorderView)
        leftArrow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftArrow)
        rightArrow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightArrow)
    }
    
    private static func makeArrow(reverse: Bool) -> UIImage? {
        let centerArrowX: CGFloat = 4
        let edgeArrowX: CGFloat = Consts.sliderWidth - 4
        let arrowHeight: CGFloat = 11

        UIGraphicsBeginImageContextWithOptions(CGSize(width: Consts.sliderWidth, height: arrowHeight + 2), false, UIScreen.main.scale)

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        context.beginPath()
        if reverse {
            context.move(to: CGPoint(x: Consts.sliderWidth - edgeArrowX, y: 1))
            context.addLine(to: CGPoint(x: Consts.sliderWidth - centerArrowX, y: 1 + arrowHeight * 0.5))
            context.addLine(to: CGPoint(x: Consts.sliderWidth - edgeArrowX, y: 1 + arrowHeight))
        } else {
            context.move(to: CGPoint(x: edgeArrowX, y: 1))
            context.addLine(to: CGPoint(x: centerArrowX, y: 1 + arrowHeight * 0.5))
            context.addLine(to: CGPoint(x: edgeArrowX, y: 1 + arrowHeight))
        }
        context.strokePath()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image?.withRenderingMode(.alwaysTemplate)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
