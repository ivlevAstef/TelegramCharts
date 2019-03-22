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
    
    private var subTitleColor: UIColor = .white
    private var chartViewModels: [ChartViewModel] = []

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

        StyleController.recursiveApplyStyle(on: tableView, style: style)
    }
    
    private func processChartsResult(_ result: [[PolygonLine]]) {
        chartViewModels = result.map { ChartViewModel(polygonLines: $0, from: 0.6, to: 1.0) }
        tableView.reloadData()
    }

    // MARK: Table View
    internal override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + chartViewModels.count
    }

    internal override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight(for: indexPath)
    }
    
    internal override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight(for: indexPath)
    }
    
    private func cellHeight(for indexPath: IndexPath) -> CGFloat {
        if 0 <= indexPath.section && indexPath.section < chartViewModels.count {
            if 0 == indexPath.row {
                return ChartTableViewCell.calculateHeight()
            }
            return 44
        }
        
        return 50
    }
    
    internal override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    internal override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section < chartViewModels.count {
            let label = UILabel(frame: CGRect(x: 16, y: 16, width: tableView.bounds.width - 16, height: 16))
            label.font = UIFont.systemFont(ofSize: 14.0)
            label.textColor = subTitleColor
            label.text = "CHART \(section + 1)"
            
            let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 36))
            view.addSubview(label)
            
            return view
        }
        
        return nil
    }
    
    internal override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    internal override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if 0 <= section && section < chartViewModels.count {
            return 1 + chartViewModels[section].polygonLines.count
        }
        
        return 1
    }

    internal override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if 0 <= indexPath.section && indexPath.section < chartViewModels.count {
            let chartViewModel = chartViewModels[indexPath.section]
            
            if 0 == indexPath.row {
                let chartCell: ChartTableViewCell = dequeueReusableCell(for: indexPath)
                chartCell.applyStyle(StyleController.currentStyle)
                chartCell.setChart(chartViewModel)
                
                return chartCell
            }
            
            let index = indexPath.row - 1
            let polygonLine = chartViewModel.polygonLines[index]
            
            let infoChartCell: InfoPolygonLineTableViewCell = dequeueReusableCell(for: indexPath)
            infoChartCell.applyStyle(StyleController.currentStyle)
            infoChartCell.setColor(polygonLine.color)
            infoChartCell.setName(polygonLine.name)
            infoChartCell.setCheckmark(polygonLine.isVisible)
            return infoChartCell
        }
        
        let switchStyleCell: SwitchStyleModeTableViewCell = dequeueReusableCell(for: indexPath)
        switchStyleCell.applyStyle(StyleController.currentStyle)
        switchStyleCell.setText("Switch to \(StyleController.nextStyle.name) Mode")
        switchStyleCell.tapCallback = { [weak self] in
            self?.switchStyle()
        }
        
        return switchStyleCell
    }

    internal override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if 0 <= indexPath.section && indexPath.section < chartViewModels.count && indexPath.row >= 1 {
            let index = indexPath.row - 1
            
            let chartViewModel = chartViewModels[indexPath.section]
            let polygonLine = chartViewModel.polygonLines[index]
            chartViewModel.toogleVisiblePolygonLine(polygonLine)
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
