//
//  MainViewController.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class MainViewController: UITableViewController, Stylizing
{
    // it's laziness
    private lazy var headerLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 14, y: 30, width: 260, height: 16))
        label.font = UIFont.systemFont(ofSize: 14.0)

        return label
    }()
    private lazy var header: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        view.addSubview(headerLabel)

        return view
    }()

    private var chartViewModel: ChartViewModel? = nil

    internal override func viewDidLoad() {
        super.viewDidLoad()

        applyStyle(StyleController.currentStyle)

        title = "Statistics"
        tableView.tableHeaderView = header
    }

    internal func setName(_ name: String) {
        headerLabel.text = name
    }

    internal func setChart(_ chartViewModel: ChartViewModel) {
        self.chartViewModel = chartViewModel
    }

    internal func applyStyle(_ style: Style) {
        tableView.backgroundColor = style.backgroundColor
        tableView.separatorColor = style.separatorColor
        tableView.separatorStyle = .singleLine

        headerLabel.textColor = style.subTitleColor

        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: style.titleColor]
        navigationController?.navigationBar.barTintColor = style.mainColor
        navigationController?.navigationBar.layoutIfNeeded()

        StyleController.recursiveApplyStyle(on: tableView, style: style)
    }

    // MARK: Table View
    internal override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight(for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight(for: indexPath)
    }
    
    private func cellHeight(for indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            if 0 == indexPath.row {
                return ChartTableViewCell.calculateHeight()
            }
            return 44
        case 1:
            return 50
        default:
            return 44
        }
    }

    internal override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 + (chartViewModel?.polygonLines.count ?? 0)
        case 1:
            return 1
        default:
            assertionFailure("It's not ideally code, but it doesn't matter")
        }
        return 0
    }

    internal override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if 0 == indexPath.row {
                let chartCell: ChartTableViewCell = dequeueReusableCell(for: indexPath)
                chartCell.applyStyle(StyleController.currentStyle)
                if let chartViewModel = self.chartViewModel {
                    chartCell.setChart(chartViewModel)
                }
                return chartCell
            } else {
                let index = indexPath.row - 1
                guard let polygonLine = self.chartViewModel?.polygonLines[safe: index] else {
                    fatalError("Charts view models mismatch chart for index: \(index)")
                }
                let infoChartCell: InfoPolygonLineTableViewCell = dequeueReusableCell(for: indexPath)
                infoChartCell.applyStyle(StyleController.currentStyle)
                infoChartCell.setColor(polygonLine.color)
                infoChartCell.setName(polygonLine.name)
                infoChartCell.setCheckmark(polygonLine.isVisible)
                return infoChartCell
            }
        case 1:
            let switchStyleCell: SwitchStyleModeTableViewCell = dequeueReusableCell(for: indexPath)
            switchStyleCell.applyStyle(StyleController.currentStyle)
            switchStyleCell.setText("Switch to \(StyleController.nextStyle.name) Mode")
            switchStyleCell.tapCallback = { [weak self] in
                self?.switchStyle()
            }
            return switchStyleCell
        default:
            fatalError("It's not ideally code, but it doesn't matter")
        }
    }

    internal override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if 0 == indexPath.section && indexPath.row > 0 {
            let index = indexPath.row - 1
            guard let polygonLine = self.chartViewModel?.polygonLines[safe: index] else {
                fatalError("Charts view models mismatch chart for index: \(index)")
            }

            self.chartViewModel?.toogleVisiblePolygonLine(polygonLine)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    internal func switchStyle() {
        StyleController.next()
        UIView.animate(withDuration: 0.1) { [weak self, style = StyleController.currentStyle] in
            self?.applyStyle(style)
        }
    }
}
