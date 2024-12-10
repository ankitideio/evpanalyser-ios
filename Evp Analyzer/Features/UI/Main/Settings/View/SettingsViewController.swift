//
//  SettingsViewController.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 07/06/2022.
//

import UIKit

class SettingsViewController: BaseViewController {

    @IBOutlet weak var buyThemeBtn: UIButton!{
        didSet{
            buyThemeBtn.layer.cornerRadius = buyThemeBtn.frame.height / 2.0
        }
    }
    
    @IBOutlet weak var sendLogsBtn: UIButton!{
        didSet{
            sendLogsBtn.layer.cornerRadius = sendLogsBtn.frame.height / 2.0
        }
    }
    
    @IBOutlet weak var buyPremiumBtn: UIButton!{
        didSet{
            buyPremiumBtn.layer.cornerRadius = buyPremiumBtn.frame.height / 2.0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    
    @IBAction func sendLogsAction(_ sender: Any) {
    }
    
    @IBAction func buyPremiumAction(_ sender: Any) {
    }
    
}
