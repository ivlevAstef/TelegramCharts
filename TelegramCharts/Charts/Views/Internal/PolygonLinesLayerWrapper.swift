//
//  PolygonLinesLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 15/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

internal final class PolygonLinesLayerWrapper
{   
    private var polygonLineLayers: [PolygonLineLayerWrapper] = []
    private weak var parentLayer: CALayer?

    private var lastAABB: AABB?
    
    internal init() {
    }

    internal func setLineWidth(_ lineWidth: CGFloat) {
        for polygonLineLayer in polygonLineLayers {
            polygonLineLayer.layer.lineWidth = lineWidth
        }
    }
    
    internal func setParentLayer(_ layer: CALayer) {
        parentLayer = layer
        
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
        
        if let layer = parentLayer {
            setParentLayer(layer)
        }
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
}
