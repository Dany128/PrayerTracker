//
//  SettingsTextSectionView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 11/02/2024.
//

import SwiftUI

struct SettingsTextSectionView: View {
    let title: String
    let sublines: [SublineModel]
    let fixedSublinesSize: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text(title.uppercased())
                .fontWeight(.bold)
            
            Divider()
                .overlay(.white)
                .padding(.vertical, 4)
            
            ForEach(sublines, id: \.title) { subline in
                HStack(alignment: .top) {
                    Text(subline.title)
                    if fixedSublinesSize {
                        VStack {
                            Text(subline.description)
                            Spacer(minLength: 0)
                        }
                        .frame(height: 50)
                    } else {
                        Text(subline.description)
                    }
                    
                }
            }
        } //: VSTACK
        .foregroundStyle(.white)
        .fontWeight(.medium)
    }
}

#Preview {
    SettingsTextSectionView(title: "Method :", sublines: [SublineModel(title: "Institute", description: "University of Islamic Sciences, Karachi")], fixedSublinesSize: true)
        .preferredColorScheme(.dark)
}
