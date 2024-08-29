import SwiftUI

struct ChatWithPurchaseView: View {
    @ObservedObject var chatModel: ChatModel
    @ObservedObject var purchaseModel: PurchaseModel

    var body: some View {
        Text("Chat with Purchase View")
    }
}