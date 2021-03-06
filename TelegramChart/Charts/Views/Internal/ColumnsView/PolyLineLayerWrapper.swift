//
//  PolyLineLayerWrapper.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 14/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

private enum Consts
{
    internal static let pointSize: CGFloat = 8
    internal static let centerPointSize: CGFloat = 4
}

internal final class PolyLineLayerWrapper: ColumnViewLayerWrapper
{
    internal init() {
        // First line, second round, third center
        super.init(countSelectorLayers: 3)
    }
    
    internal override func setStyle(_ style: ChartStyle) {
        super.setStyle(style)
        selectorLayers[0].strokeColor = style.focusLineColor.cgColor
        selectorLayers[0].lineWidth = 1.0
        selectorLayers[2].fillColor = style.dotColor.cgColor
    }
    
    internal override func fillLayer(_ layer: CAShapeLayer) {
        layer.lineWidth = CGFloat(ui?.size ?? 1.0)
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.strokeColor = ui?.color.cgColor
        layer.fillColor = nil
    }

    internal override func fillContext(_ context: CGContext) {
        context.setLineWidth(CGFloat(ui?.size ?? 1.0))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor((ui?.color ?? UIColor.clear).cgColor)
        context.strokePath()
    }
    
    internal override func updateSelector(to position: ColumnUIModel.UIData, animated: Bool, duration: TimeInterval) {
        guard let ui = self.ui else {
            return
        }
        
        let bezierPaths = [
            UIBezierPath(arcCenter: position.to, radius: Consts.pointSize * 0.5, startAngle: 0, endAngle: CGFloat(2.0 * .pi), clockwise: true),
            UIBezierPath(arcCenter: position.to, radius: Consts.centerPointSize * 0.5, startAngle: 0, endAngle: CGFloat(2.0 * .pi), clockwise: true)
        ]
        let oldPaths = selectorLayers.map { $0.path }
        
        selectorLayers[1].fillColor = ui.color.cgColor
        for (bezierPath, layer) in zip(bezierPaths, selectorLayers.dropFirst()) {
            layer.path = bezierPath.cgPath
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

        if animated {
            for (oldPath, layer) in zip(oldPaths, selectorLayers) {
                if let oldPath = oldPath, let newPath = layer.path {
                    Support.pathAnimation(duration: duration, from: oldPath, to: newPath, on: layer)
                }
            }
        }
    }

    internal override func makePath(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> UIBezierPath {
        let path = UIBezierPath()
        let datas = ui.split(uiDatas: points, in: interval)
        
        if datas.isEmpty {
            return path
        }
        
        path.move(to: datas[0].to)
        for i in 1..<datas.count {
            path.addLine(to: datas[i].to)
        }
        
        return path
    }
}
