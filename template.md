# Cilium \<Area of focus\> Test Plan

## Test Plan Description
Highlevel explaination of what this test plan will cover.

Describe the metrics that will be captured.

## System Under Test (SUT) definition

### Tools to be deployed on the SUT
Describe tools that will be used to capture metrics / information
 
### Managed Platform testing
Will the testing involve managed k8s? (EKS, AKS, GKE)

### Non-Managed Platform testing
Will the testing involve non-managed k8s, like OpenShift / Baremetal / Etc.

## Scenarios

### Cilium Configuration(s)

Example configuration(s) :

| Scenario name | Hubble        | no-conntrack-iptables | bandwidthManager |
|---------------|---------------|-----------------------|-----------|
| Baseline       | | | |
| Observibility | ✅ | | |
| Performance   | | ✅ | ✅ |
| Performance w/ Observibility | ✅ |✅ | ✅ |

## Pass / Fail Criteria
Provide information for pass/fail criteria for tests which this testplan will cover.

## Test Cases
### 1.1 Baseline Test 
#### Description
#### Metrics
#### Pass/Fail  
