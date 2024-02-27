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
        
        let urlString = "https://api.aladhan.com/v1/timings/\(dateFormatter.string(from: Date()))?latitude=\(latitude)&longitude=\(longitude)&method=\(method)"
        
        guard let url = URL(string: urlString) else {
            throw Constants.Errors.API.invalidURL(urlString)
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                    throw Constants.Errors.API.invalidResponse(statusCode: httpResponse.statusCode)
                }
                let prayerTimesModel = try JSONDecoder().decode(PrayerTimesModel.self, from: data)
                return prayerTimesModel.data.timings
            } else {
                throw Constants.Errors.API.invalidData
            }
        } catch {
            throw error
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
            throw Constants.Errors.API.invalidData
        }
    }
}
