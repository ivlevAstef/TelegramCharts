//
//  ChartProvider.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import Foundation

public class ChartProvider
{
    public func getCharts(_ completion: @escaping ([Chart]) -> Void) {
        var anyRawChartsWithName: [(RawChart,String)] = []

        guard let resourcePath = Bundle.main.resourcePath as NSString? else {
            completion([])
            return
        }

        let chartDataPath = resourcePath.appendingPathComponent("chart_data")
        guard let fileNames = try? FileManager.default.contentsOfDirectory(atPath: chartDataPath) else {
            completion([])
            return
        }

        let fileInfos: [(String, Int, String)] = fileNames.map { fileName in
            let formattedFileName = fileName.split(separator: "_")
            return (fileName, Int(formattedFileName[0])!, String(formattedFileName[1]))
        }

        for (fileName, _, name) in fileInfos.sorted(by: { $0.1 < $1.1 }) {
            if let rawChart = loadChartFromFile(path: "chart_data/\(fileName)/overview") {
                anyRawChartsWithName.append((rawChart, name))
            }
        }
        
        let charts = anyRawChartsWithName.compactMap { self.convertToModel($0, $1) }
        completion(charts)
    }

    private func loadChartFromFile(path: String) -> RawChart? {
        guard let path = Bundle.main.path(forResource: path, ofType: "json") else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(RawChart.self, from: data)
    }

    private func convertToModel(_ rawCharts: RawChart, _ name: String) -> Chart? {
        guard let timestampId = rawCharts.types.first(where: { $0.value == "x" })?.key else {
            return nil
        }
        guard let timestampColumn = rawCharts.columns.first(where: { $0[safe: 0]?.name == timestampId }) else {
            return nil
        }
        if timestampColumn.isEmpty {
            return nil
        }

        let timestamps = timestampColumn.dropFirst().compactMap{ $0.value }
        assert(timestamps == timestamps.sorted(), "Invalid data. Timestamps doen't sort.")

        var columns: [Column] = []
        for column in rawCharts.columns {
            guard let id = column[safe: 0]?.name else {
                continue
            }
            
            guard let name = rawCharts.names[id], let rawType = rawCharts.types[id], let color = rawCharts.colors[id] else {
                continue
            }
            
            if column.isEmpty || id == timestampId {
                continue
            }
            
            let type: Column.ColumnType
            switch rawType {
            case "line": type = .line
            case "bar": type = .bar
            case "area": type = .area
            default: continue
            }

            let values = column.dropFirst().compactMap { $0.value.flatMap { Int($0) } }
            assert(values.count == timestamps.count, "incorrect json - timestamp length not equals \(id) length")

            columns.append(Column(name: name, values: values.map { Int($0) }, color: color, type: type))
        }
        
        if columns.isEmpty {
            return nil
        }
        
        return Chart(name: name,
                     dates: timestamps,
                     columns: columns,
                     yScaled: rawCharts.y_scaled ?? false,
                     stacked: rawCharts.stacked ?? false,
                     percentage: rawCharts.percentage ?? false)
    }
}

private struct RawCell: Decodable
{
    internal let name: String?
    internal let value: Int64?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int64.self) {
            self.name = nil
            self.value = value
        } else if let name = try? container.decode(String.self) {
            self.name = name
            self.value = nil
        } else {
            fatalError("For what?????")
        }
    }
}

private struct RawChart: Decodable
{
    internal typealias ChartName = String
    internal typealias ChartType = String

    internal let columns: [[RawCell]]
    internal let types: [ChartName: ChartType]
    internal let names: [ChartName: String]
    internal let colors: [ChartName: String]
    
    internal let y_scaled: Bool?
    internal let stacked: Bool?
    internal let percentage: Bool?
}
