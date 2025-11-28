# Porkbun Webhook solver for cert-manager

This is an unofficial webhook solver for [cert-manager](https://cert-manager.io/) and [Porkbun](https://porkbun.com/).

## Usage

1. Deploy the webhook:
    ```bash
    helm repo add webhook-porkbun \
      https://robdavid.github.io/cert-manager-webhook-porkbun

    helm install porkbun-webhook \
      webhook-porkbun/cert-manager-porkbun-webhook \
      --set groupName=<your group>
    ```

2. Create a secret containing your [API key](https://porkbun.com/account/api):

    ```bash
    kubectl create secret generic porkbun-key \
        --from-literal=api-key=<your key> \
        --from-literal=secret-key=<your key> \
        --from-literal=zone-name=example.com.
    ```

3. Configure a certificate issuer:

    ```yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: <your e-mail>
        privateKeySecretRef:
          name: letsencrypt-key
        solvers:
          - selector:
              dnsZones:
                - <your domain>
            dns01:
              webhook:
                groupName: <your group>
                solverName: porkbun
                config:
                  apiKeySecretRef:
                    name: porkbun-key
                    key: api-key
                  secretKeySecretRef:
                    name: porkbun-key
                    key: secret-key
    ```

## Running the test suite

All DNS providers **must** run the DNS01 provider conformance testing suite,
else they will have undetermined behaviour when used with cert-manager.

**It is essential that you configure and run the test suite when creating a
DNS01 webhook.**

To run the tests, first put your api key into testdata/porkbun-solver/porkbun-secret.yaml.

Then you can run the test suite with:

```bash
TEST_ZONE_NAME=<your domain>. make test
```
