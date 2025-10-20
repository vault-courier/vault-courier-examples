#  Hummingbird with VaultCourier and Pkl

An example project of a Hummingbird server app using VaultCourier and Pkl.

It modifies Hummingbird's Todo example to use VaultCourier to securely fetch the database secrets, and Pkl to seamslessly improve the secret consumption and provision. The later makes Pkl the native config format for this Todo app example. This end-to-end example is the result of the tutorial [approle-hummingbird-pkl](https://swiftpackageindex.com/vault-courier/vault-courier/main/tutorials/vaultcourier/approle-hummingbird-pkl). This package contains the following executables:

1. A **Todo** app using VaultCourier to access database credentials with `Pkl` as main configuration format and secret resource reader.
2. A **Migrator** app that performs the initial database migrations.
3. A **VaultOperations** app that sets up the Vault-PostgreSQL integration and creates the necessary AppRoles.

The tutorial [approle-hummingbird-pkl](https://swiftpackageindex.com/vault-courier/vault-courier/main/tutorials/vaultcourier/approle-hummingbird-pkl) walks through the implementation.

## Usage

> Important: This example is deliberately simplified and is intended for illustrative purposes only. In particular, never use a Vault instance in dev-mode in a production deployment. It is strongly recommended to create a dedicated database user specifically for Vault to use. Please refer to Hashicorp Vault or Openbao documentation for best practices and production hardening.

For this example we need the `pkl` binary installed (and `pkl-gen-swift` if you want to follow the tutorial). Please visit [https://pkl-lang.org](https://pkl-lang.org/main/current/pkl-cli/index.html#installation) for instructions.

Run a docker-compose script to start your vault instance in dev-mode either with Hashicorp Vault

```sh
Scripts % ./run-services.sh vault
```

or with OpenBao

```sh
Scripts % ./run-services.sh bao
```

In the terminal go to root folder of this Package and run the `admin-vault` command line tool. First run the provision with the path to the vault configuration file:

```sh
approle-hummingbird-pkl-example % PKL_EXEC=/path/to/pkl/binary swift run Operations provision Sources/Operations/Pkl/Stage/vaultAdminConfig.pkl

Policy 'migrator' written.
Policy 'todos' written.
Database secrets engine enabled at 'database'.
Static role 'static_server_role' created.
Dynamic role 'dynamic_migrator_role' created.
AppRole Authentication enabled.
AppRole 'server_app_role' created.
AppRole 'migrator_app_role' created.
```

Run the approle credentials generation for the Migrator app:


```sh
approle-hummingbird-pkl-example % swift run Operations credentials migrator Sources/Operations/Pkl/Stage/vaultAdminConfig.pkl

Generating Approle credentials for 'migrator' app...
SecretID successfully written to ./approle_secret_id.txt
migrator app roleID: 323184a0-7665-f89f-6350-aa2c4005dc4c
```

Run the the Migrator app with the `ROLE_ID` obtained from the command before. Example:

```sh
approle-hummingbird-pkl-example % ROLE_ID=323184a0-7665-f89f-6350-aa2c4005dc4c SECRET_ID_FILEPATH=./approle_secret_id.txt swift run Migrator

info migrator : [VaultCourier] login authorized
Migration successful! 'todos' table created.
```

Run the approle credentials generation for the Todo app.

```sh
approle-hummingbird-pkl-example % swift run Operations credentials todo Sources/Operations/Pkl/Stage/vaultAdminConfig.pkl
Generating Approle credentials for 'todo' app...
SecretID successfully written to ./approle_secret_id.txt
todo app roleID: 8039d04e-f609-2733-fe7a-ef682d709548
```

With the `ROLE_ID` you obtain from the previous step we are ready to run the Todo app. Set the `PKL_EXEC` environment variable. Example (replace with your Todo `ROLE_ID` and `PKL_EXEC` path):

```sh
approle-hummingbird-pkl-example % PKL_EXEC=/path/to/pkl/binary ROLE_ID=8039d04e-f609-2733-fe7a-ef682d709548 SECRET_ID_FILEPATH=./approle_secret_id.txt swift run App

info todos-postgres-tutorial : [VaultCourier] login authorized
info todos-postgres-tutorial : [HummingbirdCore] Server started and listening on 127.0.0.1:8080
```

### Clean up

You can stop the Vault dev server, and the postgres container with

```sh
Scripts % docker compose -f compose-vault.yml -p "vault" down --volumes --remove-orphans
```

or if you started a Bao dev server

```sh
Scripts % docker compose -f compose-bao.yml -p "bao" down --volumes --remove-orphans
```

