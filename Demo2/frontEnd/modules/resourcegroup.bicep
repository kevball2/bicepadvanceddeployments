targetScope = 'subscription'

@description('ResourceGroup Name')
param name string

@description('Location for the resourceGroup')
param location string

@description('Tags to be applied to resources')
param tagValues object

@description('Current Environment for deployment')
param env string 


resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'rg-${name}-${env}-${location}'
  location: location 
  tags: tagValues 
  properties:{
    
  }
}

output rgName string = rg.name


module applyLock './applylock.bicep'= if(env == 'prod') {
  scope: rg
  name: 'applyLock-${name}'
  params: {
  }
}

