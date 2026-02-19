//
//  TemplatesView.swift
//  GymBroe
//
//  Created by Dylan on 15/12/2025.
//

import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse)
    private var templates: [WorkoutTemplate]

    @State private var showingNewTemplate = false
    @State private var selectedTemplate: WorkoutTemplate? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Templates")
                            .font(.largeTitle.weight(.bold))
                            .padding(.top, 6)

                        if templates.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 10) {
                                ForEach(templates) { t in
                                    Button {
                                        Haptics.light()
                                        selectedTemplate = t
                                    } label: {
                                        templateRow(t)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 6)
                        }

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationDestination(item: $selectedTemplate) { t in
                TemplateEditorView(template: t)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        showingNewTemplate = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.10)))
                    }
                }
            }
            .sheet(isPresented: $showingNewTemplate) {
                NewTemplateSheet { created in
                    Haptics.success()
                    selectedTemplate = created
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.92), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color("AccentGreen").opacity(0.16),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 380
            )
            .blur(radius: 24)
            .ignoresSafeArea()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No templates yet")
                .font(.headline)

            Text("Create one to quickly log your PPL / Chest+Back / Sharms days.")
                .foregroundStyle(.secondary)

            Button {
                Haptics.light()
                showingNewTemplate = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create first template")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("AccentGreen").opacity(0.95))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func templateRow(_ t: WorkoutTemplate) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(t.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(t.items.count) exercises • \(t.createdAt.formatted(date: .abbreviated, time: .omitted))")
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
}
