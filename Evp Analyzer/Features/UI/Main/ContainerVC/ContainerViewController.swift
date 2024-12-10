//
//  ContainerViewController.swift
//  Evp Analyzer
//
//  Created by MACBOOK PRO on 14/06/2022.
//

import Foundation
import UIKit
import GoogleMobileAds

class ContainerViewController: UIViewController{
    
    @IBOutlet weak var bottomAdView: UIView!
    @IBOutlet weak var bottomAdViewHeightConstraint: NSLayoutConstraint!
    
    private let banner: GADBannerView = {
        let banner = GADBannerView()
        banner.adUnitID = "ca-app-pub-7003296935766628/3224621410"
        banner.load(GADRequest())
        return banner
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        banner.rootViewController = self
        banner.delegate = self
        self.bottomAdView.addSubview(banner)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        banner.frame = CGRect(x: 0, y: 0, width: self.bottomAdView.frame.size.width, height: self.bottomAdView.frame.size.height)
    }
}

extension ContainerViewController: GADBannerViewDelegate{
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
      print("bannerViewDidReceiveAd")
        self.bottomAdViewHeightConstraint.constant = 70
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
      print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
        self.bottomAdViewHeightConstraint.constant = 0
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
