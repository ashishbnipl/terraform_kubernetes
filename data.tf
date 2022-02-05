# Pre-requistes:
# Terraform is installed on your machine.
# Account setup in Azure.
# Kubectl is installed on your machine
# Azure cli is installed
# Login to Azure using credentials
# Make sure you are login to Azure portal first.

# az login

# Choose your Microsoft credentials. 

# Let's create following tf files using Visual studio Code:

# 1. Variables.tf - where we will define the variables used in main.tf
# 2. terraform.tfvars - Declare the values for the variables
# 3. providers.tf - declare the providers with version
# 4. main.tf - main configuration file with all the resources which will be created
# 5. output.tf - Export some data to output file

create providers.tf
provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.39.0"
    }
  }
}
create variables.tf

variable "resource_group_name" {
  type        = string
  description = "RG name in Azure"
}
variable "location" {
  type        = string
  description = "Resources location in Azure"
}
variable "cluster_name" {
  type        = string
  description = "AKS name in Azure"
}
variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
}
variable "system_node_count" {
  type        = number
  description = "Number of AKS worker nodes"
}
variable "acr_name" {
  type        = string
  description = "ACR name"
}

create terraform.tfvars
resource_group_name = "aks_tf_rg"
location            = "CentralUS"
cluster_name        = "devops-coach-aks"
kubernetes_version  = "1.19.13"
system_node_count   = 2
acr_name            = "myacr3210"

create main.tf
#In Azure, all infrastructure elements such as virtual machines, storage, and our Kubernetes cluster need to be attached to a resource group.
resource "azurerm_resource_group" "aks-rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_role_assignment" "role_acrpull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.aks-rg.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  location            = var.location
  resource_group_name = azurerm_resource_group.aks-rg.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = "Standard_DS2_v2"
    type                = "VirtualMachineScaleSets"
    availability_zones  = [1, 2, 3]
    enable_auto_scaling = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "kubenet" 
  }
}

create output.tf
output "aks_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_node_rg" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

resource "local_file" "kubeconfig" {
  depends_on   = [azurerm_kubernetes_cluster.aks]
  filename     = "kubeconfig"
  content      = azurerm_kubernetes_cluster.aks.kube_config_raw
}

Run terraform commands

terraform init



terraform plan



terraform apply

and type yes


You will see following resources are created:




Move the generated Kubeconfig file to ~/.kube/config
mv kubeconfig ~/.kube/config

To verify if worker nodes are created, use the kubectl get nodes command to return a list of the cluster nodes.

kubectl get nodes

 
You will see worker nodes with health status ready.

Let's deploy some apps into AKS cluster. 

Deploy Nginx App
kubectl create -f https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/controllers/nginx-deployment.yaml

Once the deployment is created, use kubectl to check on the deployments by running this command: 

kubectl get deployments









To see the list of pods

kubectl get pods



Perform cleanup by deleting the AKS cluster

To avoid Azure charges, you should clean up unneeded resources. When the cluster is no longer needed, use terraform destroy command to remove the resource group, AKS cluster service, and all related resources. 

terraform destroy --auto-approve