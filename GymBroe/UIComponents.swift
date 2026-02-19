//
//  UIComponents.swift
//  GymBroe
//
//  Created by Dylan on 15/12/2025.
//

import SwiftUI

struct GlowButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.light()
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AccentGreen").opacity(0.95),
                                Color("AccentGreen").opacity(0.80)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: Color("AccentGreen").opacity(0.22), radius: 14)
            .shadow(color: Color("AccentGreen").opacity(0.10), radius: 28)
        }
        .buttonStyle(.plain)
    }
}

struct PremiumCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

struct PremiumChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .black : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selected ? Color("AccentGreen").opacity(0.95) : Color.white.opacity(0.08))
                )
                .shadow(color: selected ? Color("AccentGreen").opacity(0.22) : .clear, radius: 14)
                .shadow(color: selected ? Color("AccentGreen").opacity(0.12) : .clear, radius: 26)
        }
        .buttonStyle(.plain)
    }
}

struct PPBadge: View {
    var body: some View {
        Text("PB")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color("AccentGreen").opacity(0.95))
            )
            .shadow(color: Color("AccentGreen").opacity(0.25), radius: 12)
            .shadow(color: Color("AccentGreen").opacity(0.14), radius: 22)
    }
}
