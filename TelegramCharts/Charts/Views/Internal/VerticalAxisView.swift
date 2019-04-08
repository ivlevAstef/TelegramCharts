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
    
    private var lastAABB: AABB?

    private let font: UIFont = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
    private var color: UIColor = .black
    private var lineColor: UIColor = .black

    private let bottomLine: UIView = UIView(frame: .zero)

    private var valueViews: [ValueView] = []

    internal init() {
        super.init(frame: .zero)

        clipsToBounds = true

        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLine)
    }

    internal func setStyle(_ style: ChartStyle) {
        color = style.textColor
        lineColor = style.linesColor
        bottomLine.backgroundColor = style.focusLineColor

        for subview in subviews.compactMap({ $0 as? ValueView }) {
            subview.setStyle(color: color, lineColor: lineColor)
        }
    }

    internal func update(aabb: AABB?, animated: Bool, duration: TimeInterval) {
        guard let aabb = aabb else {
            lastAABB = nil
            subviews.forEach { $0.removeFromSuperview() }
            valueViews.removeAll()
            return
        }

        updateValues(aabb: aabb, animated: animated, duration: duration)
        lastAABB = aabb
    }
    
    private func updateFrame() {
        self.bottomLine.frame = CGRect(x: 0, y: bounds.height - 1.0, width: bounds.width, height: 1.0)
        
        for subview in subviews.compactMap({ $0 as? ValueView }) {
            subview.setWidth(bounds.width)
        }
    }

    private func updateValues(aabb: AABB, animated: Bool, duration: TimeInterval) {
        func updatePositionOnSubviews() {
            for view in subviews.compactMap({ $0 as? ValueView }) {
                let position = aabb.calculateUIPoint(date: 0, value: view.value, rect: bounds).y
                view.setPosition(position, limits: bounds)
            }
        }

        let oldValues = valueViews.map { $0.value }
        let newValues = calculateNewValues(aabb: aabb)

        if !checkIsMoreDiff(oldValues, newValues) {
            UIView.animateIf(animated, duration: duration, options: .curveLinear, animations: {
                updatePositionOnSubviews()
            })
            return
        }

        var prevViews = valueViews
        var newViews: [ValueView] = []

        valueViews.removeAll()

        for value in newValues {
            let view: ValueView
            let unique = ValueView.makeUnique(Int64(value))

            if let prevView = prevViews.first, prevView.unique == unique {
                view = prevView
                prevViews.removeFirst()
            } else {
                view = ValueView(value: value, font: font, color: color, lineColor: lineColor, parentWidth: frame.width)
                let position = (lastAABB ?? aabb).calculateUIPoint(date: 0, value: value, rect: bounds).y
                view.setPosition(position, limits: bounds)

                addSubview(view)
                newViews.append(view)
            }
            valueViews.append(view)
        }

        newViews.forEach { $0.alpha = 0.0 }
        UIView.animateIf(animated, duration: duration, animations: {
            prevViews.forEach { $0.alpha = 0.0 }
            newViews.forEach { $0.alpha = 1.0 }
            updatePositionOnSubviews()
        }, completion: { _ in
            prevViews.forEach { $0.removeFromSuperview() }
        })
        
        UIView.animateIf(animated, duration: duration, options: .curveLinear, animations: {
            updatePositionOnSubviews()
        })
    }

    private func calculateNewValues(aabb: AABB) -> [Column.Value] {
        let begin = aabb.minValue
        let step = calculateValueStep(aabb: aabb)

        var result: [Column.Value] = []

        var value = begin
        for _ in 0..<valuesCount {
            result.append(value)
            value += step
        }

        return result
    }

    private func checkIsMoreDiff(_ oldValues: [Column.Value], _ newValues: [Column.Value]) -> Bool {
        if (oldValues.isEmpty || newValues.isEmpty) && oldValues.count != newValues.count {
            return true
        }

        var maxDiff = 0
        var minValue = Column.Value.max
        var maxValue = Column.Value.min
        for (old, new) in zip(oldValues, newValues) {
            maxDiff = max(maxDiff, abs(old - new))
            minValue = min(minValue, min(old, new))
            maxValue = max(maxValue, max(old, new))
        }

        if maxValue < minValue {
            return true
        }

        let interval = maxValue - minValue
        return Double(maxDiff) / Double(interval) > Configs.thresholdValueDiff
    }

    private func calculateValueStep(aabb: AABB) -> Column.Value {
        return (aabb.maxValue - aabb.minValue) / valuesCount
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

private class ValueView: UIView
{
    internal let unique: String
    internal let value: Column.Value

    private let label: UILabel = UILabel(frame: .zero)
    private let line: UIView = UIView(frame: .zero)

    internal init(value: Column.Value, font: UIFont, color: UIColor, lineColor: UIColor, parentWidth: CGFloat) {
        self.value = value
        self.unique = ValueView.makeUnique(Int64(value))

        super.init(frame: CGRect(x: 0, y: 0, width: parentWidth, height: 0))
        addSubview(label)
        addSubview(line)

        label.text = ValueView.abbreviationNumber(Int64(value))
        label.font = font
        label.textColor = color
        label.sizeToFit()

        frame.size.height = label.frame.height + 1

        line.frame = CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1)
        line.backgroundColor = lineColor
    }

    internal func setStyle(color: UIColor, lineColor: UIColor) {
        label.textColor = color
        line.backgroundColor = lineColor
    }
    
    internal func setWidth(_ width: CGFloat) {
        frame.size.width = width
        line.frame.size.width = width
    }

    internal func setPosition(_ position: CGFloat, limits: CGRect) {
        frame.origin = CGPoint(x: 0, y: position - frame.height)

        var limitOpacity: CGFloat = 1.0
        if frame.minY < limits.minY {
            limitOpacity = 0.0
        }
        if frame.maxY > limits.maxY {
            limitOpacity = 0.0
        }
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.label.alpha = limitOpacity
            self?.line.alpha = limitOpacity
        }
    }

    internal static func makeUnique(_ number: Int64) -> String {
        return abbreviationNumber(number)
    }

    private static func abbreviationNumber(_ number: Int64) -> String {
        if abs(number) < 1000 {
            return "\(number)"
        }

        let sign = number < 0 ? "-" : ""
        let number = abs(number)

        let exp = Int(log10(Double(number)) / 3.0)
        let units: [String] = ["K","M","B","T","q","Q","s","S"]

        let roundedNum: Double = round(10 * Double(number) / pow(1000.0, Double(exp))) / 10.0

        return "\(sign)\(roundedNum)\(units[exp - 1])"
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
