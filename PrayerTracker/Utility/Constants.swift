//
//  Constants.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 06/02/2024.
//

import SwiftUI

struct Constants {
    static let background = LinearGradient(colors: [.color5, .color6], startPoint: .bottom, endPoint: .top)
    
    struct Errors {
        enum APIError: Error {
            case invalidURL
            case invalidResponse
            case invalidData
        }
        
        enum GeoLocationError: Error {
            case failedGeoReverse
            case noCoordinates
        }
    }
}
 

