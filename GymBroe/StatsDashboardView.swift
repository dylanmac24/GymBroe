//
//  StatsDashboardView.swift
//  GymBroe
//
//  Created by Dylan on 12/12/2025.
//

import SwiftUI
import SwiftData
import Charts
import UIKit

struct StatsDashboardView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Exercise.name, order: .forward)
    private var exercises: [Exercise]

    enum Metric: String, CaseIterable, Identifiable {
        case maxWeight = "Max Weight"
        case e1rm = "Est. 1RM"
        var id: String { rawValue }
        var unit: String { "kg" }
        var allTimeTitle: String { self == .maxWeight ? "All-time max" : "All-time est. 1RM" }
        var chartTitle: String { self == .maxWeight ? "Max weight trend" : "Estimated 1RM trend" }
    }

    enum RangeFilter: String, CaseIterable, Identifiable {
        case fourWeeks = "4W"
        case threeMonths = "3M"
        case all = "All"
        var id: String { rawValue }

        var caption: String {
            switch self {
            case .fourWeeks: return "last 4W"
            case .threeMonths: return "last 3M"
            case .all: return "all time"
            }
        }
    }

    @State private var selectedExerciseID: PersistentIdentifier?
    @State private var metric: Metric = .maxWeight
    @State private var range: RangeFilter = .all

    @State private var scrubbedPoint: ExerciseAnalytics.Point?
    @State private var isScrubbing = false

    private var selectedExercise: Exercise? {
        exercises.first { $0.persistentModelID == selectedExerciseID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    header

                    if exercises.isEmpty {
                        ContentUnavailableView(
                            "No exercises yet",
                            systemImage: "dumbbell",
                            description: Text("Add an exercise in a session first.")
                        )
                        .padding(.top, 24)
                    } else {
                        pickerRow

                        Picker("Metric", selection: $metric) {
                            ForEach(Metric.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        Picker("Range", selection: $range) {
                            ForEach(RangeFilter.allCases) { r in
                                Text(r.rawValue).tag(r)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if let ex = selectedExercise {
                            let rawPoints = metricPoints(for: ex)
                            let pointsInRange = applyRangeFilter(rawPoints)

                            let allTimePBPoint = rawPoints.max(by: { $0.value < $1.value })
                            let allTimePB = allTimePBPoint?.value ?? 0

                            let rangePBPoint = pointsInRange.max(by: { $0.value < $1.value })
                            let rangePB = rangePBPoint?.value ?? 0

                            // ✅ HERO: Chart first
                            if pointsInRange.count >= 2 {
                                ChartCard(
                                    title: metric.chartTitle,
                                    unitLabel: metric.unit,
                                    rangeLabel: range.rawValue,
                                    points: pointsInRange,
                                    pbPoint: rangePBPoint,
                                    scrubbedPoint: $scrubbedPoint,
                                    isScrubbing: $isScrubbing
                                )
                                .padding(.horizontal)

                                // Small caption under chart (replaces the big 3rd stat card)
                                SessionsCaption(count: pointsInRange.count, rangeCaption: range.caption)
                                    .padding(.horizontal)
                            } else {
                                // When not enough data, still keep the UI tight
                                ContentUnavailableView(
                                    "Not enough data",
                                    systemImage: "chart.line.uptrend.xyaxis",
                                    description: Text("Log \(ex.name) in at least 2 sessions in \(range.caption) to see the trend.")
                                )
                                .padding(.top, 18)
                            }

                            // ✅ Supporting stats (2 compact cards)
                            StatCardsRow(
                                allTimeTitle: metric.allTimeTitle,
                                allTimePB: allTimePB,
                                rangeBestTitle: "Best in \(range.rawValue)",
                                rangeBest: rangePB,
                                hasRangeData: pointsInRange.count > 0
                            )
                            .padding(.horizontal)
                            .padding(.top, 6)

                            Spacer(minLength: 16)

                        } else {
                            ContentUnavailableView(
                                "Pick an exercise",
                                systemImage: "chart.line.uptrend.xyaxis",
                                description: Text("Select a lift to see your trend over time.")
                            )
                            .padding(.top, 24)
                        }
                    }
                }
                .padding(.bottom, 22)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if selectedExerciseID == nil {
                    selectedExerciseID = exercises.first?.persistentModelID
                }
            }
            .onChange(of: exercises.count) { _, _ in
                if selectedExerciseID == nil || selectedExercise == nil {
                    selectedExerciseID = exercises.first?.persistentModelID
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Stats")
                .font(.largeTitle.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var pickerRow: some View {
        HStack {
            Text("Exercise")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Exercise", selection: $selectedExerciseID) {
                ForEach(exercises) { ex in
                    Text(ex.name).tag(Optional(ex.persistentModelID))
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
    }

    private func metricPoints(for ex: Exercise) -> [ExerciseAnalytics.Point] {
        switch metric {
        case .maxWeight:
            return ExerciseAnalytics.maxLoadPerSessionSeries(context: context, exercise: ex)
        case .e1rm:
            return ExerciseAnalytics.maxE1RMPerSessionSeries(context: context, exercise: ex)
        }
    }

    private func applyRangeFilter(_ points: [ExerciseAnalytics.Point]) -> [ExerciseAnalytics.Point] {
        guard !points.isEmpty else { return points }

        switch range {
        case .all:
            return points
        case .fourWeeks:
            let start = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? .distantPast
            return points.filter { $0.date >= start }
        case .threeMonths:
            let start = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? .distantPast
            return points.filter { $0.date >= start }
        }
    }
}

// MARK: - Small caption under chart

private struct SessionsCaption: View {
    let count: Int
    let rangeCaption: String

    var body: some View {
        HStack {
            Text("\(count) session\(count == 1 ? "" : "s") in \(rangeCaption)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 2)
    }
}

// MARK: - Chart Card (scrub + haptic ticks + PB badge)

private struct ChartCard: View {
    let title: String
    let unitLabel: String
    let rangeLabel: String
    let points: [ExerciseAnalytics.Point]
    let pbPoint: ExerciseAnalytics.Point?

    @Binding var scrubbedPoint: ExerciseAnalytics.Point?
    @Binding var isScrubbing: Bool

    @State private var lastHapticPointID: UUID?
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            chartView
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color("AccentGreen").opacity(0.10), lineWidth: 1)
        )
        .onAppear { haptic.prepare() }
    }

    private var header: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()

            Text(unitLabel)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    ZStack {
                        Color("AccentGreen").opacity(0.18).blur(radius: 10)
                        Color("AccentGreen").opacity(0.35)
                    }
                )
                .foregroundStyle(.black)
                .clipShape(Capsule())
        }
    }

    private var chartView: some View {
        Chart {
            baseMarks
            pbMarks
            scrubMarks
        }
        .chartYAxisLabel("kg")
        .frame(height: 240)
        .chartOverlay { proxy in
            overlay(proxy: proxy)
        }
        .overlay(alignment: .topLeading) {
            if let s = scrubbedPoint {
                ScrubTooltip(point: s)
                    .padding(.top, 8)
            }
        }
    }

    @ChartContentBuilder
    private var baseMarks: some ChartContent {
        ForEach(points) { p in
            LineMark(
                x: .value("Date", p.date),
                y: .value("Value", p.value)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(.init(lineWidth: 3))

            PointMark(
                x: .value("Date", p.date),
                y: .value("Value", p.value)
            )
            .symbolSize(24)
            .opacity(0.7)
        }
    }

    @ChartContentBuilder
    private var pbMarks: some ChartContent {
        if let pb = pbPoint {
            PointMark(
                x: .value("Date", pb.date),
                y: .value("Value", pb.value)
            )
            .symbolSize(80)
            .foregroundStyle(Color("AccentGreen"))
            .annotation(position: .top) {
                Text("PB \(rangeLabel)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.75))
                    .overlay(
                        Capsule()
                            .stroke(Color("AccentGreen").opacity(0.55), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }

            PointMark(
                x: .value("Date", pb.date),
                y: .value("Value", pb.value)
            )
            .symbolSize(200)
            .foregroundStyle(Color("AccentGreen").opacity(0.20))
        }
    }

    @ChartContentBuilder
    private var scrubMarks: some ChartContent {
        if let s = scrubbedPoint {
            RuleMark(x: .value("Scrub", s.date))
                .lineStyle(.init(lineWidth: 1))
                .foregroundStyle(.secondary.opacity(0.6))

            PointMark(
                x: .value("Date", s.date),
                y: .value("Value", s.value)
            )
            .symbolSize(90)
            .foregroundStyle(Color("AccentGreen"))
        }
    }

    private func overlay(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true

                            let frame = geo[proxy.plotAreaFrame]
                            let locationX = value.location.x - frame.origin.x

                            if let date: Date = proxy.value(atX: locationX),
                               let nearest = nearestPoint(to: date) {

                                if lastHapticPointID != nearest.id {
                                    haptic.impactOccurred()
                                    haptic.prepare()
                                    lastHapticPointID = nearest.id
                                }
                                scrubbedPoint = nearest
                            }
                        }
                        .onEnded { _ in
                            isScrubbing = false
                            lastHapticPointID = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                scrubbedPoint = nil
                            }
                        }
                )
        }
    }

    private func nearestPoint(to date: Date) -> ExerciseAnalytics.Point? {
        guard !points.isEmpty else { return nil }
        return points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
}

private struct ScrubTooltip: View {
    let point: ExerciseAnalytics.Point

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(String(format: "%.1f", point.value)) kg")
                .font(.subheadline.bold())
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("AccentGreen").opacity(0.9))
        )
        .shadow(color: Color("AccentGreen").opacity(0.35), radius: 16)
        .shadow(color: Color("AccentGreen").opacity(0.18), radius: 32)
    }
}

// MARK: - Compact 2-card row

private struct StatCardsRow: View {
    let allTimeTitle: String
    let allTimePB: Double

    let rangeBestTitle: String
    let rangeBest: Double
    let hasRangeData: Bool

    var body: some View {
        HStack(spacing: 12) {
            CompactStatCard(
                title: allTimeTitle,
                value: "\(String(format: "%.1f", allTimePB)) kg",
                accent: true
            )

            CompactStatCard(
                title: rangeBestTitle,
                value: hasRangeData ? "\(String(format: "%.1f", rangeBest)) kg" : "—",
                accent: false
            )
        }
    }
}

private struct CompactStatCard: View {
    let title: String
    let value: String
    let accent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12) // compact height
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accent ? Color("AccentGreen").opacity(0.14) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
