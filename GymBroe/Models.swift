//
//  Models.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import Foundation
import SwiftData

@Model
final class GymSession {
    var date: Date
    var notes: String

    @Relationship(deleteRule: .cascade)
    var exercises: [ExerciseEntry] = []

    init(date: Date = .now, notes: String = "") {
        self.date = date
        self.notes = notes
    }
}

enum ExerciseKind: String, Codable, CaseIterable, Identifiable {
    case weighted
    case bodyweight
    case bodyweightPlusLoad

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weighted: return "Weighted"
        case .bodyweight: return "Bodyweight"
        case .bodyweightPlusLoad: return "Bodyweight + Load"
        }
    }
}

@Model
final class ExerciseEntry {
    var exercise: Exercise
    var session: GymSession?

    @Relationship(deleteRule: .cascade)
    var sets: [SetEntry] = []

    init(exercise: Exercise, session: GymSession) {
        self.exercise = exercise
        self.session = session
    }
}

@Model
final class SetEntry {
    var reps: Int
    var loadKg: Double
    var note: String

    init(reps: Int, loadKg: Double, note: String = "") {
        self.reps = reps
        self.loadKg = loadKg
        self.note = note
    }
}
