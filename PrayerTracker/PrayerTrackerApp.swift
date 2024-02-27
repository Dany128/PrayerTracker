//
//  PrayerTrackerApp.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 17/02/2024.
//

import SwiftUI

@main
struct PrayerTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            SettingsView(showSettings: .constant(true))
        }
    }
}
