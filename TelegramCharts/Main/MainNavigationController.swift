//
//  MainNavigationController.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 22/03/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

class MainNavigationController: UINavigationController
{
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.topViewController?.preferredStatusBarStyle ?? .default
    }
}
