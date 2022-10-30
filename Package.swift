// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "LoggingManager",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "LogsViewer", targets: ["LogsViewer"]),
        .library(name: "LogsExtractor", targets: ["LogsExtractor"]),
        .library(name: "LogsExtractorImpl", targets: ["LogsExtractorImpl"]),
        .library(name: "LoggingManager", targets: ["LoggingManager"]),
        .library(name: "LoggingManagerImpl", targets: ["LoggingManagerImpl"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/kutchie-pelaez-packages/AlertBuilder.git", branch: "master"),
        .package(url: "https://github.com/kutchie-pelaez-packages/Builder.git", branch: "master"),
        .package(url: "https://github.com/kutchie-pelaez-packages/Core.git", branch: "master"),
        .package(url: "https://github.com/kutchie-pelaez-packages/SessionManager.git", branch: "master"),
        .package(url: "https://github.com/kutchie-pelaez-packages/Version.git", branch: "master")
    ],
    targets: [
        .target(name: "LogEntryEncryption", dependencies: [
            .product(name: "CoreUtils", package: "Core"),
            .product(name: "Logging", package: "swift-log")
        ]),
        .target(name: "LogsViewer", dependencies: [
            .product(name: "AlertBuilder", package: "AlertBuilder"),
            .product(name: "Builder", package: "Builder"),
            .product(name: "Core", package: "Core"),
            .product(name: "CoreUI", package: "Core"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "Version", package: "Version"),
            .target(name: "LogEntryEncryption")
        ]),
        .target(name: "LogsExtractor"),
        .target(name: "LogsExtractorImpl", dependencies: [
            .product(name: "Core", package: "Core"),
            .product(name: "CoreUtils", package: "Core"),
            .target(name: "LogEntryEncryption"),
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
            .product(name: "Version", package: "Version"),
            .target(name: "LogEntryEncryption"),
            .target(name: "LoggingManager")
        ])
    ]
)
