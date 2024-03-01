//
//  ContentView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 24/01/2024.
//

import SwiftUI


struct ContentView: View {
    
    // MARK: - PROPERTIES
    
    @AppStorage("showSettings") var showSettings: Bool = true
    @State var settingsHaveChanged = false
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            ScrollView {
                HeaderView(settingsHaveChanged: $settingsHaveChanged)

                dividier
            } //: SCROLL
        } //: ZSTACK
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings, settingsHaveChanged: $settingsHaveChanged)
        }
    }
}

#Preview {
    ContentView()
}

extension ContentView {
    var dividier: some View {
        HStack() {
            ButtonView(imageName: "chart.line.uptrend.xyaxis")
                .padding()
            
            Spacer()
            
            Text("Prayer Tracker")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.color7)
            
            Spacer()
            
            Button(action: {
                showSettings = true
            }, label: {
                ButtonView(imageName: "gear")
                    .padding()
            })
            
        }
        .background(Rectangle()
            .foregroundStyle(.color1)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 15)
        )
    }
}
