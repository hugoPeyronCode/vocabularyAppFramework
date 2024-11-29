//
//  Colors.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 22/09/2023.
//

import Foundation
import SwiftUI

extension Color {
    private func adjust(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let adjustmentAmount = percentage / 100

        return Color(
            red: min(1, max(0, red + adjustmentAmount)),
            green: min(1, max(0, green + adjustmentAmount)),
            blue: min(1, max(0, blue + adjustmentAmount)),
            opacity: alpha
        )
    }

    func adjustBrightness(byPercentage percentage: CGFloat) -> Color {
        return Color(UIColor { traitCollection in
            let baseColor = UIColor(self)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            baseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            let adjustmentAmount = percentage / 100
            let adjustedColor: UIColor

            switch traitCollection.userInterfaceStyle {
            case .light:
                adjustedColor = UIColor(
                    red: min(1, max(0, red - adjustmentAmount)),
                    green: min(1, max(0, green - adjustmentAmount)),
                    blue: min(1, max(0, blue - adjustmentAmount)),
                    alpha: alpha
                )
            case .dark:
                adjustedColor = UIColor(
                    red: min(1, max(0, red - adjustmentAmount * 0.7)),
                    green: min(1, max(0, green - adjustmentAmount * 0.7)),
                    blue: min(1, max(0, blue - adjustmentAmount * 0.7)),
                    alpha: alpha
                )
            @unknown default:
                adjustedColor = baseColor
            }
            return adjustedColor
        })
    }

    var dark: Color {
        return adjustBrightness(byPercentage: 20)
    }
}
