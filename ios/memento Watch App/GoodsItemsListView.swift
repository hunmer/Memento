//
//  GoodsItemsListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

/// 物品列表视图
struct GoodsItemsListView: View {
    let warehouse: GoodsWarehouse?
    let title: String

    @StateObject private var viewModel: GoodsItemsViewModel

    init(warehouse: GoodsWarehouse?, title: String = "物品") {
        self.warehouse = warehouse
        self.title = title
        _viewModel = StateObject(wrappedValue: GoodsItemsViewModel(warehouse: warehouse))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.error {
                VStack(spacing: 20) {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Button("重试") {
                        Task { await viewModel.loadData() }
                    }
                }
            } else if viewModel.items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "cube.box")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("暂无物品")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.items) { item in
                            GoodsItemRow(item: item)
                        }
                    }
                }
                .navigationTitle(warehouse?.title ?? "所有物品")
            }
        }
        .task { await viewModel.loadData() }
    }
}

/// 物品行组件
struct GoodsItemRow: View {
    let item: GoodsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 标题
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                // 价格（如果有）
                if let priceText = item.priceText {
                    Text(priceText)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // 标签（如果有）
            if !item.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.gray.opacity(0.15))
                                )
                        }
                    }
                }
            }

            // 仓库和状态信息
            HStack(spacing: 8) {
                // 仓库名
                Text(item.warehouseName)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                // 状态图标
                Image(systemName: item.itemStatusIcon)
                    .font(.caption2)
                    .foregroundColor(item.itemStatusColor)

                // 最后使用时间
                if let lastUsedText = item.lastUsedText {
                    Text(lastUsedText)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            Color.gray.opacity(0.1)
                .cornerRadius(8)
        )
    }
}

/// 视图模型
@MainActor
class GoodsItemsViewModel: ObservableObject {
    let warehouse: GoodsWarehouse?
    @Published var items: [GoodsItem] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    init(warehouse: GoodsWarehouse?) {
        self.warehouse = warehouse
    }

    func loadData() async {
        isLoading = true
        error = nil

        do {
            let items = try await WCSessionManager.shared.getGoodsItems(warehouseId: warehouse?.id)
            self.items = items
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
