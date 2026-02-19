//
//  SessionsDetailView.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var context
    var session: GymSession

    @State private var showingAddExercise = false
    @State private var showingTemplatePicker = false

    private var title: String {
        session.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var sessionVolume: Double {
        session.exercises
            .flatMap { $0.sets }
            .reduce(0) { $0 + ($1.loadKg * Double($1.reps)) }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Session volume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(sessionVolume)) kg")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)

            Section("Exercises") {
                if session.exercises.isEmpty {
                    Text("No exercises yet. Tap + or use a template.")
                        .foregroundStyle(.secondary)
                }

                ForEach(session.exercises) { entry in
                    NavigationLink {
                        ExerciseEntryDetailView(entry: entry)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.exercise.name)
                                    .font(.headline)
                                Text("\(entry.sets.count) sets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()

                            let vol = entry.sets.reduce(0) { $0 + ($1.loadKg * Double($1.reps)) }
                            Text("\(Int(vol))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.06))
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Haptics.warning()
                            context.delete(entry)
                            try? context.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { idx in
                    Haptics.warning()
                    idx.forEach { context.delete(session.exercises[$0]) }
                    try? context.save()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 10) {

                    Button {
                        Haptics.light()
                        showingTemplatePicker = true
                    } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                    .tint(Color("AccentGreen"))

                    Button {
                        Haptics.light()
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            ExercisePickerView(session: session)
        }
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerSheet { template in
                Haptics.success()
                applyTemplate(template)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func applyTemplate(_ template: WorkoutTemplate) {
        let existingExerciseIDs = Set(session.exercises.map { $0.exercise.persistentModelID })

        let sortedItems = template.items.sorted { $0.orderIndex < $1.orderIndex }

        for item in sortedItems {
            let ex = item.exercise
            if existingExerciseIDs.contains(ex.persistentModelID) { continue }

            let entry = ExerciseEntry(exercise: ex, session: session)
            context.insert(entry)
        }

        try? context.save()
    }
}
