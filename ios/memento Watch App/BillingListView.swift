//
//  BillingListView.swift
//  memento Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

// MARK: - 账单列表视图

struct BillingListView: View {
    @StateObject private var viewModel = BillingListViewModel()

    // 主色调
    private let primaryColor = Color(red: 236/255, green: 91/255, blue: 19/255)  // #ec5b13

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("加载失败")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        Task {
                            await viewModel.loadBillItems()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.bills.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wallet.pass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无账单")
                        .font(.headline)
                    Text("最近7天没有账单记录\n在 iPhone 上记账后会同步到这里")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12, pinnedViews: []) {
                        // 按日期分组显示账单
                        ForEach(viewModel.groupedBills.keys.sorted(by: >), id: \.self) { dateKey in
                            BillDateGroup(
                                dateKey: dateKey,
                                bills: viewModel.groupedBills[dateKey] ?? []
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
                }
                .refreshable {
                    await viewModel.loadBillItems()
                }
            }
        }
        .navigationTitle("Billing")
        .task {
            await viewModel.loadBillItems()
        }
    }
}

// MARK: - 日期分组视图

struct BillDateGroup: View {
    let dateKey: String
    let bills: [BillItem]

    // 主色调
    private let primaryColor = Color(red: 236/255, green: 91/255, blue: 19/255)  // #ec5b13

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 日期标签
            Text(formatDateLabel(dateKey))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(primaryColor.opacity(0.7))
                .tracking(.wide(0.5))

            // 账单项列表
            VStack(spacing: 4) {
                ForEach(bills) { bill in
                    BillItemRow(bill: bill)
                }
            }
        }
    }

    private func formatDateLabel(_ dateKey: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateKey) else {
            return dateKey
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date).uppercased()
        }
    }
}

// MARK: - 账单项视图

struct BillItemRow: View {
    let bill: BillItem

    // 颜色定义
    private let primaryColor = Color(red: 236/255, green: 91/255, blue: 19/255)  // #ec5b13
    private let expenseColor = Color(red: 1.0, green: 0.231, blue: 0.188)  // #ff3b30
    private let incomeColor = Color(red: 0.204, green: 0.78, blue: 0.349)  // #34c759
    private let backgroundColor = Color(red: 10/255, green: 7/255, blue: 5/255)  // #0a0705

    var body: some View {
        HStack(spacing: 8) {
            // 图标容器
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(primaryColor.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: iconName(for: bill))
                    .font(.system(size: 16))
                    .foregroundStyle(primaryColor)
            }

            // 标题和分类
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(bill.category)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 金额
            Text(bill.formattedAmount)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(bill.isExpense ? expenseColor : incomeColor)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(primaryColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: primaryColor.opacity(0.15), radius: 4, x: 0, y: 0)
        )
    }

    // 根据账单分类返回图标名称
    private func iconName(for bill: BillItem) -> String {
        let category = bill.category.lowercased()

        if category.contains("music") || category.contains("音乐") {
            return "music.note"
        } else if category.contains("salary") || category.contains("工资") || category.contains("income") {
            return "banknote"
        } else if category.contains("food") || category.contains("餐饮") || category.contains("grocery") {
            return "cart"
        } else if category.contains("transport") || category.contains("交通") {
            return "car"
        } else if category.contains("utility") || category.contains("水电") || category.contains("bill") {
            return "bolt"
        } else if category.contains("subscription") || category.contains("订阅") {
            return "arrow.clockwise"
        } else if category.contains("shopping") || category.contains("购物") {
            return "bag"
        } else if category.contains("entertainment") || category.contains("娱乐") {
            return "gamecontroller"
        } else if category.contains("health") || category.contains("医疗") {
            return "cross.case"
        } else if category.contains("education") || category.contains("教育") {
            return "book"
        } else {
            return "wallet.pass"
        }
    }
}

// MARK: - ViewModel

@MainActor
class BillingListViewModel: ObservableObject {
    @Published var bills: [BillItem] = []
    @Published var groupedBills: [String: [BillItem]] = [:]
    @Published var isLoading = false
    @Published var error: String?

    func loadBillItems() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            bills = try await WCSessionManager.shared.getBillItems()
            groupedBills = groupBillsByDate(bills)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // 按日期分组账单
    private func groupBillsByDate(_ bills: [BillItem]) -> [String: [BillItem]] {
        var grouped: [String: [BillItem]] = [:]
        for bill in bills {
            let dateKey = bill.date
            if grouped[dateKey] == nil {
                grouped[dateKey] = []
            }
            grouped[dateKey]?.append(bill)
        }
        return grouped
    }
}

#Preview {
    NavigationView {
        BillingListView()
    }
}
