//
//  BarLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 10/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//


import UIKit

internal final class BarLayerWrapper: ColumnViewLayerWrapper
{
    private var pathLayer: CAShapeLayer?
    
    internal override func fillLayer(_ layer: CAShapeLayer) {
        layer.lineWidth = 0
        layer.strokeColor = nil
        layer.fillColor = ui?.color.cgColor
        layer.opacity = 1.0
    }

    internal override func fillContext(_ context: CGContext) {
        context.setLineWidth(0)
        context.setFillColor((ui?.color ?? UIColor.clear).cgColor)
        context.fillPath()
    }
    
    internal override func updateSelector(to date: Chart.Date?, animated: Bool, duration: TimeInterval) {
        
    }

    internal override func makePath(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> UIBezierPath {
        return makePath(by: calculatePoints(ui: ui, points: points, interval: interval))
    }
    
    private func calculatePoints(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> [CGPoint] {
        let datas = ui.split(uiDatas: points, in: interval)
        let step = (datas[1].from.x - datas[0].from.x) / 2
        
        var result = [CGPoint](repeating: CGPoint.zero, count: 4 * datas.count)
        for i in 0..<datas.count {
            result[2 * i] = CGPoint(x: datas[i].from.x - step, y: datas[i].from.y)
            result[2 * i + 1] = CGPoint(x: datas[i].from.x + step, y: datas[i].from.y)
        }
        for i in 0..<datas.count {
            result[result.count - 2 * i - 1] = CGPoint(x: datas[i].to.x - step, y: datas[i].to.y)
            result[result.count - 2 * i - 2] = CGPoint(x: datas[i].to.x + step, y: datas[i].to.y)
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

