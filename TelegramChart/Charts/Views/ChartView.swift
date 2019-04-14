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
    internal static let topOffset: CGFloat = 30.0
}

public class ChartView: UIView
{
    override public var frame: CGRect {
        didSet { updateFrame() }
    }
    
    public var hintClickHandler: ((Chart.Date) -> Void)?
    
    private let margins: UIEdgeInsets
    private var ui: ChartUIModel? = nil
    
    private var columnsView: ColumnsView = ColumnsView(isAdditionalOffset: true)
    private let verticalAxisView: VerticalAxisView = VerticalAxisView(topOffset: Consts.topOffset)
    private let horizontalAxisView: HorizontalAxisView = HorizontalAxisView()
    private let hintView: HintAndOtherView = HintAndOtherView()
    private let intervalLabel: IntervalLabel = IntervalLabel()

    public init(margins: UIEdgeInsets) {
        self.margins = margins
        super.init(frame: .zero)

        self.isOpaque = true
        configureSubviews()
    }

    public func setStyle(_ style: ChartStyle) {
        self.backgroundColor = style.backgroundColor

        columnsView.setStyle(style)
        horizontalAxisView.setStyle(style)
        verticalAxisView.setStyle(style)
        hintView.setStyle(style)
        intervalLabel.setStyle(style)
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
        hintView.update(ui: ui)
        intervalLabel.update(ui: ui, animated: false, duration: 0.0)
    }

    private func configureSubviews() {
        columnsView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(columnsView)

        horizontalAxisView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(horizontalAxisView)

        verticalAxisView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(verticalAxisView)

        hintView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(hintView)
        
        intervalLabel.translatesAutoresizingMaskIntoConstraints = true
        addSubview(intervalLabel)
        
        hintView.hintClickHandler = { [weak self] date in
            self?.hintClickHandler?(date)
        }
        
        hintView.dateIsChangedHandler = { [weak self] date in
            self?.columnsView.updateSelector(to: date, animated: true, duration: Configs.hintDuration)
        }
    }
    
    private func updateFrame() {
        let fullFrame = CGRect(x: 0, y: Consts.spacing,
                               width: bounds.width, height: bounds.height - Consts.horizontalAxisHeight - Consts.spacing)
        
        let columnsFrame = CGRect(x: fullFrame.origin.x,
                                  y: fullFrame.origin.y + Consts.topOffset,
                                  width: fullFrame.width,
                                  height: fullFrame.height - Consts.topOffset)
        columnsView.frame = columnsFrame
        
        let marginsFrame = CGRect(x: fullFrame.origin.x + margins.left,
                                  y: fullFrame.origin.y + margins.top,
                                  width: fullFrame.width - margins.left - margins.right,
                                  height: fullFrame.height - margins.top - margins.bottom)
        self.horizontalAxisView.frame = CGRect(x: marginsFrame.minX, y: marginsFrame.maxY,
                                               width: marginsFrame.width, height: Consts.horizontalAxisHeight)
        
        self.verticalAxisView.frame = marginsFrame
        
        let hintFrame = CGRect(x: columnsFrame.origin.x + margins.left,
                               y: columnsFrame.origin.y + margins.top,
                               width: columnsFrame.width - margins.left - margins.right,
                               height: columnsFrame.height - margins.top - margins.bottom)
        self.hintView.frame = hintFrame
        
        self.intervalLabel.frame = CGRect(x: marginsFrame.origin.x,
                                          y: marginsFrame.origin.y,
                                          width: marginsFrame.width,
                                          height: Consts.topOffset)
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
        hintView.update(ui: ui)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        let ui = ChartUIModel(viewModel: viewModel, fully: false, size: 2.0)
        self.ui = ui
        
        columnsView.update(ui: ui, animated: true, duration: Configs.intervalChangeForLinesDuration)
        verticalAxisView.update(ui: ui, animated: true, duration: Configs.intervalChangeForValuesDuration)
        horizontalAxisView.update(ui: ui, animated: true, duration: Configs.intervalChangeForDatesDuration)
        hintView.update(ui: ui)
        intervalLabel.update(ui: ui, animated: true, duration: Configs.intervalChangeForLabelDuration)
    }
}
