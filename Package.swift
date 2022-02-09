// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "Logging",
    platforms: [
        .iOS("15")
    ],
    products: [
        .library(
            name: "LogsComposer",
            targets: [
                "LogsComposer"
            ]
        ),
        .library(
            name: "Logger",
            targets: [
                "Logger"
            ]
        ),
        .library(
            name: "Logs",
            targets: [
                "Logs"
            ]
        )
    ],
    dependencies: [
        .package(name: "Core", url: "https://github.com/kutchie-pelaez-packages/Core.git", .branch("master")),
        .package(name: "Yams", url: "https://github.com/jpsim/Yams.git", from: "4.0.6")
    ],
    targets: [
        .target(
            name: "LogsComposer",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .target(name: "Logs")
            ]
        ),
        .target(
            name: "Logger",
            dependencies: [
                .product(name: "Core", package: "Core")
            ]
        ),
        .target(
            name: "Logs",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Yams", package: "Yams")
            ]
        ),
    ]
)
