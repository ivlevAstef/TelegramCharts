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
    
    private var chartViewModel: ChartViewModel? = nil
    private var visibleAABB: AABB? {
        return chartViewModel?.visibleInIntervalAABB?.copyWithIntellectualPadding(date: 0, value: Configs.padding)
    }
    
    private var columnsViews: [UIView & ColumnView] = []
    private let verticalAxisView: VerticalAxisView = VerticalAxisView()
    private let horizontalAxisView: HorizontalAxisView = HorizontalAxisView()
    private let hintView: HintAndOtherView = HintAndOtherView()

    public init() {
        super.init(frame: .zero)
        
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
        
        columnsViews = ColumnsViewFabric.makeColumnViews(by: chartViewModel.columns, size: 2.0, parent: self)
        
        update(use: chartViewModel)
    }
    
    private func update(use chartViewModel: ChartViewModel) {
        for columnView in columnsViews {
            columnView.update(aabb: visibleAABB, animated: false, duration: 0.0)
        }
        
        verticalAxisView.update(aabb: visibleAABB, animated: false, duration: 0.0)
        
        horizontalAxisView.setFullInterval(chartViewModel.fullInterval)
        horizontalAxisView.update(aabb: visibleAABB, animated: false, duration: 0.0)
        
        hintView.setColumns(chartViewModel.columns)
        hintView.setAABB(aabb: visibleAABB)
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
        for columnView in columnsViews {
            columnView.frame = fullFrame
        }
        
        self.horizontalAxisView.frame = CGRect(x: 0, y: fullFrame.maxY, width: bounds.width, height: Consts.horizontalAxisHeight)
        
        self.verticalAxisView.frame = fullFrame
        self.hintView.frame = fullFrame
        
        if let vm = chartViewModel {
            update(use: vm)
        }
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configureSubviews()
    }
}

extension ChartView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        let aabb = visibleAABB
        for columnView in columnsViews {
            columnView.update(aabb: aabb, animated: true, duration: Configs.visibleChangeDuration)
        }
        verticalAxisView.update(aabb: aabb, animated: true, duration: Configs.visibleChangeDuration)
        horizontalAxisView.update(aabb: aabb, animated: true, duration: Configs.visibleChangeDuration)
        hintView.setAABB(aabb: aabb)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        let aabb = visibleAABB
        for columnView in columnsViews {
            columnView.update(aabb: aabb, animated: true, duration: Configs.intervalChangeForLinesDuration)
        }
        verticalAxisView.update(aabb: aabb, animated: true, duration: Configs.intervalChangeForValuesDuration)
        horizontalAxisView.update(aabb: aabb, animated: true, duration: Configs.intervalChangeForDatesDuration)
        hintView.setAABB(aabb: aabb)
    }
}
