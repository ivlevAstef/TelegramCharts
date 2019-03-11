//
//  Chart.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation

public struct Chart
{
    public struct Point
    {
        public let date: Date
        public let value: Int
    }

    public let name: String
    public let points: [Point]
    public let color: String
}
