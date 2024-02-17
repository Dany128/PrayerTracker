//
//  LoadingView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 15/02/2024.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .ignoresSafeArea()
                .opacity(0.5)
            
            GroupBox {
                ProgressView("Loading Prayer Times")
                    .foregroundStyle(.black)
                    .tint(.black)
            }
            .backgroundStyle(.colorYellow)
        }
    }
}

#Preview {
    LoadingView()
}
