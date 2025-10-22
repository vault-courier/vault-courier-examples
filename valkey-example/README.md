#  Valkey Integration example

An example project using VaultCourier and Valkey.

OpenBao offers a plugin to manage Valkey database credentials, and in this example uses `vault-courier` to initialize a valkey client from [valkey-swift](https://github.com/valkey-io/valkey-swift). 

> Important: This example is deliberately simplified and is intended for illustrative purposes only. In particular, never use a Vault instance in dev-mode in a production deployment. It is strongly recommended to create a dedicated database user specifically for Vault to use. Please refer to Openbao documentation for best practices and production hardening.

## Usage

We'll use Docker Compose to spin up an OpenBao Vault instance and a Valkey database on the same network. Start by copying the [scripts folder](https://github.com/vault-courier/vault-courier-examples/tree/main/scripts) from the `vault-courier-examples` repository and placing it anywhere on your computer. Then, inside that folder, run:

```
scripts % docker compose -f compose-bao-valkey.yml -p "bao-valkey" up --build -d
```

After downloading this example, run the **provision** command from the project’s root directory. This step connects OpenBao to Valkey and creates a dynamic role, which will allow on-demand user creation later. In this example, the dynamic role’s access control is restricted to read and write operations on a specific Valkey key.

```sh
% swift run valkey-example provision

info VaultClient: [VaultCourier] login authorized
info VaultClient: [valkey_example] Database secret engine enabled at database
info VaultClient: [valkey_example] Success! Data written to: database/config/valkey_connection
info VaultClient: [valkey_example] connection details ---
allowed_roles: ["*"]
connection_host: valkey-cache
connection_port: 6379
connection_username: vault_user
rotate_statements: ["+@all", "+@admin"]
plugin_name: valkey-database-plugin
----------------------------------------------
info VaultClient: [valkey_example] Success! Dynamic role 'qa_role' created.
```

Next, we'll run an app that uses `valkey-swift` to increment a "likes counter" in the Valkey database. The Vault client requests OpenBao to generate a new Valkey user and return the credentials. The app then uses those credentials to increase and retrieve the counter’s value.

```
swift run valkey-example app

info App: [VaultCourier] login authorized
info App: [valkey_example] Valkey credentials fetched successfully: RoleCredentialsResponse(requestID: "3b34a44d-1b09-d8e4-e068-bab74cd27ac8", username: "V_TOKEN_QA_ROLE_RZHTDTBVAEI6460A89AB_1761152156", password: "M14--FRsxG1Z4SIzXw7i", timeToLive: nil)
info App: [valkey_example] likes-count created
info App: [valkey_example] likes-count increased by ten
info App: [valkey_example] likes-count increased by ten
info App: [valkey_example] likes-count = 21
```

And that’s it! In this example, `vault-courier` handles Valkey credential management for us.

### Clean up

You can stop OpenBao's vault dev server, and the valkey container with

```sh
scripts % docker compose -f compose-bao-valkey.yml -p "bao-valkey" down --volumes --remove-orphans
```
