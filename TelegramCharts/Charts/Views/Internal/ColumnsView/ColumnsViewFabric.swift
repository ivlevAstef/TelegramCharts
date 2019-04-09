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
    internal static func makeColumnViews(by models: [ColumnViewModel], size: Double, parent: UIView) -> [UIView & ColumnView] {
        let views: [UIView & ColumnView] = models.map { model in
            switch model.type {
            case .line:
                return PolyLineView(model)
            case .area:
                return PolyLineView(model)
            case .bar:
                return PolyLineView(model)
            }
        }
        
        for view in parent.subviews.compactMap({ $0 as? (UIView & ColumnView) }) {
            view.removeFromSuperview()
        }
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setSize(size)
            parent.addSubview(view)
        }
        
        return views
    }
}
