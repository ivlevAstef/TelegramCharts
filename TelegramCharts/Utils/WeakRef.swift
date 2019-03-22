//
//  WeakRef.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 13/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

public final class WeakRef<Value>
{
    public var value: Value? {
        return self.weakValue as? Value
    }

    private weak var weakValue: AnyObject? // для работы с протоколами

    public init(_ value: Value)
    {
        self.weakValue = value as AnyObject
    }
}

