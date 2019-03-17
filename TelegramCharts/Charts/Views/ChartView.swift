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
        return chartViewModel?.visibleInIntervalAABB?.copyWithPadding(date: 0, value: 0.1)
    }
    
    private var polygonLinesView: PolygonLinesView = PolygonLinesView()
    private var horizontalAxisView: HorizontalAxisView = HorizontalAxisView()

    public init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        
        configureSubviews()
        makeConstaints()
    }

    public func setStyle(_ style: ChartStyle) {
        horizontalAxisView.setStyle(style)
    }
    
    public func setChart(_ chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel
        chartViewModel.registerUpdateListener(self)
        
        polygonLinesView.setPolygonLines(chartViewModel.polygonLines)
        polygonLinesView.update(aabb: visibleAABB, animated: false)
        
        horizontalAxisView.setFullInterval(chartViewModel.interval)
        horizontalAxisView.update(aabb: visibleAABB, animated: false)
    }
    
    private func configureSubviews()
    {
        polygonLinesView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(polygonLinesView)
        
        horizontalAxisView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalAxisView)
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
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension ChartView: ChartUpdateListener
{
    public func chartVisibleIsChanged(_ viewModel: ChartViewModel) {
        polygonLinesView.update(aabb: visibleAABB, animated: true)
    }

    public func chartIntervalIsChanged(_ viewModel: ChartViewModel) {
        polygonLinesView.update(aabb: visibleAABB, animated: false)
        horizontalAxisView.update(aabb: visibleAABB, animated: true)
    }
}
