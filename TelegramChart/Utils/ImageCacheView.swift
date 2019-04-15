//
//  ImageCacheView.swift
//  TelegramChart
//
//  Created by Alexander Ivlev on 15/04/2019.
//  Copyright © 2019 SIA. All rights reserved.
//

import UIKit

public final class ImageCacheView: UIImageView
{
    var cacheMethod: ((CGContext) -> Void)?
    
    private var updateCacheBlock: DispatchWorkItem?
    
    public init() {
        super.init(image: nil)
    }
    
    public func cache(in size: CGSize) -> UIImage?
    {
        guard let executor = cacheMethod else {
            return nil
        }
        
        return ImageCacheView.cache(in: size, executor: executor)
    }
    
    public func cacheAfter(deadline: DispatchTime, in size: CGSize, success: @escaping (UIImage?) -> Void) {
        updateCacheBlock?.cancel()
        
        var capturedBlock: DispatchWorkItem!
        let block = DispatchWorkItem { [weak self] in
            guard let `self` = self else {
                return
            }
            let image = self.cache(in: size)
            DispatchQueue.main.asyncAfter(deadline: deadline) {
                if !capturedBlock.isCancelled {
                    success(image)
                }
            }
        }
        capturedBlock = block
        updateCacheBlock = block

        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: deadline, execute: block)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func cache(in size: CGSize, executor: ((CGContext) -> Void)) -> UIImage?
    {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        executor(context)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
