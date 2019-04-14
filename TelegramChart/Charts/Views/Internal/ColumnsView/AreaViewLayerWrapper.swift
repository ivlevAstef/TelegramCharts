//
//  AreaViewLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 10/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

private enum Consts
{
    internal static let pointSize: CGFloat = 10
    internal static let centerPointSize: CGFloat = 5
}

internal final class AreaLayerWrapper: ColumnViewLayerWrapper
{
    
    internal init() {
        // First line, second round, third center
        super.init(countSelectorLayers: 1)
    }
    
    internal override func setStyle(_ style: ChartStyle) {
        super.setStyle(style)
        selectorLayers[0].strokeColor = style.focusLineColor.cgColor
        selectorLayers[0].lineWidth = 1.0
    }
    
    
    internal override func fillLayer(_ layer: CAShapeLayer) {
        layer.lineWidth = 0
        layer.strokeColor = nil
        layer.fillColor = ui?.color.cgColor
    }

    internal override func fillContext(_ context: CGContext) {
        context.setLineWidth(0)
        context.setFillColor((ui?.color ?? UIColor.clear).cgColor)
        context.fillPath()
    }
    
    internal override func updateSelector(to position: ColumnUIModel.UIData, animated: Bool, duration: TimeInterval) {
        guard let ui = self.ui else {
            return
        }

        if isFirst {
            let max = ui.translate(value: ui.aabb.maxValue, to: selectorLayer.bounds)
            let min = ui.translate(value: ui.aabb.minValue, to: selectorLayer.bounds)

            let line = UIBezierPath()
            line.move(to: CGPoint(x: position.to.x, y: max))
            line.addLine(to: CGPoint(x: position.to.x, y: min))

            selectorLayers[0].path = line.cgPath
        } else {
            selectorLayers[0].path = nil
        }
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


