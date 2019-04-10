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
    internal static func makeColumnViews(by types: [ColumnViewModel.ColumnType], margins: UIEdgeInsets, parent: UIView) -> [UIView & ColumnView] {
        let views: [UIView & ColumnView] = types.map { type in
            switch type {
            case .line:
                return PolyLineView(margins: margins)
            case .area:
                return PolyLineView(margins: margins)
            case .bar:
                return PolyLineView(margins: margins)
            }
        }
        
        for view in parent.subviews.compactMap({ $0 as? (UIView & ColumnView) }) {
            view.removeFromSuperview()
        }
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(view)
        }
        
        return views
    }
}
