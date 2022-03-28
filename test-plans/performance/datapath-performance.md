# Cilium Datapath Performance Test Plan

## Test Plan Description
Datapath Performance will cover 

- TCP / UDP Stream
- TCP / UDP RR
- TCP CRR

Each of these tests will have multiple metrics we will collect and compare. 

| Workload | Main Metric | Secondary Metric |
|----------|-------------|------------------|
| Stream   | Throughput (Mbps) | CPU usage  |
| RR       | Latency (ms) | CPU usage       |
| CRR      | Latency (ms) | CPU usage       |

> CPU usage will be for the Cilium pods as well as the overall node CPU usage. We will use Prometheus to collect this information. 

## System Under Test (SUT) definition

### Tools to be deployed on the SUT

<details>
 <summary> Expand section </summary>

 - Prometheus 
*How do we install prom?*\
`helm install prometheus prometheus-community/prometheus --namespace prometheus  --namespace prometheus --create-namespace`

   We will use Prom to monitor CPU/Mem/IO of the cilium pods, the test pods and the nodes.
 
- Grafana
*How do we install Grafana?*\
`git clone https://github.com/cloud-bulldozer/performance-dashboards; cd performance-dashboards; make; cd dittybopper; ./k8s-deploy.sh`

   **WIP but having a Cilium specific dashboard showing Overall System metrics + Cilium Specific Metrics.  https://github.com/jtaleric/performance-dashboards/commit/1ac3a9b21c33c3dc2516f21428ebd4ea4a6396c1#diff-b9c0833d120841436640df16492f6e79f8e99e25232047aadcb63bd4378193aeR339-R375 

- benchmark-operator
*How do we install benchmark-operator?*\
 `git clone http://github.com/cloud-bulldozer/benchmark-operator;cd benchmark-operator;cd chart/benchmark-operator;helm install benchmark-operator . -n benchmark-operator --create-namespace`
 
    More background on how we use benchmark-operator : https://hackmd.io/DfCvLvMxR66a7iyCDN_Vng

- ciium-cli
 
 </details>
 
### Managed Platform testing
Datapath Performance testing will be in a single Region and Zone.

We will use `cilium install` which will capture SUT details such as the platform we are running on, to help build the most
performant configuration for Cilium to run. 

| IaaS | SaaS | Controller Sizes | Node Sizes |  Region | Zone |
|------|------|------------------|------------|---------|------|
| AWS  | EKS  | n/a | m5.2xlarge | us-west-2 |
| GCP | GKE | n/a | m5.large | us-west-2 |
| Azure | AKS | n/a | Standard_D2_v5 | uswest2 |

> Comment : Need to ensure the GCP size is close to the same CPU/Bandwidth other clouds 

### Non-Managed Platform testing
In this section, we will discuss Enterprise / On-prem deployments. There will also be specific scenario's that we only test in non-managed/baremetal platforms. Example scenario's would be high rate packet-per-second testing (pps), using DPDK tools such as trex/moongen. 

| IaaS | SaaS | Controller Sizes | Node Sizes |  Region |
|------|------|------------------|------------|---------|
| AWS | OpenShift | m5.2xlarge | m5.2xlarge | us-west-2 |
| Baremetal | OpenShift | [Server type] | [Server type] | n/a |

> Comment : Baremetal machines we have today are not sutabile to automate against, they lack IPMI / BMC. We could consider Packet.net or something similar.

## Scenarios

### Cilium Configuration(s)

| Scenario name | Hubble        | no-conntrack-iptables | bandwidthManager |
|---------------|---------------|-----------------------|-----------|
| Baseline       | | | |
| Observibility | ✅ | | |
| Performance   | | ✅ | ✅ |
| Performance w/ Observibility | ✅ |✅ | ✅ |

> Questions : Are there other configuartion options we need for the performance config

### Pod Scenarios 
<details open>
  <summary>Expand section</summary>
 
### hostNetwork
  ```mermaid
    graph LR;
      subgraph NodeA
        ClientPod
      end
      subgraph NodeB
        ServerPod
      end
 ```

### Same node 
 ```mermaid
    graph LR;
      subgraph Node
        ClientPod===ServerPod
      end
 ```
 
### Across Node
  ```mermaid
    graph LR;
      ClientPod==Tunnel/Direct/Platform Dependent==>ServerPod
      subgraph NodeA
        ClientPod
      end
      subgraph NodeB
        ServerPod
      end
 ```
 
 ### Across Node w/ Service
  ```mermaid
    graph LR;
      ClientPod==Tunnel/Direct/Platform Dependent==>Service
      subgraph NodeA
        ClientPod
      end
      subgraph NodeB
        Service====>ServerPod
      end
 ```
 
 </details>

## Pass / Fail Criteria
Each Platform has different bandwidth guidelines for each instance size. 

## Raw Throughput / Latency
**across node** Performance will depend on if Cilium can run in non-tunneling mode. If tunneling mode is the only option, there is a tax for tunnel encap. 

| Scenario | Message size | % Expected |
|----------|--------------|------------|
| hostNetwork | 16384 | ~100% of instance bandwidth |
| same node | 16384 | > 100% of instnace bandwidth |
| across node | 16384 | 50-70% of instance bandwidth| 

## CPU overhead for Observability
This needs some more investigation to establish a basline. 

## Test Cases
### 1.1 Baseline hostNetwork tests
<details>
  <summary>Expand section</summary>
 
#### Description
Using `benchmark-operator` 
```yaml
# within args:
run_id: "rook-eks-cilium-01" # name the test
hostnetwork: true # Bypass pod network, pass nic to pod
serviceip: false # Place the server behind a service
debug: false
pin: true # set the pods on specific nodes
pin_server: "<server>" # node to pin the server to
pin_client: "<client>" # node to pin the client to
samples: 3 # Number of samples to collect
pair: 1 # Pairs of server/clients to run concurrently
nthrs: # list [ 1, 4, 8] - Multiple test iterations with different number of threads
  - 1
protos: # protocols [tcp, udp]
  - tcp
  - udp
test_types: # tests to execute [stream, rr]
  - stream
  - rr
sizes:
  - 64
  - 1024 
  - 16384
runtime: 30
```

#### Metrics
- Benchmark Result Measured in throughput and latency
- CPU / Memory of node during duration of test 
 </details>
 
### 1.2 Baseline same node tests
<details>
  <summary>Expand section</summary>
 
#### Description
Using `benchmark-operator` 
```yaml
# within args:
run_id: "" # name the test
hostnetwork: false # Bypass pod network, pass nic to pod
serviceip: false # Place the server behind a service
debug: false
pin: true # set the pods on specific nodes
pin_server: "<server>" # node to pin the server to
pin_client: "<client>" # node to pin the client to
samples: 3 # Number of samples to collect
pair: 1 # Pairs of server/clients to run concurrently
nthrs: # list [ 1, 4, 8] - Multiple test iterations with different number of threads
  - 1
protos: # protocols [tcp, udp]
  - tcp
  - udp
test_types: # tests to execute [stream, rr]
  - stream
  - rr
sizes:
  - 64
  - 1024 
  - 16384
runtime: 30
```

#### Metrics
- Benchmark Result Measured in throughput and latency
- CPU / Memory of node during duration of test 
 </details>

### 1.3 Baseline across node tests
<details>
  <summary>Expand section</summary>
 
#### Description
Using `benchmark-operator` 
```yaml
# within args:
run_id: "" # name the test
hostnetwork: false # Bypass pod network, pass nic to pod
serviceip: false # Place the server behind a service
debug: false
pin: true # set the pods on specific nodes
pin_server: "<server>" # node to pin the server to
pin_client: "<client>" # node to pin the client to
samples: 3 # Number of samples to collect
pair: 1 # Pairs of server/clients to run concurrently
nthrs: # list [ 1, 4, 8] - Multiple test iterations with different number of threads
  - 1
protos: # protocols [tcp, udp]
  - tcp
  - udp
test_types: # tests to execute [stream, rr]
  - stream
  - rr
sizes:
  - 64
  - 1024 
  - 16384
runtime: 30
```

#### Metrics
- Benchmark Result Measured in throughput and latency
- CPU / Memory of node during duration of test 
 </details>
