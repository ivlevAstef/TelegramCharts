//
//  ColumnsView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 08/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class ColumnView: UIView
{
    override public var frame: CGRect {
        didSet { updateFrame() }
    }
    
    private let contentView: UIView = UIView(frame: .zero)
    private let margins: UIEdgeInsets
    private let columnLayer: ColumnViewLayerWrapper
    
    required internal init(margins: UIEdgeInsets, columnLayer: ColumnViewLayerWrapper) {
        self.margins = margins
        self.columnLayer = columnLayer
        super.init(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        
        // without contentView clipsToBounds unwork... WTF?
        contentView.clipsToBounds = true
        contentView.layer.addSublayer(columnLayer.layer)
    }
    
    internal func update(ui: ColumnUIModel, animated: Bool, duration: TimeInterval) {
        columnLayer.update(ui: ui, animated: animated, duration: duration)
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
