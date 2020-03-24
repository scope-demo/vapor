// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "vapor",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Vapor", targets: ["Vapor"]),
        .library(name: "XCTVapor", targets: ["XCTVapor"])
    ],
    dependencies: [
        // HTTP client library built on SwiftNIO
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
    
        // Sugary extensions for the SwiftNIO library
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0-rc.1"),

        // 💻 APIs for creating interactive CLI tools.
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.0.0-rc.1"),

        // 🔑 Hashing (BCrypt, SHA2, HMAC), encryption (AES), public-key (RSA), and random data generation.
        .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0"),

        // 🚍 High-performance trie-node router.
        .package(url: "https://github.com/vapor/routing-kit.git", from: "4.0.0-rc.1"),

        // 💥 Backtraces for Swift on Linux
        .package(url: "https://github.com/swift-server/swift-backtrace.git", from: "1.1.1"),
        
        // Event-driven network application framework for high performance protocol servers & clients, non-blocking.
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.13.1"),
        
        // Bindings to OpenSSL-compatible libraries for TLS support in SwiftNIO
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.4.1"),
        
        // HTTP/2 support for SwiftNIO
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.11.0"),
        
        // Useful code around SwiftNIO.
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
        
        // Swift logging API
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),

        // Swift metrics API
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.0.0"),

        // WebSocket client library built on SwiftNIO
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.0.0-rc.1"),
    ],
    targets: [
        // C helpers
        .target(name: "CBase32"),
        .target(name: "CBcrypt"),
        .target(name: "CMultipartParser"),
        .target(name: "COperatingSystem"),
        .target(name: "CURLParser"),

        // Vapor
        .target(name: "Vapor", dependencies: [
            .product(name: "AsyncHTTPClient", package: "async-http-client"),
            .product(name: "AsyncKit", package: "async-kit"),
            .product(name: "Backtrace", package: "swift-backtrace"),
            .target(name: "CBase32"),
            .target(name: "CBcrypt"),
            .target(name: "CMultipartParser"),
            .target(name: "COperatingSystem"),
            .target(name: "CURLParser"),
            .product(name: "ConsoleKit", package: "console-kit"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "Metrics", package: "swift-metrics"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOExtras", package: "swift-nio-extras"),
            .product(name: "NIOFoundationCompat", package: "swift-nio"),
            .product(name: "NIOHTTPCompression", package: "swift-nio-extras"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
            .product(name: "NIOHTTP2", package: "swift-nio-http2"),
            .product(name: "NIOSSL", package: "swift-nio-ssl"),
            .product(name: "NIOWebSocket", package: "swift-nio"),
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "RoutingKit", package: "routing-kit"),
            .product(name: "WebSocketKit", package: "websocket-kit"),
        ]),

        // Development
        .target(name: "Development", dependencies: [
            .target(name: "Vapor"),
        ]),

        // Testing
        .target(name: "XCTVapor", dependencies: [
            .target(name: "Vapor"),
        ]),
        .testTarget(name: "VaporTests", dependencies: [
            .product(name: "NIOTestUtils", package: "swift-nio"),
            .target(name: "XCTVapor"),
        ]),
    ]
)
