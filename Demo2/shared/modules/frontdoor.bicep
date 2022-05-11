// ----------------------------------------
// Parameter declaration
@description('Name of frontdoor for deployment')
param frontDoorName string

@description('Workspace Id to send diagnostic information')
param workspaceId string

@description('Properties for frondoor deployment')
param frontDoorInfo object

@description('Firewall policy for frontdoor')
param firewallPolicy object


// ----------------------------------------
// Variable declaration
var tempWafName = replace(frontDoorName, '-', '')
var frontDoorWafName = 'fdfp${tempWafName}${uniqueString(subscription().subscriptionId, resourceGroup().id, frontDoorName)}'// Firwall name must start with a letter and can only have letters and numbers in it

var frontendEndpoints = [for endpoint in frontDoorInfo.endpoints : {
  name: toLower('${((endpoint.name == 'Default') ? 'default-${frontDoorName}-azurefd-net' : '${endpoint.name}')}')
  properties: {
    hostName: toLower('${((endpoint.name == 'Default') ? '${frontDoorName}.azurefd.net' : '${endpoint.hostName}')}')
    sessionAffinityEnabledState: endpoint.sessionAffinityEnabledState
    sessionAffinityTtlSeconds: 0
    webApplicationFirewallPolicyLink: {
      id: frontDoorFirewall.id
    }
  }
}]

var healthProbeSettings = [for probe in frontDoorInfo.probes : {
  name: probe.name
  properties: {
    path: probe.ProbePath
    protocol: 'Https'
    intervalInSeconds: 30
    healthProbeMethod: (contains(probe, 'probeMethod') ? probe.probeMethod : 'Head')
    enabledState: 'Enabled'
  }
}]

var loadBalancingSettings = [for lb in frontDoorInfo.LBSettings : {
  name: lb.name
  properties: {
    sampleSize: lb.sampleSize
    successfulSamplesRequired: lb.successfulSamplesRequired
    additionalLatencyMilliseconds: lb.additionalLatencyMilliseconds
  }
}]

module frontDoorBEpools 'frontdoor-Backends.bicep' = [for (endpoint, i) in frontDoorInfo.endpoints: {
name: 'dp-${frontDoorName}-Bepool-${endpoint.name}-${i}'
params:{
  endpoints: endpoint
}  
}]


var routingRulesHTTPS = [for endpoint in frontDoorInfo.endpoints:  {
  name: '${endpoint.name}-HTTPS'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/FrontendEndpoints', frontDoorName, '${((endpoint.name == 'Default') ? 'default-${frontDoorName}-azurefd-net' : '${endpoint.name}')}')
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          enabledState: 'Enabled'
          resourceState: 'Enabled'
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/BackendPools', frontDoorName, '${endpoint.name}')
            }
          }
        }
}]

var routingRulesRedirect = [for endpoint in frontDoorInfo.endpoints:  {
  name: '${endpoint.name}-redirect'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/FrontendEndpoints', frontDoorName, '${((endpoint.name == 'Default') ? 'default-${frontDoorName}-azurefd-net' : '${endpoint.name}')}')
            }
          ]
          acceptedProtocols: [
            'Http'
          ]
          patternsToMatch: [
            '/*'
          ]
          enabledState: 'Enabled'
          resourceState: 'Enabled'
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorRedirectConfiguration'
            redirectProtocol: 'HttpsOnly'
            redirectType: 'Found' 
          }
        }
}]



// ----------------------------------------
// Resource declaration
resource frontDoor 'Microsoft.Network/frontdoors@2020-01-01' = {
  name: frontDoorName
  location: 'Global'
  properties: {
    enabledState: frontDoorInfo.enabledState ? 'Enabled' : 'Disabled'
    friendlyName: frontDoorName
    frontendEndpoints:frontendEndpoints
    healthProbeSettings: healthProbeSettings
    loadBalancingSettings: loadBalancingSettings
    routingRules: union(routingRulesHTTPS, routingRulesRedirect)  //routingRules
    backendPoolsSettings: {
      enforceCertificateNameCheck: 'Enabled'
      sendRecvTimeoutSeconds: 30
    }
    backendPools: [for (endpoint, index) in frontDoorInfo.endpoints: {
        name: endpoint.name
        properties: {
          backends: frontDoorBEpools[index].outputs.backends
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, endpoint.name)
          }
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/LoadBalancingSettings', frontDoorName, endpoint.name)
          }
        }
      }]
  }
}



resource frontDoorFirewall 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-11-01' = {
  name: frontDoorWafName
  location: 'Global'
  properties: {
    policySettings: {
      enabledState: firewallPolicy.policySettings.enabledState
      mode: firewallPolicy.policySettings.mode
      requestBodyCheck: firewallPolicy.policySettings.requestBodyCheck
    }
    customRules: {
      rules: firewallPolicy.customRules
    }
    managedRules: {
      managedRuleSets: firewallPolicy.managedRuleSets
    }
  }
}

resource FDDiags 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diag-${frontDoorName}'
  scope: frontDoor
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'FrontdoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontdoorWebApplicationFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        timeGrain: 'PT5M' //ISO8601 format, interval is set for 5 minutes
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}




output frontDoorId string = frontDoor.id
output frontDoorName string = frontDoor.name
output frontDoorLocation string = frontDoor.location
