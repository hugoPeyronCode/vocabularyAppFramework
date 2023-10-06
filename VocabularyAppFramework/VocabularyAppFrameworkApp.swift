//
//  VocabularyAppFrameworkApp.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 19/09/2023.
//

import SwiftUI
import AppTrackingTransparency
import FacebookCore

@main
struct VocabularyAppFrameworkApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var themesManager = ThemesManager()
    @StateObject private var storeKitManager = StoreKitManager()
    let haptic = HapticManager.shared
    
    let allWordsFromHome : Set<Word> = WordManager.shared.allWords
    let wordsByCategories : [String: Set<Word>]  = WordManager.shared.wordsByCategory
    
    var body: some Scene {
        WindowGroup {
            Home(allWords: allWordsFromHome, wordsByCategories: wordsByCategories)
                .onAppear(perform: {
                    haptic.prepareHaptic()
                })
                .environmentObject(themesManager)
                .environmentObject(storeKitManager)
                .task {
                    await storeKitManager.updatePurchasedProducts()
                    configureAdvertiserTracking()
                }
        }
    }
}

func configureAdvertiserTracking() {
    // Verifier et demander l'autorisation si nécéssaire
    print(ATTrackingManager.trackingAuthorizationStatus.rawValue)
    
    if #available(iOS 14, *) {
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    Settings.shared.isAdvertiserTrackingEnabled = true
                    print("Autorized")
                default:
                    Settings.shared.isAdvertiserTrackingEnabled = false
                    print("Not autorized")
                }
            }
        } else {
            print("Authorization status is already determined: \(ATTrackingManager.trackingAuthorizationStatus)")
        }
    } else {
        print("Device not using iOS 14")
    }
}
