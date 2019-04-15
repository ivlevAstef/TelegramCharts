//
//  SwitchColumnVisibleTableViewCell.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 07/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

private enum Consts {
    internal static let margins: UIEdgeInsets = {
        var margins = layoutMargins
        margins.bottom = 2 * margins.bottom
        return margins
    }()
    
    internal static let togglersSpacing: CGFloat = 6.0
    
    internal static let padding: CGFloat = 10.0
    internal static let contentHeight: CGFloat = 28.0
    internal static let spacing: CGFloat = 4.0
    
    internal static let checkMarkLineWidth: CGFloat = 1.5
    
    internal static let borderWidth: CGFloat = 1.0
    internal static let cornerRadius: CGFloat = 7.0
    
    internal static let font: UIFont = UIFont.systemFont(ofSize: 15.0, weight: .regular)
}

internal class SwitchColumnVisibleTableViewCell: UITableViewCell, Stylizing, IActualizedCell
{
    internal let identifier: String = "SwitchColumnVisibleTableViewCell"
    
    override internal var frame: CGRect {
        didSet { updateFrame() }
    }
    private var prevFrame: CGRect = .zero
    
    private var imageCacheView: ImageCacheView = ImageCacheView()
    private var cacheBlock: DispatchWorkItem? = nil
    private var buttonsView: UIView = UIView(frame: .zero)
    private var togglers: [ColumnToggler] = []

    internal init() {
        super.init(style: .default, reuseIdentifier: nil)
        
        imageCacheView.isUserInteractionEnabled = false
        imageCacheView.cacheMethod = { [weak self] context in
            self?.cacheButtons(context: context)
        }
        imageCacheView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(imageCacheView)
        
        buttonsView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(buttonsView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnSelf(_:)))
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longOnSelf(_:)))
        tapGesture.delegate = self
        longGesture.delegate = self
        tapGesture.require(toFail: longGesture)
        
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(longGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func actualizeFrame(width: CGFloat) {
        let height = (togglers.last?.frame.maxY ?? Consts.margins.top) + Consts.margins.bottom
        let rect = CGRect(x: frame.origin.x, y: frame.origin.y, width: width, height: height)
        
        buttonsView.frame = CGRect(origin: .zero, size: rect.size)
        imageCacheView.frame = CGRect(origin: .zero, size: rect.size)
        self.frame = rect
    }
    
    internal func applyStyle(_ style: Style) {
        backgroundColor = style.mainColor
        contentView.backgroundColor = style.mainColor
        for subview in subviews.compactMap({ $0 as? ColumnToggler }) {
            subview.backgroundColor = style.mainColor
        }
    }
    
    internal func addColumnVisibleToogler(name: String, color: UIColor, isVisible: Bool, clickHandler: @escaping (_ long: Bool) -> Void) {
        let columnToggler = ColumnToggler(name: name, color: color)

        columnToggler.isVisible = isVisible
        columnToggler.tapHandler = {
            clickHandler(false)
        }
        columnToggler.longHandler = {
            clickHandler(true)
        }

        SwitchColumnVisibleTableViewCell.layoutColumnToggler(columnToggler: columnToggler, last: togglers.last, width: buttonsView.frame.width)
        
        columnToggler.makeCacheImages()

        buttonsView.addSubview(columnToggler)
        togglers.append(columnToggler)
    }
    
    internal func setIsVisibleOnTogglers(_ isVisibles: [Bool], animated: Bool, duration: TimeInterval) {
        UIView.animateIf(animated, duration: duration, animations: { [weak self] in
            self?.setIsVisibleOnTogglers(isVisibles)
        })
        
        updateCache(after: animated ? duration : 0.0)
    }
    
    internal func updateCache(after duration: TimeInterval) {
        buttonsView.isHidden = false
        imageCacheView.isHidden = true
        
        imageCacheView.cacheAfter(deadline: .now() + duration, in: buttonsView.frame.size) { [weak self] image in
            self?.imageCacheView.image = image
            self?.buttonsView.isHidden = true
            self?.imageCacheView.isHidden = false
        }
    }
    
    internal func setIsVisibleOnTogglers(_ isVisibles: [Bool]) {
        assert(isVisibles.count == togglers.count)
        for (toggler, isVisible) in zip(togglers, isVisibles) {
            toggler.isVisible = isVisible
        }
    }

    private func cacheButtons(context: CGContext) {
        for toggler in togglers {
            let image: UIImage? = toggler.isVisible ? toggler.visibleImage : toggler.unvisibleImage
            
            if let image = image {
                let rect = CGRect(origin: toggler.position, size: toggler.size)
                image.draw(in: rect)
            }
        }
    }

    private func updateFrame() {
        if prevFrame.size.equalTo(frame.size) {
            return
        }
        prevFrame = frame

        var lastColumnToggler: ColumnToggler? = nil
        for columnToggler in togglers {
            SwitchColumnVisibleTableViewCell.layoutColumnToggler(columnToggler: columnToggler, last: lastColumnToggler, width: bounds.width)
            lastColumnToggler = columnToggler
        }
        actualizeFrame(width: bounds.width)
        
        updateCache(after: 0.0)
    }
    
    private static func layoutColumnToggler(columnToggler: ColumnToggler, last: ColumnToggler?, width: CGFloat) {
        let margins = Consts.margins
        if let lastToggler = last {
            columnToggler.position = CGPoint(x: lastToggler.frame.maxX + Consts.togglersSpacing, y: lastToggler.frame.origin.y)
            if columnToggler.frame.maxX > width - margins.right {
                columnToggler.position = CGPoint(x: margins.left, y: lastToggler.frame.maxY + Consts.togglersSpacing)
            }
        } else {
            columnToggler.position = CGPoint(x: margins.left, y: margins.top)
        }
    }
    
    @objc private func tapOnSelf(_ tapGesture: UITapGestureRecognizer) {
        if let toggler = findButton(tapGesture) {
            toggler.tapHandler?()
        }
    }
    
    @objc private func longOnSelf(_ tapGesture: UILongPressGestureRecognizer) {
        if let toggler = findButton(tapGesture) {
            toggler.longHandler?()
        }
    }
    
    private func findButton(_ gestureRecognizer: UIGestureRecognizer) -> ColumnToggler? {
        guard let view = gestureRecognizer.view else {
            return nil
        }
        
        let loc = gestureRecognizer.location(in: view)
        
        for toggler in togglers {
            let position = view.convert(loc, to: toggler)
            if toggler.point(inside: position, with: nil) {
                return toggler
            }
        }
        
        return nil
    }
}

extension SwitchColumnVisibleTableViewCell
{
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
}

private class ColumnToggler: UIView
{
    internal var tapHandler: (() -> Void)?
    internal var longHandler: (() -> Void)?
    internal var isVisible: Bool = false {
        didSet {
            changeUIVisible()
        }
    }
    
    internal var position: CGPoint = .zero {
        didSet {
            self.frame.origin = position
        }
    }
    
    internal let size: CGSize
    internal private(set) var unvisibleImage: UIImage?
    internal private(set) var visibleImage: UIImage?
    
    private let checkmark: CheckmarkView
    private let label: UILabel
    private let color: UIColor
    
    internal init(name: String, color: UIColor) {
        self.color = color
        label = ColumnToggler.makeAndResizeLabel(name: name)
        
        let checkmarkSize = label.font.capHeight + Consts.checkMarkLineWidth
        checkmark = CheckmarkView(frame: CGRect(x: Consts.padding, y: Consts.padding, width: checkmarkSize, height: checkmarkSize))
        
        label.frame.origin.x = checkmark.frame.maxX + Consts.spacing
        
        self.size = CGSize(width: floor(label.frame.maxX + Consts.padding), height: Consts.contentHeight)
        super.init(frame: CGRect(origin: .zero, size: size))
        
        checkmark.color = elementColor
        
        translatesAutoresizingMaskIntoConstraints = true
        checkmark.translatesAutoresizingMaskIntoConstraints = true
        label.translatesAutoresizingMaskIntoConstraints = true
        
        self.isUserInteractionEnabled = true
        checkmark.isUserInteractionEnabled = false
        label.isUserInteractionEnabled = false
        
        addSubview(checkmark)
        addSubview(label)

        checkmark.backgroundColor = .clear

        label.center.y = center.y
        checkmark.center.y = center.y
        
        layer.cornerRadius = Consts.cornerRadius
        layer.masksToBounds = true
        clipsToBounds = true
    }
    
    internal func makeCacheImages() {
        func currentStateCache() {
            if self.isVisible {
                visibleImage = ImageCacheView.cache(in: self.size, executor: { (context) in
                    self.layer.render(in: context)
                })
            } else {
                unvisibleImage = ImageCacheView.cache(in: self.size, executor: { (context) in
                    self.layer.render(in: context)
                })
            }
        }
        
        currentStateCache()
        
        self.isVisible = !self.isVisible
        self.changeUIVisible()
        currentStateCache()
        
        self.isVisible = !self.isVisible
        self.changeUIVisible()
    }
    
    private func changeUIVisible() {
        if isVisible {
            label.frame.origin.x = checkmark.frame.maxX + Consts.spacing
            label.textColor = elementColor
            backgroundColor = color
            checkmark.isHidden = false

            layer.borderWidth = 0.0
            layer.borderColor = nil
        } else {
            label.frame.origin.x = 0.5 * (bounds.width - label.frame.width)
            label.textColor = color
            backgroundColor = .clear
            checkmark.isHidden = true

            layer.borderWidth = Consts.borderWidth
            layer.borderColor = color.cgColor
        }
    }
    
    private var elementColor: UIColor {
        return UIColor.white
    }
    
    private static func makeAndResizeLabel(name: String) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: Consts.contentHeight))
        label.text = name
        label.font = Consts.font
        label.sizeToFit()
        return label
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class CheckmarkView: UIView {
    
    internal var color: UIColor?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext(), let color = self.color else {
            return
        }
        
        let lWidth = Consts.checkMarkLineWidth
        let rect = bounds.inset(by: UIEdgeInsets(top: lWidth * 0.5, left: lWidth * 0.5, bottom: lWidth * 0.5, right: lWidth * 0.5))
        
        context.saveGState()
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: rect.minX,
                                    y: rect.minY + 0.54348 * rect.height))
        bezierPath.addLine(to: CGPoint(x: rect.minX + 0.30435 * rect.width,
                                       y: rect.minY + 0.84782 * rect.height))
        bezierPath.addLine(to: CGPoint(x: rect.minX + rect.width,
                                       y: rect.minY + 0.15218 * rect.height))
        bezierPath.lineCapStyle = .round
        
        color.setStroke()
        bezierPath.lineWidth = lWidth
        bezierPath.stroke()
        
        context.restoreGState()
    }
}
