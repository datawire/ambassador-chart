# devel (aka `make deploy`) profile

Main profile used for generating a manifest similar to the manifest
created with `make deploy`.

The main differences from the `getambassador.io` manifest to `make deploy`'s yaml are:

- We generate a mangled version of the CRDs that works on kube 1.10, for _kubernaut_.
- obey `DEV_IMAGE_PULL_SECRET` environment variable
- obey `AMBASSADOR_SINGLE_NAMESPACE` environment variable
- obey `AES_IMAGE` environment variable
- Set `SCOUT_DISABLE`

