# Various Azure Resource Graph Queries

| Name | Description |  
|----------|-------------|
| kubernetes-core-count.kql |  Resturns the core count from  microsoft.containerservice/managedclusters |
| loadBalancersWithPipsAndExposedPortsViaLbRules.kql | Lists load balancers with public Ip Addresses and exposed management ports via load balancing rules |
| loadBalancersWithPipsAndExposedPortsViaNatRules.kql | Lists load balancers with public Ip Addresses and exposed management ports via inbound NAT rules |
| loadBalancersWithPipsAndExposedPortsViaNatRulesToVms.kql | Lists load balancers with public Ip Addresses and exposed management ports via inbound NAT rules and the associated virtual machine |
| nicsWithNoNSG.kql | Lists NICs without Network Security Groups |
| nsgInboundExposedMangementPorts.kql | Lists NSGs with exposed management ports to the internet |
| vmNetworkInventory.kql | Lists virtual machines, associated nics, public ip addresses, nsgs, subnets, and vnets |
| vmsWithBasicPipsAndNoNSG.kql | List virtual machines with Basic Public IP Addresses and No Network Security Groups. Basic Public IP Addresses are open to inbound traffic by default | 
| vmsWithPips.kql | List virtual machines with Public IP Addresses | 
| vmsWithPipsAndNSG.kql | List virtual machines with Public IP Addresses and Network Security Groups |
| vmsWithPipsAndNoNSG.kql | List virtual machines with Public IP Addresses and No Network Security Groups |
