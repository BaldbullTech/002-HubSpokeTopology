param location string = 'westus2'
// Components
// Virtual Networks        - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks?pivots=deployment-language-bicep
// Peerings                - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/virtualnetworkpeerings?pivots=deployment-language-bicep
// Network Security Groups - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups?pivots=deployment-language-bicep
// Log Analytics Workspace - https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?pivots=deployment-language-bicep
// Diagnostic Settings     - https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings?pivots=deployment-language-bicep
// Public IP (Bastion)     - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/publicipaddresses?pivots=deployment-language-bicep
// Bastion Service         - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/bastionhosts?pivots=deployment-language-bicep
// Bastion Service NSG Info- https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg
// Firewall                - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/azurefirewalls?pivots=deployment-language-bicep



resource logCentralLogging 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-CentralLogging'
  location: location
}

resource nsgSpoke 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-spoke-default'
  location: location
  properties: {}
}

resource nsgBastion 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-bastion'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          description: 'Allows users in via HTTPS / 443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          description: 'Service Requirement for the Gateway Manager'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancerInbound'
        properties: {
          description: 'Service Requirement for Load Balancer Health Probes'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostToHostInbound'
        properties: {
          description: 'Service Requirement for Host to Host communication'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'Deny anything else inbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      // Build Outbound rules per the link above
      {
        name: 'AllowSSHtoVNETOutbound'
        properties: {
          description: 'Allow SSH out to the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '22'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowRdpToVnetOutbound'
        properties: {
          description: 'Allow RDP out to the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          description: 'Service Requirement for control plane'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostToHostOutbound'
        properties: {
          description: 'Service Requirement allowing host to host communication'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionCertValidationOutbound'
        properties: {
          description: 'Service Requirement allowing session and certificate validation'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          description: 'Deny anything else outbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource hubnetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.1.0/24'
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.10.1.0/27'
          networkSecurityGroup: {
            id: nsgBastion.id
          }
        }
      }
      {
        name: 'subnet-vpngateway'
        properties: {
          addressPrefix: '10.10.1.32/27'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.10.1.64/26'
        }
      }
    ]
  }

  resource bastionSubnet 'subnets' existing = {
    name: 'AzurebastionSubnet'
  }
  
  resource firewallSubnet 'subnets' existing = {
    name: 'AzureFirewallSubnet'
  }
}

resource spokenetwork1 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-spoke1'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.2.0/24'
      ]
    }
    subnets: [
      {
        name: 'subnet-spoke1-default'
        properties: {
          addressPrefix: '10.10.2.0/27'
          networkSecurityGroup: {
            id: nsgSpoke.id
          }
        }
      }
    ]
  }
}

resource spokenetwork2 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-spoke2'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.3.0/24'
      ]
    }
    subnets: [
      {
        name: 'subnet-spoke2-default'
        properties: {
          addressPrefix: '10.10.3.0/27'
          networkSecurityGroup: {
            id: nsgSpoke.id
          }
        }
      }
    ]
  }
}

resource peerToSpoke1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-hub-to-spoke1'
  parent: hubnetwork
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: spokenetwork1.id
    }
  }
}

resource peerFromSpoke1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-spoke1-to-hub'
  parent: spokenetwork1
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: hubnetwork.id
    }
  }
}

resource peerToSpoke2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-hub-to-spoke2'
  parent: hubnetwork
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: spokenetwork2.id
    }
  }
}

resource peerFromSpoke2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-spoke2-to-hub'
  parent: spokenetwork2
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: hubnetwork.id
    }
  }
}

resource diagSettingHub 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics-Hub'
  scope: hubnetwork
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
    metrics:[
      {
        category: 'allMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
    workspaceId: logCentralLogging.id
  }
}

resource pipBastion 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-VastionService'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastionInstance 'Microsoft.Network/bastionHosts@2022-07-01' ={
  name: 'bastion-hubnetwork'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastionConfigs'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipBastion.id
          }
          subnet: {
            id: hubnetwork::bastionSubnet.id
          }
        }
      }
    ]
  }
}

resource pipFirewall 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-Firewall'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: 'policy-firewall'
  location: location
  properties: {
    sku:{
      tier: 'Standard'
    }
    threatIntelMode: 'Deny'
    threatIntelWhitelist: {
      fqdns: []
      ipAddresses: []
    }
    insights: {
      isEnabled: true
      retentionDays: 30
      logAnalyticsResources: {
        defaultWorkspaceId: {
          id: logCentralLogging.id
        }
      }
    }
    intrusionDetection: null
    dnsSettings: {
      servers: []
      enableProxy: true
    }
  }

  resource defaultNetworkRuleCollectionGroup 'ruleCollectionGroups@2022-07-01' = {
    name: 'DefaultNetworkRuleCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          name: 'org-wide-allow'
          priority: 100
          action: {
            type: 'Allow'
          }
          rules:[
            {
              ruleType: 'NetworkRule'
              name: 'DNS'
              description: 'Allow DNS outbound'
              ipProtocols: [
                'UDP'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
              destinationAddresses: [
                '*'
              ]
              destinationIpGroups: []
              destinationFqdns: []
              destinationPorts: [
                '53'
              ]
            }
          ]
        }
      ]
    }
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: 'fw-hub'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: pipFirewall.name
        properties: {
          subnet:{
            id: hubnetwork::firewallSubnet.id
          }
          publicIPAddress: {
            id: pipFirewall.id
          }
        }
      }
    ]
  }
}

resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics-firewall'
  scope: firewall
  properties: {
    workspaceId: logCentralLogging.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
