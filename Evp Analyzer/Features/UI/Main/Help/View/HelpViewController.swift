//
//  HelpViewController.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 07/06/2022.
//

import UIKit
import youtube_ios_player_helper
import StoreKit

class HelpViewController: BaseViewController {
    //MARK: - IBOutlets & Properties
    @IBOutlet weak var playStoreView: UIView!{
        didSet{
            playStoreView.layer.cornerRadius = playStoreView.frame.height / 2.0
        }
    }
    @IBOutlet weak var youtubeView: YTPlayerView!
    @IBOutlet weak var appstoreView: UIView!{
        didSet{
            appstoreView.layer.cornerRadius = appstoreView.frame.height / 2.0
        }
    }
    
    var products = [SKProduct]()
    
    //MARK: - ViewCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.youtubeView.load(withVideoId: "b4JylC_G_hY")
        self.getInAppProducts()
    }
    
    @IBAction func playstoreBtnAction(_ sender: Any) {
        if let url = URL(string: "https://play.google.com/store/apps/details?id=com.zk.teslamonitor") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func appstoreBtnAction(_ sender: Any) {
    }
    @IBAction func didTapRestore() {
        if let product = self.getProductForItem(package: "") {
            IAPManager.shared.restorePurchases()
        }
    }
    
    @IBAction func didTapBuy() {
        if let product = self.getProductForItem(package: "") {
            if !self.purchase(product: product, index: 0) {
                AlertHelper.getInstance().show("Error", message:"In-App Purchases are not allowed in this device.", cancelButtonText: "OK", cancelAction: {
                })
            }
        }
    }
}


// In app work
extension HelpViewController {
    func getProductForItem(package: String) -> SKProduct? {
        // Search for a specific keyword depending on the index value.
        let keyword: String
        
        switch package {
        case "Monthly Tier 1": keyword = "removeads"
        default: keyword = "removeads"
        }
        
        // Check if there is a product fetched from App Store containing
        // the keyword matching to the selected item's index.
        guard let product = self.getProduct(containing: keyword) else { return nil }
        return product
    }
    
    func purchase(product: SKProduct, index: Int) -> Bool {
        if !IAPManager.shared.canMakePayments() {
            return false
        } else {
            IAPManager.shared.buy(product: product) { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // call api to notify server that user purchased subscription and reload tableview
                        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKey.inAppPurchasekey)
                        self.hideBanner()
                        print("")
                    case .failure(let error):
                        AlertHelper.getInstance().show("Error", message:"\(error.localizedDescription)", cancelButtonText: "OK", cancelAction: {
                        })
                    }
                }
            }
        }
        
        return true
    }
    func getInAppProducts(){
        IAPManager.shared.fetchProducts { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let products):
                    self.products = products
                    print(self.products)
                case .failure(let error):
                    AlertHelper.getInstance().show("Error", message:"\(error.localizedDescription)", cancelButtonText: "OK", cancelAction: {
                    })
                }
            }
        }
    }
    
    func getProduct(containing keyword: String) -> SKProduct? {
        return products.filter { $0.productIdentifier.contains(keyword) }.first
    }
}
