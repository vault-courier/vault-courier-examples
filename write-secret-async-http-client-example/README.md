# Write a Secret using VaultCourier with AsyncHTTPClient

An example project using VaultCourier

## Usage

> Important: This example is deliberately simplified and is intended for illustrative purposes only. In particular, never use a Vault instance in dev-mode in a production environment.

Start your vault instance instance in dev-mode either with Hashicorp Vault

```sh
% vault server -dev -dev-root-token-id="education"
```

or with OpenBao

```sh
% bao server -dev -dev-root-token-id="education"
```

The last argument sets the root token to be equal to "education".

Build and run the VaultCourier client CLI using:

```sh
% swift run
```

You will get something like:

```sh 
Secret written successfully!
created_time: 2025-01-25T11:28:25.592030964Z
version: 1
```

If you run it again the version will increase.


