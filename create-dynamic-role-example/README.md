#  Create Dynamic Role

An example project using VaultCourier.

This example is part of the tutorial [understanding dynamic roles](https://swiftpackageindex.com/vault-courier/vault-courier/main/tutorials/vaultcourier/understand-dynamic-roles), section 3 and is a follow-up to [configure-pg-connection-example](https://github.com/vault-courier/vault-courier-examples/tree/main/configure-pg-connection-example). It's a CLI client that uses a configured connection between vault and a [Postgres](https://www.postgresql.org) database to generate dynamic credentials.

## Usage

> Important: This example is deliberately simplified and is intended for illustrative purposes only. In particular, never use a Vault instance in dev-mode in a production deployment. It is strongly recommended to create a dedicated database user specifically for Vault to use.
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

If not done before, run [configure-pg-connection-example](https://github.com/vault-courier/vault-courier-examples/tree/main/configure-pg-connection-example).

Finally, build and run the VaultCourier client CLI using the same arguments as given to `configure-pg-connection-example`:

```sh
% swift build
% $(swift build --show-bin-path)/create-dynamic-role-example -e "path/to/database/mount" -c "my_connection" -r "read_only"
lease_id           path/to/database/mount/creds/read_only/TVo0C6muW9bzvlrREx8pZKKr
lease_duration     3600
lease_renewable    true
password           52TkXJAM43E-G7IBgV9c
username           v-token-read_onl-EkLbrLOfzIiGuIVmtEx9-1746220628 
```

You can verified that the user was created in the database with

```sh
% docker exec -i \
  learn-postgres \
  psql -U vault_root -d postgres -c "SELECT usename, valuntil FROM pg_user;"

                     usename                      |        valuntil
--------------------------------------------------+------------------------
 vault_root                                       |
 v-token-read_onl-EkLbrLOfzIiGuIVmtEx9-1746220628 | 2025-06-03 20:28:25+00

```


