//
//  HintAndOtherView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 19/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

private enum Consts
{
    internal static let pointSize: CGFloat = 10
    internal static let centerPointSize: CGFloat = 5

    internal static let innerHintPadding: CGFloat = 8
    internal static let hintLabelsSpace: CGFloat = 2
    internal static let hintHorizontalSpace: CGFloat = 8

    internal static let hintYOffset: CGFloat = -16
    internal static let hintCornerRadius: CGFloat = 5
}

internal class HintAndOtherView: UIView
{
    private var aabb: AABB?
    private var columnsViewModels: [ColumnViewModel] = []

    private let font: UIFont = UIFont.systemFont(ofSize: 12.0)
    private var color: UIColor = .black
    private var lineColor: UIColor = .black

    private var lastTouchPosition: CGPoint? = nil

    private let lineView: LineView = LineView()
    private let hintView: HintView = HintView(font: UIFont.systemFont(ofSize: 12.0),
                                              accentFont: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.medium))

    internal init() {
        super.init(frame: .zero)

        addSubview(lineView)
        addSubview(hintView)
        hide(animated: false)

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        gestureRecognizer.minimumPressDuration = Configs.minimumPressDuration
        self.addGestureRecognizer(gestureRecognizer)
    }

    internal func setStyle(_ style: ChartStyle) {
        lineView.lineColor = style.focusLineColor
        lineView.centerPointColor = style.dotColor
        hintView.backgroundColor = style.hintBackgroundColor
        hintView.textColor = style.hintTextColor
    }

    internal func setColumns(_ columnsViewModels: [ColumnViewModel]) {
        self.columnsViewModels = columnsViewModels
    }

    internal func setAABB(aabb: AABB?) {
        self.aabb = aabb

        if let touchPosition = lastTouchPosition {
            touchProcessor(tapPosition: touchPosition, state: .changed)
        }
    }

    @objc
    private func tapGesture(_ recognizer: UIGestureRecognizer) {
        touchProcessor(tapPosition: recognizer.location(in: self), state: recognizer.state)
    }

    private func touchProcessor(tapPosition: CGPoint, state: UIGestureRecognizer.State) {
        guard let aabb = self.aabb else {
            hide(animated: true)
            return
        }

        switch state {
        case .began:
            fallthrough
        case .changed:
            lastTouchPosition = tapPosition
            let date = aabb.calculateDate(x: tapPosition.x, rect: bounds)
            showHintAndOther(aroundDate: date)
            break
        default:
            lastTouchPosition = nil
            hide(animated: true)
        }
    }

    private func showHintAndOther(aroundDate: Column.Date) {
        guard let aabb = self.aabb else {
            hide(animated: true)
            return
        }

        let polylineViewModels = columnsViewModels.filter { $0.isVisible }

        let dates = polylineViewModels.map { $0.getPoint(by: aroundDate).date }
        guard let nearDate = dates.min(by: { abs($0 - aroundDate) <= abs($1 - aroundDate) }) else {
            hide(animated: true)
            return
        }
        let position = aabb.calculateUIPoint(date: nearDate, value: 0, rect: bounds).x

        show(animated: true)

        let lines = polylineViewModels.map { ($0.color, $0.getPoint(by: nearDate).pair.to) }
        hintView.setData(date: nearDate, lines: lines)
        hintView.setPosition(position, limit: bounds)

        let points = lines.map { ($0.0, aabb.calculateUIPoint(date: nearDate, value: $0.1, rect: bounds).y) }
        lineView.setPoints(points)
        lineView.setHeightAndOrigin(height: frame.height, origin: hintView.frame.maxY)
        lineView.setPosition(position, limit: bounds)
    }

    private func hide(animated: Bool) {
        UIView.animateIf(animated, duration: Configs.hintDuration, animations: { [weak self] in
            self?.hintView.alpha = 0.0
            self?.lineView.alpha = 0.0
        }, completion: { [weak self] _ in
            self?.hintView.isHidden = true
            self?.lineView.isHidden = true
        })
    }

    private func show(animated: Bool) {
        hintView.isHidden = false
        lineView.isHidden = false
        
        UIView.animateIf(animated, duration: Configs.hintDuration, animations: { [weak self] in
            self?.hintView.alpha = 1.0
            self?.lineView.alpha = 1.0
        })
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class LineView: UIView
{
    internal var lineColor: UIColor = .black {
        didSet {
            lineView.backgroundColor = lineColor
        }
    }
    internal var centerPointColor: UIColor = .white

    private let lineView: UIView = UIView(frame: .zero)

    internal init() {
        super.init(frame: CGRect(x: 0, y: 0, width: Consts.pointSize, height: 0))

        lineView.frame.origin.x = Consts.pointSize * 0.5
        lineView.frame.size.width = 1
        addSubview(lineView)
    }

    internal func setPoints(_ points: [(UIColor, CGFloat)]) {
        subviews.filter { $0 !== lineView }.forEach { $0.removeFromSuperview() }

        for (color, position) in points {
            let pointView = UIView(frame: CGRect(x: 0, y: 0, width: Consts.pointSize, height: Consts.pointSize))
            pointView.center = CGPoint(x: frame.width * 0.5, y: position)
            pointView.backgroundColor = color
            pointView.layer.cornerRadius = Consts.pointSize * 0.5

            let centerView = UIView(frame: CGRect(x: 0, y: 0, width: Consts.centerPointSize, height: Consts.centerPointSize))
            centerView.center = CGPoint(x: Consts.pointSize * 0.5, y: Consts.pointSize * 0.5)
            centerView.backgroundColor = centerPointColor
            centerView.layer.cornerRadius = Consts.centerPointSize * 0.5
            pointView.addSubview(centerView)

            addSubview(pointView)
        }
    }

    internal func setHeightAndOrigin(height: CGFloat, origin: CGFloat) {
        frame.size.height = height
        lineView.frame.origin.y = origin
        lineView.frame.size.height = height - origin
    }

    internal func setPosition(_ position: CGFloat, limit: CGRect) {
        let position = max(limit.minX, min(position, limit.maxX - 1))
        center = CGPoint(x: position, y: frame.height / 2.0)
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class HintView: UIView
{
    internal static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter
    }()

    internal static let dateYearFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter
    }()

    internal var textColor: UIColor = .black
    private let font: UIFont
    private let accentFont: UIFont

    internal init(font: UIFont, accentFont: UIFont) {
        self.font = font
        self.accentFont = accentFont
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

        self.layer.cornerRadius = Consts.hintCornerRadius
    }

    internal func setData(date: Column.Date, lines: [(UIColor, AABB.Value)]) {
        subviews.forEach { $0.removeFromSuperview() }

        // Date
        let dateLabel: UILabel = UILabel(frame: .zero)
        let date = Date(timeIntervalSince1970: TimeInterval(date) / 1000.0)
        let dateOfStr = HintView.dateFormatter.string(from: date)
        dateLabel.font = accentFont
        dateLabel.text = dateOfStr
        dateLabel.textColor = textColor
        dateLabel.frame.origin = CGPoint(x: Consts.innerHintPadding, y: Consts.innerHintPadding)
        dateLabel.sizeToFit()
        addSubview(dateLabel)

        // Year
        let yearLabel: UILabel = UILabel(frame: .zero)
        let yearOfStr = HintView.dateYearFormatter.string(from: date)
        yearLabel.font = font
        yearLabel.text = yearOfStr
        yearLabel.textColor = textColor
        yearLabel.frame.origin = CGPoint(x: Consts.innerHintPadding, y: dateLabel.frame.maxY + Consts.hintLabelsSpace)
        yearLabel.sizeToFit()
        addSubview(yearLabel)

        // Values
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        let minLeftX = max(dateLabel.frame.maxX, yearLabel.frame.maxX)
        var rightX = minLeftX
        var valueLabels: [UILabel] = []
        for (color, value) in lines {
            let valueLabel = UILabel(frame: .zero)
            valueLabel.font = accentFont
            valueLabel.text = numberFormatter.string(from: NSNumber(value: value))
            valueLabel.textColor = color
            valueLabel.sizeToFit()

            rightX = max(rightX, minLeftX + Consts.hintHorizontalSpace + valueLabel.frame.width)

            valueLabels.append(valueLabel)
            addSubview(valueLabel)
        }

        var maxY = yearLabel.frame.maxY
        var yPosition = dateLabel.frame.minY
        for valueLabel in valueLabels {
            valueLabel.frame.origin = CGPoint(x: rightX - valueLabel.frame.width, y: yPosition)
            yPosition = valueLabel.frame.maxY + Consts.hintLabelsSpace
            maxY = max(valueLabel.frame.maxY, maxY)
        }

        frame.size = CGSize(width: rightX + Consts.innerHintPadding, height: maxY + Consts.innerHintPadding)
    }

    internal func setPosition(_ position: CGFloat, limit: CGRect) {
        center = CGPoint(x: position, y: 0)
        frame.origin.y = Consts.hintYOffset

        if frame.minX < limit.minX {
            frame.origin.x = limit.minX
        }

        if frame.maxX > limit.maxX {
            frame.origin.x = limit.maxX - frame.size.width
        }
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
