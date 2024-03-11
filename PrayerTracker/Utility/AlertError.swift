//
//  AlertError.swift
//  PrayerTracker
//
//  Created by Dany Jamous on 11/03/2024.
//

import Foundation

protocol AlertError: Error {
    var errorTitle: String { get }
    var errorDescription: String { get }
}
