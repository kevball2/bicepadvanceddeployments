targetScope = 'subscription'

// ----------------------------------------
// Parameter declaration
@description('Location for the resourceGroup')
param location string

@description('Current Environment for deployment')
param env string 

@description('Returns the current date for Tag updates')
param currentDate string = utcNow('yyyy-MM-dd')

@description('Application asscociated with deployment')
param product string

@description('Websites to deploy')
param sites object

@description('list of app plans to deploy')
param appPlans array = sites.appPlans

@description('Application component being deployed')
param component string

@description('Dictionary of deployment regions with shortname')
param locationList object

@description('Properties for deploying action group')
param actionGroupProperties object

// ----------------------------------------
// Variable declaration
var tagValues = {
  createdBy: 'az cli'
  environment: env
  deploymentDate: currentDate
  product: product
}

var locationShortName = locationList[location]
var actionGroupName = 'ag-${product}-${component}-${locationShortName}'
var actionGroupShortName = substring('${product}${component}${env}', 0, 11)
var groupName = '${product}-${component}'
var sharedKeyvaultName = 'kv${product}shared${env}${locationShortName}'
var resourcegroupName = 'rg-${product}-${component}-${env}-${locationShortName}'
var workspaceName = 'log-${product}-${component}-${env}-${locationShortName}'
var applicationInsightsName ='appi-${groupName}-${env}-${locationShortName}'
var sharedResourceGroup = 'rg-${product}-shared-${env}-${locationShortName}'


// ----------------------------------------
// Resource declaration
resource resourceGroup_r 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourcegroupName
  location: location
  tags: tagValues
  
}

module actionGroup 'modules/actiongroup.bicep' = {
  scope: resourceGroup_r
  name: 'ag-${applicationInsightsName}-dp'
  params: {
    actionGroupName: actionGroupName
    actionGroupShortName: actionGroupShortName
    actionGroupProperties: actionGroupProperties
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: sharedKeyvaultName
  scope: resourceGroup(sharedResourceGroup)
}

module appInsights 'modules/appinsights.bicep' = {
  scope: resourceGroup(resourceGroup_r.name)
  name: product
  params:{
    workspaceName: workspaceName
    applicationInsightsName: applicationInsightsName
    location: location
    tagValues: tagValues
    env: env
    groupName: groupName
    sharedKeyvaultName: sharedKeyvaultName
    sharedResourceGroupName: sharedResourceGroup
    actionGroupResourceGroup: resourceGroup_r.name
    actionGroupName: actionGroupName
  }
}

module appPlan 'modules/appplan.bicep' = [for item in appPlans: if(item.location == location) {
scope: resourceGroup(resourceGroup_r.name)
name: 'plan-${item.appPlanName}-${item.location}-${env}-${item.instance}-deployment'
params:{
  location: location
  tagValues: tagValues
  env: env
  planName: item.appPlanName
  skuName: item.skuName
  skuTier: item.skuTier
  skuSize: item.skuSize
  skuFamily: item.skuFamily
  skuCapacity: item.skuCapacity
  maxWorkerCount: item.maxWorkerCount
  reserverd: item.reserved
  appServices: item.appServices
  kind: item.kind
  perSiteScaling: item.perSiteScaling
  rgName:resourceGroup_r.name
  appConnectString: appInsights.outputs.appiConnectString
  appInstrumentKey: appInsights.outputs.appiInstrumentKey
  keyVaultUri: keyVault.properties.vaultUri
  instance: item.instance
  product: product
  sharedResourcegroupName: sharedResourceGroup
  actionGroupName: actionGroupName
  actionGroupResourceGroup: resourceGroup_r.name
  workspaceId: appInsights.outputs.workspaceId
  appInsightsId: appInsights.outputs.appiID
  locationShortName: locationShortName
}  
}]
