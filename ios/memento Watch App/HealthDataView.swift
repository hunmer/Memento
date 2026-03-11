//
//  HealthDataView.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI

struct HealthDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            HealthMetricCard(
                icon: "figure.walk",
                title: "步数",
                value: "8,432",
                unit: "步",
                color: .blue,
                goalProgress: 0.84
            )

            HealthMetricCard(
                icon: "heart.fill",
                title: "心率",
                value: "72",
                unit: "bpm",
                color: .red,
                goalProgress: 1.0
            )

            HealthMetricCard(
                icon: "flame.fill",
                title: "卡路里",
                value: "320",
                unit: "kcal",
                color: .orange,
                goalProgress: 0.45
            )
        }
        .navigationTitle("健康数据")
    }
}

struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let goalProgress: Double

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: goalProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.1))
        )
    }
}

#Preview {
    NavigationView {
        HealthDataView()
    }
}
