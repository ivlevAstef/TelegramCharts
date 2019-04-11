//
//  ColumnsView.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 09/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit


internal final class ColumnsView: UIView
{
    private typealias DT = Double
    internal override var frame: CGRect {
        didSet {
            updateFrame()
        }
    }

    private var columnsViews: [ColumnView] = []
    private let cacheImageView: UIImageView = UIImageView(frame: .zero)

    private var cornerRadius: CGFloat = 0.0
    private var updateCacheBlock: DispatchWorkItem?

    private var updateDiagramBlock: DispatchWorkItem?
    private var deadline: DispatchTime = .now()

    private var oldTime: DT = currentTime()
    private var oldDuration: TimeInterval = 0.0

    internal init() {
        super.init(frame: .zero)

        cacheImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cacheImageView)
    }

    internal func premake(margins: UIEdgeInsets, types: [ColumnViewModel.ColumnType]) {
        columnsViews = ColumnsViewFabric.makeColumnViews(by: types, margins: margins, parent: self)
        updateFrame()
        setCornerRadius(cornerRadius)
    }

    internal func update(ui: ChartUIModel, animated: Bool, duration: TimeInterval) {
        assert(columnsViews.count == ui.columns.count)
        updateDiagramBlock?.cancel()
        let updateBlock = DispatchWorkItem { [weak self] in
            guard let `self` = self else {
                return
            }

            let start = DispatchTime.now()
            self.recalculate(ui: ui, animated: animated, duration: duration)
            self.cacheUpdate(animated: animated, duration: duration)

            let end = DispatchTime.now()
            self.deadline = .now() + .nanoseconds(Int(end.uptimeNanoseconds &- start.uptimeNanoseconds))
        }
        updateDiagramBlock = updateBlock
        if DispatchTime.now() >= deadline {
            updateBlock.perform()
        } else {
            DispatchQueue.main.asyncAfter(deadline: deadline, execute: updateBlock)
        }
    }

    internal func recalculate(ui: ChartUIModel, animated: Bool, duration: TimeInterval) {
        let t: CGFloat = CGFloat((ColumnsView.currentTime() - oldTime) / (ColumnsView.multForSlowDevices() * oldDuration))

        let zipColumns = zip(ui.columns, columnsViews)
        for (columnUI, columnView) in zipColumns {
            columnView.update(ui: columnUI, animated: animated, duration: duration, t: t)
        }
        self.oldTime = ColumnsView.currentTime()

        for (columnUI, columnView) in zipColumns {
            columnView.confirm(ui: columnUI, animated: animated, duration: duration)
        }
        self.oldDuration = animated ? duration : 0.0
    }

    internal func setCornerRadius(_ cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
        for columnView in columnsViews {
            columnView.layer.cornerRadius = cornerRadius
            columnView.layer.masksToBounds = cornerRadius > 0
        }
    }

    private static func multForSlowDevices() -> Double {
        if cpuIsFast {
            return 1.0
        }
        // Not critical, but on old devices graphics draw is very slow
        // animation time not equals dt time. need correct :(
        return 0.6
    }

    private static func currentTime() -> Double {
        //return Date().timeIntervalSinceReferenceDate
        //return Double(DispatchTime.now().uptimeNanoseconds) / Double(NSEC_PER_SEC)
        return CACurrentMediaTime()
    }

    private func updateFrame() {
        for columnView in columnsViews {
            columnView.frame = bounds
        }
        cacheImageView.frame = bounds
    }

    private func cacheUpdate(animated: Bool, duration: TimeInterval) {
        self.updateCacheBlock?.cancel()
        hideCacheState()

        let block = DispatchWorkItem { [weak self] in
            self?.cacheImageView.image = self?.cacheLayerState()
            self?.showCacheState()
        }
        updateCacheBlock = block

        let duration = animated ? 1.2/*as a precaution*/ * duration : 0.0
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
