//
//  HorizontalAxisView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 17/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

private enum Consts
{
    internal static let topPadding: CGFloat = 5.0
    internal static let minDateSpacing: CGFloat = 16.0
}


internal class HorizontalAxisView: UIView
{
    private var fullInterval: ChartViewModel.Interval = ChartViewModel.Interval.empty
    
    private let font: UIFont = UIFont.systemFont(ofSize: 12.0)
    private var color: UIColor = .black
    
    private var dateLabels: [DateLabel] = []
    
    internal init() {
        super.init(frame: .zero)
        
        self.clipsToBounds = true
    }
    
    internal func setStyle(_ style: ChartStyle) {
        color = style.textColor

        for subview in subviews.compactMap({ $0 as? DateLabel }) {
            subview.setStyle(color: color)
        }
    }
    
    internal func setFullInterval(_ interval: ChartViewModel.Interval) {
        fullInterval = interval
    }
    
    internal func update(aabb: AABB?, animated: Bool, duration: TimeInterval) {
        guard let aabb = aabb else {
            UIView.animateIf(animated, duration: duration, animations: { [weak self] in
                self?.subviews.forEach { $0.alpha = 0.0 }
            }, completion: { [weak self] _ in
                self?.subviews.forEach { $0.removeFromSuperview() }
            })
            dateLabels.removeAll()

            return
        }

        updateLabels(aabb: aabb, animated: animated, duration: duration)
    }
    
    private func updateLabels(aabb: AABB, animated: Bool, duration: TimeInterval) {
        var prevLabels = dateLabels
        var newLabels: [DateLabel] = []
        
        dateLabels.removeAll()

        // stride not works... WTF?
        let step: PolygonLine.Date = calculateStep(aabb: aabb)
        // can optimization - calculate correct interval
        var iter = fullInterval.from
        while iter <= fullInterval.to {
            let date = iter
            iter += step

            let halfWidth = maxDateWidth * 0.5
            let dateCenter = aabb.calculateUIPoint(date: date, value: 0, rect: bounds).x
            if dateCenter + halfWidth <= self.bounds.minX - self.bounds.size.width * 0.5
            || dateCenter - halfWidth >= self.bounds.maxX + self.bounds.size.width * 0.5 {
                continue
            }

            let label: DateLabel
            if let index = prevLabels.firstIndex(where: { $0.date == date }) {
                label = prevLabels[index]
                prevLabels.remove(at: index)
            } else {
                label = DateLabel(date: date, font: font, color: color)
                addSubview(label)
                newLabels.append(label)
            }

            dateLabels.append(label)
        }
        
        // update position for all labels
        for label in subviews.compactMap({ $0 as? DateLabel }) {
            let t = Double(label.date - fullInterval.from) / Double(fullInterval.to - fullInterval.from)
            let position = aabb.calculateUIPoint(date: label.date, value: 0, rect: bounds).x
            label.setPosition(position, t: t)
        }

        for label in newLabels {
            if label.frame.minX <= self.bounds.minX || label.frame.maxX >= self.bounds.maxX {
                label.alpha = 1.0
            } else {
                label.alpha = 0.0
            }
        }

        UIView.animateIf(animated, duration: duration * 0.5, animations: {
            prevLabels.forEach { $0.alpha = 0.0 }
        }, completion: { _ in
            prevLabels.forEach { $0.removeFromSuperview() }
        })

        UIView.animateIf(animated, duration: duration, animations: {
            newLabels.forEach { $0.alpha = 1.0 }
        })
    }

    private func calculateStep(aabb: AABB) -> PolygonLine.Date {
        let div = calculateNearPowerTwoAndReturnNumber(aabb: aabb)
        return (fullInterval.to - fullInterval.from) / PolygonLine.Date(div * minScreenCount)
    }

    private func calculateNearPowerTwoAndReturnNumber(aabb: AABB) -> Int {
        let div: Int = Int(calculateMaxFullIntervalCount(aabb: aabb) / minScreenCount)
        // optimization - no!
        var iter: Int = 1
        while iter * 2 < div {
            iter = iter * 2
        }
        return iter
    }

    private func calculateMaxFullIntervalCount(aabb: AABB) -> Int {
        let k = Double(fullInterval.to - fullInterval.from) / Double(aabb.maxDate - aabb.minDate)
        return Int(Double(maxScreenCount) * k)
    }

    private var minScreenCount: Int {
        return Int(round(self.frame.width / (maxDateWidth + Consts.minDateSpacing)))
    }

    private var maxScreenCount: Int {
        return Int(round(self.frame.width / maxDateWidth))
    }

    private lazy var maxDateWidth: CGFloat = {
        let attributes = [
            NSAttributedString.Key.font: font
        ]

        // 22 march
        let date = DateLabel.dateFormatter.string(from: Date(timeIntervalSince1970: 1553212800))
        return (date as NSString).size(withAttributes: attributes).width
    }()
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private class DateLabel: UILabel
{
    internal static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter
    }()
    
    internal let date: PolygonLine.Date
    
    internal init(date: PolygonLine.Date, font: UIFont, color: UIColor) {
        self.date = date
        super.init(frame: .zero)
        
        self.text = DateLabel.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(date) / 1000.0))
        self.font = font
        self.textColor = color
        self.sizeToFit()
    }

    internal func setStyle(color: UIColor) {
        self.textColor = color
    }

    internal func setPosition(_ position: CGFloat, t: Double) {
        self.frame.origin = CGPoint(x: position - CGFloat(t) * self.frame.width, y: Consts.topPadding)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
