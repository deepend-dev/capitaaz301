<#
	.Synopsis
	This Azure Automation runbook removes resources with "cm-delete" tag set to today.

	.Description
	Completes the following:
		* Connects to Azure AD with a Service Principal and Connect-AzAccount.
		* Removes all the resources with "cm-delete" tag matching today's date.
        * Removes resource groups with "cm-delete" tag matching today's date.

    .Example
    Point to Runbook folder for SCM intergration while creating core automation account

    .Example
    Create new runbook in automation accounta and copy below code.
#>

# Get Azure Run As Connection Name
$connectionName = "AzureRunAsConnection"

# Get the Service Principal connection details for the Connection name
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

# Logging in to Azure AD with Service Principal
write-Output "Logging in to Azure AD..."
Connect-AzAccount -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

Get-AzContext | write-Output

Write-Output "Checking for resource groups to be deleted.."
$deleteResourceGroup = Get-AzResourceGroup -Tag @{"cm-delete" = (Get-date -Format "dd/MM/yyyy")}

if($deleteResourceGroup){
    Write-Output "Below resource groups will be deleted.."
    $deleteResourceGroup | Write-Output

    $deleteResourceGroup | ForEach-Object {
        Write-Output "Removing resource group $($_.ResourceGroupName)"
        Remove-AzResourceGroup -Id $_.ResourceId -Force
    }
}else{
    Write-Output "No resource group tagged for deletion"
}

Write-Output "Checking for resources to be deleted.."
$deleteResources = Get-AzResource -TagName "cm-delete" -TagValue (Get-date -Format "dd/MM/yyyy")

if($deleteResources){
    Write-Output "Below resources will be deleted.."
    $deleteResources  | Write-Output

    $deleteResources | ForEach-Object {
        Write-Output "Removing resource : $($_.Name)"
        Remove-AzResource -ResourceId $_.resourceId -Force
    }
}else{
    Write-Output "No specific resources tagged for deletion"
}
