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

import Logging
import VaultCourier
import Vapor
import struct Foundation.URL
import OpenAPIAsyncHTTPClient

func connectToVault(
    logger: Logging.Logger
) async throws -> DatabaseConfig {
    guard let roleID = Environment.get("ROLE_ID"),
          let secretIdFilePath = Environment.get("SECRET_ID_FILEPATH")
    else { fatalError("❌ Missing credentials for Vault authentication.") }

    // Read the secretID provided by the broker
    let secretID = try String(contentsOf: URL(filePath: secretIdFilePath), encoding: .utf8)

        // Create vault client.
    let vaultConfiguration = VaultClient.Configuration(
        apiURL: try URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1"),
        backgroundActivityLogger: logger
    )


    let client = Client(
        serverURL: vaultConfiguration.apiURL,
        transport: AsyncHTTPClientTransport()
    )


    let vaultClient = VaultClient(
        configuration: vaultConfiguration,
        client: client,
        authentication: .appRole(
            credentials: .init(roleID: roleID, secretID: secretID),
            isWrapped: false
        )
    )

    // Authenticate with vault
    guard try await vaultClient.authenticate()
    else { fatalError("❌ The app could not log in to Vault. Open investigation 🕵️") }

    // Read database configuration
    let config = try await vaultClient.makeResourceReader(scheme: "vault")
        .readConfiguration(
            source: .url(.init(filePath: "todoConfig.stage.pkl").absoluteURL),
            as: TodoConfig.Module.self
        )

    return try config.databaseConfig
}
