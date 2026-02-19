//
//  ManageExercisesView.swift
//  GymBroe
//
//  Created by Dylan on 15/12/2025.
//

import SwiftUI
import SwiftData

struct ManageExercisesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.createdAt, order: .reverse)
    private var exercises: [Exercise]

    // ✅ No createdAt on ExerciseEntry, so don't sort by it
    @Query
    private var entries: [ExerciseEntry]

    @State private var mergeGroup: [Exercise] = []
    @State private var showingMergeSheet = false

    private var duplicateGroups: [[Exercise]] {
        let grouped = Dictionary(grouping: exercises) { normalized($0.name) }
        return grouped.values
            .filter { $0.count >= 2 }
            .map { $0.sorted { $0.createdAt > $1.createdAt } }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            List {
                if duplicateGroups.isEmpty {
                    PremiumCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No duplicates found")
                                .font(.headline)

                            Text("You’re all good — no exercises share the same name.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section("Duplicates") {
                        ForEach(duplicateGroups.indices, id: \.self) { i in
                            let group = duplicateGroups[i]

                            PremiumCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(group.first?.name ?? "Duplicate")
                                        .font(.headline)

                                    Text("\(group.count) duplicates")
                                        .foregroundStyle(.secondary)

                                    Button {
                                        Haptics.light()
                                        mergeGroup = group
                                        showingMergeSheet = true
                                    } label: {
                                        Text("Merge")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color("AccentGreen"))
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Manage Exercises")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingMergeSheet) {
                MergeSheet(
                    exercises: mergeGroup,
                    onMerge: { keep, delete in
                        mergeExercises(keep: keep, delete: delete)
                        showingMergeSheet = false
                    }
                )
            }
        }
    }

    private func mergeExercises(keep: Exercise, delete: [Exercise]) {
        let deleteIDs = Set(delete.map { $0.persistentModelID })

        // ✅ repoint entries to the keep exercise
        for e in entries {
            if deleteIDs.contains(e.exercise.persistentModelID) {
                e.exercise = keep
            }
        }

        // ✅ delete duplicates
        for d in delete {
            context.delete(d)
        }

        try? context.save()
        Haptics.success()
    }

    private func normalized(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private struct MergeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exercises: [Exercise]
    let onMerge: (Exercise, [Exercise]) -> Void

    @State private var keep: Exercise?

    var body: some View {
        NavigationStack {
            Form {
                Section("Keep this one") {
                    Picker("Keep", selection: $keep) {
                        ForEach(exercises) { ex in
                            Text(ex.name).tag(Optional(ex))
                        }
                    }
                }

                Section {
                    GlowButton(title: "Merge", systemImage: "arrow.triangle.merge") {
                        guard let keep else { return }
                        let delete = exercises.filter { $0.persistentModelID != keep.persistentModelID }
                        Haptics.warning()
                        onMerge(keep, delete)
                        dismiss()
                    }
                    .disabled(keep == nil)
                    .opacity(keep == nil ? 0.45 : 1)
                }

                Section("What happens") {
                    Text("All logs/history from duplicates will be moved onto the kept exercise, then duplicates are deleted.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Merge Duplicates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { keep = exercises.first }
        }
    }
}
