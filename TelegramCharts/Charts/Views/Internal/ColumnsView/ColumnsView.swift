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
        updateFrame(frame: self.frame)
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

        let block = DispatchWorkItem { [weak self] in
            self?.cacheImageView.image = self?.cacheLayerState()
            self?.showCacheState()
        }
        updateCacheBlock = block

        let duration = animated ? duration : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: block)
    }

    private func cacheLayerState() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        columnsViews.forEach { $0.drawHierarchy(in: CGRect(origin: .zero, size: frame.size), afterScreenUpdates: true) }
        
        return UIGraphicsGetImageFromCurrentImageContext()
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
