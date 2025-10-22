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
        // Create vault client.
        let vaultClient = VaultClient(
            configuration: .defaultHttp(),
            clientTransport: AsyncHTTPClientTransport()
        )
        try await vaultClient.login(method: .token("education"))

        try await vaultClient.create(
            staticRole: .postgres(
                .init(vaultRoleName: roleName,
                      databaseUsername: "static_role_username",
                      databaseConnectionName: connectionName,
                      rotation: .period(.seconds(60*60*24)))
            ),
            mountPath: enginePath
        )

        let response = try await vaultClient.databaseCredentials(staticRole: roleName,
                                                                 mountPath: enginePath)
        print("""
        time_to_live       \(response.timeToLive)
        password           \(response.password)
        username           \(response.username)    
        rotation           \(String(describing: response.rotation))
        """)
    }
}

