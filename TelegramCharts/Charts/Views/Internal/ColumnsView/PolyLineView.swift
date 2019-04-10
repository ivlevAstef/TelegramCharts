//
//  PolyLineView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 17/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal class PolyLineView: UIView, ColumnView
{
    override public var frame: CGRect {
        didSet { updateFrame() }
    }
    
    private let contentView: UIView = UIView(frame: .zero)
    private let margins: UIEdgeInsets
    private let columnLayer = PolyLineLayerWrapper()
    
    required internal init(margins: UIEdgeInsets) {
        self.margins = margins
        super.init(frame: .zero)
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
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
