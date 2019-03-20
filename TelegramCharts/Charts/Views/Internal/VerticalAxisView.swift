//
//  VerticalAxisView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 18/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

private enum Consts
{
    internal static let maxValuesCount: Int = 6
    internal static let minValueSpacing: CGFloat = 8.0
}

internal class VerticalAxisView: UIView
{
    private var lastAABB: AABB?

    private let font: UIFont = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
    private var color: UIColor = .black
    private var lineColor: UIColor = .black

    private let bottomLine: UIView = UIView(frame: .zero)

    private var valueViews: [ValueView] = []

    internal init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = true

        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLine)
        makeConstraints()
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

    private func makeConstraints() {
        self.bottomLine.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        self.bottomLine.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.bottomLine.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.bottomLine.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
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
            if animated {
                UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
                    updatePositionOnSubviews()
                })
            } else {
                updatePositionOnSubviews()
            }
            return
        }

        var prevViews = valueViews
        var newViews: [ValueView] = []

        valueViews.removeAll()

        for value in newValues {
            let view: ValueView

            if let prevView = prevViews.first, prevView.value == value {
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

        if animated {
            newViews.forEach { $0.alpha = 0.0 }

            UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
                prevViews.forEach { $0.alpha = 0.0 }
                newViews.forEach { $0.alpha = 1.0 }
                updatePositionOnSubviews()
            }, completion: { _ in
                prevViews.forEach { $0.removeFromSuperview() }
            })
        } else {
            prevViews.forEach { $0.removeFromSuperview() }
            updatePositionOnSubviews()
        }
    }

    private func calculateNewValues(aabb: AABB) -> [PolygonLine.Value] {
        let begin = aabb.minValue
        let step = calculateValueStep(aabb: aabb)

        var result: [PolygonLine.Value] = []

        var value = begin
        for _ in 0..<valuesCount {
            result.append(value)
            value += step
        }

        return result
    }

    private func checkIsMoreDiff(_ oldValues: [PolygonLine.Value], _ newValues: [PolygonLine.Value]) -> Bool {
        if (oldValues.isEmpty || newValues.isEmpty) && oldValues.count != newValues.count {
            return true
        }

        var maxDiff = 0
        var minValue = PolygonLine.Value.max
        var maxValue = PolygonLine.Value.min
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

    private func calculateValueStep(aabb: AABB) -> PolygonLine.Value {
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
    internal let value: PolygonLine.Value

    private let label: UILabel = UILabel(frame: .zero)
    private let line: UIView = UIView(frame: .zero)

    internal init(value: PolygonLine.Value, font: UIFont, color: UIColor, lineColor: UIColor, parentWidth: CGFloat) {
        self.value = value

        super.init(frame: CGRect(x: 0, y: 0, width: parentWidth, height: 0))
        addSubview(label)
        addSubview(line)

        label.text = abbreviationNumber(Int64(value))
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

    internal func setPosition(_ position: CGFloat, limits: CGRect) {
        frame.origin = CGPoint(x: 0, y: position - frame.height)

        let topLimitOpacity = max(0, (limits.minY - frame.minY) / frame.height)
        let bottomLimitOpacity = max(0, (frame.maxY - limits.maxY) / frame.height)

        // pow for more opacity
        let limitOpacity = pow(1.0 - min(max(topLimitOpacity, bottomLimitOpacity), 1.0), 2.0)

        label.alpha = limitOpacity
        line.alpha = limitOpacity
    }

    private func abbreviationNumber(_ number: Int64) -> String {
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
