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

        let oldPath = selectorLayers[0].path

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

        if let oldPath = oldPath, let newPath = selectorLayers[0].path, animated {
            Support.pathAnimation(duration: duration, from: oldPath, to: newPath, on: selectorLayers[0])
        }
    }
    
    internal override func makePath(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> UIBezierPath {
        let path = UIBezierPath()
        let datas = ui.split(uiDatas: points, in: interval)
        
        if datas.isEmpty {
            return path
        }
        
        path.move(to: datas[0].from)
        for i in 1..<datas.count {
            path.addLine(to: datas[i].from)
        }
        for i in 0..<datas.count {
            path.addLine(to: datas[datas.count - i - 1].to)
        }
        path.close()
        
        return path
    }
    
}


