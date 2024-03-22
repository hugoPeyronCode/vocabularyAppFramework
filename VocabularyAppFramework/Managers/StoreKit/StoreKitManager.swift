//
//  StoreKitManager.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 29/09/2023.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
class StoreKitManager : ObservableObject {
    
    private let productIds = ["Yearly","weekly","lifetime"] // Here I'll add all the id of the products I create in the store and can find the StoreKit fill in XCode.
    
    @Published private(set) var products : [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    @Published var isLoading: Bool = false
    
    private var productsLoaded = false
    
    private var updates: Task<Void, Never>? = nil
    
    init() {
        self.updates = observeTransactionUpdates()
        print("purchasedProductIDs.count => \(purchasedProductIDs.count)")
    }
    
    deinit {
        self.updates?.cancel()
    }
    
    var hasUnlockedPremium: Bool {
//        print("has unlocked Premium")
//        return !self.purchasedProductIDs.isEmpty
        return true
    }
    
    func loadProducts() async throws {
        // If products already loaded do nothing
        guard !self.productsLoaded else { return }
        // Fill the products array of products with the product using the storeKit Api call.
        self.products = try await Product.products(for: productIds)
        self.productsLoaded = true
    }
    
    func purchase(_ product: Product) async throws {
        // Save the state of the purchase in a the isLoading variable
        self.isLoading = true
               defer { self.isLoading = false } // Ensure isLoading is set to false when the purchase is completed, even if an error occurs
        
        // Save the result of the purchase in a variable
        let result = try await product.purchase()
        
        
        switch result {
        case let .success(.verified(transaction)):
            // Successful purchase
            print("Successful purchase")
            await self.updatePurchasedProducts()
            await transaction.finish()
        case .success(.unverified(_, _)):
            // Successful purchase but transaction / receipt can't be verified
            // Could be a jailbroken phone. A cheat.
            print("Unverified purchase")
            break
            
        case .pending:
            print("transation is pending ")
            break
            
        case .userCancelled:
            print("User cancelled")
            break
        @unknown default:
            break
        }
    }
    
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await _ in Transaction.updates {
                // _ to replace -> verificationResult directly would be better
                await self.updatePurchasedProducts()
            }
        }
    }
}

