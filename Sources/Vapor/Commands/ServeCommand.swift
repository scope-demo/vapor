/// Boots the application's server. Listens for `SIGINT` and `SIGTERM` for graceful shutdown.
///
///     $ swift run Run serve
///     Server starting on http://localhost:8080
///
public final class ServeCommand: Command {
    public struct Signature: CommandSignature {
        @Option(name: "hostname", short: "H", help: "Set the hostname the server will run on.")
        var hostname: String?
        
        @Option(name: "port", short: "p", help: "Set the port the server will run on.")
        var port: Int?
        
        @Option(name: "bind", short: "b", help: "Convenience for setting hostname and port together.")
        var bind: String?

        public init() { }
    }

    /// See `Command`.
    public let signature = Signature()

    /// See `Command`.
    public var help: String {
        return "Begins serving the app over HTTP."
    }

    private var signalSources: [DispatchSourceSignal]
    private var didShutdown: Bool
    private var server: Server?
    private var running: Application.Running?

    /// Create a new `ServeCommand`.
    init() {
        self.signalSources = []
        self.didShutdown = false
    }

    /// See `Command`.
    public func run(using context: CommandContext, signature: Signature) throws {
        let hostname = signature.hostname
            // 0.0.0.0:8080, 0.0.0.0, parse hostname
            ?? signature.bind?.split(separator: ":").first.flatMap(String.init)
        let port = signature.port
            // 0.0.0.0:8080, :8080, parse port
            ?? signature.bind?.split(separator: ":").last.flatMap(String.init).flatMap(Int.init)

        try context.application.server.start(hostname: hostname, port: port)
        self.server = context.application.server

        // allow the server to be stopped or waited for
        let promise = context.application.eventLoopGroup.next().makePromise(of: Void.self)
        context.application.running = .start(using: promise)
        self.running = context.application.running

        // setup signal sources for shutdown
        let signalQueue = DispatchQueue(label: "codes.vapor.server.shutdown")
        func makeSignalSource(_ code: Int32) {
            let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
            source.setEventHandler {
                print() // clear ^C
                promise.succeed(())
            }
            source.resume()
            self.signalSources.append(source)
            signal(code, SIG_IGN)
        }
        makeSignalSource(SIGTERM)
        makeSignalSource(SIGINT)
    }

    func shutdown() {
        self.didShutdown = true
        self.running?.stop()
        if let server = self.server {
            server.shutdown()
        }
        self.signalSources.forEach { $0.cancel() } // clear refs
        self.signalSources = []
    }
    
    deinit {
        assert(self.didShutdown, "ServeCommand did not shutdown before deinit")
    }
}
