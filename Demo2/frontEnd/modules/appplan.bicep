// ----------------------------------------
// Parameter declaration

@description('Azure region for deployment')
param location string

@description('Short name for the deployment region')
param locationShortName string

@description('Tags to be deployed with this application')
param tagValues object

@description('Environment for deployment')
param env string

@description('Name of the App plan to deploy')
param planName string

@description('App plan Sku Name')
param skuName string

@description('App plan Sku Tier')
param skuTier string

@description('App plan sku Size')
param skuSize string

@description('App Plan Sku Family')
param skuFamily string

@description('Sku Capacity ')
param skuCapacity int

@description('Type of App plan, windows or Linux')
param kind string

@description('Is per site scaling enabled')
param perSiteScaling bool

@description('Max number of workers for App plan')
param maxWorkerCount int

@description('Boolean to confirm in there is reservation for the app plan')
param reserverd bool

@description('Array of app Services to deploy')
param appServices array

@description('Name of the resource group for deployment')
param rgName string

@description('Application Insights Instrumentation Key')
param appInstrumentKey string

@description('Application Insights Connection String')
param appConnectString string

@description('URL for keyvault')
param keyVaultUri string

@description('Defines what instance number is being deployed')
param instance string

@description('Application being deployed')
param product string

@description('Name of the shared resource group')
param sharedResourcegroupName string

@description('name of the action group for alerting')
param actionGroupName string

@description('Resource group for Action group deployment')
param actionGroupResourceGroup string

@description('Log Analytics workspace Id')
param workspaceId string

@description('Application Insights Id')
param appInsightsId string



resource appServicePlan 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: 'plan-${planName}-${env}-${locationShortName}-${instance}'
  location: location
  tags: tagValues
  sku: {
    name: skuName
    tier: skuTier
    size: skuSize
    family: skuFamily
    capacity: skuCapacity
  }
  kind: kind
  properties: {
    perSiteScaling: perSiteScaling
    maximumElasticWorkerCount: maxWorkerCount
    reserved: reserverd
    targetWorkerCount: skuCapacity
  }
}

module appServiceModule 'appservice.bicep'  = [for (app, index) in appServices: {
scope: resourceGroup(rgName)
name: 'app${app.appServiceName}${env}${locationShortName}${app.instance}'
params:{
  location: location 
  appServiceName: app.appServiceName
  servicePlanId: appServicePlan.id
  appConnectString: appConnectString
  appInstrumentKey: appInstrumentKey
  env:env
  siteConfig: app.siteConfig
  keyVaultUri: keyVaultUri
  instance: app.instance
  kind: app.kind
  linuxVersion: app.linuxFxVersion
  deploySlot: app.deploySlot
  deploymentSlots: app.deploymentSlots
  product: product
  ipSecurityRestrictions: app.ipSecurityRestrictions
  sharedResourceGroupName: sharedResourcegroupName
  healthCheckPath: app.healthCheckPath
  actionGroupName: actionGroupName
  actionGroupResourceGroup: actionGroupResourceGroup 
  workspaceId: workspaceId
  appInsightsId: appInsightsId
  tagValues: tagValues
  locationShortName: locationShortName
}
  
}]

output servicePlanId string  =  appServicePlan.id
