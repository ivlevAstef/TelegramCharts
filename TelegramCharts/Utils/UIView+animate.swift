//
//  UIView+animate.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 20/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

extension UIView
{
    public class func animateIf(_ animated: Bool, duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        if animated {
            self.animate(withDuration: duration, animations: animations, completion: completion)
        } else {
            animations()
            completion?(true)
        }
    }
}
