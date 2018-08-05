//
//  UIViewController+Extension.swift
//  WeChat
//
//  Created by ysq on 2018/7/30.
//  Copyright © 2018年 ysq. All rights reserved.
//

import Foundation
import UIKit

enum ColorTheme {
    case white
    case black
}

protocol NetworkErrorHandler {
    
    func showError(error: NSError?)
}

protocol NavgationBarTheme {
    
    func loadNavbarTheme(theme: ColorTheme)
}

extension NavgationBarTheme where Self: UIViewController {
    
    func loadNavbarTheme(theme: ColorTheme = ColorTheme.black) {
        
        switch theme {
        case .black:
            UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
            let navbarTextAttribute = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedStringKey.foregroundColor: UIColor.white]
            self.navigationController?.navigationBar.barTintColor = UIColor.black
            self.navigationController?.navigationBar.tintColor = UIColor.white
            self.navigationController?.navigationBar.titleTextAttributes = navbarTextAttribute
            
        case .white:
            UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.default, animated: true)
            let navbarTextAttribute = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedStringKey.foregroundColor: UIColor.black]
            self.navigationController?.navigationBar.barTintColor = UIColor.white
            self.navigationController?.navigationBar.tintColor = UIColor.black
            self.navigationController?.navigationBar.titleTextAttributes = navbarTextAttribute
        }
    }
}

extension NetworkErrorHandler where Self: UIViewController {
    
    func showError(error: NSError? = NSError(domain: baseUrl.absoluteString, code: 200, userInfo: ["message": "成功"])) {
        guard error != nil else {
            return
        }
        let code = error!.code
        let msg = error!.userInfo["message"] as! String
        print("msg--->\(msg)   code---->\(code)")
        
    }
}

var navbarAlphaKey = "navbarAlphaKey"

extension UIViewController {
    
    var navbarAlpha: CGFloat {
        set {
            objc_setAssociatedObject(self, &navbarAlphaKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            self.navigationController?.setNavbar(alpha: newValue)
        }
        get {
            guard let value = objc_getAssociatedObject(self, &navbarAlphaKey) else {
                return 1.0
            }
            return value as! CGFloat
        }
    }
    
}

extension UIViewController: NetworkErrorHandler {

}

extension UIViewController: NavgationBarTheme {}


