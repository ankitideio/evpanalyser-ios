//
//  BaseViewController.swift
//  Evp Analyzer
//
//  Created by MACBOOK PRO on 22/06/2022.
//

import Foundation
import UIKit
import GoogleMobileAds

class BaseViewController: UIViewController{
    
    @IBOutlet weak var bottomAdView: UIView!
    
    //MARK: - Properties
    private var interstitial: GADInterstitialAd?
//    var bannerView: GADBannerView!
    private let banner: GADBannerView = {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = "ca-app-pub-7003296935766628/3224621410"
        banner.load(GADRequest())
        return banner
    }()
    
    //MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let decoded = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKey.inAppPurchasekey)
        if !decoded {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(showAd),
                name: NSNotification.Name(rawValue: "showInterStitialAd"),
                object: nil
            )
            banner.rootViewController = self
            banner.delegate = self
            self.bottomAdView.addSubview(banner)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let decoded = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKey.inAppPurchasekey)
        if decoded {
            self.hideBanner()
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.updateClickCount()
        }
    }
    
    //MARK: - Functions
    func loadAd(){
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID:"ca-app-pub-7003296935766628/4653823970",
                               request: request,
                               completionHandler: { [self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
        }
        )
    }
    
    @objc func showAd(){
        if self.interstitial != nil{
            self.interstitial?.present(fromRootViewController: self)
        } else {
            self.loadAd()
        }
    }
    func hideBanner() {
        self.bottomAdView.isHidden = true
    }
}


extension BaseViewController: GADFullScreenContentDelegate{
    /// Tells the delegate that the ad failed to present full screen content.
     func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
       print("Ad did fail to present full screen content.")
     }

     /// Tells the delegate that the ad will present full screen content.
     func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
       print("Ad will present full screen content.")
     }

     /// Tells the delegate that the ad dismissed full screen content.
     func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
       print("Ad did dismiss full screen content.")
         self.loadAd()
     }
}

extension BaseViewController: GADBannerViewDelegate{
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
      print("bannerViewDidReceiveAd")
//        self.bottomAdViewHeightConstraint.constant = 70
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
      print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
//        self.bottomAdViewHeightConstraint.constant = 0
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
      print("bannerViewDidRecordImpression")
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
      print("bannerViewWillPresentScreen")
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
      print("bannerViewWillDIsmissScreen")
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
      print("bannerViewDidDismissScreen")
    }
}
