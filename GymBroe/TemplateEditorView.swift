//
//  TemplateEditorView.swift
//  GymBroe
//
//  Created by Dylan on 15/12/2025.
//

import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var template: WorkoutTemplate

    @State private var showingAddExercise = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(template.name)
                        .fontWeight(.semibold)
                }
            }
            .listRowBackground(Color.clear)

            Section("Exercises") {
                if template.items.isEmpty {
                    Text("No exercises yet. Tap “Add exercise”.")
                        .foregroundStyle(.secondary)
                }

                ForEach(sortedItems) { item in
                    HStack {
                        Text(item.exercise.name)
                            .font(.headline)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.06))
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Haptics.warning()
                            deleteItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: moveItems)
                .onDelete { indexSet in
                    Haptics.warning()
                    indexSet.forEach { deleteItem(sortedItems[$0]) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    showingAddExercise = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .tint(Color("AccentGreen"))
            }

            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            TemplateExercisePickerSheet { ex in
                addExercise(ex)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var sortedItems: [WorkoutTemplateItem] {
        template.items.sorted { $0.orderIndex < $1.orderIndex }
    }

    private func addExercise(_ ex: Exercise) {
        let nextIndex = (template.items.map(\.orderIndex).max() ?? -1) + 1
        let item = WorkoutTemplateItem(exercise: ex, orderIndex: nextIndex, template: template)
        context.insert(item)
        template.items.append(item)
        renumber()
        try? context.save()
        Haptics.success()
    }

    private func deleteItem(_ item: WorkoutTemplateItem) {
        template.items.removeAll { $0.persistentModelID == item.persistentModelID }
        context.delete(item)
        renumber()
        try? context.save()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var items = sortedItems
        items.move(fromOffsets: source, toOffset: destination)
        for (i, it) in items.enumerated() {
            it.orderIndex = i
        }
        try? context.save()
        Haptics.light()
    }

    private func renumber() {
        let items = sortedItems
        for (i, it) in items.enumerated() {
            it.orderIndex = i
        }
    }
}
