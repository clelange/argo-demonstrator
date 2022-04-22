# argo-demonstrator

This repository demonstrates the use of [argo](https://argoproj.github.io/) using CMS OpenData to run a full analysis automatically in the cloud.

The analysis used here is Level 3 of the [Higgs-to-four-lepton analysis example using 2011-2012 data](http://opendata.cern.ch/record/5500).

## Setup

### OpenStack kubernetes cluster

After sourcing your `openrc.sh`, create the cluster adjusting the number of nodes:

```shell
openstack coe cluster create cms-recast-cluster --keypair lxplus2 --cluster-template kubernetes-preview --node-count 4 --labels influx_grafana_dashboard_enabled=true,kube_tag=v1.10.3-5,cvmfs_tag=qa,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,flannel_backend=vxlan,ingress_controller=traefik,kube_csi_enabled=True,cvmfs_csi_enabled=True,cephfs_csi_enabled=True
```

Once the cluster is created, get the environment:

```shell
openstack coe cluster config cms-recast-cluster > env.sh
source env.sh
```

### Installing argo

Please also see the [argo documentation](https://github.com/argoproj/argo/blob/master/demo.md)

#### CERN OpenStack

This assumes that you have a directory `${HOME}/bin`, which is in your `${PATH}`:

```shell
./install_argo_linux.sh
```

Grant admin privileges:

```shell
kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=default:default
```

NOTE: You can also submit workflows using a different service account using the `argo submit --serviceaccount <name>` flag.

#### Mac OS X

This requires [homebrew](https://brew.sh).

```shell
brew install kubernetes-cli kubernetes-helm
brew install argoproj/tap/argo
```

Install argo workflows following the instructions.

When using minikube, one has to mount the output directory (and keep it running):

```shell
minikube mount ./output:/data/ --uid 82 --gid 82
```

### Installing CVMFS StorageClass

_CERN OpenStack only_

In order to be able to read from CVMFS, the `StorageClass` instances for `cms.cern.ch` and `cms-opendata-conddb.cern.ch` need to be created using [cvmfs-storageclass.yaml](cvmfs-storageclass.yaml):

```shell
kubectl create -f cvmfs-storageclass.yaml
```

Check that the following commands give the expected output:

```shell
kubectl get sc
kubectl describe storageclass csi-cvmfs-cms
kubectl describe storageclass csi-cvmfs-cms-opendata-conddb
```

You can then submit a test workflow using [test-cvmfs-argo.yaml](test-cvmfs-argo.yaml):
```
argo submit test-cvmfs-argo.yaml
argo list
```

### CephFS access

_CERN OpenStack only_

There are some hints in the [CephFS CloudDocs](http://clouddocs.web.cern.ch/clouddocs/containers/tutorials/cephfs.html). Figure out your shares (here `cmssw-cephfs-storage`):

```shell
manila list
```

Check how this is shared:

```shell
manila share-export-location-list cmssw-cephfs-storage
```

Give access:

```shell
manila access-allow cmssw-cephfs-storage cephx cms_storage_user
```

Use the information from `Path` in [cephfs-storageclass.yaml](cephfs-storageclass.yaml).

Then check that the access-creation worked and get the `access_key`:

```shell
manila access-list cmssw-cephfs-storage
```

Convert both `access_to` and `access_key` values to `base64`:

```
echo -n 'cms_storage_user' | base64
echo -n 'my_access_key' | base64
```

Add this to a file called `cephfs-secret.yaml` in a format like this (mind that the `userKey` here has an arbitrary value):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: csi-cephfs-secret-cms
  namespace: kube-system
data:
  userID: Y21zX3N0b3JhZ2VfdXNlcg==
  userKey: QVFEQ1Z1NVp3UTZFSkJBQnR0VlRsRkRyYUg2WkFSd25rN0VaRUE9PQ==
```

Deploy both `Secret` and `StorageClass`:

```shell
kubectl create -f cephfs-secret.yaml
kubectl create -f cephfs-storageclass.yaml
```

Check that this worked by running the following commands:

```shell
kubectl get sc
kubectl describe sc csi-cephfs-cms
```

## Monitoring and interacting with CephFS storage

_CERN OpenStack only_

There is a [pod](storage-pod.yaml) that allows you to interactively explore the mounted volumes:

```shell
kubectl create -f storage-pod.yaml
```

Once the `Pod` with its three `PersistentVolumeClaim`s is running, you can log on to it:

```shell
kubectl exec -it storage-pod /bin/sh
```

and also copy files from and to the pod:

```shell
kubectl cp README.md storage-pod:/data/
kubectl exec -it storage-pod ls /data
kubectl cp storage-pod:/data/README.md test.md
```

## Deploy a workflow

For CERN OpenStack [level3-workflow-openstack.yaml](level3-workflow-openstack.yaml):

```shell
argo submit level3-workflow-openstack.yaml
```

On Mac OS X [level3-workflow.yaml](level3-workflow.yaml):

```shell
export ARGO_NAMESPACE=argo
argo submit level3-workflow.yaml
```

The workflow currently writes out to a default directory and therefore overwrites old ones.
