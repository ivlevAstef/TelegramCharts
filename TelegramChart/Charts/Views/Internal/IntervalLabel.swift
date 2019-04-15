//
//  IntervalLabel.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 12/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal final class IntervalLabel: UIView
{
    private static let dateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter
    }()
    
    override public var frame: CGRect {
        didSet { updateFrame() }
    }
    
    private let font: UIFont = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
    private let label: UILabel = UILabel(frame: .zero)
    
    private let callFrequenceLimiter = CallFrequenceLimiter()
    
    internal init() {
        super.init(frame: .zero)

        label.translatesAutoresizingMaskIntoConstraints = true
        label.textAlignment = .center
        label.clipsToBounds = false
        addSubview(label)
    }
    
    internal func setStyle(_ style: ChartStyle) {
        self.label.textColor = style.intervalTextColor
        self.label.font = font
    }
    
    internal func update(ui: ChartUIModel, animated: Bool, duration: TimeInterval) {
        callFrequenceLimiter.update { [weak self] in
            self?.updateLogic(ui: ui, animated: animated, duration: duration)
            return DispatchTimeInterval.milliseconds(33)
        }
    }
    
    private func updateLogic(ui: ChartUIModel, animated: Bool, duration: TimeInterval) {
        let from = ui.find(around: ui.interval.from, in: ui.interval)
        let to = ui.find(around: ui.interval.to, in: ui.interval)
        let fromOfStr = IntervalLabel.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(from) / 1000.0))
        let toOfStr = IntervalLabel.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(to) / 1000.0))
        let text = "\(fromOfStr) - \(toOfStr)"
        
        if self.label.text != text {
//            UIView.animateIf(animated, duration: duration, animations: { [weak self] in
//                guard let `self` = self else {
//                    return
//                }
            
                self.label.text = text
//            })
        }
    }
    
    private func updateFrame()
    {
        label.frame = self.bounds
        label.frame.size.height = 18.0
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

