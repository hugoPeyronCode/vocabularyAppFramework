//
//  PremiumStatus.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 28/09/2023.
//

import Foundation

class PremiumStatus {
    static let shared = PremiumStatus()
    
    private let userDefaults = UserDefaults.standard
    private let premiumAccessKey = "com.words.premiumAccess"
    
    var hasPremiumAccess: Bool {
        get {
            return userDefaults.bool(forKey: premiumAccessKey)
        }
        set {
            userDefaults.set(newValue, forKey: premiumAccessKey)
        }
    }
    
    private init() {}
}
