//
//  IAPManager.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 28/09/2023.
//

import Foundation
import StoreKit


// Password of SandBox user: 4zm$5ENsKPcgMztS

class IAPManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, ObservableObject {
    static let shared = IAPManager()
    var products: [SKProduct] = []
        
    func fetchProducts() {
        let productIDs: Set<String> = ["Yearly"]
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        print("product: \(products)")
    }
}

extension IAPManager {
    func purchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        print("paid: \(payment)")
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
        print("restored purchase")
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Handle purchased state
                // Don't forget to finish the transaction
                PremiumStatus.shared.hasPremiumAccess = true
                SKPaymentQueue.default().finishTransaction(transaction)
                print("purchase validated")
                
            case .failed:
                // Handle failed state and maybe provide feedback to the user
                // Don't forget to finish transactions that fail
                SKPaymentQueue.default().finishTransaction(transaction)
                print("purchase failed")
                
            case .restored:
                // Handle restored state
                // Don't forget to finish the transaction
                SKPaymentQueue.default().finishTransaction(transaction)
                print("purchased restored")
                
            case .deferred, .purchasing:
                // You might not need to do anything for deferred and purchasing states
                break
                
            @unknown default:
                // Handle any future cases
                break
            }
        }
    }
}
