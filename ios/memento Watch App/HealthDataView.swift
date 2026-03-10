//
//  HealthDataView.swift
//  memento_watchos Watch App
//
//  Created by liao on 2026/3/9.
//

import SwiftUI

struct HealthMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}

struct HealthDataView: View {
    private let metrics = [
        HealthMetric(title: "今日步数", value: "8,432", icon: "figure.walk", color: .blue),
        HealthMetric(title: "消耗卡路里", value: "324 kcal", icon: "flame.fill", color: .orange),
        HealthMetric(title: "运动时间", value: "45 min", icon: "timer", color: .green),
        HealthMetric(title: "心率", value: "72 bpm", icon: "heart.fill", color: .red),
        HealthMetric(title: "睡眠时间", value: "7.5 h", icon: "bed.double.fill", color: .purple),
        HealthMetric(title: "站立次数", value: "12/12", icon: "figure.stand", color: .cyan)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(metrics) { metric in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(metric.color.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: metric.icon)
                                .foregroundStyle(metric.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(metric.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(metric.value)
                                .font(.headline)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.1))
                    )
                }
            }
            .padding()
        }
        .navigationTitle("健康数据")
    }
}

#Preview {
    NavigationView {
        HealthDataView()
    }
}
