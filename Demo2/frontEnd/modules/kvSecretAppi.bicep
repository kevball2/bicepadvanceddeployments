param applicationInsightsName string
param groupName string
param appInsightsConnectionString string
param sharedKeyvaultName string


resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: sharedKeyvaultName
  resource secretName 'secrets' = {
    name: '${applicationInsightsName}-${groupName}-ConnectionString'
    properties: {
    value:  appInsightsConnectionString
   }
  }
}

output appInsightsSecretUri string = keyVault::secretName.properties.secretUri
