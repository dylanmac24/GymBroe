//
//  GymBroeApp.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

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
