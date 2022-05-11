param principalId string
param assignmentName string

resource appServiceKeyVaultAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  // Note: GUID used for deployment should never change, if it is the role assignment will fail. The name must stay the same and be unqiue for the life of the resource. 
  // If the 
  name: guid('Key Vault Secret User', assignmentName, subscription().subscriptionId) 
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    
  ]
}
