locals {
  instance_type = "t2.micro"
  vpc_cidr      = "10.123"
}

/*
* This is the root implementation of network components
*/

module "networking" {
  source    = "./modules/networking"
  vpc_cidr  = local.vpc_cidr
  access_ip = var.access_ip
  allocation_id    = "eipalloc-071ec026d31e2bd23"
  public_sn_count  = 2
  private_sn_count = 2
  db_subnet_group  = true
  availabilityzone = "eu-west-2a"
  azs              = 2
}

/*
* This is the root implementation of server (web & app) components
*/

module "servers" {
  source                 = "./modules/servers"
  bastion_sg             = module.networking.bastion_sg
  frontend_app_sg        = module.networking.frontend_app_sg
  backend_app_sg         = module.networking.backend_app_sg
  public_subnets         = module.networking.public_subnets
  private_subnets        = module.networking.private_subnets
  bastion_instance_count = 1
  instance_type          = local.instance_type
  ami_id                 = "ami-06672d07f62285d1d"
  key_name               = "sumit-ec2-demo"
  lb_sg       = module.networking.lb_sg
  tg_port     = 80
  tg_protocol = "HTTP"
  vpc_id      = module.networking.vpc_id
  listener_port     = 80
  listener_protocol = "HTTP"
  azs               = 2
}

/*
* This is the root implementation of database components
*/

module "database" {
  source               = "./modules/database"
  db_storage           = 10
  db_engine_version    = "8.0.30"
  db_instance_class    = "db.t2.micro"
  db_name              = var.db_name
  dbuser               = var.dbuser
  dbpassword           = var.dbpassword
  db_identifier        = "demo-db"
  skip_db_snapshot     = true
  rds_sg               = module.networking.rds_sg
  db_subnet_group_name = module.networking.db_subnet_group_name[0]
}
