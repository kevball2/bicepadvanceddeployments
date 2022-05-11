
// ----------------------------------------
// Parameter declaration
param location string
param siteConfig array
param appServiceName string
param env string
param appInstrumentKey string
param appConnectString string
param servicePlanId string
param keyVaultUri string
param instance string
param kind string
param linuxVersion string
param deploySlot bool
param deploymentSlots array
param product string
param ipSecurityRestrictions array
param sharedResourceGroupName string
param healthCheckPath string
param workspaceId string
param actionGroupName string
param actionGroupResourceGroup string
param tagValues object
param appInsightsId string

@description('Short name for the deployment region')
param locationShortName string

// ----------------------------------------
// Variable declaration
var _ipSecurityRestrictions = [for rule in ipSecurityRestrictions: {
  ipAddress: rule.ipAddress
  action: rule.action
  tag: rule.tag
  priority: rule.priority
  name: rule.name
  description: rule.description
}] 

var _ipSecurityDefaultRule = [
  {
  ipAddress: 'Any'
  action: 'Deny'
  priority: 2147483647
  name: 'Deny all'
  description: 'Deny all access'
  }
]

var AlertRules = json(loadTextContent('.././AlertRules.json'))
var staticAlerts = AlertRules.staticAlerts
var dynamicAlerts = AlertRules.dynamicAlerts
var logAlerts = AlertRules.logAlerts
var siteName = 'app-${appServiceName}-${env}-${locationShortName}-${instance}'
var sharedVnetName = 'vnet-${product}-shared-${env}-${locationShortName}'
var funcSubnetName = 'snet-${appServiceName}-${env}-${locationShortName}'

var appConfig = [for item in siteConfig: {
  name: replace(item.name, '-', '_')
  value: item.isKeyVault ? '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${item.name}/)' : item.value
} ] 


resource sharedVnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: sharedVnetName
  scope: resourceGroup(sharedResourceGroupName)
} 

resource appService 'Microsoft.Web/sites@2021-01-15' = {
  name: siteName
  location: location
  tags: tagValues
  kind: kind
  identity:{
    type: 'SystemAssigned'
  }
  properties:{
    siteConfig:{
      appSettings:union(appConfig,[
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInstrumentKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appConnectString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'default'
        }
      ])
      linuxFxVersion: linuxVersion
      alwaysOn: true
      ftpsState: 'Disabled'
      ipSecurityRestrictions:concat(_ipSecurityRestrictions, _ipSecurityDefaultRule)
      scmIpSecurityRestrictionsUseMain: true
      healthCheckPath: healthCheckPath
    }
    clientAffinityEnabled: false
    httpsOnly: true
    serverFarmId: servicePlanId
    enabled: true
    virtualNetworkSubnetId: '${sharedVnet.id}/subnets/${funcSubnetName}'

  }
}

resource deploymentSlot 'Microsoft.Web/sites/slots@2021-01-15' = [for (item, index) in deploymentSlots: if (deploySlot == true) {
  name: '${appService.name}/${item.name}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties:{
    enabled: true
    httpsOnly: true
  }    
}]

resource appServiceDiags 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diag-${appService.name}'
  scope: appService
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceFileAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        timeGrain: 'PT5M' //ISO8601 format, interval is set for 5 minutes
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 30
        }
      }
    ]
  }
}

module appServiceKeyVaultAssignment './roleAssignment.bicep' = {
  name: 'keyVaultRoleAssignment-app-front-${env}-${location}-${instance}'
  scope: resourceGroup(sharedResourceGroupName)
  params:{
    principalId: appService.identity.principalId
    assignmentName: siteName
  }
}

module appServiceSlotKeyVaultAssignment './roleAssignment.bicep' = [for (item, index) in deploymentSlots: if (deploySlot == true) {
  name: 'keyVaultRoleAssignment-app-front-${env}-${location}-${instance}-${item.name}'
  scope: resourceGroup(sharedResourceGroupName)
  params:{
    principalId: deploymentSlot[index].identity.principalId
    assignmentName: '${siteName}-${item.name}'
  }
}]


module staticMetricAlerts './staticMetricAlerts.bicep' = [for alert in staticAlerts: {
  name: '(${replace(alert.alertName, ' ', '-')})-${appService.name}-dp'
  params:{
    actionGroupName: actionGroupName
    actionGroupResourceGroup: actionGroupResourceGroup
    alertName: alert.alertName
    alertDescription: alert.alertDescription
    alertSeverity: alert.alertSeverity
    isEnabled: alert.isEnabled
    windowSize: alert.windowSize
    evaluationFrequency: alert.evaluationFrequency
    criteria: alert.criteria
    resourceId: appService.id
    tagValues: tagValues
    odataType: alert.odataType

  }
}]


module dynamicMetricAlerts './dynamicMetricAlerts.bicep' = [for alert in dynamicAlerts: {
  name: '(${replace(alert.alertName, ' ', '-')})-${siteName}-dp'
  params:{
    actionGroupName: actionGroupName
    actionGroupResourceGroup: actionGroupResourceGroup
    alertName: alert.alertName
    alertDescription: alert.alertDescription
    alertSeverity: alert.alertSeverity
    isEnabled: alert.isEnabled
    windowSize: alert.windowSize
    evaluationFrequency: alert.evaluationFrequency
    criteria: alert.criteria
    resourceId: appService.id
    tagValues: tagValues
    odataType: alert.odataType

  }
}]


module logMetricAlerts './logAlerts.bicep' = [for alert in logAlerts: {
  name: '(${replace(alert.alertName, ' ', '-')})-${siteName}-dp'
  params:{
    actionGroupName: actionGroupName
    actionGroupResourceGroup: actionGroupResourceGroup
    location: location
    alertName: alert.alertName
    alertDescription: alert.alertDescription
    alertSeverity: alert.alertSeverity
    isEnabled: alert.isEnabled
    windowSize: alert.windowSize
    evaluationFrequency: alert.evaluationFrequency
    criteria: alert.criteria
    resourceId: appInsightsId
    tagValues: tagValues
    autoMitigate: alert.autoMitigate
    muteActionsDuration: alert.muteActionsDuration

  }
}]
