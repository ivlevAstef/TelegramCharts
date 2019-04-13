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
    internal static let pointSize: CGFloat = 10
    internal static let centerPointSize: CGFloat = 5
}


internal final class PolyLineLayerWrapper: ColumnViewLayerWrapper
{
    private var selectorLayer: CAShapeLayer = PolyLineLayerWrapper.makeSelectorLayer()
    
    internal override init() {
        super.init()
        layer.addSublayer(selectorLayer)
    }
    
    internal override func setStyle(_ style: ChartStyle) {
        if let sublayer = selectorLayer.sublayers?.first as? CAShapeLayer {
            sublayer.fillColor = style.dotColor.cgColor
        }
        //lineColor = style.focusLineColor
    }
    
    internal override func fillLayer(_ layer: CAShapeLayer) {
        layer.lineWidth = CGFloat(ui?.size ?? 1.0)
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.strokeColor = ui?.color.cgColor
        layer.fillColor = nil
        layer.opacity = 1.0
    }

    internal override func fillContext(_ context: CGContext) {
        context.setLineWidth(CGFloat(ui?.size ?? 1.0))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor((ui?.color ?? UIColor.clear).cgColor)
        context.strokePath()
    }
    
    internal override func updateSelector(to date: Chart.Date?, animated: Bool, duration: TimeInterval) {
        guard let ui = self.ui else {
            return
        }
        
        ui.tran
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
    
    private static func makeSelectorLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.lineWidth = 0.0
        
        let path = UIBezierPath(arcCenter: .zero, radius: Consts.pointSize * 0.5, startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: true)
        layer.path = path.cgPath
        
        let centerLayer = CAShapeLayer()
        let cpath = UIBezierPath(arcCenter: .zero, radius: Consts.centerPointSize * 0.5, startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: true)
        centerLayer.path = cpath.cgPath
        
        let offset = (Consts.pointSize - Consts.centerPointSize) * 0.5
        centerLayer.position = CGPoint(x: offset, y: offset)
        layer.addSublayer(centerLayer)
        
        return layer
    }
}
