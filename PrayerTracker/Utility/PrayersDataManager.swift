//
//  HeaderDataManager.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 08/02/2024.
//

import Foundation

class PrayersDataManager {
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }
    
    func downloadPrayerTimes(with latitude: Double, _ longitude: Double, _ method: Int) async throws -> [String : String] {
        
        guard let url = URL(string: "https://api.aladhan.com/v1/timings/\(dateFormatter.string(from: Date()))?latitude=\(latitude)&longitude=\(longitude)&method=\(method)") else {
            print("url error")
            throw Constants.Errors.APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 else {
                print("invalid response")
                throw Constants.Errors.APIError.invalidResponse
            }
            let prayerTimesModel = try JSONDecoder().decode(PrayerTimesModel.self, from: data)
            return prayerTimesModel.data.timings
        } catch {
            print("Couldn't decode data")
            throw Constants.Errors.APIError.invalidData
        }
    }
    
    func generatePrayerTimes(with timings: [String : String]) throws -> [String] {
        if
            let fajr = timings["Fajr"],
            let sunrise = timings["Sunrise"],
            let dhuhr = timings["Dhuhr"],
            let asr = timings["Asr"],
            let maghrib = timings["Maghrib"],
            let isha = timings["Isha"],
            let midnight = timings["Midnight"] {
            return [fajr, sunrise, dhuhr, asr, maghrib, isha, midnight]
        } else {
            print("couldn't generatePrayerTimes")
            throw Constants.Errors.APIError.invalidData
        }
    }
}
