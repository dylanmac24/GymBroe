//
//  TemplatePickerSheet.swift
//  GymBroe
//
//  Created by Dylan on 15/12/2025.
//

import SwiftUI
import SwiftData

struct TemplateExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.createdAt, order: .reverse)
    private var exercises: [Exercise]

    @State private var search: String = ""

    let onPick: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { ex in
                    Button {
                        Haptics.light()
                        onPick(ex)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ex.name).font(.headline)
                                Text(ex.kind.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color("AccentGreen"))
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $search, prompt: "Search exercises")
            .background(
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.92), Color.black],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        Haptics.light()
                        dismiss()
                    }
                }
            }
        }
    }

    private var filtered: [Exercise] {
        let base = search.isEmpty ? exercises : exercises.filter {
            $0.name.localizedCaseInsensitiveContains(search)
        }
        return base
    }
}
