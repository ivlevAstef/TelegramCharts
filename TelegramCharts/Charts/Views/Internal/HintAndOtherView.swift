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

    internal static let hintYOffset: CGFloat = 4
    internal static let hintCornerRadius: CGFloat = 5
}

internal final class HintAndOtherView: UIView
{
    private let font: UIFont = UIFont.systemFont(ofSize: 12.0)
    private var color: UIColor = .black
    private var lineColor: UIColor = .black

    private var ui: ChartUIModel?
    private var lastTouchPosition: CGPoint? = nil

    private let barsView: BarsView = BarsView()
    private let lineView: LineView = LineView()
    private let hintView: HintView = HintView(font: UIFont.systemFont(ofSize: 12.0),
                                              accentFont: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.medium))

    internal init() {
        super.init(frame: .zero)

        barsView.translatesAutoresizingMaskIntoConstraints = false
        // addSubview(barsView) -> setParent
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineView)
        hintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hintView)

        hide(hintView: true, lineView: true, barsView: true, animated: false)

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        gestureRecognizer.minimumPressDuration = Configs.minimumPressDuration
        self.addGestureRecognizer(gestureRecognizer)
    }

    internal func setParent(_ parent: UIView) {
        parent.addSubview(barsView)
    }
    internal func updateParentFrame(_ frame: CGRect) {
        barsView.frame = frame
    }

    internal func setStyle(_ style: ChartStyle) {
        lineView.lineColor = style.focusLineColor
        lineView.centerPointColor = style.dotColor
        hintView.backgroundColor = style.hintBackgroundColor
        hintView.textColor = style.hintTextColor
        barsView.barColor = style.hintBarColor
    }

    internal func update(ui: ChartUIModel) {
        self.ui = ui
        
        if let touchPosition = lastTouchPosition {
            touchProcessor(tapPosition: touchPosition, state: .changed)
        }
    }

    @objc
    private func tapGesture(_ recognizer: UIGestureRecognizer) {
        touchProcessor(tapPosition: recognizer.location(in: self), state: recognizer.state)
    }

    private func touchProcessor(tapPosition: CGPoint, state: UIGestureRecognizer.State) {
        guard let ui = self.ui else {
            hide(hintView: true, lineView: true, barsView: true)
            return
        }

        switch state {
        case .began:
            fallthrough
        case .changed:
            lastTouchPosition = tapPosition
            let date = ui.translate(x: tapPosition.x, from: bounds)
            showHintAndOther(aroundDate: date, use: ui)
        default:
            lastTouchPosition = nil
            hide(hintView: true, lineView: true, barsView: true)
        }
    }

    private func showHintAndOther(aroundDate: Chart.Date, use ui: ChartUIModel) {
        let nearDate = ui.find(around: aroundDate, in: ui.interval)

        let animated = showHint(in: nearDate, use: ui)
        let lineRect = showLineIfNeeded(in: nearDate, use: ui)
        let barsRect = showBarsIfNeeded(in: nearDate, use: ui)
        updateHintPosition(in: nearDate, use: ui, animated: animated, aroundRects: [lineRect, barsRect])
    }

    private func showHint(in date: Chart.Date, use ui: ChartUIModel) -> Bool {
        let rows = ui.columns.enumerated().compactMap { (index, column) -> (UIColor, ColumnViewModel.Value, Int)? in
            if let value = column.find(by: date)?.original, column.isVisible {
                return (column.color, value, index)
            }
            return nil
        }

        let animated = needAnimated(hintView)
        hintView.isHidden = false
        UIView.animateIf(animated, duration: Configs.hintDuration * 0.5, animations: { [weak self] in
            self?.hintView.setDate(date)
            self?.hintView.setRows(rows)
        })

        if hintView.alpha < 1.0 {
            UIView.animateIf(true, duration: Configs.hintDuration, animations: { [weak self] in
                self?.hintView.alpha = 1.0
            })
        }

        return animated
    }

    private func updateHintPosition(in date: Chart.Date, use ui: ChartUIModel, animated: Bool, aroundRects: [CGRect]) {
        let position = ui.translate(date: date, to: bounds)

        let limit = bounds
        UIView.animateIf(animated, duration: Configs.hintPositionDuration, animations: { [weak self] in
            self?.hintView.setPosition(position, aroundRects: aroundRects, limit: limit)
        })
    }

    private func showLineIfNeeded(in date: Chart.Date, use ui: ChartUIModel) -> CGRect {
        let position = ui.translate(date: date, to: bounds)
        let points = ui.columns.enumerated().compactMap { (index, column) -> (UIColor, CGFloat, Int)? in
            if let value = column.find(by: date)?.to, column.isVisible, column.type != .bar {
                return (column.color, column.translate(value: value, to: bounds), index)
            }
            return nil
        }

        if 0 == points.count {
            hide(lineView: true)
            return .zero
        }

        let animated = needAnimated(lineView)
        self.lineView.isHidden = false

        if lineView.alpha < 1.0 {
            UIView.animateIf(true, duration: Configs.hintDuration, animations: { [weak self] in
                self?.lineView.alpha = 1.0
            })
        }

        let limit = bounds
        let yStart = self.hintView.frame.minY
        // points animation need animate by path, or, not animate...
        self.lineView.setPoints(points)
        self.lineView.setPosition(position, limit: bounds)
        self.lineView.setHeightAndYStart(height: limit.height, yStart: yStart)

        return lineView.myRect()
    }

    private func showBarsIfNeeded(in date: Chart.Date, use ui: ChartUIModel) -> CGRect {
        let position = ui.translate(date: date, to: bounds)

        let bars = ui.columns.filter { column in
            return column.isVisible && column.type == .bar
        }

        if 0 == bars.count {
            hide(barsView: true)
            return .zero
        }

        let minY = bars.compactMap { column -> CGFloat? in
            if let barData = column.find(by: date).flatMap({ column.translate(data: $0, to: bounds) }) {
                return min(barData.to.y, barData.from.y)
            }
            return nil
        }.min() ?? CGFloat(0)

        let animated = needAnimated(barsView)
        self.barsView.isHidden = false

        if barsView.alpha < 1.0 {
            UIView.animateIf(true, duration: Configs.hintDuration, animations: { [weak self] in
                self?.barsView.alpha = 1.0
            })
        }

        let date1Pos = ui.translate(date: ui.dates[0], to: bounds)
        let date2Pos = ui.translate(date: ui.dates[1], to: bounds)
        let width = (date2Pos - date1Pos)

        let limit = bounds
        UIView.animateIf(false, duration: Configs.hintPositionDuration, animations: { [weak self] in
            self?.barsView.setBars(minY: minY, width: width)
            self?.barsView.setPosition(position, limit: limit)
        })

        return barsView.myRect()
    }

    private func needAnimated(_ view: UIView) -> Bool {
        return false == view.isHidden && view.alpha > 0.01
    }

    private func hide(hintView: Bool = false, lineView: Bool = false, barsView: Bool = false, animated: Bool = true) {
        UIView.animateIf(animated, duration: Configs.hintDuration, animations: { [weak self] in
            guard let `self` = self else {
                return
            }
            if hintView && 0.0 != self.hintView.alpha {
                self.hintView.alpha = 0.0
            }
            if lineView && 0.0 != self.lineView.alpha {
                self.lineView.alpha = 0.0
            }
            if barsView && 0.0 != self.barsView.alpha {
                self.barsView.alpha = 0.0
            }
        }, completion: { [weak self] _ in
            if hintView {
                self?.hintView.isHidden = true
            }
            if lineView {
                self?.lineView.isHidden = true
            }
            if barsView {
                self?.barsView.isHidden = true
            }
        })
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class LineView: UIView
{
    private class Point: UIView {
        internal let id: Int
        internal init(id: Int, parent: UIView, centerColor: UIColor) {
            self.id = id

            super.init(frame: CGRect(x: 0, y: 0, width: Consts.pointSize, height: Consts.pointSize))
            layer.cornerRadius = Consts.pointSize * 0.5

            let centerView = UIView(frame: CGRect(x: 0, y: 0, width: Consts.centerPointSize, height: Consts.centerPointSize))
            centerView.center = CGPoint(x: Consts.pointSize * 0.5, y: Consts.pointSize * 0.5)
            centerView.backgroundColor = centerColor
            centerView.layer.cornerRadius = Consts.centerPointSize * 0.5
            centerView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(centerView)

            translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(self)
        }

        internal required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    internal var lineColor: UIColor = .black {
        didSet {
            lineView.backgroundColor = lineColor
        }
    }
    internal var centerPointColor: UIColor = .white

    private let lineView: UIView = UIView(frame: .zero)
    private var pointViews: [Point] = []

    internal init() {
        super.init(frame: CGRect(x: 0, y: 0, width: Consts.pointSize, height: 0))

        lineView.frame.origin.x = Consts.pointSize * 0.5
        lineView.frame.size.width = 1
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineView)
    }

    internal func setPoints(_ points: [(color: UIColor, position: CGFloat, id: Int)]) {
        let oldPointViews = pointViews
        pointViews.removeAll()
        for (color, position, id) in points {
            let foundPointView = oldPointViews.first(where: { $0.id == id })
            let pointView = foundPointView ?? Point(id: id, parent: self, centerColor: centerPointColor)

            pointView.center = CGPoint(x: frame.width * 0.5, y: position)
            pointView.backgroundColor = color

            pointViews.append(pointView)
        }

        for view in oldPointViews {
            if !pointViews.contains(where: { $0.id == view.id }) {
                view.removeFromSuperview()
            }
        }
    }

    internal func setHeightAndYStart(height: CGFloat, yStart: CGFloat) {
        var minY: CGFloat = yStart
        for view in pointViews {
            minY = min(minY, view.frame.minY)
        }

        frame.size.height = height
        lineView.frame.origin.y = minY
        lineView.frame.size.height = height - minY
    }

    internal func setPosition(_ position: CGFloat, limit: CGRect) {
        let position = max(limit.minX, min(position, limit.maxX - 1))
        center = CGPoint(x: position, y: frame.height / 2.0)
    }

    internal func myRect() -> CGRect {
        var minX: CGFloat = 99999
        var minY: CGFloat = 99999
        var maxX: CGFloat = -99999
        var maxY: CGFloat = -99999

        for view in pointViews {
            minX = min(minX, view.frame.minX + frame.minX)
            minY = min(minY, view.frame.minY + frame.minY)
            maxX = max(maxX, view.frame.maxX + frame.minX)
            maxY = max(maxY, view.frame.maxY + frame.minY)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class BarsView: UIView
{
    internal var barColor: UIColor = .black {
        didSet {
            leftView.backgroundColor = barColor
            rightView.backgroundColor = barColor
        }
    }
    private var leftView: UIView = UIView(frame: .zero)
    private var rightView: UIView = UIView(frame: .zero)
    private var width: CGFloat = 0.0
    private var minY: CGFloat = 0.0

    internal init() {
        super.init(frame: .zero)

        leftView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftView)
        rightView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightView)
    }

    internal func setBars(minY: CGFloat, width: CGFloat) {
        self.width = width
        self.minY = minY
    }

    internal func setPosition(_ position: CGFloat, limit: CGRect) {
        var position = max(limit.minX, min(position, limit.maxX))
        position += (frame.width - limit.width) * 0.5

        let leftWidth = position - width * 0.5 - 0.1
        let leftRect = CGRect(x: 0, y: 0, width: leftWidth, height: frame.height)
        if !leftView.frame.equalTo(leftRect) {
            leftView.frame = leftRect
        }

        let rightX = position + width * 0.5 + 0.1
        let rightWidth = frame.width - rightX
        let rightRect = CGRect(x: rightX, y: 0, width: rightWidth, height: frame.height)
        if !rightView.frame.equalTo(rightRect) {
            rightView.frame = rightRect
        }
    }

    internal func myRect() -> CGRect {
        return CGRect(x: leftView.frame.width, y: minY, width: width, height: frame.height - minY)
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class HintView: UIView
{
    private class Label: UILabel {
        internal let id: Int

        internal init(id: Int, font: UIFont, parent: UIView) {
            self.id = id
            super.init(frame: .zero)
            self.font = font

            translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(self)
        }

        internal required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    internal static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy MMM d"
        return dateFormatter
    }()

    internal var textColor: UIColor = .black
    private let font: UIFont
    private let accentFont: UIFont

    private let dateLabel: UILabel = UILabel(frame: .zero)
    private var valueLabels: [Label] = []
    private var lastIntersectTime: Date = Date()

    internal init(font: UIFont, accentFont: UIFont) {
        self.font = font
        self.accentFont = accentFont
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

        layer.cornerRadius = Consts.hintCornerRadius
        frame.origin.y = Consts.hintYOffset

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(dateLabel)
    }

    internal func setDate(_ date: Chart.Date) {
        let date = Date(timeIntervalSince1970: TimeInterval(date) / 1000.0)
        let dateOfStr = HintView.dateFormatter.string(from: date)
        dateLabel.font = accentFont
        dateLabel.text = dateOfStr
        dateLabel.textColor = textColor
        dateLabel.frame.origin = CGPoint(x: Consts.innerHintPadding, y: Consts.innerHintPadding)
        dateLabel.sizeToFit()
    }

    internal func setRows(_ rows: [(color: UIColor, value: ColumnViewModel.Value, id: Int)])
    {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        var rightX = dateLabel.frame.maxX

        let oldValueLabels = valueLabels
        valueLabels.removeAll()
        for (color, value, id) in rows {
            let foundLabel = oldValueLabels.first(where: { $0.id == id })
            let valueLabel = foundLabel ?? Label(id: id, font: font, parent: self)

            valueLabel.text = numberFormatter.string(from: NSNumber(value: value))
            valueLabel.textColor = color
            valueLabel.sizeToFit()

            valueLabels.append(valueLabel)

            rightX = max(rightX, Consts.innerHintPadding + valueLabel.frame.width)
        }

        for label in oldValueLabels {
            if !valueLabels.contains(where: { $0.id == label.id }) {
                label.removeFromSuperview()
            }
        }

        var maxY = dateLabel.frame.maxY
        var yPosition = dateLabel.frame.maxY + Consts.hintLabelsSpace
        for valueLabel in valueLabels {
            valueLabel.frame.origin = CGPoint(x: rightX - valueLabel.frame.width, y: yPosition)
            yPosition = valueLabel.frame.maxY + Consts.hintLabelsSpace
            maxY = max(valueLabel.frame.maxY, maxY)
        }

        frame.size = CGSize(width: rightX + Consts.innerHintPadding, height: maxY + Consts.innerHintPadding)
    }

    internal func setPosition(_ position: CGFloat, aroundRects: [CGRect], limit: CGRect) {
        let lastRect = frame

        var rect = frame
        rect.origin.x = position - rect.width * 0.5
        if aroundRects.contains(where: { rect.intersects($0) }) {
            lastIntersectTime = Date()
        }
        let centerPriority = CGFloat(Date().timeIntervalSince1970 - lastIntersectTime.timeIntervalSince1970)

        var leftPriority: CGFloat = 1.0
        var rightPriority: CGFloat = 1.0

        var testRect = frame
        testRect.origin.x = limit.minX
        if aroundRects.contains(where: { testRect.intersects($0) }) {
            leftPriority = -1
        }

        testRect.origin.x = limit.maxX - frame.size.width
        if aroundRects.contains(where: { testRect.intersects($0) }) {
            rightPriority = -1
        }

        if leftPriority < 0 && rightPriority < 0 {
            setPosition(position, limit: limit)
            return
        }

        if leftPriority > 0 && rightPriority > 0 {
            leftPriority *= position / limit.width
            rightPriority *= (limit.width - position) / limit.width

            let lastCenter = 0.5 * lastRect.minX + 0.5 * lastRect.maxX
            let procentTranslate = (lastCenter - position) / lastRect.width
            leftPriority *= (procentTranslate < 0) ? 1 : procentTranslate
            rightPriority *= (procentTranslate > 0) ? 1 : -procentTranslate
        }

        if centerPriority > leftPriority && centerPriority > rightPriority {
            setPosition(position, limit: limit)
        } else {
            let subWidth = ((aroundRects.map{ $0.width }.max() ?? 0) + frame.width) * 0.5
            if leftPriority < rightPriority {
                setPosition(position + subWidth, limit: limit)
            } else {
                setPosition(position - subWidth, limit: limit)
            }
        }
    }

    private func setPosition(_ position: CGFloat, limit: CGRect) {
        center.x = position

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
