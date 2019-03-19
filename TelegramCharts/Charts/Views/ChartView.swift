//
//  ChartView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 13/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

private enum Consts
{
    internal static let horizontalAxisHeight: CGFloat = 20.0
    internal static let spacing: CGFloat = 10.0
}

public class ChartView: UIView
{
    private var chartViewModel: ChartViewModel? = nil
    private var visibleAABB: AABB? {
        return chartViewModel?.visibleInIntervalAABB?.copyWithIntellectualPadding(date: 0, value: 0.1)
    }
    
    private let polygonLinesView: PolygonLinesView = PolygonLinesView()
    private let verticalAxisView: VerticalAxisView = VerticalAxisView()
    private let horizontalAxisView: HorizontalAxisView = HorizontalAxisView()
    private let hintView: HintAndOtherView = HintAndOtherView()

    public init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        
        configureSubviews()
        makeConstaints()
    }

    public func setStyle(_ style: ChartStyle) {
        horizontalAxisView.setStyle(style)
        verticalAxisView.setStyle(style)
        hintView.setStyle(style)
    }
    
    public func setChart(_ chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel
        chartViewModel.registerUpdateListener(self)
        
        polygonLinesView.setPolygonLines(chartViewModel.polygonLines)
        polygonLinesView.setLineWidth(2.0)
        polygonLinesView.update(aabb: visibleAABB, animated: false, duration: 0.0)

        verticalAxisView.update(aabb: visibleAABB, animated: false, duration: 0.0)

        horizontalAxisView.setFullInterval(chartViewModel.fullInterval)
        horizontalAxisView.update(aabb: visibleAABB, animated: false, duration: 0.0)

        hintView.setPolygonLines(chartViewModel.polygonLines)
        hintView.setAABB(aabb: visibleAABB)
    }
    
    private func configureSubviews()
    {
        polygonLinesView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(polygonLinesView)
        
        horizontalAxisView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalAxisView)

        verticalAxisView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verticalAxisView)

        hintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hintView)
    }
    
    private func makeConstaints() {
        self.polygonLinesView.topAnchor.constraint(equalTo: self.topAnchor, constant: Consts.spacing).isActive = true
        self.polygonLinesView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.polygonLinesView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        
        self.polygonLinesView.bottomAnchor.constraint(equalTo: self.horizontalAxisView.topAnchor).isActive = true
        
        self.horizontalAxisView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.horizontalAxisView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.horizontalAxisView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Consts.spacing).isActive = true
        self.horizontalAxisView.heightAnchor.constraint(equalToConstant: Consts.horizontalAxisHeight).isActive = true

        self.verticalAxisView.topAnchor.constraint(equalTo: self.polygonLinesView.topAnchor).isActive = true
        self.verticalAxisView.leftAnchor.constraint(equalTo: self.polygonLinesView.leftAnchor).isActive = true
        self.verticalAxisView.rightAnchor.constraint(equalTo: self.polygonLinesView.rightAnchor).isActive = true
        self.verticalAxisView.bottomAnchor.constraint(equalTo: self.polygonLinesView.bottomAnchor).isActive = true

        self.hintView.topAnchor.constraint(equalTo: self.polygonLinesView.topAnchor).isActive = true
        self.hintView.leftAnchor.constraint(equalTo: self.polygonLinesView.leftAnchor).isActive = true
        self.hintView.rightAnchor.constraint(equalTo: self.polygonLinesView.rightAnchor).isActive = true
        self.hintView.bottomAnchor.constraint(equalTo: self.polygonLinesView.bottomAnchor).isActive = true
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension ChartView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        polygonLinesView.update(aabb: visibleAABB, animated: true, duration: 0.3)
        verticalAxisView.update(aabb: visibleAABB, animated: true, duration: 0.3)
        hintView.setAABB(aabb: visibleAABB)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        polygonLinesView.update(aabb: visibleAABB, animated: true, duration: 0.1)
        verticalAxisView.update(aabb: visibleAABB, animated: false, duration: 0.1)
        horizontalAxisView.update(aabb: visibleAABB, animated: true, duration: 0.2)
        hintView.setAABB(aabb: visibleAABB)
    }
}
