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
    internal static let maxValuesCount: Int = 6
    internal static let minValueSpacing: CGFloat = 8.0
    internal static let labelPadding: CGFloat = 2.0
}

internal class VerticalAxisView: UIView
{
    override public var frame: CGRect {
        didSet { updateFrame() }
    }

    private let font: UIFont = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
    private var color: UIColor = .black
    private var lineColor: UIColor = .black
    private var shadowColor: UIColor = .white

    private let bottomLine: UIView = UIView(frame: .zero)

    private var leftLastUI: ColumnUIModel?
    private var rightLastUI: ColumnUIModel?
    private var leftValueViews: [ValueView<Left>] = []
    private var rightValueViews: [ValueView<Right>] = []

    internal init() {
        super.init(frame: .zero)

        clipsToBounds = true

        bottomLine.translatesAutoresizingMaskIntoConstraints = false
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
        
        
        if let column = usedColumns.first, column.isVisible {
            updateValues(ui: column, lastUI: leftLastUI,
                         valueViews: &leftValueViews, columnColor: useTwoY ? column.color : nil,
                         animated: animated, duration: duration)
            leftLastUI = column
        } else {
            cleanLeft()
        }
        
        if let column = usedColumns.dropFirst().first, column.isVisible, useTwoY {
            updateValues(ui: column, lastUI: rightLastUI,
                         valueViews: &rightValueViews, columnColor: useTwoY ? column.color : nil,
                         animated: animated, duration: duration)
            rightLastUI = column
        } else {
            cleanRight()
        }
    }
    
    private func updateFrame() {
        self.bottomLine.frame = CGRect(x: 0, y: bounds.height - 1.0, width: bounds.width, height: 1.0)
        
        for subview in subviews.compactMap({ $0 as? ValueViewProtocol }) {
            subview.setWidth(bounds.width)
        }
    }

    private func updateValues<T>(ui: ColumnUIModel, lastUI: ColumnUIModel?,
                                 valueViews: inout [ValueView<T>], columnColor: UIColor?,
                                 animated: Bool, duration: TimeInterval) {
        
        let newValues = calculateNewValues(aabb: ui.aabb)
        var prevViews = valueViews
        var newViews: [ValueView<T>] = []

        valueViews.removeAll()

        for value in newValues {
            let view: ValueView<T>
            let unique = ValueView<T>.makeUnique(Int64(value))

            if let prevViewIndex = prevViews.firstIndex(where: { $0.unique == unique }) {
                view = prevViews[prevViewIndex]
                prevViews.remove(at: prevViewIndex)
            } else {
                view = ValueView(value: value, font: font, parentWidth: frame.width)
                view.setStyle(color: color, lineColor: lineColor, shadowColor: shadowColor)
                let position = (lastUI ?? ui).translate(value: value, to: bounds)
                view.setPosition(position)

                view.translatesAutoresizingMaskIntoConstraints = false
                addSubview(view)
                newViews.append(view)
            }
            view.columnColor = columnColor
            valueViews.append(view)
        }

        newViews.forEach { $0.alpha = 0.0 }
        UIView.animateIf(animated, duration: duration, animations: {
            prevViews.forEach { $0.alpha = 0.0 }
            newViews.forEach { $0.alpha = 1.0 }
        }, completion: { _ in
            prevViews.forEach { $0.removeFromSuperview() }
        })

        func updatePositionOnSubviews() {
            for view in subviews.compactMap({ $0 as? ValueView<T> }) {
                let position = ui.translate(value: view.value, to: bounds)
                view.setPosition(position)
            }
        }

        UIView.animateIf(animated, duration: duration, options: .curveLinear, animations: {
            updatePositionOnSubviews()
        })
    }

    private func calculateNewValues(aabb: AABB) -> [AABB.Value] {
        let begin = aabb.minValue
        let step = (aabb.maxValue - aabb.minValue) / Double(valuesCount)

        var result: [AABB.Value] = []

        var value = begin
        for _ in 0..<valuesCount {
            result.append(value)
            value += step
        }

        return result
    }

    private var valuesCount: Int {
        return min(Consts.maxValuesCount, Int(frame.height / (valueHeight + Consts.minValueSpacing)))
    }

    private lazy var valueHeight: CGFloat = {
        let attributes = [
            NSAttributedString.Key.font: font
        ]

        return ("1" as NSString).size(withAttributes: attributes).height
    }()

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private class Left {}
private class Right {}

private protocol ValueViewProtocol {
    func setStyle(color: UIColor, lineColor: UIColor, shadowColor: UIColor)
    func setWidth(_ width: CGFloat)
}

private class ValueView<T>: UIView, ValueViewProtocol
{
    internal let value: AABB.Value
    internal let unique: Int64
    
    internal var columnColor: UIColor? {
        didSet {
            // unwork in reverse.. :(
            label.textColor = columnColor ?? label.textColor
        }
    }

    private let label: UILabel = UILabel(frame: .zero)
    private let shadow: UIView = UIView(frame: .zero)
    private let line: UIView = UIView(frame: .zero)

    internal init(value: AABB.Value, font: UIFont, parentWidth: CGFloat) {
        self.value = value
        self.unique = ValueView.makeUnique(Int64(value))

        super.init(frame: CGRect(x: 0, y: 0, width: parentWidth, height: 0))
        shadow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shadow)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        
        label.text = ValueView.abbreviationNumber(Int64(value))
        label.font = font
        label.sizeToFit()
        let labelSize = label.frame.size
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

    internal func setStyle(color: UIColor, lineColor: UIColor, shadowColor: UIColor) {
        label.textColor = columnColor ?? color
        line.backgroundColor = lineColor
        
        shadow.layer.cornerRadius = 5.0
        shadow.backgroundColor = shadowColor
    }
    
    internal func setWidth(_ width: CGFloat) {
        frame.size.width = width
        line.frame.size.width = width
    }

    internal func setPosition(_ position: CGFloat) {
        frame.origin = CGPoint(x: 0, y: position - frame.height)
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
