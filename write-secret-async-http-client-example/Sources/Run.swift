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
import AsyncHTTPClient
import OpenAPIAsyncHTTPClient
import VaultCourier
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
#endif

@main
struct write_secret_async_http_client_example: AsyncParsableCommand {
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

    struct Secret: Codable {
        var apiKey: String
    }

    mutating func run() async throws {
        let vaultClient = try Self.makeVaultClient()
        try await vaultClient.authenticate()

        let secret = Secret(apiKey: "my_secret_api_key")

        do {
            guard let response = try await vaultClient.writeKeyValue(secret: secret, key: "dev-eu-central-1")
            else {
                fatalError("Unable to write secret. Please check your Vault configuration has the same root token")
            }

            print("""
                Secret written successfully!
                created_time: \(response.data.createdTime!)
                version: \(response.data.version!)
                """)
        } catch {
            print("Unable to write secret: " + String(reflecting: error))
        }
    }
}

