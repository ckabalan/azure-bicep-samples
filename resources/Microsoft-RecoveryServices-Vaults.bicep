targetScope = 'resourceGroup'

param resourceSuffix string

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  name: 'rsv-${resourceSuffix}'
  location: resourceGroup().location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    monitoringSettings: {
      azureMonitorAlertSettings: {
        alertsForAllFailoverIssues: 'Enabled'
        alertsForAllJobFailures: 'Enabled'
        alertsForAllReplicationIssues: 'Enabled'
      }
      classicAlertSettings: {
        alertsForCriticalOperations: 'Disabled'
        emailNotificationsForSiteRecovery: 'Disabled'
      }
    }
    publicNetworkAccess: 'Disabled'
    redundancySettings: {
      crossRegionRestore: 'Enabled'
      standardTierStorageRedundancy: 'GeoRedundant'
    }
    securitySettings: {
      softDeleteSettings: {
        enhancedSecurityState: 'Enabled'
        softDeleteRetentionPeriodInDays: 14
        softDeleteState: 'Enabled'
      }
    }
  }
}

// This list created by:
//   > az account list-locations | jq -r '.[] | [.type, .metadata.regionType, .metadata.regionCategory, .name, .displayName, .metadata.geography, .metadata.physicalLocation] | @tsv' > timezones.tsv
// Opening that Tab-Separated Value file in Excel, removing some errant regions (all the Logical ones, and some that have Stage or Canary in the name).
// I then fed it into Copilot to generate the Windows Time Zone value corresponding to each Azure Region's home city. I did spot checks and it looks right.
// The list of possible Time Zone Values is attainable using the `tzutil /`, or at the following page:
//   https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones?view=windows-11
var backupTimeZone = {
  australiacentral: 'AUS Eastern Standard Time'
  australiacentral2: 'AUS Eastern Standard Time'
  australiaeast: 'AUS Eastern Standard Time'
  australiasoutheast: 'AUS Eastern Standard Time'
  brazilsouth: 'E. South America Standard Time'
  brazilsoutheast: 'E. South America Standard Time'
  canadacentral: 'Eastern Standard Time'
  canadaeast: 'Eastern Standard Time'
  centralindia: 'India Standard Time'
  centralus: 'Central Standard Time'
  eastasia: 'China Standard Time'
  eastus: 'Eastern Standard Time'
  eastus2: 'Eastern Standard Time'
  francecentral: 'Romance Standard Time'
  francesouth: 'Romance Standard Time'
  germanynorth: 'W. Europe Standard Time'
  germanywestcentral: 'W. Europe Standard Time'
  israelcentral: 'Israel Standard Time'
  italynorth: 'W. Europe Standard Time'
  japaneast: 'Tokyo Standard Time'
  japanwest: 'Tokyo Standard Time'
  jioindiacentral: 'India Standard Time'
  jioindiawest: 'India Standard Time'
  koreacentral: 'Korea Standard Time'
  koreasouth: 'Korea Standard Time'
  mexicocentral: 'Central Standard Time (Mexico)'
  northcentralus: 'Central Standard Time'
  northeurope: 'GMT Standard Time'
  norwayeast: 'W. Europe Standard Time'
  norwaywest: 'W. Europe Standard Time'
  polandcentral: 'Central European Standard Time'
  qatarcentral: 'Arabian Standard Time'
  southafricanorth: 'South Africa Standard Time'
  southafricawest: 'South Africa Standard Time'
  southcentralus: 'Central Standard Time'
  southeastasia: 'Singapore Standard Time'
  southindia: 'India Standard Time'
  spaincentral: 'Romance Standard Time'
  swedencentral: 'Gävle, Sweden - W. Europe Standard Time'
  switzerlandnorth: 'W. Europe Standard Time'
  switzerlandwest: 'W. Europe Standard Time'
  uaecentral: 'Arabian Standard Time'
  uaenorth: 'Arabian Standard Time'
  uksouth: 'GMT Standard Time'
  ukwest: 'GMT Standard Time'
  westcentralus: 'Mountain Standard Time'
  westeurope: 'W. Europe Standard Time'
  westindia: 'India Standard Time'
  westus: 'Pacific Standard Time'
  westus2: 'Pacific Standard Time'
  westus3: 'US Mountain Standard Time'
}

resource rsvBackupPolicyVM 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  name: 'BackupPolicy-VM'
  parent: recoveryServicesVault
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V2'
    instantRPDetails: {
      azureBackupRGNamePrefix: 'rsv-${resourceSuffix}-backups-vm-'
      azureBackupRGNameSuffix: ''
    }
    instantRpRetentionRangeInDays: 2
    timeZone: backupTimeZone[resourceGroup().location]
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      dailySchedule: {
        // 5PM in the Azure Region's Timezone
        scheduleRunTimes: [ '2024-01-01T17:00:00Z' ]
      }
      scheduleRunFrequency: 'Daily'
    }
    snapshotConsistencyType: 'OnlyCrashConsistent'
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionDuration: {
          count: 8
          durationType: 'Days'
        }
        // 5PM in the Azure Region's Timezone
        retentionTimes: [ '2024-01-01T17:00:00Z' ]
      }
      monthlySchedule: {
        retentionDuration: {
          count: 3
          durationType: 'Months'
        }
        // 5PM in the Azure Region's Timezone
        retentionTimes: [ '2024-01-01T17:00:00Z' ]
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: {
          daysOfTheWeek: [ 'Friday' ]
          weeksOfTheMonth: [ 'Last']
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [ 'Friday' ]
        retentionDuration: {
          count: 5
          durationType: 'Weeks'
        }
        // 5PM in the Azure Region's Timezone
        retentionTimes: [ '2024-01-01T17:00:00Z' ]
      }
    }
  }
}

