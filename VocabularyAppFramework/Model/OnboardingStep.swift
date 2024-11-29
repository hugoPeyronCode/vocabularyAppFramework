//
//  OnboardingStep.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 29/11/2024.
//

import Foundation

enum OnboardingStep: Int, CaseIterable, Hashable {
    case intro
    case survey
    case userLevel
    case askForRating
    case notification
    case premium
}
