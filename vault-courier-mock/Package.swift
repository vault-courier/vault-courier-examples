// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vault-courier-mock",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/vault-courier/vault-courier", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client.git", from: "1.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "vault-courier-mock",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "VaultCourier", package: "vault-courier"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client")
            ]
        ),
    ]
)
