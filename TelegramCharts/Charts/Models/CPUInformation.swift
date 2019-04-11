//
//  CPUInformation.swift
//  TelegramCharts
//
//  Created by Ивлев Александр on 11/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import Foundation

internal var cpuIsFast: Bool = {
    #if targetEnvironment(simulator)
        let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
    #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    #endif
    switch identifier {
    case "iPod5,1":                                 return false
    case "iPod7,1":                                 return false
    case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return false
    case "iPhone4,1":                               return false
    case "iPhone5,1", "iPhone5,2":                  return false
    case "iPhone5,3", "iPhone5,4":                  return false
    case "iPhone6,1", "iPhone6,2":                  return false
    case "iPhone7,2":                               return false
    case "iPhone7,1":                               return false
    case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return false
    case "iPad3,1", "iPad3,2", "iPad3,3":           return false
    case "iPad3,4", "iPad3,5", "iPad3,6":           return false
    case "iPad4,1", "iPad4,2", "iPad4,3":           return false
    case "iPad2,5", "iPad2,6", "iPad2,7":           return false
    case "iPad4,4", "iPad4,5", "iPad4,6":           return false
    case "iPad4,7", "iPad4,8", "iPad4,9":           return false
    case "AppleTV5,3":                              return false
    default:
        return true
    }
}()
