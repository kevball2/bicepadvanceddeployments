targetScope = 'subscription'

// ----------------------------------------
// Parameter declaration
@description('Azure region for deployment')
param location string

@description('Dictionary of deployment regions with shortname')
param locationList object

@description('Environment for deployment')
param env string

@description('Gets the current date in the format below. Do not Change!')
param currentDate string = utcNow('yyyy-MM-dd')

@description('Application component being deployed')
param component string

@description('Application being deployed')
param product string

@description('Role assignments for keyvault deployment')
param roleAssignments array

@description('Current Tenant Id to be used in deployment')
param tenantId string = tenant().tenantId

@description('Properties for keyvault deployment')
param keyVaultProperties object 

@description('Properties for Frontdoor deployment')
param frontDoorProperties object

@description('Properties of Logs Workspace deployment')
param workspaceProperties object

@description('IP range used for shared virtual network deployment')
param addressPrefixes array

@description('Subnets to be deployed with shared virtual network')
param subnets array

@description('Properties for deploying action group')
param actionGroupProperties object

@description('Custom DNS servers for Virtual Network')
param dnsServers array

// ----------------------------------------
// Variable declaration
var locationShortName = locationList[location]
var groupName = '${product}-${component}'
var actionGroupName = 'ag-${product}-${component}-${locationShortName}'
var actionGroupShortName = '${substring(product, 0, 2)}${component}${env}'
var environmentName = '${product}-${component}-${env}-${locationShortName}'
var workspaceName = 'log-${environmentName}'
var appInsightsName = 'appi-${environmentName}'
var keyVaultName = 'kv${product}${component}${env}${locationShortName}'
var frontDoorName = 'fd-${product}-${component}-${env}'
var resourceGroupName = 'rg-${environmentName}'
//var virtualNetworkRules = [for vnet in virtualNetworks: '${vnet}-${env}-${location}'] 
var firewallPolicy = json(loadTextContent('./demoFirewallPolicy.json'))

var tagValues = {
  createdBy: 'VaccineSharedServices CI-CD'
  environment: env
  deploymentDate: currentDate
  product: product
}


// ----------------------------------------
// Resource declaration
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: location 
  tags: tagValues 
  properties:{
    
  }
}

module actionGroup 'modules/actionGroup.bicep' = {
  scope: resourceGroup
  name: '${actionGroupName}-${environmentName}-dp'
  params: {
    actionGroupName: actionGroupName
    actionGroupShortName: actionGroupShortName
    actionGroupProperties: actionGroupProperties
  }
}

module appInsights  'modules/appinsights.bicep' = {
name: 'appi-${environmentName}-dp'
scope: resourceGroup
params:{
  workspaceName: workspaceName
  applicationInsightsName: appInsightsName
  actionGroupName: actionGroupName
  tagValues: tagValues
  actionGroupResourceGroup: resourceGroupName
  location: location
  workspace: workspaceProperties
  }
}

module appInsightsKeyvaultSecret 'modules/kv-Secret.bicep' = {
  name: 'kvsecret-${appInsightsName}-${env}-${location}-dp' 
  scope: resourceGroup
  params: {
    applicationInsightsName: appInsights.outputs.appiName
    applicationInsightsConnectionString: appInsights.outputs.appiConnectString
    sharedKeyvaultName: keyvault.outputs.keyVaultName
  }
}  

module keyvault 'modules/keyvault.bicep' = {
  name: 'kv-${environmentName}-dp'
  scope: resourceGroup
  params: {
    keyVault: keyVaultProperties
    location: location
    locationShortName: locationShortName
    env: env
    keyVaultName: keyVaultName
    roleAssignments: roleAssignments
    tenantId: tenantId
    virtualNetworkId: virtualNetwork.outputs.virtualNetworkId
    workspaceId: appInsights.outputs.workspaceId
  }
  
}

module frontdoor 'modules/frontdoor.bicep' = {
  scope: resourceGroup
  name: 'fd-${product}${component}-${env}-dp'
  params: {
    workspaceId: appInsights.outputs.workspaceId
    frontDoorName: frontDoorName
    frontDoorInfo: frontDoorProperties
    firewallPolicy: firewallPolicy
  }
}

module virtualNetwork 'modules/virtualNetwork.bicep' = {
  scope: resourceGroup
  name: 'vnet-${environmentName}-dp'
  params: {
    addressPrefixes: addressPrefixes
    env: env
    location: location 
    subnets: subnets
    tagValues: tagValues
    workspaceId: appInsights.outputs.workspaceId
    dnsServers: dnsServers
    groupName: groupName
    locationShortName: locationShortName
  }
}
