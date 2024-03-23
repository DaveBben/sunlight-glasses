//
//  huberman.swift
//  Sunlight Glasses
//
//  Created by David Bennett on 3/4/24.
//

import Foundation
import UserNotifications


struct AmbientMeasurement {
    var lux: Int32
    var time: Date
    init(lux: Int32, time: Date = .now) {
        self.lux = lux
        self.time = time
    }
}

class huberman: NSObject, ObservableObject{
    
    var bleManager: CoreBluetoothViewModel!
    var timer: Timer?
    @Published var current_lux: Int32
    @Published var average_lux: Int32
    @Published var minutes_left: Int32
    @Published var total_lux: Int32
    @Published var percentage: Double
    @Published var device_connected: Bool
    var lightMeasurements: [Int32] = []
    
    init(current_lux: Int32 = 0, device_connected: Bool = false, average_lux: Int32 = 0, minutes_left: Int32 = 0, total_lux: Int32 = 0, percentage: Double = 0) {
        self.current_lux = current_lux
        self.device_connected = device_connected
        self.average_lux = average_lux
        self.minutes_left = minutes_left
        self.total_lux = total_lux
        self.percentage = percentage
        super.init()
        self.request_notification_permissions()
        bleManager = CoreBluetoothViewModel()
        bleManager.luxUpdate = {
            result in
            print("Lux Value: \(result)")
            self.current_lux = result
            self.lightMeasurements.append(result)
        }
         bleManager.connected = { connected in
             self.device_connected = true
//             Calculate the median lux every minute
             self.timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.calculate_median_lux), userInfo: nil, repeats: true)
         }
    }
    
    func create_notification(title: String, body: String){
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
//        trigger immediately
       let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let id = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
               print(error)
            }
        }

    }
    
    func request_notification_permissions(){
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge]) { success, error in
        }
    }


    func find_glasses(){
        bleManager.startScanning()
    }
    

    @objc func calculate_median_lux() {
        if(self.lightMeasurements.count > 1){
            self.average_lux = lightMeasurements.sorted(by: <)[lightMeasurements.count / 2]
            print("Average Lux", self.average_lux)
            self.total_lux += self.average_lux
            self.minutes_left = (100000 - self.total_lux)/self.average_lux
            self.lightMeasurements = []
            self.percentage = (Double(self.total_lux)/Double(100000)) * 100
            print("Percentage of max Lux received: ", self.percentage)
            if(self.percentage > 99){
                create_notification(title: "100K Lux Achieved", body: "Dr. Huberman would be proud")
            }
            let hour = Calendar.current.component(.hour, from: Date())
            // Night time notification
            if(hour > 21 || hour < 5){
                if(self.average_lux > 100){
                    self.create_notification(title: "Too Much Night Time Light", body: "Avoid bright light this late")
                }
                
            }
        }
        
    }

    // Other methods...
}

