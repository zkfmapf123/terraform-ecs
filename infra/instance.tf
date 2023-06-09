#### Backend ####
terraform {
  backend "s3" {
    bucket = "my-ecs-terraform"
    key    = "2023-06-24/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

#### Variable ####
variable "region" {
  default = "ap-northeast-2"
}

variable "env" {
  default = "dev"
}

#### Instance #####
module "vpc" {
  source = "./modules/vpc"

  region      = var.region
  env         = var.env
  config_json = jsondecode(file("./config/vpc.json"))
}

#### Security ####
module "security_groups" {
  source = "./modules/security_groups"

  region      = var.region
  env         = var.env
  config_json = jsondecode(file("./config/security_group.json"))
  vpc_id      = module.vpc.id
}

#### ACM ####
# module "acm" {
#     source = "./modules/acm"

#     region = var.region
#     env = var.env
#     config_json = jsondecode(file("./config/acm.json"))
# }

#### Container #####
module "ecr" {
  source = "./modules/ecr"

  region      = var.region
  env         = var.env
  config_json = jsondecode(file("./config/container.json"))

  vpc = module.vpc
  sg  = module.security_groups.sg
}


#### Jenkins EC2 ####
module "ec2" {
  source = "./modules/ec2"

  region      = var.region
  env         = var.env
  config_json = jsondecode(file("./config/ec2.json"))

  vpc = module.vpc
  sg  = module.security_groups.sg
}

#### iam ####
module "iam" {
  source = "./modules/iam"  

  region = var.region
  ecr = module.ecr.ecr
}

#### ecs ####
module "ecs" {
  source = "./modules/ecs"

  region      = var.region
  env         = var.env
  config_json = jsondecode(file("./config/container.json"))

  vpc = module.vpc
  ecr = module.ecr.ecr
  iam = module.iam.iam
  sg = module.security_groups.sg
}

#### ALB ####
module "alb" {
  source ="./modules/alb"

  region = var.region
  env = var.env
  config_json = jsondecode(file("./config/container.json"))

  vpc = module.vpc
  sg = module.security_groups.sg
}

output "all_output" {
  value = {
    vpc = module.vpc
    sg  = module.security_groups.sg
    ecr = module.ecr.ecr
    iam = module.iam.iam
    ecs = module.ecs.ecs
  }
}
