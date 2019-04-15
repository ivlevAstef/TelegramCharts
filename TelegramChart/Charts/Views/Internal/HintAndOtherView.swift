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
    internal static let pointSize: CGFloat = 8

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
    
    internal var dateIsChangedHandler: ((Chart.Date?) -> Void)?
    internal private(set) var currentDate: Chart.Date? = nil {
        willSet {
            if newValue != currentDate {
                dateIsChangedHandler?(newValue)
            }
        }
    }
    
    private let font: UIFont = UIFont.systemFont(ofSize: 12.0)
    private var color: UIColor = .black
    private var lineColor: UIColor = .black

    private let callFrequenceLimiter = CallFrequenceLimiter()

    private var ui: ChartUIModel?
    
    private var hideHintBlock: DispatchWorkItem?
    private let hintView: HintView = HintView(font: UIFont.systemFont(ofSize: 12.0),
                                              accentFont: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.medium))

    internal init() {
        super.init(frame: .zero)

        hintView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(hintView)

        hide(animated: false)

        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        longGesture.minimumPressDuration = Configs.minimumPressDuration
        let tapHintGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnHintGesture(_:)))
        longGesture.require(toFail: tapHintGesture)
        
        self.addGestureRecognizer(longGesture)
        hintView.addGestureRecognizer(tapHintGesture)
    }

    internal func setStyle(_ style: ChartStyle) {
        hintView.backgroundColor = style.hintBackgroundColor
        hintView.arrowColor = style.hintArrowColor
        hintView.textColor = style.hintTextColor

        if let ui = self.ui {
            update(ui: ui)
        }
    }

    internal func update(ui: ChartUIModel) {
        self.ui = ui
        
        if let date = currentDate {
            showHint(in: date, use: ui)
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
            hide()
            return
        }
        
        switch state {
        case .began:
            fallthrough
        case .changed:
            self.hideHintBlock?.cancel()
            let aroundDate = ui.translate(x: tapPosition.x, from: bounds)
            let date = ui.find(around: aroundDate, in: ui.interval)
            currentDate = date
            callFrequenceLimiter.update { [weak self] in
                self?.showHint(in: date, use: ui)
                return DispatchTimeInterval.milliseconds(30)
            }

        default:
            hideAfter()
        }
    }
    
    private func hideAfter() {
        self.hideHintBlock?.cancel()
        let hideHintBlock = DispatchWorkItem { [weak self] in
            self?.hide()
            self?.currentDate = nil
        }
        self.hideHintBlock = hideHintBlock
        DispatchQueue.main.asyncAfter(deadline: .now() + Configs.hintAutoHideDelay, execute: hideHintBlock)
    }

    private func showHint(in date: Chart.Date, use ui: ChartUIModel) {
        var rows = ui.columns.enumerated().compactMap { (index, column) -> (UIColor?, String, ColumnViewModel.Value, Int)? in
            if let value = column.find(by: date)?.original, column.isVisible {
                return (column.color, column.name, value, index)
            }
            return nil
        }
        
        if ui.stacked && !ui.percentage {
            let sum = rows.map { $0.2 }.reduce(0, +)
            rows.append((nil, "All", sum, ui.columns.count))
        }

        let position = ui.translate(date: date, to: bounds)

        let animated = needAnimated(hintView)
        hintView.isHidden = false
        let percentage = ui.percentage

        hintView.preRows(rows, percentage: percentage)
        UIView.animateIf(animated, duration: Configs.hintDuration, animations: { [weak self] in
            self?.hintView.setDate(date)
            self?.hintView.setRows(rows, percentage: percentage)
        })

        if hintView.alpha < 1.0 {
            UIView.animateIf(true, duration: Configs.hintDuration, animations: { [weak self] in
                self?.hintView.alpha = 1.0
            })
        }

        var minY = bounds.height
        for column in ui.columns {
            if let data = column.find(by: date).flatMap({ column.translate(data: $0, to: bounds) }) {
                minY = min(minY, min(data.to.y, data.from.y))
            }
        }

        let date1Pos = ui.translate(date: ui.dates[0], to: bounds)
        let date2Pos = ui.translate(date: ui.dates[1], to: bounds)
        let width = max(Consts.pointSize, (date2Pos - date1Pos))
        var rect = CGRect(x: position - width * 0.5, y: minY, width: width, height: bounds.height - minY)
        rect = rect.insetBy(dx: -4, dy: 0)

        var limit = bounds
        let minWidth = rect.width + 2 * hintView.frame.width
        if limit.size.width < minWidth {
            limit.origin.x = (limit.size.width - minWidth) * 0.5
            limit.size.width = minWidth
        }

        UIView.animateIf(animated, duration: Configs.hintPositionDuration, animations: { [weak self] in
            self?.hintView.setPosition(position, aroundRect: rect, limit: limit)
        })

    }

    private func needAnimated(_ view: UIView) -> Bool {
        return false == view.isHidden && view.alpha > 0.01
    }

    private func hide(animated: Bool = true) {
        UIView.animateIf(animated, duration: Configs.hintDuration, animations: { [weak self] in
            guard let `self` = self else {
                return
            }
            if 0.0 != self.hintView.alpha {
                self.hintView.alpha = 0.0
            }
        }, completion: { [weak self] _ in
            self?.hintView.isHidden = true
        })
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Character {
    func length() -> Double {
        let symbol = "\(self)"
        if let number = Int(symbol) {
            if 1 == number {
                return 8
            }
            return 10
        }

        return 10
    }
}

extension String {
    func length() -> Double {
        var result: Double = 0
        for symbol in self {
            result += symbol.length()
        }
        return result
    }
}

class OptimizeUILabel: UILabel {
    private var maxTextLength: Double = 0
    
    func optimizeReText(_ text: String?) {
        if self.text == text {
            return
        }
        
        self.text = text
        if let length = text?.length(), length >= maxTextLength {
            maxTextLength = length
            maxSizeToFit()
        }
    }
    
    private func maxSizeToFit() {
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

private final class HintView: UIView
{
    private final class Row: UIView {
        internal let id: Int
        
        internal let percentageLabel: OptimizeUILabel?
        internal let leftLabel: OptimizeUILabel = OptimizeUILabel(frame: .zero)
        internal let rightLabel: OptimizeUILabel = OptimizeUILabel(frame: .zero)

        internal init(id: Int, accentFont: UIFont, font: UIFont, percentage: Bool, parent: UIView) {
            self.id = id
            self.percentageLabel = percentage ? OptimizeUILabel(frame: .zero) : nil
            
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

    private let dateLabel: OptimizeUILabel = OptimizeUILabel(frame: .zero)
    private let arrowView: UIImageView = ArrowView(reverse: true, size: Consts.arrowSize, offset: Consts.arrowOffset)
    private var rowsView: [Row] = []
    private var lastIntersectTime: Date = Date()
    
    private var maxTopX: CGFloat = 0.0

    internal init(font: UIFont, accentFont: UIFont) {
        self.font = font
        self.accentFont = accentFont
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.isOpaque = true

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
        dateLabel.optimizeReText(dateOfStr)
        dateLabel.textColor = textColor
        dateLabel.frame.origin = CGPoint(x: Consts.innerHintPadding, y: Consts.innerHintPadding)
        
        arrowView.center.y = dateLabel.center.y
        
        maxTopX = max(maxTopX, dateLabel.frame.maxX + Consts.hintHorizontalSpace + arrowView.frame.width)
    }
    
    internal func preRows(_ rows: [(color: UIColor?, name: String, value: ColumnViewModel.Value, id: Int)], percentage: Bool) {
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

    internal func setRows(_ rows: [(color: UIColor?, name: String, value: ColumnViewModel.Value, id: Int)], percentage: Bool) {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        var rightX = maxTopX

        let sum: Double = rows.map { Double($0.value) }.reduce(Double(0), +)
        
        for (color, name, value, id) in rows {
            guard let rowView = rowsView.first(where: { $0.id == id }) else {
                assert(false, "call pre rows")
                continue
            }

            rowView.rightLabel.optimizeReText(numberFormatter.string(from: NSNumber(value: value)))
            rowView.rightLabel.textColor = color ?? textColor
            
            rowView.leftLabel.optimizeReText(name)
            rowView.leftLabel.textColor = textColor
            
            rowView.percentageLabel?.optimizeReText("\(Int(round(100.0 * Double(value) / sum)))%")
            rowView.percentageLabel?.textColor = textColor

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

    internal func setPosition(_ position: CGFloat, aroundRect: CGRect, limit: CGRect) {
        let lastRect = frame

        var rect = frame
        rect.origin.x = position - rect.width * 0.5
        if aroundRect.intersects(rect) {
            lastIntersectTime = Date()
        }
        let centerPriority = CGFloat(Date().timeIntervalSince1970 - lastIntersectTime.timeIntervalSince1970)

        var leftPriority: CGFloat = 1.0
        var rightPriority: CGFloat = 1.0

        var testRect = frame
        testRect.origin.x = limit.minX
        if aroundRect.intersects(testRect) {
            leftPriority = -1
        }

        testRect.origin.x = limit.maxX - frame.size.width
        if aroundRect.intersects(testRect) {
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
            leftPriority *= (procentTranslate < 0) ? 1 : max(0.05, abs(procentTranslate))
            rightPriority *= (procentTranslate > 0) ? 1 : max(0.05, abs(procentTranslate))
        }

        if centerPriority > leftPriority && centerPriority > rightPriority {
            setPosition(position, limit: limit)
        } else {
            let subWidth = (aroundRect.width + frame.width) * 0.5
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
