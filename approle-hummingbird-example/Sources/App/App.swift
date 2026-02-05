//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird project
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import Hummingbird
import Logging

@main
struct App: AsyncParsableCommand, AppArguments {
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    @Option(name: .shortAndLong)
    var logLevel: Logger.Level?

    @Flag
    var inMemoryTesting: Bool = false

    func run() async throws {
        let app = try await buildApplication(self)
        try await app.runService()
    }
}

/// Extend `Logger.Level` so it can be used as an argument
extension Logger.Level: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        guard let value = Self(rawValue: argument) else {
            return nil
        }
        self = value
    }
}
