param env string = 'dev'
param product string = 'bicep'
param location string
param IPaddressPrefixes array
param subnetname string
param subnetIPPrefix string
param Delegations string
param ServiceEndpoint string

// ----------------------------------------
// Variable declaration
var vnetName = 'vnet-${product}-${env}-${location}'
var subnetNameFull = 'snet-${subnetname}-${env}-${location}'



// ----------------------------------------
// Resource declaration

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: IPaddressPrefixes
    }
    subnets: [
      {
      name: subnetNameFull
      properties: {
        addressPrefix: subnetIPPrefix
        serviceEndpoints: [
          {
            service: ServiceEndpoint
            locations: [
              '*'
            ]
          }
        ]
        delegations: [
          {
            name: 'keyvaultDelegation'
            properties:{
              serviceName: Delegations
            }
             
          }
        ]
         
      }
    }
  ]
  }
}



// ----------------------------------------
// Resource Outputs
output virtualNetworkId string = virtualNetwork.id

// resource virtualNetworkDiag 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
//   name: 'diag-${vnetName}'
//   scope: virtualNetwork
//   properties: {
//     workspaceId: workspaceId
//     logs: [
//       {
//         category: 'VMProtectionAlerts'
//         enabled: true
//         retentionPolicy: {
//           days: 30
//           enabled: false
//         }
//       }
//     ]
//     metrics: [
//       {
//         timeGrain: 'PT5M'
//         enabled: true
//         retentionPolicy: {
//           enabled: false
//           days: 30
//         }
//       }
//     ]
//   }
// }
