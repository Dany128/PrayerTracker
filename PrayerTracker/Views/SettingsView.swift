//
//  PrayerTimesSettingView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 06/02/2024.
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
    var coordinates : CLLocationCoordinate2D? = nil
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
    
    func requestOnceLocationPermission() {
        isLoading = true
        locationManager.requestLocation()
    }
    
    func fetchGeoNames (with location: CLLocation) async throws -> (String, String) {
        let geoCoder = CLGeocoder()
        do {
            let placemarks = try await geoCoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first,
               let country = placemark.country,
               let city = placemark.locality {
                return (city, country)
            } else {
                throw Constants.Errors.GeoLocationError.failedGeoReverse
            }
        } catch  {
            throw error
        }
    }
    
    func fetchPrayerTimes() async throws -> [String : String] {
        if let latitude = coordinates?.latitude,
           let longitude = coordinates?.longitude {
            do {
                return try await prayersDataManager.downloadPrayerTimes(with: latitude, longitude, method)
            } catch {
                throw error
            }
        } else {
            throw Constants.Errors.GeoLocationError.noCoordinates
        }
    }
    
    func updatePrayerTimes() {
        isLoading = true
        Task {
            do {
                let timings = try await fetchPrayerTimes()
                await MainActor.run {
                    prayerTimes = timings
                }
            } catch {
                print(error.localizedDescription)
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task {
            if let location = locations.last {
                do {
                    self.coordinates = location.coordinate
                    async let fetchNames = fetchGeoNames(with: location)
                    async let fetchTimings = fetchPrayerTimes()
                    let ((city, country), timings) = try await (fetchNames, fetchTimings)
                    
                    await MainActor.run {
                        prayerTimes = timings
                        self.country = country
                        self.city = city
                    }
                } catch {
                    print(error.localizedDescription)
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

import CoreLocationUI

struct SettingsView: View {
    
    @StateObject var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    
                    Picker("Method", selection: $settingsViewModel.wifiOn) {
                        Text("wifi").tag(true)
                        Text("manual").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .padding(.bottom)
                    
                    Divider()
                        .overlay(.color6)
                    
                    ZStack {
                        Rectangle()
                            .fill(.color2)
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                if settingsViewModel.wifiOn {
                                    wifiSections
                                } else {
                                    manualSection
                                }
                                
                                prayerTimesSection
                                    .padding(.bottom)
                            }
                        }
                    } //: ZSTACK
                } //: VSTACK
                .navigationTitle("Prayer Times")
                .ignoresSafeArea(.all, edges: .bottom)
            } //: NAVIGATION
            
            if settingsViewModel.isLoading {
                LoadingView()
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    .zIndex(1)
            }
            
        } //: ZSTACK
    }
}

#Preview {
    SettingsView()
}

extension SettingsView {
    
    var wifiSections: some View {
        VStack(spacing: 20) {
            
            //MARK: - LOCATION
            GroupBox {
                SettingsTextSectionView(title: "Location", sublines: [
                    SublineModel(
                        title: "Country : \(settingsViewModel.country)",
                        description: ""
                    ),
                    SublineModel(
                        title: "City : \(settingsViewModel.city)",
                        description: ""
                    )], fixedSublinesSize: false
                )
                
                LocationButton(.currentLocation) {
                    settingsViewModel.requestOnceLocationPermission()
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .foregroundStyle(.colorBrown)
                .tint(.colorYellow)
                .symbolVariant(.fill)
                .padding(.top)
                .padding(.horizontal, 20)
                
            } //: GROUPBOX
            .backgroundStyle(.color5)
            .padding(.horizontal)
            .padding(.top, 30)
            
            //MARK: - METHOD
            GroupBox {
                SettingsTextSectionView(title: "Method", sublines: [
                    SublineModel(
                        title: "Institute :",
                        description: "\(settingsViewModel.methods[settingsViewModel.method])"
                    )], fixedSublinesSize: true
                )
                
                Menu {
                    ForEach(
                        Array(settingsViewModel.methods.enumerated()), id: \.element) { i, method in
                            Button(method) {
                                settingsViewModel.method = i
                                settingsViewModel.updatePrayerTimes()
                            }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.and.down")
                            .fontWeight(.bold)
                        Text("Select Method")
                    }
                    .font(.system(size: 19))
                    .foregroundStyle(.colorBrown)
                    .padding(.horizontal, 2)
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 15).fill(.colorYellow))
                }
            } //: GROUPBOX
            .backgroundStyle(.color5)
            .padding(.horizontal)
        }
    }
    
    var manualSection: some View {
        GroupBox {
            HStack {
                Picker("Period", selection: $settingsViewModel.period) {
                    ForEach(settingsViewModel.periods, id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .tint(.white)
                .onChange(of: settingsViewModel.period, initial: true) {
                    settingsViewModel.loadPickers()
                }
                .frame(minWidth: 110)
                
                Divider()
                    .overlay(.white)
                
                Picker("Hour", selection: $settingsViewModel.hour) {
                    ForEach(0...23, id: \.self) { hour in
                        let hourWithPadding = hour < 10 ? "0\(hour)" : "\(hour)"
                        Text(hourWithPadding)
                            .tag(hourWithPadding)
                    }
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
                }
                .pickerStyle(.wheel)
                .frame(width: 50)
                .onChange(of: settingsViewModel.hour) {
                    settingsViewModel.saveTime()
                }
                
                Text(":")
                    .foregroundStyle(.white)
                    .frame(width: 10)
                
                Picker("Minutes", selection: $settingsViewModel.minutes) {
                    ForEach(0...59, id: \.self) { minute in
                        let minuteWithPadding = minute < 10 ? "0\(minute)" : "\(minute)"
                        Text(minuteWithPadding)
                            .tag(minuteWithPadding)
                    }
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
                    .onChange(of: settingsViewModel.minutes) {
                        settingsViewModel.saveTime()
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 50)
            }
        } //: GROUPBOX
        .backgroundStyle(.color5)
        .padding(.horizontal)
        .padding(.top, 30)
    }
        
    var prayerTimesSection: some View {
        
        GroupBox {
            SettingsTextSectionView(title: "Prayer Times", sublines: [], fixedSublinesSize: false)
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach(settingsViewModel.periods, id: \.self) { period in
                        Text("\(period) : \(settingsViewModel.prayerTimes[period] ?? "")")
                    }
                }
                .foregroundStyle(.white)
                .fontWeight(.medium)
            }
            .scrollIndicators(.hidden)
            .frame(height: 45)
        }
        .backgroundStyle(.color5)
        .padding(.horizontal)
    }
}
