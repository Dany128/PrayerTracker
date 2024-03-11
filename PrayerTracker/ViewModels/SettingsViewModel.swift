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
    @Published var prayerTimes: [String : String] = ["Fajr" : "", "Sunrise" : "", "Dhuhr" : "", "Asr" : "", "Maghrib" : "", "Isha" : "", "Midnight" : ""] {
        didSet {
            prayersDataManager.savePrayerTimesToUD(with: prayerTimes)
        }
    }
    let sampleTimes: [String: String] = ["Fajr" : "04:30", "Sunrise" : "05:45", "Dhuhr" : "12:00", "Asr" : "16:55", "Maghrib" : "20:15", "Isha" : "22:05", "Midnight" : "00:45"]
    // Wifi Settings
    let prayersDataManager = PrayersDataManager()
    let locationManager = CLLocationManager()
    @AppStorage("latitude") var latitude: Double = .infinity
    @AppStorage("longitude") var longitude: Double = .infinity
    @AppStorage("country") var country: String = ""
    @AppStorage("city") var city: String = ""
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
    
    func prayerTimesAreComplete() -> Bool {
        var i = 0
        while i < Constants.periodsCount && !(prayerTimes[Constants.periods[i]] ?? "").isEmpty {
            i += 1
        }
        return i >= Constants.periodsCount
    }
    
    func prayerTimesAreWithinADay() -> Bool {
        var newDays = 0
        for i in 0..<Constants.periodsCount {
            if let firstTime = prayerTimes[Constants.periods[i]],
               let secondTime = prayerTimes[Constants.periods[(i + 1) % Constants.periodsCount]],
               firstTime > secondTime {
                newDays += 1
            }
        }
        return newDays < 2
    }
    
    func checkPrayerTimesValidity() -> Bool {
        guard prayerTimesAreComplete() else {
            showAlert(Constants.Errors.UnableToExit.incompletePrayerTimes)
            return false
        }
        guard prayerTimesAreWithinADay() else {
            showAlert(Constants.Errors.UnableToExit.prayerTimesNotInADay)
            return false
        }
        return true
    }
    
    // MARK: - WIFI
    
    override init() {
        super.init()
        locationManager.delegate = self
        if let times = prayersDataManager.loadPrayerTimesFromUD() {
            prayerTimes = times
        }
    }
    
    func showAlert(_ error: Error) {
        if let error = error as? AlertError {
            alertTitle = error.errorTitle
            alertMessage = error.errorDescription
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
    
    func fetchGeoNames (with location: CLLocation) async -> Result<GeoNamesModel, Error> {
        let geoCoder = CLGeocoder()
        do {
            let placemarks = try await geoCoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first,
               let country = placemark.country {
                return .success(GeoNamesModel(city: placemark.locality ?? "", country: country))
            } else {
                return .failure(Constants.Errors.GeoLocation.failedGeoReverse(coordinate: location.coordinate))
            }
        } catch  {
            return .failure(error)
        }
    }
    
    func fetchPrayerTimes(latitude: Double, longitude: Double) async -> Result<[String : String], Error> {
        do {
            return .success(try await prayersDataManager.downloadPrayerTimes(latitude: latitude, longitude: longitude, method: method))
        } catch {
            return .failure(error)
        }
    }
    
    func updatePrayerTimes() {
        isLoading = true
        Task {
            if latitude != .infinity && longitude != .infinity {
                let fetchTimings = await fetchPrayerTimes(latitude: latitude, longitude: longitude)
                await MainActor.run {
                    switch fetchTimings {
                    case .success(let timings):
                        prayerTimes = timings
                    case .failure(let error):
                        showAlert(error)
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
                let coordinate = location.coordinate
                async let fetchNames = fetchGeoNames(with: location)
                async let fetchTimings = fetchPrayerTimes(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let returnedValues = await (fetchNames, fetchTimings)
                
                await MainActor.run {
                    latitude = coordinate.latitude
                    longitude = coordinate.longitude
                    switch returnedValues {
                    case (.success(let geoNames), .success(let timings)):
                        prayerTimes = timings
                        country = geoNames.country
                        city = geoNames.city
                    case (.success(let geoNames), .failure(let error)):
                        country = geoNames.country
                        city = geoNames.city
                        showAlert(error)
                    case (.failure(let error), .success(let timings)):
                        prayerTimes = timings
                        showAlert(error)
                    case (.failure(let namesError), .failure(let timingsError)):
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
        print("location did not take place : \(error.localizedDescription)")
    }
    
    // MARK: - MANUAL
    
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
