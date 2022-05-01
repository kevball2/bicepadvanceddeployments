// ----------------------------------------
// Parameter declaration
@description('Environment for deployment')
param env string

@description('Azure region for deployment.')
param location string

@description('A list of required and optional subnet propeties.')
param subnets array

@description('Virtual Network Address Range')
param addressPrefixes array

@description('Tag values to be applied to resources in this deployment')
param tagValues object

@description('Group name is created based on the product name and component being deployed')
param groupName string

@description('Short name for the deployment region')
param locationShortName string

@description('Custom DNS servers for Virtual Network')
param dnsServers array




// ----------------------------------------
// Variable declaration
var vnetName = 'vnet-${groupName}-${env}-${locationShortName}'
var nsgSecurityRules = json(loadTextContent('../parameters/nsg-rules.json')).securityRules
var nsgName = 'nsg-${groupName}-${env}-${locationShortName}'

var dnsServers_var = {
  dnsServers: array(dnsServers)
}


// ----------------------------------------
// Resource declaration
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: nsgSecurityRules
  }
}


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  tags: tagValues
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: !empty(dnsServers) ? dnsServers_var : null
    subnets: [for subnet in subnets: {
      name: 'snet-${subnet.name}-${env}-${locationShortName}'
      properties: {
        addressPrefix: subnet.subnetPrefix
        serviceEndpoints: contains(subnet, 'serviceEndpoints') ? subnet.serviceEndpoints : []
        delegations: contains(subnet, 'delegation') ? subnet.delegation : []
        networkSecurityGroup: {
          id: networkSecurityGroup.id
        }
        privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies') ? subnet.privateEndpointNetworkPolicies : null
        privateLinkServiceNetworkPolicies: contains(subnet, 'privateLinkServiceNetworkPolicies') ? subnet.privateLinkServiceNetworkPolicies : null
      }
    }]
  }
}


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
