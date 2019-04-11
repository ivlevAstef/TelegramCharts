//
//  AreaViewLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 10/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal final class AreaLayerWrapper: ColumnViewLayerWrapper
{
    private var pathLayer: CAShapeLayer?
    
    internal override func fillLayer(_ layer: CAShapeLayer, ui: ColumnUIModel) {
        layer.lineWidth = 0
        layer.lineCap = .butt
        layer.lineJoin = .miter
        layer.strokeColor = nil
        layer.fillColor = ui.color.cgColor
        layer.opacity = 1.0
    }

    internal override func makePath(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> UIBezierPath {
        return makePath(by: calculatePoints(ui: ui, points: points, interval: interval))
    }
    
    private func calculatePoints(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> [CGPoint] {
        let datas = ui.split(uiDatas: points, in: interval)
        
        var result = [CGPoint](repeating: CGPoint.zero, count: 2 * datas.count)
        for i in 0..<datas.count {
            result[i] = CGPoint(x: datas[i].from.x, y: datas[i].from.y)
        }
        for i in 0..<datas.count {
            result[result.count - i - 1] = CGPoint(x: datas[i].to.x, y: datas[i].to.y)
        }
        return result
    }
    
    private func makePath(by points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        
        guard let firstPoint = points.first else {
            return path
        }
        
        
        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}


