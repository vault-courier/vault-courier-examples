#  Read Secret using VaultCourier with URLSession

An example project using VaultCourier

This example is a follow-up of write-secret-urlsession-example or write-secret-async-http-client-example. Please run one of them before continuing here.

## Usage

> Important: This example is deliberately simplified and is intended for illustrative purposes only. In particular, never install a Vault instance in dev-mode in a production environment.

Start your vault instance instance in dev-mode either with Hashicorp Vault

```sh
% vault server -dev -dev-root-token-id="education"
```

or with OpenBao

```sh
% bao server -dev -dev-root-token-id="education"
```

Build and run the VaultCourier client CLI using:

```sh
% swift run
Access Granted!
apiKey: my_secret_api_key
```
