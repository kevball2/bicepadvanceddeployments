// ----------------------------------------
// Parameter declaration
@description('Name of the Logs workspace')
param workspaceName string 

@description('Name of the Application Insights Instance')
param applicationInsightsName string 

@description('Properties for Logs workspace')
param location string = resourceGroup().location

@description('Environment tags for resources')
param tagValues object

@description('Name of the Action group for alerting')
param actionGroupName string

@description('Resource Group for the action group')
param actionGroupResourceGroup string = resourceGroup().name

@description('Properties for Logs workspace')
param workspace object


// ----------------------------------------
// Variable declaration
var actionGroupId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${actionGroupResourceGroup}/providers/microsoft.insights/ActionGroups/${actionGroupName}'
var requestPerformanceDegradationDetectorRuleName_var = 'Response Latency Degradation - ${applicationInsightsName}'
var dependencyPerformanceDegradationDetectorRuleName_var = 'Dependency Latency Degradation - ${applicationInsightsName}'
var traceSeverityDetectorRuleName_var = 'Trace Severity Degradation - ${applicationInsightsName}'
var exceptionVolumeChangedDetectorRuleName_var = 'Exception Anomalies - ${applicationInsightsName}'
var memoryLeakRuleName_var = 'Potential Memory Leak - ${applicationInsightsName}'


// ----------------------------------------
// Resource declaration
resource logsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  tags: tagValues
  properties: {
    sku: {
      name: workspace.skuName
    }
    retentionInDays: workspace.retentionInDays
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tagValues
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logsWorkspace.id
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}

resource requestPerformanceDegradationDetectorRuleName 'Microsoft.AlertsManagement/smartdetectoralertrules@2019-03-01' = {
  name: requestPerformanceDegradationDetectorRuleName_var
  #disable-next-line BCP187
  location: 'global'
  properties: {
    description: 'Response Latency Degradation notifies you of an unusual increase in latency in your app response to requests.'
    state: 'Enabled'
    severity: 'Sev3'
    frequency: 'PT24H'
    detector: {
      id: 'RequestPerformanceDegradationDetector'
    }
    scope: [
      applicationInsights.id
    ]
    actionGroups: {
      groupIds: [
        actionGroupId
      ]
    }
  }
}

resource dependencyPerformanceDegradationDetectorRuleName 'Microsoft.AlertsManagement/smartdetectoralertrules@2019-03-01' = {
  name: dependencyPerformanceDegradationDetectorRuleName_var
  #disable-next-line BCP187
  location: 'global'
  properties: {
    description: 'Dependency Latency Degradation notifies you of an unusual increase in response by a dependency your app is calling (e.g. REST API or database)'
    state: 'Enabled'
    severity: 'Sev3'
    frequency: 'PT24H'
    detector: {
      id: 'DependencyPerformanceDegradationDetector'
    }
    scope: [
      applicationInsights.id
    ]
    actionGroups: {
      groupIds: [
        actionGroupId
      ]
    }
  }
}

resource traceSeverityDetectorRuleName 'Microsoft.AlertsManagement/smartdetectoralertrules@2019-03-01' = {
  name: traceSeverityDetectorRuleName_var
  #disable-next-line BCP187
  location: 'global'
  properties: {
    description: 'Trace Severity Degradation notifies you of an unusual increase in the severity of the traces generated by your app.'
    state: 'Enabled'
    severity: 'Sev3'
    frequency: 'PT24H'
    detector: {
      id: 'TraceSeverityDetector'
    }
    scope: [
      applicationInsights.id
    ]
    actionGroups: {
      groupIds: [
        actionGroupId
      ]
    }
  }
}

resource exceptionVolumeChangedDetectorRuleName 'Microsoft.AlertsManagement/smartdetectoralertrules@2019-03-01' = {
  name: exceptionVolumeChangedDetectorRuleName_var
  #disable-next-line BCP187
  location: 'global'
  properties: {
    description: 'Exception Anomalies notifies you of an unusual rise in the rate of exceptions thrown by your app.'
    state: 'Enabled'
    severity: 'Sev3'
    frequency: 'PT24H'
    detector: {
      id: 'ExceptionVolumeChangedDetector'
    }
    scope: [
      applicationInsights.id
    ]
    actionGroups: {
      groupIds: [
        actionGroupId
      ]
    }
  }
}

resource memoryLeakRuleName 'Microsoft.AlertsManagement/smartdetectoralertrules@2019-03-01' = {
  name: memoryLeakRuleName_var
  #disable-next-line BCP187
  location: 'global'
  properties: {
    description: 'Potential Memory Leak notifies you of increased memory consumption pattern by your app which may indicate a potential memory leak.'
    state: 'Enabled'
    severity: 'Sev3'
    frequency: 'PT24H'
    detector: {
      id: 'MemoryLeakDetector'
    }
    scope: [
      applicationInsights.id
    ]
    actionGroups: {
      groupIds: [
        actionGroupId
      ]
    }
  }
}

resource applicationInsightsResourceName_migrationToAlertRulesCompleted 'Microsoft.Insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  name: '${applicationInsightsName}/migrationToAlertRulesCompleted'
  location: location
  properties: {
    SendEmailsToSubscriptionOwners: false
    CustomEmails: []
    Enabled: true
  }
  dependsOn: [
    requestPerformanceDegradationDetectorRuleName
    dependencyPerformanceDegradationDetectorRuleName
    traceSeverityDetectorRuleName
    exceptionVolumeChangedDetectorRuleName
    memoryLeakRuleName
  ]
}

resource applicationInsightsDiag 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diag-${applicationInsightsName}'
  scope: applicationInsights
  properties: {
    workspaceId: logsWorkspace.id
    logs: [
      {
        category: 'AppAvailabilityResults'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppBrowserTimings'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppEvents'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppMetrics'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppDependencies'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppExceptions'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppPageViews'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppPerformanceCounters'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppRequests'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppSystemEvents'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'AppTraces'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
    ]
    metrics: [
      {
        timeGrain: 'PT5M'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}




output appiId string = applicationInsights.id
output appiName string = applicationInsights.name
output appiConnectString string = applicationInsights.properties.ConnectionString
output appiInstrumentKey string = applicationInsights.properties.InstrumentationKey
output workspaceId string = logsWorkspace.id