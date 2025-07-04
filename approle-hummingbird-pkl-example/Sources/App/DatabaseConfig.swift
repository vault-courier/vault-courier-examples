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
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import struct Foundation.URL
import class Foundation.JSONDecoder
import struct Foundation.Data
#endif

struct DatabaseConfig: Sendable {
    var host: String
    var port: Int
    var database: String
    var username: String
    var password: String
}

extension TodoConfig.Module {
    var databaseConfig: DatabaseConfig {
        get throws {
            let credentials = try JSONDecoder().decode(
                DatabaseCredentials.self,
                from: Data(postgresConfig.credentials.utf8)
            )

            return .init(
                host: postgresConfig.hostname,
                port: postgresConfig.port,
                database: postgresConfig.database,
                username: credentials.username,
                password: credentials.password
            )
        }
    }
}
