//
//  CoreBluetooth.swift
//  Sunlight Glasses
//
//  Created by David Bennett on 3/3/24.
//  ChatGPT helped write most of this as I know very little
//  Swift or iOS development
//

import SwiftUI
import CoreBluetooth



class CoreBluetoothViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let environmentalsensingservice = CBUUID(string: "181a")
    let perceivedLightCharacteristic = CBUUID(string: "2b03")
    
    // Create a central manager instance
     var centralManager: CBCentralManager!

     // Create a property to hold the discovered peripheral
     var peripheral: CBPeripheral?
    
     var isSwitchedOn = false
    
    
    var luxUpdate: ((Int32)->())?
    
    var connected: ((Bool)->())?


    var lux = 0

     // Create a property to track connection status
     var isConnected = false
    

     override init() {
         super.init()
         centralManager = CBCentralManager(delegate: self, queue: nil)
     }

     // Function to start scanning for peripherals
     func startScanning() {
         print("Scanning started")
         centralManager.scanForPeripherals(withServices: [environmentalsensingservice], options: nil)
     }

     // Delegate method called when a peripheral is discovered
     func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                         advertisementData: [String : Any], rssi RSSI: NSNumber) {
         // Connect to the discovered peripheral
         print("Found peripheral")
         self.peripheral = peripheral
         centralManager.connect(peripheral, options: nil)
     }

     // Delegate method called when a connection is established
     func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
         // Update connection status
         isConnected = true
         connected?(true)
         print("Connected to \(peripheral.name ?? "unknown device")")
         // Set the peripheral's delegate to self to receive characteristic updates
         peripheral.delegate = self
         // Do further operations after successful connection
         peripheral.discoverServices([environmentalsensingservice])
         
     }

     // Delegate method called when a connection fails
     func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
         // Handle connection failure
         print("Failed to connect to peripheral: \(error?.localizedDescription ?? "Unknown Error")")
     }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
          if central.state == .poweredOn {
              isSwitchedOn = true
          }
          else {
              isSwitchedOn = false
          }
      }
    
    // Delegate method called when services are discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // Handle discovered services
        if let services = peripheral.services {
            for service in services {
                // Discover characteristics for each service
                peripheral.discoverCharacteristics([perceivedLightCharacteristic], for: service)
            }
        }
    }

    

        // Delegate method called when characteristics are discovered
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            // Handle discovered characteristics
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    // Check if the characteristic supports notifications
                    print(characteristic.uuid)
                    if characteristic.properties.contains(.notify) {
                        // Subscribe to notifications for this characteristic
                        print("Subscribed to notification")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
            }
        }

        // Delegate method called when characteristic value is updated
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            // Handle updated characteristic value
            if let data = characteristic.value {
                
                // Ensure the data has at least 4 bytes
                  guard data.count >= 4 else {
                      print("Received characteristic value does not contain enough bytes.")
                      return
                  }
              
                // Extract the bytes and reconstruct the Int32 value
                  let byte0 = Int32(data[0])
                  let byte1 = Int32(data[1]) << 8
                  let byte2 = Int32(data[2]) << 16
                  let byte3 = Int32(data[3]) << 24

                  let intValue = byte0 | byte1 | byte2 | byte3
                  lux = Int(intValue)

                  // Handle the reconstructed Int32 value
                //print("Received Int32 value:", intValue)
                 luxUpdate?(intValue)
            }
        }
}
