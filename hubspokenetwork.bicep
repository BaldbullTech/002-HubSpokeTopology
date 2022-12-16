param location string = 'westus2'
// build the hub network

// Resource reference links

// Microsoft.Network/virtualNetworks
//  https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks?pivots=deployment-language-bicep
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
        id: 'subnet-bastion'
        name: 'subnet-bastion'
        properties: {
          addressPrefix: '10.10.1.1/27'
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
}

// spoke 1
resource spokenetwork1 'Microsoft.Network/virtualnetworks@2015-05-01-preview' = {
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
          addressPrefix: '10.10.2.1/27'
        }
      }
    ]
  }
}

// spoke 2
resource spokenetwork2 'Microsoft.Network/virtualnetworks@2015-05-01-preview' = {
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
          addressPrefix: '10.10.3.1/27'
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

// NSG
resource nsgSpokes 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-spokes-default'
  location: location
  properties: {
    
  }
}
