//
//  VerticalAxisView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 18/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

private enum Consts
{
    internal static let labelPadding: CGFloat = 2.0
}

internal final class VerticalAxisView: UIView
{
    override public var frame: CGRect {
        didSet { updateFrame() }
    }

    private let font: UIFont = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
    private var color: UIColor = .black
    private var lineColor: UIColor = .black
    private var shadowColor: UIColor = .white
    
    private let topOffset: CGFloat
    private var rect: CGRect = .zero

    private let bottomLine: UIView = UIView(frame: .zero)

    private var leftLastUI: ColumnUIModel?
    private var rightLastUI: ColumnUIModel?
    private var leftValueViews: [ValueView<Left>] = []
    private var rightValueViews: [ValueView<Right>] = []
    
    private let callFrequenceLimiter = CallFrequenceLimiter()

    internal init(topOffset: CGFloat) {
        self.topOffset = topOffset
        super.init(frame: .zero)

        clipsToBounds = true

        bottomLine.translatesAutoresizingMaskIntoConstraints = true
        addSubview(bottomLine)
    }

    internal func setStyle(_ style: ChartStyle) {
        color = style.textColor
        lineColor = style.linesColor
        shadowColor = style.textShadowColor
        bottomLine.backgroundColor = style.focusLineColor

        for subview in subviews.compactMap({ $0 as? ValueViewProtocol }) {
            subview.setStyle(color: color, lineColor: lineColor, shadowColor: shadowColor)
        }
    }

    internal func update(ui: ChartUIModel, animated: Bool, duration: TimeInterval) {
        callFrequenceLimiter.update { [weak self] in
            guard let `self` = self else {
                return DispatchTimeInterval.never
            }
            
            let isUpdated = self.updateLogic(ui: ui, animated: animated, duration: duration)
            return isUpdated ? DispatchTimeInterval.milliseconds(200) : DispatchTimeInterval.milliseconds(33)
        }
    }
    
    private func updateLogic(ui: ChartUIModel, animated: Bool, duration: TimeInterval) -> Bool {
        func cleanLeft() {
            leftLastUI = nil
            leftValueViews.forEach { $0.removeFromSuperview() }
            leftValueViews.removeAll()
        }
        func cleanRight() {
            rightLastUI = nil
            rightValueViews.forEach { $0.removeFromSuperview() }
            rightValueViews.removeAll()
        }
        
        let uniqueAABBs = Set(ui.columns.map { $0.aabb })
        let useTwoY = uniqueAABBs.count > 1
        let usedColumns = ui.columns.filter { $0.isVisible || useTwoY }
        
        var finalIsUpdated = false
        if let column = usedColumns.first, column.isVisible {
            let isUpdated = updateValues(ui: column, lastUI: leftLastUI,
                                         valueViews: &leftValueViews,
                                         columnColor: useTwoY ? column.color : nil,
                                         animated: animated, duration: duration)
            finalIsUpdated = finalIsUpdated || isUpdated
            leftLastUI = column
        } else {
            cleanLeft()
        }
        
        if let column = usedColumns.dropFirst().first, column.isVisible, useTwoY {
            let isUpdated = updateValues(ui: column, lastUI: rightLastUI,
                                         valueViews: &rightValueViews,
                                         columnColor: useTwoY ? column.color : nil,
                                         animated: animated, duration: duration)
            finalIsUpdated = finalIsUpdated || isUpdated
            rightLastUI = column
        } else {
            cleanRight()
        }
        
        return finalIsUpdated
    }
    
    private func updateFrame() {
        self.bottomLine.frame = CGRect(x: 0, y: bounds.height - 1.0, width: bounds.width, height: 1.0)
        self.rect = CGRect(x: 0, y: topOffset, width: bounds.width, height: bounds.height - topOffset)
        
        for subview in subviews.compactMap({ $0 as? ValueViewProtocol }) {
            subview.setWidth(bounds.width)
        }
    }

    private func updateValues<T>(ui: ColumnUIModel, lastUI: ColumnUIModel?,
                                 valueViews: inout [ValueView<T>], columnColor: UIColor?,
                                 animated: Bool, duration: TimeInterval) -> Bool {
        let prevViews = valueViews
        var oldViews = valueViews
        var equalViews: [ValueView<T>] = []
        var newViews: [ValueView<T>] = []

        valueViews.removeAll()

        for value in ui.verticalValues {
            let view: ValueView<T>
            let unique = ValueView<T>.makeUnique(Int64(value))

            if let oldViewIndex = oldViews.firstIndex(where: { $0.unique == unique }) {
                view = oldViews[oldViewIndex]
                view.updateValue(value)
                equalViews.append(view)
                oldViews.remove(at: oldViewIndex)
            } else {
                view = ValueView(value: value, font: font, parentWidth: rect.width)
                view.setStyle(color: color, lineColor: lineColor, shadowColor: shadowColor)
                view.position = ui.translate(value: value, to: rect)

                view.translatesAutoresizingMaskIntoConstraints = true
                addSubview(view)
                newViews.append(view)
            }
            view.columnColor = columnColor
            valueViews.append(view)
        }
        
        let prevSum = prevViews.map { $0.value }.reduce(0, +)
        let newSum = valueViews.map { $0.value }.reduce(0, +)
        
        var translateY = frame.height / (1.5 * CGFloat(ui.verticalValues.count))
        translateY = newSum > prevSum ? translateY : -translateY

        let translateAnimatedViews = equalViews.filter { abs($0.position - ui.translate(value: $0.value, to: rect)) > 0.1 }
        if translateAnimatedViews.count > 0 {
            let rect = self.rect
            UIView.animateIf(animated, duration: duration * 0.5, animations: {
                for view in translateAnimatedViews {
                    view.position = ui.translate(value: view.value, to: rect)
                }
            })
        }
        
        if oldViews.count > 0 {
            UIView.animateIf(animated, duration: duration, animations: {
                for view in oldViews {
                    view.alpha = 0.0
                    view.position = view.position + translateY
                }
            }, completion: { _ in
                oldViews.forEach { $0.removeFromSuperview() }
            })
        }
        
        if newViews.count > 0 {
            for view in newViews {
                view.alpha = 0.0
                view.position = view.position - translateY
            }
            UIView.animateIf(animated, duration: duration, animations: {
                for view in newViews {
                    view.alpha = 1.0
                    view.position = view.position + translateY
                }
            })
        }
        
        return !newViews.isEmpty || !oldViews.isEmpty || !translateAnimatedViews.isEmpty
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private final class Left {}
private final class Right {}

private protocol ValueViewProtocol {
    func setStyle(color: UIColor, lineColor: UIColor, shadowColor: UIColor)
    func setWidth(_ width: CGFloat)
}

private final class ValueView<T>: UIView, ValueViewProtocol
{
    internal private(set) var value: AABB.Value = 0
    internal private(set) var unique: Int64 = 0
    
    internal var position: CGFloat = 0 {
        didSet {
            frame.origin = CGPoint(x: 0, y: position - frame.height)
        }
    }
    
    internal var columnColor: UIColor? {
        didSet {
            // unwork in reverse.. :(
            label.textColor = columnColor ?? label.textColor
        }
    }

    private var labelSize: CGSize = .zero
    private let label: UILabel = UILabel(frame: .zero)
    private let shadow: UIView = UIView(frame: .zero)
    private let line: UIView = UIView(frame: .zero)

    internal init(value: AABB.Value, font: UIFont, parentWidth: CGFloat) {
        super.init(frame: CGRect(x: 0, y: 0, width: parentWidth, height: 0))
        updateValue(value)
        
        shadow.translatesAutoresizingMaskIntoConstraints = true
        addSubview(shadow)
        label.translatesAutoresizingMaskIntoConstraints = true
        addSubview(label)
        line.translatesAutoresizingMaskIntoConstraints = true
        addSubview(line)
        
        label.text = ValueView.abbreviationNumber(Int64(value))
        label.font = font
        label.sizeToFit()
        labelSize = label.frame.size
        shadow.frame = label.frame.inset(by: UIEdgeInsets(top: 2, left: -2, bottom: 2, right: -2))
        label.frame.origin.x = Consts.labelPadding
        label.frame.size.width = parentWidth - 2 * Consts.labelPadding
        
        let widthDiff = (shadow.frame.width - labelSize.width) * 0.5
        if T.self is Right.Type {
            label.textAlignment = .right
            shadow.frame.origin.x = parentWidth - labelSize.width - Consts.labelPadding - widthDiff
        } else {
            label.textAlignment = .left
            shadow.frame.origin.x = Consts.labelPadding - widthDiff
        }

        frame.size.height = label.frame.height + 1

        line.frame = CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1)
    }
    
    internal func updateValue(_ value: AABB.Value) {
        self.value = value
        self.unique = ValueView.makeUnique(Int64(value))
    }

    internal func setStyle(color: UIColor, lineColor: UIColor, shadowColor: UIColor) {
        label.textColor = columnColor ?? color
        line.backgroundColor = lineColor
        
        shadow.layer.cornerRadius = 5.0
        shadow.backgroundColor = shadowColor
    }
    
    internal func setWidth(_ width: CGFloat) {
        frame.size.width = width
        line.frame.size.width = width
        label.frame.size.width = width
        
        if T.self is Right.Type {
            let widthDiff = (shadow.frame.width - labelSize.width) * 0.5
            shadow.frame.origin.x = width - labelSize.width - Consts.labelPadding - widthDiff
        }
    }

    internal static func makeUnique(_ number: Int64) -> Int64 {
        let (roundedNum, exp) = simplifyNumber(number)
        return Int64((floor(10.0 * roundedNum) * pow(1000.0, Double(exp))) / 10.0)
    }

    private static func abbreviationNumber(_ number: Int64) -> String {
        let (roundedNum, exp) = simplifyNumber(number)
        if exp < 1 {
            return "\(number)"
        }

        let units: [String] = ["K","M","B","T","q","Q","s","S"]
        return "\(roundedNum)\(units[exp - 1])"
    }
    
    private static func simplifyNumber(_ number: Int64) -> (Double, Int) {
        if abs(number) < 1000 {
            return (Double(number), 0)
        }
        
        let exp = Int(log10(Double(abs(number))) / 3.0)
        let roundedNum: Double = round(10 * Double(number) / pow(1000.0, Double(exp))) / 10.0
        
        return (roundedNum, exp)
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
