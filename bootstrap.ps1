# This script performs the one-time setup for the Terraform remote backend.
# It creates a dedicated resource group, a storage account, and a container
# to store the Terraform state file securely.

# --- Configuration ---
# You can customize these names, but the defaults are based on the project documentation.
$StateRg = "terraform-state-rg"

$Location = "westus2" # Updated Location

# Generate a random suffix to ensure the storage account name is globally unique
$RandomSuffix = -join ((1..8) | ForEach-Object { (Get-Random -Minimum 0 -Maximum 15).ToString('x') })
$StateStorageAccount = "tfstate$($RandomSuffix)"
$StateContainer = "tfstate"

# --- Pre-flight Checks ---

Write-Host "Azure Terraform Backend Bootstrap Script (Azure CLI Edition)"
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

# Create the Resource Group for the backend
Write-Host "Checking for resource group: $StateRg..."
$rgExists = az group exists --name $StateRg
if ($rgExists -eq 'true') {
    Write-Host "Resource group '$StateRg' already exists."
} else {
    Write-Host "Creating resource group: $StateRg..."
    az group create --name $StateRg --location $Location --output none
    Write-Host "Resource group '$StateRg' created."
}

# Create the Storage Account for the backend
Write-Host "Checking for storage account: $StateStorageAccount..."
$sa = az storage account show --name $StateStorageAccount --resource-group $StateRg -o tsv --query "name" 2>$null
if ($sa) {
    Write-Host "Storage account '$StateStorageAccount' already exists."
} else {
    Write-Host "Creating storage account: $StateStorageAccount..."
    az storage account create `
        --name $StateStorageAccount `
        --resource-group $StateRg `
        --location $Location `
        --sku Standard_LRS `
        --encryption-services blob `
        --output none
    Write-Host "Storage account '$StateStorageAccount' created."
}

# Create the Blob Container for the state file
Write-Host "Checking for container: $StateContainer..."
$containerExists = az storage container exists --name $StateContainer --account-name $StateStorageAccount --auth-mode login -o tsv
if ($containerExists -eq 'true') {
    Write-Host "Container '$StateContainer' already exists."
} else {
    Write-Host "Creating container: $StateContainer..."
    az storage container create --name $StateContainer --account-name $StateStorageAccount --auth-mode login --output none
    Write-Host "Container '$StateContainer' created."
}

# --- Completion ---

Write-Host "

Bootstrap complete!"
Write-Host "-----------------"
Write-Host "Please update your 'terraform/backend.tf' file with the following details:"
Write-Host ""
Write-Host "terraform {"
Write-Host "  backend "azurerm" {"
Write-Host "    resource_group_name  = "$StateRg""
Write-Host "    storage_account_name = "$StateStorageAccount""
Write-Host "    container_name       = "$StateContainer""
Write-Host "    key                  = "cicd.terraform.tfstate""
Write-Host "  }"
Write-Host "}"