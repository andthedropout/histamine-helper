import Foundation
import StoreKit

class PurchaseModel: ObservableObject {
    
    @Published var productIds: [String]
    @Published var productDetails: [PurchaseProductDetails] = []

    @Published var isSubscribed: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var isFetchingProducts: Bool = false
    
    init() {
        // Initialize your product IDs and product details
        self.productIds = ["your_weekly_product_id", "your_annual_product_id"]
        self.productDetails = [
            PurchaseProductDetails(price: "$4.99", productId: "your_weekly_product_id", duration: "week", durationPlanName: "Weekly Plan", hasTrial: false),
            PurchaseProductDetails(price: "$49.99", productId: "your_annual_product_id", duration: "year", durationPlanName: "Annual Plan", hasTrial: true)
        ]
    }
    
    func purchaseSubscription(productId: String) {
        // Implement your purchase logic here
        print("Purchasing subscription with ID: \(productId)")
    }
    
    func restorePurchases() {
        // Implement your restore purchases logic here
        print("Restoring purchases")
    }
}

class PurchaseProductDetails: ObservableObject, Identifiable {
    let id: UUID
    
    @Published var price: String
    @Published var productId: String
    @Published var duration: String
    @Published var durationPlanName: String
    @Published var hasTrial: Bool
    
    init(price: String = "", productId: String = "", duration: String = "", durationPlanName: String = "", hasTrial: Bool = false) {
        self.id = UUID()
        self.price = price
        self.productId = productId
        self.duration = duration
        self.durationPlanName = durationPlanName
        self.hasTrial = hasTrial
    }
}