//
//  SettingVC.swift
//  Evp Analyzer
//
//  Created by meet sharma on 06/12/23.
//

import UIKit


class SettingVC: UIViewController {

    @IBOutlet weak var defaultSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    @IBAction func actionSetDefault(_ sender: UISwitch) {
       
    }
    
    @IBAction func actionSendLogs(_ sender: UIButton) {
        let email = "bluflymatrix@outlook.com"
        if let url = URL(string: "mailto:\(email)") {
          if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
          } else {
            UIApplication.shared.openURL(url)
          }
        }
    
    }
    
    @IBAction func actionVisitWebsite(_ sender: UIButton) {
        if let url = NSURL(string: "https://ghostxshop.com/"){
            UIApplication.shared.openURL(url as URL)
            }
    }
    @IBAction func actionGhostMap(_ sender: UIButton) {
        if let url = NSURL(string: "https://ghostxshop.com/ghost-map/"){
            UIApplication.shared.openURL(url as URL)
            }
    }
    
}
