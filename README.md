# preemptible-killer

This repo is based 99% of the 

[estafette-gke-preemptible-killer](https://github.com/estafette/estafette-gke-preemptible-killer)

repo.

This small Kubernetes application loop through a given preemptibles node pool and kill a node before the regular [24h
life time of a preemptible VM](https://cloud.google.com/compute/docs/instances/preemptible#limitations).

[![License](https://img.shields.io/github/license/estafette/estafette-gke-preemptible-killer.svg)](https://github.com/estafette/estafette-gke-preemptible-killer/blob/master/LICENSE)

## Why?

When creating a cluster, all the node are created at the same time and should be deleted after 24h of activity. To
prevent large disruption, the estafette-gke-preemptible-killer can be used to kill instances during a random period
of time between 12 and 24h. It makes use of the node annotation to store the time to kill value.

## How does that work

At a given interval, the application get the list of preemptible nodes and check weither the node should be
deleted or not. If the annotation doesn't exist, a time to kill value is added to the node annotation with a
random range between 12h and 24h based on the node creation time stamp.
When the time to kill time is passed, the Kubernetes node is marked as unschedulable, drained and the instance
deleted on GCloud.

## Known limitations

- Pods in selected nodes are deleted, not evicted.
- Selecting node pool is not supported yet, the code is processing ALL
  preemptible nodes attached to the cluster, and there is no way to limit it
  even via taints nor annotations
- This tool increases the chances to have many small disruptions instead of
  one major disruption.
- This tool does not guarantee that major disruption is avoided - GCP can
  trigger large disruption because the way preemptible instances are managed.
  Ensure your have PDB and enough of replicas, so for better safety just use
  non-preemptible nodes in different zones. You may also be interested in [estafette-gke-node-pool-shifter](https://github.com/estafette/estafette-gke-node-pool-shifter)

## Usage

You can either use environment variables or flags to configure the following settings:

| Environment variable   | Flag                     | Default  | Description
| ---------------------- | ------------------------ | -------- | -----------------------------------------------------------------
| DRAIN_TIMEOUT          | --drain-timeout          | 300      | Max time in second to wait before deleting a node
| FILTERS                | --filters (-f)           |          | Label filters in the form of `key1: value1[, value2[, ...]][; key2: value3[, value4[, ...]], ...]`
| INTERVAL               | --interval (-i)          | 600      | Time in second to wait between each node check
| KUBECONFIG             | --kubeconfig             |          | Provide the path to the kube config path, usually located in ~/.kube/config. This argument is only needed if you're running the killer outside of your k8s cluster
| METRICS_LISTEN_ADDRESS | --metrics-listen-address | :9001    | The address to listen on for Prometheus metrics requests
| METRICS_PATH           | --metrics-path           | /metrics | The path to listen for Prometheus metrics requests

### Create a Google Service Account

In order to have the estafette-gke-preemptible-killer instance delete nodes,
create a service account and give the _compute.instances.delete_ permissions.

You can either create the service account and associate the role using the
GCloud web console or the cli:

```bash
$ export project_id=<PROJECT>
$ gcloud iam --project=$project_id service-accounts create preemptible-killer \
    --display-name preemptible-killer
$ gcloud iam --project=$project_id roles create preemptible_killer \
    --project $project_id \
    --title preemptible-killer \
    --description "Delete compute instances" \
    --permissions compute.instances.delete
$ export service_account_email=$(gcloud iam --project=$project_id service-accounts list --filter preemptible-killer --format 'value([email])')
$ gcloud projects add-iam-policy-binding $project_id \
    --member=serviceAccount:${service_account_email} \
    --role=projects/${project_id}/roles/preemptible_killer
$ gcloud iam --project=$project_id service-accounts keys create \
    --iam-account $service_account_email \
    google_service_account.json
```

## Installation

Prepare using Helm:

```
brew install kubernetes-helm
kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --wait
```

Then install or upgrade with Helm:

```
helm repo add softonic-public https://charts.softonic.io
helm upgrade --install preemptible-killer --namespace preemptible-killer softonic-public/preemptible-killer
```
