//
//  RootTabView.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            SessionsView()
                .tabItem { Label("Log", systemImage: "list.bullet") }

            StatsDashboardView()
                .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }

            ReportsView()
                .tabItem { Label("Reports", systemImage: "doc.text.magnifyingglass") }

            TemplatesView()
                .tabItem { Label("Templates", systemImage: "square.grid.2x2") }
        }
        .tint(Color("AccentGreen"))
        .preferredColorScheme(.dark) // ✅ keeps templates from turning white
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

