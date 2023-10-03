//
//  HapticManager.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 02/10/2023.
//

import Foundation
import UIKit
import SwiftUI
import CoreHaptics

enum HapticPreset {
    case successStrong
    case successLight
    case warningStrong
    case warningLight
    case errorStrong
    case errorLight
}

class HapticManager: ObservableObject {
    
    // Singleton instance
    static let shared = HapticManager()
    
    // Property to enable or disable haptic feedback
    @Published var isHapticEnabled: Bool = UserDefaults.standard.bool(forKey: "isHapticEnabled") {
        didSet {
            UserDefaults.standard.setValue(self.isHapticEnabled, forKey: "isHapticEnabled")
        }
    }
    
    private var engine : CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    
    init() {
        if UserDefaults.standard.object(forKey: "isHapticEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "isHapticEnabled")
        }
        _isHapticEnabled = Published(initialValue: UserDefaults.standard.bool(forKey: "isHapticEnabled"))
    }
    
    // Basic Haptic func: .success, .warning, .failure
    static func customNotification(type: UINotificationFeedbackGenerator.FeedbackType, strength: CGFloat = 1.0) {
        if HapticManager.shared.isHapticEnabled {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(type)
            
            let impactGenerator = UIImpactFeedbackGenerator()
            impactGenerator.prepare()
            impactGenerator.impactOccurred(intensity: min(max(strength, 0), 1))
        }
    }
    
    // Preparation function to activate the haptic in the device
    func prepareHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {return}
        guard isHapticEnabled else { 
            print("Haptic not enabled")
            return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic preparation failed: \(error.localizedDescription)")
        }
    }
    
    // Complex Haptic func.
    func complexFeedback(sharpness: Float, intensity: Float, occurrences: Int) {
        if isHapticEnabled {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            
            var events = [CHHapticEvent]()
            
            for i in 0..<occurrences {
                let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
                let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParameter, sharpnessParameter], relativeTime: Double(i) * 0.1)
                events.append(event)
            }
    
            do {
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine?.makeAdvancedPlayer(with: pattern)
                try player?.start(atTime: CHHapticTimeImmediate)
            } catch {
                print("Failed to play pattern: \(error.localizedDescription)")
            }
        }
    }
    
    func generateFeedback(for preset: HapticPreset) {
        switch preset {
        case .successStrong:
            complexFeedback(sharpness: 0.3, intensity: 1.0, occurrences: 2)
        case .successLight:
            complexFeedback(sharpness: 0.2, intensity: 0.5, occurrences: 1)
        case .warningStrong:
            complexFeedback(sharpness: 0.4, intensity: 1.0, occurrences: 2)
        case .warningLight:
            complexFeedback(sharpness: 0.3, intensity: 0.5, occurrences: 2)
        case .errorStrong:
            complexFeedback(sharpness: 0.9, intensity: 1.0, occurrences: 3)
        case .errorLight:
            complexFeedback(sharpness: 0.8, intensity: 0.5, occurrences: 3)
        }
    }
}
