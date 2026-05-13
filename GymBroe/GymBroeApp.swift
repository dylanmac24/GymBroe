//  GymBroeApp.swift
//  GymBroe

import SwiftUI
import SwiftData

@main
struct GymBroeApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [
            GymSession.self,
            Exercise.self,
            ExerciseEntry.self,
            ExerciseSet.self,
            WorkoutTemplate.self,
            WorkoutTemplateItem.self
        ])
    }
}
