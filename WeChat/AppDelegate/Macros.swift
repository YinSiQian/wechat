//
//  File.swift
//  WeChat
//
//  Created by ysq on 2017/10/7.
//  Copyright © 2017年 ysq. All rights reserved.
//

import Foundation
import UIKit

let kScreen_width = UIScreen.main.bounds.size.width

let kScreen_height = UIScreen.main.bounds.size.height

//112.74.162.15 120.79.10.111
let baseUrl = URL(string: "http://112.74.162.15:8090/")!

let testHostUrl = URL(string: "http://localhost:8080/")!

let kNetworkStatusChanged = Notification.Name(rawValue: "kNetworkStatusChanged")

let kViewBackgroudColor = UIColor(red:0.94, green:0.95, blue:0.95, alpha:1.00)
