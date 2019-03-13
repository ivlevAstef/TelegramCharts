//
//  ChartsProvider.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation

public class ChartsProvider
{
    public enum Result
    {
        case success(_ charts2D: [[Chart]])
        case failed
    }

    public func getCharts(_ completion: @escaping (Result) -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let `self` = self else {
                completion(.failed)
                return
            }
            guard let rawCharts2D = self.loadChartsFromFile() else {
                completion(.failed)
                return
            }

            let charts2D = rawCharts2D.map{ self.convertToModel($0) }
            completion(.success(charts2D))
        }
    }

    private func loadChartsFromFile() -> [RawCharts]? {
        guard let path = Bundle.main.path(forResource: "chart_data", ofType: "json") else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode([RawCharts].self, from: data)
    }

    private func convertToModel(_ rawCharts: RawCharts) -> [Chart]
    {
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

        var result: [Chart] = []

        for (id, type) in rawCharts.types where type == "line" {
            guard let name = rawCharts.names[id], let color = rawCharts.colors[id] else {
                continue
            }
            guard let column = rawCharts.columns.first(where: { $0[safe: 0]?.name == id }) else {
                continue
            }
            if column.isEmpty {
                continue
            }

            let values = column.dropFirst().compactMap{ $0.value }
            assert(values.count == timestamps.count, "incorrect json - timestamp length not equals \(id) length")

            let points = zip(timestamps, values).map { pair -> Chart.Point in
                let (timestamp, value) = pair
                return Chart.Point(date: timestamp, value: Int(value))
            }

            result.append(Chart(name: name, points: points, color: color))
        }

        return result
    }
}

private struct RawColumn: Decodable
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

private struct RawCharts: Decodable
{
    internal typealias ChartName = String
    internal typealias ChartType = String

    internal let columns: [[RawColumn]]
    internal let types: [ChartName: ChartType]
    internal let names: [ChartName: String]
    internal let colors: [ChartName: String]
}
