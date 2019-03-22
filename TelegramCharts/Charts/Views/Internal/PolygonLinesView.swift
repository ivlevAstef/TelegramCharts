//
//  PolygonLinesView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 17/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class PolygonLinesView: UIView
{
    private var polygonLinesLayerWrapper: PolygonLinesLayerWrapper = PolygonLinesLayerWrapper()
    
    internal init() {
        super.init(frame: .zero)
        
        clipsToBounds = true
        
        polygonLinesLayerWrapper.setParentLayer(layer)
    }

    internal func setLineWidth(_ lineWidth: CGFloat) {
        polygonLinesLayerWrapper.setLineWidth(lineWidth)
    }
    
    internal func setPolygonLines(_ polygonLineViewModels: [PolygonLineViewModel]) {
        polygonLinesLayerWrapper.setPolygonLines(polygonLineViewModels)
    }
    
    internal func update(aabb: AABB?, animated: Bool, duration: TimeInterval) {
        polygonLinesLayerWrapper.update(aabb: aabb, animated: animated, duration: duration)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
