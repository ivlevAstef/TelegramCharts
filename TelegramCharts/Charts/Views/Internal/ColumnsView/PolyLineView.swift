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
    
    private let columnLayer: PolyLineLayerWrapper
    private var lastAABB: AABB?
    
    required internal init(_ columnViewModel: ColumnViewModel) {
        self.columnLayer = PolyLineLayerWrapper(columnViewModel: columnViewModel)
        super.init(frame: .zero)
        
        clipsToBounds = true
        layer.addSublayer(columnLayer.layer)
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
        columnLayer.layer.frame = layer.bounds
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
