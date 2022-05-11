@description('Backend pools for frontdoor') // due to not being able to nest for loops in bicep we need to utilize modules. 
param endpoints object

  var backends = [for i in range(0, length(endpoints.backendHosts)): {
    weight: (contains(endpoints.backendHosts[i], 'weight') ? endpoints.backendHosts[i].weight : 100)
    address: endpoints.backendHosts[i].address
    backendHostHeader: endpoints.backendHosts[i].hostHeader
    enabledState: 'Enabled'
    httpPort: 80
    httpsPort: 443
    priority: 1
  }]


output backends array = backends
