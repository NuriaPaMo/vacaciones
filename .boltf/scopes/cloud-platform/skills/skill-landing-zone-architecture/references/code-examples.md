# Azure Landing Zone Architecture - Code Examples

> **Progressive Disclosure**: These examples demonstrate Azure Landing Zone patterns including management group hierarchies, hub-spoke networking, governance policies, and subscription organization following Cloud Adoption Framework (CAF) guidance.

---

## Example 1: Management Group Hierarchy with Bicep

**Management Groups** organize subscriptions into hierarchical governance structures. Azure Landing Zones use management groups for policy inheritance and RBAC assignment at scale.

```bicep
// management-groups.bicep
targetScope = 'tenant'

resource rootManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'contoso-root'
  properties: {
    displayName: 'Contoso Root'
    details: {
      parent: {
        id: tenantResourceId('Microsoft.Management/managementGroups', 'Tenant Root Group')
      }
    }
  }
}

resource platformManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'contoso-platform'
  properties: {
    displayName: 'Platform'
    details: {
      parent: {
        id: rootManagementGroup.id
      }
    }
  }
}

resource identityManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'contoso-identity'
  properties: {
    displayName: 'Identity'
    details: {
      parent: {
        id: platformManagementGroup.id
      }
    }
  }
}

resource managementManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'contoso-management'
  properties: {
    displayName: 'Management'
    details: {
      parent: {
        id: platformManagementGroup.id
      }
    }
  }
}

resource connectivityManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'contoso-connectivity'
  properties: {
    displayName: 'Connectivity'
    details: {
      parent: {
        id: platformManagementGroup.id
      }
    }
  }
}

resource landingZonesManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'contoso-landingzones'
  properties: {
    displayName: 'Landing Zones'
    details: {
      parent: {
        id: rootManagementGroup.id
      }
    }
  }
}

resource corpManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'contoso-corp'
  properties: {
    displayName: 'Corp (Internal)'
    details: {
      parent: {
        id: landingZonesManagementGroup.id
      }
    }
  }
}

resource onlineManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'contoso-online'
  properties: {
    displayName: 'Online (Internet-facing)'
    details: {
      parent: {
        id: landingZonesManagementGroup.id
      }
    }
  }
}

output rootManagementGroupId string = rootManagementGroup.id
output platformManagementGroupId string = platformManagementGroup.id
output landingZonesManagementGroupId string = landingZonesManagementGroup.id
```

**Deployment**:

```bash
# Deploy management group hierarchy at tenant scope
az deployment tenant create \
  --location eastus \
  --template-file management-groups.bicep
```

**Key Points**:

- Management groups provide hierarchical governance and policy inheritance
- Platform management group contains Identity, Management, Connectivity subscriptions
- Landing Zones management group separates Corp (internal) from Online (internet-facing) workloads
- Policies assigned at management group scope apply to all child subscriptions

---

## Example 2: Hub-Spoke Virtual Network Topology

**Hub-Spoke Topology** centralizes shared services (Azure Firewall, VPN Gateway, DNS) in a hub VNet, with application workloads in spoke VNets connected via peering.

```bicep
// hub-network.bicep
param location string = resourceGroup().location
param hubVNetName string = 'vnet-hub'
param hubAddressPrefix string = '10.0.0.0/16'
param firewallSubnetPrefix string = '10.0.0.0/26'
param gatewaySubnetPrefix string = '10.0.1.0/27'
param bastionSubnetPrefix string = '10.0.2.0/27'

resource hubVNet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hubVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet' // Reserved name for Azure Firewall
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
      {
        name: 'GatewaySubnet' // Reserved name for VPN Gateway
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
      {
        name: 'AzureBastionSubnet' // Reserved name for Azure Bastion
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
    ]
  }
}

output hubVNetId string = hubVNet.id
output hubVNetName string = hubVNet.name
```

**Spoke Network**:

```bicep
// spoke-network.bicep
param location string = resourceGroup().location
param spokeVNetName string = 'vnet-spoke-workload1'
param spokeAddressPrefix string = '10.1.0.0/16'
param appSubnetPrefix string = '10.1.0.0/24'
param dataSubnetPrefix string = '10.1.1.0/24'

resource spokeVNet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: spokeVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-app'
        properties: {
          addressPrefix: appSubnetPrefix
          networkSecurityGroup: {
            id: appNSG.id
          }
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: dataSubnetPrefix
          networkSecurityGroup: {
            id: dataNSG.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Sql'
            }
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}

resource appNSG 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-app'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource dataNSG 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-data'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyInternetOutbound'
        properties: {
          priority: 4096
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
    ]
  }
}

output spokeVNetId string = spokeVNet.id
output spokeVNetName string = spokeVNet.name
```

**VNet Peering**:

```bicep
// vnet-peering.bicep
param hubVNetName string
param spokeVNetName string
param hubResourceGroupName string
param spokeResourceGroupName string

resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: '${hubVNetName}/peer-to-${spokeVNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true // Allow spoke traffic through hub firewall
    allowGatewayTransit: true   // Hub shares VPN Gateway with spokes
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(spokeResourceGroupName, 'Microsoft.Network/virtualNetworks', spokeVNetName)
    }
  }
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: '${spokeVNetName}/peer-to-${hubVNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true     // Spoke uses hub's VPN Gateway
    remoteVirtualNetwork: {
      id: resourceId(hubResourceGroupName, 'Microsoft.Network/virtualNetworks', hubVNetName)
    }
  }
}
```

**Key Points**:

- Hub VNet contains shared services (Firewall, VPN Gateway, Bastion) with reserved subnet names
- Spoke VNets host application workloads with subnets for app and data tiers
- VNet peering connects hub-spoke with `allowForwardedTraffic` for hub firewall routing
- Hub provides centralized gateway transit to on-premises networks

---

## Example 3: Azure Policy Assignments at Management Group Scope

**Azure Policy** enforces governance rules at scale. Landing Zones assign policies at management group scope for inheritance across subscriptions.

```bicep
// policy-assignments.bicep
targetScope = 'managementGroup'

param managementGroupId string = 'contoso-landingzones'

// Built-in Policy: Require tag on resources
resource requireTagPolicy 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'require-costcenter-tag'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99'
    displayName: 'Require CostCenter tag on resources'
    description: 'Enforces existence of CostCenter tag on all resources'
    parameters: {
      tagName: {
        value: 'CostCenter'
      }
    }
    enforcementMode: 'Default' // 'Default' enforces, 'DoNotEnforce' audits only
  }
}

// Built-in Policy: Allowed locations
resource allowedLocationsPolicy 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'allowed-locations'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
    displayName: 'Allowed Azure regions'
    description: 'Restricts resource deployment to approved regions'
    parameters: {
      listOfAllowedLocations: {
        value: [
          'eastus'
          'westus'
          'northeurope'
        ]
      }
    }
  }
}

// Built-in Policy: Deny public IP addresses
resource denyPublicIPPolicy 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'deny-public-ips'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749'
    displayName: 'Deny creation of public IP addresses'
    description: 'Prevents accidental exposure via public IPs in Corp landing zones'
  }
}

// Custom Policy Initiative (Policy Set)
resource securityBaselineInitiative 'Microsoft.Authorization/policySetDefinitions@2023-04-01' = {
  name: 'security-baseline'
  properties: {
    displayName: 'Security Baseline Initiative'
    policyType: 'Custom'
    description: 'Bundles multiple security policies'
    policyDefinitions: [
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9' // Require HTTPS for storage accounts
        parameters: {}
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/0961003e-5a0a-4549-abde-af6a37f2724d' // Require encryption at rest
        parameters: {}
      }
    ]
  }
}

resource securityBaselineAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'security-baseline-assignment'
  properties: {
    policyDefinitionId: securityBaselineInitiative.id
    displayName: 'Assign Security Baseline'
  }
}
```

**Deployment**:

```bash
# Deploy policies at management group scope
az deployment mg create \
  --management-group-id contoso-landingzones \
  --location eastus \
  --template-file policy-assignments.bicep
```

**Key Points**:

- Policy assignments at management group scope apply to all child subscriptions and resource groups
- Built-in policies (require tags, allowed locations, deny public IPs) enforce compliance
- Policy initiatives bundle multiple policies for consistent governance
- `enforcementMode: 'DoNotEnforce'` audits policy compliance without blocking deployments

---

## Example 4: Azure Firewall in Hub VNet

**Azure Firewall** provides centralized network filtering and threat protection for hub-spoke architectures.

```bicep
// azure-firewall.bicep
param location string = resourceGroup().location
param hubVNetName string = 'vnet-hub'
param firewallName string = 'afw-hub'

resource hubVNet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVNetName
}

resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${firewallName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard' // or 'Premium' for TLS inspection, IDPS
    }
    ipConfigurations: [
      {
        name: 'firewallConfig'
        properties: {
          subnet: {
            id: '${hubVNet.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: firewallPublicIP.id
          }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'AllowCriticalSites'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowMicrosoft'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*.microsoft.com'
                '*.azure.com'
              ]
              sourceAddresses: [
                '10.1.0.0/16' // Spoke VNet address space
              ]
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'AllowDNS'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowDNSOutbound'
              protocols: [
                'UDP'
              ]
              sourceAddresses: [
                '10.1.0.0/16'
              ]
              destinationAddresses: [
                '168.63.129.16' // Azure DNS
              ]
              destinationPorts: [
                '53'
              ]
            }
          ]
        }
      }
    ]
  }
}

// User-Defined Route (UDR) to force spoke traffic through firewall
resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: 'rt-spoke-to-firewall'
  location: location
  properties: {
    routes: [
      {
        name: 'DefaultRouteToFirewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

output firewallPrivateIP string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output routeTableId string = routeTable.id
```

**Key Points**:

- Azure Firewall requires public IP and dedicated AzureFirewallSubnet (/26 minimum)
- Application rules filter outbound traffic by FQDN (e.g., allow \*.microsoft.com)
- Network rules filter by IP, protocol, port (e.g., allow DNS to Azure DNS 168.63.129.16)
- User-Defined Route (UDR) forces spoke traffic (0.0.0.0/0) through firewall's private IP

---

## Example 5: DDoS Protection Plan

**Azure DDoS Protection Standard** provides enhanced DDoS mitigation for public-facing VNets in hub-spoke architectures.

```bicep
// ddos-protection.bicep
param location string = resourceGroup().location
param ddosProtectionPlanName string = 'ddos-plan-hub'
param hubVNetName string = 'vnet-hub'

resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2023-05-01' = {
  name: ddosProtectionPlanName
  location: location
  properties: {}
}

resource hubVNet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVNetName
}

// Enable DDoS Protection on Hub VNet
resource hubVNetWithDDoS 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hubVNetName
  location: location
  properties: {
    addressSpace: hubVNet.properties.addressSpace
    subnets: hubVNet.properties.subnets
    enableDdosProtection: true
    ddosProtectionPlan: {
      id: ddosProtectionPlan.id
    }
  }
}

output ddosProtectionPlanId string = ddosProtectionPlan.id
```

**Key Points**:

- DDoS Protection Standard protects all public IPs in VNet (vs. Basic tier per-IP protection)
- Single DDoS plan can protect multiple VNets (cost optimization)
- Provides real-time attack metrics, traffic analytics, and automatic attack mitigation
- Recommended for internet-facing workloads in Online landing zones

---

## Example 6: Resource Organization with Tags

**Resource Tags** provide metadata for cost allocation, resource organization, and automation. Landing Zones enforce tagging policies.

```bicep
// resource-group-with-tags.bicep
targetScope = 'subscription'

param location string = 'eastus'
param environment string = 'production'
param costCenter string = 'IT-001'
param applicationName string = 'eShopOnWeb'

resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${applicationName}-${environment}'
  location: location
  tags: {
    Environment: environment
    CostCenter: costCenter
    Application: applicationName
    ManagedBy: 'Bicep'
    CreatedDate: utcNow('yyyy-MM-dd')
    Owner: 'platform-team@contoso.com'
  }
}

// Resource with inherited tags
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-${applicationName}'
  location: location
  tags: union(workloadResourceGroup.tags, {
    Tier: 'PremiumV3' // Merge with additional resource-specific tags
  })
  sku: {
    name: 'P1v3'
    capacity: 2
  }
  properties: {
    reserved: true // Linux
  }
  scope: workloadResourceGroup
}

output resourceGroupName string = workloadResourceGroup.name
output resourceGroupId string = workloadResourceGroup.id
```

**PowerShell Tag Reporting**:

```powershell
# Generate cost allocation report by CostCenter tag
$resources = Get-AzResource -TagName 'CostCenter'
$resources | Group-Object -Property { $_.Tags['CostCenter'] } |
    Select-Object Name, Count |
    Export-Csv -Path 'cost-center-report.csv' -NoTypeInformation

# Find resources missing required tags
$requiredTags = @('Environment', 'CostCenter', 'Application')
$allResources = Get-AzResource
$missingTags = $allResources | Where-Object {
    $resource = $_
    $requiredTags | Where-Object { -not $resource.Tags.ContainsKey($_) }
}
```

**Key Points**:

- Standard tags (Environment, CostCenter, Application) enable cost allocation and reporting
- `union()` function merges resource group tags with resource-specific tags
- Azure Policy can require specific tags before resource creation
- Tag inheritance from resource groups simplifies consistent tagging

---

## Example 7: Subscription Vending Machine Pattern

**Subscription Vending** automates creation of landing zone subscriptions with pre-configured governance, networking, and RBAC.

```bicep
// subscription-vending.bicep
targetScope = 'managementGroup'

param managementGroupId string = 'contoso-corp'
param subscriptionAliasName string = 'workload1-sub'
param subscriptionDisplayName string = 'Workload 1 Production'
param subscriptionBillingScope string
param subscriptionOwnerPrincipalId string

// Create subscription alias (requires EA or MCA billing account)
resource subscriptionAlias 'Microsoft.Subscription/aliases@2021-10-01' = {
  name: subscriptionAliasName
  properties: {
    displayName: subscriptionDisplayName
    billingScope: subscriptionBillingScope
    workload: 'Production' // or 'DevTest'
    managementGroupId: managementGroupId
  }
}

// Assign subscription owner RBAC
resource subscriptionOwnerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscriptionAlias.id, subscriptionOwnerPrincipalId, 'Owner')
  scope: subscription(subscriptionAlias.properties.subscriptionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635') // Owner
    principalId: subscriptionOwnerPrincipalId
    principalType: 'User'
  }
}

// Deploy baseline networking to subscription
module spokeNetwork './spoke-network.bicep' = {
  name: 'deploy-spoke-network'
  scope: subscription(subscriptionAlias.properties.subscriptionId)
  params: {
    location: 'eastus'
    spokeVNetName: 'vnet-workload1'
    spokeAddressPrefix: '10.10.0.0/16'
  }
}

output subscriptionId string = subscriptionAlias.properties.subscriptionId
```

**Key Points**:

- Subscription aliases automate subscription creation via API (requires EA or MCA billing)
- New subscriptions automatically placed in designated management group (inherits policies)
- Baseline networking, RBAC, and tags applied via Bicep modules
- "Subscription Vending Machine" pattern enables self-service for application teams

---

## Example 8: Monitoring and Diagnostics Settings

**Centralized Logging** to Log Analytics workspace enables security monitoring, compliance auditing, and operational insights across landing zones.

```bicep
// log-analytics-workspace.bicep (deployed in Management subscription)
param location string = resourceGroup().location
param workspaceName string = 'law-management'
param workspaceRetentionDays int = 90

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: workspaceRetentionDays
    features: {
      enableDataExport: true
    }
  }
}

output workspaceId string = logAnalyticsWorkspace.id
```

**Diagnostic Settings for Resources**:

```bicep
// diagnostic-settings.bicep
param workspaceId string
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-law'
  scope: keyVault
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}
```

**Azure Policy to Enforce Diagnostic Settings**:

```bicep
// policy-diagnostic-settings.bicep
targetScope = 'managementGroup'

resource diagnosticSettingsPolicy 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'enforce-diagnostic-settings'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9'
    displayName: 'Deploy diagnostic settings for Key Vault to Log Analytics'
    parameters: {
      logAnalytics: {
        value: '/subscriptions/<subscription-id>/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/law-management'
      }
    }
  }
}
```

**Key Points**:

- Centralized Log Analytics workspace in Management subscription receives logs from all landing zones
- Diagnostic settings capture resource logs (Key Vault audit events, NSG flow logs, Azure Firewall logs)
- Azure Policy enforces diagnostic settings automatically for new resources
- Retention policies balance compliance requirements with cost

---

These examples demonstrate Azure Landing Zone foundational patterns for enterprise-scale architectures following Cloud Adoption Framework guidance.
