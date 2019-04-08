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
    public func getCharts(_ completion: @escaping ([[Column]]) -> Void) {
        var anyRawCharts: [RawChart] = []
        for chartIndex in 1...5 {
            if let rawChart = loadChartFromFile(path: "chart_data/\(chartIndex)/overview") {
                anyRawCharts.append(rawChart)
            }
        }
        
        let charts = anyRawCharts.map{ self.convertToModel($0) }
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

    private func convertToModel(_ rawCharts: RawChart) -> [Column] {
        guard let timestampId = rawCharts.types.first(where: { $0.value == "x" })?.key else {
            return []
        }
        guard let timestampColumn = rawCharts.columns.first(where: { $0[safe: 0]?.name == timestampId }) else {
            return []
        }
        if timestampColumn.isEmpty {
            return []
        }

        let timestamps = timestampColumn.dropFirst().compactMap{ $0.value }
        assert(timestamps == timestamps.sorted(), "Invalid data. Timestamps doen't sort.")

        var result: [Column] = []

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

            let values = column.dropFirst().compactMap{ $0.value }
            assert(values.count == timestamps.count, "incorrect json - timestamp length not equals \(id) length")

            let points = zip(timestamps, values).map { pair -> Column.Point in
                let (timestamp, value) = pair
                return Column.Point(date: timestamp, value: Int(value))
            }

            result.append(Column(name: name, points: points, color: color, type: type))
        }

        return result
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
}
