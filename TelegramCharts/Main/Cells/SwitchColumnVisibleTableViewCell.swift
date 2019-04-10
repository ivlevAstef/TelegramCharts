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
    
    private var togglers: [ColumnToggler] = []

    internal init() {
        super.init(style: .default, reuseIdentifier: nil)

        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func actualizeFrame(width: CGFloat) {
        let height = (togglers.last?.frame.maxY ?? Consts.margins.top) + Consts.margins.bottom
        self.frame = CGRect(x: 0, y: 0, width: width, height: height)
    }
    
    internal func applyStyle(_ style: Style) {
        backgroundColor = style.mainColor
    }
    
    internal func addColumnVisibleToogler(name: String, color: UIColor, isVisible: Bool, clickHandler: @escaping () -> Bool) {
        let columnToggler = ColumnToggler(name: name, color: color)
        
        columnToggler.isVisible = isVisible
        columnToggler.tapHandler = { [weak columnToggler] in
            if clickHandler() {
                UIView.animate(withDuration: 0.1, animations: {
                    columnToggler?.isVisible.toggle()
                })
            }
        }
        
        SwitchColumnVisibleTableViewCell.layoutColumnToggler(columnToggler: columnToggler, last: togglers.last, width: bounds.width)
        
        contentView.addSubview(columnToggler)
        togglers.append(columnToggler)

        self.frame.size.height = columnToggler.frame.maxY + Consts.margins.bottom
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
    }
    
    private static func layoutColumnToggler(columnToggler: ColumnToggler, last: ColumnToggler?, width: CGFloat) {
        let margins = Consts.margins
        if let lastToggler = last {
            columnToggler.frame.origin = CGPoint(x: lastToggler.frame.maxX + Consts.togglersSpacing, y: lastToggler.frame.origin.y)
            if columnToggler.frame.maxX > width - margins.right {
                columnToggler.frame.origin = CGPoint(x: margins.left, y: lastToggler.frame.maxY + Consts.togglersSpacing)
            }
        } else {
            columnToggler.frame.origin = CGPoint(x: margins.left, y: margins.top)
        }
    }
}

private class ColumnToggler: UIView
{
    internal var tapHandler: (() -> Void)?
    internal var isVisible: Bool = false {
        didSet {
            changeUIVisible()
        }
    }
    
    private let checkmark: CheckmarkView
    private let label: UILabel
    private let color: UIColor
    
    internal init(name: String, color: UIColor) {
        self.color = color
        label = ColumnToggler.makeAndResizeLabel(name: name)
        
        let checkmarkSize = label.font.capHeight + Consts.checkMarkLineWidth
        checkmark = CheckmarkView(frame: CGRect(x: Consts.padding, y: Consts.padding, width: checkmarkSize, height: checkmarkSize))
        
        label.frame.origin.x = checkmark.frame.maxX + Consts.spacing
        
        super.init(frame: CGRect(x: 0, y: 0, width: label.frame.maxX + Consts.padding, height: Consts.contentHeight))
        
        checkmark.color = elementColor
        checkmark.backgroundColor = .clear
        
        translatesAutoresizingMaskIntoConstraints = false
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(checkmark)
        addSubview(label)
        
        label.center.y = center.y
        checkmark.center.y = center.y
        
        layer.cornerRadius = Consts.cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = Consts.borderWidth
        
        layer.borderColor = color.cgColor
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOnSelf)))
    }
    
    private func changeUIVisible() {
        if isVisible {
            label.textColor = elementColor
            backgroundColor = color
            checkmark.isHidden = false
        } else {
            label.textColor = color
            backgroundColor = .clear
            checkmark.isHidden = true
        }
    }
    
    private var elementColor: UIColor {
        return UIColor.white
    }
    
    @objc private func tapOnSelf() {
        tapHandler?()
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
