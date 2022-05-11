//param planName string
param location string
param tagValues object
param env string
param appPlanSettings array
param skuName string
param skuTier string
param skuSize string
param skuFamily string


resource appServicePlan 'Microsoft.Web/serverfarms@2018-02-01' = [for item in appPlanSettings: {
  name: 'plan-${item.name}-${location}-${env}'
  location: location
  tags: tagValues
  sku: {
    name: item.skuName
    tier: item.skuTier
    size: item.skuSize
    family: item.skuFamily
    capacity: item.skuCapacity
  }
  kind: item.kind
  properties: {
    perSiteScaling: item.perSiteScaling
    maximumElasticWorkerCount: (contains(item, 'maxWorkerCount') ? item.maxWorkerCount : json('null'))
    reserved: item.reserved
    targetWorkerCount: item.skuCapacity
  }
}]


output servicePlanId array  = [for i in range(0, length(appPlanSettings)): appServicePlan[i].id]
