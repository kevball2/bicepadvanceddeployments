targetScope = 'resourceGroup'

resource dontDeleteLock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: 'DontDelete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevent deletion of the resourceGroup'
  }
}
