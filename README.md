## Crusoe Cloud Controller Manager Helm Charts

This repository defines the official Cloud Controller Manager (CCM) Helm Charts for use with [Crusoe Cloud](https://crusoecloud.com/).

**The CCM Helm Charts are currently in :construction: Alpha :construction:.**

## Support

**The Crusoe CCM is only supported on Crusoe Managed Kubernetes (CMK).** 
This guide assumes that the user has already set up CMK on Crusoe Cloud.

Other configurations will be supported on a best-effort basis.

## Prerequisites

The examples below assume the intended namespace
for the CCM is `kube-system`.

### Setting up credentials

As the CCM will communicate with the Crusoe Cloud API to orchestrate VM / Instance Operations, you will have to set up
credentials in your Kubernetes cluster which the CCM can then use to communicate with the API. Here is a template `.yaml` file
which can be modified with your credentials and applied to your cluster.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: crusoe-secrets
  namespace: kube-system
type: Opaque
data:
  CRUSOE_PROJECT_ID: [base64 encoded value]
  CRUSOE_ACCESS_KEY: [base64 encoded value]
  CRUSOE_SECRET_KEY: [base64 encoded value]
  CRUSOE_API_ENDPOINT: [base64 encoded value]

```

An appropriate secret can be created in your cluster by filling out the command below and running it in the terminal:
```shell
kubectl create secret generic crusoe-secrets -n kube-system -o yaml \
--from-literal=CRUSOE_PROJECT_ID=$CRUSOE_PROJECT_ID \
--from-literal=CRUSOE_ACCESS_KEY=$CRUSOE_ACCESS_KEY \
--from-literal=CRUSOE_SECRET_KEY=$CRUSOE_SECRET_KEY \
--from-literal=CRUSOE_API_ENDPOINT=$CRUSOE_API_ENDPOINT
```

By default, the ccm will use the `crusoe-secrets` secret.
The name of the secret may be changed in the `secrets` section of the `values.yaml` file.

### Helm

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add <repo alias> https://crusoecloud.github.io/crusoe-cloud-controller-manager-helm-charts/charts

If you have already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
<repo alias>` to see the available charts.

## Installation


To install the Crusoe Cloud Controller Manager chart in the `kube-system` namespace:

    helm install <chart alias> <repo alias>/crusoe-cloud-controller-manager -n kube-system

To uninstall the chart:

    helm delete <chart alias>

## Customization

The name of the secret containing the access key, secret key, project_id and api endpoint can be changed by modifying the `secrets.crusoeApiKeys.secretName` value.

## Non-CMK Deployments

If you are deploying on a self-managed Kubernetes cluster, it is **strongly recommended** that you change the `crusoe.projectID` value to the Crusoe project ID that contains your node VMs.
