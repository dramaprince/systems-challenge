# Systems Technical Challenge Resolution

## Background

Cabify is running an application under a load balancer and we would like to
provide High Availability for this application. Since the application is
stateless we have decided to run more than one instance of it.

We believe that putting the application inside a Docker container will be
helpful in order to run more than one instance on the same host. Then Consul
will help you with service discovery.

## Description of contents

This repository hosts roles for the deployment of the Cabify App in parallel instances. A succint description of each of the roles follows:

### Common

Installs some base packages and performs some maintenance tasks in the target host. 

### Consul

Deploys a Consul server locally. HA is not yet supported.
Since the deployment of Consul features a single node, this node will run as both server and client, and will be the one and single leader (no raft consensus).

All Consul data is persisted by default in /var/lib/consul

### HAProxy

Deploys a HAProxy load balancer. 

The load balancer dynamically adapts to new service addresses in Consul by querying the SRV records that Consul provides, thus forwarding traffic to newly instantiated cabify app services, which are registered in Consul. This feature was introduced to the stable branch of HAProxy in 1.8. More on the topic can be found [here](https://www.haproxy.com/blog/dns-service-discovery-haproxy/). The strategy does not require re-loading the configuration of HAProxy nor has any performance concern. The weak spot of this is the requirement of Consul availability for the correct functionality of the load balancer. Esentially, HAProxy won't boot if Consul is down, since even the resolvers had to be reconfigured to use Consul's. The risk can be easily mitigated by providing HA to Consul. 

### Cabify 

Builds and deploys the Cabify App docker image. This image, when in runtime, will request registration of a new service address, using the container IP. Bear in mind that since no private networking systems are defined, this container IP will be, by default, a local IP only accessible in the context of the machine itself. This means that for distributed systems a different networking solution, able to link containers from different hosts needs to be implemented so that all containers can reach each other in the cluster.

The deployment of a container orchestration system such as [kubernetes](https://kubernetes.io/) or [nomad](https://www.nomadproject.io/) is also heavily encouraged for future iterations of work in these roles.,

The service discovery is done through the use of a tool named registrator, which implements nothing else than a wrapper around all the HTTP queries that one could craft to alter Consul configuration. One could also modify the available source code of the Cabify app and implement the registrations there, which would be the most native, graceful and efficient way, but I wanted to be able to also provide a sane and robust procedure that does not imply modification of the main binary. This is often the scenario with thirdparty applications.

---

## Single Points of Failure

The provided code presents the following SPOFs:

- Single datacenter / machine. In its vagrant flavour, the provided code launches servers in a single VM, in a single machine. If the VM failed, or the machine was rebooted for any reason, a downtime would be granted. There is no possibility to bounce the containers to a different host with this approach. Again, a container orchestration system on a distributed set of nodes would be the way to go to resolve this issue. This SPOF also englobes all network issues related to the location of the deployed contents (the network link to the servers should be redundant, and it's not the case).

- Consul is not running in HA; it's running in a single agent, in a single machine, and it should instead conform a group of agents spread amongst machines and datacenters. The failure of this component would imply that HAProxy can no longer resolve the Cabify Backend addresses when the TTL expires, since it's through Consul's resolver that HAProxy performs those resolutions. 

- HAProxy is not running in HA. As pointed out before, a classic solution for this issue is to bind HAProxy to a public IP that is virtually bounced between hosts by using VRRP. This is done in practice by many tools, being the most known one keepalived. This would allow us to have an active/passive architecture in the load balancer.

---

## Upgrade strategy

The current state does not provide proper upgrade mechanisms out of the box. The best option would, and the simplest, would be to deploy a new, small pool of newly versioned containers of M replicas, and use the [weight feature of HAproxy to do a canary deployment](https://db-blog.web.cern.ch/blog/antonio-nappi/2018-01-haproxy-canary-deployment), pointing to this new pool. By defining a second server-template for the new cabify backend with a smaller weight, only a small percent of the incoming requests will be forwarded to these specific endpoints. After ensuring the viability of the newly released version, a new pool of N replicas would be deployed, to after that kill the pool with the old containers. The SRV record in consul linked to the Cabify service would simply be enlarged with more addresses, even though the server-template would still only create the N fixed amount of servers in HAProxy. After the old services are killed, the addresses be garbage collected by Consul and then HAProxy only points to the new services.

No execution in this process requires a restart in any services and, consequently, nothing implies a downtime for HAProxy or a big amount of the Cabify App replicas. Consul remains untouched.

In the ideal case of having to implement something to automate deployments and come to ideal terminations, I think that from the developers side it should be a matter of testing newly commited changes. From the systems perspective, upon new image creation, a release automating tool named [spinnaker](https://www.spinnaker.io/) would track the change and make attempts to deploy a canary to the cluster. Which would then be tested and deployed. [This article](https://cloud.google.com/solutions/continuous-delivery-spinnaker-kubernetes-engine) presents the perspective I would want to follow. The reasons behind using Spinnaker and not something else is the experience that I have while integrating it with Kubernetes. It just works, with way less abstraction than one could dream of while trying to implement this on his own.

Also Ideally, a container orchestration system would be in place and one wouldn't have to take care of all the individual containers, simplifying the entire process.

Regarding the reason behind thinking that canary deployments are a good idea or even necessary (since tests were already ran against a staging environment), I believe that the answer lies on the kind of workloads that you run. If they can be unpredictable or can lead to unexpected inputs (which may, or not may be the case of Cabify), I think that Canaries provide the security to know that even in real world conditions with all its randomness (which offers really high QA guaranteees), the new release works fine. 
However, there are also cases in which every behaviour is known (for example, in the case of having full control of the client, server and the dependencies of both), in which all the cases expected should be possible to test in a simple, staging environment with known tests, and canary releases would be kind of unneeded. This case would be resolved by a simple rolling update, which would deploy new replicas with the new version and make the load balancer point to the new replicas, removing the old ones in the process when the new replicas healthchecks' proved to work. No downtime would be required in this case, as well.

---

# TO - DOS

- Run a container orchestration system (with all the network implications, re: intercommunication of containers). Right now, the deployment of the cabify app workloads is done with ansible, and does not provide any guarantee of availability. This will eventually also free us of the host SPOF. This system should run in a multi-node infrastrucgture.

- Run Consul in HA. This frees us of this point of failure.

- Secure access to Consul. Right now everyone can write to it, so anyone could delete the Cabify service and produce a downtime.

- Run HAProxy in HA. The easiest way of doing so is by using a VRRP implementation such as [keepalived](http://www.keepalived.org/). This protocol would allow us to have an active and a passive replica of the load balancer, and in the event of the loadbalancer IP becoming non-responsive (due to issues in the load balancer), would make the passive copy of HAProxy go active.

- Move Cabify App image builds to a proper CI system, such as Jenkins or any other tool of choice.

- Implement a firewall role, that protects the access to most ports from potentially malitious requests in the hosts. Better if leveraged to CSP tooling if available.
