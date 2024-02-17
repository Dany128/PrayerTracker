//
//  PrayerTimesModel.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 03/02/2024.
//

import Foundation

// MARK: - PrayerTimes
struct PrayerTimesModel: Codable {
    let data: DataStruct
}

// MARK: - Data
struct DataStruct: Codable {
    let timings: [String : String]
}

