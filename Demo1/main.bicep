targetScope = 'subscription'

param component string
param env string
param product string
param location string = 'northcentralus'
param Name string
param IpPrefixes array
param Delegation string
param ServiceEndpoint string
param subnetPrefix string


var envname = '${product}-${component}-${env}-${location}' // 
var rgName = 'rg-${envname}'


resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgName
  location: location 
  properties:{
    
  }
}


module VNET 'modules/virtualNetwork.bicep' = {
  scope: rg
  name: 'vnet-deployment'
  params: {
    IPaddressPrefixes: IpPrefixes
    env: env
    location: location 
    product: product
    Delegations: Delegation
    subnetname: Name
    subnetIPPrefix: subnetPrefix
    ServiceEndpoint: ServiceEndpoint
  }
}
