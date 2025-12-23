import AppIntents
import CoreSpotlight

struct ConversationEntity: AppEntity {
    static var defaultQuery: ConversationQuery = ConversationQuery()
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "AI聊天频道")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    let id: String
    let title: String

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

extension ConversationEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.displayName = self.title
        return attributes
    }
}
