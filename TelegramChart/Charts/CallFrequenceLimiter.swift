//
//  CallFrequenceLimiter.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 12/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation

internal final class CallFrequenceLimiter
{
    private var updateBlock: DispatchWorkItem?
    private var deadline: DispatchTime = .now()
    
    internal init() {
        
    }
    
    internal func update(_ block: @escaping () -> DispatchTimeInterval) {
#if TEST_PERFORMANCE
        block()
#else
        self.updateBlock?.cancel()
        let updateBlock = DispatchWorkItem { [weak self] in
            let delay = block()
            self?.deadline = .now() + delay
        }
        self.updateBlock = updateBlock

        if DispatchTime.now() >= deadline {
            updateBlock.perform()
        } else {
            DispatchQueue.main.asyncAfter(deadline: deadline, execute: updateBlock)
        }
#endif
    }
}
