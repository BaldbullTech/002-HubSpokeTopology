param location string = 'westus2'
// Components
// Virtual Networks        - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks?pivots=deployment-language-bicep
// Peerings                - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/virtualnetworkpeerings?pivots=deployment-language-bicep
// Network Security Groups - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups?pivots=deployment-language-bicep
// Log Analytics Workspace - https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?pivots=deployment-language-bicep
// Diagnostic Settings     - https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings?pivots=deployment-language-bicep
// Azure Monitor
// Public IP (Bastion)     - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/publicipaddresses?pivots=deployment-language-bicep
// Bastion Service         - https://learn.microsoft.com/en-us/azure/templates/microsoft.network/bastionhosts?pivots=deployment-language-bicep
// Firewall
// VPN Gateway


// Network Security Group
resource nsgSpokes 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-spokes-default'
  location: location
  properties: {
    
  }
}
// Network Security Group - Bastion
// Reference: https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg
resource nsgBastion 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-bastion'
  location: location
  properties: {
    securityRules: [
      // build Inbound rules first per reference link above
      {
        name: 'AllowHttpsInbound'
        properties: {
          description: 'Allows users in via HTTPS 443'
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

// Log Analytics Workspace
resource logCentralLogging 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-CentralLogging'
  location: location

}

// Virtual Network - Hub
resource hubnetwork 'Microsoft.Network/virtualnetworks@2015-05-01-preview' = {
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
          addressPrefix: '10.10.1.1/27'
          networkSecurityGroup: {
            id: nsgBastion.id
          }
        }
      }
      {
        id: 'subnet-vpngateway'
        name: 'subnet-vpngateway'
        properties: {
          addressPrefix: '10.10.1.32/27'
        }
      }
      {
        id: 'subnet-firewall'
        name: 'subnet-firewall'
        properties: {
          addressPrefix: '10.10.1.64/26'
        }
      }
    ]
  }

  resource bastionSubnet 'subnets' existing = {
    name: 'AzureBastionSubnet'
  }
}

// Virtual Network - Spoke 1
resource spokenetwork1 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-spoke1'
  location: location
  dependsOn: [
    hubnetwork
  ]
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.2.0/24'
      ]
    }
    subnets: [
      {
        id: 'subnet-spoke1-default'
        name: 'subnet-spoke1-default'
        properties: {
          addressPrefix: '10.10.2.0/27'
          networkSecurityGroup: {
            id: nsgSpokes.id
          }
        }
      }
    ]
  }
}

// Virtual Network - Spoke 2
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
        id: 'subnet-spoke2-default'
        name: 'subnet-spoke2-default'
        properties: {
          addressPrefix: '10.10.3.0/27'
          networkSecurityGroup: {
            id: nsgSpokes.id
          }
        }
      }
    ]
    
  }
}

// peer spoke 1 --> hub
resource peerFromSpoke1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-spoke1-to-hub'
  parent: spokenetwork1
  dependsOn: [
    hubnetwork, spokenetwork1
  ]
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: hubnetwork.id
    }
  }
}

// peer spoke 2 --> hub
resource peerFromSpoke2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-spoke2-to-hub'
  parent: spokenetwork2
  dependsOn: [
    hubnetwork, spokenetwork2
  ]
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: hubnetwork.id
    }
  }
}

// peer hub --> spoke 1
resource peerToSpoke1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-hub-to-spoke1'
  parent: hubnetwork
  dependsOn: [
    hubnetwork, spokenetwork1
  ]
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: spokenetwork1.id
    }
  }
}

// peer hub --> spoke 2
resource peerToSpoke2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-hub-to-spoke2'
  parent: hubnetwork
  dependsOn: [
    hubnetwork, spokenetwork2
  ]
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: spokenetwork2.id
    }
  }
}

// Diagnostic Settings - Hub VNET
resource diagSetHub 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics-Hub'
  scope: hubnetwork
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 1
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'allMetrics'
        enabled: true
        retentionPolicy: {
          days: 1
          enabled: true
        }
      }
    ]
    workspaceId: logCentralLogging.id
  }
}

// Public IP - For Bastion Service
resource pipBastion 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-BastionService'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Bastion
resource bastion 'Microsoft.Network/bastionHosts@2022-07-01' = {
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
