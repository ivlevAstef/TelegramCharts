//
//  MainViewController.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

internal class MainViewController: UITableViewController, Stylizing
{
    // ideally need DI, ServiceLocator or other
    private let chartProvider: ChartProvider = ChartProvider()
    
    private var subTitleColor: UIColor = .white
    private var statusBarStyle: UIStatusBarStyle = .default
    private var chartViewModels: [ChartViewModel] = []

    private var cellCache: [IndexPath: UITableViewCell & IActualizedCell & Stylizing] = [:]

    @IBOutlet private var switchStyleButton: UIBarButtonItem!
  
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    internal override func viewDidLoad() {
        super.viewDidLoad()
        
        applyStyle(StyleController.currentStyle)

        title = "Statistics"
        
        chartProvider.getCharts { [weak self] result in
            self?.processChartsResult(result)
        }
    }

    internal func applyStyle(_ style: Style) {
        tableView.backgroundColor = style.backgroundColor
        tableView.separatorColor = style.separatorColor
        tableView.separatorStyle = .singleLine

        subTitleColor = style.subTitleColor

        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: style.titleColor]
        navigationController?.navigationBar.barTintColor = style.mainColor
        navigationController?.navigationBar.layoutIfNeeded()

        statusBarStyle = style.statusBarStyle
        setNeedsStatusBarAppearanceUpdate()

        for cell in cellCache.values {
            cell.applyStyle(style)
        }
        
        switchStyleButton.tintColor = style.activeElementColor
        switchStyleButton.title = textForSwitch(by: StyleController.nextStyle)
    }

    
    private func textForSwitch(by style: Style) -> String {
        return "\(style.name) Mode"
    }
    
    private func processChartsResult(_ result: [Chart]) {
        chartViewModels = result.map { ChartViewModel(chart: $0, from: 0.6, to: 1.0) }
        tableView.reloadData()
    }

    // MARK: Table View
    internal override func numberOfSections(in tableView: UITableView) -> Int {
        return chartViewModels.count
    }

    internal override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight(for: indexPath)
    }
    
    internal override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight(for: indexPath)
    }
    
    internal override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    internal override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 16, y: 16, width: tableView.bounds.width - 16, height: 16))
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = subTitleColor
        label.text = chartViewModels[safe: section]?.name
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 36))
        view.addSubview(label)
        
        return view
    }
    
    internal override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    internal override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if 0 <= section && section < chartViewModels.count {
            return 2 // Chart + switch column visible
        }
        
        return 0
    }

    internal override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return makeCellWithUseCache(indexPath: indexPath)
    }

    private func cellHeight(for indexPath: IndexPath) -> CGFloat {
        let cell = makeCellWithUseCache(indexPath: indexPath)
        return cell.frame.height
    }

    private func makeCellWithUseCache(indexPath: IndexPath) -> UITableViewCell {
        if let cell = cellCache[indexPath] {
            return cell
        }

        let cell = makeCell(indexPath: indexPath)
        cellCache[indexPath] = cell
        return cell
    }

    private func makeCell(indexPath: IndexPath) -> UITableViewCell & IActualizedCell & Stylizing {
        if !(0 <= indexPath.section && indexPath.section < chartViewModels.count) {
            fatalError("incorrect section number: \(indexPath.section)")
        }

        let chartViewModel = chartViewModels[indexPath.section]

        if 0 == indexPath.row {
            let chartCell = ChartTableViewCell()
            chartCell.actualizeFrame(width: tableView.bounds.width)
            chartCell.applyStyle(StyleController.currentStyle)
            chartCell.setChart(chartViewModel)

            return chartCell
        }

        let switchColumnVisibleCell = SwitchColumnVisibleTableViewCell()
        switchColumnVisibleCell.actualizeFrame(width: tableView.bounds.width)
        for columnVM in chartViewModel.columns {
            switchColumnVisibleCell.addColumnVisibleToogler(
                name: columnVM.name,
                color: columnVM.color,
                isVisible: columnVM.isVisible,
                clickHandler: { [weak chartViewModel] in
                    return chartViewModel?.toogleVisibleColumn(columnVM) ?? false
            })
        }

        switchColumnVisibleCell.applyStyle(StyleController.currentStyle)

        return switchColumnVisibleCell
    }

    @IBAction private func switchStyle(_ sender: Any) {
        StyleController.next()
        UIView.animate(withDuration: 0.1) { [weak self, style = StyleController.currentStyle] in
            self?.applyStyle(style)
        }
    }
}
