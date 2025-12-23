import AppIntents
import intelligence

struct ConversationQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ConversationEntity] {
        return IntelligencePlugin.storage.get(for: identifiers).map { item in
            return ConversationEntity(
                id: item.id,
                title: item.representation
            )
        }
    }

    func suggestedEntities() async throws -> [ConversationEntity] {
        return IntelligencePlugin.storage.get().map { item in
            return ConversationEntity(
                id: item.id,
                title: item.representation
            )
        }
    }
}

extension ConversationQuery: EnumerableEntityQuery {
    func allEntities() async throws -> [ConversationEntity] {
        return IntelligencePlugin.storage.get().map { item in
            return ConversationEntity(
                id: item.id,
                title: item.representation
            )
        }
    }
}
