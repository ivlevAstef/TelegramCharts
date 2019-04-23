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
    internal static let topPadding: CGFloat = 6.0
    internal static let minDateSpacing: CGFloat = 16.0
}


internal final class HorizontalAxisView: UIView
{
    private var fullInterval: ChartViewModel.Interval = ChartViewModel.Interval.empty
    
    private let font: UIFont = UIFont.systemFont(ofSize: 12.0)
    private var color: UIColor = .black
    
    private var dateLabels: [DateLabel] = []
    private var dateLabelCache: [Chart.Date: DateLabel] = [:]
    
    private let callFrequenceLimiter = CallFrequenceLimiter()
    
    internal init() {
        super.init(frame: .zero)
    }
    
    internal func setStyle(_ style: ChartStyle) {
        color = style.textColor
        backgroundColor = style.backgroundColor

        for subview in subviews.compactMap({ $0 as? DateLabel }) {
            subview.setStyle(color: color)
        }
        for label in dateLabelCache.values {
            label.setStyle(color: color)
        }
    }
    
    internal func update(ui: ChartUIModel, animated: Bool, duration: TimeInterval) {
        callFrequenceLimiter.update { [weak self] in
            self?.updateLogic(ui: ui, animated: animated, duration: duration)
            return DispatchTimeInterval.milliseconds(30)
        }
    }
    
    private func updateLogic(ui: ChartUIModel, animated: Bool, duration: TimeInterval) {
        func calcPosition(date: Chart.Date) -> (position: CGFloat, t: Double) {
            let t = Double(date - ui.fullInterval.from) / Double(ui.fullInterval.to - ui.fullInterval.from)
            let position = ui.translate(date: date, to: bounds)
            return (position, t)
        }
        
        var prevLabels = dateLabels
        var newLabels: [DateLabel] = []

        dateLabels.removeAll()

        // stride not works... WTF?
        let step: Chart.Date = calculateStep(ui: ui)
        // can optimization - calculate correct interval
        var iter = ui.fullInterval.from
        while iter <= ui.fullInterval.to {
            let date = iter
            let dateOfStr = DateLabel.string(by: date)
            iter += step

            let halfWidth = maxDateWidth * 0.5
            let dateCenter = ui.translate(date: date, to: bounds)
            if dateCenter + halfWidth <= bounds.minX - bounds.size.width * 0.5
            || dateCenter - halfWidth >= bounds.maxX + bounds.size.width * 0.5 {
                continue
            }

            let label: DateLabel
            if let index = prevLabels.firstIndex(where: { $0.unique == dateOfStr }) {
                label = prevLabels[index]
                label.date = date
                prevLabels.remove(at: index)
            } else {
                label = dateLabelCache[date] ?? DateLabel(date: date, dateOfStr: dateOfStr, font: font)
                label.setStyle(color: color)
                dateLabelCache[date] = label
                
                let (position, t) = calcPosition(date: date)
                label.setPosition(position, t: t)
                
                addSubview(label)
                newLabels.append(label)
            }

            dateLabels.append(label)
        }
        
        // update position for all labels
        UIView.animateIf(animated, duration: duration * 0.5, animations: { [subviews] in
            for label in subviews.compactMap({ $0 as? DateLabel }) {
                let (position, t) = calcPosition(date: label.date)
                label.setPosition(position, t: t)
            }
        })

        for label in newLabels {
            // out screen
            if label.frame.maxX < self.bounds.minX || self.bounds.maxX < label.frame.minX {
                label.alpha = 1.0
            } else {
                label.alpha = 0.0
            }
        }
        
        if prevLabels.count > 0 {
            UIView.animateIf(animated, duration: duration * 0.5, animations: {
                prevLabels.forEach { $0.alpha = 0.0 }
            }, completion: { _ in
                for label in prevLabels where label.alpha <= 0.01 {
                    label.removeFromSuperview()
                }
            })
        }

        if newLabels.count > 0 {
            UIView.animateIf(animated, duration: duration, animations: {
                newLabels.forEach { $0.alpha = 1.0 }
            })
        }
    }

    private func calculateStep(ui: ChartUIModel) -> Chart.Date {
        let div = calculateNearPowerTwoAndReturnNumber(ui: ui)
        return (ui.fullInterval.to - ui.fullInterval.from) / Chart.Date(div * minScreenCount)
    }

    private func calculateNearPowerTwoAndReturnNumber(ui: ChartUIModel) -> Int {
        let div: Int = Int(calculateMaxFullIntervalCount(ui: ui) / max(1, minScreenCount))
        // optimization - no!
        var iter: Int = 1
        while iter * 2 < div {
            iter = iter * 2
        }
        return iter
    }

    private func calculateMaxFullIntervalCount(ui: ChartUIModel) -> Int {
        let k = Double(ui.fullInterval.to - ui.fullInterval.from) / Double(ui.interval.to - ui.interval.from)
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

private var dateSizeCache: [String: CGSize] = [:]
private final class DateLabel: UILabel
{
    internal static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"
        return dateFormatter
    }()
    
    internal var date: Chart.Date
    internal let unique: String
    
    internal static func string(by date: Chart.Date) -> String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(date) / 1000.0))
    }
    
    internal init(date: Chart.Date, dateOfStr: String, font: UIFont) {
        self.date = date
        self.unique = dateOfStr
        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = true
        
        self.text = dateOfStr
        self.font = font

        if let size = dateSizeCache[dateOfStr] {
            self.frame.size = size
        } else {
            self.sizeToFit()
        }

        self.frame.origin.y = Consts.topPadding
    }

    internal func setStyle(color: UIColor) {
        self.textColor = color
    }

    internal func setPosition(_ position: CGFloat, t: Double) {
        let x = position - CGFloat(t) * self.frame.width
        if abs(x - self.frame.origin.x) >= 1.0 {
            self.frame.origin.x = x
        }
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
