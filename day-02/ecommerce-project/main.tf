# Networking Module
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway
  name_prefix        = local.name_prefix
  tags               = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  vpc_id      = module.networking.vpc_id
  vpc_cidr    = var.vpc_cidr
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

# Database Module
module "database" {
  source = "./modules/database"
  
  subnet_ids              = module.networking.private_db_subnet_ids
  security_group_ids      = [module.security.db_security_group_id]
  db_name                 = var.db_name
  db_username             = var.db_username
  db_instance_class       = local.current_config.db_instance_class
  backup_retention_period = local.current_config.backup_retention
  enable_read_replica     = var.enable_read_replica
  name_prefix             = local.name_prefix
  tags                    = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"
  
  ami_id                 = data.aws_ami.amazon_linux.id
  web_instance_type      = local.current_config.web_instance_type
  app_instance_type      = local.current_config.app_instance_type
  web_subnet_ids         = module.networking.public_subnet_ids
  app_subnet_ids         = module.networking.private_app_subnet_ids
  web_security_group_ids = [module.security.web_security_group_id]
  app_security_group_ids = [module.security.app_security_group_id]
  web_min_size           = local.current_config.web_min_size
  web_max_size           = local.current_config.web_max_size
  app_min_size           = local.current_config.app_min_size
  app_max_size           = local.current_config.app_max_size
  name_prefix            = local.name_prefix
  tags                   = local.common_tags
  db_endpoint            = module.database.db_instance_endpoint
}

# Load Balancer Module
module "loadbalancer" {
  source = "./modules/loadbalancer"
  
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.public_subnet_ids
  security_group_ids = [module.security.alb_security_group_id]
  web_asg_name       = module.compute.web_asg_name
  name_prefix        = local.name_prefix
  tags               = local.common_tags
}