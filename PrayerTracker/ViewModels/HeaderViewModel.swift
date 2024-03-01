//
//  HeaderViewModel.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 08/02/2024.
//

import SwiftUI

class HeaderViewModel: ObservableObject {
    // Timer
    let prayersDataManager: PrayersDataManager = PrayersDataManager()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    var prayerTimes: [String : String] = [:]
    var newDay: Bool = false
    var hasReset: Bool = false
    var comingPeriodDate: Date = Date()
    var previousPeriodIndex: Int = 0
    @Published var timeRemaining: String = "00:00:00"
    // Progression Bar
    let periodsImages: [String] = ["moon", "sunrise", "sun.max", "sun.max.fill", "sunset.fill", "moon", "moon.stars"]
    @Published var previousPeriodImage: String = "moon"
    @Published var comingPeriodImage: String = "sunrise"
    @Published var barWidthScale: CGFloat = 0.0
    // Toggle
    @Published var buttonOffset: CGFloat = 0
    let toggleDiamater: CGFloat = 70
    @Published var hasTurnedRight: Bool = false
    @Published var toggleIsVisible: Bool = false
    var inPrayerTime: Bool = false
    @AppStorage("hasPrayed") var hasPrayed: Bool = false
    @AppStorage("showSettings") var showSettings: Bool = true
    
    func loadPrayerTimes() {
        if let timings = prayersDataManager.loadPrayerTimesFromUD() {
            prayerTimes = timings
            setTimer()
        } else {
            showSettings = true
        }
    }
    
    func setTimer() {
        var i = 0
        while i < Constants.periodsCount && !isInTimeInterval(from: i, to: (i + 1) % Constants.periodsCount) {
            i += 1
        }
        updateComingPeriodDate(index: (i + 1) % Constants.periodsCount)
        previousPeriodIndex = i % Constants.periodsCount
        setImages()
        updateToggleVisibility()
    }
    
    func resetTimer() {
        previousPeriodIndex = (previousPeriodIndex + 1) % Constants.periodsCount
        hasReset = true
        if 
            let beginningTime = prayerTimes[Constants.periods[previousPeriodIndex]],
            let endTime = prayerTimes[Constants.periods[(previousPeriodIndex + 1) % Constants.periodsCount]] {
            if beginningTime > endTime {
                newDay = true
            } else {
                newDay = false
            }
            updateComingPeriodDate(index: (previousPeriodIndex + 1) % Constants.periodsCount)
        }
        
    }
    
    func addPadding(to component: Int) -> String {
        return component < 10 ? "0\(component)" : "\(component)"
    }
    
    func updateTimeRemaining(while settingsHaveChanged: inout Bool) {
        if settingsHaveChanged {
            loadPrayerTimes()
            settingsHaveChanged = false
        }
        guard !showSettings else { return }
        let datesDifference = Calendar.current.dateComponents([.hour, .minute, .second], from: Date(), to: comingPeriodDate)
        if hasReset {
            hasPrayed = false
            updateToggleVisibility()
            setImages()
            
            hasReset = false
        }
        if
            let hours = datesDifference.hour,
            let minutes = datesDifference.minute,
            let seconds = datesDifference.second {
            if hours <= 0 && minutes <= 0 && seconds <= 0 {
                resetTimer()
            }
            withAnimation(.easeOut(duration: 0.15)) {
                timeRemaining = addPadding(to: hours) + ":" + addPadding(to: minutes) + ":" + addPadding(to: seconds)
            }
            
        }
        updateBarWidth()
    }
    
    func updateComingPeriodDate(index: Int) {
        guard let timeAtPeriodFromIndex = prayerTimes[Constants.periods[index]] else { return }
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        let timeFromPeriodComponents = timeAtPeriodFromIndex.components(separatedBy: ":")
        if timeFromPeriodComponents.count > 1 {
            let currentDayComponents = calendar.dateComponents([.day, .month, .year], from: Date())
            dateComponents.year = currentDayComponents.year
            dateComponents.month = currentDayComponents.month
            dateComponents.day = currentDayComponents.day
            if newDay {
                dateComponents.day = (dateComponents.day ?? 0) + 1
            }
            dateComponents.hour = Int(timeFromPeriodComponents[0])
            dateComponents.minute = Int(timeFromPeriodComponents[1])
            if let date = calendar.date(from: dateComponents) {
                comingPeriodDate = date
            }
        }
    }
    
    func isInTimeInterval(from: Int, to: Int) -> Bool {
        let currentTime = dateFormatter.string(from: Date())
        if
            let beginningTime = prayerTimes[Constants.periods[from]],
            let endTime = prayerTimes[Constants.periods[to]] {
            if beginningTime < endTime {
                if currentTime >= beginningTime && currentTime < endTime {
                    newDay = false
                    return true
                }
            } else {
                if !(currentTime >= endTime && currentTime < beginningTime) {
                    newDay = true
                    return true
                }
            }
        }
        
        return false
    }

    // MARK: - PROGRESSION BAR
    
    func toCGFLoat(_ text: String) -> CGFloat {
        return CGFloat(Int(text) ?? 0)
    }
    
    func updateBarWidth() {
        guard
            let previousTime = prayerTimes[Constants.periods[previousPeriodIndex]],
            let comingTime = prayerTimes[Constants.periods[(previousPeriodIndex + 1) % Constants.periodsCount]]
        else { return }
        let timeRemainingComponents = timeRemaining.components(separatedBy: ":")
        let previousPeriodComponents = previousTime.components(separatedBy: ":")
        let comingPeriodComponents = comingTime.components(separatedBy: ":")
        if
            timeRemainingComponents.count > 2 && previousPeriodComponents.count > 1 && comingPeriodComponents.count > 1 {
            let remainingSeconds = (
                toCGFLoat(timeRemainingComponents[0]) * 3600 +
                toCGFLoat(timeRemainingComponents[1]) * 60 +
                toCGFLoat(timeRemainingComponents[2]))
            var hoursDifference = (
                toCGFLoat(comingPeriodComponents[0]) -
                toCGFLoat(previousPeriodComponents[0])
            ) * 3600
            if newDay {
                hoursDifference = (
                    24 + toCGFLoat(comingPeriodComponents[0]) -
                    toCGFLoat(previousPeriodComponents[0])
                ) * 3600
            }
            let minutesDifference = (
                toCGFLoat(comingPeriodComponents[1]) -
                toCGFLoat(previousPeriodComponents[1])
            ) * 60
            let totalSeconds = hoursDifference + minutesDifference
            barWidthScale = remainingSeconds / totalSeconds
        }
    }
    
    func setImages() {
        withAnimation(.easeInOut(duration: 1)) {
            previousPeriodImage = periodsImages[previousPeriodIndex]
            comingPeriodImage = periodsImages[(previousPeriodIndex + 1) % Constants.periodsCount]
        }
    }
    
    // MARK: - TOGGLE
    
    func updateToggleOnChanged(with gesture: DragGesture.Value, capsuleWidth: CGFloat) {
        let horizontalTranslation = gesture.translation.width
        let maximumTranslation = capsuleWidth
        if hasTurnedRight {
            if horizontalTranslation < 0 && buttonOffset >= 0  {
                buttonOffset = maximumTranslation - toggleDiamater + horizontalTranslation
            }
        } else {
            if horizontalTranslation > 0 && buttonOffset <= maximumTranslation - toggleDiamater {
                buttonOffset = horizontalTranslation
            }
        }
    }
    
    func updateToggleOnEnded(with capsuleWidth: CGFloat) {
        if hasTurnedRight {
            if buttonOffset < 10 {
                buttonOffset = 0
                hasTurnedRight = false
                hasPrayed = true
                updateToggleVisibility()
            } else {
                buttonOffset = capsuleWidth - toggleDiamater
            }
        } else {
            if buttonOffset > capsuleWidth - toggleDiamater - 10 {
                buttonOffset = capsuleWidth - toggleDiamater
                hasTurnedRight = true
            } else {
                buttonOffset = 0
            }
        }
    }
    
    func updateInPrayerTime() {
        switch previousPeriodIndex {
        case 1, 6:
            inPrayerTime = false
        default:
            inPrayerTime = true
        }
    }
    
    func updateToggleVisibility() {
        updateInPrayerTime()
        if inPrayerTime && !hasPrayed {
            toggleIsVisible = true
        } else {
            toggleIsVisible = false
        }
    }
}
