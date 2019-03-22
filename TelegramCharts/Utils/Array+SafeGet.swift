//
//  Array+SafeGet.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

extension Array
{
    subscript(safe index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        }
        return nil
    }
}
