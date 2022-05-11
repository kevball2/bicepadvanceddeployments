param applicationInsightsName string
param applicationInsightsConnectionString string
param sharedKeyvaultName string


resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: sharedKeyvaultName
  resource secretName 'secrets' = {
    name: '${applicationInsightsName}-ConnectionString'
    properties: {
    value:  applicationInsightsConnectionString
   }
  }
}

output appInsightsSecretUri string = keyVault::secretName.properties.secretUri
