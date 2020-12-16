terraform {
  required_version = ">= 0.13.2"
  required_providers {
    random = {
      version = ">=3.0.0"
    }
    kubernetes = {
      version = ">=1.13.3"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  load_config_file = false

  host = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(
    module.cluster.ca_certificate,
  )
  client_certificate = base64decode(
    module.cluster.client_certificate,
  )
  client_key = base64decode(
    module.cluster.client_key,
  )
}

provider "helm" {
  kubernetes {
    load_config_file = false

    host = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(
      module.cluster.ca_certificate,
    )
    client_certificate = base64decode(
      module.cluster.client_certificate,
    )
    client_key = base64decode(
      module.cluster.client_key,
    )
  }
}

module "cluster" {
  source                           = "github.com/chrismellard/terraform-jx-cluster-aks?ref=main"
  cluster_name                     = local.cluster_name
  cluster_network_model            = var.cluster_network_model
  cluster_node_resource_group_name = var.cluster_node_resource_group_name
  cluster_resource_group_name      = var.cluster_resource_group_name
  cluster_version                  = var.cluster_version
  enable_log_analytics             = var.enable_log_analytics
  location                         = var.location
  logging_retention_days           = var.logging_retention_days
  network_resource_group_name      = var.network_resource_group_name
  network_name                     = var.network_name
  node_count                       = var.node_count
  node_size                        = var.node_size
  subnet_name                      = var.subnet_name
  subnet_cidr                      = var.subnet_cidr
  vnet_cidr                        = var.vnet_cidr
}

module "registry" {
  source       = "github.com/jimmy03190/jx3-terraform-azure?ref=main"
  cluster_name = local.cluster_name
  principal_id = module.cluster.kubelet_identity_id
}

module "jx-boot" {
  source          = "github.com/jimmy03190/jx3-terraform-azure?ref=main"
  depends_on      = [module.cluster]
  jx_git_url      = var.jx_git_url
  jx_bot_username = var.jx_bot_username
  jx_bot_token    = var.jx_bot_token
}

module "dns" {
  source                          = "github.com/chrismellard/terraform-jx-azuredns?ref=main"
  enabled                         = var.dns_enabled
  apex_domain_integration_enabled = var.apex_domain_integration_enabled
  apex_domain_name                = var.apex_domain_name
  apex_resource_group_name        = var.apex_resource_group_name
  cluster_name                    = local.cluster_name
  domain_name                     = var.domain_name
  location                        = var.location
  principal_id                    = module.cluster.kubelet_identity_id
  resource_group_name             = var.dns_resource_group_name
}

module "secrets" {
  source              = "github.com/jimmy03190/jx3-azure-akv?ref=main"
  enabled             = var.key_vault_enabled
  principal_id        = module.cluster.kubelet_identity_id
  cluster_name        = local.cluster_name
  resource_group_name = var.key_vault_resource_group_name
  key_vault_name      = var.key_vault_name
  key_vault_sku       = var.key_vault_sku
  location            = var.location
}

output "connect" {
  description = "Connect to cluster"
  value       = module.cluster.connect
}

output "follow_install_logs" {
  description = "Follow Jenkins X install logs"
  value       = "jx admin log"
}

output "docs" {
  description = "Follow Jenkins X 3.x docs for more information"
  value       = "https://jenkins-x.io/v3/"
}
