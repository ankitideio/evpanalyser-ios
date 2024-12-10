//
//  UIViewControllerExtension.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 07/06/2022.
//

import Foundation
import UIKit

extension UIViewController {

    func showAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}
