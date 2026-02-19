//
//  NewTemplateSheet.swift
//  GymBroe
//
//  Created by Dylan on 15/12/2025.
//

import SwiftUI
import SwiftData

struct NewTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse)
    private var templates: [WorkoutTemplate]

    let onCreate: (WorkoutTemplate) -> Void

    @State private var name: String = ""
    @State private var showDuplicateAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Template name") {
                    TextField("e.g. PPL", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    Button {
                        create()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Create")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color("AccentGreen").opacity(0.95))
                    .foregroundStyle(.black)
                    .disabled(trimmedName.isEmpty)
                    .opacity(trimmedName.isEmpty ? 0.5 : 1)
                }
            }
            .navigationTitle("New Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        Haptics.light()
                        dismiss()
                    }
                }
            }
            .alert("Name already exists", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("That template name is already in your list.")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func create() {
        let trimmed = trimmedName
        guard !trimmed.isEmpty else { return }

        let normalized = trimmed.lowercased()
        let exists = templates.contains { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized }

        guard !exists else {
            Haptics.warning()
            showDuplicateAlert = true
            return
        }

        let t = WorkoutTemplate(name: trimmed)
        context.insert(t)
        try? context.save()

        Haptics.success()
        onCreate(t)
        dismiss()
    }
}
