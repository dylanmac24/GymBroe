//
//  AddExerciseLibraryView.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import SwiftUI
import SwiftData

struct AddExerciseLibraryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.createdAt, order: .reverse)
    private var allExercises: [Exercise]

    @State private var name = ""
    @State private var kind: ExerciseKind = .weighted
    @State private var showDuplicateAlert = false

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func nameExists(_ candidate: String) -> Bool {
        let normalized = candidate.lowercased()
        return allExercises.contains {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name (e.g., Bench Press)", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Type") {
                    Picker("Type", selection: $kind) {
                        ForEach(ExerciseKind.allCases) { k in
                            Text(k.displayName).tag(k)
                        }
                    }
                }

                Section {
                    GlowButton(title: "Save") {
                        guard !trimmedName.isEmpty else { return }
                        guard !nameExists(trimmedName) else {
                            Haptics.warning()
                            showDuplicateAlert = true
                            return
                        }

                        context.insert(Exercise(name: trimmedName, kind: kind))
                        Haptics.success()
                        dismiss()
                    }
                    .opacity(trimmedName.isEmpty ? 0.4 : 1.0)
                    .disabled(trimmedName.isEmpty)

                }
            }
            .navigationTitle("New Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Name already exists", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("That exercise name is already in your library.")
            }
        }
    }
}
