import AppIntents
import intelligence

/// 快速记账 Intent
///
/// 支持 Siri 自然语言识别金额和分类
struct CreateBillIntent: AppIntent {
    static var title: LocalizedStringResource = "快速记账"
    static var description: IntentDescription = "快速记录一笔收入或支出"
    static var openAppWhenRun: Bool = true

    // 参数1: 类型（必填）
    @Parameter(
        title: "类型",
        description: "收入还是支出",
        default: BillType.expense
    )
    var type: BillType

    // 参数2: 金额（必填）
    @Parameter(
        title: "金额",
        description: "金额数值（正数）",
        requestValueDialog: "金额是多少?"
    )
    var amount: Double

    // 参数3: 分类（必填）
    @Parameter(
        title: "分类",
        description: "账单分类",
        default: BillCategory.other
    )
    var category: BillCategory

    // 参数4: 备注（可选）
    @Parameter(
        title: "备注",
        description: "账单的详细说明"
    )
    var description: String?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        print("[CreateBill] 开始记账")
        print("[CreateBill] 类型: \(type.rawValue)")
        print("[CreateBill] 金额: \(amount)")
        print("[CreateBill] 分类: \(category.displayName)")
        print("[CreateBill] 备注: \(description ?? "无")")

        // 根据类型调整金额符号
        let finalAmount = type == .expense ? -abs(amount) : abs(amount)

        // 构造参数对象
        var params: [String: Any] = [
            "type": type.rawValue,
            "amount": finalAmount,
            "category": category.displayName
        ]

        // 添加备注（如果有）
        if let desc = description, !desc.isEmpty {
            params["description"] = desc
        }

        // 构造发送到 Flutter 的数据
        let data: [String: Any] = [
            "action": "call_plugin_method",
            "pluginId": "bill",
            "methodName": "createBill",
            "params": params,
            "timestamp": Date().timeIntervalSince1970
        ]

        // 转换为 JSON 并发送
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            IntelligencePlugin.notifier.push(jsonString)
            print("[CreateBill] 已发送数据到 Flutter: \(jsonString)")

            // 返回成功消息
            let typeText = type == .expense ? "支出" : "收入"
            let resultMessage = "已记录\(typeText) \(abs(finalAmount))元 - \(category.displayName)"
            return .result(value: resultMessage)
        } else {
            print("[CreateBill] JSON 序列化失败")
            throw IntentError.message("记账失败")
        }
    }

    static var parameterSummary: some ParameterSummary {
        Summary("记账 \(\.$amount) 元") {
            \.$type
            \.$category
            \.$description
        }
    }
}

/// 账单类型枚举
enum BillType: String, AppEnum {
    case income = "income"
    case expense = "expense"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "类型")
    }

    static var caseDisplayRepresentations: [BillType: DisplayRepresentation] {
        [
            .income: DisplayRepresentation(title: "收入", subtitle: "赚到的钱 💰"),
            .expense: DisplayRepresentation(title: "支出", subtitle: "花出去的钱 💸")
        ]
    }
}

/// 账单分类枚举
enum BillCategory: String, AppEnum {
    case food = "food"
    case transport = "transport"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case salary = "salary"
    case other = "other"

    var displayName: String {
        switch self {
        case .food: return "餐饮"
        case .transport: return "交通"
        case .shopping: return "购物"
        case .entertainment: return "娱乐"
        case .salary: return "工资"
        case .other: return "其他"
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "分类")
    }

    static var caseDisplayRepresentations: [BillCategory: DisplayRepresentation] {
        [
            .food: DisplayRepresentation(title: "餐饮", subtitle: "吃饭、零食、饮料 🍔"),
            .transport: DisplayRepresentation(title: "交通", subtitle: "打车、地铁、公交 🚗"),
            .shopping: DisplayRepresentation(title: "购物", subtitle: "衣服、日用品 🛒"),
            .entertainment: DisplayRepresentation(title: "娱乐", subtitle: "电影、游戏、旅游 🎮"),
            .salary: DisplayRepresentation(title: "工资", subtitle: "月度工资、奖金 💼"),
            .other: DisplayRepresentation(title: "其他", subtitle: "其他类型 📝")
        ]
    }
}
