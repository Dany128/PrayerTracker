//
//  personView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 01/02/2024.
//

import SwiftUI

struct PersonView: View {
    var turningLeft: Bool
    
    var body: some View {
        ZStack {
            ZStack {
                Image(systemName: "arrow.uturn.\(turningLeft ? "left" : "right").circle")
                    .resizable()
                    .foregroundStyle(.colorLightBrown.opacity(0.8))
                RoundedRectangle(cornerRadius: 30).stroke(lineWidth: 5)
                    .foregroundStyle(.colorYellow)
                RoundedRectangle(cornerRadius: 30).stroke(lineWidth: 5)
                    .foregroundStyle(.black.opacity(0.16))
                
            }
            .offset(CGSize(width: turningLeft ? 13 : -13, height: -2))
            .frame(width: 25, height: 13)
            
            
            Image(systemName: "person.fill")
                .foregroundStyle(.colorBrown)
                .scaleEffect(1.5)
            
        }
        .offset(CGSize(width: turningLeft ? -2 : 2, height: 0))
    }
}

#Preview {
    ZStack {
        Capsule()
            .fill(.colorYellow)
        Circle()
            .fill(.black.opacity(0.16))
        .padding(8)
        PersonView(turningLeft: false)
    }
    .frame(width: 70, height: 70)
}
