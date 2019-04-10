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
    
    internal let id: UUID
    
    private let contentView: UIView = UIView(frame: .zero)
    private let margins: UIEdgeInsets
    private let columnLayer: PolyLineLayerWrapper
    private var lastAABB: AABB?
    
    required internal init(margins: UIEdgeInsets, _ columnViewModel: ColumnViewModel) {
        self.id = columnViewModel.id
        self.margins = margins
        self.columnLayer = PolyLineLayerWrapper(columnViewModel: columnViewModel)
        super.init(frame: .zero)
        addSubview(contentView)
        
        // without contentView clipsToBounds unwork... WTF?
        contentView.clipsToBounds = true
        contentView.layer.addSublayer(columnLayer.layer)
    }

    internal func setSize(_ size: Double) {
        columnLayer.lineWidth = CGFloat(size)
    }
    
    internal func update(aabb: AABB?, animated: Bool, duration: TimeInterval) {
        let animatedPath = animated && (nil != lastAABB)
        let animatedOpacity = animated

        let usedAABB = aabb ?? lastAABB ?? AABB.empty
        lastAABB = aabb

        columnLayer.update(aabb: usedAABB,
                                animatedPath: animatedPath,
                                animatedOpacity: animatedOpacity,
                                duration: duration)
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
