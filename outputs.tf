output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The VPC ID"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnets
  description = "IDs of public subnets"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "IDs of private subnets"
}
