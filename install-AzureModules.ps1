#region DeclareVariables

$Script:ModuleNames = @('Microsoft365DSC')
$Script:InstalledModules = Get-Module -ListAvailable

#disable progress bar to reduce duration of update-m365dependencies
$ProgressPreference = "SilentlyContinue"

#endregion

foreach($Let_Module in $Script:ModuleNames)
{
    if(-not($Script:InstalledModules.name -contains $Let_Module))
    {
        Install-Module -Name $Script:ModuleNames -Force -Scope AllUsers
    }
    else
    {
        Import-Module -Name $Let_Module
    }
}

try
{
    Update-M365DSCDependencies -Force -Scope AllUsers 
}
catch
{
    $Error[0].Exception
}
