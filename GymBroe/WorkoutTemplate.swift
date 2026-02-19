//
//  WorkoutTemplate.swift
//  GymBroe
//
//  Created by Dylan on 15/12/2025.
//

import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var name: String
    var createdAt: Date

    @Relationship(inverse: \WorkoutTemplateItem.template)
    var items: [WorkoutTemplateItem] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}

@Model
final class WorkoutTemplateItem {
    var orderIndex: Int
    var createdAt: Date

    // link to your Exercise library
    var exercise: Exercise

    // inverse link
    var template: WorkoutTemplate?

    init(exercise: Exercise, orderIndex: Int, template: WorkoutTemplate? = nil, createdAt: Date = .now) {
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.template = template
        self.createdAt = createdAt
    }
}
