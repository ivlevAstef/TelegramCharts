//
//  ArrowView.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 13/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal final class ArrowView: UIImageView
{
    
    init(reverse: Bool, size: CGSize, offset: CGSize)
    {
        super.init(image: ArrowView.makeArrow(reverse: reverse, size: size, offset: offset))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func makeArrow(reverse: Bool, size: CGSize, offset: CGSize) -> UIImage? {
        let centerArrowX: CGFloat = offset.width
        let edgeArrowX: CGFloat = size.width - offset.width
        let arrowHeight: CGFloat = size.height - 2 * offset.height
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width, height: size.height), false, UIScreen.main.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        context.beginPath()
        if reverse {
            context.move(to: CGPoint(x: size.width - edgeArrowX, y: offset.height))
            context.addLine(to: CGPoint(x: size.width - centerArrowX, y: offset.height + arrowHeight * 0.5))
            context.addLine(to: CGPoint(x: size.width - edgeArrowX, y: offset.height + arrowHeight))
        } else {
            context.move(to: CGPoint(x: edgeArrowX, y: offset.height))
            context.addLine(to: CGPoint(x: centerArrowX, y: offset.height + arrowHeight * 0.5))
            context.addLine(to: CGPoint(x: edgeArrowX, y: offset.height + arrowHeight))
        }
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.withRenderingMode(.alwaysTemplate)
    }
}
