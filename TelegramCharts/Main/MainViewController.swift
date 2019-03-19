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
    // ideally need DI, ServiceLocator or other
    private let chartProvider: ChartProvider = ChartProvider()
    private var currentStyle: Style = Style.dayStyle

    // it's laziness
    private lazy var followersHeaderLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 14, y: 30, width: 260, height: 16))
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.text = "FOLLOWERS"

        return label
    }()
    private lazy var followersHeader: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        view.addSubview(followersHeaderLabel)

        return view
    }()
    
    @IBOutlet private var chartSegmentControl: UISegmentedControl!
    private var loadedCharts: [[PolygonLine]] = []
    private var chartViewModel: ChartViewModel? = nil

    internal override func viewDidLoad() {
        super.viewDidLoad()

        chartSegmentControl.removeAllSegments()
        applyStyle(currentStyle)

        chartProvider.getCharts { [weak self] result in
            DispatchQueue.main.async {
                self?.processChartsResult(result)
            }
        }

        title = "Statistics"
        tableView.tableHeaderView = followersHeader
    }

    internal func applyStyle(_ style: Style) {
        tableView.backgroundColor = style.backgroundColor
        tableView.separatorColor = style.separatorColor
        tableView.separatorStyle = .singleLine
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: style.titleColor]
        navigationController?.navigationBar.barTintColor = style.mainColor
        followersHeaderLabel.textColor = style.subTitleColor
        chartSegmentControl.tintColor = style.activeElementColor
    }

    private func processChartsResult(_ result: ChartProvider.Result) {
        switch result {
        case .success(let charts):
            loadedCharts = charts
            configureSegmentControl(use: charts)
            selectChart(at: chartSegmentControl.selectedSegmentIndex)
        case .failed:
            showError()
        }
    }

    private func configureSegmentControl(use charts: [[PolygonLine]]) {
        chartSegmentControl.removeAllSegments()

        for i in 0..<charts.count {
            chartSegmentControl.insertSegment(withTitle: "\(i + 1)", at: i, animated: false)
        }
        chartSegmentControl.selectedSegmentIndex = 0
    }

    @IBAction private func selectChart(_ sender: UISegmentedControl) {
        selectChart(at: sender.selectedSegmentIndex)
    }

    private func selectChart(at index: Int) {
        guard let polygonLines = loadedCharts[safe: index] else {
            assertionFailure("Can't find chart at index: \(index)")
            return
        }

        chartViewModel = ChartViewModel(polygonLines: polygonLines)
        tableView.reloadData()
    }

    private func showError() {
        let alert = UIAlertController(title: "Error", message: "It's error - can't parse json?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(alert, animated: true, completion: nil)
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
                chartCell.applyStyle(currentStyle)
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
                infoChartCell.applyStyle(currentStyle)
                infoChartCell.setColor(polygonLine.color)
                infoChartCell.setName(polygonLine.name)
                infoChartCell.setCheckmark(polygonLine.isVisible)
                return infoChartCell
            }
        case 1:
            let switchStyleCell: SwitchStyleModeTableViewCell = dequeueReusableCell(for: indexPath)
            switchStyleCell.applyStyle(currentStyle)
            switchStyleCell.setText("Switch to \(currentStyle.next().name) Mode")
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
        currentStyle = currentStyle.next()
        applyStyle(currentStyle)
        tableView.reloadData()
    }
}
