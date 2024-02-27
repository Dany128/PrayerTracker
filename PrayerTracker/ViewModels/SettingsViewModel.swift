//
//  SettingsViewModel.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 25/02/2024.
//

import SwiftUI
import CoreLocation

class SettingsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var wifiOn: Bool = true
    let periods: [String] = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha", "Midnight"]
    @Published var prayerTimes: [String : String] = ["Fajr" : "", "Sunrise" : "", "Dhuhr" : "", "Asr" : "", "Maghrib" : "", "Isha" : "", "Midnight" : ""]
    // Wifi Settings
    let locationManager = CLLocationManager()
    let prayersDataManager = PrayersDataManager()
    @Published var country: String = ""
    @Published var city: String = ""
    var location : CLLocation? = nil
    let methods: [String] = [
        "Shia Ithna-Ashari",
        "University of Islamic Sciences, Karachi",
        "Islamic Society of North America",
        "Muslim World League",
        "Umm Al-Qura University, Makkah",
        "Egyptian General Authority of Survey",
        "Institute of Geophysics, University of Tehran",
        "Gulf Region",
        "Kuwait",
        "Qatar",
        "Majlis Ugama Islam Singapura, Singapore",
        "Union Organization islamic de France",
        "Diyanet İşleri Başkanlığı, Turkey",
        "Spiritual Administration of Muslims of Russia"]
    @Published var method: Int = 3
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = "Error"
    @Published var alertMessage: String = ""
    // Manual Settings
    @Published var period: String = "Fajr"
    @Published var hour: String = "04"
    @Published var minutes: String = "30"
    let sampleTimes: [String: String] = ["Fajr" : "04:30", "Sunrise" : "05:45", "Dhuhr" : "12:00", "Asr" : "16:55", "Maghrib" : "20:15", "Isha" : "22:05", "Midnight" : "00:45"]
    
    // Wifi
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func showAPIAlert(_ error: Error) {
        if let apiError = error as? Constants.Errors.API {
            alertTitle = apiError.errorTitle
            alertMessage = apiError.errorDescription
        } else {
            alertTitle = "Error"
            alertMessage = error.localizedDescription
        }
        showAlert = true
    }
    
    func showGeoAlert(_ error: Error) {
        if let geoError = error as? Constants.Errors.GeoLocation {
            alertTitle = geoError.errorTitle
            alertMessage = geoError.errorDescription
        } else {
            alertTitle = "Error"
            alertMessage = error.localizedDescription
        }
        showAlert = true
    }
    
    func showCombinedAlert(geoError: Error, apiError: Error) {
        alertTitle = "Errors"
        alertMessage = ""
        if let error = geoError as? Constants.Errors.GeoLocation {
            alertMessage = "\(error.errorDescription)\n"
        } else {
            alertMessage = "\(apiError.localizedDescription)\n"
        }
        
        if let error = apiError as? Constants.Errors.API {
            alertMessage += error.errorDescription
        } else {
            alertMessage += geoError.localizedDescription
        }
        
        showAlert = true
    }
    
    func requestOnceLocationPermission() {
        isLoading = true
        locationManager.requestLocation()
    }
    
    func fetchGeoNames (with location: CLLocation) async -> Result<(String, String), Error> {
        let geoCoder = CLGeocoder()
        do {
            let placemarks = try await geoCoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first,
               let country = placemark.country {
                return .success((placemark.locality ?? "", country))
            } else {
                return .failure(Constants.Errors.GeoLocation.failedGeoReverse(coordinate: location.coordinate))
            }
        } catch  {
            return .failure(error)
        }
    }
    
    func fetchPrayerTimes(with coordinate: CLLocationCoordinate2D) async -> Result<[String : String], Error> {
        do {
            return .success(try await prayersDataManager.downloadPrayerTimes(with: coordinate.latitude, coordinate.longitude, method))
        } catch {
            return .failure(error)
        }
    }
    
    func updatePrayerTimes() {
        isLoading = true
        Task {
            if let location {
                let fetchTimings = await fetchPrayerTimes(with: location.coordinate)
                await MainActor.run {
                    switch fetchTimings {
                    case .success(let timings):
                        prayerTimes = timings
                    case .failure(let error):
                        showAPIAlert(error)
                    }
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task {
            if let location = locations.last {
                async let fetchNames = fetchGeoNames(with: location)
                async let fetchTimings = fetchPrayerTimes(with: location.coordinate)
                let returnedValues = await (fetchNames, fetchTimings)
                
                await MainActor.run {
                    switch returnedValues {
                    case (.success(let (city, country)), .success(let timings)):
                        prayerTimes = timings
                        self.country = country
                        self.city = city
                        self.location = location
                    case (.success(let (city, country)), .failure(let error)):
                        self.country = country
                        self.city = city
                        self.location = location
                        showAPIAlert(error)
                    case (.failure(let error), .success(let timings)):
                        prayerTimes = timings
                        self.location = location
                        showGeoAlert(error)
                    case (.failure(let namesError), .failure(let timingsError)):
                        self.location = location
                        showCombinedAlert(geoError: namesError, apiError: timingsError)
                    }
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        //show alert Location Failed
        print("location did not take place : \(error.localizedDescription)")
    }
    
    // Manual
    func loadPickers() {
        var time = sampleTimes[period] ?? "00:00"
        if let existingTime = prayerTimes[period], !existingTime.isEmpty {
            time = existingTime
        }
        let timeComponents = time.components(separatedBy: ":")
        guard timeComponents.count > 1 else { return }
        hour = timeComponents[0]
        minutes = timeComponents[1]
    }
    
    func saveTime() {
        prayerTimes[period] = "\(hour):\(minutes)"
    }
}
