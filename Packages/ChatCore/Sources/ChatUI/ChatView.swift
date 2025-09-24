import SwiftUI
import ChatDomain
import ChatPresentation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct ChatView: View {
    @ObservedObject var vm: ChatViewModel
    let currentUserId: String

    public init(viewModel: ChatViewModel, currentUserId: String) {
        self.vm = viewModel
        self.currentUserId = currentUserId
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(vm.messages) { msg in
                            MessageRow(message: msg, isOutgoing: msg.senderId == currentUserId)
                                .id(msg.id)
                        }
                    }
                }
                .onChange(of: vm.messages.map { $0.id }) { _ in
                    if let last = vm.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }
            Divider()
            HStack {
                TextField("Message", text: $vm.draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button {
                    Task { await vm.send() }
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(vm.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Self.composerBackgroundColor)
        }
        .onAppear { vm.start() }
    }
}

private extension ChatView {
    static var composerBackgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
}
