

data "aws_availability_zones" "available" {}


#--------------------------------------------------------------------------
#                 SETUP VPC AND INTERNET GATEWAY
#--------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "My Vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}


#--------------------------------------------------------------------------
#                       CREATE ROUTING TABLES
#--------------------------------------------------------------------------
resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Routing Public Subnets"
  }
}

resource "aws_route_table" "private_subnets" {
  count  = length(aws_subnet.public_subnets[*].id)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.main[*].id, count.index)
  }
  depends_on = [aws_nat_gateway.main]

}

resource "aws_route_table_association" "public_subnets" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)

}

resource "aws_route_table_association" "private_subnets" {
  count          = length(aws_subnet.private_subnets[*].id)
  route_table_id = element(aws_route_table.private_subnets[*].id, count.index)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}

#---------------------------------------------------------------------------
#                         ELLASTIC IP AND NAT
#---------------------------------------------------------------------------


resource "aws_eip" "main" {
  count      = length(aws_subnet.private_subnets[*].id)
  vpc        = true
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = length(aws_subnet.public_subnets[*].id)
  allocation_id = aws_eip.main[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = "NAT number ${count.index}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

#---------------------------------------------------------------------------
#                       PRIVATE AND PUBLIC SUBNETS
#---------------------------------------------------------------------------

resource "aws_subnet" "public_subnets" {
  count                   = length(var.aws_public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.aws_public_subnets, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "Main Public Subnet in ${data.aws_availability_zones.available.names[count.index]}"
    #Name = "Main Public Subnet"
  }
}


resource "aws_subnet" "private_subnets" {
  count                   = length(var.aws_private_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.aws_private_subnets, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "Main Private Subnet"
  }
}

#---------------------------------------------------------------------------








#-----------------------------------------------------------------------
#
# resource "aws_subnet" "main_database" {
#   count             = length(var.aws_database_subnets)
#   vpc_id            = var.aws_vpc.main.id
#   cidr_block        = element(var.aws_database_subnets, count.index)
#   availability_zone = data.aws_availability_zones.available.name[count.index]
#   tags = {
#     Name = "Main Database Subnet"
#   }
# }

#=========================================================================


# resource "aws_instance" "test_ubuntu" {
#   instance_type = "t2.micro"
#   ami           = "ami-0747bdcabd34c712a"
#   network_interface {
#     network_interface_id = aws_network_interface.test_ubuntu.id
#     device_index         = 0
#   }
#   key_name = aws_key_pair.main.key_name
#
# }
#
# resource "aws_key_pair" "main" {
#   key_name   = "Some_Public"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCI6MvNWdiS6GEbUGCT13Pnm+3afghCw8JBUNzMZocGLuu+e6ixOnIw74YDcJ6NSUmwAI0Wmlb5UyRTOj8+AoZAk7qhdwXLyFlmhLSG15IJmvkdRuzKDzxyK/OVuEcR5PbHsQFnACyH4xIkbQ4miicKOwzLqAhiJy2xFGtCrbKKqH9ApKE1MSgPJ57qbtEh8zEM+ik3M0bPB8whhhA+NRxKglmqypj56evTVUUkZOerYttwLzlnb01WXHoOceC/tEZtwikUmGj89JoqqAWdG95rqXvD4dYml9Rx78F7TXKOU9cG3Zk8I1eZHr1Yh7GTNttWGM7av/AzXn9QzX5peGe7 Jenkins_Master"
# }
#
#
# resource "aws_network_interface" "test_ubuntu" {
#   subnet_id = aws_subnet.public_subnets[0].id
#
#   tags = {
#     Name = "primary_network_interface"
#   }
# }
#
#
