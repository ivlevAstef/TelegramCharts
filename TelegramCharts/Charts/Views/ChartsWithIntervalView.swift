//
//  ChartsWithIntervalView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

public class ChartsWithIntervalView: UIView
{
    private static let defaultIntervalViewHeight: CGFloat = 40.0

    private let chartsView: ChartsView = ChartsView()
    private let intervalView: IntervalView = IntervalView()

    public init(intervalViewHeight: CGFloat? = nil) {
        super.init(frame: .zero)

        configureSubviews()
        makeConstaints(intervalViewHeight: intervalViewHeight ?? ChartsWithIntervalView.defaultIntervalViewHeight)
    }

    public func setStyle(_ style: ChartsStyle) {
        self.intervalView.unvisibleColor = style.intervalUnvisibleColor
        self.intervalView.borderColor = style.intervalBorderColor
    }

    public func setCharts(_ charts: ChartsViewModel) {
        chartsView.setCharts(charts)
        intervalView.setCharts(charts)
    }

    public static func calculateHeight() -> CGFloat {
        return UIScreen.main.bounds.width
    }

    private func configureSubviews() {
        chartsView.translatesAutoresizingMaskIntoConstraints = false
        intervalView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartsView)
        addSubview(intervalView)
    }

    private func makeConstaints(intervalViewHeight: CGFloat) {
        self.chartsView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.chartsView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.chartsView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true

        self.chartsView.bottomAnchor.constraint(equalTo: self.intervalView.topAnchor).isActive = true

        self.intervalView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.intervalView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.intervalView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.intervalView.heightAnchor.constraint(equalToConstant: intervalViewHeight).isActive = true
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configureSubviews()
        makeConstaints(intervalViewHeight: ChartsWithIntervalView.defaultIntervalViewHeight)
    }
}
