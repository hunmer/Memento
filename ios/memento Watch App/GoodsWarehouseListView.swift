//
//  GoodsWarehouseListView.swift
//  memento_watchos Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

/// 仓库列表视图
struct GoodsWarehouseListView: View {
    @StateObject private var viewModel = GoodsWarehouseViewModel()

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
            } else if viewModel.warehouses.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "shippingbox")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("暂无仓库")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.warehouses) { warehouse in
                            NavigationLink(destination: GoodsItemsListView(
                                warehouse: warehouse,
                                title: warehouse.title
                            )) {
                                WarehouseRow(warehouse: warehouse)
                            }
                        }
                    }
                }
                .navigationTitle("仓库")
            }
        }
        .onAppear {
            Task { await viewModel.loadData() }
        }
    }
}

/// 仓库行组件
struct WarehouseRow: View {
    let warehouse: GoodsWarehouse

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(warehouse.warehouseColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: iconName(for: Int32(warehouse.icon)))
                    .font(.system(size: 18))
                    .foregroundColor(warehouse.warehouseColor)
            }

            // 标题和数量
            VStack(alignment: .leading, spacing: 4) {
                Text(warehouse.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("\(warehouse.itemCount)")
                    Text("件物品")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

/// 根据图标类型返回 SF Symbols 名称
private func iconName(for iconType: Int32) -> String {
    switch iconType {
    case 0: return "house.fill"
    case 1: return "building.2.fill"
    case 2: return "bag.fill"
    case 3: return "archivebox.fill"
    case 4: return "tray.fill"
    case 5: return "cabinet.fill"
    default: return "shippingbox.fill"
    }
}

/// 视图模型
@MainActor
class GoodsWarehouseViewModel: ObservableObject {
    @Published var warehouses: [GoodsWarehouse] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    func loadData() async {
        isLoading = true
        error = nil

        do {
            let warehouses = try await WCSessionManager.shared.getGoodsWarehouses()
            self.warehouses = warehouses
            isLoading = false
        } catch {
            let errorMessage = error.localizedDescription
            self.error = errorMessage
            isLoading = false
        }
    }
}
