//
//  NotificationsSettingsView.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 30/10/2023.
//

import SwiftUI
import AVFoundation


struct NotificationsSettingsView: View {
    
    @State var audioPlayer: AVAudioPlayer?

    @ObservedObject var vm : OnboardingView.TabViewModel
    
    let notificationManager = NotificationsManager.current
    
    @State var selectedTime : Date = Date()
        
    @State var isClicked : Bool = false
    
    @State private var selectedSound: NotificationSound = .default
    
    var body: some View {
        ZStack {
            VStack {
                OnboardingBackgroundImageView(imageName: "Onboarding2")
                    .scaleEffect(0.6)
                    .padding(.top)
                
                Spacer()
                
                MiddleText
                
                Spacer()
                
                VStack {
                    
                    ChooseTime
                    
                    SelectSound
                    
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                TriggerNotificationButton
                
                Spacer()
            }
        }
        .onAppear {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set up audio session: \(error)")
            }
        }
    }
    
    var ChooseTime : some View {
        DatePicker("Choose Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
            .padding()
            .background()
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .onTapGesture {
                isClicked = true
            }
    }
    
    var MiddleText : some View {
        VStack {
            Text("Set up your daily reminder")
                .font(.title)
                .bold()
                .fontDesign(.serif)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("Consistancy is key.\nChoose at what time you want to receive your daily reminder.")
                .fontDesign(.serif)
                .multilineTextAlignment(.center)
                .padding()
        }
        

    }
    
    var SelectSound: some View {
        HStack {
            Text("Sound")
            Spacer()
            HStack {
                Button {
                    // Move to previous sound option
                    HapticManager.shared.generateFeedback(for: .successLight)
                    moveSound(forward: false)
                } label: {
                    Image(systemName: "arrow.left.circle.fill")
                        .foregroundStyle(.main)
                }
                
                Text(selectedSound.rawValue.capitalized)
                    .frame(width: 90)
                
                Button {
                    // Move to next sound option
                    HapticManager.shared.generateFeedback(for: .successLight)
                    moveSound(forward: true)
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.main)
                }
            }
        }
        .padding()
        .background()
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    func moveSound(forward: Bool) {
        if let currentIndex = NotificationSound.allCases.firstIndex(of: selectedSound) {
            let nextIndex = forward ? currentIndex + 1 : currentIndex - 1
            if nextIndex >= 0 && nextIndex < NotificationSound.allCases.count {
                selectedSound = NotificationSound.allCases[nextIndex]
                playSound(for: selectedSound)
            }
        }
    }
    
    func playSound(for soundType: NotificationSound) {
        print("Trying to play sound: \(soundType.rawValue)")
        guard let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "caf") else {
            print("URL for sound file not found!")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error)")
        }
    }

    
    var TriggerNotificationButton : some View {
        
        MoveToNextPageButton(isActive: $isClicked) {
            notificationManager.hasNotificationPermission { hasPermission in
                if !hasPermission {
                    isClicked = true
                    // Ask for permission or inform the user
                    notificationManager.askPermission()
                    notificationManager.sendNotification(date: selectedTime, type: "date", title: "Back to Words", body: "Test notification", sound: selectedSound)
                    vm.moveToNextPage()

                } else {
                    isClicked = true
                    notificationManager.sendNotification(date: selectedTime, type: "date", title: "Back to Words", body: "Test notification", sound: selectedSound)
                    vm.moveToNextPage()
                }
            }
        }
    }
    
    
    
    var FooterText : some View {
        HStack {
            Image(systemName: "hand.draw")
            Text("swipe right")
        }
        .fontDesign(.rounded)
        .bold()
        .foregroundStyle(.main)
        .shadow(color: .gray.opacity(0.3), radius: 10)
        .frame(maxHeight: 60)
    }
}
    
    #Preview {
        NotificationsSettingsView(vm: OnboardingView.TabViewModel())
    }
    
    
    struct StartAtEndAt: View {
        @State private var selectedStartTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        @State private var selectedEndTime: Date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha" // Displays time in "9AM" format
            return formatter
        }()
        
        var body: some View {
            VStack {
                HStack {
                    Text("Start at")
                    Spacer()
                    DatePicker("", selection: $selectedStartTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(width: 100, alignment: .trailing)
                }
                
                Divider()
                    .padding(5)
                
                HStack {
                    Text("End at")
                    Spacer()
                    DatePicker("", selection: $selectedEndTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(width: 100, alignment: .trailing)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 120)
            .background(Color(.white))
            .cornerRadius(15)
        }
    }
