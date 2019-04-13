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
    
    internal static let arrowSize: CGSize = CGSize(width: 8, height: 12)
    internal static let arrowOffset: CGSize = CGSize(width: 2, height: 2)
}

internal final class HintAndOtherView: UIView
{
    internal var hintClickHandler: ((Chart.Date) -> Void)?
    
    private let font: UIFont = UIFont.systemFont(ofSize: 12.0)
    private var color: UIColor = .black
    private var lineColor: UIColor = .black

    private var ui: ChartUIModel?
    private var lastDate: Chart.Date? = nil
    
    private var hideHintBlock: DispatchWorkItem?

    private let barsView: BarsView = BarsView()
    private let lineView: LineView = LineView()
    private let hintView: HintView = HintView(font: UIFont.systemFont(ofSize: 12.0),
                                              accentFont: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.medium))

    internal init() {
        super.init(frame: .zero)

        barsView.translatesAutoresizingMaskIntoConstraints = true
        // addSubview(barsView) -> setParent
        lineView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(lineView)
        hintView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(hintView)

        hide(hintView: true, lineView: true, barsView: true, animated: false)

        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        longGesture.minimumPressDuration = Configs.minimumPressDuration
        let tapHintGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnHintGesture(_:)))
        longGesture.require(toFail: tapHintGesture)
        
        self.addGestureRecognizer(longGesture)
        hintView.addGestureRecognizer(tapHintGesture)
    }

    internal func setParent(_ parent: UIView) {
        barsView.layer.zPosition = 111
        parent.addSubview(barsView)
    }
    internal func updateParentFrame(_ frame: CGRect) {
        barsView.frame = frame
    }

    internal func setStyle(_ style: ChartStyle) {
        lineView.lineColor = style.focusLineColor
        lineView.centerPointColor = style.dotColor
        hintView.backgroundColor = style.hintBackgroundColor
        hintView.arrowColor = style.hintArrowColor
        hintView.textColor = style.hintTextColor
        barsView.barColor = style.hintBarColor
    }

    internal func update(ui: ChartUIModel) {
        self.ui = ui
        
        if let date = lastDate {
            showHintAndOther(date: date, use: ui)
            hideAfter()
        }
    }

    @objc
    private func tapGesture(_ recognizer: UIGestureRecognizer) {
        touchProcessor(tapPosition: recognizer.location(in: self), state: recognizer.state)
    }
    
    @objc
    private func tapOnHintGesture(_ recognizer: UIGestureRecognizer) {
        if hintView.isHidden || hintView.alpha < 0.1 {
            return
        }
        hintClickHandler?(hintView.date)
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
            self.hideHintBlock?.cancel()
            let aroundDate = ui.translate(x: tapPosition.x, from: bounds)
            let date = ui.find(around: aroundDate, in: ui.interval)
            lastDate = date
            showHintAndOther(date: date, use: ui)
        default:
            hideAfter()
        }
    }
    
    private func hideAfter() {
        self.hideHintBlock?.cancel()
        let hideHintBlock = DispatchWorkItem { [weak self] in
            self?.hide(hintView: true, lineView: true, barsView: true)
            self?.lastDate = nil
        }
        self.hideHintBlock = hideHintBlock
        DispatchQueue.main.asyncAfter(deadline: .now() + Configs.hintAutoHideDelay, execute: hideHintBlock)
    }

    private func showHintAndOther(date: Chart.Date, use ui: ChartUIModel) {
        let animated = showHint(in: date, use: ui)
        let lineRect = showLineIfNeeded(in: date, use: ui)
        let barsRect = showBarsIfNeeded(in: date, use: ui)
        updateHintPosition(in: date, use: ui, animated: animated, aroundRects: [lineRect, barsRect])
    }

    private func showHint(in date: Chart.Date, use ui: ChartUIModel) -> Bool {
        let rows = ui.columns.enumerated().compactMap { (index, column) -> (UIColor, String, ColumnViewModel.Value, Int)? in
            if let value = column.find(by: date)?.original, column.isVisible {
                return (column.color, column.name, value, index)
            }
            return nil
        }

        let animated = needAnimated(hintView)
        hintView.isHidden = false
        let percentage = ui.percentage
        
        hintView.preRows(rows, percentage: percentage)
        UIView.animateIf(animated, duration: Configs.hintDuration * 0.5, animations: { [weak self] in
            self?.hintView.setDate(date)
            self?.hintView.setRows(rows, percentage: percentage)
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

        //let animated = needAnimated(lineView)
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

        //let animated = needAnimated(barsView)
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
            centerView.translatesAutoresizingMaskIntoConstraints = true
            addSubview(centerView)

            translatesAutoresizingMaskIntoConstraints = true
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
        lineView.translatesAutoresizingMaskIntoConstraints = true
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
        //let position = max(limit.minX, min(position, limit.maxX - 1))
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

        leftView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(leftView)
        rightView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(rightView)
    }

    internal func setBars(minY: CGFloat, width: CGFloat) {
        self.width = width
        self.minY = minY
    }

    internal func setPosition(_ position: CGFloat, limit: CGRect) {
        var position = position
        //var position = max(limit.minX, min(position, limit.maxX))
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

extension UILabel {
    func maxSizeToFit() {
        let size = self.frame.size
        sizeToFit()
        if size.width != self.frame.width {
            self.frame.size.width = max(size.width, self.frame.width)
        }
        if size.height != self.frame.height {
            self.frame.size.height = max(size.height, self.frame.height)
        }
    }
}

private class HintView: UIView
{
    private class Row: UIView {
        internal let id: Int
        
        internal let percentageLabel: UILabel?
        internal let leftLabel: UILabel = UILabel(frame: .zero)
        internal let rightLabel: UILabel = UILabel(frame: .zero)

        internal init(id: Int, accentFont: UIFont, font: UIFont, percentage: Bool, parent: UIView) {
            self.id = id
            self.percentageLabel = percentage ? UILabel(frame: .zero) : nil
            
            super.init(frame: .zero)
            
            leftLabel.font = font
            rightLabel.font = accentFont
            rightLabel.textAlignment = .right
            percentageLabel?.font = accentFont
            
            leftLabel.translatesAutoresizingMaskIntoConstraints = true
            addSubview(leftLabel)
            rightLabel.translatesAutoresizingMaskIntoConstraints = true
            addSubview(rightLabel)
            percentageLabel?.translatesAutoresizingMaskIntoConstraints = true
            if let percentageLabel = percentageLabel {
                addSubview(percentageLabel)
            }

            translatesAutoresizingMaskIntoConstraints = true
            parent.addSubview(self)
        }
        
        internal func minWidth() -> CGFloat {
            let percentageAddWidth = percentageLabel.flatMap { $0.frame.width + 2 } ?? CGFloat(0)
            return leftLabel.frame.width + Consts.hintHorizontalSpace + rightLabel.frame.width + percentageAddWidth
        }
        
        internal func height() -> CGFloat {
            let percentageHeight = percentageLabel.flatMap { $0.frame.height } ?? CGFloat(0)
            return max(percentageHeight, max(leftLabel.frame.height, rightLabel.frame.height))
        }
        
        internal func setWidth(_ width: CGFloat) {
            self.frame.size = CGSize(width: width, height: height())
            percentageLabel?.frame.origin = .zero
            
            leftLabel.frame.origin.x = (percentageLabel.flatMap { $0.frame.maxX + 2 } ?? 0)
            rightLabel.frame.origin.x = width - rightLabel.frame.width
        }

        internal required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    internal static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy"
        return dateFormatter
    }()
    
    internal var arrowColor: UIColor = .white {
        didSet {
            arrowView.tintColor = arrowColor
        }
    }
    
    internal private(set) var date: Chart.Date = 0

    internal var textColor: UIColor = .black
    private let font: UIFont
    private let accentFont: UIFont

    private let dateLabel: UILabel = UILabel(frame: .zero)
    private let arrowView: UIImageView = ArrowView(reverse: true, size: Consts.arrowSize, offset: Consts.arrowOffset)
    private var rowsView: [Row] = []
    private var lastIntersectTime: Date = Date()
    
    private var maxTopX: CGFloat = 0.0

    internal init(font: UIFont, accentFont: UIFont) {
        self.font = font
        self.accentFont = accentFont
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

        layer.cornerRadius = Consts.hintCornerRadius
        frame.origin.y = Consts.hintYOffset

        dateLabel.translatesAutoresizingMaskIntoConstraints = true
        self.addSubview(dateLabel)
        
        arrowView.translatesAutoresizingMaskIntoConstraints = true
        self.addSubview(arrowView)
    }

    internal func setDate(_ date: Chart.Date) {
        self.date = date
        let date = Date(timeIntervalSince1970: TimeInterval(date) / 1000.0)
        let dateOfStr = HintView.dateFormatter.string(from: date)
        dateLabel.font = accentFont
        dateLabel.text = dateOfStr
        dateLabel.textColor = textColor
        dateLabel.frame.origin = CGPoint(x: Consts.innerHintPadding, y: Consts.innerHintPadding)
        dateLabel.maxSizeToFit()
        
        arrowView.center.y = dateLabel.center.y
        
        maxTopX = max(maxTopX, dateLabel.frame.maxX + Consts.hintHorizontalSpace + arrowView.frame.width)
    }
    
    internal func preRows(_ rows: [(color: UIColor, name: String, value: ColumnViewModel.Value, id: Int)], percentage: Bool) {
        let oldRowsView = rowsView
        rowsView.removeAll()
        for (_, _, _, id) in rows {
            let foundRow = oldRowsView.first(where: { $0.id == id })
            let rowView = foundRow ?? Row(id: id, accentFont: accentFont, font: font, percentage: percentage, parent: self)
            
            rowsView.append(rowView)
        }
        
        for row in oldRowsView {
            if !rowsView.contains(where: { $0.id == row.id }) {
                row.removeFromSuperview()
            }
        }
        
        var yPosition = dateLabel.frame.maxY + Consts.hintLabelsSpace
        for row in rowsView {
            row.frame.origin = CGPoint(x: Consts.innerHintPadding, y: yPosition)
            var size = CGSize(width: maxTopX - Consts.innerHintPadding, height: row.height())
            size.width = max(size.width, row.frame.width)
            size.height = max(size.height, row.frame.height)
            row.frame.size = size
            yPosition = row.frame.maxY + Consts.hintLabelsSpace
        }
    }

    internal func setRows(_ rows: [(color: UIColor, name: String, value: ColumnViewModel.Value, id: Int)], percentage: Bool) {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        var rightX = maxTopX

        let sum: Double = rows.map { Double($0.value) }.reduce(Double(0), +)
        
        for (color, name, value, id) in rows {
            guard let rowView = rowsView.first(where: { $0.id == id }) else {
                assert(false, "call pre rows")
                continue
            }

            rowView.rightLabel.text = numberFormatter.string(from: NSNumber(value: value))
            rowView.rightLabel.textColor = color
            rowView.rightLabel.maxSizeToFit()
            
            rowView.leftLabel.text = name
            rowView.leftLabel.textColor = textColor
            rowView.leftLabel.maxSizeToFit()
            
            rowView.percentageLabel?.text = "\(Int(round(100.0 * Double(value) / sum)))%"
            rowView.percentageLabel?.textColor = textColor
            rowView.percentageLabel?.maxSizeToFit()

            rightX = max(rightX, Consts.innerHintPadding + rowView.minWidth())
        }

        var maxY = dateLabel.frame.maxY
        var yPosition = dateLabel.frame.maxY + Consts.hintLabelsSpace
        for row in rowsView {
            row.frame.origin = CGPoint(x: Consts.innerHintPadding, y: yPosition)
            row.setWidth(rightX - Consts.innerHintPadding)
            
            yPosition = row.frame.maxY + Consts.hintLabelsSpace
            maxY = max(row.frame.maxY, maxY)
        }

        arrowView.frame.origin.x = rightX - arrowView.frame.width
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
