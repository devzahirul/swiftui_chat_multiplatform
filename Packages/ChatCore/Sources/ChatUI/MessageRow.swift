import SwiftUI
import ChatDomain

public struct MessageRow: View {
    let message: Message
    let isOutgoing: Bool

    public init(message: Message, isOutgoing: Bool) {
        self.message = message
        self.isOutgoing = isOutgoing
    }

    public var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 40) }
            Text(message.text ?? "")
                .padding(10)
                .background(isOutgoing ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 400, alignment: isOutgoing ? .trailing : .leading)
            if !isOutgoing { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
    }
}
