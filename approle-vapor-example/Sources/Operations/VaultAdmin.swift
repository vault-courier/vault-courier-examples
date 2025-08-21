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
import struct Foundation.URL
import OpenAPIAsyncHTTPClient
import VaultCourier

@main
struct VaultAdmin: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A sample vault-admin operations tool",
        subcommands: [
            Provision.self,
            AppRoleCredentials.self
        ]
    )
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

extension VaultAdmin {
    struct AppRoleCredentials: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "credentials",
            abstract: "Generates the approle credentials for the Todo server or migrator app."
        )
        @Argument var app: App

        @Option(name: .shortAndLong)
        var outputFile: String = "./approle_secret_id.txt"

        enum App: String, ExpressibleByArgument {
            case todo
            case migrator
        }

        func run() async throws {
            let vaultClient = try makeVaultClient()
            try await vaultClient.authenticate()

            try await generateSecretID(app, vaultClient: vaultClient)
        }

        func generateSecretID(_ app: App, vaultClient: VaultClient) async throws {
            let appRoleName = switch app {
                case .todo:
                    "server_app_role"
                case .migrator:
                    "migrator_app_role"
            }
            print("Generating Approle credentials for '\(app.rawValue)' app...")

            // Generate SecretID for the given app
            let tokenResponse = try await vaultClient.generateAppSecretId(
                capabilities: .init(
                    roleName: appRoleName
                )
            )
            let secretID: String = switch tokenResponse {
                case .wrapped(let wrappedResponse):
                    wrappedResponse.token
                case .secretId(let secretIdResponse):
                    secretIdResponse.secretID
            }
            try secretID.write(to: URL(filePath: self.outputFile), atomically: true, encoding: .utf8)
            print("SecretID successfully written to \(outputFile)")

            let roleIdResponse = try await vaultClient.appRoleID(name: appRoleName)
            print("\(app.rawValue) app roleID: \(roleIdResponse.roleId)")
        }
    }

    struct Provision: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Provision vault policies, approles and sets the database secret mount."
        )

        func run() async throws {
            let vaultClient = try makeVaultClient()
            try await vaultClient.authenticate()

            try await updatePolicies(vaultClient: vaultClient)
            try await provisionDatabase(vaultClient: vaultClient)
            try await configureAppRole(vaultClient: vaultClient)
        }

        func updatePolicies(vaultClient: VaultClient) async throws {
            let policies = [
                "todos": "path \"database/static-creds/*\" { capabilities = [\"read\"] }",
                "migrator": "path \"database/creds/*\" { capabilities = [\"read\"] }"
            ]

            for (name, policy) in policies {
                try await vaultClient.createPolicy(name: name, hclPolicy: policy)
                print("Policy '\(name)' written.")
            }
        }

        func provisionDatabase(vaultClient: VaultClient) async throws {
            let databaseMountPath = "database"
            let databaseConnection = "pg_connection"
            let staticRoleName = "static_server_role"
            let dynamicRoleName = "dynamic_migrator_role"

            // Enable Database secret engine
            try await vaultClient.enableSecretEngine(mountConfig: .init(mountType: "database", path: databaseMountPath))
            print("Database secrets engine enabled at '\(databaseMountPath)'.")

            // Create connection between vault and a postgresql database
            try await vaultClient.databaseConnection(
                configuration: .init(
                    connection: databaseConnection,
                    allowedRoles: [
                        staticRoleName,
                        dynamicRoleName
                    ],
                    connectionUrl: "postgresql://{{username}}:{{password}}@127.0.0.1:5432/postgres?sslmode=disable",
                    username: "vault_root",
                    password: "root_password"),
                enginePath: databaseMountPath
            )

            // Create static role
            try await vaultClient.create(
                staticRole: .init(
                    vaultRoleName: staticRoleName,
                    databaseUsername: "todos_user",
                    databaseConnectionName: databaseConnection,
                    rotation: .period(.seconds(3600*60*24*28)),
                    credentialType: .password),
                enginePath: databaseMountPath
            )
            print("Static role '\(staticRoleName)' created.")

            // Create dynamic role
            try await vaultClient.create(
                dynamicRole: .init(
                    vaultRoleName: dynamicRoleName,
                    databaseConnectionName: databaseConnection,
                    defaultTTL: .seconds(120),
                    creationStatements: [
                        #"CREATE ROLE "{{name}}" WITH SUPERUSER LOGIN PASSWORD '{{password}}';"#
                    ],
                    credentialType: .password
                ),
                enginePath: databaseMountPath
            )
            print("Dynamic role '\(dynamicRoleName)' created.")
        }

        func configureAppRole(vaultClient: VaultClient) async throws {
            // Enable AppRole authentication
            try await vaultClient.enableAuthMethod(configuration: .init(path: "approle", type: "approle"))
            print("AppRole Authentication enabled.")

            // Create server approle
            let todoAppRole = "server_app_role"
            try await vaultClient.createAppRole(.init(
                name: todoAppRole,
                secretIdTTL: .seconds(3600),
                tokenPolicies: ["todos"],
                tokenTTL: .seconds(3600),
                tokenType: .service)
            )
            print("AppRole '\(todoAppRole)' created.")

            // Create Migrator approle
            let migratorAppRole = "migrator_app_role"
            try await vaultClient.createAppRole(.init(
                name: migratorAppRole,
                secretIdTTL: .seconds(3600),
                tokenPolicies: ["migrator"],
                tokenTTL: .seconds(3600),
                tokenType: .batch)
            )
            print("AppRole '\(migratorAppRole)' created.")
        }
    }
}
