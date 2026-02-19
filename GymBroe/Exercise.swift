//
//  Exercise.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import SwiftData
import Foundation

@Model
final class Exercise {
    var name: String
    var kindRaw: String
    var createdAt: Date
    var isFavorite: Bool
    var lastUsedAt: Date?

    init(name: String, kind: ExerciseKind) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.createdAt = .now
        self.isFavorite = false
    }

    var kind: ExerciseKind {
        get { ExerciseKind(rawValue: kindRaw) ?? .weighted }
        set { kindRaw = newValue.rawValue }
    }
}
