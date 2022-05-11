//param sites_vaccine_front_name string
//param sites_vaccine_mt_name string
//param subscriptionId string
//param serverFarmResourceGroup string
//param serverfarms_plan_front string
param location string
//param tags_Stage string
//param components_insight_name string
param appConfigs array
//var serverfarms_plan_externalid = '/subscriptions/${subscriptionId}/resourcegroups/${serverFarmResourceGroup}/providers/Microsoft.Web/serverfarms/${serverfarms_plan_front}'


param rg string
param env string
param tagvalues object
param appInstrumentKey string
param appConnectString string
param servicePlanId array
param keyVaultUri string

var siteName = 'app-${rg}-${env}-${location}'




var appConfig = [for item in appConfigs: {
  name: replace(item.name, '-', '_')
  value: item.isKeyVault ? '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/${item.name}/)' : item.value
} ] 

module m_appServiceKeyVaultAssignment './roleAssignment.bicep' = {
  name: 'keyVaultRoleAssignment-app-front-${env}-${location}'
  scope: resourceGroup('rg-shared-${env}-${location}')
  params:{
    principalId: appService.identity.principalId
    sitesVaccineMtName: siteName
  }
}

resource appService 'Microsoft.Web/sites@2021-01-15' = {
  name: siteName
  location: location
  tags: tagvalues
  kind: 'app,linux'
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
      ])
    }
    hostNameSslStates: [
      {
        name: 'vaccine-front-${env}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: 'vaccine-front-${env}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: servicePlanId
  }
  
}

resource appServiceConfig 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: appService
  name: 'web'
  properties:{
    numberOfWorkers: 1
    netFrameworkVersion:'v4.0'
    linuxFxVersion:'NODE|12-lts'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2019'
    httpLoggingEnabled: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    azureStorageAccounts: {}
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    ftpsState: 'Disabled'
  }
  
  
}

// resource sites_vaccine_front_name_sites_vaccine_front_name_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2021-01-15' = {
//   parent: appService
//   name: '${siteName}.azurewebsites.net'
//   properties: {
//     siteName: siteName
//     hostNameType: 'Verified'
//   }
// }


//old code
/*
resource sites_vaccine_front_name_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: sites_vaccine_front_name
  location: location
  tags: {
    Stage: tags_Stage
    Product: 'Vaccine'
  }
  kind: 'app,linux'
  properties: {
    enabled: true
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference('microsoft.insights/components/${components_insight_name}', '2015-05-01').InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: reference('microsoft.insights/components/${components_insight_name}', '2015-05-01').ConnectionString
        }
        {
          name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
          value: '1.0.0'
          slotSetting: false
        }
        {
          name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
          value: '1.0.0'
          slotSetting: false
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'DiagnosticServices_EXTENSION_VERSION'
          value: '~3'
          slotSetting: false
        }
        {
          name: 'InstrumentationEngine_EXTENSION_VERSION'
          value: 'disabled'
          slotSetting: false
        }
        {
          name: 'SnapshotDebugger_EXTENSION_VERSION'
          value: 'disabled'
          slotSetting: false
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_BaseExtensions'
          value: 'disabled'
          slotSetting: false
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
          slotSetting: false
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_PreemptSdk'
          value: 'disabled'
          slotSetting: false
        }
        {
          name: 'MT_URL'
          value: 'https://${sites_vaccine_mt_name}.azurewebsites.net'
          slotSetting: false
        }
        {
          name: 'MT_SECRET'
          value: listkeys(resourceId('Microsoft.Web/sites/host', sites_vaccine_mt_name, 'default'), '2020-06-01').functionKeys.front
          slotSetting: false
        }
      ]
    }
    
    serverFarmId: servicePlanId
    
  }
}

resource sites_vaccine_front_name_web 'Microsoft.Web/sites/config@2018-11-01' = {
  parent: sites_vaccine_front_name_resource
  name: 'web'
  location: location
  tags: {
    Stage: tags_Stage
    Product: 'Vaccine'
  }
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'NODE|12-lts'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2019'
    httpLoggingEnabled: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    azureStorageAccounts: {}
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'AzureFrontDoor.Backend'
        action: 'Allow'
        tag: 'ServiceTag'
        priority: 300
        name: 'Front Door only'
      }
      {
        ipAddress: 'Any'
        action: 'Deny'
        priority: 2147483647
        name: 'Deny all'
        description: 'Deny all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    ftpsState: 'Disabled'
    reservedInstanceCount: 0
  }
}

resource sites_vaccine_front_name_sites_vaccine_front_name_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2018-11-01' = {
  parent: sites_vaccine_front_name_resource
  name: '${sites_vaccine_front_name}.azurewebsites.net'
  location: location
  properties: {
    siteName: sites_vaccine_front_name
    hostNameType: 'Verified'
  }
}

resource sites_vaccine_front_name_stage 'Microsoft.Web/sites/slots@2018-11-01' = {
  parent: sites_vaccine_front_name_resource
  name: 'stage'
  location: location
  kind: 'app,linux'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${sites_vaccine_front_name}-stage.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${sites_vaccine_front_name}-stage.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverfarms_plan_externalid
    reserved: true
    isXenon: false
    hyperV: false
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference('microsoft.insights/components/${components_insight_name}', '2015-05-01').InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: reference('microsoft.insights/components/${components_insight_name}', '2015-05-01').ConnectionString
        }
        {
          name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
          value: '1.0.0'
          slotSetting: false
        }
        {
          name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
          value: '1.0.0'
          slotSetting: false
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'DiagnosticServices_EXTENSION_VERSION'
          value: '~3'
          slotSetting: false
        }
        {
          name: 'InstrumentationEngine_EXTENSION_VERSION'
          value: 'disabled'
          slotSetting: false
        }
        {
          name: 'SnapshotDebugger_EXTENSION_VERSION'
          value: 'disabled'
          slotSetting: false
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_BaseExtensions'
          value: 'disabled'
          slotSetting: false
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
          slotSetting: false
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_PreemptSdk'
          value: 'disabled'
          slotSetting: false
        }
        {
          name: 'MT_URL'
          value: 'https://${sites_vaccine_mt_name}.azurewebsites.net'
          slotSetting: false
        }
        {
          name: 'MT_SECRET'
          value: listkeys(resourceId('Microsoft.Web/sites/host', sites_vaccine_mt_name, 'default'), '2020-06-01').functionKeys.front
          slotSetting: false
        }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
  }
}

resource sites_vaccine_front_name_stage_web 'Microsoft.Web/sites/slots/config@2018-11-01' = {
  parent: sites_vaccine_front_name_stage
  name: 'web'
  location: location
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'NODE|12-lts'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2019'
    httpLoggingEnabled: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    azureStorageAccounts: {}
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    ftpsState: 'Disabled'
    reservedInstanceCount: 0
  }
  dependsOn: [
    sites_vaccine_front_name_resource
  ]
}

resource sites_vaccine_front_name_stage_sites_vaccine_front_name_stage_azurewebsites_net 'Microsoft.Web/sites/slots/hostNameBindings@2018-11-01' = {
  parent: sites_vaccine_front_name_stage
  name: '${sites_vaccine_front_name}-stage.azurewebsites.net'
  location: location
  properties: {
    siteName: '${sites_vaccine_front_name}(stage)'
    hostNameType: 'Verified'
  }
  dependsOn: [
    sites_vaccine_front_name_resource
  ]
}

*/
