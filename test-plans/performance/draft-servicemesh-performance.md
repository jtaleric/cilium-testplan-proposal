# Cilium Service Mesh Performance Test Plan

## Frequency we will execute this test plan
TBD

## Test Plan Description

Each of these tests will have multiple metrics we will collect and compare. 

| Workload | Main Metric | Secondary Metric |
|----------|-------------|------------------|
| Stream   | Throughput (Mbps) | CPU usage  |
| RR       | Latency (ms) | CPU usage       |

> CPU usage will be for the Cilium pods as well as the overall node CPU usage. We will use Prometheus to collect this information. 

## System Under Test (SUT) definition

### Tools to be deployed on the SUT

 - Prometheus 
*How do we install prom?*\
`helm install prometheus prometheus-community/prometheus --namespace prometheus  --namespace prometheus --create-namespace`

   We will use Prom to monitor CPU/Mem/IO of the cilium pods, the test pods and the nodes.
 
- Grafana
*How do we install Grafana?*\
`git clone https://github.com/cloud-bulldozer/performance-dashboards; cd performance-dashboards; make; cd dittybopper; ./k8s-deploy.sh`

   **WIP but having a Cilium specific dashboard showing Overall System metrics + Cilium Specific Metrics.  https://github.com/jtaleric/performance-dashboards/commit/1ac3a9b21c33c3dc2516f21428ebd4ea4a6396c1#diff-b9c0833d120841436640df16492f6e79f8e99e25232047aadcb63bd4378193aeR339-R375 

- Nighthawk 
 
### Managed Platform testing
Service Mesh Performance testing will be in a single Region and Zone.

We will use `cilium install` which will capture SUT details such as the platform we are running on, to help build the most performant configuration for Cilium to run. 

| IaaS | SaaS | Controller Sizes | Node Sizes |  Region | Zone |
|------|------|------------------|------------|---------|------|
| GCP | GKE | n/a | m5.large | us-west-2 |

> Comment : Need to ensure the GCP size is close to the same CPU/Bandwidth other clouds 

## Scenarios

### Baseline - No L7 Policy or Ingress
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

### Cilium Configuration(s)
## Pass / Fail Criteria
## CPU overhead for Observability
This needs some more investigation to establish a baseline. 

## Test Cases
### 1.1 
#### Steps to reproduce
#### Metrics
