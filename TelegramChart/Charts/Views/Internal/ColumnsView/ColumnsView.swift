//
//  ColumnsView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 09/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

private enum Consts {
    internal static let topOffset: CGFloat = 7.0
    internal static let bottomOffset: CGFloat = 5.0
}

internal final class ColumnsView: UIView
{
    private typealias DT = Double
    internal override var frame: CGRect {
        didSet {
            updateFrame()
        }
    }

    private var ui: ChartUIModel?
    private var columnViews: [ColumnViewLayerWrapper] = []
    private let cacheImageView: UIImageView = UIImageView(frame: .zero)
    private let clipContentView: UIView = UIView(frame: .zero)
    private let contentView: UIView = UIView(frame: .zero)
    private var margins: UIEdgeInsets = .zero
    private var style: ChartStyle? = nil
    
    private var cornerRadius: CGFloat = 0.0
    private var updateCacheBlock: DispatchWorkItem?

    private let callFrequenceLimiter = CallFrequenceLimiter()

    private var oldTime: DT = currentTime()
    private var oldDuration: TimeInterval = 0.0
    private var delayOfSec: Double = 1.0 / 60.0

    internal init() {
        super.init(frame: .zero)

        cacheImageView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(cacheImageView)

        clipContentView.clipsToBounds = true
        clipContentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(clipContentView)
        contentView.translatesAutoresizingMaskIntoConstraints = true
        clipContentView.addSubview(contentView)
    }
    
    internal func setStyle(_ style: ChartStyle) {
        self.style = style
        for columnView in columnViews {
            columnView.setStyle(style)
        }
    }
    
    internal func updateSelector(to date: Chart.Date?, animated: Bool, duration: TimeInterval) {
        var needUpdateAny: Bool = false
        for columnView in columnViews {
            columnView.updateSelector(to: date, animated: animated, duration: duration, needUpdateAny: &needUpdateAny)
        }
        
        if let ui = self.ui, needUpdateAny {
            // in indeally need update part - only who is return needUpdateAny :)
            recalculate(ui: ui, animated: animated, duration: duration)
        }
        
        cacheUpdate(animated: animated, duration: duration)
    }

    internal func premake(margins: UIEdgeInsets, types: [ColumnViewModel.ColumnType]) {
        self.margins = margins
        columnViews = ColumnsViewFabric.makeColumnViews(by: types, parent: contentView)
        if let style = self.style {
            setStyle(style)
        }
        updateFrame()
        setCornerRadius(cornerRadius)
    }

    internal func update(ui: ChartUIModel, animated: Bool, duration: TimeInterval) {
        self.ui = ui
        assert(columnViews.count == ui.columns.count)
        
        callFrequenceLimiter.update { [weak self] in
            guard let `self` = self else {
                return DispatchTimeInterval.never
            }
            
            let start = DispatchTime.now()
            self.recalculate(ui: ui, animated: animated, duration: duration)
            self.cacheUpdate(animated: animated, duration: duration)
            
            let end = DispatchTime.now()
            let delayInNSec = (end.uptimeNanoseconds &- start.uptimeNanoseconds)
            let p = 2.0 / (10.0 + 1.0)
            self.delayOfSec = p * self.delayOfSec + (1.0 - p) * Double(delayInNSec) / Double(NSEC_PER_SEC)
            return DispatchTimeInterval.nanoseconds(max(Int(delayInNSec), 33333333))
        }
    }

    internal func setCornerRadius(_ cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius

        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.masksToBounds = cornerRadius > 0
        cacheImageView.layer.cornerRadius = cornerRadius
        cacheImageView.layer.masksToBounds = cornerRadius > 0
    }
    
    private func recalculate(ui: ChartUIModel, animated: Bool, duration: TimeInterval) {
        let defaultOffset = 1.0 / 120.0
        let t: CGFloat = CGFloat((defaultOffset + delayOfSec + ColumnsView.currentTime() - oldTime) / oldDuration)
        
        let zipColumns = zip(ui.columns, columnViews)
        for (columnUI, columnView) in zipColumns {
            columnView.update(ui: columnUI, animated: animated, duration: duration, t: t)
        }
        self.oldTime = ColumnsView.currentTime()
        
        for (columnUI, columnView) in zipColumns {
            columnView.confirm(ui: columnUI, animated: animated, duration: duration)
        }
        self.oldDuration = animated ? duration : 0.0
    }


    private static func currentTime() -> Double {
        //return Date().timeIntervalSinceReferenceDate
        //return Double(DispatchTime.now().uptimeNanoseconds) / Double(NSEC_PER_SEC)
        return CACurrentMediaTime()
    }

    private func updateFrame() {
        let rect = CGRect(x: bounds.origin.x, y: bounds.origin.y - Consts.topOffset,
                          width: bounds.width, height: bounds.height + Consts.topOffset + Consts.bottomOffset)
        if !rect.equalTo(cacheImageView.frame) {
            cacheImageView.frame = rect
        }

        if !rect.equalTo(clipContentView.frame) {
            clipContentView.frame = rect
            contentView.frame = clipContentView.bounds
        }
        
        let subRect = CGRect(x: bounds.minX + margins.left,
                             y: bounds.minY + margins.top + Consts.topOffset,
                             width: bounds.width - margins.left - margins.right,
                             height: bounds.height - margins.top - margins.bottom)
        for view in columnViews {
            view.layer.frame = subRect
            view.selectorLayer.frame = subRect
            view.minX = -margins.left - 2 // reserve
            view.maxX = bounds.width + 2 // reserve
        }
    }

    private func cacheUpdate(animated: Bool, duration: TimeInterval) {
        self.updateCacheBlock?.cancel()
        hideCacheState()

        let fullDuration = animated ? (delayOfSec + duration) : delayOfSec
        let deadline: DispatchTime = .now() + fullDuration

        let size = CGSize(width: frame.width, height: frame.height + Consts.topOffset + Consts.bottomOffset)
        var capturedBlock: DispatchWorkItem!
        let block = DispatchWorkItem { [weak self] in
            guard let `self` = self else {
                return
            }
            let image = self.cacheLayerState(size: size)
            DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
                if !capturedBlock.isCancelled {
                    self?.cacheImageView.image = image
                    self?.showCacheState()
                }
            }
        }
        capturedBlock = block
        updateCacheBlock = block

        let fastDuration = animated ? duration : 0.0
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + fastDuration, execute: block)
    }

    private func cacheLayerState(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.translateBy(x: margins.left, y: margins.top + Consts.topOffset)
        columnViews.forEach { $0.drawCurrentState(to: context) }
        columnViews.forEach { $0.drawSelectorState(to: context) }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func hideCacheState() {
        contentView.isHidden = false
        cacheImageView.isHidden = true
    }

    private func showCacheState() {
        if nil != cacheImageView.image {
            contentView.isHidden = true
            cacheImageView.isHidden = false
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
