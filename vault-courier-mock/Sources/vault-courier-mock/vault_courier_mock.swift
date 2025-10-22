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
import VaultCourier

struct Secrets: Codable, Equatable {
    let apiKey1: String
    let apiKey2: String
}

@main
struct vault_courier_mock: AsyncParsableCommand {
    mutating func run() async throws {
        let apppRoleMountPath = "path/to/approle"
        let appRoleName = "test_role_name"
        let roleID = "role_id"
        let wrappedToken = "secret_wrap_id"
        let expectedSecretID = "secret_id"
        let clientToken = "approle_client_token"
        let databaseMount = "database_mount_path"
        let staticRole = "test_static_role"
        let staticRoleDatabaseUsername = "test_database_username"
        let staticRoleDatabasePassword = "test_database_password"
        let dynamicRole = "test_dynamic_role"
        let dynamicRoleDatabaseUsername = "test_database_username"
        let dynamicRoleDatabasePassword = "test_dynamic_database_password"
        let keyValueMount = "key_value_mount_path"
        let secretKeyPath = "secret_key_path"

        let expectedSecrets = Secrets(
            apiKey1: "api_key_1",
            apiKey2: "api_key_2"
        )

        let vaultClient = VaultClient(
            configuration: .defaultHttp(),
            clientTransport: MockVaultClientTransport.dev(
                clientToken: clientToken,
                apppRoleMountPath: apppRoleMountPath,
                appRoleName: appRoleName,
                wrappedToken: wrappedToken,
                expectedSecretID: expectedSecretID,
                databaseMount: databaseMount,
                staticRole: staticRole,
                staticRoleDatabaseUsername: staticRoleDatabaseUsername,
                staticRoleDatabasePassword: staticRoleDatabasePassword,
                dynamicRole: dynamicRole,
                dynamicRoleDatabaseUsername: dynamicRoleDatabaseUsername,
                dynamicRoleDatabasePassword: dynamicRoleDatabasePassword,
                keyValueMount: keyValueMount,
                secretKeyPath: secretKeyPath,
                expectedSecrets: expectedSecrets
            )
        )
        let response = try await vaultClient.unwrapAppRoleSecretID(token: wrappedToken)
        try await vaultClient.login(method: .appRole(
                path: apppRoleMountPath,
                credentials: .init(roleID: roleID,secretID: response.secretID)
            )
        )

        let staticCredentials = try await vaultClient.databaseCredentials(staticRole: staticRole,
                                                                          mountPath: databaseMount)
        print("Static role credentials: \(staticCredentials)")

        let dynamicCredentials = try await vaultClient.databaseCredentials(dynamicRole: dynamicRole,
                                                                           mountPath: databaseMount)
        print("Dynamic role credentials: \(dynamicCredentials)")

        let secrets: Secrets = try await vaultClient.readKeyValueSecret(mountPath: keyValueMount,
                                                                        key: secretKeyPath)
        print("KeyValue secrets: \(secrets)")
    }
}
