import Network
import Observation

@Observable
@MainActor
final class NetworkMonitor {
    private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.resortpass.netmonitor", qos: .utility)

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.isConnected = connected
            }
        }
        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }
}
