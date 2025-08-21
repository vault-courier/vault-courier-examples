#  Vapor with VaultCourier

An example project of a Vapor server app using VaultCourier.

It modifies Vapor's Todo start template project to use VaultCourier to securely fetch the database secrets. This end-to-end example is the result of the tutorial [approle-vapor](https://swiftpackageindex.com/vault-courier/vault-courier/main/tutorials/vaultcourier/approle-vapor). This package contains the following executables:

1. A **Todo** app using VaultCourier to access database credentials.
2. A **Migrator** app that performs the initial database migrations.
3. A **VaultOperations** app that sets up the Vault-PostgreSQL integration and creates the necessary AppRoles.

The tutorial [approle-vapor](https://swiftpackageindex.com/vault-courier/vault-courier/main/tutorials/vaultcourier/approle-vapor) walks through Vault concepts such as AppRole authentication, static and dynamic database roles, and response wrapping.

## Usage

> Important: This example is deliberately simplified and is intended for illustrative purposes only. In particular, never use a Vault instance in dev-mode in a production deployment. It is strongly recommended to create a dedicated database user specifically for Vault to use. Please refer to Hashicorp Vault or Openbao documentation for best practices and production hardening.

Start your vault instance instance in dev-mode either with Hashicorp Vault

```sh
% vault server -dev -dev-root-token-id="education"
```

or with OpenBao

```sh
% bao server -dev -dev-root-token-id="education"
```

In another terminal spin up a PostgreSQL container with docker:

```sh
% docker pull postgres:latest

% docker run \
    --detach \
    --name learn-postgres \
    -e POSTGRES_USER=vault_root \
    -e POSTGRES_PASSWORD=root_password \
    -e POSTGRES_DB=postgres \
    -e POSTGRES_HOST_AUTH_METHOD='scram-sha-256' \
    -e POSTGRES_INITDB_ARGS='--auth-host=scram-sha-256' \
    -p 5432:5432 \
    --rm \
    postgres

% docker exec -i \
    learn-postgres \
    psql -U vault_root -d postgres -c "CREATE ROLE \"todos_user\" LOGIN PASSWORD 'todos_user_password';"

% docker exec -i \
    learn-postgres \
    psql -U vault_root -d postgres -c "GRANT CONNECT ON DATABASE postgres TO todos_user;"
```

In the terminal go to root folder of this Package and run the `admin-vault` command line tool. First run the provision:

```sh
approle-vapor-example % swift run Operations provision

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
approle-vapor-example % swift run Operations credentials migrator

Generating Approle credentials for 'migrator' app...
SecretID successfully written to ./approle_secret_id.txt
migrator app roleID: 323184a0-7665-f89f-6350-aa2c4005dc4c
```

Run the the Migrator app with the `ROLE_ID` obtained from the command before. Example:

```sh
approle-vapor-example % ROLE_ID=323184a0-7665-f89f-6350-aa2c4005dc4c SECRET_ID_FILEPATH=./approle_secret_id.txt swift run Migrator

info migrator : [VaultCourier] login authorized
Migration successfull! 'todos' table created.
```

Run the approle credentials generation for the Todo app.

```sh
approle-vapor-example % swift run Operations credentials todo
Generating Approle credentials for 'todo' app...
SecretID successfully written to ./approle_secret_id.txt
todo app roleID: 8039d04e-f609-2733-fe7a-ef682d709548
```

With the `ROLE_ID` you obtain from the previous step we are ready to run the Todo app. Example (replace with your Todo `ROLE_ID`):

```sh
approle-hummingbird-example % ROLE_ID=8039d04e-f609-2733-fe7a-ef682d709548 SECRET_ID_FILEPATH=./approle_secret_id.txt swift run App

[ INFO ] login authorized
[ NOTICE ] Server started on http://127.0.0.1:8080
```

### Clean up

You can stop the Vault dev server with `Ctrl+C` (or kill the Vault process from a command: `pgrep -f vault | xargs kill`), and the postgres container with

```sh
% docker stop $(docker ps -f name=learn-postgres -q)
```

