import Foundation
import Synchronization

/// Résultat d'une opération système (StoreKit) attendue au plus `seconds` secondes, sinon `nil`.
/// Sur un appareil, `AppTransaction.shared` ou `Transaction.currentEntitlements` peuvent ne jamais répondre
/// (compte App Store, réseau) : le lancement ne doit pas en dépendre. L'opération continue en arrière-plan.
func value<T: Sendable>(within seconds: Double, of operation: @escaping @Sendable () async -> T) async -> T? {
    await withCheckedContinuation { (continuation: CheckedContinuation<T?, Never>) in
        let gate = ResumeOnce(continuation)
        Task { gate.resume(await operation()) }
        Task {
            try? await Task.sleep(for: .seconds(seconds))
            gate.resume(nil)
        }
    }
}

/// La première réponse (opération ou délai) reprend la continuation ; la seconde est ignorée.
private final class ResumeOnce<T: Sendable>: Sendable {
    private let continuation: Mutex<CheckedContinuation<T?, Never>?>

    init(_ continuation: CheckedContinuation<T?, Never>) {
        self.continuation = Mutex(continuation)
    }

    func resume(_ value: T?) {
        let pending = continuation.withLock { stored in
            defer { stored = nil }
            return stored
        }
        pending?.resume(returning: value)
    }
}
