# Grant Microsoft Graph API Scopes to an Application
# Prerequisites: Install-Module Microsoft.Graph -Scope CurrentUser

param(
    [Parameter(Mandatory=$true)]
    [string]$ApplicationId,
    
    [Parameter(Mandatory=$true)]
    [string[]]$RequiredResourceAccess,
    
    [Parameter(Mandatory=$false)]
    [switch]$AdminConsent = $false
)

# Connect to Microsoft Graph with appropriate permissions
# Note: You need to be a Global Administrator or Application Administrator to grant some permissions
Connect-MgGraph -Scopes "Application.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All"

# Get the Microsoft Graph Service Principal
$graphServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

if (-not $graphServicePrincipal) {
    Write-Error "Could not find Microsoft Graph Service Principal"
    exit 1
}

# Get the application to update
try {
    $application = Get-MgApplication -Filter "appId eq '$ApplicationId'"
    
    if (-not $application) {
        Write-Error "Could not find application with ID: $ApplicationId"
        exit 1
    }
} 
catch {
    Write-Error "Error retrieving application: $_"
    exit 1
}

# Prepare the required resource access object
$requiredAccess = @{
    ResourceAppId = $graphServicePrincipal.AppId
    ResourceAccess = @()
}

# Process each requested scope
foreach ($scope in $RequiredResourceAccess) {
    # Find the permission in the Graph service principal
    $permission = $graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $scope }
    
    if ($permission) {
        # This is an Application permission
        $requiredAccess.ResourceAccess += @{
            Id = $permission.Id
            Type = "Role"
        }
        Write-Host "Adding application permission: $scope"
    } else {
        # Check if it's a delegated permission
        $permission = $graphServicePrincipal.OAuth2PermissionScopes | Where-Object { $_.Value -eq $scope }
        
        if ($permission) {
            # This is a Delegated permission
            $requiredAccess.ResourceAccess += @{
                Id = $permission.Id
                Type = "Scope"
            }
            Write-Host "Adding delegated permission: $scope"
        } else {
            Write-Warning "Permission not found: $scope"
        }
    }
}

# Update the application's required resource access
if ($requiredAccess.ResourceAccess.Count -gt 0) {
    # First, get current permissions to avoid overwriting them
    $currentRequiredResourceAccess = $application.RequiredResourceAccess
    
    # Keep non-Graph permissions
    $nonGraphPermissions = $currentRequiredResourceAccess | Where-Object { $_.ResourceAppId -ne $graphServicePrincipal.AppId }
    
    # Combine non-Graph permissions with our new Graph permissions
    $allRequiredResourceAccess = @($nonGraphPermissions) + @($requiredAccess)
    
    # Update the application with the new permissions
    try {
        Update-MgApplication -ApplicationId $application.Id -RequiredResourceAccess $allRequiredResourceAccess
        Write-Host "Successfully updated application permissions" -ForegroundColor Green
    } 
    catch {
        Write-Error "Error updating application permissions: $_"
        exit 1
    }
    
    # Grant admin consent if requested
    if ($AdminConsent) {
        Write-Host "Granting admin consent for permissions..."
        $servicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$ApplicationId'"
        
        if ($servicePrincipal) {
            foreach ($scope in $RequiredResourceAccess) {
                try {
                    # Find the permission in the Graph service principal
                    $permission = $graphServicePrincipal.OAuth2PermissionScopes | Where-Object { $_.Value -eq $scope }
                    
                    if ($permission) {
                        # This is for delegated permissions only
                        New-MgOauth2PermissionGrant -ResourceId $graphServicePrincipal.Id `
                                                   -ClientId $servicePrincipal.Id `
                                                   -ConsentType "AllPrincipals" `
                                                   -Scope $scope
                        Write-Host "Granted admin consent for: $scope" -ForegroundColor Green
                    }
                }
                catch {
                    Write-Warning "Could not grant admin consent for $scope. Error: $_"
                }
            }
        }
        else {
            Write-Warning "Could not find service principal for application. Admin consent not granted."
        }
    }
} 
else {
    Write-Warning "No valid permissions found to add."
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph

# Example usage:
# .\Grant-GraphScopes.ps1 -ApplicationId "11111111-1111-1111-1111-111111111111" -RequiredResourceAccess "User.Read", "Mail.Read", "Calendars.ReadWrite" -AdminConsent