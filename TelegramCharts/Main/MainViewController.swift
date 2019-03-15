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
    private let chartsProvider: ChartsProvider = ChartsProvider()
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

    private var chartsViewModel: ChartsViewModel? = nil

    internal override func viewDidLoad() {
        super.viewDidLoad()

        applyStyle(currentStyle)
        chartsProvider.getCharts { [weak self] result in
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
    }

    private func processChartsResult(_ result: ChartsProvider.Result) {
        switch result {
        case .success(let charts2D):
            configureChartsViewModel(use: charts2D)
        case .failed:
            showError()
        }
    }

    private func configureChartsViewModel(use charts2D: [[Chart]]) {
        // TODO: need other screen, for select?
        chartsViewModel = ChartsViewModel(charts: charts2D[4])
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
                return ChartsTableViewCell.calculateHeight()
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
            return 1 + (chartsViewModel?.charts.count ?? 0)
        case 1:
            return 1
        default:
            assertionFailure("It's not ideally code, but it doesn't matter")
        }
        return 0
    }

    internal override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell & Stylizing

        switch indexPath.section {
        case 0:
            if 0 == indexPath.row {
                let chartsCell: ChartsTableViewCell = dequeueReusableCell(for: indexPath)
                if let chartsViewModel = self.chartsViewModel {
                    chartsCell.setCharts(chartsViewModel)
                }
                cell = chartsCell
            } else {
                let index = indexPath.row - 1
                guard let chart = self.chartsViewModel?.charts[safe: index] else {
                    fatalError("Charts view models mismatch chart for index: \(index)")
                }
                let infoChartCell: InfoChartTableViewCell = dequeueReusableCell(for: indexPath)
                infoChartCell.setColor(chart.color)
                infoChartCell.setChartName(chart.name)
                infoChartCell.setCheckmark(chart.isVisible)
                cell = infoChartCell
            }
        case 1:
            let switchStyleCell: SwitchStyleModeTableViewCell = dequeueReusableCell(for: indexPath)
            switchStyleCell.setText("Switch to \(currentStyle.next().name) Mode")
            switchStyleCell.tapCallback = { [weak self] in
                self?.switchStyle()
            }
            cell = switchStyleCell
        default:
            fatalError("It's not ideally code, but it doesn't matter")
        }

        cell.applyStyle(currentStyle)

        return cell
    }

    internal override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if 0 == indexPath.section && indexPath.row > 0 {
            let index = indexPath.row - 1
            guard let chart = self.chartsViewModel?.charts[safe: index] else {
                fatalError("Charts view models mismatch chart for index: \(index)")
            }

            self.chartsViewModel?.toogleChart(chart)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    internal func switchStyle() {
        currentStyle = currentStyle.next()
        applyStyle(currentStyle)
        tableView.reloadData()
    }
}
