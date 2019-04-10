//
//  ChartView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 13/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

private enum Consts
{
    internal static let horizontalAxisHeight: CGFloat = 20.0
    internal static let spacing: CGFloat = 10.0
}

public class ChartView: UIView
{
    override public var frame: CGRect {
        didSet { updateFrame() }
    }
    
    private let margins: UIEdgeInsets
    private var chartViewModel: ChartViewModel? = nil
    private var visibleAABB: AABB? {
        return chartViewModel?.visibleInIntervalAABB?.copyWithIntellectualPadding(date: 0, value: Configs.padding)
    }
    
    private var columnsView: ColumnsView = ColumnsView()
    private let verticalAxisView: VerticalAxisView = VerticalAxisView()
    private let horizontalAxisView: HorizontalAxisView = HorizontalAxisView()
    private let hintView: HintAndOtherView = HintAndOtherView()

    public init(margins: UIEdgeInsets) {
        self.margins = margins
        super.init(frame: .zero)
        columnsView.parent = self
        
        configureSubviews()
    }

    public func setStyle(_ style: ChartStyle) {
        horizontalAxisView.setStyle(style)
        verticalAxisView.setStyle(style)
        hintView.setStyle(style)
    }
    
    public func setChart(_ chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel
        chartViewModel.registerUpdateListener(self)

        columnsView.setChart(margins: self.margins, chartViewModel)

        update(use: chartViewModel)
    }
    
    private func update(use chartViewModel: ChartViewModel) {
        let aabb = visibleAABB
        
        columnsView.update(aabb: aabb, animated: false, duration: 0.0)
        verticalAxisView.update(aabb: aabb, animated: false, duration: 0.0)
        
        horizontalAxisView.setFullInterval(chartViewModel.fullInterval)
        horizontalAxisView.update(aabb: aabb, animated: false, duration: 0.0)
        
        hintView.setColumns(chartViewModel.columns)
        hintView.setAABB(aabb: aabb)
    }

    private func configureSubviews() {
        horizontalAxisView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalAxisView)

        verticalAxisView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verticalAxisView)

        hintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hintView)
    }
    
    private func updateFrame() {
        let fullFrame = CGRect(x: 0, y: Consts.spacing, width: bounds.width, height: bounds.height - Consts.horizontalAxisHeight - Consts.spacing)
        columnsView.updateFrame(frame: fullFrame)
        
        let marginsFrame = CGRect(x: fullFrame.origin.x + margins.left,
                                  y: fullFrame.origin.y + margins.top,
                                  width: fullFrame.width - margins.left - margins.right,
                                  height: fullFrame.height - margins.top - margins.bottom)
        
        self.horizontalAxisView.frame = CGRect(x: marginsFrame.minX, y: marginsFrame.maxY,
                                               width: marginsFrame.width, height: Consts.horizontalAxisHeight)
        
        self.verticalAxisView.frame = marginsFrame
        self.hintView.frame = marginsFrame
        
        if let vm = chartViewModel {
            update(use: vm)
        }
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

extension ChartView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        let aabb = visibleAABB
        columnsView.update(aabb: aabb, animated: true, duration: Configs.visibleChangeDuration)
        verticalAxisView.update(aabb: aabb, animated: true, duration: Configs.visibleChangeDuration)
        horizontalAxisView.update(aabb: aabb, animated: true, duration: Configs.visibleChangeDuration)
        hintView.setAABB(aabb: aabb)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        let aabb = visibleAABB
        columnsView.update(aabb: aabb, animated: true, duration: Configs.intervalChangeForLinesDuration)
        verticalAxisView.update(aabb: aabb, animated: true, duration: Configs.intervalChangeForValuesDuration)
        horizontalAxisView.update(aabb: aabb, animated: true, duration: Configs.intervalChangeForDatesDuration)
        hintView.setAABB(aabb: aabb)
    }
}
