//
//  ColumnsView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 09/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit


internal class ColumnsView
{
    internal var parent: UIView! {
        didSet {
            parent.addSubview(cacheImageView)
        }
    }

    private var columnsViews: [UIView & ColumnView] = []
    private let cacheImageView: UIImageView = UIImageView(frame: .zero)

    private var frame: CGRect = .zero
    private var updateCacheBlock: DispatchWorkItem?

    internal func setChart(_ chartViewModel: ChartViewModel) {
        columnsViews = ColumnsViewFabric.makeColumnViews(by: chartViewModel.columns, size: 2.0, parent: parent)
    }

    internal func update(aabb: AABB?, animated: Bool, duration: TimeInterval) {
        for columnView in columnsViews {
            columnView.update(aabb: aabb, animated: animated, duration: duration)
        }

        cacheUpdate(animated: animated, duration: duration)
    }

    internal func updateFrame(frame: CGRect) {
        self.frame = frame
        for columnView in columnsViews {
            columnView.frame = frame
        }
        cacheImageView.frame = frame
    }

    internal func setCornerRadius(_ cornerRadius: CGFloat) {
        for columnView in columnsViews {
            columnView.layer.cornerRadius = cornerRadius
            columnView.layer.masksToBounds = true
        }
    }

    private func cacheUpdate(animated: Bool, duration: TimeInterval) {
        self.updateCacheBlock?.cancel()
        hideCacheState()

        var capturedBlock: DispatchWorkItem? = nil
        let block = DispatchWorkItem { [weak self] in
            let image = self?.cacheLayerState()
            DispatchQueue.main.sync {
                if false == capturedBlock?.isCancelled {
                    self?.cacheImageView.image = image
                    self?.showCacheState()
                }
            }
        }
        capturedBlock = block
        updateCacheBlock = block

        let duration = animated ? duration : 0.0
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + duration, execute: block)
    }

    private func cacheLayerState() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        columnsViews.forEach { $0.layer.render(in: context) }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    private func hideCacheState() {
        columnsViews.forEach { $0.isHidden = false }
        cacheImageView.isHidden = true
    }

    private func showCacheState() {
        if nil != cacheImageView.image {
            columnsViews.forEach { $0.isHidden = true }
            cacheImageView.isHidden = false
        }
    }
}
