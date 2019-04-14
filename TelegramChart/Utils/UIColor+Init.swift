//
//  UIColor+Init.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 11/03/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

extension UIColor
{
    convenience init(r: UInt8, g: UInt8, b: UInt8) {
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
    }

    convenience init(r: UInt8, g: UInt8, b: UInt8, alpha: CGFloat) {
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }


    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }

        if hex.count == 6 {
            var hexValue: UInt32 = 0
            Scanner(string: hex).scanHexInt32(&hexValue)

            self.init(
                red: CGFloat((hexValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((hexValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(hexValue & 0x0000FF) / 255.0,
                alpha: alpha
            )
            return
        }

        if hex.count == 8 {
            var hexValue: UInt32 = 0
            Scanner(string: hex).scanHexInt32(&hexValue)

            self.init(
                red: CGFloat((hexValue & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(hexValue & 0x000000FF) / 255.0
            )
            return
        }

        self.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }

}
