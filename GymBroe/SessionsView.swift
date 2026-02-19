//
//  SessionsView.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import SwiftUI
import SwiftData

struct SessionsView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \GymSession.date, order: .reverse)
    private var sessions: [GymSession]

    @Query private var allEntries: [ExerciseEntry]

    @State private var path: [GymSession] = []

    // delete
    @State private var sessionToDelete: GymSession?
    @State private var showDeleteAlert = false

    // templates
    @State private var showingTemplatePicker = false
    @State private var showingTemplatesManager = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                background

                List {
                    Section {
                        heroHeader
                        progressNarrativePill
                        weekChips
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16))

                    if sessions.isEmpty {
                        Section {
                            emptyState
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16))
                    } else {
                        Section {
                            ForEach(sessions) { s in
                                SessionCard(
                                    session: s,
                                    entries: entriesForSession(s),
                                    hasPR: sessionHasPR(s)
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    Haptics.light()
                                    path.append(s)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Haptics.warning()
                                        sessionToDelete = s
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }

                    Spacer(minLength: 26)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationDestination(for: GymSession.self) { s in
                SessionDetailView(session: s)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Haptics.light()
                            createOrOpenToday()
                        } label: {
                            Label("Start / Open Today", systemImage: "plus.circle.fill")
                        }

                        Button {
                            showingTemplatePicker = true
                        } label: {
                            Label("Start From Template", systemImage: "square.grid.2x2")
                        }

                        Button {
                            showingTemplatesManager = true
                        } label: {
                            Label("Manage Templates", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.10)))
                    }
                }
            }
            .alert("Delete session?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    guard let s = sessionToDelete else { return }
                    deleteSession(s)
                    sessionToDelete = nil
                }
                Button("Cancel", role: .cancel) { sessionToDelete = nil }
            } message: {
                Text("This removes the session and all logged exercises/sets inside it.")
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerSheet { template in
                    startSession(from: template)
                }
            }
            .sheet(isPresented: $showingTemplatesManager) {
                TemplatesView()
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.92), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color("AccentGreen").opacity(0.16), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 380
            )
            .blur(radius: 24)
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GymBroe")
                .font(.largeTitle.weight(.bold))

            Text("Log today. Beat yesterday.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 6)
    }

    // MARK: - Progress Narrative (replaces duplicate “sessions” text)

    private var progressNarrativePill: some View {
        let now = Date()
        let thisStart = startOfWeek(now)
        let lastStart = Calendar.current.date(byAdding: .day, value: -7, to: thisStart) ?? thisStart

        let thisWeekSessions = sessions.filter { $0.date >= thisStart }
        let lastWeekSessions = sessions.filter { $0.date >= lastStart && $0.date < thisStart }

        let thisWeekEntries = entriesForSessions(thisWeekSessions)
        let lastWeekEntries = entriesForSessions(lastWeekSessions)

        let thisVol = thisWeekEntries.reduce(0.0) { $0 + volumeKg(entry: $1) }
        let lastVol = lastWeekEntries.reduce(0.0) { $0 + volumeKg(entry: $1) }

        let prs = weeklyPRCount(weekEntries: thisWeekEntries)

        let deltaKg = thisVol - lastVol
        let volText: String = {
            guard lastVol > 0 else { return "Volume: \(formatKg(thisVol))" }
            let sign = deltaKg >= 0 ? "+" : "−"
            return "Volume: \(sign)\(formatKg(abs(deltaKg)))"
        }()

        return HStack(spacing: 8) {
            Text("This week")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("•").font(.caption).foregroundStyle(.secondary)

            Text(volText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(lastVol == 0 ? .secondary : (deltaKg >= 0 ? Color("AccentGreen") : .secondary))

            Text("•").font(.caption).foregroundStyle(.secondary)

            Text("\(prs) PR\(prs == 1 ? "" : "s")")
                .font(.caption.weight(.semibold))
                .foregroundStyle(prs > 0 ? Color("AccentGreen") : .secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule().fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Week chips

    private var weekChips: some View {
        let start = startOfWeek(Date())
        let weekSessions = sessions.filter { $0.date >= start }
        let weekEntries = entriesForSessions(weekSessions)

        let volume = weekEntries.reduce(0.0) { $0 + volumeKg(entry: $1) }
        let setCount = weekEntries.reduce(0) { $0 + $1.sets.count }

        return HStack(spacing: 10) {
            chipCard(title: "This week", value: "\(weekSessions.count) sessions")
            chipCard(title: "Sets", value: "\(setCount)")
            chipCard(title: "Volume", value: formatKg(volume))
        }
    }

    private func chipCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No sessions yet")
                .font(.headline)

            Text("Start a session, add exercises, and your stats will build automatically.")
                .foregroundStyle(.secondary)

            GlowButton(title: "Start first session", systemImage: "plus") {
                createOrOpenToday()
            }

            // sample preview so it doesn’t feel empty
            SampleSessionCard()
                .padding(.top, 6)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Actions

    private func createOrOpenToday() {
        if let existing = sessions.first(where: { Calendar.current.isDateInToday($0.date) }) {
            path.append(existing)
            return
        }
        let new = GymSession(date: .now)
        context.insert(new)
        try? context.save()
        path.append(new)
    }

    private func deleteSession(_ s: GymSession) {
        // delete entries linked to this session (safe even if you have cascade)
        let sid = s.persistentModelID
        let related = allEntries.filter { $0.session?.persistentModelID == sid }
        for e in related {
            context.delete(e)
        }

        context.delete(s)
        try? context.save()
        Haptics.success()
    }

    // MARK: - Helpers

    private func startOfWeek(_ date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
    }

    private func entriesForSessions(_ list: [GymSession]) -> [ExerciseEntry] {
        let ids = Set(list.map { $0.persistentModelID })
        return allEntries.filter { e in
            guard let sid = e.session?.persistentModelID else { return false }
            return ids.contains(sid)
        }
    }

    private func entriesForSession(_ s: GymSession) -> [ExerciseEntry] {
        let sid = s.persistentModelID
        return allEntries.filter { $0.session?.persistentModelID == sid }
    }

    private func volumeKg(entry: ExerciseEntry) -> Double {
        entry.sets.reduce(0.0) { $0 + ($1.loadKg * Double($1.reps)) }
    }

    private func formatKg(_ value: Double) -> String {
        if value >= 1000 { return String(format: "%.0f kg", value) }
        return String(format: "%.1f kg", value)
    }

    private func weeklyPRCount(weekEntries: [ExerciseEntry]) -> Int {
        var prExercises = Set<PersistentIdentifier>()

        for e in weekEntries {
            let ex = e.exercise
            let allForEx = allEntries.filter { $0.exercise.persistentModelID == ex.persistentModelID }
            let allTimeBest = allForEx.flatMap(\.sets).map(\.loadKg).max() ?? 0
            let bestInEntry = e.sets.map(\.loadKg).max() ?? 0

            if bestInEntry > 0 && abs(bestInEntry - allTimeBest) < 0.0001 {
                prExercises.insert(ex.persistentModelID)
            }
        }

        return prExercises.count
    }

    private func sessionHasPR(_ s: GymSession) -> Bool {
        let sessionEntries = entriesForSession(s)
        guard !sessionEntries.isEmpty else { return false }

        for e in sessionEntries {
            let ex = e.exercise
            let allForEx = allEntries.filter { $0.exercise.persistentModelID == ex.persistentModelID }
            let allTimeBest = allForEx.flatMap(\.sets).map(\.loadKg).max() ?? 0
            let bestInEntry = e.sets.map(\.loadKg).max() ?? 0

            if bestInEntry > 0 && abs(bestInEntry - allTimeBest) < 0.0001 {
                return true
            }
        }
        return false
    }

    // MARK: - Templates

    private func startSession(from template: WorkoutTemplate) {
        let new = GymSession(date: .now)
        context.insert(new)

        // create entries for each template item (in order)
        let items = template.items.sorted(by: { $0.orderIndex < $1.orderIndex })
        for item in items {
            let entry = ExerciseEntry(exercise: item.exercise, session: new)
            context.insert(entry)
        }

        try? context.save()
        Haptics.success()
        path.append(new)
    }
}

// MARK: - Session card
private struct SessionCard: View {
    let session: GymSession
    let entries: [ExerciseEntry]
    let hasPR: Bool

    var body: some View {
        let dateText = session.date.formatted(date: .abbreviated, time: .omitted)
        let exCount = entries.count
        let vol = entries.reduce(0.0) { partial, e in
            partial + e.sets.reduce(0.0) { $0 + ($1.loadKg * Double($1.reps)) }
        }

        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(dateText)
                        .font(.headline)

                    if hasPR {
                        PRBadge()
                    }
                }

                Text("\(exCount) exercises • \(formatKg(vol)) volume")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func formatKg(_ value: Double) -> String {
        if value >= 1000 { return String(format: "%.0f kg", value) }
        return String(format: "%.1f kg", value)
    }
}

private struct PRBadge: View {
    var body: some View {
        Text("PR")
            .font(.caption.weight(.bold))
            .foregroundStyle(.black)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule().fill(Color("AccentGreen").opacity(0.95))
            )
            .shadow(color: Color("AccentGreen").opacity(0.20), radius: 12)
    }
}

private struct SampleSessionCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Example session")
                    .font(.headline)

                Text("4 exercises • 2,340 kg volume")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .opacity(0.8)
    }
}

// MARK: - TemplatePickerSheet (local fallback so it's always in scope)
struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse)
    private var templates: [WorkoutTemplate]

    let onPick: (WorkoutTemplate) -> Void

    var body: some View {
        NavigationStack {
            List {
                if templates.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No templates yet")
                            .font(.headline)
                        Text("Create one in Templates first, then come back here.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(templates) { t in
                        Button {
                            Haptics.light()
                            onPick(t)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(t.name).font(.headline)
                                    Text("\(t.items.count) exercises")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.06))
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Start From Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
