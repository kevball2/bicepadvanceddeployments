// ----------------------------------------
// Parameter declaration

@description('Name of the Cosmos Database')
param databaseAccountName string

@description('Cosmos DB Endpoint URL')
param accountEndpoint string

@description('Cosmos DB Account Key')
param accountKey string

@description('Environment for deployment')
param env string

@description('Application being deployed')
param product string

@description('Short name for the deployment region')
param locationShortName string

@description('Environment tags for resources')
param tagValues object


// ----------------------------------------
// Variable declaration
var keyVaultName = 'kv${product}shared${env}${locationShortName}'

// ----------------------------------------
// Resource declaration
resource keyVaultSecret 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
  resource cosmoConnectionStringSecret 'secrets' = {
    name: 'cosmos-${databaseAccountName}-ConnectionString'
    tags: tagValues
    properties:{
      value: 'AccountEndpoint=${accountEndpoint};AccountKey=${accountKey}'  
    }  
  }
}

