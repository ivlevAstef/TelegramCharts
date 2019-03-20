//
//  Chart.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

public struct PolygonLine
{
    public typealias Date = Int64
    public typealias Value = Int

    public struct Point
    {
        public let date: Date
        public let value: Value
    }

    public let name: String
    public let points: [Point]
    public let color: String
}
