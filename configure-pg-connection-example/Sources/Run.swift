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
import OpenAPIAsyncHTTPClient
import VaultCourier
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

@main
struct configure_pg_connection_example: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var enginePath: String = "database"

    @Option(name: .shortAndLong)
    var connectionName: String = "pg_connection"

    mutating func run() async throws {
        let vaultClient = try Self.makeVaultClient()
        try await vaultClient.authenticate()

        do {
            try await vaultClient.enableSecretEngine(mountConfig: .init(mountType: "database", path: enginePath))
            print("Database secret engine enabled at \(enginePath)")

            let config = Self.postgresConnectionConfiguration(connectionName)
            try await vaultClient.databaseConnection(configuration: config, enginePath: enginePath)
            print("""
            Success! Data written to: \(enginePath)/config/\(connectionName)
            """)

            let connection = try await vaultClient.databaseConnection(name: connectionName, enginePath: enginePath)
            print(connection)
        } catch {
            print("Unable to write secret: " + String(reflecting: error))
        }
    }

    static func makeVaultClient() throws -> VaultClient {
        let vaultURL = URL(string: "http://127.0.0.1:8200/v1")!
        let config = VaultClient.Configuration(apiURL: vaultURL)

        let client = Client(
            serverURL: vaultURL,
            transport: AsyncHTTPClientTransport()
        )

        return VaultClient(
            configuration: config,
            client: client,
            authentication: .token("education")
        )
    }

    static func postgresConnectionConfiguration(_ name: String) -> PostgresConnectionConfiguration {
        let host = "127.0.0.1"
        let port = 5432
        let databaseName = "postgres"
        let sslMode = "disable"
        let connectionURL = "postgresql://{{username}}:{{password}}@\(host):\(port)/\(databaseName)?sslmode=\(sslMode)"
        let vaultUsername = "vault_root"
        let vaultPassword = "root_password"
        let config = PostgresConnectionConfiguration(connection: name,
                                                     pluginName: "postgresql-database-plugin",
                                                     allowedRoles: ["dynamic_role", "static_role"],
                                                     connectionUrl: connectionURL,
                                                     username: vaultUsername,
                                                     password: vaultPassword,
                                                     passwordAuthentication: .scramSHA256)
        return config
    }
}

extension DatabaseConnectionResponse: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
                allowed_roles: \(allowedRoles)
                connection_url: \(connectionURL?.debugDescription.removingPercentEncoding ?? "<n/a>")
                connection_username: \(username)
                password_authentication: \(authMethod.flatMap({$0.rawValue}) ?? "unknown")
                plugin_name: \(plugin?.name ?? "<n/a>")
                """
    }
}
