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
    private var ui: ChartUIModel? = nil
    
    private var columnsView: ColumnsView = ColumnsView()
    private let verticalAxisView: VerticalAxisView = VerticalAxisView()
    private let horizontalAxisView: HorizontalAxisView = HorizontalAxisView()
    private let hintView: HintAndOtherView = HintAndOtherView()

    public init(margins: UIEdgeInsets) {
        self.margins = margins
        super.init(frame: .zero)

        configureSubviews()
    }

    public func setStyle(_ style: ChartStyle) {
        horizontalAxisView.setStyle(style)
        verticalAxisView.setStyle(style)
        hintView.setStyle(style)
    }
    
    public func setChart(_ chartViewModel: ChartViewModel) {
        chartViewModel.registerUpdateListener(self)

        columnsView.premake(margins: self.margins, types: chartViewModel.columns.map { $0.type })


        self.ui = ChartUIModel(viewModel: chartViewModel, fully: false, size: 2.0)
        update()
    }
    
    private func update() {
        guard let ui = self.ui else {
            return
        }
        
        columnsView.update(ui: ui, animated: false, duration: 0.0)
        verticalAxisView.update(ui: ui, animated: false, duration: 0.0)
        horizontalAxisView.update(ui: ui, animated: false, duration: 0.0)
        hintView.update(ui: ui, animated: false, duration: 0.0)
    }

    private func configureSubviews() {
        columnsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(columnsView)

        horizontalAxisView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalAxisView)

        verticalAxisView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verticalAxisView)

        hintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hintView)
    }
    
    private func updateFrame() {
        let fullFrame = CGRect(x: 0, y: Consts.spacing,
                               width: bounds.width, height: bounds.height - Consts.horizontalAxisHeight - Consts.spacing)
        columnsView.frame = fullFrame
        
        let marginsFrame = CGRect(x: fullFrame.origin.x + margins.left,
                                  y: fullFrame.origin.y + margins.top,
                                  width: fullFrame.width - margins.left - margins.right,
                                  height: fullFrame.height - margins.top - margins.bottom)
        
        self.horizontalAxisView.frame = CGRect(x: marginsFrame.minX, y: marginsFrame.maxY,
                                               width: marginsFrame.width, height: Consts.horizontalAxisHeight)
        
        self.verticalAxisView.frame = marginsFrame
        self.hintView.frame = marginsFrame
        
        update()
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

extension ChartView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        let ui = ChartUIModel(viewModel: viewModel, fully: false, size: 2.0)
        self.ui = ui
        
        columnsView.update(ui: ui, animated: true, duration: Configs.visibleChangeDuration)
        verticalAxisView.update(ui: ui, animated: true, duration: Configs.visibleChangeDuration)
        horizontalAxisView.update(ui: ui, animated: true, duration: Configs.visibleChangeDuration)
        hintView.update(ui: ui, animated: true, duration: 0.0)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        let ui = ChartUIModel(viewModel: viewModel, fully: false, size: 2.0)
        self.ui = ui
        
        columnsView.update(ui: ui, animated: true, duration: Configs.intervalChangeForLinesDuration)
        verticalAxisView.update(ui: ui, animated: true, duration: Configs.intervalChangeForValuesDuration)
        horizontalAxisView.update(ui: ui, animated: true, duration: Configs.intervalChangeForDatesDuration)
        hintView.update(ui: ui, animated: true, duration: 0.0)
    }
}
