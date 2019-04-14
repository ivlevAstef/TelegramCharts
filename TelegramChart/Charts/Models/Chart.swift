//
//  Chart.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 09/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

public struct Chart
{
    public typealias Date = Int64
    
    public let name: String
    public let dates: [Date]
    public let columns: [Column]
    public let yScaled: Bool
    public let stacked: Bool
    public let percentage: Bool
}
