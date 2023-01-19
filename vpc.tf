data "aws_availability_zones" "azs" {
    state = "available"
}

locals {
  az_names       = data.aws_availability_zones.azs.names
  public_sub_ids = aws_subnet.my_public.*.id
}


resource "aws_vpc" "myvpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Environment = var.environment
    Team        = "Network"
    Name        = "myVPC"
  }
}
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Environment = var.environment
    Team        = "Network"
    Name        = "myGW"
  }
}
resource "aws_subnet" "my_public" {

  count                   = length(slice(local.az_names, 0, 2))
  vpc_id                  = aws_vpc.myvpc.id
  availability_zone       = local.az_names[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  
  tags = {
    Environment = var.environment
    Team        = "Network"
    Name        = "myPUBSUBNET"
  }
}

resource "aws_route_table" "my_publicrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  
  tags = {
    Environment = var.environment
    Team        = "Network"
    Name        = "my-public-subnet"
  }
}


resource "aws_route_table_association" "my_pub_subnet_association" {
  count          = length(slice(local.az_names, 0, 2))
  subnet_id      = aws_subnet.my_public.*.id[count.index]
  route_table_id = aws_route_table.my_publicrt.id
}



#===========security-group=========================

resource "aws_security_group" "redshift_sg" {

  name        = "redshift_access_sg"
  description = "Redshift Access Group"
  vpc_id     = aws_vpc.myvpc.id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "redshift-sg"
  }
  depends_on = [
    aws_vpc.myvpc
  ]

}


#=================redshifts-cluster-subnet-group=====================

resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "redshift-subnet-group"
  #subnet_ids = [ aws_subnet.my_public.*.id ]
  subnet_ids = local.public_sub_ids


  tags = {
    environment = "dev"
    Name = "redshift-subnet-group"
  }
}