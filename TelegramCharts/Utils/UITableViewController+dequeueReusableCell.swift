//
//  UITableViewController+dequeueReusableCell.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

extension UITableViewController
{
    internal func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(T.self)", for: indexPath) as? T else {
            fatalError("dequeueReusableCell call failed for type: \(T.self)")
        }
        return cell
    }
}
