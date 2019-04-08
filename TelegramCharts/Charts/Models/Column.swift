//
//  Chart.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

public struct Column
{
    public typealias Date = Int64
    public typealias Value = Int

    public struct Point
    {
        public let date: Date
        public let value: Value
    }
    
    public enum ColumnType {
        case line
        case bar
        case area
    }

    public let name: String
    public let points: [Point]
    public let color: String
    
    public let type: ColumnType
}
