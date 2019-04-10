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
    internal static func makeColumnViews(by types: [ColumnViewModel.ColumnType], margins: UIEdgeInsets, parent: UIView) -> [ColumnView] {
        let views: [ColumnView] = types.map { type in
            switch type {
            case .line:
                return ColumnView(margins: margins, columnLayer: PolyLineLayerWrapper())
            case .area:
                return ColumnView(margins: margins, columnLayer: PolyLineLayerWrapper())
            case .bar:
                return ColumnView(margins: margins, columnLayer: BarLayerWrapper())
            }
        }
        
        for view in parent.subviews.compactMap({ $0 as? ColumnView }) {
            view.removeFromSuperview()
        }
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(view)
        }
        
        return views
    }
}
