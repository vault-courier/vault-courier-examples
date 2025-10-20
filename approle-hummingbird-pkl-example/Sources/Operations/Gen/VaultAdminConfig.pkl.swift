// Code generated from Pkl module `VaultAdminConfig`. DO NOT EDIT.
import PklSwift

public enum VaultAdminConfig {}

extension VaultAdminConfig {
    public struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "VaultAdminConfig"

        public var policies: [VaultPolicy.Module]

        public var database: DatabaseConfiguration

        public var authMethod: AppRoleAuth

        public init(
            policies: [VaultPolicy.Module],
            database: DatabaseConfiguration,
            authMethod: AppRoleAuth
        ) {
            self.policies = policies
            self.database = database
            self.authMethod = authMethod
        }
    }

    public struct DatabaseConfiguration: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "VaultAdminConfig#DatabaseConfiguration"

        public var mount: MountConfiguration.Module

        public var connection: PostgresDatabaseConnection.Module

        public var staticRole: PostgresStaticRole.Module

        public var dynamicRole: PostgresRole.Module

        public init(
            mount: MountConfiguration.Module,
            connection: PostgresDatabaseConnection.Module,
            staticRole: PostgresStaticRole.Module,
            dynamicRole: PostgresRole.Module
        ) {
            self.mount = mount
            self.connection = connection
            self.staticRole = staticRole
            self.dynamicRole = dynamicRole
        }
    }

    public struct AppRoleAuth: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "VaultAdminConfig#AppRoleAuth"

        public var config: AuthMethodConfig.Module

        public var appRoles: [String: AppRole]

        public init(config: AuthMethodConfig.Module, appRoles: [String: AppRole]) {
            self.config = config
            self.appRoles = appRoles
        }
    }

    public struct AppRole: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "VaultAdminConfig#AppRole"

        public var properties: VaultAppRole.Module

        public var tokenConfig: AppRoleToken.Module

        public init(properties: VaultAppRole.Module, tokenConfig: AppRoleToken.Module) {
            self.properties = properties
            self.tokenConfig = tokenConfig
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `VaultAdminConfig.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> VaultAdminConfig.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `VaultAdminConfig.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> VaultAdminConfig.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}