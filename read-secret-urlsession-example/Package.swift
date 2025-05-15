// swift-tools-version: 6.1
//===----------------------------------------------------------------------===//
//  Copyright (c) 2025 Javier Cuesta
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
    name: "read-secret-urlsession-example",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/vault-courier/vault-courier", from: "0.0.2"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "read-secret-urlsession-example",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "VaultCourier", package: "vault-courier"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession")
            ]
        ),
    ]
)
