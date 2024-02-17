//
//  ContentView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 24/01/2024.
//

import SwiftUI


struct ContentView: View {
    
    // MARK: - PROPERTIES
    
    @State var showPrayerSettings: Bool = false
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            ScrollView {
                HeaderView()

                dividier
            } //: SCROLL
        } //: ZSTACK
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
            
            ButtonView(imageName: "gear")
                .padding()
        }
        .background(Rectangle().foregroundStyle(.color1).shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 15))
    }
}
