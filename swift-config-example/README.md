# Swift-Configuration Integration example

This example explores a `VaultSecretProvider` which implements a custom [ConfigProvider](https://swiftpackageindex.com/apple/swift-configuration/0.2.0/documentation/configuration/configprovider). 

> Important: This example is deliberately simplified and is intended for illustrative purposes only. In particular, never use a Vault instance in dev-mode in a production deployment. Please refer to Hashicorp or Openbao documentation for best practices and production hardening.

## Usage

First run a Vault in dev mode with

```sh
container_id=$(docker run --rm --detach -p 8200:8200 -e 'VAULT_DEV_ROOT_TOKEN_ID=learn-vault' hashicorp/vault:latest)
```

or with OpenBao

```sh
container_id=$(docker run --rm --detach -p 8200:8200 -e 'BAO_DEV_ROOT_TOKEN_ID=education' openbao/openbao:latest)
```

After downloading this example, run the **provision** command from the project’s root directory. This step writes an api key in the Key/Value secret engine:

```sh
swift-config-example % swift run swift-config-example provision

info Provision: [swift_config_example] Secret written successfully at /secret/third_party_service
```

Next, we'll run an app that uses `swift-configuration` as main config format. It retrieves the API key from a remote vault, and if that attempt fails, it falls back to reading the key from an environment variable.

```sh
swift-config-example % swift run swift-config-example app

info App: [swift_config_example] third_party.service.api_key: secret_api_key_stored_in_vault
```

## Clean-up

To stop the Vault server run:

```sh
docker stop "${container_id}" > /dev/null
```



