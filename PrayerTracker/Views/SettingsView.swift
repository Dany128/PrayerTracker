//
//  PrayerTimesSettingView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 06/02/2024.
//


import SwiftUI
import CoreLocationUI

struct SettingsView: View {
    
    @StateObject var settingsViewModel = SettingsViewModel()
    @Binding var showSettings: Bool
    @Binding var settingsHaveChanged: Bool
    
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
                .toolbar {
                    Button {
                        if settingsViewModel.prayerTimesAreComplete() {
                            settingsHaveChanged = true
                            showSettings = false
                        } else {
                            settingsViewModel.showUnableToExitAlert()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                            .fontWeight(.medium)
                    }
                }
                .ignoresSafeArea(.all, edges: .bottom)
            } //: NAVIGATION
            
            if settingsViewModel.isLoading {
                LoadingView()
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    .zIndex(1)
            }
        } //: ZSTACK
        .alert(Text(settingsViewModel.alertTitle), isPresented: $settingsViewModel.showAlert) {
            
        } message: {
            Text(settingsViewModel.alertMessage)
        }

    }
}

#Preview {
    SettingsView(showSettings: .constant(true), settingsHaveChanged: .constant(false))
}

extension SettingsView {
    
    var wifiSections: some View {
        VStack(spacing: 20) {
            
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
            .padding(.top, 30)
            
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
        }
    }
    
    var manualSection: some View {
        GroupBox {
            HStack {
                Picker("Period", selection: $settingsViewModel.period) {
                    ForEach(Constants.periods, id: \.self) { period in
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
                    ForEach(Constants.periods, id: \.self) { period in
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
        .padding(.bottom)
    }
}
