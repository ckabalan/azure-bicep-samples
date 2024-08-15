targetScope = 'subscription'

param location string
param policyMIResourceId string
param backupPolicyVMId string

resource vmBackupPolAssign 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'vmBackupPA-${location}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${policyMIResourceId}': {}
    }
  }
  properties: {
    displayName: 'Configure VM Backup Policy - ${toUpper(location)}'
    description: 'Assign the Backup Policy from the Recovery Services Vault to all VMs in the ${toUpper(location)} region where the "AzBackup" tag has a value of "TRUE", "True", or "true".'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', '345fa903-145c-4fe1-8bcd-93ec2adccde8')
    parameters: {
      effect: {
        value: 'DeployIfNotExists'
      }
      backupPolicyId: {
        value: backupPolicyVMId
      }
      vaultLocation: {
        value: location
      }
      inclusionTagName: {
        value: 'AzBackup'
      }
      inclusionTagValue: {
        value: [
          'TRUE'
          'True'
          'true'
        ]
      }
    }
    resourceSelectors: [
      {
        name: 'Virtual Machines in ${location}'
        selectors: [
          {
            kind: 'resourceType'
            in: [
              'Microsoft.Compute/virtualMachines'
            ]
          }
          {
            kind: 'resourceLocation'
            in: [
              location
            ]
          }
        ]
      }
    ]
  }
}

resource vmBackupPolRemediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'vmBackupPR-${location}'
  properties: {
    policyAssignmentId: vmBackupPolAssign.id
    policyDefinitionReferenceId: '345fa903-145c-4fe1-8bcd-93ec2adccde8'
    resourceDiscoveryMode: 'ExistingNonCompliant'
  }
}
