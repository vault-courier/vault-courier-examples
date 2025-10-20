#  Read Secret using VaultCourier with AsyncHTTPClient

An example project using VaultCourier

This example is a follow-up of [write-secret-urlsession-example](https://github.com/vault-courier/vault-courier-examples/tree/main/write-secret-urlsession-example) or [write-secret-async-http-client-example](https://github.com/vault-courier/vault-courier-examples/tree/main/write-secret-async-http-client-example). Please run one of them before continuing here.

## Usage

> Important: This example is intentionally simplified for demonstration purposes and can serve as a helpful starting point for learning. However, never use a Vault instance in `dev` mode in a production environment.

Start your vault instance instance in dev-mode either with Hashicorp Vault

```sh
% vault server -dev -dev-root-token-id="education"
```

or with OpenBao

```sh
% bao server -dev -dev-root-token-id="education"
```

Alternative you can run a docker image with

```sh
docker run --rm --detach -p 8200:8200 -e 'VAULT_DEV_ROOT_TOKEN_ID=education' hashicorp/vault:latest
```

or

```sh
docker run --rm --detach -p 8200:8200 -e 'BAO_DEV_ROOT_TOKEN_ID=education' openbao/openbao:latest
```

Build and run the VaultCourier client CLI using:

```sh
% swift run
Access Granted!
apiKey: my_secret_api_key
```


