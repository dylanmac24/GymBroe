//
//  ExercisePickerView.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let session: GymSession

    @Query(sort: \Exercise.createdAt, order: .reverse)
    private var allExercises: [Exercise]

    @State private var search = ""
    @State private var showingNewExercise = false

    // rename
    @State private var renamingExercise: Exercise?
    @State private var renameText: String = ""
    @State private var showRenameDuplicateAlert = false

    // delete confirmation
    @State private var exerciseToDelete: Exercise?
    @State private var showDeleteAlert = false

    private var filtered: [Exercise] {
        let base: [Exercise] = search.isEmpty
        ? allExercises
        : allExercises.filter { $0.name.localizedCaseInsensitiveContains(search) }

        // favourites first, then recently used
        return base.sorted {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite && !$1.isFavorite }
            let a = $0.lastUsedAt ?? .distantPast
            let b = $1.lastUsedAt ?? .distantPast
            return a > b
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("No exercises yet")
                            .font(.headline)

                        Text("Tap + to create your first exercise.")
                            .foregroundStyle(.secondary)

                        GlowButton(title: "Create exercise") {
                            showingNewExercise = true
                        }
                    }
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                ForEach(filtered) { ex in
                    row(ex)
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewExercise = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewExercise) {
                AddExerciseLibraryView()
            }
            .sheet(item: $renamingExercise) { ex in
                renameSheet(for: ex)
            }
            .alert("Delete exercise?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    guard let ex = exerciseToDelete else { return }
                    Haptics.warning()
                    context.delete(ex)
                    try? context.save()
                    Haptics.success()
                    exerciseToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    exerciseToDelete = nil
                }
            } message: {
                Text("This will delete the exercise and its history.")
            }
        }
    }

    // MARK: - Row
    @ViewBuilder
    private func row(_ ex: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.name)
                    .font(.headline)

                Text(ex.kind.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Haptics.light()
                ex.isFavorite.toggle()
            } label: {
                Image(systemName: ex.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(ex.isFavorite ? Color("AccentGreen") : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.success()
            let entry = ExerciseEntry(exercise: ex, session: session)
            context.insert(entry)
            ex.lastUsedAt = .now
            try? context.save()
            dismiss()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                Haptics.light()
                renamingExercise = ex
                renameText = ex.name
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.gray)

            Button(role: .destructive) {
                exerciseToDelete = ex
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                renamingExercise = ex
                renameText = ex.name
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                exerciseToDelete = ex
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Rename sheet
    private func renameSheet(for ex: Exercise) -> some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $renameText)
                }

                Section {
                    GlowButton(title: "Save name") {
                        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        let normalized = trimmed.lowercased()
                        let exists = allExercises.contains { other in
                            other.persistentModelID != ex.persistentModelID &&
                            other.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
                        }

                        guard !exists else {
                            Haptics.warning()
                            showRenameDuplicateAlert = true
                            return
                        }

                        ex.name = trimmed
                        try? context.save()
                        Haptics.success()
                        renamingExercise = nil
                    }
                    .opacity(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
                    .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Rename")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { renamingExercise = nil }
                }
            }
            .alert("Name already exists", isPresented: $showRenameDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("That exercise name is already in your library.")
            }
        }
    }
}
