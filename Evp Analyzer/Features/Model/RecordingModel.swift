//
//  RecordingModel.swift
//  Evp Analyzer
//
//  Created by MACBOOK PRO on 13/06/2022.
//

import Foundation

class RecordingModel: NSObject, NSCoding{
    let fileName: String
    let date: String
    var url: URL?
    
    
    init(fileName: String, date: String) {
        self.fileName = fileName
        self.date = date
    }

    required convenience init(coder aDecoder: NSCoder) {
        let fileName = aDecoder.decodeObject(forKey: "fileName") as! String
        let date = aDecoder.decodeObject(forKey: "date") as! String
        self.init(fileName: fileName, date: date)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(fileName, forKey: "fileName")
        aCoder.encode(date, forKey: "date")
    }
}
