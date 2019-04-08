//
//  UIView+animate.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 20/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

extension UIView
{
    public class func animateIf(_ animated: Bool, duration: TimeInterval, options: UIView.AnimationOptions = .curveEaseInOut, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        if animated {
            
            self.animate(withDuration: duration, delay: 0, options: options, animations: animations, completion: completion)
        } else {
            animations()
            completion?(true)
        }
    }
}
