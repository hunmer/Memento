//
//
//  HabitsListView: View {
    @StateObject private var viewModel = HabitsListViewModel()

 @Published var habits: [HabitItem] = []
    @Published var isLoading = false
    @Published var error: String?

    private var isExpanded = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        Task { await viewModel.loadData() }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.habits.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("暂无习惯")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("请在手机上添加习惯")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.habits) { habit in
                            HabitItemRow(habit: habit)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("习惯")
        .task { await viewModel.loadData() }
    }
}

}

