//
//  Item.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
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
