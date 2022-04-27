// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "Logging",
    platforms: [
        .iOS("15")
    ],
    products: [
        .library(
            name: "LoggerImpl",
            targets: [
                "LoggerImpl"
            ]
        ),
        .library(
            name: "Logger",
            targets: [
                "Logger"
            ]
        ),
        .library(
            name: "LogsExtractor",
            targets: [
                "LogsExtractor"
            ]
        )
    ],
    dependencies: [
        .package(name: "Core", url: "https://github.com/kutchie-pelaez-packages/Core.git", .branch("master")),
        .package(name: "DeviceKit", url: "https://github.com/kutchie-pelaez-packages/DeviceKit.git", .branch("master")),
        .package(name: "SessionManager", url: "https://github.com/kutchie-pelaez-packages/SessionManager.git", .branch("master")),
        .package(name: "Tweaking", url: "https://github.com/kutchie-pelaez-packages/Tweaking.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "LoggerImpl",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "SessionManager", package: "SessionManager"),
                .target(name: "Logger")
            ]
        ),
        .target(
            name: "Logger",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "SessionManager", package: "SessionManager")
            ]
        ),
        .target(
            name: "LogsExtractor",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "DeviceKit", package: "DeviceKit")
            ]
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "SessionManager", package: "SessionManager"),
                .product(name: "Tweaking", package: "Tweaking"),
                .target(name: "Logger"),
                .target(name: "LoggerImpl")
            ]
        )
    ]
)
