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
}

internal class VerticalAxisView: UIView
{
    override public var frame: CGRect {
        didSet { updateFrame() }
    }

    private let font: UIFont = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
    private var color: UIColor = .black
    private var lineColor: UIColor = .black
    private var chartViewModel: ChartViewModel?

    private let bottomLine: UIView = UIView(frame: .zero)

    private var leftLastAABB: AABB?
    private var rightLastAABB: AABB?
    private var leftValueViews: [ValueView<Left>] = []
    private var rightValueViews: [ValueView<Right>] = []

    internal init() {
        super.init(frame: .zero)

        clipsToBounds = true

        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLine)
    }
    
    internal func setChart(_ chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel
    }

    internal func setStyle(_ style: ChartStyle) {
        color = style.textColor
        lineColor = style.linesColor
        bottomLine.backgroundColor = style.focusLineColor

        for subview in subviews.compactMap({ $0 as? ValueViewProtocol }) {
            subview.setStyle(color: color, lineColor: lineColor)
        }
    }

    internal func update(aabb: AABB?, animated: Bool, duration: TimeInterval) {
        func cleanLeft() {
            leftLastAABB = nil
            leftValueViews.forEach { $0.removeFromSuperview() }
            leftValueViews.removeAll()
        }
        func cleanRight() {
            rightLastAABB = nil
            rightValueViews.forEach { $0.removeFromSuperview() }
            rightValueViews.removeAll()
        }
        
        guard let aabb = aabb else {
            cleanLeft()
            cleanRight()
            return
        }

        guard let chartViewModel = chartViewModel, chartViewModel.yScaled else {
            updateValues(aabb: aabb, lastAABB: leftLastAABB,
                         columnColor: nil, valueViews: &leftValueViews,
                         animated: animated, duration: duration)
            leftLastAABB = aabb
            return
        }
        
        // Support Y-Scaled...
        if let leftColumn = chartViewModel.columns.first, leftColumn.isVisible,
            let leftAABB = aabb.childs.first(where: { $0.id == leftColumn.id }) {
            updateValues(aabb: leftAABB, lastAABB: leftLastAABB,
                         columnColor: leftColumn.color, valueViews: &leftValueViews,
                         animated: animated, duration: duration)
            leftLastAABB = leftAABB
        } else {
            cleanLeft()
        }
        
        if let rightColumn = chartViewModel.columns.dropFirst().first, rightColumn.isVisible,
           let rightAABB = aabb.childs.first(where: { $0.id == rightColumn.id }) {
            updateValues(aabb: rightAABB, lastAABB: rightLastAABB,
                         columnColor: rightColumn.color, valueViews: &rightValueViews,
                         animated: animated, duration: duration)
            rightLastAABB = rightAABB
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

    private func updateValues<T>(aabb: AABB, lastAABB: AABB?, columnColor: UIColor?, valueViews: inout [ValueView<T>], animated: Bool, duration: TimeInterval) {
        let newValues = calculateNewValues(aabb: aabb)
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
                view = ValueView(value: value, font: font, color: color, lineColor: lineColor, parentWidth: frame.width)
                let position = (lastAABB ?? aabb).calculateUIPoint(date: 0, value: value, rect: bounds).y
                view.setPosition(position)

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
                let position = aabb.calculateUIPoint(date: 0, value: view.value, rect: bounds).y
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
    func setStyle(color: UIColor, lineColor: UIColor)
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
    private let line: UIView = UIView(frame: .zero)

    internal init(value: AABB.Value, font: UIFont, color: UIColor, lineColor: UIColor, parentWidth: CGFloat) {
        self.value = value
        self.unique = ValueView.makeUnique(Int64(value))

        super.init(frame: CGRect(x: 0, y: 0, width: parentWidth, height: 0))
        addSubview(label)
        addSubview(line)

        label.text = ValueView.abbreviationNumber(Int64(value))
        label.font = font
        label.textColor = color
        label.sizeToFit()
        label.frame.size.width = parentWidth
        
        if T.self is Right.Type {
            label.textAlignment = .right
        } else {
            label.textAlignment = .left
        }

        frame.size.height = label.frame.height + 1

        line.frame = CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1)
        line.backgroundColor = lineColor
    }

    internal func setStyle(color: UIColor, lineColor: UIColor) {
        label.textColor = columnColor ?? color
        line.backgroundColor = lineColor
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
