//
//  ReportsView.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import SwiftUI
import SwiftData

struct ReportsView: View {
    @Query(sort: \GymSession.date, order: .reverse)
    private var sessions: [GymSession]

    @Query private var entries: [ExerciseEntry]
    @Query private var exercises: [Exercise]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Reports")
                    .font(.largeTitle.weight(.bold))
                    .padding(.top, 8)

                weeklySummaryCard
                streakCard
                mostImprovedCard

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
        }
        .background(
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.92), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Cards

    private var weeklySummaryCard: some View {
        let now = Date()
        let thisStart = startOfWeek(for: now)
        let lastStart = Calendar.current.date(byAdding: .day, value: -7, to: thisStart) ?? thisStart
        let lastEnd = thisStart

        let thisWeek = sessions.filter { $0.date >= thisStart }
        let lastWeek = sessions.filter { $0.date >= lastStart && $0.date < lastEnd }

        let thisSessions = thisWeek.count

        let thisEntries = entriesForSessions(thisWeek)
        let lastEntries = entriesForSessions(lastWeek)

        let thisSets = thisEntries.reduce(0) { $0 + $1.sets.count }
        let thisVol = thisEntries.reduce(0.0) { $0 + volumeKg(entry: $1) }
        let lastVol = lastEntries.reduce(0.0) { $0 + volumeKg(entry: $1) }

        let delta = lastVol > 0 ? ((thisVol - lastVol) / lastVol) * 100.0 : 0

        return reportCard(title: "Weekly Summary") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    metric("Sessions", "\(thisSessions)")
                    Spacer()
                    metric("Sets", "\(thisSets)")
                }
                HStack {
                    metric("Volume", formatKg(thisVol))
                    Spacer()
                    metric("vs last week", lastVol > 0 ? String(format: "%+.0f%%", delta) : "—")
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var streakCard: some View {
        let streakWeeks = computeWeeklyStreak()
        let longest = computeLongestWeeklyStreak()

        return reportCard(title: "Consistency") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    metric("Current streak", "\(streakWeeks) weeks")
                    Spacer()
                    metric("Longest", "\(longest) weeks")
                }
                Text(streakWeeks >= 2 ? "🔥 You’re building momentum." : "Keep it rolling — streaks compound fast.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mostImprovedCard: some View {
        let winner = computeMostImprovedLift()

        return reportCard(title: "Most Improved (30D)") {
            if let w = winner {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(w.name)
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%+.1f kg", w.delta))
                            .font(.headline)
                            .foregroundStyle(Color("AccentGreen"))
                            .shadow(color: Color("AccentGreen").opacity(0.18), radius: 14)
                    }
                    Text("Best 30D: \(formatKg(w.best30))  •  Prev: \(formatKg(w.prev30))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Not enough data yet.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Base premium card

    private func reportCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
        }
    }

    // MARK: - Helpers

    private func entriesForSessions(_ list: [GymSession]) -> [ExerciseEntry] {
        let ids = Set(list.map { $0.persistentModelID })
        return entries.filter { e in
            guard let sid = e.session?.persistentModelID else { return false }
            return ids.contains(sid)
        }
    }

    private func volumeKg(entry: ExerciseEntry) -> Double {
        entry.sets.reduce(0.0) { partial, s in
            partial + (s.loadKg * Double(s.reps))
        }
    }

    private func formatKg(_ value: Double) -> String {
        if value >= 1000 { return String(format: "%.0f kg", value) }
        return String(format: "%.1f kg", value)
    }

    private func startOfWeek(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
    }

    private func computeWeeklyStreak() -> Int {
        let grouped = Dictionary(grouping: sessions) { startOfWeek(for: $0.date) }
        var streak = 0
        var week = startOfWeek(for: Date())

        while grouped[week]?.isEmpty == false {
            streak += 1
            week = Calendar.current.date(byAdding: .day, value: -7, to: week) ?? week
        }
        return streak
    }

    private func computeLongestWeeklyStreak() -> Int {
        let grouped = Dictionary(grouping: sessions) { startOfWeek(for: $0.date) }
        let weeks = grouped.keys.sorted()

        var best = 0
        var current = 0
        var prev: Date?

        for w in weeks {
            if let p = prev,
               let expected = Calendar.current.date(byAdding: .day, value: 7, to: p),
               Calendar.current.isDate(expected, inSameDayAs: w) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            prev = w
        }
        return best
    }

    private func computeMostImprovedLift() -> (name: String, delta: Double, best30: Double, prev30: Double)? {
        let now = Date()
        let start30 = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let start60 = Calendar.current.date(byAdding: .day, value: -60, to: now) ?? now

        var best30: [PersistentIdentifier: Double] = [:]
        var prev30: [PersistentIdentifier: Double] = [:]

        for e in entries {
            // ✅ exercise is NON-optional in your project
            let ex = e.exercise

            guard let d = e.session?.date else { continue }

            let bestInEntry = e.sets.map(\.loadKg).max() ?? 0

            if d >= start30 {
                best30[ex.persistentModelID] = max(best30[ex.persistentModelID] ?? 0, bestInEntry)
            } else if d >= start60 {
                prev30[ex.persistentModelID] = max(prev30[ex.persistentModelID] ?? 0, bestInEntry)
            }
        }

        var winner: (PersistentIdentifier, Double, Double, Double)?
        for ex in exercises {
            let b30 = best30[ex.persistentModelID] ?? 0
            let p30 = prev30[ex.persistentModelID] ?? 0
            let delta = b30 - p30
            if delta <= 0 { continue }
            if winner == nil || delta > winner!.1 {
                winner = (ex.persistentModelID, delta, b30, p30)
            }
        }

        guard let w = winner,
              let ex = exercises.first(where: { $0.persistentModelID == w.0 }) else { return nil }

        return (ex.name, w.1, w.2, w.3)
    }
}
