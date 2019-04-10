//
//  CColumnViewModel.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

public class ColumnViewModel
{
    public typealias Value = Column.Value

    public struct Color
    {
        public let r: UInt8
        public let g: UInt8
        public let b: UInt8
    }
    
    public enum ColumnType {
        case line
        case bar
        case area
    }

    public let name: String
    public let values: [Value]
    public let color: UIColor
    public let type: ColumnType
    
    public internal(set) var isVisible: Bool = true

    public init(name: String, values: [Value], color: UIColor, type: ColumnType) {
        self.name = name
        self.values = values
        self.color = color
        self.type = type
    }
}
