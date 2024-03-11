//
//  ContentView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 24/01/2024.
//

import SwiftUI


struct ContentView: View {
    @StateObject var headerViewModel: HeaderViewModel = HeaderViewModel()
    
    var body: some View {
        ZStack {
            ScrollView {
                HeaderView(headerViewModel: headerViewModel)

                dividier
                    .animation(.spring, value: headerViewModel.toggleIsVisible)
            } //: SCROLL
        } //: ZSTACK
        .fullScreenCover(isPresented: $headerViewModel.showSettings) {
            SettingsView(headerViewModel: headerViewModel)
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
                headerViewModel.showSettings = true
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
