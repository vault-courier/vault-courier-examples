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

import ArgumentParser
import Logging
import OpenAPIAsyncHTTPClient
import VaultCourier
import Valkey

@main
struct valkey_example: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "valkey-example",
        abstract: "Example of managing Valkey secrets with Vault. Run After 'Provision' command.",
        subcommands: [
            Provision.self,
            App.self
        ]
    )
}

enum Constants {
    static let host = "valkey-cache"
    static let port = 6379
    static let role = "qa_role"
    static let enginePath = "database"
    static let keyName = "pokemon-count"
}

extension valkey_example {
    struct App: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Application using Valkey which increases a counter",
        )

        mutating func run() async throws {
            let logger = Logger(label: "App")
            // Create vault client
            let vaultClient = VaultClient(
                configuration: .defaultHttp(backgroundActivityLogger: logger),
                clientTransport: AsyncHTTPClientTransport()
            )
            // Authenticate with vault
            try await vaultClient.login(method: .token("education"))

            // Fetch credentials
            let credentials = try await vaultClient.databaseCredentials(dynamicRole: Constants.role, mountPath: Constants.enginePath)
            logger.info("Valkey credentials fetched successfully: \(credentials)")

            // Init Valkey client
            let valkeyClient = ValkeyClient(
                .hostname("localhost", port: Constants.port),
                configuration: .init(authentication: .init(username: credentials.username, password: credentials.password)),
                logger: logger
            )

            // Run the Valkey client and execute some operations
            try await withThrowingTaskGroup(of: Void.self) { taskGroup in
                taskGroup.addTask {
                    await valkeyClient.run() // !important
                }

                let key: ValkeyKey = .init(Constants.keyName)
                try await valkeyClient.incr(key)
                logger.info("\(key) created")
                try await valkeyClient.incrby(key, increment: 10)
                logger.info("\(key) increased by ten")
                try await valkeyClient.incrby(key, increment: 10)
                logger.info("\(key) increased by ten")
                let value = try await valkeyClient.get(key).map({ String(buffer: $0) })

                logger.info("\(key) = \(value, default: "0")")

                taskGroup.cancelAll()
            }
        }
    }
}

extension valkey_example {
    struct Provision: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Establish connection with Valkey and Vault, and creates a dynamic role. Run this first before 'App' command.",
        )

        var enginePath: String = "database"
        var connectionName: String = "valkey_connection"

        mutating func run() async throws {
            let logger = Logger(label: "VaultClient")
            // Create vault client
            let vaultClient = VaultClient(
                configuration: .defaultHttp(backgroundActivityLogger: logger),
                clientTransport: AsyncHTTPClientTransport()
            )
            // Authenticate with vault
            try await vaultClient.login(method: .token("education"))

            do {
                // Enable database secret engine
                try await vaultClient.enableSecretEngine(mountConfig: .init(mountType: "database", path: Constants.enginePath))
                logger.info("Database secret engine enabled at \(Constants.enginePath)")

                // Connect with Valkey
                try await vaultClient.withDatabaseClient(mountPath: Constants.enginePath) { client in
                    let config = Self.valkeyConnectionConfiguration(connectionName)
                    try await client.databaseConnection(configuration: config)
                    logger.info("""
                    Success! Data written to: \(enginePath)/config/\(connectionName)
                    """)

                    let connection = try await client.valkeyConnection(name: connectionName)
                    logger.info(.init(stringLiteral: """
                        connection details ---
                        \(connection.debugDescription)
                        ----------------------------------------------
                        """)
                    )
                    // Rotate root
                    try await client.rotateRoot(connection: connectionName)

                    try await client.create(dynamicRole: .valkey(.init(vaultRoleName: Constants.role,
                                                                       databaseConnectionName: connectionName,
                                                                       defaultTimeToLive: .seconds(60),
                                                                       creationStatements: [
                                                                        "+@read",
                                                                        "+@write",
                                                                        "~\(Constants.keyName)" // restrict which keys the user can access
                                                                       ])))
                    logger.info("""
                    Success! Dynamic role '\(Constants.role)' created.
                    """)
                }
            } catch {
                logger.error(.init(stringLiteral: "Unable to write secret: " + String(reflecting: error)))
            }
        }

        static func valkeyConnectionConfiguration(_ name: String) -> ValkeyConnectionConfig {
            let host = Constants.host
            let port = Constants.port
            let vaultUsername = "vault_user"
            let vaultPassword = "init_password"
            let config = ValkeyConnectionConfig(
                connection: name,
                allowedRoles: ["*"],
                host: host,
                port: UInt16(port),
                username: vaultUsername,
                password: vaultPassword,
                tls: nil,
                rootRotationStatements: ["+@all", "+@admin"]
            )
            return config
        }
    }
}

extension ValkeyConnectionResponse: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
                allowed_roles: \(allowedRoles)
                connection_host: \(host)
                connection_port: \(port)
                connection_username: \(username)
                rotate_statements: \(rotateStatements)
                plugin_name: \(plugin?.name ?? "<n/a>")
                """
    }
}
