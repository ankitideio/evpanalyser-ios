//
//  AlertHelper.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 16/10/2022.
//

import Foundation
import UIKit

public typealias SimpleClosure = (() -> ())

open class AlertHelper: NSObject, UIAlertViewDelegate {
    
    fileprivate static let instance = AlertHelper()
    
    fileprivate var alertView: UIAlertController?
    fileprivate var inputField: UITextField?
    fileprivate var cancelAction: SimpleClosure?
    fileprivate var options = Array<(title: String, action: ((String?) -> Void))>()
    
    open class func getInstance() -> AlertHelper {
        return instance
    }
    
    open func addOption(_ title: String, onSelect: @escaping ((String?) -> Void)) {
        options.append((title: title, action: onSelect))
    }
    
    open func show(_ title: String?, message: String?, cancelButtonText: String = "Cancel", cancelAction: SimpleClosure? = nil) {
        self.cancelAction = cancelAction
        alertView = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        addButtons(cancelButtonText)
        
        DispatchQueue.main.async {
            UIApplication.presentView(self.alertView!)
        }
    }
    
    open func showInput(_ target: UIViewController, title: String?, message: String?, cancelButtonText: String = "Cancel", cancelAction: SimpleClosure? = nil) {
        self.cancelAction = cancelAction
        alertView = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertView!.addTextField(configurationHandler: {
            (textField: UITextField) -> Void in
            self.inputField = textField
        })
        
        addButtons(cancelButtonText)
        target.present(alertView!, animated: true, completion: nil)
    }
    
    fileprivate func addButtons(_ cancelButtonText: String) {
        alertView!.addAction(UIAlertAction(title: cancelButtonText, style: UIAlertAction.Style.cancel, handler: {
            (_) -> Void in
            self.options.removeAll()
            self.cancelAction?()
        }))
        
        for option in options {
            alertView!.addAction(UIAlertAction(title: option.title, style: UIAlertAction.Style.default, handler: {
                (_) -> Void in
                self.options.removeAll()
                self.alertView = nil
                option.action(self.inputField?.text)
            }))
        }
    }
}
