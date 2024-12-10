//
//  SideMenuVC.swift
//  Evp Analyzer
//
//  Created by meet sharma on 07/12/23.
//

import UIKit

class SideMenuVC: UIViewController {

    @IBOutlet weak var tblVwSideMenu: UITableView!
    
    var arrSideMenu = ["Hunted Local Map","Ghost_stories","Website"]
    var arrTitleImg = ["40","131","121"]
    override func viewDidLoad() {
        super.viewDidLoad()

      
    }
    

  

}

extension SideMenuVC:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrSideMenu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuTVC", for: indexPath) as! SideMenuTVC
        cell.lblSideMenuTitle.text = arrSideMenu[indexPath.row]
        cell.imgVwSideMenu.image = UIImage(named: arrTitleImg[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            if let url = NSURL(string: "https://ghostxshop.com/ghost-map/"){
                UIApplication.shared.openURL(url as URL)
                }
        }else if indexPath.row == 1{
            if let url = NSURL(string: "https://ghostxshop.com/maintenance-page/"){
                UIApplication.shared.openURL(url as URL)
                }
        }else{
            if let url = NSURL(string: "https://ghostxshop.com"){
                UIApplication.shared.openURL(url as URL)
                }
        }
    }
    
}
