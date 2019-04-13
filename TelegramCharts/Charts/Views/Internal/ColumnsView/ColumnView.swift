//
//  ColumnsView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 08/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal final class ColumnView: UIView
{
    override internal var frame: CGRect {
        didSet { updateFrame() }
    }
    
    private let contentView: UIView = UIView(frame: .zero)
    private let margins: UIEdgeInsets
    private let columnLayer: ColumnViewLayerWrapper
    
    required internal init(margins: UIEdgeInsets, columnLayer: ColumnViewLayerWrapper) {
        self.margins = margins
        self.columnLayer = columnLayer
        super.init(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
        
        // without contentView clipsToBounds unwork... WTF?
        contentView.clipsToBounds = true
        contentView.layer.addSublayer(columnLayer.layer)
    }
    
    @inline(__always)
    internal func setStyle(_ style: ChartStyle) {
        self.columnLayer.setStyle(style)
    }
    
    @inline(__always)
    internal func updateSelector(to date: Chart.Date?, animated: Bool, duration: TimeInterval) {
        columnLayer.updateSelector(to: date, animated: animated, duration: duration)
    }
    
    @inline(__always)
    internal func update(ui: ColumnUIModel, animated: Bool, duration: TimeInterval, t: CGFloat) {
        columnLayer.update(ui: ui, animated: animated, duration: duration, t: t)
    }

    @inline(__always)
    internal func confirm(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        columnLayer.confirm(ui: ui, animated: animated, duration: duration)
    }

    @inline(__always)
    internal func drawCurrentState(to context: CGContext) {
        columnLayer.drawCurrentState(to: context)
    }

    internal func setCornerRadius(_ cornerRadius: CGFloat) {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = cornerRadius > 0
    }
    
    private func updateFrame() {
        contentView.frame = bounds
        
        let rect = CGRect(x: bounds.minX + margins.left,
                          y: bounds.minY + margins.top,
                          width: bounds.width - margins.left - margins.right,
                          height: bounds.height - margins.top - margins.bottom)
        columnLayer.layer.frame = rect
        columnLayer.minX = -margins.left - 2 // reserve
        columnLayer.maxX = bounds.width + 2 // reserve
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
