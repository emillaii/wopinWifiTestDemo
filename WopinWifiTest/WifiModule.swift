//
//  WifiModule.swift
//  WopinWifiTest
//
//  Created by Lai kwok tai on 13/7/2018.
//  Copyright © 2018 Lai kwok tai. All rights reserved.
//

import Foundation

import NetworkExtension
import SystemConfiguration.CaptiveNetwork

struct WifiScanResult: Codable {
    let essid: String
    let bssid: String
    let rssid: String?
    let channel: String?
    
    private enum CodingKeys: String, CodingKey {
        case essid = "essid"
        case bssid = "bssid"
        case rssid = "rssid"
        case channel = "channel"
    }
}

struct WifiResponse: Codable {
    let deviceId: String
    let status: String
    private enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case status = "status"
    }
}

func getWifiSsid() -> String? {
    var ssid: String?
    if let interfaces = CNCopySupportedInterfaces() as NSArray? {
        for interface in interfaces {
            if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                break
            }
        }
    }
    return ssid
}
