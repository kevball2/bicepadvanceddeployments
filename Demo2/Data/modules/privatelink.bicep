// ----------------------------------------
// Parameter declaration
@description('Name of the private endpoint')
param endpointName string

@description('Location of resource deployment')
param location string

@description('Id of the PrivateLink service')
param privateLinkServiceId string

@description('Name of the subnet to create private endpoing on')
param subnetName string

@description('Sub resource ids for private endpoint ')
param targetSubResource array

@description('Tags for resource deployment')
param tagValues object

@description('Id for private DNS zone to create entry for private endpoint')
param privateDnsZoneId string

@description('Name of the shared virtual network that has the private endpoints subnet')
param sharedVirtualNetwork string

@description('Id of the Logs workspace')
param workspaceId string


// ----------------------------------------
// Variable declaration
var privateEndpointName = 'pe-${endpointName}'
var privateEndpointDiagName = 'diag-${privateEndpointName}'


// ----------------------------------------
// Resource declaration
resource privateLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${sharedVirtualNetwork}/${subnetName}'
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointName
  tags: tagValues
  location: location
  properties:{
    privateLinkServiceConnections:[
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: targetSubResource
          privateLinkServiceConnectionState:{
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: privateLinkSubnet.id
    }
  }
}

module privatelinkDiags 'privatelinkDiags.bicep' = {
  name: 'dp-${privateEndpointName}-diag'
  params: {
    NICName: last(split(privateEndpoint.properties.networkInterfaces[0].id, '/'))
    workspaceId: workspaceId
    name: privateEndpointDiagName
  }
}


resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  name: '${privateEndpoint.name}/default'
  properties:{
    privateDnsZoneConfigs:[
      {
        name: 'privatelink-documents-azure-com'
        properties:{
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  } 
}
