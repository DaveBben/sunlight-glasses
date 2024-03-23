//
//  ContentView.swift
//  Sunlight Glasses
//
//  Created by David Bennett on 3/3/24.
//

import SwiftUI
import SwiftData
import CoreBluetooth


struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @StateObject var controller = huberman()

    
    
    var body: some View {
        VStack {
            
            GeometryReader { geometry in
                ZStack {
           
                    RingShape()
                        .stroke(style: StrokeStyle(lineWidth:50))
                        .fill(Color.gray)

                    RingShape(percent: controller.percentage, startAngle: -90)
                        .stroke(style: StrokeStyle(lineWidth: 50, lineCap: .round))
                        .fill(Color.orange)
                }
                .padding(50)
            }

               Text("BLE Device Connection")
                   .font(.title2)
                   .padding()
               
               // Display connection status
               Text(controller.device_connected ? "Connected" : "Disconnected")
            
            Text("LUX: \(String(controller.current_lux))")
                .font(.title)
                .padding()


            Text("Total Lux: \(controller.total_lux)")
                .font(.title3)
                .padding()

            Text("Minutes Left: \(controller.minutes_left)")
                .font(.title3)
                .padding()

            
               // Button to initiate connection
               Button(action: {
                   controller.find_glasses()
               }) {
                   Text("Scan for Devices")
               }
           }
       }
    

    private func addItem() {
        withAnimation {
            let newItem = Measurement(lux: 0)
            modelContext.insert(newItem)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Measurement.self, inMemory: true)
}
