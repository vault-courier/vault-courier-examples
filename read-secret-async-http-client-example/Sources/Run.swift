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
struct read_secret_async_http_client_example: AsyncParsableCommand {
    struct Secret: Codable {
        var apiKey: String
    }

    mutating func run() async throws {
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: AsyncHTTPClientTransport())
        try await vaultClient.login(method: .token("education"))

        do {
            guard let secret: Secret = try await vaultClient.readKeyValueSecret(mountPath: "secret", key: "dev-eu-central-1")
            else {
                fatalError("Unable to read secret. Please check your Vault configuration has the same root token")
            }

            print("""
                Access Granted!
                apiKey: \(secret.apiKey)
                """)
        } catch {
            print("Unable to read secret: " + String(reflecting: error))
        }
    }
}

