param NICName string
param workspaceId string
param name string


resource NIC 'Microsoft.Network/networkInterfaces@2021-05-01' existing = {
  name: NICName
}

resource NIC1Diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: name
  scope: NIC
  properties: {
    workspaceId: workspaceId
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
