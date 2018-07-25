//
//  WopinWifiCommand.swift
//  WopinWifiTest
//
//  Created by Lai kwok tai on 24/7/2018.
//  Copyright © 2018 Lai kwok tai. All rights reserved.
//

import Foundation

struct WopinWifiCommand {
}

func wopinWifiLEDCommand(r: Int, g: Int, b: Int) -> String {
    let red_val = String(format:"%02X", r)
    let green_val  = String(format:"%02X", g)
    let blue_val = String(format:"%02X", b)
    return "01" + red_val + green_val + blue_val
}
