//
//  Measurement.swift
//  Sunlight Glasses
//
//  Created by David Bennett on 3/3/24.
//
//

import Foundation
import SwiftData


@Model public class Measurement {
    var lux: Int
    var time: Date
    init(lux: Int = 0, time: Date = .now) {
        self.lux = lux
        self.time = time
    }
    
}
