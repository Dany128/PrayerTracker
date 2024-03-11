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
    
    func downloadPrayerTimes(latitude: Double, longitude: Double, method: Int) async throws -> [String : String] {
        
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
    
    func savePrayerTimesToUD(with prayerTimes: [String : String]) {
        UserDefaults.standard.set(prayerTimes, forKey: Constants.prayerTimesKey)
    }
    
    func loadPrayerTimesFromUD() -> [String : String]? {
        if let prayerTimes = UserDefaults.standard.object(forKey: Constants.prayerTimesKey) as? [String : String] {
            return prayerTimes
        } else {
            return nil
        }
    }
}
