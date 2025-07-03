//
//  CSVModel.swift
//  DPD
//
//  Created by Kristina Paterson on 5/20/25.
//

import Foundation
import Foundation
struct PoliceLink: Identifiable {
    var id = UUID()
    var state: String
    var city: String
    var county: String
    var sourceType: String
    var name: String
    var url: String
    var description: String
    var group_id:String
}
