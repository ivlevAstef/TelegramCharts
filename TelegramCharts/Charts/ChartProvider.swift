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
    public func getCharts(_ completion: @escaping ([[PolygonLine]]) -> Void) {
        guard let rawCharts = self.loadChartsFromFile() else {
            completion([])
            return
        }

        let charts = rawCharts.map{ self.convertToModel($0) }
        completion(charts)
    }

    private func loadChartsFromFile() -> [RawChart]? {
        guard let path = Bundle.main.path(forResource: "chart_data", ofType: "json") else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode([RawChart].self, from: data)
    }

    private func convertToModel(_ rawCharts: RawChart) -> [PolygonLine] {
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

        var result: [PolygonLine] = []

        for column in rawCharts.columns {
            guard let id = column[safe: 0]?.name else {
                continue
            }
            
            guard let name = rawCharts.names[id], let type = rawCharts.types[id], let color = rawCharts.colors[id] else {
                continue
            }
            
            if column.isEmpty && type != "line" && id != timestampId {
                continue
            }

            let values = column.dropFirst().compactMap{ $0.value }
            assert(values.count == timestamps.count, "incorrect json - timestamp length not equals \(id) length")

            let points = zip(timestamps, values).map { pair -> PolygonLine.Point in
                let (timestamp, value) = pair
                return PolygonLine.Point(date: timestamp, value: Int(value))
            }

            result.append(PolygonLine(name: name, points: points, color: color))
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
