//
//  CustomSlider.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 30/10/2023.
//

import SwiftUI
struct CustomSlider: UIViewRepresentable {
    @Binding var value: Int
    
    var minValue: Int
    var maxValue: Int
    var thumbColor: UIColor
    var minTrackColor: UIColor
    var maxTrackColor: UIColor

    class Coordinator: NSObject {
        var value: Binding<Int>
        
        init(value: Binding<Int>) {
            self.value = value
        }
        
        @objc func valueChanged(_ sender: UISlider) {
            self.value.wrappedValue = Int(sender.value)
        }
    }
    
    func makeCoordinator() -> CustomSlider.Coordinator {
        Coordinator(value: $value)
    }
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider(frame: .zero)
        slider.thumbTintColor = thumbColor
        slider.minimumTrackTintColor = minTrackColor
        slider.maximumTrackTintColor = maxTrackColor
        slider.minimumValue = Float(minValue)
        slider.maximumValue = Float(maxValue)
        slider.value = Float(value)
        
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
    }
}


#Preview {
    CustomSlider(value: .constant(Int(10.0)), minValue: Int(1.0), maxValue: Int(10.0), thumbColor: .orange, minTrackColor: .orange, maxTrackColor: .lightGray)
}
