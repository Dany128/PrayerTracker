//
//  ButtonView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 08/02/2024.
//

import SwiftUI

struct ButtonView: View {
    
    let imageName: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.colorYellow)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 0)
            Circle()
                .fill(.black.opacity(0.16))
                .padding(6)
            Image(systemName: imageName)
                .foregroundStyle(.colorBrown)
                .fontWeight(.bold)
        }
        
        .frame(width: 50, height: 50)
        
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ButtonView(imageName: "xmark")
        .padding()
    
}
