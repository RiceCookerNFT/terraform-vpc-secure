module "vpc" {
  source     = "./modules/vpc"
  region     = var.region
  vpc_cidr   = var.vpc_cidr
  az_count   = var.az_count
  project    = var.project
}
