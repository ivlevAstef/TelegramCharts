//
//  ChartTableViewCell.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

private enum Consts {
    internal static let margins: UIEdgeInsets = layoutMargins
    internal static let internalMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: layoutMargins.left, bottom: 0, right: layoutMargins.right)
}

internal class ChartTableViewCell: UITableViewCell, Stylizing, IActualizedCell
{
    internal let identifier: String = "ChartTableViewCell"
    
    internal var hintClickHandler: ((_ date: Chart.Date) -> Void)?
    
    override internal var frame: CGRect {
        didSet { updateFrame() }
    }
    private var prevFrame: CGRect = .zero

    private let chartView = ChartWithIntervalView(margins: Consts.internalMargins, intervalViewHeight: nil)

    internal init() {
        super.init(style: .default, reuseIdentifier: nil)

        self.selectionStyle = .none

        chartView.translatesAutoresizingMaskIntoConstraints = true
        contentView.addSubview(chartView)
        
        chartView.hintClickHandler = { [weak self] date in
            self?.hintClickHandler?(date)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func actualizeFrame(width: CGFloat) {
        let height =  min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        self.frame = CGRect(x: 0, y: 0, width: width, height: height)
    }
    
    internal func updateFrame() {
        if prevFrame.size.equalTo(frame.size) {
            return
        }
        prevFrame = frame
        
        chartView.frame = CGRect(x: 0,
                                 y: Consts.margins.top,
                                 width: frame.width,
                                 height: frame.height - Consts.margins.top - Consts.margins.bottom)
    }

    internal func applyStyle(_ style: Style) {
        backgroundColor = style.mainColor
        chartView.backgroundColor = style.mainColor

        chartView.setStyle(style.chartStyle)
    }

    internal func setChart(_ chartViewModel: ChartViewModel) {
        chartView.setChart(chartViewModel)
    }
}
