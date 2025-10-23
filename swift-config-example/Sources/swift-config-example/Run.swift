//  Copyright (c) 2025 Javier Cuesta
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  See LICENSE.txt for license information.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import ArgumentParser
import VaultCourier
import OpenAPIAsyncHTTPClient
import Configuration
import Logging
import Foundation

@main
struct swift_config_example: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Example of using a Vault secret provider in swift-configuration",
        subcommands: [
            Provision.self,
            App.self
        ]
    )
}

enum Constants {
    static let enginePath = "secret"
    static let keyName = "third_party_service"
    static let token = "education"
}

struct AppSecrets: Codable {
    let apiKey: String
}

extension swift_config_example {
    struct App: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Application using swift-configuration with VaultSecretProvider. Note: run the 'provision' command first before running this command",
        )

        

        mutating func run() async throws {
            // Create vault client
            let logger = Logger(label: "App")
            let vaultClient = VaultClient(
                configuration: .defaultHttp(backgroundActivityLogger: logger),
                clientTransport: AsyncHTTPClientTransport()
            )
            try await vaultClient.login(method: .token(Constants.token))

            // Create VaultSecretProvider
            let absoluteKey = AbsoluteConfigKey(["third_party", "service", "api_key"])
            let encodedKey = VaultSecretProvider.keyEncoder.encode(absoluteKey)
            let vaultSecretProvider = VaultSecretProvider(
                vaultClient: vaultClient,
                evaluationMap: [
                    absoluteKey: try await VaultSecretProvider.keyValueSecret(mount: Constants.enginePath, key: Constants.keyName)
                ]
            )

            // Create a Hierarchy of providers
            let reader = ConfigReader(
                providers: [
                    vaultSecretProvider,
                    EnvironmentVariablesProvider(environmentVariables: [
                        "THIRD_PARTY_SERVICE_API_KEY": "api_key_from_environment_variables_provider"
                    ])
                ],
                accessReporter: AccessLogger(logger: logger, level: .debug)
            )
            let readerValue = try await reader.fetchRequiredBytes(
                forKey: encodedKey,
                isSecret: true
            )

            let secret = try JSONDecoder().decode(AppSecrets.self, from: Data(readerValue))
            logger.info("\(encodedKey): \(secret.apiKey)")
        }
    }
}


extension swift_config_example {
    struct Provision: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Provision a new Vault secret version",
        )

        mutating func run() async throws {
            // Create vault client
            let logger = Logger(label: "Provision")
            let vaultClient = VaultClient(
                configuration: .defaultHttp(backgroundActivityLogger: logger),
                clientTransport: AsyncHTTPClientTransport()
            )

            // Authenticate with vault
            try await vaultClient.login(method: .token(Constants.token))

            let mountPath = Constants.enginePath
            let key = Constants.keyName
            // Write secret
            try await vaultClient.writeKeyValue(
                mountPath: mountPath,
                secret: AppSecrets(apiKey: "secret_api_key_stored_in_vault"),
                key: key
            )

            logger.info("Secret written successfully at /\(mountPath)/\(key)")
        }
    }
}
