import Foundation
import Network
import SwiftUI

/// Manager for monitoring network connectivity status
@MainActor
class NetworkStatusManager: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isExpensive = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
}

