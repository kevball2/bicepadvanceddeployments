targetScope = 'subscription'

// ----------------------------------------
// Parameter declaration
@description('Location for the resourceGroup')
param location string

@description('Current Environment for deployment')
param env string 

@description('Cosmo DB Settings')
param cosmosDbProperties array

@description('Cosmo DB container Settings')
param containerProperties array

@description('Returns the current date for Tag updates')
param currentDate string = utcNow('yyyy-MM-dd')

@description('Application being deployed')
param product string

@description('Production flag')
param isProd bool

@description('Allowed IP Addresses to add to Comsos firewall')
param allowedIpAddress array

@description('Allowed Virtual Networks to add to Comsos firewall')
param allowedVirtualNetworks array

@description('Properties for deploying action group')
param actionGroupProperties object

@description('Deployment locations for Comsos instances')
param cosmoLocations array

@description('Dictionary of deployment regions with shortname')
param locationList object

@description('Application component being deployed')
param component string

var tagValues = {
  createdBy: 'BicepData CI-CD'
  environment: env
  deploymentDate: currentDate
  product: product
}

// ----------------------------------------
// Variable declaration
var actionGroupName = 'ag-${product}-${component}-${locationShortName}'
var actionGroupShortName = '${substring(product, 0, 2)}${component}${env}'
var locationShortName = locationList[location]
var resourceGroupName = 'rg-${product}-${component}-${env}-${locationShortName}'
var sharedResourceGroup = 'rg-${product}-shared-${env}-${locationShortName}'
var sharedVirtualNetwork = 'vnet-${product}-shared-${env}-${locationShortName}'
var allowedVnetIds = [for i in range(0, length(allowedVirtualNetworks)):{
  id: allowedVnets[i].id
  }]
  

// ----------------------------------------
// Resource declaration
resource resourceGroup_r 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: location 
  tags: tagValues 
  properties:{
    
  }
}


module actionGroup 'modules/actiongroup.bicep' = {
  scope: resourceGroup_r
  name: 'ag-${actionGroupName}-dp'
  params: {
    actionGroupName: actionGroupName
    actionGroupShortName: actionGroupShortName
    actionGroupProperties: actionGroupProperties
  }
}


resource allowedVnets 'Microsoft.Network/virtualNetworks@2021-02-01' existing = [for vnet in allowedVirtualNetworks:{
  name: vnet.vnet
  scope: resourceGroup(vnet.resourceGroupName)
}]



module privateEndpointDNS 'modules/privateEndPointDNS.bicep' = {
  scope: resourceGroup(sharedResourceGroup)
  name: 'Cosmos-DnsZone-${env}-${locationShortName}-deployment' 
  params: {
    tagValues: tagValues
    sharedVirtualNetwork: sharedVirtualNetwork
  }
}




module CosmosDb 'modules/cosmos.bicep' = [for db in cosmosDbProperties: {
  name: 'cosmos-${db.cosmosAccountName}-${env}-${locationShortName}deploy'
  scope: resourceGroup_r
  params:{
  locationShortName: locationShortName
  cosmosAccountName:  db.cosmosAccountName
  SqlDatabaseName: db.sqlDatabaseName
  location:location
  containerProperties: containerProperties
  env: env
  product: product
  isProd: isProd
  tagValues: tagValues
  privateDnsZoneId: privateEndpointDNS.outputs.zoneId
  allowedIpAddress: allowedIpAddress
  allowedVirtualNetworks: allowedVirtualNetworks
  sharedVirtualNetwork: sharedVirtualNetwork
  actionGroupName: actionGroupName
  actionGroupResourceGroup: resourceGroupName
  allowedVnetIds: allowedVnetIds
  cosmoLocations: cosmoLocations
    }
    dependsOn:[
      allowedVnets
    ]
  }]
