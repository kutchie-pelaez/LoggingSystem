// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "Logging",
    platforms: [
        .iOS("15")
    ],
    products: [
        .library(
            name: "LogsExtractor",
            targets: [
                "LogsExtractor"
            ]
        ),
        .library(
            name: "Logger",
            targets: [
                "Logger"
            ]
        )
    ],
    dependencies: [
        .package(name: "Core", url: "https://github.com/kutchie-pelaez-packages/Core.git", .branch("master")),
        .package(name: "DeviceKit", url: "https://github.com/kutchie-pelaez-packages/DeviceKit.git", .branch("master")),
        .package(name: "SessionManager", url: "https://github.com/kutchie-pelaez-packages/SessionManager.git", .branch("master")),
        .package(name: "Tweaks", url: "https://github.com/kutchie-pelaez-packages/Tweaks.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "LogsExtractor",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "DeviceKit", package: "DeviceKit")
            ]
        ),
        .target(
            name: "Logger",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "SessionManager", package: "SessionManager")
            ]
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "SessionManager", package: "SessionManager"),
                .product(name: "Tweak", package: "Tweaks"),
                .target(name: "Logger")
            ]
        )
    ]
)
