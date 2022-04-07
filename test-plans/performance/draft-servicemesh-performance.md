# Cilium Service Mesh Performance Test Plan

## Frequency we will execute this test plan
Before each Release

## Test Plan Description
Each of these tests will have multiple metrics we will collect and compare. 

| Workload | Main Metric | Secondary Metric |
|----------|-------------|------------------|
| Nighthawk   | Throughput (rps) | CPU usage  |
| Nighthawk   | Latency (ms) | CPU usage       |

> CPU usage will be for the Cilium pods as well as the overall node CPU usage. We will use Prometheus to collect this information. 

> CPU and Memory will also be summarized across nodes as a single metric


## Tooling
### Tools to be deployed on the SUT

- Fortio UI \
*How do we install Fortio \
For your distribution read the docs : https://github.com/fortio/fortio#installation 

- Performance bookinfo \
*How do we install perf bookinfo?*\
First label one of your nodes with `app=workload`
 then `kubectl create -f https://gist.githubusercontent.com/jtaleric/ededfed35facde1296b40ca757efa3e8/raw/8ac3ac2fa6b07a9afe5bd3b5a461adbe71f048d9/performance-bookinfo.yaml`

 - Prometheus \
*How do we install prom?*\
`helm install prometheus prometheus-community/prometheus --namespace prometheus  --namespace prometheus --create-namespace`

   We will use Prom to monitor CPU/Mem/IO of the cilium pods, the test pods and the nodes.
 
- Grafana \
*How do we install Grafana?*\
`git clone https://github.com/cloud-bulldozer/performance-dashboards; cd performance-dashboards; make; cd dittybopper; ./k8s-deploy.sh`

   **WIP but having a Cilium specific dashboard showing Overall System metrics + Cilium Specific Metrics.  https://github.com/jtaleric/performance-dashboards/commit/1ac3a9b21c33c3dc2516f21428ebd4ea4a6396c1#diff-b9c0833d120841436640df16492f6e79f8e99e25232047aadcb63bd4378193aeR339-R375 

### Tooling Setup
#### kube-burner 
We will use kube-burner to scrape prometheus and store the metrics in ES. 

We will need to capture the prometheus token

> $ export token=$(kubectl get secrets -n prometheus prometheus-server-<secret> -o go-template='{{index .data "ca.crt"}}')

We will also need to forward the prometheus server port to the machine running the tests

> kubectl --namespace prometheus port-forward <prom server pod> 9090

We need to create a kube-burner config to define the ES server to store the data. I store this as `burner.yaml`
```yaml
---
global:
  writeToFile: true
  metricsDirectory: collected-metrics
  indexerConfig:
    enabled: true 
    esServers: [https://user:pass@es-server:9243]
    insecureSkipVerify: false 
    defaultIndex: kube-burner
    type: elastic

```



## System Under Test (SUT) definition
### Managed Platform testing
Service Mesh Performance testing will be in a single Region and Zone.

We will use `cilium install` which will capture SUT details such as the platform we are running on, to help build the most performant configuration for Cilium to run. 

| IaaS | SaaS | Controller Sizes | Node Sizes |  Region |
|------|------|------------------|------------|---------|
| GCP | GKE | n/a | n2-standard-16 | us-central1-a |


## Scenarios

### Baseline - No L7 Policy, Ingress and Hubble
Envoy shouldn't even bee in the picture here, as we haven't created an L7 policy or defined an ingress. 

#### Simple
  ```mermaid
    graph LR;
      subgraph NodeA
        LoadPod
      end
      subgraph NodeB
        Service
        ProductPage
      end
    Service---ProductPage
    LoadPod---Service
 ```

#### With Backend Calls
  ```mermaid
    graph LR;
      subgraph NodeA
        LoadPod
      end
      subgraph NodeB
        Service
        ProductPage
        Backend
      end
    Service---ProductPage---Backend
    LoadPod---Service
 ```

 ### With L7 Policy
 With l7 Policy, Envoy will only be created on the node that has the pod which matches the label for the l7 policy. 
 #### Simple HTTP Request
   ```mermaid
    graph LR;
      subgraph NodeA
        LoadPod
      end
      subgraph NodeB
        Envoy
        Service
        ProductPage
      end
    Envoy---Service---ProductPage
    LoadPod---Envoy
```
#### With Backend Calls
   ```mermaid
    graph LR;
      subgraph NodeA
        LoadPod
      end
      subgraph NodeB
        Envoy
        Service
        ProductPage
        Backend
      end
    Envoy---Service---ProductPage---Backend
    LoadPod---Envoy
 ```
 ### With Ingress 
Creating an Ingress policy will create Envoy instances across the fleet of nodes in the cluster.
  #### Simple HTTP Request
   ```mermaid
    graph LR;
      subgraph NodeA
        LoadPod
      end
      subgraph NodeB
        Service
        ProductPage
      end
    Envoy---Service---ProductPage
    LoadPod---Envoy
```
#### With Backend Calls
   ```mermaid
    graph LR;
      subgraph NodeA
        LoadPod
      end
      subgraph NodeB
        Service
        ProductPage
        Backend
      end
    Envoy---Service---ProductPage---Backend
    LoadPod---Envoy
   ```

### With Ingress and L7 policy

## CPU overhead for Observability
This needs some more investigation to establish a baseline. 

## Test Cases
### 1.1 Baseline - No Policy or Ingress defined
#### Steps to reproduce
1. Deploy Cloud in GKE using (https://github.com/jtaleric/tinker/tree/main/clouds/gke/kernel-swap) 
   1. Using parameters 
    - export TYPE=n2-standard-16
    - export KERNEL=5.16
    - export NODES=5
    - export BOOTSTRAP=true
2. Once the cluster is up, ensure the kernel version, `kubectl get nodes -o wide` 
3. Label a single node with `app=workload` this will be where Nighthawk runs, and we will steer all other pods to other nodes.
4. Follow the Kube-burner & Prometheus setup in the [tooling section](/Tooling-setup)
5. `kubectl create -f https://gist.githubusercontent.com/jtaleric/b786331b9c36b122b52aac666d9b2a64/raw/ed9a8afcfc117caeb1b091e7ee4b42b2a6a0558a/sm-benchmark-deployment.yaml`
6. Note the svc ip for the productpage that was deployed
7. Exec into the load pod `kubectl exec -it <pod> - sh`
8. Ensure connectivity to the svc ip is working with a simple 10sec test `nighthawk_client --duration 10 --simple-warmup --rps 1000 --connections 1 --concurrency auto -v error http://<svc ip>:<port>/` 
*Good Output:*
```
Counter                                 Value       Per second
benchmark.http_2xx                      7631        763.10
```
*Bad Output:* 
```
Counter                                 Value       Per second
cluster_manager.cluster_added           4           inf
```
1. ```for n in {1..3}; do k exec -it <load pod> -- nighthawk_client --duration 60 --simple-warmup --rps 1000 --connections 1 --concurrency auto -v error http://<svc ip>:<port>/ --output-format fortio | tee baseline-$n.json; done```
   
   > We will run with a single connection and attempt to achieve 1000rps. Since we are testing in mainly cloud environments. This can be adjusted if you are running in a more controlled deployment such as bare- metal. 

#### Metrics
##### Node CPU
##### Node Memory

### 1.2 Baseline - No Policy or Ingress defined - Hubble Enabled
#### Steps to reproduce
1. Deploy Cloud in GKE using (https://github.com/jtaleric/tinker/tree/main/clouds/gke/kernel-swap) 
   1. Using parameters 
    - export TYPE=n2-standard-16
    - export KERNEL=5.16
    - export NODES=5
    - export BOOTSTRAP=true
2. Once the cluster is up, ensure the kernel version, `kubectl get nodes -o wide` 
3. Label a single node with `app=workload` this will be where Nighthawk runs, and we will steer all other pods to other nodes.
4. `cilium hubble enable` Ensure hubble is enabled and cilium doesn't have any errors `cilium status`
5. `kubectl create -f https://gist.githubusercontent.com/jtaleric/b786331b9c36b122b52aac666d9b2a64/raw/ed9a8afcfc117caeb1b091e7ee4b42b2a6a0558a/sm-benchmark-deployment.yaml`
6. Note the svc ip for the productpage that was deployed
7. Exec into the load pod `kubectl exec -it <pod> - sh`
8. Ensure connectivity to the svc ip is working with a simple 10sec test `nighthawk_client --duration 10 --simple-warmup --rps 1000 --connections 1 --concurrency auto -v error http://<svc ip>:<port>/` 
*Good Output:*
```
Counter                                 Value       Per second
benchmark.http_2xx                      7631        763.10
```
*Bad Output:* 
```
Counter                                 Value       Per second
cluster_manager.cluster_added           4           inf
```
1. ```for n in {1..3}; do k exec -it <load pod> -- nighthawk_client --duration 60 --simple-warmup --rps 1000 --connections 1 --concurrency auto -v error http://<svc ip>:<port>/ --output-format fortio | tee baseline-$n.json; done```
   
   > We will run with a single connection and attempt to achieve 1000rps. Since we are testing in mainly cloud environments. This can be adjusted if you are running in a more controlled deployment such as bare- metal. 
#### Metrics
##### CPU
##### Memory