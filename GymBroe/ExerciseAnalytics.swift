//
//  ExerciseAnalytics.swift
//  GymBroe
//
//  Created by Dylan on 13/12/2025.
//

import Foundation
import SwiftData

struct ExerciseAnalytics {

    // Epley estimated 1RM
    static func e1RM(loadKg: Double, reps: Int) -> Double {
        guard reps > 0 else { return loadKg }
        return loadKg * (1.0 + (Double(reps) / 30.0))
    }

    static func allTimeMaxLoadKg(context: ModelContext, exercise: Exercise) -> Double {
        let entries = fetchEntries(context: context, exercise: exercise)
        let allSets = entries.flatMap { $0.sets }
        return allSets.map(\.loadKg).max() ?? 0
    }

    static func allTimeMaxE1RM(context: ModelContext, exercise: Exercise) -> Double {
        let entries = fetchEntries(context: context, exercise: exercise)
        let allSets = entries.flatMap { $0.sets }
        return allSets.map { e1RM(loadKg: $0.loadKg, reps: $0.reps) }.max() ?? 0
    }

    /// Max LOAD per day (for trend)
    static func maxLoadPerSessionSeries(context: ModelContext, exercise: Exercise) -> [Point] {
        series(context: context, exercise: exercise) { sets in
            sets.map(\.loadKg).max() ?? 0
        }
    }

    /// Max estimated 1RM per day (for trend)
    static func maxE1RMPerSessionSeries(context: ModelContext, exercise: Exercise) -> [Point] {
        series(context: context, exercise: exercise) { sets in
            sets.map { e1RM(loadKg: $0.loadKg, reps: $0.reps) }.max() ?? 0
        }
    }

    // MARK: - Series builder

    private static func series(
        context: ModelContext,
        exercise: Exercise,
        metric: ([SetEntry]) -> Double
    ) -> [Point] {
        let entries = fetchEntries(context: context, exercise: exercise)
            .sorted { ($0.session?.date ?? .distantPast) < ($1.session?.date ?? .distantPast) }

        var map: [Date: Double] = [:]
        let cal = Calendar.current

        for entry in entries {
            guard let d = entry.session?.date else { continue }
            let day = cal.startOfDay(for: d)

            let value = metric(entry.sets)
            map[day] = max(map[day] ?? 0, value)
        }

        return map.keys.sorted().map { day in
            Point(date: day, value: map[day] ?? 0)
        }
    }

    // MARK: - Helpers (SwiftData-safe)
    private static func fetchEntries(context: ModelContext, exercise: Exercise) -> [ExerciseEntry] {
        let descriptor = FetchDescriptor<ExerciseEntry>()
        let all = (try? context.fetch(descriptor)) ?? []

        let targetID = exercise.persistentModelID
        return all.filter { $0.exercise.persistentModelID == targetID }
    }

    struct Point: Identifiable, Equatable {
        let id = UUID()
        let date: Date
        let value: Double
    }
}
