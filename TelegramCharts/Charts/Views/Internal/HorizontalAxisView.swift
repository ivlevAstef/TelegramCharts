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
}


internal class HorizontalAxisView: UIView
{
    private var fullInterval: ChartViewModel.Interval = ChartViewModel.Interval.empty
    private var dates: [PolygonLine.Date] = []
    private var aabb: AABB?
    
    private let font: UIFont = UIFont.systemFont(ofSize: 12.0)
    private var color: UIColor = .black
    
    private var dateLabels: [DateLabel] = []
    
    internal init() {
        super.init(frame: .zero)
        
        backgroundColor = .clear
    }
    
    public func setStyle(_ style: ChartStyle) {
        color = style.textColor
    }
    
    internal func setFullInterval(_ interval: ChartViewModel.Interval) {
        fullInterval = interval
    }
    
    internal func update(aabb: AABB?, animated: Bool) {
        defer { setNeedsDisplay() }
        
        dates.removeAll()
        self.aabb = aabb
        
        guard let aabb = aabb else {
            return
        }
        
        fillDates(aabb: aabb)
        updateLabels(aabb: aabb, animated: animated)
    }
    
    private func updateLabels(aabb: AABB, animated: Bool) {
        var prevLabels = dateLabels
        var newLabels: [UILabel] = []
        
        dateLabels.removeAll()
        
        for date in dates {
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
            let dateCenter = aabb.calculateUIPoint(date: label.date, value: 0, rect: bounds).x
            label.center = CGPoint(x: dateCenter, y: Consts.topPadding)
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
    
    private func fillDates(aabb: AABB) {
        let datesCount = Double(self.frame.width / maxDateWidth)
        let dateSize = Double(aabb.dateInterval) / datesCount
        
        if dateSize < 1 {
            return
        }

        let begin = fullInterval.from
        let end = fullInterval.to

        let countDatesOnFullInterval: Int = Int(Double(end - begin) / (1.5 * dateSize))
        let step = (end - begin) / PolygonLine.Date(countDatesOnFullInterval)

        // stride not works... WTF?
        var iter = begin
        while iter <= end {
            iter = iter - iter % (60 * 60 * 24 * 1000)
            dates.append(iter)
            iter += step
        }
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
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
