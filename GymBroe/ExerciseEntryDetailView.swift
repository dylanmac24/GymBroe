//
//  ExerciseEntryDetailView.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import SwiftUI
import SwiftData

struct ExerciseEntryDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var entry: ExerciseEntry

    @State private var repsText: String = ""
    @State private var loadText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                setsCard

                addSetCard
            }
            .padding(16)
        }
        .navigationTitle(entry.exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.exercise.name)
                .font(.title2.weight(.bold))

            Text(entry.exercise.kind.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var setsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sets")
                    .font(.headline)
                Spacer()
                PremiumPill(text: "\(entry.sets.count)")
            }

            if entry.sets.isEmpty {
                Text("No sets yet. Add one below.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(entry.sets) { s in
                    HStack {
                        Text("\(s.reps) reps")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(String(format: "%.1f kg", s.loadKg))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Haptics.warning()
                            entry.sets.removeAll { $0.persistentModelID == s.persistentModelID }
                            context.delete(s)
                            try? context.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    Divider().opacity(0.15)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var addSetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add set")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("Reps", text: $repsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                TextField("kg", text: $loadText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            GlowButton(title: "Add set", systemImage: "plus") {
                let reps = Int(repsText) ?? 0
                let load = Double(loadText) ?? 0
                guard reps > 0 else { return }

                let set = SetEntry(reps: reps, loadKg: load)
                context.insert(set)
                entry.sets.append(set)
                try? context.save()

                repsText = ""
                loadText = ""
                Haptics.success()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }
}
