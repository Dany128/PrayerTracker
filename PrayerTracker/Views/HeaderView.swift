//
//  HeaderView.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 25/01/2024.
//

import SwiftUI

struct HeaderView: View {
    // MARK: - PROPERTIES
    @StateObject var headerViewModel: HeaderViewModel = HeaderViewModel()
    
    // Progression Bar
    
    // MARK: - BODY
    var body: some View {
        GroupBox {
            VStack(spacing: 20) {
                // TIMER
                
                ZStack(alignment: .leading) {
                    // AVOIDS SHIFT
                    Text("00:00:00").opacity(0.0)
                    Text(headerViewModel.timeRemaining)
                }
                .font(.system(size: 55))
                .foregroundStyle(.white)
                .fontWeight(.bold)
                .padding(.bottom, -10)
                
                progressionBar
                
                if headerViewModel.toggleIsVisible {
                    toggle
                        .transition(.asymmetric(
                            insertion: AnyTransition.scale(scale: 0, anchor: .top).animation(.spring()),
                            removal: AnyTransition.scale(scale: 0, anchor: .top).animation(.easeOut(duration: 0.26))))
                }
            } //: VSTACK
            .onReceive(headerViewModel.timer, perform: { _ in
                headerViewModel.updateTimeRemaining()
            })
        } //: GROUPBOX
        .backgroundStyle(Constants.background)
        .padding()
        .animation(.spring, value: headerViewModel.toggleIsVisible)
        .task {
            await headerViewModel.checkForTimingsUpdate()
        }
    }
}

#Preview {
    ScrollView {
        HeaderView()
    }
}

extension HeaderView {
    
    var progressionBar: some View {
        HStack(spacing: 15) {
            Image(systemName: headerViewModel.previousPeriodImage)
                .foregroundStyle(.color1)
                .fontWeight(.bold)
            
            GeometryReader { geometry in
                ZStack {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(.colorYellow)
                            .frame(height: 3)
                        Rectangle()
                            .fill(.gray)
                            .frame(width: geometry.size.width * headerViewModel.barWidthScale, height: 3)
                    } //: HSTACK
                    
                    Group {
                        Circle()
                            .fill(.colorYellow)
                        .frame(width: 11, height: 11)
                        Circle()
                            .stroke(.colorYellow, lineWidth: 2)
                            .frame(width: 20, height: 20)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.colorBrown)
                    } //: GROUP
                    .offset(x: geometry.size.width * (0.5 - headerViewModel.barWidthScale) , y: 0)
                } //: ZSTACK
            } //: GEOMETRY
            .frame(height: 20)
            
            Image(systemName: headerViewModel.comingPeriodImage)
                .foregroundStyle(.color1)
                .fontWeight(.bold)
        } //: HSTACK
    }
    
    var toggle: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. CAPSULE (STATIC)
                
                Capsule()
                    .fill(Color(.color7))
                Capsule()
                    .fill(Color(.color2))
                    .padding(8)
                
                // 2. CAPSULE (DRAGGABLE)
                
                HStack {
                    if headerViewModel.hasTurnedRight {
                        Spacer()
                    }
                    
                    Capsule()
                        .fill(.colorYellow)
                        .frame(width: headerViewModel.hasTurnedRight ? geometry.size.width - headerViewModel.buttonOffset : headerViewModel.toggleDiamater + headerViewModel.buttonOffset)
                    
                    if !headerViewModel.hasTurnedRight {
                        Spacer()
                    }
                    
                }
                
                // 3. CIRCLE (DRAGGABLE)
                
                HStack {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.16))
                            .padding(8)
                        PersonView(turningLeft: headerViewModel.hasTurnedRight)

                    } //: ZSTACK
                    .offset(x: headerViewModel.buttonOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                headerViewModel.updateToggleOnChanged(with: gesture, capsuleWidth: geometry.size.width)
                            }
                            .onEnded { _ in
                                headerViewModel.updateToggleOnEnded(with: geometry.size.width)
                            }
                    )
                    
                    Spacer()
                } //: HSTACK
            } //: ZSTACK
        } //: GEOMETRY
        .frame(height: headerViewModel.toggleDiamater)
        .padding(.horizontal)
    }

    
}
