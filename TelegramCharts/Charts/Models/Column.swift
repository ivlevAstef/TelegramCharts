//
//  Chart.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

public struct Column
{
    public typealias Value = Int
    
    public enum ColumnType {
        case line
        case bar
        case area
    }

    public let name: String
    public let values: [Value]
    public let color: String
    
    public let type: ColumnType
}
