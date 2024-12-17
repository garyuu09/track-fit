//
//  Item.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/17.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
