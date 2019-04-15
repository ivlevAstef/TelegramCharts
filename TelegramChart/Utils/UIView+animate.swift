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
    
    public func shake(distance: CGFloat, duration: TimeInterval, completion: (() -> Void)? = nil) {
        let step = duration / 4
        self.moveX(x: -distance, duration: step) { [weak self] in
            self?.moveX(x: 2 * distance, duration: step) {
                self?.moveX(x: -2 * distance, duration: step) {
                    self?.moveX(x: distance, duration: step) {
                        completion?()
                    }
                }
            }
        }
    }
    
    private func setX(x: CGFloat, duration: TimeInterval, completion: @escaping () -> Void) {
        var frame = self.frame
        frame.origin.x = x
        
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.frame = frame
        }, completion: { _ in
            completion()
        })
    }
    
    private func moveX(x: CGFloat, duration: TimeInterval, completion: @escaping () -> Void) {
        self.setX(x: frame.origin.x + x, duration: duration, completion: completion)
    }
}
