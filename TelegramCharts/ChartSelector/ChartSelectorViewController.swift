//
//  ChartSelectorViewController.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 20/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal class ChartSelectorViewController: UITableViewController, Stylizing
{
    // ideally need DI, ServiceLocator or other
    private let chartProvider: ChartProvider = ChartProvider()

    private var loadedCharts: [[PolygonLine]] = []

    internal override func viewDidLoad() {
        super.viewDidLoad()

        chartProvider.getCharts { [weak self] result in
            DispatchQueue.main.async {
                self?.processChartsResult(result)
            }
        }

        title = "Charts"
    }

    internal override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyStyle(StyleController.currentStyle)
    }

    internal override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mainVC = segue.destination as? MainViewController, let index = sender as? Int {
            mainVC.setName("Chart \(index + 1)")
            if let polylines = loadedCharts[safe: index] {
                mainVC.setChart(ChartViewModel(polygonLines: polylines, from: 0.6, to: 1.0))
            } else {
                assertionFailure("Can't found chart by index: \(index)")
            }
        }
    }

    internal func applyStyle(_ style: Style) {
        tableView.backgroundColor = style.backgroundColor
        tableView.separatorColor = style.separatorColor
        tableView.separatorStyle = .singleLine

        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: style.titleColor]
        navigationController?.navigationBar.barTintColor = style.mainColor
        navigationController?.navigationBar.layoutIfNeeded()

        StyleController.recursiveApplyStyle(on: tableView, style: style)
    }

    private func processChartsResult(_ result: ChartProvider.Result) {
        switch result {
        case .success(let charts):
            loadedCharts = charts
            tableView.reloadData()
        case .failed:
            showError()
        }
    }

    private func showError() {
        let alert = UIAlertController(title: "Error", message: "It's error - can't parse json?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    // MARK: Table View
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight(for: indexPath)
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight(for: indexPath)
    }

    private func cellHeight(for indexPath: IndexPath) -> CGFloat {
       return 80
    }

    internal override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loadedCharts.count
    }

    internal override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chartCell: ChartPreviewTableViewCell = dequeueReusableCell(for: indexPath)
        chartCell.applyStyle(StyleController.currentStyle)
        chartCell.setName("Chart \(indexPath.row + 1)")

        guard let polylines = loadedCharts[safe: indexPath.row] else {
            assertionFailure("not found chart by index: \(indexPath.row)")
            return chartCell
        }

        chartCell.setChart(ChartViewModel(polygonLines: polylines, from: 0.0, to: 1.0))

        return chartCell
    }

    internal override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ToChart", sender: indexPath.row)
    }
}

