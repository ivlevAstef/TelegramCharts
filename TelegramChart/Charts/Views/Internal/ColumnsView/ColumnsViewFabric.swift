//
//  ColumnsViewFabric.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 09/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal final class ColumnsViewFabric
{
    internal static func makeColumnViews(by types: [ColumnViewModel.ColumnType], parent: UIView) -> [ColumnViewLayerWrapper] {
        let views: [ColumnViewLayerWrapper] = types.map { type in
            switch type {
            case .line:
                return PolyLineLayerWrapper()
            case .area:
                return AreaLayerWrapper()
            case .bar:
                return BarLayerWrapper()
            }
        }
        
        for layer in parent.layer.sublayers ?? [] {
            layer.removeFromSuperlayer()
        }
        
        for view in views {
            parent.layer.addSublayer(view.layer)
        }
        
        for view in views {
            parent.layer.addSublayer(view.selectorLayer)
        }
        
        return views
    }
}
