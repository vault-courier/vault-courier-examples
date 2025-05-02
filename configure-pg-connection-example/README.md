#  Configure PostgreSQL Connection

An example project using VaultCourier

This example is part of the tutorial [understanding dynamic roles](https://swiftpackageindex.com/vault-courier/vault-courier/main/tutorials/documentation/understand-dynamic-roles), section 2. It's a CLI client that enables the vault's database mount and creates a connection between Vault/OpenBao and a [Postgres](https://www.postgresql.org) database.

## Usage

> Important: This example is deliberately simplified and is intended for illustrative purposes only. In particular, never use a Vault instance in dev-mode in a production deployment, and consider using a dedicated vault root user when interacting with databases.

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
$ docker pull postgres:latest

$ docker run \
    --detach \
    --name learn-postgres \
    -e POSTGRES_USER=vault_root \
    -e POSTGRES_PASSWORD=root_password \
    -e POSTGRES_DB=postgres \
    -p 5432:5432 \
    --rm \
    postgres

$ docker exec -i \
    learn-postgres \
    psql -U vault_root -d postgres -c "CREATE ROLE \"read_only\" NOINHERIT;"

$ docker exec -i \
  learn-postgres \
  psql -U vault_root -d postgres -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"read_only\";"
```


Finally, build and run the VaultCourier client CLI using:

```sh
% swift build
% $(swift build --show-bin-path)/configure-pg-connection-example -e "path/to/database/mount" -c "my_connection"
Database secret engine enabled at path/to/database/mount
Success! Data written to: path/to/database/mount/config/my_connection
allowed_roles: ["read_only"]
connection_url: postgresql://{{username}}:{{password}}@127.0.0.1:5432/postgres?sslmode=disable
connection_username: vault_root
password_authentication: scram-sha-256
plugin_name: postgresql-database-plugin
```


