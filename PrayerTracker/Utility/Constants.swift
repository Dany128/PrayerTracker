//
//  Constants.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 06/02/2024.
//

import SwiftUI
import CoreLocation

struct Constants {
    static let background = LinearGradient(colors: [.color5, .color6], startPoint: .bottom, endPoint: .top)
    static let prayerTimesKey = "prayer_times"
    static let periods: [String] = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha", "Midnight"]
    static var periodsCount: Int {
        periods.count
    }
    
    struct Errors {
        enum API: Error {
            case invalidURL(_ url: String)
            case invalidResponse(statusCode: Int)
            case invalidData
            
            var errorTitle: String {
                switch self {
                case .invalidURL(_):
                    return "Invalid Url"
                case .invalidResponse(_):
                    return "Invalid Response"
                case .invalidData:
                    return "Invalid Data"
                }
            }
            
            var errorDescription: String {
                switch self {
                case .invalidURL(let url):
                    return "Couldn't form a valid url from : \(url)"
                case .invalidResponse(let statusCode):
                    return "Invalid status code : \(statusCode)"
                case .invalidData:
                    return "Couldn't decode the data or the data is corrupted"
                }
            }
        }
        
        enum GeoLocation: Error {
            case failedGeoReverse(coordinate: CLLocationCoordinate2D)
            
            var errorTitle: String {
                return "Error Reversing"
            }
            
            var errorDescription: String {
                if case .failedGeoReverse(let coordinate) = self {
                    return String(format: "Couldn't get country and city names from latitude : %.3f, longitude : %.3f", arguments: [coordinate.latitude, coordinate.longitude])
                } else {
                    return ""
                }
            }
        }
        
        struct UnableToExitAlert {
            static let title = "Incomplete Prayer Times"
            static let message = "Please compute the prayer times or fill them manually"
        }
    }
}
 

