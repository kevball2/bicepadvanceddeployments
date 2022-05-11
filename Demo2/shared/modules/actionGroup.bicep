@description('Name of the action group being deployed')
param actionGroupName string
@description('Short name for action group. 12 character limit')
param actionGroupShortName string
@description('Properties for deploying action group')
param actionGroupProperties object

resource actionGroup 'microsoft.insights/actionGroups@2019-06-01' = {
  name: actionGroupName
  location: 'global'
  properties:{
    enabled: true
    groupShortName: actionGroupShortName
    emailReceivers: contains(actionGroupProperties, 'emailReceivers') ? actionGroupProperties.emailReceivers : []
    armRoleReceivers: contains(actionGroupProperties, 'armRoleReceivers') ? actionGroupProperties.armRoleReceivers : []

  }
}
