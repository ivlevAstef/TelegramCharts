//
//  ChartsView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 13/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

public class ChartsView: UIView
{

    private var chartsViewModel: ChartsViewModel? = nil
    private var chartsVisibleAABB: Chart.AABB? {
        return chartsViewModel?.visibleInIntervalAABB?.copyWithPadding(date: 0, value: 0.1)
    }

    public init() {
        super.init(frame: .zero)

        self.backgroundColor = .clear
        self.clipsToBounds = true
    }

    public func setCharts(_ charts: ChartsViewModel)
    {
        chartsViewModel = charts
        charts.registerUpdateListener(self)

        setNeedsDisplay()
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        if let chartsViewModel = chartsViewModel, let aabb = chartsVisibleAABB
        {
            drawCharts(chartsViewModel: chartsViewModel, aabb: aabb, rect: rect, context: context)
        }
    }

    private func drawCharts(chartsViewModel: ChartsViewModel, aabb: Chart.AABB, rect: CGRect, context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        context.setLineCap(.butt)
        context.setLineWidth(1.0)

        for chart in chartsViewModel.visibleCharts {
            let points = chart.calculateUIPoints(for: rect, aabb: aabb)

            context.setStrokeColor(chart.color.cgColor)
            context.beginPath()
            context.addLines(between: points)
            context.strokePath()
        }
    }

}

extension ChartsView: ChartsUpdateListener
{
    public func chartsVisibleIsChanged(_ viewModel: ChartsViewModel)
    {
        setNeedsDisplay()
    }

    public func chartsIntervalIsChanged(_ viewModel: ChartsViewModel)
    {
        setNeedsDisplay()
    }
}
