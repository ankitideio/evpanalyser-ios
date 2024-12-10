//
//  GaugeRangeColorSet.swift
//  Evp Analyzer
//
//  Created by MACBOOK PRO on 14/06/2022.
//

import Foundation

struct GaugeRangeColorsSet {
    static var first: UIColor   { return UIColor.colorFromHexString("#00FF00") }
    static var second: UIColor  { return UIColor.colorFromHexString("#FFFF00") }
    static var third: UIColor   { return UIColor.colorFromHexString("#FF0000") }
    static var fourth: UIColor  { return UIColor.colorFromHexString("#3BDBA6") }
    static var fifth: UIColor   { return UIColor.colorFromHexString("#21A579") }
    static var sixth: UIColor   { return UIColor.colorFromHexString("#02724D") }
    static var seventh: UIColor { return UIColor.colorFromHexString("#00442E") }
    
    static var all: [UIColor] = [first, second, third, fourth, fifth, sixth, seventh]
}

extension UIColor {
    static func colorFromHexString (_ hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
