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
    private static let minHeight: CGFloat = 1
    
    private var barColor: UIColor?
    private var step: CGFloat = 0.0
    
    internal init() {
        super.init(countSelectorLayers: 1)
    }
    
    internal override func setStyle(_ style: ChartStyle) {
        super.setStyle(style)
        barColor = style.hintBarColor
    }
    
    internal override func fillLayer(_ layer: CAShapeLayer) {
        layer.lineWidth = 0
        layer.fillColor = fillColor.cgColor
    }

    internal override func fillContext(_ context: CGContext) {
        context.setLineWidth(0)
        context.setFillColor(fillColor.cgColor)
        context.fillPath()
    }
    
    private var fillColor: UIColor {
        let mainColor = ui?.color ?? UIColor.clear
        if let barColor = self.barColor, nil != selectedDate {
            var (r1, g1, b1, a1) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
            var (r2, g2, b2, a2) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
            
            mainColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            barColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            let (r, g, b) = (r1 * a2 + r2 * (1 - a2), g1 * a2 + g2 * (1 - a2), b1 * a2 + b2 * (1 - a2))
            return UIColor(red: r, green: g, blue: b, alpha: a1)
        }
        
        return mainColor
    }
    
    internal override func updateSelector(to position: ColumnUIModel.UIData, animated: Bool, duration: TimeInterval) {
        guard let ui = self.ui else {
            return
        }

//
//        if animated {
//            let lastLayer = CAShapeLayer()
//            lastLayer.fillColor = selectorLayers[0].fillColor
//            lastLayer.path = selectorLayers[0].path
//            lastLayer.opacity = 1.0
//            selectorLayer.addSublayer(lastLayer)
//            opacityAnimated(duration: duration, to: 0.0, on: lastLayer, completion: {
//                lastLayer.removeFromSuperlayer()
//            })
//        }

        selectorLayers[0].fillColor = ui.color.cgColor
        
        let minHeight = ui.isVisible ? BarLayerWrapper.minHeight: 0.0
        let height = max(minHeight, position.from.y - position.to.y)
        let path = UIBezierPath(rect: CGRect(x: position.from.x - step,
                                             y: position.to.y,
                                             width: 2 * step,
                                             height: height))
        
        selectorLayers[0].path = path.cgPath
        
//        if animated {
//            let layer = selectorLayers[0]
//            layer.opacity = 0.0
//            opacityAnimated(duration: duration, to: 1.0, on: layer)
//        }
    }

    
    internal override func updateSelector(to date: Chart.Date?, animated: Bool, duration: TimeInterval, needUpdateAny: inout Bool) {
        needUpdateAny = needUpdateAny || (nil == selectedDate && nil != date) || (nil != selectedDate && nil == date)
        
        super.updateSelector(to: date, animated: animated, duration: duration, needUpdateAny: &needUpdateAny)
    }

    internal override func makePath(ui: ColumnUIModel, points: [ColumnUIModel.UIData], interval: ChartViewModel.Interval) -> UIBezierPath {
        let path = UIBezierPath()
        let datas = ui.split(uiDatas: points, in: interval)
        let step = (datas[1].from.x - datas[0].from.x) / 2
        self.step = step
        
        let minHeight = ui.isVisible ? BarLayerWrapper.minHeight: 0.0
        for i in 0..<datas.count {
            let height = max(minHeight, datas[i].from.y - datas[i].to.y)
            path.move(to: CGPoint(x: datas[i].from.x - step, y: datas[i].from.y))
            path.addLine(to: CGPoint(x: datas[i].from.x + step, y: datas[i].from.y))
            path.addLine(to: CGPoint(x: datas[i].from.x + step, y: datas[i].from.y - height))
            path.addLine(to: CGPoint(x: datas[i].from.x - step, y: datas[i].from.y - height))
            path.addLine(to: CGPoint(x: datas[i].from.x - step, y: datas[i].from.y))
        }

        return path
    }
}

