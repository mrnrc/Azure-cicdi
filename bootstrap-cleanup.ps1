# This script cleans up the resources created by bootstrap.ps1.
# It deletes the entire resource group that was created to hold the Terraform state backend.

# --- Configuration ---
# This must match the resource group name from the bootstrap script.
$StateRg = "terraform-state-rg"

# --- Pre-flight Checks ---

Write-Host "Azure Terraform Backend Cleanup Script (Azure CLI Edition)"
Write-Host "---------------------------------------------------------"

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Azure CLI (az) could not be found. Please install it first."
    exit 1
}

# --- Execution ---

# Login to Azure
Write-Host "Logging into Azure. Please follow the prompts..."
try {
    az login | Out-Null
} catch {
    Write-Host "Azure login failed. Please try again."
    exit 1
}

Write-Host "Successfully logged into Azure."

# Check if the resource group exists
Write-Host "Checking for resource group: $StateRg..."
$rgExists = az group exists --name $StateRg
if ($rgExists -ne 'true') {
    Write-Host "Resource group '$StateRg' not found. Nothing to do."
    exit 0
}

# --- DANGER ZONE: Confirmation ---

Write-Host ""
Write-Host "WARNING: You are about to permanently delete the resource group '$StateRg'."
Write-Host "This group contains the Terraform state file and cannot be recovered."
$confirmation = Read-Host -Prompt "Are you sure you want to continue? (y/n)"

if ($confirmation -ne 'y') {
    Write-Host "Cleanup cancelled."
    exit 0
}

# --- Deletion ---

Write-Host "Deleting resource group '$StateRg'. This may take a few minutes..."
try {
    az group delete --name $StateRg --yes --no-wait | Out-Null
    Write-Host "Deletion of resource group '$StateRg' has been initiated. Check the Azure portal for progress."
} catch {
    Write-Host "An error occurred during resource group deletion."
    exit 1
}

# --- Completion ---

Write-Host ""
Write-Host "Cleanup script finished."