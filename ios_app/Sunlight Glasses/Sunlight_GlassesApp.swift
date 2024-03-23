//
//  Sunlight_GlassesApp.swift
//  Sunlight Glasses
//
//  Created by David Bennett on 3/3/24.
//

import SwiftUI
import SwiftData
import CoreBluetooth

@main
struct Sunlight_GlassesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Measurement.self)
    }
}
