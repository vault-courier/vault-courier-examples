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
struct create_static_role_example: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var enginePath: String = "database"

    @Option(name: .shortAndLong)
    var connectionName: String = "pg_connection"

    var roleName: String = "static_role"

    mutating func run() async throws {
        let vaultClient = try Self.makeVaultClient()
        try await vaultClient.authenticate()

        try await vaultClient.create(staticRole: .init(vaultRoleName: roleName,
                                                       databaseUsername: "static_role_username",
                                                       databaseConnectionName: connectionName,
                                                       rotation: .period(.seconds(60*60*24))),
                                     enginePath: enginePath)

        let response = try await vaultClient.databaseCredentials(staticRole: roleName, enginePath: enginePath)
        print("""
        lease_renewable    \(response?.renewable ?? false)
        password           \(response?.password ?? "")
        username           \(response?.username ?? "")    
        rotation           \(String(describing: response?.rotation))
        """)
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
}

