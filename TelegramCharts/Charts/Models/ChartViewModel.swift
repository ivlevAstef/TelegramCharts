//
//  ChartViewModel.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation
import UIKit

public class ChartViewModel
{
    public struct Point
    {
        public let date: Date
        public let value: Int
    }

    public struct Color
    {
        public let r: UInt8
        public let g: UInt8
        public let b: UInt8
    }

    public let name: String
    public let points: [Point]
    public let color: UIColor
    public internal(set) var isEnabled: Bool = true

    public init(name: String, points: [Point], color: UIColor) {
        self.name = name
        self.points = points
        self.color = color
    }
}
