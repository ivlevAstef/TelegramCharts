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
}

internal class ChartTableViewCell: UITableViewCell, Stylizing
{
    internal let identifier: String = "ChartTableViewCell"
    
    override internal var frame: CGRect {
        didSet { updateFrame() }
    }
    private var prevFrame: CGRect = .zero

    private let chartView = ChartWithIntervalView(intervalViewHeight: nil)
    
    internal override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartView)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartView)
    }
    
    internal func updateFrame() {
        if prevFrame.equalTo(frame) {
            return
        }
        prevFrame = frame
        
        chartView.frame = CGRect(x: Consts.margins.left,
                                 y: Consts.margins.top,
                                 width: frame.width - Consts.margins.left - Consts.margins.right,
                                 height: frame.height - Consts.margins.top - Consts.margins.bottom)
    }

    internal func applyStyle(_ style: Style) {
        backgroundColor = style.mainColor
        chartView.backgroundColor = style.mainColor

        chartView.setStyle(style.chartStyle)
    }

    internal func setChart(_ chartViewModel: ChartViewModel) {
        prevFrame = .zero
        chartView.setChart(chartViewModel)
    }

    internal static func calculateHeight() -> CGFloat {
        return ChartWithIntervalView.calculateHeight()
    }
}
