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

import VaultCourier
import OpenAPIAsyncHTTPClient
import PostgresNIO
import struct Hummingbird.Environment
import struct Foundation.URL

let environment = Environment()
guard let roleID = environment.get("ROLE_ID"),
      let secretIdFilePath = environment.get("SECRET_ID_FILEPATH")
else { fatalError("❌ Missing credentials for Vault authentication.") }

// 1. Read the secretID provided by the broker
let secretID = try String(contentsOf: URL(filePath: secretIdFilePath), encoding: .utf8)
let logger = Logger(label: "migrator")

// 2. Create a vault client.
let vaultURL = try URL(validatingOpenAPIServerURL: "http://127.0.0.1:8200/v1")
let vaultConfiguration = VaultClient.Configuration(
    apiURL: vaultURL,
    databaseMountPath: "database",
    backgroundActivityLogger: logger
)

let vaultClient = VaultClient(
    configuration: vaultConfiguration,
    client: Client(
        serverURL: vaultConfiguration.apiURL,
        transport: AsyncHTTPClientTransport()
    ),
    authentication: .appRole(
        credentials: .init(roleID: roleID, secretID: secretID),
        isWrapped: false
    )
)
// 3. Authenticate with vault
guard try await vaultClient.authenticate()
else { fatalError("❌ The app could not log in to Vault. Open investigation 🕵️") }

// 4. Get dynamic credentials
let credentials = try await vaultClient.databaseCredentials(dynamicRole: "dynamic_migrator_role")

// 5. Create PG client
let pgClient = PostgresClient(
    configuration: .init(host: "localhost", username: credentials.username, password: credentials.password, database: "postgres", tls: .disable),
    backgroundLogger: logger
)

// 6. Run the PG client and the migration
try await withThrowingTaskGroup(of: Void.self) { taskGroup in
    taskGroup.addTask {
        await pgClient.run() // !important
    }

    try await pgClient.query(
        """
        CREATE TABLE IF NOT EXISTS todos (
            "id" uuid PRIMARY KEY,
            "title" text NOT NULL,
            "order" integer,
            "completed" boolean,
            "url" text
        )
        """,
        logger: logger
    )

    try await pgClient.query(
        """
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE todos TO todos_user;
        """,
        logger: logger
    )

    try await pgClient.query(
        """
        ALTER TABLE IF EXISTS todos OWNER TO vault_root;
        """,
        logger: logger
    )

    taskGroup.cancelAll()
}

print("Migration successfull! 'todos' table created.")
