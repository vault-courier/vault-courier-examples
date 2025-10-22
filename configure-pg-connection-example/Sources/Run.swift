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

@main
struct configure_pg_connection_example: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var enginePath: String = "database"

    @Option(name: .shortAndLong)
    var connectionName: String = "pg_connection"

    mutating func run() async throws {
        // Create vault client.
        let vaultClient = VaultClient(
            configuration: .defaultHttp(),
            clientTransport: AsyncHTTPClientTransport()
        )
        // Authenticate with vault
        do {
            try await vaultClient.login(method: .token("education"))
        }
        catch {
            fatalError("❌ The app could not log in to Vault. Open investigation 🕵️")
        }

        do {
            try await vaultClient.enableSecretEngine(mountConfig: .init(mountType: "database", path: enginePath))
            print("Database secret engine enabled at \(enginePath)")

            let config = Self.postgresConnectionConfiguration(connectionName)
            try await vaultClient.createPostgresConnection(configuration: config, mountPath: enginePath)
            print("""
            Success! Data written to: \(enginePath)/config/\(connectionName)
            """)

            let connection = try await vaultClient.postgresConnection(name: connectionName, mountPath: enginePath)
            print(connection)
        } catch {
            print("Unable to write secret: " + String(reflecting: error))
        }
    }

    static func postgresConnectionConfiguration(_ name: String) -> PostgresConnectionConfig {
        let host = "127.0.0.1"
        let port = 5432
        let databaseName = "postgres"
        let sslMode = "disable"
        let connectionURL = "postgresql://{{username}}:{{password}}@\(host):\(port)/\(databaseName)?sslmode=\(sslMode)"
        let vaultUsername = "vault_root"
        let vaultPassword = "root_password"
        let config = PostgresConnectionConfig(connection: name,
                                              allowedRoles: ["dynamic_role", "static_role"],
                                              connectionUrl: connectionURL,
                                              username: vaultUsername,
                                              password: vaultPassword,
                                              passwordAuthentication: .scramSHA256)
        return config
    }
}

extension PostgresConnectionResponse: @retroactive CustomDebugStringConvertible {
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
