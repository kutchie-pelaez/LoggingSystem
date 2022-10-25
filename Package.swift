// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "LoggingManager",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "LogsExtractor", targets: ["LogsExtractor"]),
        .library(name: "LogsExtractorImpl", targets: ["LogsExtractorImpl"]),
        .library(name: "LoggingManager", targets: ["LoggingManager"]),
        .library(name: "LoggingManagerImpl", targets: ["LoggingManagerImpl"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/kutchie-pelaez-packages/Core.git", branch: "master"),
        .package(url: "https://github.com/kutchie-pelaez-packages/SessionManager.git", branch: "master")
    ],
    targets: [
        .target(name: "LogCoding"),
        .target(name: "LogsExtractor"),
        .target(name: "LogsExtractorImpl", dependencies: [
            .target(name: "LogCoding"),
            .target(name: "LogsExtractor")
        ]),
        .target(name: "LoggingManager", dependencies: [
            .product(name: "CoreUtils", package: "Core")
        ]),
        .target(name: "LoggingManagerImpl", dependencies: [
            .product(name: "Core", package: "Core"),
            .product(name: "CoreUtils", package: "Core"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "SessionManager", package: "SessionManager"),
            .target(name: "LogCoding"),
            .target(name: "LoggingManager")
        ])
    ]
)
