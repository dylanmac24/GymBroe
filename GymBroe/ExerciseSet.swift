//
//  ExerciseSet.swift
//  GymBroe
//
//  Created by Dylan on 15/12/2025.
//

import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var reps: Int
    var loadKg: Double
    var createdAt: Date

    init(reps: Int, loadKg: Double, createdAt: Date = .now) {
        self.reps = reps
        self.loadKg = loadKg
        self.createdAt = createdAt
    }
}
