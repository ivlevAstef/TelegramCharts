//
//  PolyLineLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 14/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal final class PolyLineLayerWrapper: ColumnViewLayerWrapper
{
    internal override func fillLayer(_ layer: CAShapeLayer) {
        layer.lineWidth = CGFloat(size)
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.strokeColor = color?.cgColor
        layer.fillColor = nil
        layer.opacity = 1.0
    }

    internal override func fillContext(_ context: CGContext) {
        context.setLineWidth(CGFloat(size))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor((color ?? UIColor.clear).cgColor)
        context.strokePath()
    }

    internal override func makePath(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> UIBezierPath {
        return makePath(by: calculatePoints(ui: ui, points: points, interval: interval))
    }
    
    private func calculatePoints(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> [CGPoint] {
        let datas = ui.split(uiDatas: points, in: interval)
        var result = [CGPoint](repeating: CGPoint.zero, count: datas.count)
        for i in 0..<datas.count {
            result[i] = datas[i].to
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
