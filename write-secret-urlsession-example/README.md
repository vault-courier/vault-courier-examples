# Write a Secret using VaultCourier with URLSession

An example project using VaultCourier

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

The last argument sets the root token to be equal to "education". Alternative you can run a docker image with

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
```

You will get something like:

```sh
Secret written successfully!
created_time: 2025-01-25T11:28:25.592030964Z
version: 1
```

If you run it again the version will increase.

