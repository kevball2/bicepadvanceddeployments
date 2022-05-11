// ----------------------------------------
// Parameter declaration
@description('Location of resource deployment')
param location string

@description('Environment for deployment')
param env string

@description('Unique name for the roleAssignment in the format of a guid')
param keyVault object 

@description('Current Tenant Id to be used in deployment')
param tenantId string = tenant().tenantId

@description('Keyvault Name for this deployment')
param keyVaultName string

@description('Role Assignments to allow access to keyvault')
param roleAssignments array

@description('Id of the virtual network')
param virtualNetworkId string

@description('Id of the Logs workspace')
param workspaceId string

@description('Short name for the deployment region')
param locationShortName string


/*
User Assignment format for parameter file

{
  "name": "az-keyvault-reader-dev",
  "groupObjId": "ea8a9d34-b11b-472a-a52f-105a941ba1b7",
  "roleDefinitionId": "21090545-7ca7-4776-b22c-e363652d74d2"
}
*/

// ----------------------------------------
// Variable declaration
var allowedVirtualNetworks = keyVault.allowedSubnets
var diagnosticSettings = keyVault.logs
var ipRules = json(loadTextContent('.././keyVaultIpAllowList.json'))


// ----------------------------------------
// Resource declaration
resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: keyVault.enabledForDeployment
    enabledForTemplateDeployment: keyVault.enabledForTemplateDeployment
    enabledForDiskEncryption: keyVault.enabledForDiskEncryption
    enableRbacAuthorization: keyVault.enableRbacAuthorization
    tenantId: tenantId
    sku: {
      name: keyVault.sku
      family: 'A'
    }
    enableSoftDelete: keyVault.enableSoftDelete
    softDeleteRetentionInDays: keyVault.softDeleteRetentionInDays
    enablePurgeProtection: keyVault.enablePurgeProtection
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules:ipRules.ipRules
      virtualNetworkRules: [ for vnet in allowedVirtualNetworks: {
        id: '${virtualNetworkId}/subnets/${vnet}-${env}-${locationShortName}'
        ignoreMissingVnetServiceEndpoint: false
      }]
    }
  }
  tags: {}
  dependsOn: []
}

resource roleassignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = [for user in roleAssignments: {
    name: guid(user.roleDefinitionId, user.groupObjId, resourceGroup().id)
    properties: {
      principalType: user.type
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', user.roleDefinitionId)
      principalId: user.groupObjId
    }
}]

resource keyvaultDiags 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diag-${keyvault.name}'
  scope: keyvault
  properties: {
    workspaceId: workspaceId
    logs: [for log in diagnosticSettings: {
      category: log.name
      enabled: log.enabled
      
    }]
    metrics: [
      {
        timeGrain: 'PT5M' //ISO8601 format, interval is set for 5 minutes
        enabled: true
        retentionPolicy: {
          enabled: false
          days: keyVault.metricsRetentionDays
        }
      }
    ]
  }
}


output keyVaultId string = keyvault.id
output keyVaultName string = keyvault.name
