//
//  StoreListView.swift
//  memento Watch App
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import Combine

// MARK: - 商店主视图（带 Tabs）

struct StoreListView: View {
    @StateObject private var viewModel = StoreListViewModel()
    @State private var selectedTab = 0

    // 主色调
    private let primaryColor = Color(red: 236/255, green: 91/255, blue: 19/255)  // #ec5b13

    var body: some View {
        TabView(selection: $selectedTab) {
            // 商品列表 Tab
            ProductListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "storefront")
                    Text("商品")
                }
                .tag(0)

            // 我的物品 Tab
            UserItemsListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "gift")
                    Text("我的")
                }
                .tag(1)
        }
        .tabViewStyle(.verticalPage)
        .navigationTitle("Store")
        .task {
            await viewModel.loadAllData()
        }
    }
}

// MARK: - 商品列表视图

struct ProductListView: View {
    @ObservedObject var viewModel: StoreListViewModel

    private let primaryColor = Color(red: 236/255, green: 91/255, blue: 19/255)
    private let backgroundColor = Color(red: 10/255, green: 7/255, blue: 5/255)

    var body: some View {
        Group {
            if viewModel.isLoadingProducts {
                ProgressView("加载中...")
            } else if let error = viewModel.productsError {
                ErrorView(error: error) {
                    Task { await viewModel.loadProducts() }
                }
            } else if viewModel.products.isEmpty {
                EmptyStateView(
                    icon: "storefront",
                    title: "暂无商品",
                    subtitle: "在 iPhone 上添加商品后会同步到这里"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.products) { product in
                            ProductItemRow(product: product)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
                }
                .refreshable {
                    await viewModel.loadProducts()
                }
            }
        }
    }
}

// MARK: - 用户物品列表视图

struct UserItemsListView: View {
    @ObservedObject var viewModel: StoreListViewModel

    private let primaryColor = Color(red: 236/255, green: 91/255, blue: 19/255)
    private let backgroundColor = Color(red: 10/255, green: 7/255, blue: 5/255)

    var body: some View {
        Group {
            if viewModel.isLoadingItems {
                ProgressView("加载中...")
            } else if let error = viewModel.itemsError {
                ErrorView(error: error) {
                    Task { await viewModel.loadUserItems() }
                }
            } else if viewModel.userItems.isEmpty {
                EmptyStateView(
                    icon: "gift",
                    title: "暂无物品",
                    subtitle: "兑换商品后会显示在这里"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.userItems) { item in
                            UserItemRow(item: item)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
                }
                .refreshable {
                    await viewModel.loadUserItems()
                }
            }
        }
    }
}

// MARK: - 商品项视图

struct ProductItemRow: View {
    let product: StoreProduct

    private let primaryColor = Color(red: 236/255, green: 91/255, blue: 19/255)
    private let backgroundColor = Color(red: 10/255, green: 7/255, blue: 5/255)
    private let unavailableColor = Color.gray

    var body: some View {
        HStack(spacing: 10) {
            // 图标容器
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(product.isAvailable ? primaryColor.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: "gift")
                    .font(.system(size: 18))
                    .foregroundStyle(product.isAvailable ? primaryColor : unavailableColor)
            }

            // 商品信息
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(product.isAvailable ? .white : .gray)
                    .lineLimit(1)

                if let description = product.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 价格和库存
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                    Text("\(product.price)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(product.isAvailable ? .yellow : .gray)
                }

                Text(product.stockStatus)
                    .font(.system(size: 8))
                    .foregroundStyle(product.stock > 0 ? .secondary : .red)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(product.isAvailable ? primaryColor.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: product.isAvailable ? primaryColor.opacity(0.1) : Color.clear, radius: 3, x: 0, y: 0)
        )
    }
}

// MARK: - 用户物品视图

struct UserItemRow: View {
    let item: UserItemGroup

    private let primaryColor = Color(red: 236/255, green: 91/255, blue: 19/255)
    private let backgroundColor = Color(red: 10/255, green: 7/255, blue: 5/255)

    var body: some View {
        HStack(spacing: 10) {
            // 图标容器
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.isExpired ? Color.red.opacity(0.15) : item.statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "gift.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(item.isExpired ? .red : item.statusColor)
            }

            // 物品信息
            VStack(alignment: .leading, spacing: 2) {
                Text(item.productName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(item.isExpired ? .gray : .white)
                    .lineLimit(1)

                Text(item.expiryStatus)
                    .font(.system(size: 9))
                    .foregroundStyle(item.statusColor)
            }

            Spacer()

            // 数量和原价
            VStack(alignment: .trailing, spacing: 2) {
                Text("x\(item.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(item.isExpired ? .gray : .white)

                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(.yellow)
                    Text("\(item.purchasePrice)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(item.isExpired ? Color.red.opacity(0.3) : primaryColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: item.isExpired ? Color.red.opacity(0.1) : primaryColor.opacity(0.1), radius: 3, x: 0, y: 0)
        )
    }
}

// MARK: - 辅助视图

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ErrorView: View {
    let error: String
    let retryAction: () -> Void

    var body: some View {
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
            Button("重试", action: retryAction)
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - ViewModel

@MainActor
class StoreListViewModel: ObservableObject {
    @Published var products: [StoreProduct] = []
    @Published var userItems: [UserItemGroup] = []
    @Published var isLoadingProducts = false
    @Published var isLoadingItems = false
    @Published var productsError: String?
    @Published var itemsError: String?

    func loadAllData() async {
        async let productsTask = loadProducts()
        async let itemsTask = loadUserItems()
        _ = await (productsTask, itemsTask)
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }

        isLoadingProducts = true
        productsError = nil

        do {
            products = try await WCSessionManager.shared.getStoreProducts()
        } catch {
            productsError = error.localizedDescription
        }

        isLoadingProducts = false
    }

    func loadUserItems() async {
        guard !isLoadingItems else { return }

        isLoadingItems = true
        itemsError = nil

        do {
            userItems = try await WCSessionManager.shared.getUserItems()
        } catch {
            itemsError = error.localizedDescription
        }

        isLoadingItems = false
    }
}

#Preview {
    NavigationView {
        StoreListView()
    }
}
