// ----------------------------------------
// Parameter declaration
@description('Tags to be deployed with this application')
param tagValues object

@description('Name of the shared virtual network to associate the Private DNS too')
param sharedVirtualNetwork string


// ----------------------------------------
// Resource declaration
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: sharedVirtualNetwork
}

resource privateEndpointDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.documents.azure.com'
  location: 'global'
  tags: tagValues
  properties:{}

}

resource privateEndpointLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'privatelink.documents.azure.com/${uniqueString(virtualNetwork.id)}'
  location: 'global'
  tags: tagValues
  properties:{
    virtualNetwork:{
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
  dependsOn:[
    privateEndpointDNS
  ]
}


output zoneId string = privateEndpointDNS.id
