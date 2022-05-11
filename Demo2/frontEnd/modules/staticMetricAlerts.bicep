@description('Name of Alert displayed in Azure')
param alertName string

@description('Description of the alert activitys') 
param alertDescription string

@description('Severity of alert {0,1,2,3,4}')
param alertSeverity int

@description('Specifies whether the alert is enabled')
param isEnabled bool

@description('Full Resource ID of the resource emitting the metric that will be used for the comparison. For example /subscriptions/00000000-0000-0000-0000-0000-00000000/resourceGroups/ResourceGroupName/providers/Microsoft.compute/virtualMachines/VM_xyz')
param resourceId string


@description('The name of the action group that is triggered when the alert is activated or deactivated')
param actionGroupName string

@description('The resource group name that holds the action group')
param actionGroupResourceGroup string

@description('Azure environment Tags')
param tagValues object

@description('how often the metric alert is evaluated represented in ISO 8601 duration format')
@allowed([
  'PT1M'
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
])
param evaluationFrequency string = 'PT1M'

@description('Period of time used to monitor alert activity based on the threshold. Must be between one minute and one day. ISO 8601 duration format.')
@allowed([
  'PT1M'
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
  'PT6H'
  'PT12H'
  'PT24H'
])
param windowSize string = 'PT5M'

@description('Data type of the criteria that will fire alert')
@allowed([
  'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
  'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
  'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
])
param odataType string

@description('Criteria for the alert to fire')
param criteria array

var actionGroupId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${actionGroupResourceGroup}/providers/microsoft.insights/ActionGroups/${actionGroupName}'
var allOf = [for prop in criteria:{
  name: prop.name
  metricName: prop.metricName
  criterionType: prop.criterionType
  dimensions: prop.dimensions
  operator: prop.operator
  threshold: prop.threshold
  timeAggregation: prop.timeAggregation
} ]

resource monitorAlertRule 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertName
  location: 'global'
  tags: tagValues
  properties: {
    description: alertDescription 
    enabled: isEnabled
    evaluationFrequency: evaluationFrequency
    scopes:[ 
      '${resourceId}'
    ]
    severity: alertSeverity
    windowSize: windowSize
    criteria: {
      'odata.type': odataType
      allOf: allOf
    }

    actions:[
    {
        actionGroupId: actionGroupId
    }
  ]
  }
}

