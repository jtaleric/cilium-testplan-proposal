# Cilium Test-plan Proposal ( CTP ) 

# FAQ

## Should we have a CTP with every CFP?

No.

With each Cilium Feature Proposal there is no need for a Cilium Testplan Proposal (CTP). There should be testing (unit) with a feature proposal, but not a Cilium Testplan Proposal.

## When would I write a CTP?

Cilium Testplan Proposals should be considered end-to-end testing for a very specific area of focus. Areas of focus could be:
- **integration** *ex: How well does Cilium work with different IPAM solutions*
- **performance** *ex: What sort of dataplane performance can we expect out of Cilium on AWS with m5.large worker nodes*
- **upgrades** *ex: Under a defined circumstance, perform an upgrade from version x to version y*

 The person preparing the testplan should be considering multiple dimensions, for example the platform (baremetal, aws, gcp, etc), platform configuration (networking topology, k8s distro, kernel, etc), and Cilium configuration. The reader of the CTP should be able to recreate the SUT (System Under Test) as well as the test execution.

## What frequency should a CTP be executed?

Each CTP should determine the frequency of which it is executed. Some might be before each release, some might be more frequently. For example, it makes sense to run control-plane and data-plane performance tests more frequently than before a release, as we would want to establish which PR could of introduced a regression.

| Workflow | Unit Testing | Conformance Testing | CTP |
|----------|--------------|----------------------|---|
| Pull Request |  ✅ | ✅ | Maybe |
| Weekly | ✅ | ✅ | Maybe|
| Release promotion |  ✅ | ✅ |✅ |
