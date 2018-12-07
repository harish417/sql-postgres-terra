provider "aws" {
  access_key = "xxxxxxxx"
  secret_key = "xxxxxxxxxxxx"
  region = "us-east-2"
}
##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  name   = "default"
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

// Added for this issue purposes:
resource "aws_db_subnet_group" "this" {
  name_prefix = "my_db_subnet_group"
  subnet_ids  = ["${data.aws_subnet_ids.all.ids}"]
}

#####
# DB
#####
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.13.0"

  identifier = "demodb123"

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine            = "postgres"
  engine_version    = "9.5"
  instance_class    = "db.t2.micro"
  allocated_storage = 30
  storage_encrypted = false

  # kms_key_id        = "arm:aws:kms:<region>:<accound id>:key/<kms key id>"
  name     = "demodb123"
  username = "harish"
  password = "YourPwdShouldBeLongAndSecure!"
  port     = "5432"

  vpc_security_group_ids = ["${data.aws_security_group.default.id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = "harish"
    Environment = "dev"
  }

  # DB subnet group
  # Disable automatic db_subnet_group creation, as we want to pass one that already exists:
  create_db_subnet_group = false
  #db_subnet_group_name   = "this"

  # DB parameter group
  family = "postgres9.5"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "demodb123"
}
                                        
