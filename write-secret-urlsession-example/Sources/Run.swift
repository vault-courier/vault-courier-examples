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
import OpenAPIURLSession
import VaultCourier
import Foundation

@main
struct write_secret_urlsession_example: AsyncParsableCommand {
    struct Secret: Codable {
        var apiKey: String
    }

    mutating func run() async throws {
        let vaultClient = VaultClient(configuration: .defaultHttp(),
                                      clientTransport: URLSessionTransport())
        try await vaultClient.login(method: .token("education"))

        let secret = Secret(apiKey: "my_secret_api_key")

        do {
            let response = try await vaultClient.writeKeyValue(
                mountPath: "secret",
                secret: secret,
                key: "dev-eu-central-1"
            )

            print("""
                Secret written successfully!
                created_time: \(response.createdAt)
                version: \(response.version)
                """)
        } catch {
            print("Unable to write secret: " + String(reflecting: error))
        }
    }
}
