// ----------------------------------------
// Parameter declaration
@description('Environment for deployment')
param env string

@description('Short name for the deployment region')
param locationShortName string

@description('Azure region for deployment')
param location string

@description('Name of the Cosmos SQL Database account')
param SqlDatabaseName string

@description('Name of the Cosmos account')
param cosmosAccountName string

@description('Name of the Cosmos SQL Database account')
param containerProperties array

@description('Application being deployed')
param product string

@description('Bolean check if deployment is for production or not')
param isProd bool

@description('Tags to be deployed with this application')
param tagValues object

@description('Id for private DNS zone to create entry for private endpoint')
param privateDnsZoneId string

@description('IP address list to add to Cosmo Firewall')
param allowedIpAddress array

@description('Virtuals Networks that are allowed to connect to CosmoDB')
param allowedVirtualNetworks array

@description('Shared Virtual Network Name')
param sharedVirtualNetwork string

@description('Ids of virtual Networks')
param allowedVnetIds array

@description('Name of the action group for alerting')
param actionGroupName string

@description('Resource Group Name where action group will be created')
param actionGroupResourceGroup string

@description('Locations that Cosmos will be deployed too')
param cosmoLocations array

// ----------------------------------------
// Variable declaration
var alerts = isProd == false ? json(loadTextContent('../alerts/vaccine-data-alertrules-dev.json')) : json(loadTextContent('../alerts/vaccine-data-alertrules-prod.json'))
var staticAlerts = alerts.staticAlerts
//var vNetResourceGroup = 'rg-${product}-${env}-${locationShortName}'
var subnetName = 'snet-privateEndpoints-${env}-${locationShortName}'
var sharedResourceGroup = 'rg-${product}-shared-${env}-${locationShortName}'
var sharedLogWorkspaceName = 'log-${product}-shared-${env}-${locationShortName}'

var targetSubResource = [
  'Sql'
]

var devCapabilites = [
  {
    name: 'EnableServerless'
  }
]

//var prodCapabilites = []

var allowedIp = [for ip in allowedIpAddress: {
  ipAddressOrRange: ip
}]

var allowedSubnet = [for (subnet, index) in allowedVirtualNetworks: {    
  id: '${allowedVnetIds[index].id}/subnets/${subnet.subnet}'
  ignoreMissingVNetServiceEndpoint: false
}]

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: sharedLogWorkspaceName
  scope: resourceGroup(sharedResourceGroup)
}




// Create Cosmo DB account
resource cosmoDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: 'cosmos-${cosmosAccountName}-${env}-${locationShortName}'
  location: location
  tags: tagValues
  identity:{
    type: 'SystemAssigned'
  }
  properties: {
    analyticalStorageConfiguration: {
      schemaType: 'WellDefined'
    }
    defaultIdentity: 'FirstPartyIdentity'
    databaseAccountOfferType: 'Standard' 
    enableMultipleWriteLocations: false //isProd ? true : false disabling multiwrite, app cannot write to multiple locations atm // Dev only deploys to a single location, Prod is deployed to 2. 
    locations: cosmoLocations
    capabilities: isProd ? [] : devCapabilites // Dev is using the serverless tier 
    isVirtualNetworkFilterEnabled: true
    virtualNetworkRules: allowedSubnet
    ipRules: allowedIp
    //publicNetworkAccess: 'Disabled' Possible feature
  }
}




// Create SQL DB in Cosmo Account
resource sqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  parent: cosmoDbAccount
  name: SqlDatabaseName
  properties: {
    resource: {
      id: SqlDatabaseName
    }
  }
  resource containers 'containers' = [for container in containerProperties: if(container.cosmosAccountName == cosmosAccountName) {
    name: container.name
    properties:{
      resource:{
        id: container.name
        conflictResolutionPolicy:{
          conflictResolutionPath: '/_ts'
          mode: 'LastWriterWins'
        }
        indexingPolicy:{
          automatic: true
          excludedPaths:[
            {
              path: '/"_etag"/?'
            }
          ]
          includedPaths:[
            {
             path: '/*'
            }
          ]
        }
        partitionKey: {
          kind: 'Hash'
          paths: [
            '${container.path}'
          ]
        }
      }
      options: {
        throughput: container.throughput
        
      }
    }
  
  }]
}

module keyVaultSecret 'kv-Secret.bicep' = {
  name: '${cosmosAccountName}-${env}-${locationShortName}-Secret'
  scope: resourceGroup(sharedResourceGroup)
  params: {
    accountEndpoint: cosmoDbAccount.properties.documentEndpoint
    accountKey: cosmoDbAccount.listkeys().primaryMasterKey
    databaseAccountName: cosmosAccountName
    env: env
    locationShortName: locationShortName
    tagValues: tagValues
    product: product 
  }
  
}


module privateLinkEndpoint 'privatelink.bicep' = {
  name: 'pe-${cosmoDbAccount.name}-${locationShortName}-Deployment'
  scope: resourceGroup(sharedResourceGroup)
  params: {
    endpointName: cosmoDbAccount.name
    location: location 
    privateLinkServiceId: cosmoDbAccount.id
    subnetName: subnetName
    targetSubResource: targetSubResource
    tagValues: tagValues
    privateDnsZoneId: privateDnsZoneId
    sharedVirtualNetwork: sharedVirtualNetwork
    workspaceId: workspace.id
  }
}

module staticMetricAlerts './staticMetricAlerts.bicep' = [for alert in staticAlerts: {
  name: '(${replace(alert.alertName, ' ', '-')})-${cosmosAccountName}-dp'
  params:{
    actionGroupName: actionGroupName
    actionGroupResourceGroup: actionGroupResourceGroup
    alertName: '${alert.alertName}_${cosmosAccountName}'
    alertDescription: alert.alertDescription
    alertSeverity: alert.alertSeverity
    isEnabled: alert.isEnabled
    windowSize: alert.windowSize
    evaluationFrequency: alert.evaluationFrequency
    criteria: alert.criteria
    resourceId: cosmoDbAccount.id
    tagValues: tagValues
    odataType: alert.odataType

  }
}]


resource CosmosDBDiag 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diag-${cosmoDbAccount.name}'
  scope: cosmoDbAccount
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'QueryRuntimeStatistics'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'ControlPlaneRequests'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'MongoRequests'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'PartitionKeyStatistics'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'PartitionKeyRUConsumption'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'CassandraRequests'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'GremlinRequests'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'TableApiRequests'
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
