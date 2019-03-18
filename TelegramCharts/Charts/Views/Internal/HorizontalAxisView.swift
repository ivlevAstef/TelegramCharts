//
//  HorizontalAxisView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 17/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

private enum Consts {
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
        
        backgroundColor = .clear
    }
    
    internal func setStyle(_ style: ChartStyle) {
        color = style.textColor
    }
    
    internal func setFullInterval(_ interval: ChartViewModel.Interval) {
        fullInterval = interval
    }
    
    internal func update(aabb: AABB?, animated: Bool) {
        defer { setNeedsDisplay() }
        
        guard let aabb = aabb else {
            subviews.forEach { $0.removeFromSuperview() }
            return
        }

        updateLabels(aabb: aabb, animated: animated)
    }
    
    private func updateLabels(aabb: AABB, animated: Bool) {
        var prevLabels = dateLabels
        var newLabels: [UILabel] = []
        
        dateLabels.removeAll()
        // TODO: тут все переписываем (почти)
        // порядок такой:
        // 1. находим сколько всего максиум влазиет дат = (maxCount), на весь интервал (эта функция зависит от скейлинга)
        // 2. находим сколько максиум влазиет дат на экран = (maxScreenCount) (обычно 5-7, не зависит от масштаба)
        // 3. Полный интервал делеим на maxScreenCount равных частей (см. пункт 2)
        // 4. Делим maxCount на maxScreenCount и потом смотрим ближайшую наименьшую степень двойки. (55/6 = 9 -> 8 = 2^3)
        // 5. начинаем наши интервалы делить пополам пока не поделим их N раз, где N степерь двойки
        // 5 этап проще. - делим весь интервал на maxScreenCount и потом делим еще на значение степени двойки (8)
        // получаем расстояние между датами. После чего можно легко посчитать даты которые лежат в заданном интервале, ну или циклом пройтись и заполнить весь массив дат.

        // stride not works... WTF?
        let step: PolygonLine.Date = calculateStep(aabb: aabb)
        var iter = fullInterval.from
        while iter <= fullInterval.to {
            let date = iter
            iter += step

            let halfWidth = maxDateWidth * 0.5
            let dateCenter = aabb.calculateUIPoint(date: date, value: 0, rect: bounds).x
            if dateCenter + halfWidth <= self.bounds.minX || dateCenter - halfWidth >= self.bounds.maxX {
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
        
        if animated {
            newLabels.forEach { $0.alpha = 0.0 }
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
                prevLabels.forEach { $0.alpha = 0.0 }
                newLabels.forEach { $0.alpha = 1.0 }
            }, completion: { _ in
                prevLabels.forEach { $0.removeFromSuperview() }
            })
        } else {
            prevLabels.forEach { $0.removeFromSuperview() }
        }
        
       
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
        
        return ("Www 11" as NSString).size(withAttributes: attributes).width
    }()
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private class DateLabel: UILabel
{
    private static let dateFormatter: DateFormatter = {
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

    internal func setPosition(_ position: CGFloat, t: Double) {
        self.frame.origin = CGPoint(x: position - CGFloat(t) * self.frame.width, y: Consts.topPadding)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
