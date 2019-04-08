//
//  PolygonLineView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 17/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal class PolygonLineView: UIView, ColumnsView
{
    private var columnLayers: [PolygonLineLayerWrapper] = []

    private var lastAABB: AABB?
    
    internal init() {
        super.init(frame: .zero)
        
        clipsToBounds = true
        setParentLayer()
    }

    internal func setSize(_ size: Double) {
        let lineWidth: CGFloat = CGFloat(size)
        for columnLayer in columnLayers {
            columnLayer.lineWidth = lineWidth
        }
    }

    internal func setColumns(_ columnViewModels: [ColumnViewModel]) {
        columnLayers.forEach { $0.layer.removeFromSuperlayer() }
        columnLayers.removeAll()
        for column in columnViewModels {
            let columnLayer = PolygonLineLayerWrapper(columnViewModel: column)
            columnLayers.append(columnLayer)
        }

        setParentLayer()
    }

    internal func update(aabb: AABB?, animated: Bool, duration: TimeInterval) {

        let animatedPath = animated && (nil != lastAABB)
        let animatedOpacity = animated

        let usedAABB = aabb ?? lastAABB ?? AABB.empty
        lastAABB = aabb

        for columnLayer in columnLayers {
            columnLayer.update(aabb: usedAABB,
                                    animatedPath: animatedPath,
                                    animatedOpacity: animatedOpacity,
                                    duration: duration)
        }
    }
    
    private func setParentLayer() {
        columnLayers.forEach { $0.layer.removeFromSuperlayer() }
        for columnLayer in columnLayers {
            columnLayer.layer.frame = layer.bounds
            layer.addSublayer(columnLayer.layer)
        }
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
