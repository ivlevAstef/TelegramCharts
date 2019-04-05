//
//  PolygonLinesView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 17/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal class PolygonLinesView: UIView
{
    private var polygonLineLayers: [PolygonLineLayerWrapper] = []

    private var lastAABB: AABB?
    
    internal init() {
        super.init(frame: .zero)
        
        clipsToBounds = true
        setParentLayer()
    }

    internal func setLineWidth(_ lineWidth: CGFloat) {
        for polygonLineLayer in polygonLineLayers {
            polygonLineLayer.layer.lineWidth = lineWidth
        }
    }

    internal func setParentLayer() {
        polygonLineLayers.forEach { $0.layer.removeFromSuperlayer() }
        for polygonLineLayer in polygonLineLayers {
            polygonLineLayer.layer.frame = layer.bounds
            layer.addSublayer(polygonLineLayer.layer)
        }
    }

    internal func setPolygonLines(_ polygonLineViewModels: [PolygonLineViewModel]) {
        polygonLineLayers.forEach { $0.layer.removeFromSuperlayer() }
        polygonLineLayers.removeAll()
        for polygonLine in polygonLineViewModels {
            let polygonLineLayer = PolygonLineLayerWrapper(polygonLineViewModel: polygonLine)
            polygonLineLayers.append(polygonLineLayer)
        }

        setParentLayer()
    }

    internal func update(aabb: AABB?, animated: Bool, duration: TimeInterval) {

        let animatedPath = animated && (nil != lastAABB)
        let animatedOpacity = animated

        let usedAABB = aabb ?? lastAABB ?? AABB.empty
        lastAABB = aabb

        for polygonLineLayer in polygonLineLayers {
            polygonLineLayer.update(aabb: usedAABB,
                                    animatedPath: animatedPath,
                                    animatedOpacity: animatedOpacity,
                                    duration: duration)
        }
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
